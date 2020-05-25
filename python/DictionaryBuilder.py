import os
import os.path

import Flat

class VBDictionaryWord:
    def __init__(self,store=None):
        self.storage = store
        self.ID = 0
        self.word = ''
        self.simple = ''

    def write(self):
        print(f'{self.ID}\t{self.word}\t{self.simple}', file=self.storage)

class VBDictionaryMeaning:
    def __init__(self,store=None):
        self.storage = store
        self.dictionaryID = 0
        self.wordID = 0
        self.recordID = 0
        self.meaning = ''
    def write(self):
        print(f'{self.wordID}\t{self.dictionaryID}\t{self.recordID}\t{self.meaning}', file=self.storage)

class VBDictionaryInstance:
    def __init__(self,store):
        self.storage = store
        self.ID = 0
        self.name = ''
    def write(self):
        print(f'{self.ID}\t{self.name}', file=self.storage)

class DictionaryBuilder:
    def __init__(self):
        self.fileMean = None
        self.fileInst = None
        self.fileWord = None
        self.outputDir = ''
        self.inputFiles = []
        self.levelFile = None

    def validate(self):
        return len(self.inputFiles) > 0 and len(self.outputDir) > 0

    def writeMeanings(self,meanings):
        rid = 1
        for ekey,means in meanings.items():
            keys = ekey.split('_')
            for obj in means:
                dm = VBDictionaryMeaning(self.fileMean)
                dm.wordID = keys[1]
                dm.dictionaryID = keys[0]
                dm.meaning = obj
                dm.recordID = rid
                dm.write()
                rid += 1

    def process(self):
        self.fileMean = open(os.path.join(self.outputDir, "tables", "dict_means.txt"), 'wt', encoding='utf-8')
        self.fileInst = open(os.path.join(self.outputDir, "tables", "dictionary.txt"), 'wt', encoding='utf-8')
        self.fileWord = open(os.path.join(self.outputDir, "tables", "dict_words.txt"), 'wt', encoding='utf-8')

        if len(self.inputFiles) > 0:
            dictionaries = {}
            currentDictionary = None
            lastDictionaryId = 1
            words = {}
            wordDict = None
            lastWordId = 1
            meanings = {}
            wscs = ['\r', '\n']
            for str in self.inputFiles:
                with open(str,'rt',encoding='utf-8') as rf:
                    for line in rf:
                        line = line.strip()
                        if line.startswith('<D>'):
                            name = line[3:].strip()
                            if name not in dictionaries:
                                di = VBDictionaryInstance(self.fileInst)
                                di.ID = lastDictionaryId
                                di.name = name
                                di.write()

                                currentDictionary = {
                                    'DICTID': lastDictionaryId,
                                    'NAME': name
                                }
                                dictionaries[name] = currentDictionary
                                lastDictionaryId+=1
                            else:
                                currentDictionary = dictionaries[name]
                        elif line.startswith("<H>") and line.endswith('<E>'):
                            parts = line[3:-3].split('<L>')
                            if len(parts) != 2:
                                print(f"==== line ====\n{line}")
                                continue
                            word = parts[0]
                            meaning = parts[1]
                            if word not in words:
                                dw = VBDictionaryWord(self.fileWord)
                                dw.ID = lastWordId
                                dw.word = word
                                dw.simple = Flat.makeDictionaryString(word)
                                dw.write()

                                wordDict = {
                                    'WORD': dw.word,
                                    'SIMPLE': dw.simple,
                                    'WORDID': lastWordId
                                }
                                words[word] = wordDict
                                lastWordId+=1

                                if lastWordId % 1200 == 0:
                                    print(f"\rWord {lastWordId} - Importing Dictionaries",end='')
                            else:
                                wordDict = words[word]

                            meaningKey = '{}_{}'.format( currentDictionary['DICTID'], wordDict['WORDID'])
                            if meaningKey not in meanings:
                                meanings[meaningKey] = []
                            meanings[meaningKey].append(meaning)

            print("\nWrite meanings - Importing Dictionaries")
            self.writeMeanings(meanings)

        self.fileMean.close()
        self.fileInst.close()
        self.fileWord.close()
