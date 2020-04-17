import Flat
from FlatFileUtils import FlatFileTagString
import FlatIndexer
import json
import os
import os.path
from io import StringIO


# This script serves for investigation of Devanagari paragraphs in the folio
# text.
#
# Run as:
#
#  python3 Devatrans.py
#
# Thi swill print first 3 blocks with devanagari and sanskrit transliteration

class Style:
    def __init__(self,nameStyle='',idStyle=0):
        self.name = nameStyle
        self.id = idStyle
        self.prop = {}
    def __str__(self):
        return "Name:\"{}\"; ID:{}; Data: {}".format(self.name, self.id, self.prop)

class IdMap:
    def __init__(self):
        self.arr = {}
    def get(self,s):
        if s == None: return 0
        if s in self.arr:
            return self.arr[s]
        nid = len(self.arr)+1
        self.arr[s] = nid
        return nid
    def write_to(self,f):
        dl = len(self.arr)
        f.write(dl.to_bytes(4,byteorder='little',signed=False))
        for value,key in self.arr.items():
            d = value.encode();
            dl = len(d)
            f.write(key.to_bytes(4,byteorder='little',signed=False))
            f.write(dl.to_bytes(4,byteorder='little',signed=False))
            f.write(d)

class ParserStatus:
    def __init__(self):
        self.resetFonts()
        self.lastParaStyleID = -1
    def resetFonts(self):
        self.fonts = ['Times']
    def pushFont(self,font):
        self.fonts.append(font)
    def popFont(self):
        if len(self.fonts)>1:
            del self.fonts[-1]
    def font(self):
        return self.fonts[-1]

def GetStyles(output_dir):
    styles_file_name = os.path.join(output_dir, 'tables', 'styles.txt')
    styles_det_file_name = os.path.join(output_dir, 'tables', 'styles_detail.txt')
    styles = {}
    with open(styles_file_name,'rt',encoding='utf-8') as sf:
        for line in sf:
            line = line.strip().split('\t')
            if len(line)==2:
                styles[int(line[0])] = Style(line[1],int(line[0]))

    with open(styles_det_file_name,'rt',encoding='utf-8') as sf:
        for line in sf:
            line = line.strip().split('\t')
            if len(line)==3:
                style_id = int(line[0])
                styles[style_id].prop[line[1]] = line[2]

    styles2 = {}
    for k,v in styles.items():
        styles2[v.name] = v
    return styles2


def AnalyseTag(tag,pstate,styles,dbg=False):
    tt = FlatFileTagString(tag)
    tttag = tag[1:3]
    pstate.lastParaStyleID=-1
    if tttag == 'PS':
        arr = tt.createArray()
        if dbg: print("--> PARASTYLE =", Flat.stringToSafe(arr[2],'PA'))
        safename = Flat.stringToSafe(arr[2],'PA')
        if safename in styles:
            sd = styles[safename]
            pstate.lastParaStyleID = sd.id
            if 'font-family' in sd.prop:
                pstate.pushFont(sd.prop['font-family'])
                if dbg: print("--> SET FONT =", pstate.font())
    elif tttag == 'LV':
        arr = tt.createArray()
        if dbg: print("--> PARASTYLE =", Flat.stringToSafe(arr[2],'LE'))
        safename = Flat.stringToSafe(arr[2],'LE')
        if safename in styles:
            sd = styles[safename]
            if 'font-family' in sd.prop:
                pstate.pushFont(sd.prop['font-family'])
                if dbg: print("--> SET FONT =", pstate.font())
    elif tttag == 'FT':
        arr = tt.createArray()
        if len(arr)==1:
            # only FT
            pstate.popFont()
        elif len(arr)>=3:
            pstate.pushFont(arr[2])
            if dbg: print("--> SET FONT =", pstate.font())
    else:
        return False

    return True

