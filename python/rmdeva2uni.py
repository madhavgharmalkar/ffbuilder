from io import StringIO
import Flat
import uni2deva


r1 = ['&130; kra1.', '&131; gr2.', '&132; ghr2.', '&133; cr2.', '&134; jr2.', '&135; tr2.', '&136; thr2.','&137; dra1.', '&139; dhr2.', '&140; nr2.', '&141; ḹ1.', '&145; pr2.', '&146; phra1.', '&147; br2.', '&148; bhr2.', '&149; mr2.', '&150; –', '&151; —','&152; vr2.', '&153; śr2.', '&155; sr2.', '&156; hra1.', '&159; kṣr2.', '&161; kna1.', '&162; gn2.', '&163; ghn2.', '&165; tn2.', '&167; thn2.', '&168; dna1.', '&169; dhn2.', '&170; nn2.', '&171; pn2.', '&172; phna1.', '&174; bn2.', '&175; bhn2.', '&176; mn2.', '&177; vn2.', '&180; śn2.', '&181; sn2.', '&182; hna1.', '&183; kta1.', '&184; kva1.', '&186; kṣ2.', '&187; cc2.', '&191; cñ2.', '&192; jj2.', '&193; jñ2.', '&194; ñc2.', '&195; ñj2.', '&196; ṭṭa1.', '&197; ṭva1.', '&198; ḍka1.', '&199; ḍku1.', '&200; ḍkta1.', '&201; ḍkṣa1.', '&202; ḍkha1.', '&203; ḍga1.', '&204; ḍgu1.', '&205; ḍgra1.', '&206; ḍgha1.', '&207; ḍḍa1.', '&209; ḍbha1.', '&210; ḍva1.', '&211; ḍhva1.', '&212; tt2.', '&213; dga1.', '&214; dgu1.', '&216; dgra1.', '&217; dgha1.', '&218; dda1.', '&219; ddra1.', '&220; ddha1.', '&223; dba1.', '&224; dbha1.', '&225; dma1.', '&226; dya1.', '&227; dva1.', '&228; da1.', '&229; dra1.', '&230; pt2.', '&231; ru1.', '&232; rū1.', '&233; ll2.', '&234; śca1.', '&235; śla1.', '&236; śva1.', '&237; ṣṭa1.', '&238; ṣṭva1.', '&239; ṣṭha1.', '&241; stra1.', '&242; hu1.', '&243; hū1.', '&244; hṛ1.', '&245; hṇa1.', '&246; hma1.', '&247; hya1.', '&248; hla1.', '&249; hva1.', '&250; u5.', '&251; ū5.','&252; ṛ5.', '&255; ṅ9.', '[ ṛ1.', '] u5.', "' '", ') rb.', '* ḹ5.', '+ ṛ5.', ', .8.', '- -', '. .8.', '/ |', '0 0', '1 1', '2 2', '3 3', '4 4', '5 5', '6 6', '7 7', '8 8', '9 9', ': ḥ1.', '< ṁa.', '<CR> <CR>', '= r6.', '> ṁa.', '@ a1.', '@a ā1.', '@aE au1.', '@ae o1.', 'A a4.', 'B bh2.', 'C cha1.', 'C_ chru1.', 'D dh2.', 'E E5.', 'G gh2.', 'H ñ2.', 'I ī4.', 'J jh2.', 'K kh2.', 'L ī4.', 'M ṁ5.', 'N ṇ2.', 'O ū1.', 'P pha1.', 'Q ṭha1.', 'R r6.', 'S ṣ2.', 'T th2.', 'U ū5.', 'V oṁ', 'W e1.', 'We ai1.', 'X ḍha1.', 'XM#] ḍhuṁ', 'Y yc.', 'Z ṣ2.', '^ ū5.', '_ ru5.', '` rū5.', 'a a4.', 'ae o5.', 'b b2.', 'c c2.', 'd da1.', 'e e5.', 'f k2.', 'g g2.', 'h ha1.', 'i i7.', 'j j2.', 'k ka1.', 'l l2.', 'm m2.', 'n n2.', 'o u1.', 'p p2.', 'q ṭa1.', 'r ra1.', 's s2.', 't t2.', 'u u5.', 'v v2.', 'w i1.', 'w= ī1.', 'wR ī1.', 'x ḍa1.', 'y y2.', 'z ś2.', '{ ṛ5.', '| ṝ5.', '} ḷ5.', '~ ṅ9.']

formap = {
    'a1.': {
        'ī4.': 'ī1.',
        'u5.': 'u1.',
        'ū5.': 'ū1.',
        'a4.': 'ā1.',
        'ṛ5.': 'ṛ1.',
        'ṝ5.': 'ṝ1.',
        'E5.': 'ai1.',
        'u5.': 'u1.',
        'e5.': 'e1.',
        'ḷ5.': 'ḷ1.',
        'o5.': 'o1.'
    },
    'ā1.': {
        'a4.': 'ā1.',
        'E5.': 'au1.',
        'e5.': 'o1.',
        'u5.': 'u1.',
    }
}


r = [a.split(' ') for a in r1]
r.append([' ', ' '])
r.append(['$', ''])
r.append(['"', ''])
r.append(['(', ''])
r.append(['%', ''])
r.append(['#', ''])
r.append(['&amp;', ''])
r = sorted(r, key = lambda k: len(k[0]), reverse=True)

