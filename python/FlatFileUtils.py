import urllib.parse

MAKEARRAY_STATUS_DEFAULT = 0
MAKEARRAY_STATUS_START_DECISION = 1
MAKEARRAY_STATUS_QUOTE_READ = 2
MAKEARRAY_STATUS_END_QUOTE = 3
MAKEARRAY_STATUS_READ_TAG  = 4


class FlatFileUtils:
    highlighterColors = [
        None,
        "#ffff00",
        "#00ff00",
        "#00ffff",
        "#ff0000",
        "#ff00ff",
        "#ff6600",
        "#ff6699",
        "#6666ff",
        "#7f7fff",
        "#ff7f7f"
    ]

    @staticmethod
    def encodeLinkSafeString(string):
        str = urllib.parse.quote_plus(string)
        return str

    @staticmethod
    def decodeLinkSafeString(string):
        str = urllib.parse.unquote_plus(string)
        return str

    @staticmethod
    def removeTags(str):
        if str==None: return None
        text = str
        start = 0
        end = 0
        status = 0
        removeRange = 0
        removedCount = 1
        spaceTags = ["<CR>", "<HR>", "<HS>", "<SP>",
                         "<SB>", "</SS>", "<TA>", "</TA>", "<CE>",
                         "</CE>", "<GP>", "<GD>", "<GM>", "<GT>",
                         "<GQ>", "<GI>", "<GA>", "<GF>"]

        while removedCount>0:
            removedCount=0
            i=0
            while removedCount==0 and i < len(text):
                if status == 0:
                    if text[i] == '<':
                        status = 1
                elif status == 1:
                    if text[i] == '<':
                        status = 0
                    else:
                        start = i-1
                        status=2
                elif status==2:
                    if text[i]=='>':
                        end=i
                        removeRange=1
                        status=0
                    elif text[i]=='"':
                        status=3
                elif status==3:
                    if text[i]=='"':
                        status = 4
                elif status==4:
                    if text[i]=='"':
                        status=3
                    elif text[i]=='>':
                        end=i
                        removeRange=1
                        status=0

                if removeRange==1:
                    extractedTag=text[start:end]
                    if extractedTag in spaceTags:
                        text[start:end]=' '
                    else:
                        text[start:end]=''
                    removeRange=0
                    removedCount+=1

        return text

    @staticmethod
    def removeTagsAndNotes(str):
        if str==None: return None
        text = str
        start = 0
        end = 0
        status = 0
        removeRange = 0
        removedCount = 1
        pwLevel=0
        pwStart=0
        spaceTags = ["<CR>", "<HR>", "<HS>", "<SP>",
                         "<SB>", "</SS>", "<TA>", "</TA>", "<CE>",
                         "</CE>", "<GP>", "<GD>", "<GM>", "<GT>",
                         "<GQ>", "<GI>", "<GA>", "<GF>"]

        while removedCount>0:
            removedCount=0
            i=0
            while removedCount==0 and i < len(text):
                if status == 0:
                    if text[i] == '<':
                        status = 1
                elif status == 1:
                    if text[i] == '<':
                        status = 0
                    else:
                        start = i-1
                        status=2
                elif status==2:
                    if text[i]=='>':
                        end=i
                        removeRange=1
                        status=0
                    elif text[i]=='"':
                        status=3
                elif status==3:
                    if text[i]=='"':
                        status = 4
                elif status==4:
                    if text[i]=='"':
                        status=3
                    elif text[i]=='>':
                        end=i
                        removeRange=1
                        status=0

                if removeRange==1:
                    extractedTag=text[start:end]
                    if extractedTag.startswith('<PW'):
                        if pwLevel==0:
                            pwStart=start
                        pwLevel+=1
                    elif extractedTag.startswith('<LT'):
                        pwLevel-=1
                        if pwLevel==0:
                            text[pwStart:end]=''
                            removedCount+=1
                    elif pwLevel==0:
                        if extractedTag in spaceTags:
                            text[start:end]=' '
                        else:
                            text[start:end]=''
                        removedCount+=1
                    removeRange=0

        return text

    @staticmethod
    def makeDictionaryString(aString):
        str=''
        for s in aString.encode('ascii','ignore'):
            if s.isalnum():
                str += s.lower()
        return str

    @staticmethod
    def makeIndexableString(aString):
        str=''
        for s in aString.encode('ascii','ignore'):
            if s.isalnum():
                str += s.lower()
            elif s=='.' or s=='_' or s=='@':
                str += s
            else:
                str += ' '
                if str.endswith('. '):
                    str[len(str)-2:]=' '
        return str.strip()


