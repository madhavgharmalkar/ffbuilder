import io

class GPStreamReadFile:
    def __init__(self,filename):
        self.fileHandle = open(filename,'rb')
        self.fileName = filename
        self.lineNumber = 1

    def __del__(self):
        self.closeFile()

    def closeFile(self):
        self.fileHandle.close()

    def getChar(self):
        c = self.fileHandle.read(1)
        if not c:
            return -1
        return ord(c)

    def setLineNumber(self,line):
        self.lineNumber = line

    def size(self):
        pos = self.fileHandle.ftell()
        self.fileHandle.seek(0,2)
        siz = self.fileHandle.ftell()
        self.fileHandle.see(pos,0)
        return siz
