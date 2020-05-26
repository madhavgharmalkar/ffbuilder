import os
import os.path
import json
import numpy as np

import Flat

CLR_DEF = 0
CLR_RED = 1
CLR_GREEN = 2
CLR_YELLOW = 3
CLR_BLUE = 4
CLR_MAGENTA = 5
CLR_CYAN = 6
CLR_WHITE = 7

CI_GROUP_DEFAULT = 0
CI_GROUP_NEW     = 1
CI_GROUP_DELETED = 2

class ContentItem:
    def __init__(self,text='',recordID=-1,foreignRecordID=-1,level=-1,subStart=-1,subEnd=-1):
        self.text = text
        self.recordID = recordID
        self.foreignRecordID = foreignRecordID
        self.level = level
        self.subStart = subStart
        self.subEnd = subEnd
        self.globalIndex = -1
        self.group = CI_GROUP_DEFAULT
        self.subLevel = -1
        self.subArray = None

    def __str__(self):
        return f'[{self.level}] {self.text} : {self.recordID}-->{self.foreignRecordID}'

    def __iter__(self):
        yield 'tex', self.text
        yield 'rec', self.recordID,
        yield 'fre', self.foreignRecordID
        yield 'lev', self.level
        yield 'sst', self.subStart
        yield 'sen', self.subEnd
        yield 'gin', self.globalIndex
        yield 'grp', self.group

    @staticmethod
    def FromData(data):
        ci = ContentItem()
        ci.text = data['tex']
        ci.recordID = data['rec']
        ci.foreignRecordID = data['fre']
        ci.level = data['lev']
        ci.subStart = data['sst']
        ci.subEnd = data['sen']
        ci.globalIndex = data['gin']
        if 'grp' in data:
            ci.group = data['grp']
        return ci

class LevelRecords:
    def __init__(self, maxrec):
        self.recs = [maxrec] * 100

    def setLevelRecord(self,level,record):
        for i in range(level,len(self.recs)):
            self.recs[i] = record

