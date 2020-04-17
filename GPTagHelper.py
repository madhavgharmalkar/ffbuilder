

#
# returns in startIndex such value
# that is assumes, that after incrementing with value 1
# index will point at next TAG
#
def readColor(tagArr,a,b=None,c=None):
    if b==None and c==None:
        return readColorB(tagArr,a)
    else:
        return readColorA(tagArr,a,b,c)

def readColorA(tagArr,prefix,startIndex,obj):
    vr = vg = vb = 0
    if startIndex < len(tagArr):
        str = tagArr[startIndex]
        if str == "DC" or str == "NO":
            return startIndex + 1
        vr = int(str)
        vg = int(tagArr[startIndex+2])
        vb = int(tagArr[startIndex+4])

        obj[prefix] = '#{:02x}{:02x}{:02x}'.format(vr,vg,vb)
        startIndex += 6
        if startIndex >= len(tagArr):
            return startIndex
        if tagArr[startIndex] == 'DC':
            return startIndex + 1
        else:
            return startIndex - 1
    return startIndex

def readColorB(tagArr,startIndex):
    strColor = ""

    if startIndex < len(tagArr):
        str = tagArr[startIndex]
        if str == "DC" or str == "NO":
            return startIndex + 1
        vr = int(str)
        vg = int(tagArr[startIndex+2])
        vb = int(tagArr[startIndex+4])
        strColor = '#{:02x}{:02x}{:02x}'.format(vr,vg,vb)
        startIndex += 6
        if startIndex >= len(tagArr):
            return strColor,startIndex
        if tagArr[startIndex] == "DC":
            startIndex += 1
        else:
            startIndex -= 1
    return strColor,startIndex

side2postfixes = {
    'AL': [''],
    'LF': ['-left'],
    'RT': ['-right'],
    'BT': ['-bottom'],
    'TP': ['-top'],
    'HZ': ['-top', '-bottom'],
    'VT': ['-right', '-left']
}

def sideTextFromAbbr(side):
    if side not in side2postfixes:
        return None
    return side2postfixes[side]

def inchToPoints(value):
    if value.endswith("pt"):
        return value
    try:
        return '{}pt'.format(int(float(value) * 72.0))
    except:
        return None

def percentValue(value):
    try:
        d = float(value)
        if d>0.3:
            return '{}%'.format(int(d*100))
    except:
        pass
    return None

def readBorderFormating(dict, prefix, side, obj):
    str=''
    if prefix: str = prefix + '_'
    str += "BR_{}_WIDTH".format(side)

    if str in dict:
        value = dict[str]
        res = ''
        val2 = inchToPoints(value)
        sides = sideTextFromAbbr(side)
        for sideitem in sides:
            key = "border{}-width".format(sideitem)
            key2 = "border{}-style".format(sideitem)
            if obj:
                obj[key] = val2
                obj[key2] = 'solid'
            if res:
                res += "{}:{};\n".format(key, val2)
                res += "{}:solid;\n".format(key2)

        str = ''
        if prefix: str = prefix + '_'
        str += "BR_{}_INSIDE".format(side)

        if str in dict:
            value = dict[str]
            val2 = inchToPoints(value)
            for sideitem in sides:
                key = "padding" + sideitem
                if obj:
                    obj[key] = val2
                if res:
                    res += "{}:{};\n".format(key, val2)

        str = ''
        if prefix:
            str = "{}_BR_FC_{}".format(prefix,side)
        else:
            str = "BR_FC_{}".format(side)
        if str in dict:
            value = dict[str]
            for sideitem in sides:
                key = "border{}-color".format(sideitem)
                if obj:
                    obj[key] = value
                if res:
                    res += "{}:{};\n".format(key, value)
    return res

fffalign2cssalign = {
    'CN': 'center',
    'RT': 'right',
    'FL': 'justify',
    'CA': 'left'
}

def alignFromString(str):
    if str not in fffalign2cssalign:
        return 'left'
    return fffalign2cssalign[str]

def readTabSpaces(dict,prefix):
    str = ''
    if prefix:
        str = prefix + '_'
    str += "TS_JU"
    if str in dict:
        value = dict[str]
        str2 = ''
        if prefix:
            str2 += prefix + "_"
        str2 += "TS_LDR"

        str = ''
        if prefix:
            str += prefix + '_'
        str += "TS_TABS"
        if str2 in dict and str in dict:
            value2 = dict[str2]
            value3 = dict[str]
            arr1 = value
            arr2 = value2
            arr3 = value3
            mset = []

            i = len(arr1)
            if len(arr1) == len(arr2) and len(arr2) == len(arr3):
                for m in range(i):
                    pass

    return mset

def getValue(dict, str, prefix, name):
    str = prefix
    str += name
    return dict[str]

