import os
import os.path
from ContentsItem import ContentsItem



if os.environ.get('FBUILD_OUT')==None:
    print('Missing environment variable FBUILD_OUT with output directory for folio building files (e.g. ../flat-output)')
    exit(0)

# working directory
output_dir = os.environ.get('FBUILD_OUT')
# input and output files
in_content_filename = os.path.join(output_dir, 'tables', 'contents.txt')
texts_filename = os.path.join(output_dir, 'tables', 'texts.txt')
out_content_filename = os.path.join(output_dir, 'data', 'contents.tbl')


'''
 Structure of content:

    LIST OF content_page


 Structure of content_page:

    content_page_entry           ; this is parent items
    LIST OF content_page_entry   ; these are child entries

 Structure of content_page_entry:


    display_text    ; this text is in Unicode and is displayed in UI
    target_ref      ; reference to target "c:258", "t:88928", "a:bg_1_1.mp3"
                    ; prefix is type of target:
                    ;    c - content page
                    ;    t - text
                    ;    a - audio
                    ;    b - bookmark
    subtext         ; some Unicode text used as description of the item,
                    ; designated to be displayed
'''

def FillContents(recs,entry):
    if not entry.fullDump:
        recs.append(entry.Entry())
        for c in entry.children:
            FillContents(recs,c)

def PrintAll(entry):
    if not entry.fullDump:
        entry.Print()
        for c in entry.children:
            PrintAll(c)

def GetTextsCount():
    maxrec = 0
    print('Counting...',end='')
    with open(texts_filename,'rt',encoding='utf-8') as rf:
        for line in rf:
            i = line.find('\t')
            if i>0:
                maxrec = max(maxrec,int(line[:i]))
    print(maxrec)
    return maxrec

def ReadContentFile():
    with open(in_content_filename,'rt',encoding='utf-8') as crfile:
        for line in crfile:
            parts = line.strip('\n').split('\t')
            if len(parts)>=4:
                yield [parts[3],int(parts[1]),int(parts[2]),int(parts[0]),'','']

def GetContentRecords():
    dict = {}
    recs = []

    # get contents from DB table
    root = ContentsItem()
    root.title = 'Contents'
    root.record = 0
    root.parent = 0
    root.level = 0
    root.simpletitle = ''
    root.subtext = ''
    dict[root.record] = root
    print('Reading contents file...')
    for con in ReadContentFile():
        ci = ContentsItem()
        ci.title = con[0]
        ci.record = con[1]
        ci.parent = con[2]
        ci.level = con[3]
        ci.simpletitle = con[4]
        ci.subtext = con[5]
        dict[ci.record] = ci
        if ci.parent in dict:
            dict[ci.parent].addChild(ci)
    dict[0].SetRecordEnds(GetTextsCount())
    dict[0].SetFulldumpFlag()

    # prepare table
    FillContents(recs,dict[0])
    #PrintAll(dict[0])
    #for c in recs:
    #    print(c)
    return recs


# write to file
#root.Print()
with open(out_content_filename,'wb') as f:
    f.write(b'GOF     CONTENT ')
    recs = GetContentRecords()
    recs[0][0] = f.tell() + 4 + 16 + len(recs)*20
    for i in range(len(recs)-1):
        recs[i][1] = len(recs[i][5])
        recs[i+1][0] = recs[i][0] + recs[i][1]
    recs[-1][1] = len(recs[-1][5])

    f.write(b'CNTARR  CONTENT ')
    f.write(len(recs).to_bytes(4,byteorder='little',signed=False))
    for b in recs:
        f.write(b[0].to_bytes(4,byteorder='little',signed=False))
        f.write(b[1].to_bytes(4,byteorder='little',signed=False))
        f.write(b[2].to_bytes(4,byteorder='little',signed=False))
        f.write(b[3].to_bytes(4,byteorder='little',signed=False))
        f.write(b[4].to_bytes(4,byteorder='little',signed=False))
    for b in recs:
        f.write(b[5])
