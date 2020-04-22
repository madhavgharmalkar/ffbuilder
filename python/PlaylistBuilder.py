import os
import os.path

import Flat

kMaxLevel = 100

class PlaylistBuilder:
    def __init__(self):
        self.outputFile = None
        self.outputFile2 = None
        self.levelRecs = [None] * kMaxLevel
        self.levelRecIds = [-1] * kMaxLevel
        self.outputDir = None
        self.inputFile = None
        self.levelFile = None
        self.levels = None
        self.maxLevel = 6
        self.gid = 1
        self.regex1 = None
        self.regex2 = None
        self.printedRecs = {}

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

        self.outputFile = open(os.path.join(self.outputDir, "playlists.txt"), "wt", encoding='utf-8')
        self.outputFile2 = open(os.path.join(self.outputDir, "playlists_details.txt"), "wt", encoding='utf-8')

        with open(self.inputFile,'rt',encoding='utf-8') as input_file:
            for line in input_file:
                part = line.strip('\n').split('\t')

                self.processText(part[1], int(part[0]), part[3], part[2])
                count += 1

                if count % 2000 == 0:
                    print(f'\rProcessed {count} lines.',end='')
        print()

        self.outputFile.close()
        self.outputFile2.close()


    def processText(self,text,recId,style,levelName):
        level = self.getLevelIndex(levelName)

        if level != -1 and level <= self.maxLevel:
            for i in range(level,kMaxLevel):
                self.levelRecs[i] = None
                self.levelRecIds[i] = -1

        if style=="PA_Audio_Bg":
            #print(recId, text)
            r1 = text.find("<AUDIO:\"")
            r1l = 8
            if r1<0:
                r1 = text.find("<DL:Data,\"")
                r1l = 10

            if r1>=0:
                r2 = text.find('"', r1 + r1l)

            if r1>=0 and r2 > r1:
                object = text[r1 + r1l:r2]
                prevLevId = -1
                for i in range(kMaxLevel):
                    if self.levelRecIds[i] == -1: continue
                    key = self.levelRecIds[i]
                    if key not in self.printedRecs:
                        # PLAYLT  levelRecs[i]   prevLevId     title
                        print("{}\t{}\t{}".format(self.levelRecIds[i], prevLevId, Flat.removeTags(self.levelRecs[i])), file=self.outputFile)
                        self.printedRecs[key] = True
                    prevLevId = self.levelRecIds[i]

                print("{}\t{}\t{}".format(prevLevId, self.gid, object), file=self.outputFile2)
                #OBJECT   self.gid   prevLevId    object
                self.gid+=1
        else:
            if level != -1 and level <= self.maxLevel:
                self.levelRecs[level] = text
                self.levelRecIds[level] = self.gid
                self.gid+=1
