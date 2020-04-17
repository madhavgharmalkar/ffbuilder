import unicodedata as ucd
from io import StringIO


spaceTags = ["<CR>", "<HR>", "<HS>", "<SP>", "<SB>", "</SS>", "<TA>", "</TA>", "<CE>", "</CE>", "<GP>", "<GD>", "<GM>", "<GT>", "<GQ>", "<GI>", "<GA>", "<GF>"]


def toOEM(data):
    word = ''
    for a in data:
        if a=='Ñ':
            a='N'
        elif a=='ñ':
            a='n'
        base = ord(a)
        while base>255:
            nc = ucd.decomposition(a)
            parts = nc.split(' ')
            if parts[0]=='<compat>':
                a = ''
                for p in parts[1:]:
                    try:
                        ip = int(p,16)
                        if ip<256: a += chr(ip)
                    finally:
                        pass
                break
            elif parts[0]=='':
                a = ' '
                break
            else:
                base = int(parts[0],16)
                a = chr(base)
        word += a
    return word

def parseTags(text):
    status = 0
    last = 0
    removeRange = False
    for i in range(len(text)):
        if status == 0:
            if text[i] == '<':
                status = 1
        elif status == 1:
            if text[i] == '<':
                status = 0
            else:
                start = i-1
                status = 2
        elif status == 2:
            if text[i] == '>':
                end = i
                removeRange = True
                status = 0
            elif text[i] == '"':
                status = 3
        elif status == 3:
            if text[i] == '"':
                status = 4
        elif status == 4:
            if text[i] == '"':
                status = 3
            elif text[i] == '>':
                end = i
                removeRange = True
                status = 0

        if removeRange:
            yield 'text', text[last:start]
            yield 'tag', text[start:end+1]
            last = end + 1
            removeRange = False
    if last<len(text):
        yield 'text',text[last:]

def removeTagsAndNotes(str):
    if not str or len(str)==0: return ''
    s = StringIO('')
    level = 0

    for tp,tx in parseTags(str):
        if tp=='text':
            if level <= 0:
                s.write(tx)
        if tp=='tag':
            if tx in spaceTags:
                if level==0:
                    s.write(' ')
            elif tx.startswith('<PW'):
                level += 1
            elif tx.startswith('<LT'):
                level -= 1
    return s.getvalue()


def removeTags(str):
    if not str: return ''
    s = StringIO()

    for tp,tx in parseTags(str):
        if tp=='text':
            s.write(tx)
        if tp=='tag' and tx in spaceTags:
            s.write(' ')
    return s.getvalue()

    text = str
    start = 0
    end = 0
    status = 0
    removeRange = True
    result = ''

    last = 0
    for i in range(len(text)):
        if status == 0:
            if text[i] == '<':
                status = 1
        elif status == 1:
            if text[i] == '<':
                status = 0
            else:
                start = i-1
                status = 2
        elif status == 2:
            if text[i] == '>':
                end = i
                removeRange = True
                status = 0
            elif text[i] == '"':
                status = 3
        elif status == 3:
            if text[i] == '"':
                status = 4
        elif status == 4:
            if text[i] == '"':
                status = 3
            elif text[i] == '>':
                end = i
                removeRange = True
                status = 0

        if removeRange:
            result += text[last:start]
            extractedTag = text[start:end+1]
            if extractedTag in spaceTags: result += ' '
            last = end + 1
            removeRange = False
    if last<len(text):
        result += text[last:]
    return result


def stringToSafe(str,tag):
    s = toOEM(str)
    result = tag + '_'
    for bi in s:
        if bi.isalpha():
            result += bi
        elif bi == ' ':
            result += '_'
        else:
            result += "_{}".format(ord(bi))
    return result


def makeContentTextFromRecord(plainText):
    contentTextCandidate = plainText

    bh = plainText.find('<BH>')
    eh = plainText.find('<EH>')

    if bh >= 0:
        if eh > bh:
            contentTextCandidate = plainText[bh + 4:eh]
        else:
            contentTextCandidate = plainText[bh + 4:]
    contentTextCandidate = contentTextCandidate.strip()
    return removeTagsAndNotes(contentTextCandidate)


def makeSimpleContentText(orig):
    bytes = toOEM(orig.lower())
    lastType = 0
    str = ''
    for i in range(len(bytes)):
        uc = bytes[i]
        if uc.isalpha():
            if lastType == 3:
                str = str[:-1] + ' '
            str += uc
            lastType = 1
        elif uc.isdigit():
            str += uc
            lastType = 2
        elif uc == '.':
            if lastType == 2:
                str += '.'
                lastType = 3
        elif uc == '-' or uc == 150:
            if lastType == 3:
                str = str[:-1] + ' '
            elif lastType == 2:
                str += '-'
                lastType = 4
            elif lastType != 6:
                str += ' '
                lastType = 6
        elif uc == '\'':
            str += '\''
            lastType = 5
        elif uc == ' ':
            if lastType == 3:
                str = str[:-1] + ' '
            elif not str.endswith(' ') and len(str)>0:
                str += " "
            lastType = 6
        else:
            if lastType != 6:
                str += ' '
                lastType = 6

    return str.rstrip()


def makeDictionaryString(aString):
    s = StringIO()
    for c in toOEM(aString):
        if c.isalnum(): s.write(c.lower())
    return s.getvalue()