class FolioBuild:
    def __init__(self,directory,name):
        self.dir = directory
        self.name = name
        self.textFile = os.path.join(self.dir, 'tables', 'texts-b.txt')
        self.levelFile = os.path.join(self.dir, 'tables', 'levels.txt')
        self.mergeFile = os.path.join(self.dir, 'tables', 'merge-1.json')
        self.historyRecordsFile = os.path.join(self.dir, 'tables', 'historec.txt')
        self.levels = {}
        # this sets the limit for levels, because not all levels are in our interest
        self.levelLimit = 10
        self.contents = []
        self.maxRecord = 0
        self.levelRecords = LevelRecords(0)

    def __iter__(self):
        yield 'dir', self.dir
        yield 'name', self.name
        yield 'levels', self.levels
        yield 'levelLimit', self.levelLimit
        yield 'contents', [dict(a) for a in self.contents]
        yield 'maxRecord', self.maxRecord

    def indexContent(self):
        i=0
        for a in self.contents:
            a.globalIndex = i
            i+=1

    def loadData(self,data):
        self.directory = data['dir']
        self.name = data['name']
        self.levels = data['levels']
        self.levelLimit = data['levelLimit']
        self.contents = [ContentItem.FromData(a) for a in data['contents']]
        print(len(data['contents']))
        print(len(self.contents))
        self.maxRecord = data['maxRecord']
        self.indexContent()

    def checkFiles(self):
        if not os.path.exists(self.textFile):
            print('File', self.textFile, 'does not exist.')
            return False
        if not os.path.exists(self.levelFile):
            print('File', self.levelFile, 'does not exist.')
            return False
        return True

    def loadLevels(self):
        self.levels = {}
        with open(self.levelFile,'rt',encoding='utf-8') as rf:
            for line in rf:
                parts = line.strip().split('\t')
                if len(parts)==3 and int(parts[0])<=self.levelLimit:
                    self.levels[parts[2]] = int(parts[0])

    def textRecordGenerator(self):
        with open(self.textFile,'rt',encoding='utf-8') as rf:
            for line in rf:
                p = line.strip('\n').split('\t')
                if len(p)!=4: continue
                p[0] = int(p[0])
                yield p


    def loadContents(self):
        print(f'Loading contents from {self.textFile}')
        with open(self.textFile,'rt',encoding='utf-8') as rf:
            for line in rf:
                p = line.strip('\n').split('\t')
                if len(p)!=4: continue
                p[0] = int(p[0])
                if self.maxRecord<p[0]:
                    self.maxRecord = p[0]
                if self.getLevel(p[2])<100:
                    pr = ContentItem(level=self.getLevel(p[2]), recordID = int(p[0]), text=Flat.removeTags(p[1]), subStart=p[0]+1)
                    self.contents.append(pr)
                    #print(pr)
            self.contents.insert(0, ContentItem(level=0, recordID=0, foreignRecordID=-1, text='root', subStart=0, subEnd=self.maxRecord))
            self.levelRecords = LevelRecords(self.maxRecord)
            for i in range(len(self.contents)-1,-1,-1):
                ci = self.contents[i]
                ci.globalIndex = i
                ci.subEnd = self.levelRecords.recs[ci.level]-1
                if ci.subEnd < ci.subStart:
                    ci.subStart = -1
                    ci.subEnd = -1
                self.levelRecords.setLevelRecord(ci.level, ci.recordID)

    def getLevel(self,levelName):
        if levelName in self.levels:
            return self.levels[levelName]
        return 100

    def compareLevels(self, fnew):
        for k,v in self.levels.items():
            if k not in fnew.levels:
                print ('Level {} ({}) only in {}'.format(k, v, self.name))
            elif self.levels[k] != fnew.levels[k]:
                print ('Level', k, 'has different order among folios')

    def contentItems(self,level):
        arr = []
        for a in self.contents:
            if a[0]==level:
                arr.append(a)
        return arr

    def getSubItems(self,cidx):
        if cidx>=0 and cidx<len(self.contents):
            ci = self.contents[cidx]
            if ci.subLevel!=-1:
                return ci.subLevel,ci.subArray
            if ci.subStart==-1 and ci.subEnd==-1:
                return None,None
            minLevel = 100
            arr = []
            for ccidx in range(cidx,len(self.contents)):
                cci = self.contents[ccidx]
                if cci.recordID < ci.subStart: continue
                if cci.recordID > ci.subEnd: break
                if cci.level > ci.level and cci.level<minLevel:
                    #arr = []
                    minLevel = cci.level
                if cci.level == minLevel:
                    arr.append(cci)
            ci.subLevel = minLevel
            ci.subArray = arr
            return minLevel,arr

    def getParents(self,record,startIndex=-1):
        if startIndex<0: startIndex = len(self.contents)-1
        lastRec = record
        arr = []
        for index in range(len(self.contents)-1,-1,-1):
            item = self.contents[index]
            if item.subStart >= lastRec and item.subEnd <= lastRec:
                arr.insert(0,item)
                lastRec = item.recordID
        arr.insert(0,self.contents[0])
        return arr

class ContentWindow:
    def __init__(self,folio=None):
        self.folio = folio
        self.screenKeys = {}
        self.windowItems = []
        self.currentLevel = 0
        self.currentGlobalIndex = 0

    def loadPage(self,index=-1):
        if index<0: index = self.currentGlobalIndex
        if self.folio!=None:
            mla,A = self.folio.getSubItems(index)
            self.currentLevel = mla
            self.windowItems = A
        return self.currentLevel,self.windowItems

    def __iter__(self):
        yield 'index', self.currentGlobalIndex

    def loadData(self,data):
        self.currentGlobalIndex = data['index']

    # return ContentItem object
    def findGlobalRecord(self,recId):
        for r in self.folio.contents:
            if r.recordID==recId:
                return r
        return None

    # returns index withon local array windowItems
    def findLocalIndex(self,record=-1):
        if record>=0:
            for i in range(len(self.windowItems)):
                if self.windowItems[i].recordID == record:
                    return i
        return -1


