
import urllib.parse

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
    def __init__(self):
        self.buffer = ''
        self.extractedTag = ''
    def clear(self):
        self.buffer = ''
        self.extractedTag = ''

    def appendChar(self,c):
        self.buffer += c
        return

    def appendString:(self,str):
        self.buffer += str
        return

    def buffer(self):
        return self.buffer

    def createArray(self):
    	part = ''
    	tagParts = []
    	brackets = 0;
        MAKEARRAY_STATUS_DEFAULT = 0
        MAKEARRAY_STATUS_START_DECISION = 1
        MAKEARRAY_STATUS_QUOTE_READ = 2
        MAKEARRAY_STATUS_END_QUOTE = 3
        MAKEARRAY_STATUS_READ_TAG  = 4
    	status = MAKEARRAY_STATUS_DEFAULT;
        nextStatus = MAKEARRAY_STATUS_DEFAULT;

    	// main import procedure
    	for idx in range(len(self.buffer)):
            rd = self.buffer[idx]
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
                    idx--
                    status = MAKEARRAY_STATUS_READ_TAG
                    continue
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
                        tagParts.append(string(rd))
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

        if len(part) > 0:
            tagParts.append(part)

        return tagParts;

    def tag(self):
        if len(self.extractedTag)>0:
            return self.extractedTag

        i=self.buffer.find('<')
        while i<len(self.buffer):
            c = self.buffer[i]
            if c.isalpha() or c in ['+','-','/']:
                self.extractedTag+=c
            else:
                break
        return self.extractedTag




class HtmlStyle:
    styleName = ''
    format = {}
    styleNameChanged = False

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

    def styleCssText(self):
        str = ''
        return str

    def htmlTextForTag(self,tag):
        str = ''
        return str

    def clear(self):
        return

class HtmlStyleTracker(HtmlStyle):
    formatOld = {}
    formatChanges = []

    def clearChanges(self):
        self.formatChanges = []

    def hasChanges(self):
        return len(self.formatChanges)>0


class HtmlStylesCollection:
    styles = []

    def addStyle(self,style):
        self.styles.append(style)
        return

    def substitutionFontName(self,fname):
        str = fname
        return str

    def getMIMEType(self,str):
        return str


class HtmlString:
    buffer = ''
    acceptText = False

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
        self.buffer[atIndex:atIndex]=str
        return

g_FlastFileString_DataLinkAsButton=False