def GetTexts(conn,output_dir):
    # output files
    out_index_dat = os.path.join(output_dir, 'data', 'index.tbl')
    out_words_dat = os.path.join(output_dir, 'data', 'words.tbl')
    out_words_json = os.path.join(output_dir, 'tables', 'words.json')
    debug=True
    omitfonts = ['Indevr', 'Inbenb', 'Inbenr', 'Inbeno', "Inbeni"]
    RECORD_FLAG = 0x10000000
    STYLE_FLAG = 0x20000000
    styles = GetStyles(output_dir)
    #for key in styles.items():
    #    print(key)
    i = 0

    ids = IdMap()
    with open(out_index_dat,'wb') as f:
        for line in conn:
            line = line.strip('\n').split('\t')
            if len(line)!=4: continue
            d = [int(line[0]),line[1],line[2],line[3]]
            #c.execute("SELECT recid,plain,levelname,stylename FROM texts")
            #data = c.fetchmany()
            pstate = ParserStatus()
            if debug:
                print('RECORDID:', d[0])
            elif d[0]%100==0:
                print('\r Record: {}'.format(d[0]), end='')
            token_id = d[0] + RECORD_FLAG
            #print('----record---- ', token_id)
            #f.write(token_id.to_bytes(4,byteorder='little',signed=False))
            pstate.resetFonts()
            #tokens = GetTokens(d[1])
            has_deva = False
            for tag_type,t in FlatIndexer.parse(d[1]):
                if tag_type == 'tag':
                    #pass
                    AnalyseTag(t,pstate,styles)
                    #    if debug: print('       ', t)
                    #if pstate.lastParaStyleID>=0:
                    #    token_id = pstate.lastParaStyleID + STYLE_FLAG
                    #    f.write(token_id.to_bytes(4,byteorder='little',signed=False))
                else:
                    if pstate.font() in omitfonts:
                        #if debug: print('FONT:',pstate.font(), 'TOKEN:', t)
                        #token_id = ids.get(t)
                        #print(token_id, '-->', t)
                        #f.write(token_id.to_bytes(4,byteorder='little',signed=False))
                        has_deva = True
            if has_deva:
                print(f'\033[38;5;11m', end='')
                print(d, end='')
                print(f'\033[38;5;11m \033[0m')
            else:
                print(d)
            if debug and i > 5000:
                break;
            i += 1

def str2oem(text):
    s = StringIO()
    text = text.replace('<PS:"Devanagari">','')
    text = text.replace('<FD:Devanagari>','')
    text = text.replace('</FD:Devanagari>','')
    for a in text.replace('<CR>','\n'):
        if ord(a)>127:
            s.write('&{};'.format(ord(a)))
        else:
            s.write(a)
    t = s.getvalue().replace('\n', '<CR>')
    return t

def GetTexts2(conn,output_dir):
    # output files
    out_index_dat = os.path.join(output_dir, 'data', 'index.tbl')
    out_words_dat = os.path.join(output_dir, 'data', 'words.tbl')
    out_words_json = os.path.join(output_dir, 'tables', 'words.json')
    debug=True
    omitfonts = ['Indevr', 'Inbenb', 'Inbenr', 'Inbeno', "Inbeni"]
    RECORD_FLAG = 0x10000000
    STYLE_FLAG = 0x20000000
    i = 0

    block = False
    j = 0
    for line in conn:
        line = line.strip('\n').split('\t')
        if len(line)!=4: continue
        d = [int(line[0]),line[1],line[2],line[3]]
        if d[3]=='PA_Devanagari':
            print(f'\033[38;5;11m', end='')
            t = str2oem(d[1])
            print(d[0], t, end='')
            print(f'\033[38;5;11m \033[0m')
            block=True
        elif d[3]=='LE_Verse_Text' or d[3]=='PA_Uvaca_line':
            print(d[0], d[1])
            block = True
        else:
            if block:
                print('-----------------------------------------')
                block = False
                j += 1
        if debug and i > 5000:
            break;
        if debug and j>3:
            break
        i += 1


def DevaTransRun(output_dir):
    input_file = os.path.join(output_dir, 'tables', 'texts.txt')
    with open(input_file,'rt',encoding='utf-8') as conn:
        GetTexts2(conn,output_dir)

if __name__ == '__main__':
    if os.environ.get('FBUILD_OUT')==None:
        print('Missing environment variable FBUILD_OUT with output directory for folio building files (e.g. ../flat-output)')
    else:
        output_dir = os.environ.get('FBUILD_OUT')
        DevaTransRun(output_dir)