class MergeTexts:
    def __init__(self):
        self.oldFolio = FolioBuild('../../fff-out', 'Folio-2014')
        self.newFolio = FolioBuild('../../vb2019', 'Folio-2019')
        self.mergeDataFile = self.newFolio.mergeFile
        self.folios = [self.oldFolio, self.newFolio]
        self.oldWindow = ContentWindow(self.oldFolio)
        self.newWindow = ContentWindow(self.newFolio)
        self.history = []
        self.findStack = []
        self.lastIndexOfFind = 0
        self.matrix = None
        self.matrix_init = False

    def __iter__(self):
        yield 'oldFolio', dict(self.oldFolio)
        yield 'newFolio', dict(self.newFolio)
        yield 'oldWindow', dict(self.oldWindow)
        yield 'newWindow', dict(self.newWindow)

    def initialSetup(self):
        for f in self.folios:
            f.checkFiles()
        for f in self.folios:
            f.loadLevels()

    def pushToHistory(self,a,b):
        self.history.append((a,b))

    def popFromHistory(self):
        if len(self.history)>0:
            self.oldWindow.currentGlobalIndex = self.history[-1][0]
            self.newWindow.currentGlobalIndex = self.history[-1][1]
        if len(self.history)>1:
            del self.history[-1]

    def saveData(self):
        with open(self.mergeDataFile,'wt',encoding='utf-8') as wf:
            wf.write(json.dumps(dict(self), indent=2))

    def loadData(self):
        if os.path.exists(self.mergeDataFile):
            with open(self.mergeDataFile,'rt',encoding='utf-8') as rf:
                data = json.load(rf)
                self.oldWindow.loadData(data['oldWindow'])
                self.newWindow.loadData(data['newWindow'])
                self.oldFolio.loadData(data['oldFolio'])
                self.newFolio.loadData(data['newFolio'])

    def compareLevels(self):
        self.oldFolio.compareLevels(self.newFolio)
        self.newFolio.compareLevels(self.oldFolio)

    def printColor(self,item=None):
        if item==None:
            print('\033[0m',end='')
        elif item.foreignRecordID<0:
            color = CLR_WHITE
            if item.group == CI_GROUP_NEW:
                color = CLR_YELLOW
            elif item.group == CI_GROUP_DELETED:
                color = CLR_RED
            print(f'\033[38;5;{color}m',end='')
        elif item.foreignRecordID>=0:
            color = CLR_GREEN
            print(f'\033[38;5;{color}m',end='')
        else:
            pass

    def printCurrentItem(mt):
        mla,A = mt.oldWindow.loadPage()
        mlb,B = mt.newWindow.loadPage()
        mt.printDualPage(mla,A,mlb,B)

    def printDualPage(mt,mla,A,mlb,B):
        if mla!=mlb:
            print("Different levels in items:")
        try:
            print('{:>45}'.format(mt.oldFolio.contents[mt.oldWindow.currentGlobalIndex]), end='')
            print('{:>45}'.format(mt.newFolio.contents[mt.newWindow.currentGlobalIndex]))
            print('-'*90)
        except:
            pass
        for i in range(max(len(A),len(B))):
            if i<len(A):
                k = f'a{i}'
                mt.oldWindow.screenKeys[k] = i
                mt.printColor(A[i])
                print('{:<3} {:<40} '.format(k, A[i].text[:40]), end='')
                mt.printColor()
            else:
                print(' ' * 45, end='')
            if i<len(B):
                k = f'b{i}'
                mt.newWindow.screenKeys[k] = i
                mt.printColor(B[i])
                print('{:<3} {:<40} '.format(k,B[i].text[:40]), end='')
                mt.printColor()
            else:
                print(' ' * 45, end='')
            print()

    def getContentItemBySymbol(self,symbol):
        if symbol in self.oldWindow.screenKeys:
            idx = self.oldWindow.screenKeys[symbol]
            return self.oldWindow.windowItems[idx]
        if symbol in self.newWindow.screenKeys:
            idx = self.newWindow.screenKeys[symbol]
            return self.newWindow.windowItems[idx]
        return None

    def getContentPairByIndexes(self,ia,ib):
        return self.oldFolio.contents[ia],self.newFolio.contents[ib]

    def getContentPairBySymbol(self,symbol):
        itemNew = None
        itemOld = None
        if symbol in self.oldWindow.screenKeys:
            idx = self.oldWindow.screenKeys[symbol]
            itemOld = self.oldWindow.windowItems[idx]
            itemNew = self.newWindow.findGlobalRecord(itemOld.foreignRecordID)
        if symbol in self.newWindow.screenKeys:
            idx = self.newWindow.screenKeys[symbol]
            if idx<0 or idx >= len(self.newWindow.windowItems):
                print(self.newWindow.windowItems)
                print('idx=', idx)
            itemNew = self.newWindow.windowItems[idx]
            itemOld = self.oldWindow.findGlobalRecord(itemNew.foreignRecordID)
        return itemOld,itemNew

    def autoMerge(self,A=None,B=None):
        if A==None: A = self.oldWindow.windowItems
        if B==None: B = self.newWindow.windowItems
        for i in range(len(A)):
            if A[i].group != CI_GROUP_DEFAULT: continue
            minl = 1000
            minrec = -1
            minlev = -1
            for j in range(len(B)):
                if B[j].group != CI_GROUP_DEFAULT: continue
                if B[j].foreignRecordID>=0: continue
                l = self.levenshtein(A[i].text, B[j].text)
                if l<minl:
                    minl = l
                    minrec = j
                    minlev = B[j].level
                elif l==minl and B[j].level==A[i].level:
                    minrec = j
                    minlev = B[j].level
            if minrec >= 0 and minl < 5:
                self.linkRecordsIdx(i,minrec,A,B)

    def levenshtein(self,seq1, seq2, limitMin=5.0):
        size_x = len(seq1) + 1
        size_y = len(seq2) + 1
        if abs(size_x - size_y)>=int(limitMin):
            return limitMin
        if not self.matrix_init:
            self.matrix = np.zeros ((size_x, size_y))
            self.matrix_init = True
        sh = self.matrix.shape
        if sh[0]<size_x or sh[1]<size_y:
            self.matrix = np.zeros((size_x,size_y))
        self.matrix.fill(0.0)
        matrix = self.matrix
        for x in range(size_x):
            matrix [x, 0] = x
        for y in range(size_y):
            matrix [0, y] = y

        for x in range(1, size_x):
            maxmin = 1000
            for y in range(1, size_y):
                if seq1[x-1] == seq2[y-1]:
                    matrix [x,y] = min(
                        matrix[x-1, y] + 1,
                        matrix[x-1, y-1],
                        matrix[x, y-1] + 1
                    )
                else:
                    matrix [x,y] = min(
                        matrix[x-1,y] + 1,
                        matrix[x-1,y-1] + 1,
                        matrix[x,y-1] + 1
                    )
                maxmin = min(maxmin,matrix[x,y])
            if maxmin>=limitMin:
                return limitMin
        #print (matrix)
        return (matrix[size_x - 1, size_y - 1])

    # this will simply set foreignRecordID in both items in new and old list
    # but in case there already is some foreignRecordID set, then we have to
    # clear the link in oposite list, since we need to avoid duplicity
    def linkRecordsIdx(self,oidx,nidx, A=None, B=None):
        if A==None: A = self.oldWindow.windowItems
        if B==None: B = self.newWindow.windowItems
        if oidx>=0 and oidx<len(A) and nidx>=0 and nidx<len(B):
            if A[oidx].foreignRecordID >= 0:
                pid = self.FindItemWithRecordId(B, A[oidx].foreignRecordID)
                if pid!=None: pid.foreignRecordID = -1
            A[oidx].foreignRecordID = B[nidx].recordID
            if B[nidx].foreignRecordID >= 0:
                pid = self.FindItemWithRecordId(A, B[nidx].foreignRecordID)
                if pid!=None: pid.foreignRecordID = -1
            B[nidx].foreignRecordID = A[oidx].recordID

    def FindItemWithRecordId(self,array,recId):
        for a in array:
            if a.recordID==recId:
                return a
        return None

    def FindIncompletePage3(self,sA,sB,type=0):
        index = -1
        for item in self.newFolio.contents:
            if item.globalIndex<=self.lastIndexOfFind:
                continue
            if item.group==CI_GROUP_DEFAULT and item.foreignRecordID<0:
                index = item.globalIndex
                arr = self.newFolio.getParents(self.newFolio.contents[index].recordID,startIndex=index)
                old_rec_id = arr[-1].foreignRecordID
                if old_rec_id < 0:
                    continue
                old_ci = self.newWindow.findGlobalRecord(old_rec_id)
                self.findStack = arr
                self.lastIndexOfFind = index
                return old_ci.globalIndex,arr[-1].globalIndex


    def FindIncompletePage(self,sA,sB,type=0):
        if type==0: self.findStack = [ self.newFolio.contents[sB] ]
        #print(f'===== in FindIncompletePage {sA} - {sB} ====================')
        al,ai = self.oldFolio.getSubItems(sA)
        bl,bi = self.newFolio.getSubItems(sB)
        if al==None or bl==None:
            return None,None
        if al!=bl:
            #print(f'         Unequal levels {al} <-> {bl} (starting with {sA},{sB})')
            pass
        #self.printDualPage(al,ai,bl,bi)
        #print('----------------------------------------')
            #return sA,sB
        for item in bi:
            if item.group==CI_GROUP_DEFAULT and item.foreignRecordID<0:
                #print(f'   Unassigned record {item}')
                return sA,sB
        for item in bi:
            if item.group!=CI_GROUP_DEFAULT: continue
            item_old = self.FindItemWithRecordId(ai,item.foreignRecordID)
            if item_old==None:
                #print('    not found equivalent for record:', dict(item))
                return sA,sB
            #print(f'Trying {item_old} <=> {item}')
            #print(f'> {item}')
            self.findStack.append(item)
            s1,s2 = self.FindIncompletePage(item_old.globalIndex,item.globalIndex,type=1)
            if s1!=None and s2!=None:
                return s1,s2
            del self.findStack[-1]
        return None,None

    def autoMergeFull(self,symbol=None,oldgi=None,newgi=None):
        s1 = s2 = None
        if symbol!=None:
            s1,s2 = self.getContentPairBySymbol(symbol)
            if s1==None or s2==None:
                return
            oldgi = s1.globalIndex
            newgi = s2.globalIndex
            self.findStack = [ s2 ]
        elif oldgi==None or newgi==None:
            return
        else:
            s1,s2 = self.getContentPairByIndexes(oldgi,newgi)
        al,ai = self.oldFolio.getSubItems(oldgi)
        bl,bi = self.newFolio.getSubItems(newgi)
        if al==None or bl==None:
            return
        print(f'Merging {s1} with {s2}')
        self.autoMerge(ai,bi)
        for item in bi:
            self.findStack.append(item)
            #print('\r ', end='')
            #for stack_item in self.findStack:
            #    print(stack_item.text, ' ', end='')
            #print('         ', end='')
            if item.group==CI_GROUP_DEFAULT and item.foreignRecordID>=0:
                item_old = self.FindItemWithRecordId(ai,item.foreignRecordID)
                if item_old!=None:
                    self.autoMergeFull(oldgi=item_old.globalIndex,newgi=item.globalIndex)
            del self.findStack[-1]

    def get_history_map(self):
        recs = [[-1,-1] for a in range(self.newFolio.maxRecord+1)]
        # go through content and set record mappings
        assigned = [False] * (self.oldFolio.maxRecord + 1)
        #recs = [-1,-1] * (self.newFolio.maxRecord + 1)

        for cidx in range(len(self.oldFolio.contents)-1,-1,-1):
            ci = self.oldFolio.contents[cidx]
            if ci.foreignRecordID>=0:
                tidx = ci.foreignRecordID
                recs[tidx][0] = ci.recordID
                assigned[ci.recordID] = True
                if ci.subStart < ci.subEnd:
                    for nidx in range(ci.subStart,ci.subEnd+1):
                        tidx += 1
                        if tidx<0 or tidx>self.newFolio.maxRecord:
                            continue
                        if recs[tidx][0]>0: break
                        if assigned[nidx]: break
                        recs[tidx][1] = nidx
                        assigned[nidx] = True

        for nidx in range(len(recs)-2):
            if recs[nidx][0]>0 and recs[nidx+1][0]==-1 and recs[nidx+2][0]==recs[nidx][0]+2:
                recs[nidx+1][1]=recs[nidx][0]+1

        return recs

    def get_future_map(self):
        recs = [-1] * (self.oldFolio.maxRecord+1)
        # go through content and set record mappings
        assigned = [False] * (self.newFolio.maxRecord + 1)

        for cidx in range(len(self.oldFolio.contents)-1,-1,-1):
            ci = self.oldFolio.contents[cidx]
            if ci.foreignRecordID>=0:
                recs[ci.recordID] = ci.foreignRecordID
                assigned[ci.foreignRecordID] = True
                if ci.subStart < ci.subEnd:
                    tidx = ci.foreignRecordID
                    for nidx in range(ci.subStart,ci.subEnd+1):
                        tidx += 1
                        if tidx<0 or tidx>self.oldFolio.maxRecord:
                            continue
                        if recs[nidx]>0: break
                        if assigned[tidx]: break
                        recs[nidx] = tidx
                        assigned[tidx] = True

        for nidx in range(len(recs)-2):
            if recs[nidx]>0 and recs[nidx+1]==-1 and recs[nidx+2]==recs[nidx]+2:
                recs[nidx+1]=recs[nidx]+1

        return recs


    def export(self):
        with open(self.newFolio.historyRecordsFile,'wt',encoding='utf-8') as wb:
            for i,a in enumerate(self.get_future_map()):
                print(f'{i}\t{a}',file=wb)

