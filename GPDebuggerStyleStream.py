
class GPDebuggerStyleStream:
    def __init__(self):
        self.file = None

    def writeText(self,str):
        self.file.write(str)
        