class FlatFileString:
    buffer = ''
    hcParaStarted = False
    hcSpanStarted = False
    hcSup = False
    hcSupChanged = False
    hcSub = False
    hcSubChanged = False
    linkStarted = False
    buttonStarted = False
    ethDefaultExpanded = False
    hcPwCounter = 0
    hcNtCounter = 0
    hcTableRows = 0
    hcTableColumns = 0
    catchPwLevel = 0
    catchPwCounter = 0
    catchNtCounter = 0
    ethStyle = ''
    ethListImage = ''
    ethDict = {}
    ethStack = []
    dataObjectName = None
    paraStyleRead = None
    validator = None

    @staticmethod
    def stringToSafe(str,tag):
        return ''

    @staticmethod
    def dataLinkAsButton():
        return g_FlastFileString_DataLinkAsButton

    @staticmethod
    def setDataLinkAsButton(bValue):
        g_FlastFileString_DataLinkAsButton=bValue

    def string(self):
        return self.buffer

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

    @staticmethod
    def removeTags(str):
        return str

    def checkParagraphStart(self,target,paraStyle):
        if self.hcParaStarted == False:
            self.hcParaStarted = True
        target.appendString(paraStyle.htmlTextForTag("p"))

    def processChar(self,chr,target,paraStyle,charStyle):
        self.checkParagraphStart(target,paraStyle)

        if self.hcSubChanged and !self.hcSub:
            target.appendString("</sub>")
        if self.hcSupChanged and !self.hcSup:
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
            hcSub = False
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
    		if str=="DC" or str=="NO":
    			startIndex.value += 1
    			return ""
    		vr = int(str)
    		startIndex.value += 2
    		vg = int(tagArr[startIndex.value])
    		startIndex.value += 2
    		vb = int(tagArr[startIndex.value])

    		strColor = "#{0:2x}{1:2x}{2:2x}".format(vr, vg, vb)
            assert len(strColor)==7, 'bad value for color {}'.format(strColor)
    		startIndex.value +=2;
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
    		if startIndex.value >= len(arrTag)
    			return
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
    		if str=="DC" or str=="NO":
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
        return "vbase://stylist_image/{}".format(file)

    def getObjectMIMEType(self,ob_type,ob_name):
        if ob_name.lower().endswith('.png'):
            return 'image/png'
        assert False, 'Unknown file/type ' + ob_name + ' ' + ob_type


    def processTag(self,tag,target,styles,paraStyle,charStyle,recordDict,pwLevel,pwParaStart,pwLinkStyle):
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
            self.hcPwCounter++;
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
            else
                restCount = 0
            if len(pwParaStart)>0:
                self.hcParaStarted = pwParaStart[-1]
                del pwParaStart[-1]

            classFormat = "Popup"
            if len(pwLinkStyle) > 0:
                classFormat = pwLinkStyle[-1]
            target.acceptText = (restCount == catchPwCounter)
            self.checkParagraphStart(target,paraStyle)


            if 'NamedPopup' in recordDict:
                target.appendString("<a class=\"LK_{}\" href=\"vbase://inlinepopup/DP/{}/{}\">".format(classFormat,
                    FlatFileUtils.encodeLinkSafeString(recordDict["NamedPopup"]), hcPwCounter))
                linkStarted = True
            else:
                target.appendString("<a class=\"LK_{}\" href=\"vbase://inlinepopup/RD/{}/{}\">".format(classFormat,
                    recordDict['record'], hcPwCounter))
                linkStarted = True
            if len(pwLinkStyle) > 0:
                del pwLinkStyle[-1]
        elif str=='NT':
            self.hcNtCounter+=1
            target.acceptText = (hcNtCounter == catchNtCounter)
        elif str=="/NT":
            self.hcNtCounter-=1
            target.acceptText = (hcNtCounter == catchNtCounter)

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
            ethArg = (tagArr[2] if len(tagArr)>=3 else "cont_book_open")
            self.ethDict['A']=ethArg
            ethArg = (tagArr[4] if len(tagArr)>=5 else @"cont_book_closed")
            self.ethDict['B']=ethArg
            gEthCounter+=1
            self.ethDict['C'] = "ethimg{}".format(gEthCounter)
            self.ethDict['D'] = "eth_{}".format(gEthCounter)
            target.appendString("<table style='font-family:Helvetica;font-size:14pt;text-align:left'>")
            target.appendString("<tr><td><img id='{}'".format(self.ethDict['C']))
            target.appendString("src='vbase://stylist_images/{}' style='cursor:pointer;' ".format(self.ethDict['A' if ethDefaultExpanded else 'B']))
            target.appendString("onclick=\"eth_show_hide('{}');eth_expand('{}', '{}', '{}');\"></td><td>".format(self.ethDict["D"], self.ethDict["C"], self.ethDict["A"], self.ethDict["B"]))
        elif str=="ETB":
            self.finishHtmlFormating(target,paraStyle,charStyle)
            self.finishEtlStarted(target)
            target.appendString("</td></tr><tr><td></td><td id='{}' style='display:{};'>".format(self.ethDict["D"], 'block' if ethDefaultExpanded else "none"))
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
            target.appendString("<td width=20 valign=top><img src='vbase://stylist_images/{}'></td><td>".format(self.ethListImage))
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
            if len(tagArr) == 1 or tagArr[2]=='NO':
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
        else if ([str isEqual:@"SB"]) {
            hcSub = YES;
            hcSubChanged = YES;
        }
        else if ([str isEqual:@"/SS"]) {
            if (hcSub) {
                hcSub = NO;
                hcSubChanged = YES;
            }
            if (hcSup) {
                hcSup = NO;
                hcSupChanged = YES;
            }
        }

        //
        // tag for controlling
        //

        if ([str isEqual:@"CR"]) {
            [target appendString:@"<br>"];
        }
        else if ([str isEqual:@"HR"]) {
            hcParaStarted = NO;
        }
        else if ([str isEqual:@"HS"]) {
            [target appendString:@"&nbsp;"];
        }
        else if ([str isEqual:@"OB"]) {
            NSString * ob_type = [tagArr objectAtIndex:2];
            NSString * ob_name = [tagArr objectAtIndex:4];
            NSString * ob_width = nil;
            NSString * ob_height = nil;
            if ([tagArr count] > 6)
                ob_width = [tagArr objectAtIndex:6];
            if ([tagArr count] > 8)
                ob_height = [tagArr objectAtIndex:8];
            //NSMutableDictionary * form = [[NSMutableDictionary alloc] initWithCapacity:10];
            NSMutableString * s = [[NSMutableString alloc] initWithCapacity:100];
            NSString * objectExtension = [[ob_name pathExtension] lowercaseString];
            NSSet * imageExtensions = [NSSet setWithObjects:@"png", @"tif", @"tiff", @"jpg", @"gif", @"bmp", nil];
            [self checkParagraphStart:target paragraphStyle:paraStyle];
            if ([imageExtensions containsObject:objectExtension])
            {
                [s appendFormat:@"<img src=\"vbase://objects/%@\"", ob_name];
                if (ob_width != nil && ob_height != nil)
                {
                    [s appendFormat:@" width=%@ height=%@",
                     [self inchToPoints:ob_width],
                     [self inchToPoints:ob_height]];
                }
                [s appendString:@">"];
            } else {
                [s appendFormat:@"<object data=\"vbase://objects/%@\"", ob_name];
                if (ob_type != nil)
                {
                    [s appendFormat:@" type=\"%@\"", [self getObjectMIMEType:ob_type objectName:ob_name]];
                }
                if (ob_width != nil && ob_height != nil)
                {
                    [s appendFormat:@" width=%@ height=%@",
                     [self inchToPoints:ob_width],
                     [self inchToPoints:ob_height]];
                }

                [s appendFormat:@"></object>"];
            }
            [target appendString:s];

            return;
        }
        else if ([str isEqual:@"QL"] || [str isEqual:@"EN"]) {
            NSString * query = [tagArr objectAtIndex:4];
            [target appendString:[NSString stringWithFormat:@"<a class=\"%@\" href=\"vbase://links/%@/%@\">",
                                  [FlatFileString stringToSafe:[tagArr objectAtIndex:2] tag:@"LK"],
                                  str,
                                  [FlatFileUtils encodeLinkSafeString:query]]];
            linkStarted = YES;
            //NSLog(@"ORIGINAL QUERY: %@\nNEW QUERY: %@\n-------------------", query, [FlatFileUtils encodeLinkSafeString:query]);
        }
        else if ([str isEqual:@"PX"]) {
            [self checkParagraphStart:target paragraphStyle:paraStyle];
            [target appendString:[NSString stringWithFormat:@"<a class=\"%@\" href=\"vbase://popup/%@\">",
                                  [FlatFileString stringToSafe:[tagArr objectAtIndex:2] tag:@"LK"],
                                  [FlatFileUtils encodeLinkSafeString:[tagArr objectAtIndex:4]]]];
            linkStarted = YES;
        }
        else if ([str isEqual:@"DL"] || [str isEqual:@"ML"] || [str isEqual:@"PL"])
        {
            [self checkParagraphStart:target paragraphStyle:paraStyle];
            self.dataObjectName = [tagArr objectAtIndex:4];
            if ([FlatFileString dataLinkAsButton])
            {
                [target appendString:[NSString stringWithFormat:@"<input style=\"font-size:100%%\" type=\"button\" name=\"b1\" onclick=\"location.href='vbase://links/%@/%@'\" value=\"", str, [FlatFileUtils encodeLinkSafeString:self.dataObjectName]]];
                buttonStarted = YES;
            }
            else
            {
                [target appendString:[NSString stringWithFormat:@"<a class=\"%@\" style=\"font-size:0pt;\" href=\"vbase://links/%@/%@\"><img src=\"vbase://stylist_images/speaker\" width=40 height=40 border=0>",
                                      [FlatFileString stringToSafe:[tagArr objectAtIndex:2] tag:@"LK"],
                                      str,
                                      [FlatFileUtils encodeLinkSafeString:self.dataObjectName]]];
                linkStarted = YES;
            }
        }
        else if ([str isEqual:@"WW"])
        {
            [self checkParagraphStart:target paragraphStyle:paraStyle];
            [target appendString:[NSString stringWithFormat:@"<a class=\"%@\" href=\"%@\">",
                                  [FlatFileString stringToSafe:[tagArr objectAtIndex:2] tag:@"LK"],
                                  [tagArr objectAtIndex:4]]];
            linkStarted = YES;
        }
        else if ([str isEqual:@"/DL"] || [str isEqual:@"/ML"] || [str isEqual:@"EL"]
                 || [str isEqual:@"/EN"] || [str isEqual:@"/JL"]
                 || [str isEqual:@"/PX"] || [str isEqual:@"/OL"] || [str isEqual:@"/PL"] || [str isEqual:@"/QL"]
                 || [str isEqual:@"/PW"] || [str isEqual:@"/WW"])
        {
            if (linkStarted) {
                [target appendString:@"</a>"];
                linkStarted = NO;
            } else if (buttonStarted) {
                [target appendString:@"\">"];
                buttonStarted = NO;
            }
        }
        else if ([str isEqual:@"JL"]) {
            if ([tagArr count] > 4)
            {
                NSString * s2 = [tagArr objectAtIndex:4];
                if (s2 != nil)
                {
                    if ([self.validator jumpExists:s2]) {
                        [target appendString:@"<a href=\"vbase://links/JL/"];
                        [target appendString:[FlatFileUtils encodeLinkSafeString:s2]];
                        [target appendString:@"\">"];
                        linkStarted = YES;
                    } else {
                        [charStyle setValue:@"#909090" forKey:@"color"];
                    }
                }
            }
        }
        else if ([str isEqual:@"RO"])
        {
            [self finishHtmlFormating:target paragraphStyle:paraStyle characterStyle:charStyle];
            [target appendString:@"<tr>"];
            hcTableRows++;
            hcTableColumns=0;
        }
        else if ([str isEqual:@"TB"]) {
            [target appendString:@"  &nbsp;&nbsp;&nbsp; "];
        }
        else if ([str isEqual:@"TA"]) {
            [self finishHtmlFormating:target paragraphStyle:paraStyle characterStyle:charStyle];
            NSMutableString * tableTag = [[NSMutableString alloc] initWithCapacity:10];
            [tableTag setString:@"<table"];
            if ([tagArr count] > 2)
            {
                HtmlStyle * dict = [[HtmlStyle alloc] init];
                int counts = [(NSString *)[tagArr objectAtIndex:2] intValue];
                if (counts > 0)
                {
                    [self readParaFormating:tagArr fromIndex:(4+counts*2) target:dict];
                }
                else
                {
                    [self readParaFormating:tagArr fromIndex:2 target:dict];
                }
                [tableTag appendFormat:@" style='"];
                [tableTag appendString:[dict styleCssText]];
                [tableTag appendFormat:@"'>"];

            }
            else {
                [tableTag appendFormat:@">"];
            }

            [target appendString:tableTag];
            hcTableRows = 0;
            hcTableColumns = 0;
        }
        else if ([str isEqual:@"CE"])
        {
            hcTableColumns++;
            [target appendString:@"<td>"];
        }
        else if ([str isEqual:@"/CE"]) {
            [target appendString:@"</td>"];
        }
        else if ([str isEqual:@"/TA"])
        {
            [target appendString:@"</table>"];
        }

    }



class RefInt:
    value=0
    def __init__(self,value=0):
        self.value=value

    def inc(self,iv):
        value += iv

class FlatFileStringIndexer:
    delegate = None
    text = ''
    properties = {}

    def parse(self):
        return

    def objectForKey(self,key):
        return

    def setObject(property,forKey='_default_'):
        properties[forKey] = property
        return