load_existing = False

mt = MergeTexts()
mt.initialSetup()

if os.path.exists(mt.mergeDataFile):
    a = input('Do you want to load existing merge file? (y/n):')
    a = a.lower() + 'y'
    if a[0]=='y': load_existing = True

if load_existing:
    mt.loadData()
    mt.oldWindow.currentGlobalIndex = 0
    mt.newWindow.currentGlobalIndex = 0
else:
    mt.compareLevels()
    for f in mt.folios:
        f.loadContents()

cmds = ''
carr = []
while cmds != 'exit':
    print('------------------------------------------')
    mt.printCurrentItem()
    cmds = input('>')
    cmdsarr = cmds.split(';')
    for cmd in cmdsarr:
        carr = cmd.strip().split(' ')
        if len(carr)==0: continue
        if cmd=='auto':
            mt.autoMerge()
        elif cmd=='save':
            mt.saveData()
        elif cmd=='back':
            mt.popFromHistory()
        elif cmd=='export':
            mt.export()
        elif cmd=='top':
            mt.oldWindow.currentGlobalIndex = 0
            mt.newWindow.currentGlobalIndex = 0
            mt.oldWindow.loadPage()
            mt.newWindow.loadPage()
        elif carr[0]=='new':
            for m in carr[1:]:
                if m=='all':
                    for a in mt.newWindow.windowItems:
                        a.group = CI_GROUP_NEW
                elif m=='rest':
                    for a in mt.newWindow.windowItems:
                        if a.foreignRecordID<0:
                            a.group = CI_GROUP_NEW
                else:
                    ci = mt.getContentItemBySymbol(m)
                    if ci!=None: ci.group = CI_GROUP_NEW
        elif carr[0]=='reset':
            for m in carr[1:]:
                if m=='all':
                    for a in mt.oldWindow.windowItems:
                        a.group = CI_GROUP_DEFAULT
                    for a in mt.newWindow.windowItems:
                        a.group = CI_GROUP_DEFAULT
                else:
                    ci = mt.getContentItemBySymbol(m)
                    if ci!=None: ci.group = CI_GROUP_DEFAULT
        elif carr[0]=='delete':
            for m in carr[1:]:
                if m=='all':
                    for a in mt.oldWindow.windowItems:
                        a.group = CI_GROUP_DELETED
                else:
                    ci = mt.getContentItemBySymbol(m)
                    if ci!=None: ci.group = CI_GROUP_DELETED
        elif len(carr)==3:
            if carr[1]=='=':
                oidx = -1
                nidx = -1
                if carr[0] in mt.oldWindow.screenKeys and carr[2] in mt.newWindow.screenKeys:
                    oidx = mt.oldWindow.screenKeys[carr[0]]
                    nidx = mt.newWindow.screenKeys[carr[2]]
                elif carr[2] in mt.oldWindow.screenKeys and carr[0] in mt.newWindow.screenKeys:
                    oidx = mt.oldWindow.screenKeys[carr[2]]
                    nidx = mt.newWindow.screenKeys[carr[0]]
                mt.linkRecordsIdx(oidx,nidx)
        elif len(carr)==2:
            if carr[0]=='merge':
                mt.autoMergeFull(symbol=carr[1])
            elif carr[0]=='q':
                print('quest---')
                a,b = mt.getContentPairBySymbol(carr[1])
                if a != None and b!=None:
                    print(str(b))
                    a,b = mt.FindIncompletePage(a.globalIndex,b.globalIndex)
                    if a!=None and b!=None:
                        mt.history = []
                        mt.pushToHistory(0,0)
                        for item in mt.findStack[:-1]:
                            if item.foreignRecordID>=0 and item.recordID>=0:
                                item_old = mt.oldWindow.findGlobalRecord(item.foreignRecordID)
                                mt.pushToHistory(item_old.globalIndex,item.globalIndex)
                            print(item)
                        mt.oldWindow.currentGlobalIndex = a
                        mt.newWindow.currentGlobalIndex = b
            elif carr[0]=='go':
                a,b = mt.getContentPairBySymbol(carr[1])
                if a!=None and b!=None:
                    mt.pushToHistory(mt.oldWindow.currentGlobalIndex, mt.newWindow.currentGlobalIndex)
                    mt.oldWindow.currentGlobalIndex = a.globalIndex
                    mt.newWindow.currentGlobalIndex = b.globalIndex
                else:
                    print('Item must be linked to oposite folio in order to be able to go into it.')
                if True:
                    pass
                elif carr[1] in mt.oldWindow.screenKeys:
                    print('found in old folio')
                    cin = mt.oldWindow.screenKeys[carr[1]]
                    ci = mt.oldWindow.windowItems[cin]
                    if ci.foreignRecordID<0:
                        print('Item must be linked to oposite folio in order to be able to go into it.')
                    elif ci.subStart>0:
                        mt.pushToHistory(mt.oldWindow.currentGlobalIndex, mt.newWindow.currentGlobalIndex)
                        mt.oldWindow.currentGlobalIndex = ci.globalIndex
                        ci2 = mt.newWindow.findGlobalRecord(ci.foreignRecordID)
                        print(f'for {ci.foreignRecordID} found global index {ci2}')
                        mt.newWindow.currentGlobalIndex = ci2.globalIndex
                    else:
                        print('Not able to go into item.')
                elif carr[1] in mt.newWindow.screenKeys:
                    print('found in new folio')
                    cin = mt.newWindow.screenKeys[carr[1]]
                    ci = mt.newWindow.windowItems[cin]
                    if ci.foreignRecordID<0:
                        print('Item must be linked to oposite folio in order to be able to go into it.')
                    elif ci.subStart>0:
                        mt.pushToHistory(mt.oldWindow.currentGlobalIndex, mt.newWindow.currentGlobalIndex)
                        mt.newWindow.currentGlobalIndex = ci.globalIndex
                        ci2 = mt.oldWindow.findGlobalRecord(ci.foreignRecordID)
                        print(f'for {ci.foreignRecordID} found global index {ci2}')
                        mt.oldWindow.currentGlobalIndex = ci2.globalIndex
                    else:
                        print('Not able to go into item.')
