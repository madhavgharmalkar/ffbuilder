import os
import os.path
from io import StringIO

import Flat
from FlatFileUtils import FlatFileTagString


kStackMax     = 64
kContStripMax = 240

class ContentLevelRecordMap:
    def __init__(self):
        self.reclev = [0] * kContStripMax
    def setEnd(self,endrec):
        self.reclev = [endrec] * kContStripMax
    def setRecordForLevel(self,rec,lev):
        for i in range(lev,len(self.reclev)):
            self.reclev[i] = rec
    def getRecordForLevel(self,lev):
        return self.reclev[lev]

class ContentsBuilder:
    def __init__(self):
        self.outputFile = None
        self.textFile = None
        self.contStrips = [None] * kContStripMax
        self.levelMapping = [0] * kContStripMax
        self.lastLevelRecord = [0] * kContStripMax
        self.outputDir = None
        self.inputFile = None
        self.levelFile = None
        self.levels = {}
        self.whiteSpaces = [' ', '\t', '\n', '\r']
        self.contentTaggedItems = {}
        self.stpdefs = {}
        self.contentArray = []
        self.lastContentItemInserted = {}
        self.maxRecordId = 0
        self.maxLevelAllowed = 7

    def validate(self):
        return len(self.inputFile) > 0 and len(self.outputDir) > 0 and len(self.levelFile) > 0

    def loadLevels(self):
        self.levels = {}
        with open(self.levelFile,'rt',encoding='utf-8') as rf:
            for line in rf:
                parts = line.strip().split('\t')
                if len(parts)==3:
                    self.levels[parts[2]] = int(parts[0])

    def process(self):
        self.loadLevels()

        count = 0

        self.outputFile = open(os.path.join(self.outputDir,"contents.txt"), "wt", encoding='utf-8')
        self.textFile = open(os.path.join(self.outputDir,"texts-b.txt"), "wt", encoding='utf-8')

        with open(self.inputFile, "rt",encoding='utf-8') as inputf:
            for line in inputf:
                part = line.strip().split('\t')
                while len(part) < 4:
                    part.append('')
                text = part[1].strip()
                levelName = part[2]
                styleName = part[3]
                recId = int(part[0])
                if self.maxRecordId<recId: self.maxRecordId = recId

                dict = {
                    'RECORDID': recId,
                    'LEVELNAME': levelName,
                    'STYLENAME': styleName,
                    'curr_flow': 'plain',
                    'plain': StringIO()
                }
                self.setDict(dict,text)

                print("{}\t{}\t{}\t{}".format(recId, dict['plain'].getvalue(), levelName, styleName), file=self.textFile)

                self.processText(dict)

                count +=1

                if count % 2000 == 0:
                    print(f'\rProcessed {count} lines', end='')
            print()

        self.setEndRecordIds()
        self.saveContents()
        self.outputFile.close()
        self.textFile.close()


    def processText(self,dict):
        text = dict['plain'].getvalue()
        recId = dict["RECORDID"]
        style = dict["STYLENAME"]
        level = dict["LEVELNAME"]

        if "STPDEF" in self.lastContentItemInserted:
            contentBuilding = self.lastContentItemInserted["STPDEF"]
            hook = contentBuilding[level]
            if not hook:
                hook = contentBuilding[style]
            if hook:
                plainText = Flat.makeContentTextFromRecord(text)
                if 'subtext' in self.lastContentItemInserted:
                    target = self.lastContentItemInserted["subtext"]
                    target.write("<STP:{}>{}".format(hook, plainText))
        # save record to contents
        return self.saveRecordToContents(dict)

    def getLevelIndex(self,levelName):
        if not levelName or len(levelName) == 0:
            return -1

        if levelName not in self.levels:
            return -1

        return self.levels[levelName]

    def checkSupressedContentLevel(self,nLevel):
        for i in range(kContStripMax - 1, -1, -1):
            if self.contStrips[i] and 'STPLAST' in self.contStrips[i] and self.contStrips[i]['STPLAST']:
                str = self.contStrips[i]["STPLAST"]
                level = self.getLevelIndex(str)
                # first STPLAST found is actually last STPLAST defined
                # so last STPLAST overrides all previously defined
                # therefore return after evaluating level index
                # :: current level (nLevel) must not be higher than level of found STPLAST
                # :: in order to write content item into contents
                return level < nLevel
        if nLevel>self.maxLevelAllowed: return True
        return False

    def setDict(self,dict,str):
        if not str: return

        start = 0
        end = 0
        status = 0
        foundTag = False
        foundChar = False
        foundCharSpec = False

        for i in range(len(str)):
            if status == 0:
                if str[i] == '<':
                    status = 1
                else:
                    foundChar = True
            elif status == 1:
                if str[i] == '<':
                    status = 0
                    foundCharSpec = True
                else:
                    start = i-1
                    status = 2
            elif status == 2:
                if str[i] == '>':
                    end = i
                    foundTag = True
                    status = 0
                elif str[i] == '"':
                    status = 3
            elif status == 3:
                if str[i] == '"':
                    status = 4
            elif status == 4:
                if str[i] == '"':
                    status = 3
                elif str[i] == '>':
                    end = i
                    foundTag = True
                    status = 0

            if foundTag:
                extractedTag = str[start:end+1]
                tag = FlatFileTagString()
                tag.clear()
                tag.appendString(extractedTag)
                foundTag = False
                arr = tag.createArray()

                if arr[0]=="FLOW":
                    dict['curr_flow'] = arr[2]
                elif arr[0]=="STPLAST":
                    if len(arr) == 1:
                        dict['STPLAST'] = ''
                    elif len(arr) == 3:
                        paraName = arr[2]
                        safeString = Flat.stringToSafe(paraName,"LE")
                        dict['STPLAST'] = safeString
                elif arr[0] == "CTDEF":
                    if len(arr) > 2:
                        dict['ctdef'] = arr[2]
                elif arr[0] == "CTUSE":
                    if len(arr) > 2:
                        dict['ctuse'] = arr[2]
                elif arr[0] == "STPDEF":
                    if len(arr) == 1:
                        self.stpdefs = {}
                    elif len(arr)==5:
                        if arr[4] in self.stpdefs:
                            del self.stpdefs[arr[4]]
                    elif len(arr) == 13:
                        # tagArr[2] must be equal to LV
                        # tagArr[10] must be equal to STP
                        targetString = Flat.stringToSafe(arr[4],'LE')
                        hookString = Flat.stringToSafe(arr[8],arr[6])
                        if targetString not in self.stpdefs:
                            self.stpdefs[targetString] = {hookString:arr[12]}
                        else:
                            self.stpdefs[targetString[hookString]] = arr[12]
                else:
                    ms = self.currentFlowText(dict)
                    ms.write(extractedTag)
            elif foundChar:
                ms = self.currentFlowText(dict)
                ms.write(str[i])
                foundChar = False
            elif foundCharSpec:
                ms = self.currentFlowText(dict)
                ms.write('<<')
                foundCharSpec = False

        return

    def currentFlowText(self,dict):
        cf = dict['curr_flow']
        if cf not in dict:
            dict[cf] = StringIO()
        return dict[cf]

    def saveRecordToContents(self,dict):
        thisRecordId = dict["RECORDID"]
        levelName = dict["LEVELNAME"]
        level = -1

        if not levelName: return

        if 'ctuse' in dict:
            contentText = Flat.makeContentTextFromRecord(dict['plain'],getvalue())
            simpleContentText = Flat.makeSimpleContentText(contentText)
            contentItem = {
                'record': dict['id'],
                'text': contentText,
                'simpletitle': simpleContentText
            }

            children = self.contentTaggedItems[dict['ctuse']]
            children.append(contentItem)
        level = self.getLevelIndex(levelName)

        if self.checkSupressedContentLevel(level): return

        # if no level defined, then this record is not part of contents
        if level < 0 or level >= kContStripMax: return

        # writes last record to level
        for i in range(level,kContStripMax):
            self.lastLevelRecord[i] = -1
            self.contStrips[i] = None

        self.lastLevelRecord[level] = thisRecordId
        stp = dict['STPLAST'] if 'STPLAST' in dict else ''
        self.contStrips[level] = {
            'STPLAST': stp
        }

        # gets parent for current record level
        parentRecordId = 0
        for i in range(level-1,-1,-1):
            if self.lastLevelRecord[i] >= 0:
                parentRecordId = self.lastLevelRecord[i]
                break

        contentText = Flat.makeContentTextFromRecord(dict['plain'].getvalue())
        simpleContentText = Flat.makeSimpleContentText(contentText)
        strSubtext = ''
        if 'subtext' in dict: strSubtext = dict["subtext"]
        subtext = StringIO(strSubtext)

        contentItem = {
            'record': thisRecordId,
            'parent': parentRecordId,
            'text': contentText,
            'level': level,
            'simpletitle': simpleContentText,
            'subtext': subtext
        }

        if 'ctdef' in dict:
            children = []
            contentItem['children'] = children
            self.contentTaggedItems[dict['ctdef']] = children

        self.contentArray.append(contentItem)
        self.lastContentItemInserted = contentItem
        if levelName in self.stpdefs:
            contentItem['STPDEF'] = self.stpdefs[levelName]

        return contentItem

    def setEndRecordIds(self):
        map = ContentLevelRecordMap()
        map.setEnd(self.maxRecordId)
        lastLevel = -1
        for cidx in range(len(self.contentArray)-1,-1,-1):
            ci = self.contentArray[cidx]
            ci['node_count'] = 0 if lastLevel <= ci['level'] else 1
            ci['nextSibling'] = map.getRecordForLevel(ci['level'])
            map.setRecordForLevel(ci['record'],ci['level'])
            lastLevel = ci['level']

    def saveContents(self):
        ai = 0
        contentItemId = 0
        for contItem in self.contentArray:
            contentItemId+=1
            ai+=1
            contItem['itemid'] = contentItemId
            level = contItem['level']
            parent = contItem['record']
            child_count = contItem['node_count']
            if 'children' in contItem:
                children = sorted(contItem['children'], key='simpletitle')
                for contChild in children:
                    contentItemId+=1
                    contChild['itemid'] = contentItemId
                    contChild['parent'] = parent
                    contChild['level'] = level + 1

            # writes to dump file
            self.outputFile.write("{}\t".format(contItem['level']))
            self.outputFile.write("{}\t".format(contItem['record']))
            self.outputFile.write("{}\t".format(contItem['parent']))
            self.outputFile.write("{}\t".format(contItem["text"]))
            self.outputFile.write("{}\t".format(contItem["simpletitle"]))
            self.outputFile.write("{}\t".format(contItem["subtext"].getvalue()))
            self.outputFile.write("{}\t".format(child_count))
            self.outputFile.write("{}\t".format('C'))
            node_type = 1 if child_count==0 else 2
            self.outputFile.write("{}\t".format(node_type))
            self.outputFile.write("{}\n".format(contItem['nextSibling']))

        print("Done - Saving Content")
