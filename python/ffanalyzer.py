from FlatFileImporter import FlatFileImporter
from FlatFileUtils import FlatFileTagString
from VBFolioBuilder import VBFolioBuilder
import os
import os.path


class IndexedSet:
    def __init__(self):
        self.arr = []
    def set(self,s,id):
        index=int(id)
        while len(self.arr)<=index:
            self.arr.append('')
        self.arr[index] = s
    def get(self,s):
        if s == None: return 0
        for ia,a in enumerate(self.arr):
            if a==s: return ia
        self.arr.append(s)
        return len(self.arr)-1
    def write_to(self,f):
        a = len(self.arr)
        f.write(a.to_bytes(2,byteorder='little',signed=False))
        for s in self.arr:
            d = s.encode()
            a = len(d)
            f.write(a.to_bytes(2,byteorder='little',signed=False))
            f.write(d)

def LoadLevels(fileName):
    indexset = IndexedSet()
    with open(fileName,'rt',encoding='utf-8') as rf:
        for line in rf:
            parts = line.strip('\n').split('\t')
            if len(parts)==3:
                indexset.set(parts[2], parts[0])
    return indexset

def LoadStyles(fileName):
    indexset = IndexedSet()
    with open(fileName,'rt',encoding='utf-8') as rf:
        for line in rf:
            parts = line.strip('\n').split('\t')
            if len(parts)==2:
                indexset.set(parts[1], parts[0])
    return indexset

def ConvertTextsToBinaryFile(output_dir):
    texts_filename = os.path.join(output_dir, 'tables', 'texts.txt')
    levels_filename = os.path.join(output_dir, 'tables', 'levels.txt')
    styles_filename = os.path.join(output_dir, 'tables', 'styles.txt')
    out_texts_tbl = os.path.join(output_dir, 'data', 'texts.tbl')
    maxrec = 0
    print('Counting...',end='')
    with open(texts_filename,'rt',encoding='utf-8') as rf:
        for line in rf:
            maxrec += 1
    print(maxrec,'records')
    recs = [[0,0,0,0] for i in range(maxrec+1)]
    levels = LoadLevels(levels_filename)
    styles = LoadStyles(styles_filename)
    print("Reading lines info...")
    with open(texts_filename,'rt',encoding='utf-8') as rf:
        for line in rf:
            d = line.strip('\n').split('\t')
            recid = int(d[0])
            while len(recs)<=recid:
                recs.append([0,0,0,0])
            recs[recid][1] = len(d[1].encode())
            recs[recid][2] = levels.get(d[2])
            recs[recid][3] = styles.get(d[3])

    maxrec = len(recs)
    print('Writing...')
    with open(out_texts_tbl,'wb') as f:
        f.write(b'GOF     TEXTS   ')

        f.write(b'STRLIST LEVELS  ')
        levels.write_to(f)

        f.write(b'STRLIST STYLES  ')
        styles.write_to(f)

        # recalculate texts
        recs[0][0] = f.tell() + 4 + 16 + (maxrec + 1)*12
        recs.append([0,0,0,0])
        for i in range(maxrec):
            recs[i+1][0] = recs[i][0] + recs[i][1]

        f.write(b'STRARR  TEXTS   ')
        f.write(maxrec.to_bytes(4,byteorder='little',signed=False))
        for b in recs:
            f.write(b[0].to_bytes(4,byteorder='little',signed=False))
            f.write(b[1].to_bytes(4,byteorder='little',signed=False))
            f.write(b[2].to_bytes(2,byteorder='little',signed=False))
            f.write(b[3].to_bytes(2,byteorder='little',signed=False))

        with open(texts_filename,'rt',encoding='utf-8') as rf:
            i = 0
            for line in rf:
                d = line.strip('\n').split('\t')
                f.write(d[1].encode())
                i+=1
                if i%10000:
                    print(f'\rWriten {i} records',end='')
        print()
        #for b in recs:
        #    f.write(b[4])

def FFAnalyzerRun(output_dir, input_file):
    importer = FlatFileImporter()
    importer.safeStringReplace = {}
    importer.workingDirectory = output_dir
    importer.inputPath = os.path.dirname(input_file)
    importer.storePath = importer.inputPath
    importer.openFile(input_file)
    importer.parseFile()

    ConvertTextsToBinaryFile(output_dir)

    print ('\nOK.')


if __name__ == '__main__':
    if os.environ.get('FBUILD_OUT')==None:
        print('Missing environment variable FBUILD_OUT with output directory for folio building files (e.g. ../flat-output)')
        exit(0)

    if os.environ.get('FBUILD_IN')==None:
        print('Missing environment variable FBUILD_IN with input file (e.g. ../flat-input/VB2020.FFF)')
        exit(0)
    # working directory
    output_dir = os.environ.get('FBUILD_OUT')
    input_file = os.environ.get('FBUILD_IN')
    FFAnalyzerRun(output_dir,input_file)
