from io import StringIO
import logging
import datetime
import os
import os.path

from FlatFileUtils import *
from RKSortedList import RKSortedList
from RKKeySet import RKKeySet
from FontGroups import changeFontName,fontGroupFromFontNameInt, VBFB_FONTGROUP_BALARAM, VBFB_FONTGROUP_DEVANAGARI, VBFB_FONTGROUP_SANSKRIT, VBFB_FONTGROUP_BENGALI, VBFB_FONTGROUP_WINDGDINGS, VBFB_FONTGROUP_RMDEVA
import GPDebugger
import GPTagHelper
import Flat
import uni2deva
import rmdeva2uni
import indevr2uni


CURM_NONE = 0
CURM_TEXT = 1
CURM_NOTE = 2

kStackMax     = 64
kContStripMax = 240

OUTPUT_UNICODE = 1

log = logging.getLogger('builder')

def balaramToOemSize(uniChar):
    balaram2oemSize = [ 0,    1,   2,   3,  4,   5,   6,   7,   8,   9,  10,  11,  12,  13,  14,  15, 16,  17,  18,  19, 20,  21,  22,  23,  24,  25,  26,  27,  28,  29,  30,  31, 32,  32,  32,  32, 32,  32,  32,  32,  32,  32,  32,  32,  32,  32,  46,  32, 48,  49,  50,  51, 52,  53,  54,  55,  56,  57,  32,  32,  32,  32,  32,  32, 32,  65,  66,  67, 68,  69,  70,  71,  72,  73,  74,  75,  76,  77,  78,  79, 80,  81,  82,  83, 84,  85,  86,  87,  88,  89,  90,  32,  32,  32,  32,  32, 32,  97,  98,  99,100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112,113, 114, 115,116, 117, 118, 119, 120, 121, 122,  32,  32,  32,  32,  32, 32,  32,  32,  32,  32,  32,  32,  32,  32,  32,  32,  32, 32,  32,  32,  32, 32,  32,  32,  32,  32,  32,  32,  32,  32,  32,  32,  32,  32,  32,  32,  32, 32,  32,  32,  32,  32,  32,  32,  32,  32,  32,  97,  32, 105,  32,  32,  32, 32,  32,  32,  32,  32,  32,  32,  32,  32,  32, 117,  32,  32,  32,  32,  32, 109, 97,  97,  97,  97, 114,  32, 115, 117, 105, 101, 110, 110, 105, 111, 110, 100, 115, 100, 111,  97, 111, 116,  32,  32, 104, 117,  32,117, 121, 32,  108, 109,  97,  97,  97,  97, 114,  32, 115, 114, 105,  32, 110, 110, 105,  32, 110, 32, 115, 100, 111,  32, 111, 116,  32,  32, 104, 117, 108, 117, 121,  32, 108, 0,   0,   0,   0 ]

    if uniChar < 0 or uniChar > 255:
        return 32
    return balaram2oemSize[uniChar]

def sanskritTimesToUnicode(uniChar):
    sanskritTimes2Unicode = [ 257, 7693, 0x201a, 7717, 0x201e, 299, 7735, 108, 7745, 7749, 7751, 0x2039, 0x152, 7771, 7773, 347, 7779, 0x2018, 0x2019, 0x201c, 0x201d, 0x2022, 0x2013, 0x2014, 7789, 363, 256, 0x203a, 0x153, 7692, 7716, 298, 160, 161, 7734, 163, 7744, 7748, 7750, 167, 168, 169, 170, 171, 7770, 7772, 346, 175, 176, 7778, 178, 179, 180, 7788, 362, 183, 184, 185, 186, 187, 188, 189, 190, 191 ]
    if uniChar < 128: return uniChar
    if uniChar > 191: return uniChar
    return sanskritTimes2Unicode[uniChar - 128]

def bengaliToUnicode(uniChar):
    if (uniChar < 33):
        return uniChar
    return 0xf000 + uniChar

def wingdingsToUnicode(uniChar):
    if uniChar == '\\':
        return 0x0950
    elif uniChar == 167:
        return 0x25fe
    elif uniChar == 10 or uniChar == 13:
        return 32
    elif uniChar == 74:
        return 0x263a
    elif uniChar == 92:
        return 0x0950
    print("Wingdings char used:", uniChar)
    return 32

def balaramToUnicode(uniChar):
    mconv = [ 128, 129, 0x201a, 0x192, 0x201e, 0x2026, 0x2020, 0x2021, 136, 0x2030, 138, 0x2039, 0x152, 141, 142, 143, 144, 0x2018, 0x2019, 0x201c, 0x201d, 0x2022, 0x2013, 0x2014, 152, 153, 154, 0x203a, 0x153, 157, 158, 159, 160, 161, 162, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175, 176, 177, 178, 179, 180, 181, 182, 0x2219, 184, 0x131, 186, 187, 188, 189, 190, 191, 7744, 193, 194, 195, 256, 7770, 198, 346, 7772, 298, 202, 7750, 7748, 205, 206, 209, 208, 7778, 7692, 211, 212, 213, 7788, 215, 216, 7716, 218, 219, 362, 221, 222, 7734, 7745, 225, 226, 227, 257, 7771, 230, 347, 7773, 299, 234, 7751, 7749, 237, 238, 241, 240, 7779, 7693, 243, 244, 245, 7789, 247, 248, 7717, 250, 7737, 363, 253, 254, 7735, ]
    if (uniChar < 128):
        return uniChar
    if (uniChar > 255):
        return 32
    return mconv[uniChar - 128]