fontSubx = { "Balaram": "Times",
    "Dravida": "Times",
    "scagoudy": "Times",
    "Rama-Palatino": "Times",
    "Times New Roman": "Times",
    "Tamal": "Times",
    "Rama Garamond Plus": "Times",
    "New York": "Times",
    "Bhaskar": "Times",
    "HGoudyOldStyleBTBoldItalic": "Times",
    "Poetica": "Times",
    "Shiksha": "Times",
    "Drona": "Times",
    "Sanskrit_Times": "Times",
    "Sanskrit Benguiat": "Times",
    "Palatino Sanskrit Hu 2": "Times",
    "Font13399": "Times",
    "Calibri": "Times",
    "Tahoma": "Helvetica",
    "Arial": "Helvetica",
    "Arial Unicode MS": "Helvetica",
    "Courier New": "Helvetica",
    "ScaHelvetica": "Helvetica",
    "Sanskrit-Helvetica": "Helvetica",
    "ScaOptima": "Helvetica",
}

def substitutionFontName(fname):
    if fname.startswith("Sanskrit-"):
        return "Times"
    if fname.startswith('Sca'):
        return "Times"
    if fname in fontSubx:
        return fontSubx[fname]
    return fname

def readParaFormating(dict, prefix, obj):
    value = None
    str = ''
    # AP
    value = getValue(dict,str,prefix,"_AP")
    if value:
        obj["margin-bottom"] = inchToPoints(value)
    #BP
    value = getValue(dict,str,prefix,"_BP")
    if value:
        obj["margin-top"] = inchToPoints(value)

    #JU
    value = getValue(dict,str,prefix,"_JU")
    if value:
        obj['text-align'] = alignFromString(value)

    value = getValue(dict,str,prefix,"_IN_LEFT")
    if value:
        obj['margin-left'] = inchToPoints(value)

    # IN_RIGHT
    value = getValue(dict,str,prefix,"_IN_RIGHT")
    if value:
        obj['margin-right'] = inchToPoints(value)

    # IN_FIRST
    value = getValue(dict,str,prefix,"_IN_FIRST")
    if value:
        obj['text-indent'] = inchToPoints(value)

    # LH
    value = getValue(dict,str,prefix,"_LH")
    if value:
        obj['line-height'] = inchToPoints(value)

    # LS
    value = getValue(dict,str,prefix,"_LS")
    if value:
        d = float(value)
        if d > 0.3:
            obj['line-height'] = "{}%".format(int(d*100))

    # LW
    #value = getValue(dict,str,prefix,"_LW");
    #if value:
    #   val = value + 'in'
    #   obj['width'] = '{}in'.format(value)

    # TS_
    #value = [GPTagHelper readTabSpaces:dict withPrefix:prefix inManagedObjectContext:ctx];
    #if (value) [obj addTab_spaces:value];
    # BR_
    for sd in ['AL','RT','LF','BT','TP','HZ','VT']:
        readBorderFormating(dict,prefix,sd,obj)


def appendCssStyleFromDictionary(dict):
    s = ''
    for key,value in dict.items():
        if key != 'class':
            if len(s)>0: s+=';'
            if ' ' in value:
                s += '{}:"{}"'.format(key,value)
            else:
                s += '{}:{}'.format(key,value)
    return s

def readSuperSubScript(dict,prefix,subp):
    obj=None
    str='{}_{}_VALUE'.format(prefix,subp)
    if str in dict:
        value = dict[str]
        str='{}_{}_POINT'.format(prefix,subp)
        if str in dict:
            obj = '{}pt'.format(value)
        else:
            obj = '{}in'.format(value)
    return obj

def getBoldText(num):
    i = int(num)
    if i == 0:
        return "normal"
    elif i == 1:
        return ''
    else:
        return 'bold'

def getItalicText(num):
    i = int(num)
    if i == 0:
        return "normal"
    elif i == 1:
        return ''
    return "italic"

def getHiddenText(num):
    i = int(num)
    if i == 0:
        return "inherit"
    elif i == 1:
        return ''
    return "none"

def getUnderlineText(num):
    i = int(num)
    if i == 0:
        return "normal"
    elif i == 1:
        return ''
    return "underline"

def getStrikeoutText(num):
    i = int(num)
    if i == 0:
        return "normal"
    elif i == 1:
        return 'normal'
    return "line-through"

def readFont(arrTag,idx,obj):
    if idx < len(arrTag):
        obj['font-family'] = arrTag[idx]
        idx += 1
        while idx < len(arrTag) and arrTag[idx]!=';':
            idx += 1
    return idx

