
#from GPStreamReadFile import GPStreamReadFile
#from VBFolioBuilder import VBFolioBuilder
import GPDebugger
from GPStreamReadFile import GPStreamReadFile
from VBFolioBuilder import VBFolioBuilder
from FlatFileUtils import FlatFileTagString
import os
import sys, traceback

NUMFLAG_DECIMAL = 10
NUMFLAG_INT     = 20
NUMFLAG_HEXA    = 30


RF2STRING    = 180
RF2DOUBLEDOT = 200
RF2PLUS      = 220
RF2MINUS     = 240
RF2PERCENT   = 260
RF2EOT       = 280
RF2NUM       = 300
RF2DOLLAR    = 320
RF2COMMA     = 330
RF2SEMICOLON = 350


class FlatFileImporter:
    def __init__(self):
        self.fileQueue = []
        self.cancelPending = False
        self.storePath = ''
        self.unreadChar = ''
        self.isUnread = False
        self.outputFileName = ''
        self.excludedQLFileName = ''
        self.indexing = True
        self.validateQueries = True
        self.divideFiles = True
        self.workingDirectory = ''
        self._propertiesArray = []
        self.inputPath = ''
        self.requestedCancel = False
        self.sansDictionaries = []
        self.importLineNumber = 0

    def openFile(self,fileName):
        print('Importer.openFile:', fileName)
        file = GPStreamReadFile(fileName)
        self.fileQueue.insert(0,file)
        GPDebugger.setFileName(os.path.basename(fileName))

    @property
    def currentFileName(self):
        if len(self.fileQueue)>0:
            return self.fileQueue[0].fileName
        return None

    @property
    def currentFile(self):
        if len(self.fileQueue)>0:
            return self.fileQueue[0]
        return None

    def unreadChar(self,chr):
        self.isUnread = True
        self.unreadChar = chr

    def readChar(self):
        if self.isUnread:
            self.isUnread = False
            return unreadChar

        if len(self.fileQueue)==0:
            return -1

        while len(self.fileQueue)>0:
            gpf = self.fileQueue[0]
            rc = gpf.getChar()
            if rc >= 0:
                return rc
            print('\nImporter.closeFile:', self.fileQueue[0].fileName)
            del self.fileQueue[0]

        return -1

    def openOutputFile(self,outputFile):
        self.outputFileName = outputFile

    def flatFileScanner(self):
        brackets = 0
        counter = 0
        tagBuffer = None
        while not self.requestedCancel:
            counter += 1
            rd = self.readChar()
            if rd == -1: break
            if rd == 13: continue
            if rd == 10:
                self.importLineNumber += 1
                self.currentFile.setLineNumber(self.importLineNumber)
                GPDebugger.setLineNumber(self.importLineNumber)
            if brackets == 0:
                if rd == ord('<'):
                    rd = self.readChar()
                    if rd == -1: break
                    if rd == ord('<'):
                        yield rd
                    else:
                        tagBuffer = FlatFileTagString()
                        tagBuffer.clear()
                        tagBuffer.appendString('<')
                        tagBuffer.appendChar(rd)
                        brackets += 1
                else:
                    yield rd
            else:
                tagBuffer.appendChar(rd)
                if rd == ord('<'):
                    brackets += 1
                elif rd == ord('>'):
                    brackets -= 1
                    if brackets == 0:
                        yield tagBuffer

    def parseFile(self):
        rd = 0
        counter = 0
        lineNumber = 1
        predefinedKeys = []
        GPDebugger.createInstanceWithDirectory(self.workingDirectory)
        textDB = VBFolioBuilder(self.workingDirectory)
        textDB.inputPath = self.inputPath
        textDB.fileInfo += 'FILE={}'.format(self.outputFileName)
        textDB.safeStringReplace = self.safeStringReplace
        textDB.supressIndexing = not self.indexing
        textDB.contentDict = {}

        textDB.acceptStart()
        tagsAddedToPlain = ["AUDIO", "BUILDVIEW", "BD", "BD-", "BD+", "BC", "CTUSE", "CTDEF", "CE", "/CE", "CR", "/CS", "DECOR", "DL", "/DL", "FC", "FD", "FLOW", "/FD", "GP", "GT", "GD", "GM", "GQ", "GI", "GA", "GF", "HD", "HD-", "HD+", "HR", "HS", "IN", "IT", "IT+", "IT-", "/JL", "JU", "KT", "KN", "LH", "LT", "LS", "ML", "/ML", "NT", "/NT", "PL", "/PL",  "PN", "/PN", "PT", "PX", "/PX", "RO", "SB", "SD", "SH", "SO", "SO-", "SO+", "SP", "/SS", "TA", "/TA", "TB", "UN", "UN-", "UN+", "WW", "/WW", "ETH", "ETB", "/ETH", "ETL", "/ETL", "ETS", "ETX", "STP", "STPLAST", "STPDEF"]

        tagsToOmit = ["AUDIO", "BUILDVIEW", "CD", "CD-", "CTUSE", "CTDEF", "CD+", "DI", "/ETH", "ETX", "ETL", "ETH", "ETB", "FLOW", "FD", "/FD", "FE", "GP", "KN-", "KN+", "KT-", "KT+", "HL", "LS", "LW", "OU", "NT", "/NT", "OU-", "OU+", "PB", "PN", "/PN", "QT", "RE", "RX", "SH", "SH+", "SH-", "STP", "STPLAST", "STPDEF", "TP", "TS", "VI", "WP"]

        for t in self.flatFileScanner():
            if isinstance(t,int):
                if t==10 or t==13:
                    textDB.acceptCharEnd()
                else:
                    textDB.acceptChar(t)
            elif isinstance(t,FlatFileTagString):
                textDB.acceptCharEnd()
                self.processTag(textDB,t,predefinedKeys=predefinedKeys,
                    tagsToOmit=tagsToOmit,tagsAddedToPlain=tagsAddedToPlain)
            else:
                print (type(t),t)

        textDB.acceptCharEnd()
        textDB.acceptEnd()

        print("Saving Files...")
        textDB.saveFolio()
        textDB.closeDumpFiles()

        print("Files saved.")

        GPDebugger.endWrite()
        print("Folio Building done.")

    def processTag(self, textDB, tagBuffer, predefinedKeys=[], tagsToOmit=[], tagsAddedToPlain=[]):
        tagText = tagBuffer.tag()
        try:
            if tagText in tagsAddedToPlain:
                textDB.currentPlainAppend(tagBuffer.buffer)
            if tagText not in tagsToOmit and tagText not in predefinedKeys:
                arr = tagBuffer.createArray()
                textDB.acceptTagArray(arr,tagBuffer)
            if tagText in ["DI","FI"]:
                arr = tagBuffer.createArray()
                if len(arr)>2:
                    fileName = arr[2].replace('\\','/')
                    fileName = os.path.join(textDB.inputPath,fileName)
                    print('request open file', fileName)
                    self.openFile(fileName)
        except:
            print('='*60)
            traceback.print_stack(file=sys.stdout)
            traceback.print_exc(file=sys.stdout)
            print('-'*60)
