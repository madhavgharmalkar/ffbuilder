
class RKKeySet:
    def __init__(self):
        self.nextId = 1
        self.map = {}


    def addObject(self,str):
        if str not in self.map:
            self.map[str] = self.nextId
            self.nextId+=1

    def idForKey(self,str):
        retVal = self.nextId
        if str not in self.map:
            self.map[str] = retVal
            self.nextId += 1
        else:
            retVal = self.map[str]
        return retVal

    def keys(self):
        return list(self.map.keys())