class buffer_arr:
    def __init__(self,a):
        self.arr = a
        self.idx = 0
    @property
    def next(self,offset=1):
        if self.idx<len(self.arr)-offset:
            return self.arr[self.idx+offset]
        else:
            return ''
    @next.setter
    def next(self,val):
        if self.idx<len(self.arr)-1:
            self.arr[self.idx+1] = val
    @property
    def prev(self,offset=1):
        if self.idx-offset>=0:
            return self.arr[self.idx-offset]
        else:
            return ''
    @prev.setter
    def prev(self,val):
        if self.idx-1>=0:
            self.arr[self.idx-1]=val
    @property
    def curr(self):
        if self.idx>=0 and self.idx<len(self.arr):
            return self.arr[self.idx]
        else:
            return ''
    @curr.setter
    def curr(self,val):
        if self.idx>=0 and self.idx<len(self.arr):
            self.arr[self.idx] = val
    def go(self):
        self.idx += 1
    def goback(self):
        self.idx -= 1
    def findprevend(self,ends):
        i = self.idx
        while i>=0 and i<len(self.arr):
            if self.arr[i].endswith(ends):
                return i
            i -= 1
        return -1


def RMDeva2Unicode(text, normalize=False):
    i = 0
    replaced = 0
    res = StringIO()
    arr = []
    if normalize:
        for cr in text:
            res.write(uni2deva.NormalizeChar(cr))
        text = res.getvalue()
    while i<len(text):
        found = False
        for a in r:
            k = len(a[0])
            if text[i:i+k]==a[0]:
                i += k
                if len(a[1])>0:
                    arr.append(a[1])
                found = True
                break
        if not found:
            if text[i]=='&':
                end = text.find(';',i)
                arr.append(text[i:end+1])
                i = end + 1
            else:
                arr.append(text[i])
                i += 1

    ba = buffer_arr(arr)

    replaced = 0
    ba.idx = 0
    while ba.idx<len(arr):
        if ba.curr.endswith('b.'):
            k = ba.findprevend('1.')
            if k >= 0:
                ba.arr[k] = ba.arr[k][:-3] + 'r' + ba.arr[k][-3:]
                del ba.arr[ba.idx]
                ba.goback()
                #replaced += 1
        elif ba.curr.endswith('9.'):
            k = ba.findprevend('1.')
            if k >= 0:
                ba.arr[k] = ba.curr[:-2] + ba.arr[k][1:]
                del ba.arr[ba.idx]
                ba.goback()
        elif ba.curr.endswith('2.'):
            if ba.next.endswith('1.') or ba.next.endswith('2.'):
                ba.next = ba.curr[:-2] + ba.next
                del ba.arr[ba.idx]
                ba.goback()
            elif not ba.next.endswith('.'):
                ba.curr = ba.curr[:-2] + '1.'
                ba.goback()
            elif ba.next == 'a4.':
                ba.curr = ba.curr[:-2] + 'a1.'
                del ba.arr[ba.idx+1]
                ba.goback()
            elif ba.next == 'o5.' or ba.next == 'e5.':
                ba.curr = ba.curr[:-2] + 'e1.'
                del ba.arr[ba.idx+1]
                ba.goback()
            elif ba.next == '.8.':
                ba.curr = ba.curr[:-2] + '1.'
                del ba.arr[ba.idx+1]
                ba.goback()
        ba.go()


    ba.idx = 0
    while ba.idx<len(arr):
        if ba.next.endswith('c.'):
            if ba.curr.endswith('1.'):
                ba.curr = ba.curr[:-3] + 'y' + ba.curr[-3:]
                del ba.arr[ba.idx+1]
                ba.goback()
        elif ba.curr.endswith('6.'):
            k = ba.findprevend('1.')
            if k >= 0:
                ba.arr[k] = 'r' + ba.arr[k]
                del ba.arr[ba.idx]
                ba.goback()
        elif ba.curr.endswith('a.'):
            k = ba.findprevend('1.')
            if k >= 0:
                ba.arr[k] = 'r' + ba.arr[k]
                ba.curr = ba.curr[:-2] + '1.'
                ba.goback()
                replaced += 1
        elif ba.curr.endswith('7.'):
            if ba.next.endswith('1.'):
                ba.next = ba.next[:-3] + ba.curr[:-2] + '1.'
            del ba.arr[ba.idx]
            ba.goback()
        elif ba.curr == 'ṁ5.':
            ba.curr = 'ṁ1.'
        elif ba.curr == 'ḹ5.':
            if ba.next.startswith('l'):
                ba.next = ba.curr[0] + ba.next[1:]
            del ba.arr[ba.idx]
            ba.goback()
        ba.go()


    ba.idx = 0
    while ba.idx<len(arr):
        if ba.curr.endswith('4.') or ba.curr.endswith('5.'):
            if ba.prev.endswith('1.'):
                if ba.prev[-3:] in formap:
                    crec = formap[ba.prev[-3:]]
                    if ba.curr in crec:
                        ba.prev = ba.prev[:-3] + crec[ba.curr]
                        replaced += 1
            del ba.arr[ba.idx]
            ba.goback()
        elif ba.curr.endswith('8.'):
            if ba.prev.endswith('1.'):
                ba.prev = ba.prev[:-3] + '1.'
            del ba.arr[ba.idx]
            ba.goback()
        ba.go()

    res.truncate(0)
    res.seek(0)
    for a in arr:
        if a.endswith('.'):
            if a.endswith('1.'):
                res.write(a[:-2])
        else:
            res.write(a)

    uc = uni2deva.ConvertToDevanagari(res.getvalue())

    return uc