class FlatFileTagString:
    def __init__(self,tagText=''):
        self.buffer = tagText
        self.extractedTag = ''
    def clear(self):
        self.buffer = ''
        self.extractedTag = ''

    def appendChar(self,c):
        self.buffer += chr(c)

    def appendString(self,str):
        self.buffer += str

    def buffer(self):
        return self.buffer

    def createArray(self):
        part = ''
        tagParts = []
        brackets = 0
        status = MAKEARRAY_STATUS_DEFAULT
        nextStatus = MAKEARRAY_STATUS_DEFAULT
        rd = ''

        # main import procedure
        idx = 0
        while idx < len(self.buffer):
            rd = self.buffer[idx]
            #print(status, rd)
            if status == MAKEARRAY_STATUS_DEFAULT:
                if rd == '<':
                    status = MAKEARRAY_STATUS_START_DECISION
                    nextStatus = MAKEARRAY_STATUS_DEFAULT

            elif status == MAKEARRAY_STATUS_START_DECISION:
                if rd == '<':
                    status = nextStatus
                else:
                    part += rd
                    brackets+=1
                    status = MAKEARRAY_STATUS_READ_TAG
            elif status == MAKEARRAY_STATUS_QUOTE_READ:
                if rd == '\"':
                    status = MAKEARRAY_STATUS_END_QUOTE
                else:
                    part += rd
            elif status == MAKEARRAY_STATUS_END_QUOTE:
                if rd == '\"':
                    part += '"'
                    status = MAKEARRAY_STATUS_QUOTE_READ
                else:
                    tagParts.append(part)
                    part = ''
                    idx-=1
                    status = MAKEARRAY_STATUS_READ_TAG
            elif status == MAKEARRAY_STATUS_READ_TAG:
                if rd == '<':
                    brackets+=1
                    part += '<'
                elif rd == ':' or rd == ' ' or rd == ';' or rd == ',':
                    if len(part) > 0:
                        tagParts.append(part)
                        part=''
                    if rd != ' ':
                        part=''
                        tagParts.append(rd)
                elif rd == '>':
                    brackets-=1
                    if brackets == 0:
                        if len(part) > 0:
                            tagParts.append(part)
                            part=''
                        break
                    else:
                        part += '>'
                elif rd == '"':
                    if len(part) > 0:
                        tagParts.append(part)
                        part=''
                    status = MAKEARRAY_STATUS_QUOTE_READ
                else:
                    part += rd
            idx += 1

        if len(part) > 0:
            tagParts.append(part)

        return tagParts

    def tag(self):
        if len(self.extractedTag)>0:
            return self.extractedTag

        i = self.buffer.find('<')
        if i>=0:
            i+=1
        while i<len(self.buffer):
            c = self.buffer[i]
            if c.isalpha() or c in ['+','-','/']:
                self.extractedTag+=c
                i+=1
            else:
                break
        return self.extractedTag




class HtmlStyle:
    def __init__(self):
        self._styleName = None
        self.format = {}
        self.styleNameChanged = False

    @property
    def styleName(self):
        return self._styleName

    @styleName.setter
    def styleName(self,str):
        self._styleName=str
        self.styleNameChanged=True

    def __getitem__(self,key):
        return self.format[str]

    def __setitem__(self,key,value):
        self.format[key]=value

    def __delitem__(self,key):
        del self.format[key]

    def valueForKey(self,str):
        return self.format[str]

    def setValue(self,strValue,forKey=''):
        self.format[forKey]=strValue

    def clearFormat(self):
        self.format = {}

    @property
    def styleCssText(self):
        str = ''
        for key,val in self.format.items():
            if len(str)>0: str += ';'
            if ' ' in val:
                str += '{}:{}'.format(key,val)
            else:
                str += '{}:\'{}\''.format(key,val)
        return str

    def htmlTextForTag(self,tag):
        target = '<' + tag
        if not self.styleName and len(self.styleName) > 0:
            target += f' class="{self.styleName}"'

        if len(self.format) > 0:
            target += f' style="{self.styleCssText}"'

        target += '>'
        return target

    def clear(self):
        self.format = {}
        self.styleName = None
        self.styleNameChanged = False

class HtmlStyleTracker(HtmlStyle):
    def __init__(self):
        self.formatOld = {}
        self.formatChanges = []

    def __setitem__(self,key,value):
        if key not in self.formatChanges:
            self.formatOld[key] = self.format[key]
        self.formatChanges.append(key)
        HtmlStyle.__setitem__(self,key,value)

    def __delitem__(self,key):
        if key not in self.formatChanges:
            self.formatOld[key] = self.format[key]
        self.formatChanges.append(key)
        HtmlStyle.__delitem__(self,key)

    def clearChanges(self):
        self.formatOld = dict(self.format)
        self.formatChanges = []
        self.styleNameChanged = False

    def hasChanges(self):
        return self.styleNameChanged or len(self.formatChanges)>0


