import json

class RKSortedList:
    def __init__(self,key='text'):
        self.sortingKey = key
        self.array = []
        self.modified = False
        self.keyName = ''

    #pragma mark Loading and saving file

    def writeToFile(self,fileName):
        with open(fileName,'wt',encoding='utf-8') as wf:
            wf.write(json.dumps(self.array))

    def loadFile(self,fileName):
        with open(fileName,'rt',encoding='utf-8') as rf:
            self.array = json.load(rf)

    #pragma content access

    def objectForKey(self,key,a=0,b=-1):
        if b<0: b = len(self.array)-1
        key = key.lower()
        if (b < a):
            return None

        if (a == b):
            str = self.array[a][self.keyName].lower()
            if str == key:
                return self.array[a]
            return None

        if (a == b - 1):
            str = self.array[a][self.keyName].lower()
            if str == key:
                return self.array[a]
            str = self.array[b][self.keyName].lower()
            if str == key:
                return self.array[b]
            return None

        c = int((a + b) / 2)

        str = self.array[c][self.keyName].lower()
        if str == key:
            return self.array[c]
        elif str < key:
            return self.objectForKey(key,c,b)
        else:
            return self.objectForKey(key,a,c)

    def indexForKey(self, key, a=0, b=-1):
        if b<0: b = len(self.array)-1
        if (b < a):
            return a
        r = 0
        if (a == b):
            str = self.array[a][self.keyName].lower()
            if str == key:
                return -1
            elif str < key:
                return a+1
            else:
                return a

        if (a == b - 1):
            str = self.array[a][self.keyName].lower()
            if str == key:
                return -1
            elif str > key:
                return a

            str = self.array[b][self.keyName].lower()
            if str < key:
                return b+1
            elif str == key:
                return -1
            else:
                return b

        c = int((a + b) / 2)

        str = self.array[c][self.keyName].lower()
        if str == key:
            return -1
        elif str < key:
            return self.indexForKey(key,c,b)
        else:
            return self.indexForKey(key,a,c)

    def __getitem__(self,a):
        return self.array[a]

    def count(self):
        return len(self.array)

    def addObject(self,obj):
        key = obj[self.keyName]
        i = self.indexForKey(key)
        if i < 0: return
        self.modified = True
        self.array.insert(i,obj)
