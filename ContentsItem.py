


class ContentsItem:
    def __init__(self):
        self.title = ''
        self.record = 0
        self.parent = 0
        self.level = 0
        self.simpletitle = ''
        self.subtext = ''
        self.children=[]
        self.recordEnd = 0
        self.writen=False
        self.fullDump = False
        self.ref_type = 'c'
    def setWriten(self):
        self.writen=True
        if self.level>=7 and len(self.children)>0:
            for c in self.children:
                c.setWriten()
    def addChild(self,child):
        self.children.append(child)
    def Print(self,indent=0):
        if len(self.children)==0 and indent==0:
            return
        for i in range(indent):
            print('   ', end='')
        print('Title: ', self.title, 'rec:', self.record, 'lev:', self.level)
        for c in self.children:
            c.Print(indent=indent+1)
    def SetRecordEnds(self,recordEnd):
        length = len(self.children)
        if length==0: return
        for i in range(length-1):
            self.children[i].recordEnd = self.children[i+1].record-1
        self.children[-1].recordEnd = recordEnd
        for c in self.children:
            c.SetRecordEnds(c.recordEnd)
    def Entry(self):
        if len(self.children)==0: return None
        return [0,0,self.record,self.recordEnd,self.parent,self.Bytes()]
    def AddTextToByteArray(self,text):
        tb = text.encode()
        array = len(tb).to_bytes(4,byteorder='little',signed=False)
        return array + tb
    def CanAddChildren(self):
        return len(self.children)>0 and self.level>=7
    def Bytes(self,recurrent=True):
        self.writen=True
        array = b'{'
        array += b'R'
        ref = ''
        if self.fullDump:
            ref = 't:{}'.format(self.record)
        else:
            ref = 'c:{}'.format(self.record)
        array += self.AddTextToByteArray(ref)
        array += b'T'
        array += self.AddTextToByteArray(self.title)
        #array += b'L'
        #array += self.level.to_bytes(4,byteorder='little',signed=False)
        if recurrent and len(self.children)>0:
            array += b'['
            for c in self.children:
                array += c.Bytes(recurrent=self.fullDump)
            array += b']'
        array += b'}'
        return array
    def Print(self,recurrent=True,level=1):
        self.writen=True
        print('  ' * level, end='')
        if self.fullDump:
            print('t:{} '.format(self.record), end='')
        else:
            print('c:{} '.format(self.record), end='')
        print(self.title, end='')
        print('   L:', self.level)
        if recurrent and len(self.children)>0:
            for c in self.children:
                c.Print(recurrent=c.fullDump,level=level+1)
    def CountHierarchicalChildren(self):
        count=0
        if self.level<7:
            count+=1
        for c in self.children:
            count += c.CountHierarchicalChildren()
        return count
    def GetChildMinLevel(self):
        minLevel = 100
        for c in self.children:
            if minLevel>c.level:
                minLevel=c.level
        if minLevel==100:
            minLevel=-1
        return minLevel
    def SetFulldumpFlag(self,enforce=False):
        if len(self.children)==0:
            self.fullDump=True
        elif self.level>=7:
            self.fullDump=True
            for c in self.children:
                c.SetFulldumpFlag(enforce=True)
        elif self.CountHierarchicalChildren()<25:
            for c in self.children:
                c.SetFulldumpFlag(enforce=True)
        elif enforce:
            self.fullDump=True
            for c in self.children:
                c.SetFulldumpFlag(enforce=True)
        else:
            for c in self.children:
                c.SetFulldumpFlag()