def dd(dict,k,v):
    if not dict: return v
    if k not in dict: return v
    return dict[k]

class VBFolioBuilder:
    def __init__(self,directory):
        self.fileInfo = ''
        self.rawChars = ''
        self.currFields = {}
        self.definedObjects = {}
        self.contRoot = []
        self.temparrStyles = []
        self.wordList = RKSortedList()
        self.contentArray = None
        self.contStrips = [None] * kContStripMax
        self.linkRefs = []
        self.levelMapping = [i for i in range(kContStripMax)]
        self.lastLevelRecord = [-1] * kContStripMax
        self.strHelper = ''
        self.strBuff = ''
        self.levels = []
        self.spanClass = ''
        self.whiteSpaces = [' ', '\t', '\n', '\r']
        self.strInsertA = ''
        self.contentDict = {}
        self.contentTaggedItems = {}
        self.records = []
        self.notes = []
        self.recordStack = []
        self.contentStack = []
        self.speedFontGroupStyle = {}
        self.speedFontNameStyle = {}
        self.speedFontGroupName = {}
        self.targetHtmlRec = HtmlString()
        self.flagSub = False
        self.flagSup = False
        self.flagSpan = False
        self.commentText = False
        self.inclusionPathIndex = 0
        self.includesIndex = 1
        self.bCharToBuff = True
        self.fontGroup = 0
        self.tagCount = 0
        self.currentRecordID = 0
        self.textSizeMultiplier = 1.0
        self.previousFontGroup = 0
        self.shouldFlush = 0
        self.supressIndexing = False
        self.excludedQueryLinks = []
        self.fileTableDocInfo = None
        self.fileTableTexts = None
        self.fileTableObjects = None
        self.fileTableGroups = None
        self.fileTableGroupsMap = None
        self.fileTableLevels = None
        self.fileTablePopup = None
        self.fileTableJumplinks = None
        self.fileTableStyles = None
        self.fileTableStylesDetail = None
        self.levels = []
        self.currentRecordID = 1
        self.progressMax = 0.0
        # this enables style name replacement for all occurences
        self.safeStringReplace = {}
        self.paraUsageCounter = {}
        self.speedFontGroupStyle = {}
        self.speedFontNameStyle = {}
        self.speedFontGroupName = {}
        self.contentDict = {}
        self.lastContentItemInserted = {}
        self.groupMap = RKKeySet()
        self.stpdefs = {}
        self.inputPath = ''
        self.linkTagStarted = False
        self.lastInlinePopup = 1
        self.unrecognizedTags = []

    def __del__(self):
        self.closeDumpFiles()

    def fontGroupFromFontName(self,fname):
        if fname in self.speedFontGroupName:
            return self.speedFontGroupName[fname]

        number = fontGroupFromFontNameInt(fname)
        self.speedFontGroupName[fname] = number
        return number

    def fontNameFromStyle(self,sname):
        if sname in self.speedFontNameStyle:
            return self.speedFontNameStyle[sname]
        str = self.fontNameFromStyleInt(sname)
        if str:
            self.speedFontNameStyle[sname] = str
        return str

    def fontNameFromStyleInt(self,sname):
        for dict in self.temparrStyles:
            if dict['name'] == sname:
                if 'format' in dict and 'font-family' in dict['format']:
                    return dict['format']['font-family']
                break
        return None

    def fontGroupFromStyle(self,fname):
        if fname in self.speedFontGroupStyle:
            return self.speedFontGroupStyle[fname]
        number = self.fontGroupFromStyleInt(fname)
        self.speedFontGroupStyle[fname] = number
        return number

    def fontGroupFromStyleInt(self,sname):
        if sname=="Bengro":
            return VBFB_FONTGROUP_BENGALI
        fontName = self.fontNameFromStyle(sname)
        if fontName == None:
            return VBFB_FONTGROUP_BALARAM
        return self.fontGroupFromFontName(fontName)

    def createLinkRef(self,str):
        ret = len(self.linkRefs) + 1
        linkRefs.append({
            'linkid': ret,
            'query': str
        })
        return ret

    #=======================================================
    # Tag acceptance functions

    def acceptTagArray(self,tagArr,tagStr):
        if tagArr == None or len(tagArr)==0: return
        count = len(tagArr)
        str = tagArr[0]
        if str=="AS" or str=="AU" or str=="RM" or str=="SU" or str=="InclusionPath":
            self.strBuff=''
            self.bCharToBuff = True
            return
        elif str=="/AS" or str=="/AU" or str=="/RM" or str=="/SU":
            self.fileTableDocInfo.write("{}\t{}\t{}\n".format(str[1:], self.strBuff, 0))
            self.bCharToBuff = False
            return
        elif str=="PR" or str=="DQ" or str=="Collection" or str=="SortKey":
            self.fileTableDocInfo.write("{}\t{}\t{}\n".format(str, tagArr[2], 0))
        elif str=="CollectionName":
            self.fileInfo += "CNAME={}\n".format(tagArr[2])
            self.fileTableDocInfo.write("{}\t{}\t{}\n".format(str, tagArr[2], 0))
        elif str.casefold()=="key":
            self.fileInfo += "KEY={}\n".format(tagArr[2])
            self.fileTableDocInfo.write("{}\t{}\t{}\n".format(str, tagArr[2], 0))
        elif str=="CH":
            self.acceptChar(int(tagArr[2]))
        elif str.casefold()=="injectionpath":
            # this is actually the same tag as InclusionPath but difference is that
            # InclusionPath tag is writen in source file as
            #     <InclusionPath>... text ... </InclusionPath>
            # while InjectionPath is written as:
            #     <InjectionPath:"....text....">
            self.fileTableDocInfo.write("{}\t{}\t{}\n".format("InclusionPath", tagArr[2], inclusionPathIndex))
            self.inclusionPathIndex+=1
        elif str.casefold()=="inclusionpath":
            self.strBuff=''
            self.bCharToBuff = True
        elif str.casefold()=="/inclusionpath":
            self.bCharToBuff = False
            self.fileTableDocInfo.write("{}\t{}\t{}\n".format("InclusionPath", strBuff, inclusionPathIndex))
            inclusionPathIndex+=1
        elif str.casefold()=="includes":
            self.fileInfo.write("INCLUDES={}\n", tagArr[2])
            self.fileTableDocInfo.write("{}\t{}\t{}\n".format("Includes", tagArr[2], includesIndex))
            includesIndex+=1
        elif str=="AP":
            pass
        elif str=="BP":
            pass
        elif str=="BK":
            pass
        elif str=="BC":
            if count == 1 or tagArr[2]=="DC":
                pass
        elif str=="BR":
            pass
        elif str=="BD-":
            pass
        elif str=="BD":
            pass
        elif str=="BH":
            d = self.currentRecord['bh'] = self.currentPlainLength
        elif str=="EH":
            d = self.currentRecord['eh'] = self.currentPlainLength
        elif str=="BD+":
            #[self startCharTag:"font-weight" data:"bold"]
            pass
        elif str=='CD':
            pass
        elif str=='CD+':
            pass
        elif str=='CD-':
            pass
        elif str in ["UN", "UN+", "UN-"]:
            pass
            #[self startCharTag:"text-decoration" data:"none"]
        elif str=="SO-":
            #[self startCharTag:"text-decoration" data:"none"]
            pass
        elif str=="SO":
            #[self endCharTag:"text-decoration"]
            pass
        elif str=="SO+":
            #[self startCharTag:"text-decoration" data:"line-through"]
            pass
        elif str=="HD-":
            #[self startCharTag:"visibility" data:"visible"]
            pass
        elif str=="HD":
            pass
        elif str=="HD+":
            pass
        elif str=="CM":
            self.commentText = True
        elif str=="/CM":
            self.commentText = False
        elif str=="CR":
            pass
        elif str=="CS":
            paraName = tagArr[2]
            if paraName in self.safeStringReplace:
                paraName = self.safeStringReplace[paraName]
            self.currentPlainAppend('<CS:"{}">'.format(paraName))
        elif str=="/CS":
            pass
        elif str=="DF":
            for i in range(2,7,4):
                if len(tagArr) > i+2:
                    if tagArr[i]=="FT":
                        self.fileTableDocInfo.write("DefaultFontFamily\t{}\t{}\n".format(tagArr[i+2], 0))
                    elif tagArr[i]=="PT":
                        self.fileTableDocInfo.write("DefaultFontSize\t{}\t{}\n".format(tagArr[i+2], 0))
        elif str=="DP":
            d = self.recordWillStartRead(str)
            if count == 7:
                d['width'] = tagArr[2]
                d['height'] = tagArr[4]
                d['title'] = tagArr[6]
            elif count == 3:
                d['title'] = tagArr[2]
            else:
                d['title'] = ''
        elif str=="/DP":
            self.restoreCurrentTarget()
        elif str=="FO" or str=="HE":
            self.commentText = True
        elif str=="/FO" or str=="/HE":
            self.commentText = False
        elif str=='FD':
            pass
        elif str=='/FD':
            pass
        elif str=="FC":
            pass
        elif str=="FT":
            if count == 1:
                self.fontGroup = self.previousFontGroup
                self.currentPlainAppend('<FT>')
            else:
                fontName = tagArr[2]
                if 'fonts' not in self.currentRecord:
                    self.currentRecord['fonts'] = []
                self.currentRecord['fonts'].append(fontName)
                self.previousFontGroup = self.fontGroup
                self.fontGroup = self.fontGroupFromFontName(fontName)
                self.currentPlainAppend('<FT:"{}">'.format(changeFontName(fontName)))
        elif str=="HR":
            #[self.currentText appendFormat:"<br>"];
            pass
        elif str=="GR":
            grpId = self.groupMap.idForKey(tagArr[2])
            self.fileTableGroups.write("{}\t{}\n".format(grpId, self.currentRecordID))
        elif str=="HS":
            #[self.currentText appendFormat:"&nsbp;"];
            pass
        elif str=="IT-":
            #[self startCharTag:"font-style" data:"normal"];
            pass
        elif str=="IT":
            #[self endCharTag:"font-style"]
            pass
        elif str=="IT+":
            pass
        elif str=="JD":
            o = tagArr[2].replace('\'','-')
            self.fileTableJumplinks.write("{}\t{}\n".format(o, self.currentRecordID))
        elif str=="JU":
            pass
        elif str=="LT":
            d = self.currentRecord
            self.restoreCurrentTarget()
            self.currentPlainAppend("<PX:\"{}\",\"{}\">".format(d["pwLinkStyle"], d["title"]))
            self.linkTagStarted = True
        elif str=="LH":
            pass
        elif str=='LW':
            pass
        elif str=='KT':
            pass
        elif str=='KT+':
            pass
        elif str=='KT-':
            pass
        elif str=="IN":
            pass
        elif str=="LE" or str=="PA":
            obj = {}
            form = {}
            form["margin-bottom"] = "0pt"
            form["margin-top"] = "0pt"
            GPTagHelper.readParaFormating(tagArr, 4, form)
            GPTagHelper.readCharFormating(tagArr, form)
            obj["format"] = form
            obj["cat"] = str
            paraName = tagArr[2]
            obj["originalName"] = paraName
            if str=="PA" and paraName in self.safeStringReplace:
                paraName = self.safeStringReplace[paraName]
            obj["substitutedName"] = paraName
            name = Flat.stringToSafe(paraName, str)
            obj["name"] = name
            self.temparrStyles.append(obj)
            #[self.currentRecord setObject:name forKey:"styleName"]
        elif str=="LN":
            idx = 2
            self.levels = []
            for idx in range(2,count,2):
                originalLevelName = tagArr[idx]
                sx = Flat.stringToSafe(originalLevelName, "LE")
                levelDict = {'original': originalLevelName,
                    'safe': sx,
                    'index': int(idx/2)}
                self.fileTableLevels.write("{}\t{}\t{}\n".format(int(idx/2), originalLevelName, sx))
                self.levels.append(levelDict)
        elif str in ['OU', 'OU-', 'OU+']:
            pass
        elif str=="OB":
            # !!!!!!!
            # must remain here after removing production of HTML strings
            #
            ob_type = tagArr[2]
            ob_name = tagArr[4]
            ob_width = None
            ob_height = None
            if (count > 6): ob_width = tagArr[6]
            if (count > 8): ob_height = tagArr[8]
            ob_type = self.definedObjects[ob_name]
            s = f'<OB:"{ob_type}";"{ob_name}"'
            if (count > 6): s += f";{ob_width}"
            if (count > 8): s += f";{ob_height}"
            s += ">"
            self.currentPlainAppend(s)
            return
        elif str=="OptimizeStyles":
            #self.saveStylesRefactoring
            pass
        elif str=="OD":
            objectName = tagArr[4]
            objectFile = tagArr[8]
            #objectType = tagArr[6]
            fullFilePath = os.path.join(self.inputPath, objectFile.replace('\\','/'))
            f1,e1 = os.path.splitext(objectFile)
            extension = GPTagHelper.getMIMETypeFromExtension(e1)
            self.fileTableObjects.write("{}\t{}\t{}\n".format(objectName, fullFilePath, extension))
            self.definedObjects[objectName] = extension
        elif str=="PT":
            if (count == 1):
                #[self endCharTag:"font-size"]
                pass
            else:
                #ptSizeDescr = tagArr[2]
                #[self startCharTag:"font-size" data:[NSString stringWithFormat:"{}pt", ptSizeDescr]]
                pass
        elif str=="PW":
            dict = self.recordWillStartRead(str)
            dict['title'] = ''
            dict['pwLinkStyle'] = "Popup"
            if (count > 2):
                dict['pwLinkStyle'] = tagArr[2]
            if (count > 4):
                dict['width'] = tagArr[4]
            if (count > 6):
                dict['height'] = tagArr[6]
            if (count > 8):
                dict['title'] = tagArr[8]
            self.lastInlinePopup += 1
            dict['title'] = "InlinePopupText_{}".format(self.lastInlinePopup)
        elif str=="QL" or str=="EN":
            #self.finishLink
            #[self pushLinkStack:str]
            #query = tagArr[4]
            query = tagArr[4]

            GPDebugger.writeTag(str, query)
            GPDebugger.newerTags.append(query)
            #[self createLinkRef:query]
            #[self.currentText appendFormat:"<a name=\"loc\">"]

            afterTest = True

            if afterTest and query not in self.excludedQueryLinks:
                self.currentPlainAppend(tagStr.buffer)
                self.linkTagStarted = True
        elif str=="PX":
            #self.finishLink
            #[self pushLinkStack:str]
            #NSDictionary * dict = [self findPopupByName:tagArr[4]]
            #[self.currentText appendFormat:"<a class=\"{}\" href=\"vbase:#popup/0\">",  tagArr[2]#, dict["id"] ]
            self.linkTagStarted = True
        elif str=="DL" or str=="ML" or str=="PL" or str=="WW":
            #self.finishLink
            #[self pushLinkStack:str]
            GPDebugger.writeTag(str, tagArr[4])
            self.linkTagStarted = True
        elif str=="/DL" or str=="/ML" or str=="/JL" or str=="/PX" or str=="/OL" or str=="/PL" or str=="/PW" or str=="/WW":
            #lastLinkTag = self.peekLinkStack
            #self.finishLink
            self.linkTagStarted = True
        elif str=="/QL" or str=="/EN":
            if self.linkTagStarted:
                self.currentPlainAppend("<{}>".format(str))
                self.linkTagStarted = True
        elif str=="EL":
            if (self.linkTagStarted):
                self.currentPlainAppend("<{}>".format(str))
                self.linkTagStarted = False
        elif str=="JL":
            #self.finishLink
            #[self pushLinkStack:str]
            self.currentPlainAppend(tagStr.buffer.replace('\'',''))
            self.linkTagStarted = True
        elif str=="RO":
            #self.finishHtmlText
            #[self.currentText appendFormat:"<tr>"]
            #self.curr_rows++
            #self.curr_columns=0
            pass
        elif str in ['PN', '/PN']:
            pass
        elif str=="PS":
            paraName = tagArr[2]
            if paraName in self.safeStringReplace:
                paraName = self.safeStringReplace[paraName]

            safeString = Flat.stringToSafe(paraName, "PA")

            if safeString not in self.paraUsageCounter:
                self.paraUsageCounter[safeString] = GPMutableInteger()
            self.paraUsageCounter[safeString].increment()
            self.currentClass = safeString
            self.currentRecord['styleName'] = safeString
            self.fontGroup = self.fontGroupFromStyle(safeString)
            self.currentPlainAppend("<PS:\"{}\">".format(paraName))

            font = self.fontNameFromStyle(safeString)
            if font:
                if 'fonts' in self.currentRecord:
                    self.currentRecord['fonts'].append(font)
                else:
                    self.currentRecord['fonts'] = [font]
        elif str=="RD":
            dict = self.recordWillStartRead(str)

            previousFontGroup = 0
            strLevel = None
            strItem = None
            if count == 3:
                strLevel = tagArr[2]
            elif count == 5:
                if tagArr[2]=="ID":
                    pass
                elif tagArr[2]=="CH":
                    strLevel = tagArr[4]
                elif tagArr[4]=="CH":
                    strLevel = tagArr[2]
            elif count == 7:
                if tagArr[2]=="ID":
                    strLevel = tagArr[6]
            elif count == 9:
                if tagArr[2]=="ID" and tagArr[-1]=="CH":
                    strLevel = tagArr[6]

            if strLevel:
                #if (self.safeStringReplace[strLevel])
                #    strLevel = self.safeStringReplace[strLevel]
                safeString = Flat.stringToSafe(strLevel, "LE")
                dict['styleName'] = safeString
                dict['level'] = self.getLevelIndex(safeString)
                dict['levelName'] = safeString
                self.fontGroup = self.fontGroupFromStyle(safeString)

                font = self.fontNameFromStyle(safeString)
                if font:
                    if 'fonts' in dict:
                        dict['fonts'].append(font)
                    else:
                        dict['fonts'] = [font]
        elif str in ['SH', 'SH-', 'SH+']:
            pass
        elif str=="LV":
            paraName = tagArr[2]
            #if ([self.safeStringReplace objectForKey:paraName:
            #    paraName = self.safeStringReplace[paraName]
            safeString = Flat.stringToSafe(paraName, "LE")

            dict = self.currentRecord
            dict['levelName'] = safeString
            self.fontGroup = self.fontGroupFromStyle(safeString)
            self.currentPlainAppend(f'<LV:"{safeString}">')
            font = self.fontNameFromStyle(safeString)
            if font:
                if 'fonts' in self.currentRecord:
                    self.currentRecord['fonts'].append(font)
                else:
                    self.currentRecord['fonts'] = [font]
        elif str=='LS':
            pass
        elif str=="SD":
            if count == 1 or tagArr[2]=="True":
                pass
        elif str=="ST":
            obj = {}
            form = {}
            paraName = tagArr[2]
            obj["originalName"] = paraName
            if paraName in self.safeStringReplace:
                paraName = self.safeStringReplace[paraName]
            obj["substitutedName"] = paraName
            name = Flat.stringToSafe(paraName, tagArr[4])
            GPTagHelper.readCharFormating(tagArr, form)
            obj["format"] = form
            obj["cat"] = str
            obj["name"] = name
            self.temparrStyles.append(obj)
        elif str=="PD":
            obj = {}
            form = {}
            paraName = tagArr[2]
            obj["originalName"] = paraName
            if paraName in self.safeStringReplace:
                paraName = self.safeStringReplace[paraName]
            obj["substitutedName"] = paraName
            name = Flat.stringToSafe(paraName, str)
            GPTagHelper.readCharFormating(tagArr, form)
            obj["format"] = form
            obj["cat"] = str
            obj["name"] = name
            self.temparrStyles.append(obj)
        elif str=="SP":
            pass
        elif str=="SB":
            pass
        elif str=="/SS":
            pass
        elif str=="TB":
            pass
        elif str=="TA":
            GPDebugger.writeTag(str, GPDebugger.fileLocationPlain)
        elif str=="CE":
            pass
        elif str=="/CE":
            pass
        elif str=="/TA":
            pass
        elif str=="TT":
            self.fileInfo += "TT={}\n".format(tagArr[2])
            self.fileTableDocInfo.write("{}\t{}\t0\n".format("TT", tagArr[2]))
            today = datetime.datetime.now()
            dateTimeStamp = today.strftime('%Y.%m.%d.%H%M')
            self.fileTableDocInfo.write("{}\t{}\t0\n".format("BUILD", dateTimeStamp))
            dateTimeStamp = today.strftime('%m/%d %Y %H:%M')
            self.fileTableDocInfo.write("{}\t{}\t0\n".format("DATE", dateTimeStamp))
        elif str=='TS':
            pass
        else:
            if str not in self.unrecognizedTags:
                self.unrecognizedTags.append(str)
                log.warning("--------------------------------------------------")
                log.warning("Unrecognized tag: {}".format(tagArr))

    def acceptChar(self,rfChar):
        if self.commentText: return
        convertedChar = ''

        if self.fontGroup == VBFB_FONTGROUP_SANSKRIT:
            convertedChar = chr(sanskritTimesToUnicode(rfChar))
        elif self.fontGroup == VBFB_FONTGROUP_BALARAM:
            convertedChar = chr(balaramToUnicode(rfChar))
        elif self.fontGroup == VBFB_FONTGROUP_WINDGDINGS:
            convertedChar = chr(wingdingsToUnicode(rfChar))
        elif self.fontGroup == VBFB_FONTGROUP_BENGALI:
            convertedChar = chr(bengaliToUnicode(rfChar))
        elif self.fontGroup == VBFB_FONTGROUP_DEVANAGARI:
            convertedChar = uni2deva.NormalizeChar(rfChar)
        elif self.fontGroup == VBFB_FONTGROUP_RMDEVA:
            convertedChar = uni2deva.NormalizeChar(rfChar)

        # we need to duplicate < in order to convert it to flat file notation
        if convertedChar == '<': convertedChar += '<'
        if self.bCharToBuff:
            self.strBuff += convertedChar
        else:
            self.rawChars += convertedChar

    def acceptCharEnd(self):
        if len(self.rawChars)==0: return
        str = None
        if self.fontGroup == VBFB_FONTGROUP_DEVANAGARI:
            str = indevr2uni.Indevr2Unicode(self.rawChars)
            #print(self.rawChars, str)
        elif self.fontGroup == VBFB_FONTGROUP_RMDEVA:
            str = rmdeva2uni.RMDeva2Unicode(self.rawChars, normalize=False)
            #print(self.rawChars, str)
        else:
            str = self.rawChars

        self.currentPlainAppend(str)
        self.rawChars = ''

    def saveStylesExamples(self):
        i = 0
        exported = []
        with self.openDumpFile('styles-examples.html') as examples:
            examples.write("<html><head><title>Styles Examples</title><link href=\"styles.css\" type=text/css rel=stylesheet></head><body><h1><a href=\"by-font/index.html\">Fonts</a> | Styles</h1><p><table border=1>\n")
            for dict in self.temparrStyles:
                if not dict or 'name' not in dict: continue
                styleName = dict["name"]
                if styleName in exported: continue
                if styleName not in self.paraUsageCounter: continue
                counter = self.paraUsageCounter[styleName]
                if counter.value == 0: continue

                examples.write("<tr><td width=200px><a href=\"./by-style/{}.html\">{}</a></td><td>{}</td><td><p class=\"{}\">Lorem ipsum textum examples<br>haribol - Hare Rama this is some example of some dummy text, but what can be done?</p></td></tr>\n".format(styleName, styleName, counter.value, styleName))
                exported.append(styleName)

            # finishing examples
            examples.write("</table></body></html>\n")


    def cleaningStyles(self):
        for dict in self.temparrStyles:
            if dict:
                if 'format' in dict and len(dict['format']) > 0:
                    dictFormat = dict["format"]
                    if 'font-family' in dictFormat:
                        fontName = dictFormat["font-family"]
                        newValue = changeFontName(fontName)
                        if newValue=="Times" or newValue == "Helvetica":
                            del dictFormat["font-family"]
                        else:
                            dictFormat['font-family'] = newValue
                            if newValue != 'Times' and newValue == fontName:
                                log.info("Font in Styles - {}", newValue)

                    if 'text-align' in dictFormat and dictFormat['text-align'] in ['left', 'justify']:
                        del dictFormat["text-align"]

                    if 'font-size' in dictFormat:
                        fontSize = dictFormat["font-size"]
                        size = 0
                        if fontSize.endswith('pt'):
                            size = int(fontSize[:-2])
                            if size > 0:
                                if size == 14:
                                    del dictFormat["font-size"]
                                else:
                                    newValue = '{:d}%'.format(int(size*100/14))
                                    dictFormat['font-size'] = newValue
                                    if 'line-height' not in dictFormat:
                                        dictFormat["line-height"] = "120%"
                            else:
                                log.info("font size = {}, size = %d", fontSize, size)
                        else:
                            log.info("font size = {}, size = %d", fontSize, size)

    def saveStylesObject(self):
        with self.openDumpFile('styles.css') as strStyles:
            exported = []

            self.cleaningStyles()

            print("started Generating Styles")
            for i,dict in enumerate(self.temparrStyles):
                if 'name' not in dict: continue
                styleName = dict["name"]
                if styleName in exported: continue

                self.fileTableStyles.write("{}\t{}\n".format((i+1), styleName))

                if 'format' in dict and len(dict['format']) > 0:
                    dictFormat = dict["format"]
                    exported.append(styleName)
                    strStyles.write('.{} {{\n'.format(styleName))
                    for key,value in dictFormat.items():
                        self.fileTableStylesDetail.write("{}\t{}\t{}\n".format((i+1), key, value))
                        if ' ' not in value:
                            strStyles.write("  {}:{};\n".format(key,value))
                        else:
                            strStyles.write("  {}:\"{}\";\n".format(key,value.replace('"','\\"')))
                    strStyles.write('}\n')
            print("done Generating Styles")


    def saveAllPopups(self):
        print('Save all popups....')
        for d in self.notes:
            self.fileTablePopup.write("{}\t{}\t{}\n".format(dd(d,"title",''), dd(d,'className',''), d['plain'].getvalue()))
        print("Done - Saving Popups")

    def saveDebugRecord(self, d, htmlString=None):
        GPDebugger.writeText(d['plain'].getvalue(), dd(d,'styleName',''), d)

    def saveAllRecords(self):
        print('Saving all record...')
        target = HtmlString()
        for d in self.records:
            #levelName = dd(d,'levelName','')
            self.saveDebugRecord(d, htmlString=target)
        print("Done - Saving Records")

    def saveFolio(self):
        self.saveStylesObject()
        self.saveStylesExamples()
        self.saveAllRecords()
        self.saveAllPopups()
        print('save groups...')
        for key in self.groupMap.keys():
            print("{}\t{}".format(key, self.groupMap.idForKey(key)), file=self.fileTableGroupsMap)

    def closeDumpFiles(self):
        self.closeDumpFile(self.fileTableDocInfo)
        self.closeDumpFile(self.fileTableTexts)
        self.closeDumpFile(self.fileTableObjects)
        self.closeDumpFile(self.fileTableGroups)
        self.closeDumpFile(self.fileTableGroupsMap)
        self.closeDumpFile(self.fileTableLevels)
        self.closeDumpFile(self.fileTablePopup)
        self.closeDumpFile(self.fileTableJumplinks)
        self.closeDumpFile(self.fileTableStyles)
        self.closeDumpFile(self.fileTableStylesDetail)

    def openDumpFile(self,fileName):
        filePath = os.path.join(GPDebugger.dumpDirectory,fileName)
        return open(filePath,'wt',encoding='utf-8')

    def closeDumpFile(self,pfile):
        if pfile:
            pfile.close()

    def acceptStart(self):
        self.temparrStyles = []
        self.definedObjects = {}
        self.contentArray = []
        self.contentTaggedItems = []

        print("Started - Folio Building")
        self.tagCount = 0
        self.inclusionPathIndex = 1
        self.linkTagStarted = True

        tBuild = str(datetime.datetime.now())
        self.fileInfo += "TBUILD={}\n".format(tBuild)

        self.fileTableDocInfo = self.openDumpFile("docinfo.txt")
        self.fileTableTexts = self.openDumpFile("texts.txt")
        self.fileTableObjects = self.openDumpFile("objects.txt")
        self.fileTableGroups = self.openDumpFile("groups_detail.txt")
        self.fileTableGroupsMap = self.openDumpFile("groups.txt")
        self.fileTableLevels = self.openDumpFile("levels.txt")
        self.fileTablePopup = self.openDumpFile("popup.txt")
        self.fileTableJumplinks = self.openDumpFile("jumplinks.txt")
        self.fileTableStyles = self.openDumpFile("styles.txt")
        self.fileTableStylesDetail = self.openDumpFile("styles_detail.txt")

        self.fileTableDocInfo.write("{}\t{}\t{}\n".format("TBUILD", tBuild, 0))

    def acceptEnd(self):
        print("OK End of import")
        self.recordDidEndRead()
        self.definedObjects = None

    #pragma mark -
    #pragma mark Paragraph Managemenet

    def restoreCurrentTarget(self):
        #self.finishHtmlText
        self.recordStack = self.recordStack[:-1]
        if self.currentClassDefined:
            fontGroup = self.fontGroupFromStyle(self.currentClass)

    def recordWillStartRead(self, strType):
        self.flagSub = True
        self.flagSup = True
        self.flagSpan = True

        # ends current paragraph
        if len(self.recordStack) > 0 and self.recordStack[-1] != None:
            if strType == "RD":
                # previous record should be finished
                self.recordDidEndRead()

        dict = {'type': strType, 'plain': StringIO() }

        if strType=="RD":
            self.records.append(dict)
            self.currentRecordID+=1
            dict['id'] = self.currentRecordID
            self.recordStack = [dict]
        elif strType=="DP":
            self.notes.append(dict)
            #<DP:Width,Height,"Title"> . . . </DP>
            self.recordStack.append(dict)
        elif strType=="PW":
            self.notes.append(dict)
            self.recordStack.append(dict)
            #<PW:Style Name,Width,Height,"Title">
            # .... (Popup Window Text) ...
            # <LT>
            # .... (Link Text) ...
            # </PW>
            #<PX:Style,"Title"> . . . </PX>
        else:
            self.recordStack.append(dict)

        dict['fileLoc'] = GPDebugger.fileLocation
        if len(self.records) > 100:
            for i in range(0,95):
                self.saveDebugRecord(self.records[i], self.targetHtmlRec)
            self.records = self.records[95:]

        return dict

    #
    # save record to file foTxMain
    #
    def recordDidEndRead(self):
        d = self.currentRecord
        styleName = dd(d,"styleName",'')
        levelName = dd(d,"levelName",'')

        self.fileTableTexts.write("{}\t{}\t{}\t{}\n".format(d["id"], d['plain'].getvalue(), levelName, styleName))

        if self.currentRecordID % 200 == 0:
            print("\rRecord", self.currentRecordID, end='           ')

    #pragma mark -
    #pragma mark getter functions

    @property
    def currentRecord(self):
        if len(self.recordStack)==0:
            return None
        return self.recordStack[-1]

    @property
    def currentClassDefined(self):
        cr = self.currentRecord
        if not cr: return False
        return 'className' in cr

    @property
    def currentPlainLength(self):
        dict = self.currentRecord
        if not dict or 'plain' not in dict: return 0
        return len(dict['plain'].getvalue())

    @property
    def currentPlain(self):
        dict = self.currentRecord
        if not dict: return None
        if 'plain' not in dict: dict['plain'] = StringIO()
        return dict['plain']

    def currentPlainAppend(self,str):
        cp = self.currentPlain
        if cp != None:
            cp.write(str)
        else:
            print('Text:', str)
            print('Not writen in record stack: ', self.recordStack)

    @property
    def currentRecordType(self):
        return self.currentRecord['type']

    @property
    def currentClass(self):
        dict = self.currentRecord
        if not dict: return ''
        if 'className' not in dict:
            dict['className'] = ''
            return ''
        return dict['className']

    @currentClass.setter
    def currentClass(self,value):
        d = self.currentRecord
        if d: d['className'] = value

    @property
    def currentLevel(self):
        dict = self.currentRecord
        if 'levelName' not in dict:
            dict['levelName'] = ''
            return ''
        return dict['levelName']

    def getCurrStyleIndex(self,rec):
        if 'levelName' in rec:
            return self.getStyleIndex(rec['levelName'])
        return self.getStyleIndex(rec['className'])

    def getStyleIndex(self,styleName):
        for i,dict in enumerate(self.temparrStyles):
            if dict['name'] == styleName: return i
        return -1

    def getLevelIndex(self,levelName):
        if levelName == None or len(levelName) == 0:
            return -1

        for dict in self.levels:
            if dict["safe"].casefold() == levelName.casefold():
                return int(dict['index'])
        return -1

    def htmlTextToOEMHtmlText(self,origHtmlText):
        return FlatFileUtils.toOEM(origHtmlText)
