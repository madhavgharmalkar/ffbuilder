
gid = 0

def nextGid():
    global gid
    g = gid
    gid += 1
    return g

class ViewDir:
    def __init__(self):
        self.name = ''
        self.pid = -1
        self.subs = None

    def getChild(self,text):
        if self.subs == None:
            self.subs = []

        for vv in self.subs:
            if vv.name == text:
                return vv

        vv = ViewDir()
        vv.name = text;
        vv.pid = nextGid()
        self.subs.append(vv)
        return vv