def readCharFormating(arrTag,obj):
    i = 4;
    while i < len(arrTag):
        tag = arrTag[i]
        if tag == "FT":
            i = readFont(arrTag, i+2, obj)
        elif tag == "PT":
            obj['font-size'] = "{}pt".format(arrTag[i+2])
            i += 2
        elif tag == "BC":
            i = readColor(arrTag, "background-color", i+2, obj)
        elif tag == "FC":
            i = readColor(arrTag, "color", i+2, obj)
        elif tag == "BD+":
            obj['font-weight'] = "bold"
        elif tag == "BD-":
            obj["font-weight"] = "normal"
        elif tag == "IT+":
            obj["font-style"] = "italic"
        elif tag == "IT-":
            obj["font-style"] = "normal"
        elif tag == "UN+":
            obj["text-decoration"] = "underline"
        elif tag == "HD+":
            obj["visibility"] = "hidden"
        elif tag == "HD-":
            obj["visibility"] = "visible"
        elif tag == "SO+":
            obj['text-decoration'] = "line-through"
        else:
            while i < len(arrTag) and arrTag[i] != ';':
                i+=1
        i += 1

def getMIMEType(str):
    if str == "mp3file":
        return "audio/mpeg"
    if str == "AcroExch.Document":
        return "application/pdf"
    return str

def getMIMETypeFromExtension(str):
    if str == ".mp3":
        return "audio/mpeg"
    if str == ".pdf":
        return "application/pdf"
    if str == ".png":
        return "image/png"
    return str

def readIndentFormating(arrTag,startIdx,obj):
    paramName = "margin-left"
    str = inchToPoints(arrTag[startIdx])
    if not str:
        if len(arrTag) <= startIdx or arrTag[startIdx]==';':
            return startIdx
        while len(arrTag) > startIdx:
            str = arrTag[startIdx]
            if str == "LF":
                paramName = "margin-left"
            elif str == "RT":
                paramName = "margin-right"
            elif str == "FI":
                paramName = "text-indent"
            else:
                return startIdx - 1

            startIdx += 2
            if len(arrTag) <= startIdx or arrTag[startIdx] == ";":
                return startIdx
            str = inchToPoints(arrTag[startIdx])
            obj[paramName] = str
            startIdx += 1
            if len(arrTag) <= startIdx or arrTag[startIdx]==";":
                return startIdx
            startIdx += 1
    else:
        obj['margin-left'] = str
        startIdx += 1
        if len(arrTag) <= startIdx or arrTag[startIdx] == ';':
            return startIdx
        startIdx += 1
        str = inchToPoints(arrTag[startIdx])
        obj['margin-right'] = str
        startIdx += 1
        if len(arrTag) <= startIdx or arrTag[startIdx] == ';':
            return startIdx
        startIdx += 1
        str = inchToPoints(arrTag[startIdx])
        obj["text-indent"] = str

    return startIdx

def readParaFormating(arrTag,stdix,obj):
    value = None
    str = ''
    i = stdix
    while i < len(arrTag):
        tag = arrTag[i]
        if tag == "AP":
            value = inchToPoints(arrTag[i+2])
            obj['margin-bottom'] = value
            i += 2
        elif tag == "BP":
            value = inchToPoints(arrTag[i+2])
            obj['margin-top'] = value
            i += 2
        elif tag == "JU":
            value = alignFromString(arrTag[i+2])
            obj['text-align'] = value
            i +=  2
        elif tag == "SD":
            i = readColor(arrTag, "background-color", i+2, obj)
        elif tag == "LH":
            value = inchToPoints(arrTag[i+2])
            obj['line-height'] = value
            i += 2
        elif tag == "LS":
            obj['line-height'] = percentValue(arrTag[i+2])
            i += 2
        elif tag == "IN":
            i = readIndentFormating(arrTag, i+2, obj)
        elif tag == "BR":
            i = readBorders(arrTag,i+2,obj)
        else:
            while i < len(arrTag) and arrTag[i] != ';':
                i+=1
        i += 1

def readBorders(arrTag, startIndex, obj):
    side = None
    postfix = None
    value = None
    strWidth = None
    strStyle = None
    strColor = None

    while startIndex < len(arrTag):
        strWidth = "0"
        strStyle = "solid"
        strColor = ""
        side = arrTag[startIndex]
        if side == ";": return startIndex
        postfix = sideTextFromAbbr(side)
        if not postfix: return startIndex - 1
        strWidth = inchToPoints(arrTag[startIndex+2])
        startIndex += 4
        value = inchToPoints(arrTag[startIndex])
        if value:
            for postfixitem in postfix:
                obj['padding{}'.format(postfixitem)] = value
        startIndex += 1
        if startIndex >= len(arrTag): return startIndex
        startIndex += 1
        value = arrTag[startIndex]
        if value == "FC":
            startIndex += 2;
            strColor,startIndex = readColor(arrTag,startIndex)
            startIndex += 1
        else:
            strColor = ""

        for item in postfix:
            obj["border{}-width".format(item)] = strWidth
            obj["border{}-style".format(item)] = strStyle
            obj["border{}-color".format(item)] = strColor
    return startIndex