class HtmlStylesCollection:
    def __init__(self):
        self.styles = []

    def addStyle(self,style):
        self.styles.append(style)
        return

    def substitutionFontName(self,fname):
        if fname=="Sanskrit-Helvetica":
            return "Helvetica"
        if fname.startswith("Sanskrit-"):
            return "Times"

        # this is when converting to Unicode Vedabase
        if fname=="ScaHelvetica" or fname=="ScaOptima":
            return "Helvetica"
        if fname.startswith("Sca"):
            return "Times"
        if fname=="Balaram" or fname=="Dravida":
            return "Times"
        if fname=="scagoudy":
            return "Times"
        # end convertion to Unicode Vedabase
        return fname

    def getMIMEType(self,str):
        if str=="mp3file":
            return "audio/mpeg"
        if str == "AcroExch.Document":
            return "application/pdf"
        return str


class HtmlString:
    def __init__(self):
        self.buffer = ''
        self.acceptText = False

    def string(self):
        return self.buffer

    def setString(self,str):
        self.buffer=str

    def clear(self):
        self.buffer = ''
        self.acceptText=False

    def addCharacter(self,chr):
        if self.acceptText:
            if chr=='<':
                self.buffer += '&gt;'
            elif chr=='>':
                self.buffer += '&lt;'
            elif chr=='&':
                self.buffer += '&amp;'
            elif ord(chr)<128:
                self.buffer += chr
            else:
                self.buffer += '&#{};'.format(ord(chr))
        return self.acceptText

    def appendString(self,str):
        if self.acceptText:
            self.buffer += str
        return self.acceptText

    def indexfOfFirstOccurenceOfTag(self,strTag):
        adjusted = '<{} '.format(strTag)
        i = self.buffer.find(adjusted)
        if i < 0:
            adjusted = '<{}>'.format(strTag)
            i = self.buffer.find(adjusted)
        return i

    def insertString(self,str,atIndex=0):
        self.buffer.insert(atIndex,str)
        return


class GPMutableInteger:
    def __init__(self):
        self.value = 0
    def increment(self):
        self.value += 1
    def decrement(self):
        self.value -= 1
    def intValue(self):
        return self.value

