from ViewDir import ViewDir
import Flat

import os
import os.path


kMaxLevel = 100

class ViewsBuilder:
    def __init__(self):
        self.outputFile = None
        self.outputFile2 = None
        self.levelRecs = [None] * kMaxLevel
        self.levelRecIds = [-1] * kMaxLevel
        self.levelBuildViews = [False] * kMaxLevel
        self.outputDir = None
        self.inputFile = None
        self.levelFile = None
        self.levels = {}
        self.gid = 1
        self.maxLevel = 6
        self.globLastLevel = 0
        self.views = ViewDir()
        self.contentItems = []

    def loadLevels(self):
        self.levels = {}
        with open(self.levelFile,'rt',encoding='utf-8') as rf:
            for line in rf:
                parts = line.strip().split('\t')
                if len(parts)==3:
                    self.levels[parts[2]] = int(parts[0])

    def validate(self):
        return len(self.inputFile) > 0 and len(self.outputDir) > 0 and len(self.levelFile) > 0

    def getLevelIndex(self,levelName):
        if levelName == None or len(levelName)==0: return -1
        if levelName not in self.levels: return -1
        return self.levels[levelName]

    def process(self):
        self.loadLevels()

        count = 0

        self.outputFile = open(os.path.join(self.outputDir, "views.txt"), "wt", encoding='utf-8')
        self.outputFile2 = open(os.path.join(self.outputDir, "view_details.txt"), "wt", encoding='utf-8')

        with open(self.inputFile,'rt',encoding='utf-8') as input_file:
            for line in input_file:
                part = line.strip('\n').split('\t')

                self.processText(part[1], int(part[0]), part[3], part[2])
                count += 1

                if count % 2000 == 0:
                    print(f'\rProcessed {count} lines.',end='')
        print()
        self.writeViews(self.views)

        self.outputFile.close()
        self.outputFile2.close()

    def writeViews(self,V):
        if V.subs == None: return
        for A in V.subs:
            print("{}\t{}\t{}".format(V.pid, A.pid, A.name), file=self.outputFile)
            self.writeViews(A)

    def eligibleForBuild(self, text, recId):
        t = Flat.makeContentTextFromRecord(text)
        t = Flat.makeSimpleContentText(t)
        #print('Orig=',text,'\nNew=', t, '\n------------------')
        if t in self.contentItems:
            print(f'\n{t}\n')
            return True
        return '<BUILDVIEW>' in text

    def processText(self,text,recId,style,levelName):
        level = self.getLevelIndex(levelName)
        buildTags = False

        if level != -1:
            for i in range(level,kMaxLevel):
                self.levelRecs[i] = None
                self.levelRecIds[i] = -1
                self.levelBuildViews[i] = False
            self.levelBuildViews[level] = self.eligibleForBuild(text,recId)
            self.levelRecs[level] = Flat.removeTags(text)
            self.levelRecIds[level] = self.gid
            self.gid+=1
            self.globLastLevel = level

        if self.globLastLevel != -1:
            for j in range(self.globLastLevel):
                if self.levelBuildViews[j]:
                    buildTags = True
                    break

        if buildTags:
            if style == "PA_Textnum":
                self.insertRecord(recId,"Translations",self.maxLevel)
                self.insertRecord(recId,"Verses",self.maxLevel)
                self.insertRecord(recId,"Verses & Translations",self.maxLevel)
            elif style == "PA_Translation":
                self.insertRecord(recId, "Translations", self.maxLevel)
                self.insertRecord(recId, "Verses & Translations", self.maxLevel)
            elif levelName == "LE_Verse_Text" and style != "PA_Audio_Bg":
                self.insertRecord(recId,"Verses",self.maxLevel)
                self.insertRecord(recId,"Verses & Translations",self.maxLevel)

    def insertRecord(self, recId, group, maxLev):
        vw = self.views.getChild(group)
        for i in range(maxLev+1):
            if self.levelRecs[i] != None:
                vw = vw.getChild(self.levelRecs[i])
        print(f"{vw.pid}\t{recId}", file=self.outputFile2)
