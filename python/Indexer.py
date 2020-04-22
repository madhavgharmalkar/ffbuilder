from RKKeySet import RKKeySet
from RKSortedList import RKSortedList
from FlatFileUtils import GPMutableInteger,FlatFileTagString
import Flat
import FlatIndexer

from io import BytesIO
import os
import os.path

PAGE_SIZE_X = 0x10000


class Indexer:
    def __init__(self):
        self.fileA = None
        self.fileB = None
        self.inputFile = None
        self.keywordFileName = None
        self.outputDir = None
        self.errorFile = None
        self.wordList = RKSortedList()
        self.wordList.keyName = 'text'
        self.dotsCharset = ['.', ',', '?', '!']
        self.wordsMap = RKKeySet()
        self.idxMap = RKKeySet()
        self.counter = 0

    def doIndexLine(self,text,recId):
        prop = {
            'record': recId,
            'fields': {},
            'all': [],
            'position': GPMutableInteger(),
            'level': GPMutableInteger(),
            'note': GPMutableInteger()
        }
        for tp,tx in FlatIndexer.parse(text):
            if tp=='tag':
                self.pushTag(FlatFileTagString(tx),prop)
            elif tp=='text':
                self.pushWord(tx,prop)
        self.pushEndfromIndexer(prop)

    def pushEndfromIndexer(self,indexer):
        all = indexer["all"]
        record = indexer["record"]
        for obj in all:
            self.addWordOccurence:("<all>", record, 0, obj)

    def doIndexing(self):
        count = 0
        if self.keywordFileName != None and len(self.keywordFileName) > 0 and os.path.exists(self.keywordFileName):
            print("START KEYWORDS INDEXING")
            lineCount = 0
            with open(self.keywordFileName,'rt',encoding='utf-8') as file:
                for line in file:
                    p = line.strip().replace('\t',' ').split(' ')
                    if len(p) >= 2:
                        recId = int(p[0])
                        for j in range(1,len(p)):
                            self.addWordOccurence(p[j],recId,j,'keywords')
                    lineCount+=1
            print(f"END OF KEYWORDS INDEXING - {lineCount} lines processed")

        print("START INDEXING")

        with open(self.inputFile, "rt") as i:
            print()
            for line in i:
                part = line.strip('\n').split('\t')
                self.doIndexLine(part[1],int(part[0]))
                count += 1
                if count % 400 == 0:
                    print(f"\rProcessed {count} records", end='')
            print()

            self.fileB = open(os.path.join(self.outputDir,'tables',"words_b.txt"), "wt", encoding='utf-8')
            self.fileA = open(os.path.join(self.outputDir,'tables',"words_a.txt"), "wt", encoding='utf-8')

            self.saveWordsIndex()

            self.fileA.close()
            self.fileB.close()

        print("END OF INDEXING")

    def nextId(self):
        self.counter+=1
        return self.counter

    def saveWordsIndex(self):
        self.counter = 0
        objDir = os.path.join(self.outputDir, 'tables', 'obj')

        if os.path.isfile(objDir):
            print(f"Could not save object files, because name {objDir} is already the name of existing file")
            return
        elif not os.path.exists(objDir):
            os.mkdir(objDir)

        for i in range(len(self.wordList.array)):
            dict = self.wordList.array[i]
            blobs = dict["blobs"]
            for indexName,pages in blobs.items():
                for page,dataio in pages.items():
                    word = dict[self.wordList.keyName]
                    data = dataio.getvalue()
                    if len(data) > 50000:
                        filePath = os.path.join(objDir,f'w_{self.counter}')
                        with open(filePath,'wb') as wf:
                            wf.write(data)
                        self.counter+=1
                        print("{}\t{}\t{}\t{}\t".format(indexName,dict['uid'],word,page), file=self.fileB, end='')
                        print(filePath, file=self.fileB)
                    else:
                        print("{}\t{}\t{}\t{}\t".format(indexName,dict['uid'],word,page), file=self.fileA, end='')
                        for k in data:
                            print('{:02x}'.format(k), file=self.fileA, end='')
                        print('', file=self.fileA)

    def validate(self):
        return len(self.outputDir) > 0 and len(self.inputFile) > 0


    #pragma mark -
    #pragma mark Indexer Delegate


    def pushTag(self,tag,indexer):
        fields = indexer["fields"]
        all = indexer["all"]
        level = indexer["level"]
        note = indexer["note"]

        tagStr = tag.tag()
        if tagStr=="NT":
            note.increment()
            all.append("Note")
        elif tagStr=="/NT":
            note.decrement()
        elif tagStr=="PW":
            level.increment()
            all.append("Popup")
        elif tagStr=="LT":
            level.decrement()
        elif tagStr=="FD":
            arr = tag.createArray()
            if len(arr) >= 3:
                fields[arr[2]] = True
                all.append(arr[2])
                all.append("<all>")
        elif tagStr=="/FD":
            arr = tag.createArray()
            if len(arr) >= 3:
                del fields[arr[2]]

    def pushWord(self,aWord,indexer):
        word = aWord.rstrip('.,?!')
        position = indexer["position"]
        fields = indexer["fields"]
        level = indexer["level"]
        record = indexer["record"]
        note = indexer["note"]

        if 'Devanagari' in fields: return

        if level.value > 0:
            self.addWordOccurence(word, record, position.value, 'Popup')
        elif note.value > 0:
            self.addWordOccurence(word, record, position.value, 'Note')
        else:
            self.addWordOccurence(word, record, position.value, '')

        for obj in fields:
            self.addWordOccurence(word, record, position.value, obj)

        # increase word position
        position.increment()


    def addWordOccurence(self, aWord, aRecord, aPosition, idxTag):
        wordObject = self.wordList.objectForKey(aWord)
        if wordObject == None:
            blobs = {}

            wordObject = {
                'text': aWord,
                'uid': self.wordList.count() + 1,
                'blobs': blobs
            }
            self.wordList.addObject(wordObject)

        recs = None
        pages = None
        blobs = wordObject["blobs"]
        page = int(aRecord/PAGE_SIZE_X)*PAGE_SIZE_X
        if idxTag not in blobs:
            pages = {}
            blobs[idxTag] = pages
        else:
            pages = blobs[idxTag]

        if page not in pages:
            recs = BytesIO()
            pages[page] = recs
        else:
            recs = pages[page]

        # zapisuje rec_id aj proximity
        r = aRecord % PAGE_SIZE_X
        recs.write(r.to_bytes(4,byteorder='little',signed=False))
        recs.write(aPosition.to_bytes(2,byteorder='little',signed=False))



def BlobIndexerRun(output_dir,kwFile = None):
    indexer = Indexer()
    indexer.outputDir = output_dir
    indexer.inputFile = os.path.join(output_dir,'tables','texts-b.txt')
    indexer.keywordFileName = kwFile

    if indexer.validate():
        indexer.doIndexing()


if __name__ == '__main__':
    if os.environ.get('FBUILD_OUT')==None:
        print('Missing environment variable FBUILD_OUT with output directory for folio building files (e.g. ../flat-output)')
    else:
        output_dir = os.environ.get('FBUILD_OUT')
        BlobIndexerRun(output_dir)