class FlatFileString:
    dataLinkAsButton = False
    def __init__(self,tagText=''):
        self.buffer = tagText
        self.hcParaStarted = False
        self.hcSpanStarted = False
        self.hcSup = False
        self.hcSupChanged = False
        self.hcSub = False
        self.hcSubChanged = False
        self.linkStarted = False
        self.buttonStarted = False
        self.ethDefaultExpanded = False
        self.hcPwCounter = 0
        self.hcNtCounter = 0
        self.hcTableRows = 0
        self.hcTableColumns = 0
        self.catchPwLevel = 0
        self.catchPwCounter = 0
        self.catchNtCounter = 0
        self.ethStyle = ''
        self.ethListImage = ''
        self.ethDict = {}
        self.ethStack = []
        self.dataObjectName = None
        self.validator = None

    @property
    def string(self):
        return self.buffer

    @string.setter
    def string(self,str):
        self.buffer = str

    def reset(self):
        self.hcParaStarted = False
        self.hcSpanStarted = False
        self.hcSub = False
        self.hcSup = False
        self.hcSupChanged = False
        self.hcSubChanged = False
        self.hcPwCounter = 0
        self.hcNtCounter = 0
        self.hcTableRows = 0
        self.hcTableColumns = 0
        self.catchPwLevel = 0
        self.catchPwCounter = 0
        self.catchNtCounter = 0
        self.linkStarted = False
        self.buttonStarted = False
        return

    def setString(self,str):
        self.buffer=str

    def setCatchPwCounter(self,val):
        self.catchPwCounter=val

    def setCatchPwLevel(self,val):
        self.catchPwLevel=val

    def setCatchNtCounter(self,val):
        self.catchNtCounter=val

    def checkParagraphStart(self,target,paraStyle):
        if self.hcParaStarted == False:
            self.hcParaStarted = True
        target.appendString(paraStyle.htmlTextForTag("p"))

    def processChar(self,chr,target,paraStyle,charStyle):
        self.checkParagraphStart(target,paraStyle)

        if self.hcSubChanged and not self.hcSub:
            target.appendString("</sub>")
        if self.hcSupChanged and not self.hcSup:
            target.appendString("</sup>")
        if charStyle.hasChanges():
            if self.hcSpanStarted:
                target.appendString("</span>")
                self.hcSpanStarted = False

        if charStyle.hasChanges():
            spanText = charStyle.htmlTextForTag("span")
            if spanText!= "<span>":
                target.appendString(spanText)
                self.hcSpanStarted = True
            charStyle.clearChanges()
        if self.hcSupChanged and self.hcSup:
            target.appendString("<sup>")
        if self.hcSubChanged and self.hcSub:
            target.appendString("<sub>")
        self.hcSubChanged = False
        self.hcSupChanged = False
        target.addCharacter(chr)

    def finishHtmlFormating(self,target,paraStyle,charStyle):
        if self.hcSub:
            target.appendString("</sub>")
            self.hcSub = False
        if self.hcSup:
            target.appendString("</sup>")
            self.hcSup = False
        if self.hcSpanStarted:
            target.appendString("</span>")
            self.hcSpanStarted = False

        target.appendString("</p>")
        self.hcParaStarted = False

    def sideTextFromAbbr(self,side):
        if side=='AL':
            return ['']
        if side=="LF":
            return ["-left"]
        if side=="RT":
            return ["-right"]
        if side=="BT":
            return ["-bottom"]
        if side=="TP":
            return ["-top"]
        if side=="VT":
            return ["-top", "-bottom"]
        if side=="HZ":
            return ["-right", "-left"]
        return None

    def inchToPoints(self,value):
        if value.endswith('pt'):
            return value
        try:
            return '{}pt'.format(float(value)*72.0)
        except:
            return None

    def readColor(tagArr,startIndex):
        vr = 0
        vg = 0
        vb = 0
        str = ''
        strColor = ""
        assert isinstance(startIndex,RefInt)

        if startIndex.value < len(tagArr):
            str = tagArr[startIndex.value]
            if str=="DC" or str=="False ":
                startIndex.value += 1
                return ""
            vr = int(str)
            startIndex.value += 2
            vg = int(tagArr[startIndex.value])
            startIndex.value += 2
            vb = int(tagArr[startIndex.value])

            strColor = "#{0:2x}{1:2x}{2:2x}".format(vr, vg, vb)
            assert len(strColor)==7, 'bad value for color {}'.format(strColor)
            startIndex.value +=2
            if startIndex.value >= len(tagArr):
                return strColor
            if tagArr[startIndex.value]=="DC":
                startIndex.value += 1
            else:
                startIndex.value -= 1
        return strColor

    def readBorders(self,arrTag,startIndex,obj):
        assert isinstance(startIndex,RefInt)
        assert isinstance(obj,HtmlStyle)
        side=''
        postfix=[]
        value=''

        strWidth = None
        strStyle = None
        strColor = None

        while startIndex.value < len(arrTag):
            strWidth = "0"
            strStyle = "solid"
            strColor = ""
            side = arrTag[startIndex.value]
            if side==';':
                return
            postfix = self.sideTextFromAbbr(side)
            if postfix == None:
                startIndex.value -= 1
                return
            startIndex.value += 2
            strWidth = self.inchToPoints(arrTag[startIndex.value])
            startIndex.value += 2
            value = self.inchToPoints(arrTag[startIndex.value])
            for postfixitem in postfix:
                obj["padding{}".format(postfixitem)]=value
            startIndex.value += 1
            if startIndex.value >= len(arrTag): return
            startIndex.value += 1
            value = arrTag[startIndex.value]
            if value=="FC":
                startIndex.value += 2
                strColor = self.readColor(arrTag,startIndex)
                startIndex.value += 1
            else:
                strColor = ""

            for item in postfix:
                obj["border{}-width".format(item)]=strWidth
                obj["border{}-style".format(item)]=strStyle
                obj["border{}-color".format(item)]=strColor

    def alignFromString(self,str):
        if str=="CN": return "center"
        if str=="RT": return "right"
        if str=="FL": return "justify"
        if str=="CA": return "left"
        return 'left'

    def readIndentFormating(self,arrTag,startIdx,obj):
        assert isinstance(startIndex,RefInt)
        assert isinstance(obj,HtmlStyle)
        str=''
        paramName = "margin-left"
        str = self.inchToPoints(arrTag[startIdx.value])

        if str == None:
            if len(arrTag) <= startIdx.value or arrTag[startIdx.value]==";": return
            while len(arrTag) > startIdx.value:
                str = arrTag[startIdx.value]
                if str=='LF': paramName = "margin-left"
                elif str=="RT": paramName = "margin-right"
                elif str=="FI": paramName = "text-indent"
                else:
                    startIdx.value -= 1
                    return
                startIdx.value += 2
                if len(arrTag) <= startIdx.value or arrTag[startIdx.value]==";": return
                str = self.inchToPoints(arrTag[startIdx.value])
                obj[paramName]=str
                startIdx.value += 1
                if len(arrTag) <= startIdx.value or arrTag[startIdx.value]==";": return
                startIdx.value += 1
        if str != None:
            obj['margin-left']=str
            startIdx.value += 1
            if len(arrTag) <= startIdx.value or arrTag[startIdx.value]==";": return
            startIdx.value += 1
            str = self.inchToPoints(arrTag[startIdx.value])
            obj['margin-right']=str
            startIdx.value += 1
            if len(arrTag) <= startIdx.value or arrTag[startIdx.value]==";": return
            startIdx.value += 1
            str = self.inchToPoints(arrTag[startIdx.value])
            obj['text-indent']=str
        return

    def readColor(self,tagArr,prefix,startIndex,obj):
        assert isinstance(startIndex,RefInt)
        assert isinstance(obj,HtmlStyle)
        vr = vg = vb = 0
        str = ''

        if startIndex.value < len(tagArr):
            str = tagArr[startIndex.value]
            if str=="DC" or str=="False ":
                startIndex.value += 1
                return
            vr = int(str)
            startIndex.value += 2
            vg = int(tagArr[startIndex.value])
            startIndex.value += 2
            vb = int(tagArr[startIndex.value])

            colorStr = '#{0:2x}{1:2x}{2:2x}'.format(vr,vg,vb)
            assert len(colorStr)==7, 'Color string invalid: {}'.format(colorStr)
            obj[prefix]=colorStr
            startIndex.value +=2
            if startIndex.value >= len(tagArr): return
            if tagArr[startIndex.value]=='DC':
                startIndex.value += 1
            else:
                startIndex.value -= 1

    def stringToSafe(self,str,tag):
        s = str.encode('cp1252','ignore')
        result=tag + '_'

        for bt in s:
            if bt.isaplha():
                result += bt
            elif bt == ' ':
                result += '_'
            else:
                result += '_{}'.format(ord(bt))

        return result

    def percentValue(self, value):
        try:
            d=float(value)
            if d>0.3:
                return '{}%'.format(int(d))
            return None
        except:
            return None

    def readParaFormating(self,arrTag,stidx,obj):
        assert isinstance(obj,HtmlStyle)
        value=None
        str=''
        ri=RefInt()
        ri.value=0
        while ri.value < len(arrTag):
            tag = arrTag[i]
            if tag=='AP':
                value = self.inchToPoints(arrTag[ri.value+2])
                obj['margin-bottom']=value
                ri.inc(2)
            elif tag=='BP':
                value = self.inchToPoints(arrTag[ri.value+2])
                obj['margin-top']=value
                ri.inc(2)
            elif tag=='JU':
                value = self.alignFromString(arrTag[ri.value+2])
                obj['text-align']=value
                ri.inc(2)
            elif tag=='SD':
                ri.inc(2)
                self.readColor(arrTag,"background-color",ri,obj)
            elif tag=='LH':
                value = self.inchToPoints(arrTag[ri.value+2])
                obj['line-height']=value
                ri.inc(2)
            elif tag=='LS':
                value = self.percentValue(arrTag[ri.value+2])
                obj['line-height']=value
                ri.inc(2)
            elif tag=='IN':
                ri.inc(2)
                self.readIndentFormating(arrTag,ri,obj)
            elif tag=='BR':
                ri.inc(2)
                self.readBorders(arrTag,ri,obj)
            else:
                while ri.value < len(arrTag) and arrTag[ri.value]!=';':
                    ri.inc(1)


    def finishEtlStarted(self,target):
        if 'ETL_STARTED' in self.ethDict:
            target.appendString("</table>")
            del self.ethDict['ETL-STARTED']

    def fullPathStylistImage(self,file):
        return "vbase:#stylist_image/{}".format(file)

    def getObjectMIMEType(self,ob_type,ob_name):
        if ob_name.lower().endswith('.png'):
            return 'image/png'
        assert False, 'Unknown file/type ' + ob_name + ' ' + ob_type

    def processTag(self, tag, target, styles, paraStyle, charStyle, recordDict, pwLevel, pwParaStart, pwLinkStyle):
        assert isinstance(tag,FlatFileTagString)
        assert isinstance(target,HtmlString)
        assert isinstance(styles,HtmlStylesCollection)
        assert isinstance(paraStyle,HtmlStyle)
        assert isinstance(charStyle,HtmlStyleTracker)

        tagArr = tag.createArray()
        str = tagArr[0]

        #
        # first processing is for taga, which can influence levels of text
        #
        if str=='PW':
            self.hcPwCounter+=1
            pwLevel.append(self.hcPwCounter)
            pwParaStart.append(self.hcParaStarted)
            self.hcParaStarted = False
            target.acceptText = (self.hcPwCounter == self.catchPwCounter)
            if len(tagArr)>2:
                pwLinkStyle.append(tagArr[2])
            else:
                pwLinkStyle.append('')
        elif str=='LT':
            restCount = 0
            if len(pwLevel) > 0:
                del pwLevel[-1]
            if len(pwLevel) > 0:
                restCount = pwLevel[-1]
            else:
                restCount = 0
            if len(pwParaStart)>0:
                self.hcParaStarted = pwParaStart[-1]
                del pwParaStart[-1]

            classFormat = "Popup"
            if len(pwLinkStyle) > 0:
                classFormat = pwLinkStyle[-1]
            target.acceptText = (restCount == self.catchPwCounter)
            self.checkParagraphStart(target,paraStyle)


            if 'NamedPopup' in recordDict:
                target.appendString("<a class=\"LK_{}\" href=\"vbase:#inlinepopup/DP/{}/{}\">".format(classFormat,
                    FlatFileUtils.encodeLinkSafeString(recordDict["NamedPopup"]), self.hcPwCounter))
                self.linkStarted = True
            else:
                target.appendString("<a class=\"LK_{}\" href=\"vbase:#inlinepopup/RD/{}/{}\">".format(classFormat,
                    recordDict['record'], self.hcPwCounter))
                self.linkStarted = True
            if len(self.pwLinkStyle) > 0:
                del self.pwLinkStyle[-1]
        elif str=='NT':
            self.hcNtCounter+=1
            target.acceptText = (self.hcNtCounter == self.catchNtCounter)
        elif str=="/NT":
            self.hcNtCounter-=1
            target.acceptText = (self.hcNtCounter == self.catchNtCounter)

        #
        # if text is not accepted, then also tags are rejected to write
        #
        if not target.acceptText:
            return

        if str=='ETH':
            self.finishHtmlFormating(target,paraStyle,charStyle)
            paraStyle.clear()
            charStyle.clearChanges()
            ethArg = ''
            self.ethStack.append(self.ethDict.copy())
            ethArg = tagArr[2] if len(tagArr)>=3 else "cont_book_open"
            self.ethDict['A']=ethArg
            ethArg = tagArr[4] if len(tagArr)>=5 else "cont_book_closed"
            self.ethDict['B']=ethArg
            gEthCounter+=1
            self.ethDict['C'] = "ethimg{}".format(gEthCounter)
            self.ethDict['D'] = "eth_{}".format(gEthCounter)
            target.appendString("<table style='font-family:Helvetica;font-size:14pt;text-align:left'>")
            target.appendString("<tr><td><img id='{}'".format(self.ethDict['C']))
            target.appendString("src='vbase:#stylist_images/{}' style='cursor:pointer;' ".format(self.ethDict['A' if self.ethDefaultExpanded else 'B']))
            target.appendString("onclick=\"eth_show_hide('{}');eth_expand('{}', '{}', '{}');\"></td><td>".format(self.ethDict["D"], self.ethDict["C"], self.ethDict["A"], self.ethDict["B"]))
        elif str=="ETB":
            self.finishHtmlFormating(target,paraStyle,charStyle)
            self.finishEtlStarted(target)
            target.appendString("</td></tr><tr><td></td><td id='{}' style='display:{};'>".format(self.ethDict["D"], 'block' if self.ethDefaultExpanded else "none"))
        elif str=="/ETH":
            self.finishHtmlFormating(target,paraStyle,charStyle)
            paraStyle.clear()
            charStyle.clearChanges()
            self.finishEtlStarted()
            self.ethDict = {}
            if len(self.ethStack) > 0:
                self.ethDict = self.ethStack[-1]
                del self.ethStack[-1]
            target.appendString("</td></tr></table>")
            self.ethStyle = ""
        elif str=="ETL":
            self.finishHtmlFormating(target,paraStyle,charStyle)
            paraStyle.clear()
            charStyle.clearChanges()
            self.ethListImage = (tagArr[2] if len(tagArr)>=3 else "cont_text")
            if 'ETL_STARTED' in self.ethDict:
                target.appendString("</td></tr>")
            else:
                target.appendString("<table style='font-size:14pt;' cellpadding=4>")
            target.appendString("<tr>")
            target.appendString("<td width=20 valign=top><img src='vbase:#stylist_images/{}'></td><td>".format(self.ethListImage))
            self.ethDict['ETL_STARTED']=1
        elif str=="ETX":
            self.finishHtmlFormating(target,paraStyle,charStyle)
            paraStyle.clear()
            charStyle.clearChanges()
            if 'ETL_STARTED' in self.ethDict:
                target.appendString("</td></tr>")
            else:
                target.appendString("<table style='font-size:14pt;'>")
            target.appendString("<tr>")
            target.appendString("<td valign=top colspan=2>")
            self.ethDict['ETL_STARTED']=1
        elif str=="/ETL":
            self.finishHtmlFormating(target,paraStyle,charStyle)
            paraStyle.clear()
            charStyle.clearChanges()
            self.finishEtlStarted(target)
        elif str=="ETS":
            if len(tagArr) >= 3:
                self.ethStyle = tagArr[2]
            else:
                self.ethStyle = ""

        # extended para styles
        if str=='PS':
            safeString = FlatFileString.stringToSafe(tagArr[2],"PA")
            paraStyle.setStyleName(safeString)
        elif str=="LV":
            safeString = FlatFileString.stringToSafe(tagArr[2],"LE")
            paraStyle.setStyleName(safeString)

        # reading paragraph styles
        if str=="AP":
            paraStyle['margin-bottom']="{}in".format(tagArr[2])
        elif str=="BP":
            paraStyle['margin-top']="{}in".format(tagArr[2])
        elif str=="BR":
            index = RefInt()
            index.value=2
            self.readBorders(tagArr,index,paraStyle)
        elif str=="JU":
            paraStyle['text-align']=self.alignFromString(tagArr[2])
        elif str=="LH":
            try:
                v = float(tagArr[2])
                paraStyle['line-height']='{}%'.format(v*100.0)
            except:
                pass
        elif str=="IN":
            index=RefInt(2)
            self.readIndentFormating(tagArr,index2,paraStyle)
        elif str=="SD":
            if len(tagArr) == 1 or tagArr[2]=='False ':
                del paraStyle["background-color-x"]
            else:
                i=RefInt(2)
                self.readColor(tagArr,"background-color-x",i,paraStyle)
        elif str=='TS':
            pass



        if str=="BC":
            if len(tagArr) == 1 or tagArr[2]=="DC":
                del charStyle["background-color-x"]
            else:
                i = RefInt(2)
                self.readColor(tagArr,"background-color-x",i,charStyle)
        elif str=="BD-":
            charStyle['font-weight']="normal"
        elif str=="BD":
            del charStyle['font-weight']
        elif str=="BD+":
            charStyle['font-weight']="bold"
        elif str=="UN-":
            charStyle["text-decoration"]="none"
        elif str=="UN":
            del charStyle["text-decoration"]
        elif str=="UN+":
            charStyle["text-decoration"]="underline"
        elif str=="SO-":
            charStyle["text-decoration"]="none"
        elif str=="SO":
            del charStyle["text-decoration"]
        elif str=="SO+":
            charStyle["text-decoration"]="line-through"
        elif str=="HD-":
            charStyle["visibility"]="visible"
        elif str=="HD":
            del charStyle["visibility"]
        elif str=="HD+":
            charStyle["visibility"]="hidden"
        elif str=="CS":
            charStyle.styleName = FlatFileString.stringToSafe(tagArr[2],"CS")
        elif str=="/CS":
            charStyle.styleName = ""
        elif str=="FC":
            if len(tagArr) == 1 or tagArr[2]=="DC":
                del charStyle["color"]
            else:
                i = RefInt(2)
                self.readColor(tagArr,"color",i,charStyle)
        elif str=="FT":
            if len(tagArr) == 1:
                del charStyle["font-family"]
            else:
                fontName = tagArr[2]
                charStyle["font-family"]=styles.substitutionFontName(fontName)
        elif str=="IT-":
            charStyle["font-style"]="normal"
        elif str=="IT":
            del charStyle["font-style"]
        elif str=="IT+":
            charStyle["font-style"]="italic"
        elif str=="PN":
            charStyle.styleName = FlatFileString.stringToSafe(tagArr[2],"PD")
        elif str=="/PN":
            charStyle.styleName = ""
        elif str=="PT":
            if len(tagArr) == 1:
                del charStyle["font-size"]
            else:
                ptSizeDescr = tagArr[2]
                if ptSizeDescr.endswith("pt"):
                    ptSizeDescr = ptSizeDescr[:-2]
                if ptSizeDescr!="14":
                    charStyle["font-size"]="{}%".format(int(float(ptSizeDescr)*100/14))
                    if "line-height" in charStyle:
                        charStyle["line-height"]="120%"
        elif str=="SP":
            self.hcSup = True
            self.hcSupChanged = True
        elif str=="SB":
            self.hcSub = True
            self.hcSubChanged = True
        elif str == "/SS":
            if self.hcSub:
                self.hcSub = False
                self.hcSubChanged = True
            if self.hcSup:
                self.hcSup = False
                self.hcSupChanged = True

        #
        # tag for controlling
        #

        if str == "CR":
            target += "<br>"
        elif str == "HR":
            self.hcParaStarted = False
        elif str == "HS":
            target += "&nbsp;"
        elif str == "OB":
            ob_type = tagArr[2]
            ob_name = tagArr[4]
            ob_width = None
            ob_height = None
            if len(tagArr) > 6: ob_width = tagArr[6]
            if len(tagArr) > 8: ob_height = tagArr[8]
            s = ''
            objectFileName,objectExtension = os.path.splitext(ob_name).lower()
            imageExtensions = [".png", ".tif", ".tiff", ".jpg", ".gif", ".bmp"]
            self.checkParagraphStart(target,paraStyle)
            if objectExtension in imageExtensions:
                s += f"<img src=\"vbase:#objects/{ob_name}\""
                if ob_width != None and ob_height != None:
                    s += " width={} height={}".format(self.inchToPoints(ob_width), self.inchToPoints(ob_height))
                s += ">"
            else:
                s += "<object data=\"vbase:#objects/{}\"".format(ob_name)
                if ob_type:
                    s += " type=\"{}\"".format( self.getObjectMIMEType(ob_type,ob_name))
                if ob_width != None and ob_height != None:
                    s += " width={} height={}".format(self.inchToPoints(ob_width), self.inchToPoints(ob_height))
                s += "></object>"
            target += s
            return
        elif str == "QL" or str == "EN":
            query = tagArr[4]
            target += "<a class=\"{}\" href=\"vbase:#links/{}/{}\">".format( FlatFileString.stringToSafe(tagArr[2],"LK"), str, FlatFileUtils.encodeLinkSafeString(query))
            self.linkStarted = True
        elif str == "PX":
            self.checkParagraphStart(target,paraStyle)
            target += "<a class=\"{}\" href=\"vbase:#popup/{}\">".format( FlatFileString.stringToSafe(tagArr[2],"LK"), FlatFileUtils.encodeLinkSafeString(tagArr[4]))
            self.linkStarted = True
        elif str == "DL" or str == "ML" or str == "PL":
            self.checkParagraphStart(target,paraStyle)
            self.dataObjectName = tagArr[4]
            if FlatFileString.dataLinkAsButton:
                target += "<input style=\"font-size:100%%\" type=\"button\" name=\"b1\" onclick=\"location.href='vbase:#links/{}/{}'\" value=\"".format(str, FlatFileUtils.encodeLinkSafeString(self.dataObjectName))
                self.buttonStarted = True
            else:
                target += "<a class=\"{}\" style=\"font-size:0pt;\" href=\"vbase:#links/{}/{}\"><img src=\"vbase:#stylist_images/speaker\" width=40 height=40 border=0>".format( FlatFileString.stringToSafe( tagArr[2],"LK"), str, FlatFileUtils.encodeLinkSafeString(self.dataObjectName))
                self.linkStarted = True
        elif str == "WW":
            self.checkParagraphStart(target,paraStyle)
            target += "<a class=\"{}\" href=\"{}\">".format( FlatFileString.stringToSafe(tagArr[2],"LK"), tagArr[4])
            self.linkStarted = True
        elif str == "/DL" or str == "/ML" or str == "EL" or str == "/EN" or str == "/JL" or str == "/PX" or str == "/OL" or str == "/PL" or str == "/QL" or str == "/PW" or str == "/WW":
            if self.linkStarted:
                target += "</a>"
                self.linkStarted = False
            elif self.buttonStarted:
                target += "\">"
                self.buttonStarted = False
        elif str == "JL":
            if len(tagArr) > 4:
                s2 = tagArr[4]
                if s2:
                    if self.validator.jumpExists(s2):
                        target += "<a href=\"vbase:#links/JL/"
                        target += FlatFileUtils.encodeLinkSafeString(s2)
                        target += "\">"
                        self.linkStarted = True
                    else:
                        self.charStyle['color'] = "#909090"
        elif str == "RO":
            self.finishHtmlFormating(target,paraStyle,charStyle)
            target += "<tr>"
            self.hcTableRows+=1
            self.hcTableColumns=0
        elif str == "TB":
            target += "  &nbsp;&nbsp;&nbsp;"
        elif str == "TA":
            self.finishHtmlFormating(target, paraStyle, charStyle)
            tableTag = '<table'
            if len(tagArr) > 2:
                dict = HtmlStyle()
                counts = int(tagArr[2])
                if counts > 0:
                    self.readParaFormating(tagArr, 4+counts*2, dict)
                else:
                    self.readParaFormating(tagArr, 2, dict)
                tableTag += " style='"
                tableTag += dict.styleCssText()
                tableTag += "'>"
            else:
                tableTag += ">"
            target += tableTag
            self.hcTableRows = 0
            self.hcTableColumns = 0
        elif str == "CE":
            self.hcTableColumns += 1
            target += "<td>"
        elif str == "/CE":
            target += "</td>"
        elif str == "/TA":
            target += "</table>"



class RefInt:
    def __init__(self,value=0):
        self.value=value

    def inc(self,iv):
        value += iv
