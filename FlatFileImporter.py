
from GPStreamReadFile import GPStreamReadFile
from VBFolioBuilder import VBFolioBuilder
from GPDebugger import GPDebugger
import os

class FlatFileImporter:
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

    def openFile(self,fileName):
        file = GPStreamReadFile(fileName)
        self.fileQueue.insert(0,file)
        GPDebugger.setFileName(os.path.basename(fileName))

    def currentFileName(self):
        if len(self.fileQueue)>0:
            return self.fileQueue[0].fileName
        return None

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
            del self.fileQueue[0]

        return -1

    def openOutputFile(self,outputFile):
        self.outputFileName = outputFile


    def processTag(self,textDB,tagBuffer,predefinedKeys=[],tagsToOmit=[],tagsAddedToPlain=[]):
        tagText = tagBuffer.tag()
        if tagText in tagsAddedToPlain:
            textDB.currentPlain.appendString(tagBuffer.mutableBuffer())
        if tagText not in tagsToOmit and tagText not in predefinedKeys:
            arr = tagBuffer.createArray()
            textDB.acceptTagArray(arr,tagBuffer)
            if textDB.requestedFileName != None:
                self.openFile(textDB.requestedFileName)
                textDB.requestedFileName = None

    def parseFile(self):
        rd = 0
        counter = 0
        lineNumber = 1
        brackets = 0
        tagBuffer = FlatFileTagString()
        predefinedKeys = []
        textDB = VBFolioBuilder()
        textDB.inputPath = self.inputPath
        textDB.fileInfo += 'FILE={}'.format(self.outputFileName)
        textDB.safeStringReplace = self.safeStringReplace
        textDB.supressIndexing = !self.indexing
        textDB.contentDict = {}

        textDB.acceptStart()
        tagsAddedToPlain = ["AUDIO", "BUILDVIEW", "BD", "BD-", "BD+", "CTUSE", "CTDEF", "CE", "/CE", "CR", "/CS", "DECOR", "DL", "/DL", "FC", "FD", "FLOW", "FT", "/FD", "GP", "GT", "GD", "GM", "GQ", "GI", "GA", "GF", "HD", "HD-", "HD+", "HR", "HS", "IN", "IT", "IT+", "IT-", "/JL", "JU", "KT", "KN", "LH", "LT", "LS", "ML", "/ML", "NT", "/NT", "PL", "/PL",  "PN", "/PN", "PT", "PX", "/PX", "RO", "SB", "SD", "SH", "SO", "SO-", "SO+", "SP", "/SS", "TA", "/TA", "TB", "UN", "UN-", "UN+", "WW", "/WW", "ETH", "ETB", "/ETH", "ETL", "/ETL", "ETS", "ETX", "STP", "STPLAST", "STPDEF"]

        tagsToOmit = ["AUDIO", "BUILDVIEW", "CD", "CD-", "CTUSE", "CTDEF", "CD+", "/ETH", "ETX", "ETL", "ETH", "ETB", "FLOW", "FD", "/FD", "FE", "GP", "KN-", "KN+", "KT-", "KT+", "HL", "LS", "LW", "OU", "NT", "/NT", "OU-", "OU+", "PB", "PN", "/PN", "QT", "RE", "RX", "SH", "SH+", "SH-", "STP", "STPLAST", "STPDEF", "TP", "TS", "VI", "WP"]

        while !self.requestedCancel:
            counter += 1
            rd = self.readChar()
            if rd == -1: break
            if rd == '\n':
                lineNumber += 1
                self.currentFile.setLineNumber(lineNumber)
                GPDebugger.setLineNumber:lineNumber
            if brackets == 0:
                if rd == '<':
                    rd = self.readChar()
                    if rd == -1: break
                    if rd == '<':
                        textDB.acceptChar(rd)
                    else:
                        tagBuffer.clear()
                        tagBuffer.appendChar('<')
                        tagBuffer.appendChar(rd)
                        brackets += 1
                else:
                    if rd != '\n' and rd != '\r':
                        textDB.acceptChar(rd)
            else:
                tagBuffer.appendChar(rd)
                if rd == '<':
                    brackets += 1
                elif rd == '>':
                    brackets -= 1
                    if brackets == 0:
                        self.processTag(textDB,tagBuffer,predefinedKeys=predefinedKeys,tagsToOmit=tagsToOmit,tagsAddedToPlain=tagsAddedToPlain)
                        tagBuffer.clear()
        textDB.acceptEnd()

        print("Saving Files...")
        textDB.saveFolio()
        textDB.closeDumpFiles()

        print("Files saved.")

        GPDebugger.endWrite()
        print("Folio Building done.")


        
