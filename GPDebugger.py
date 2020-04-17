import os
import os.path

from GPDebuggerStyleStream import GPDebuggerStyleStream


WRITE_NONE      = 0
WRITE_BY_STYLE  = 1
WRITE_BY_FONT   = 2
WRITE_BY_FORMAT = 3
WRITE_BY_RECORD = 4

stable = 0
fileName = ''
dictStyles = {}
dictTags = {}
dictFonts = {}
newerTags = []
workingDirectory = ''
dumpDirectory = ''
dumpObjectDirectory = ''
outputDirectory = ''
write_style = WRITE_NONE

PAGE_RECS = 10000

g_is_debug = False
outputSingle = None
outputSingleCounter = 0
outSingleRecs = 0
lineNum = 0

def dd(dict,k,v):
    if not dict: return v
    if k not in dict: return v
    return dict[k]

def initWithDirectory(directory):
    global workingDirectory
    global dumpDirectory
    global dumpObjectDirectory
    global outputDirectory
    workingDirectory = directory
    dumpDirectory = os.path.join(directory, "tables")
    outputDirectory = os.path.join(directory, "data")
    dumpObjectDirectory = os.path.join(dumpDirectory, 'obj')
    os_mkdir(workingDirectory)
    os_mkdir(dumpDirectory)
    os_mkdir(dumpObjectDirectory)
    os_mkdir(outputDirectory)
    os_mkdir(os.path.join(workingDirectory,'by-tag'))
    os_mkdir(os.path.join(workingDirectory,'by-style'))
    os_mkdir(os.path.join(workingDirectory,'by-rec'))
    os_mkdir(os.path.join(workingDirectory,'by-font'))

def os_mkdir(dir):
    if not os.path.exists(dir):
        os.mkdir(dir)

def createInstanceWithDirectory(directory):
    initWithDirectory(directory)

def releaseInstance():
    global outputSingle
    if outputSingle!=None:
        outputSingle.close()
        outputSingle = None

def writeFile(fileName,strText):
    with open(os.path.join(workingDirectory,fileName),'wt',encoding='utf-8') as wf:
        wf.write(strText)

def _writeSingle(text, num):
    recid = int(num)
    global outputSingle
    global outputSingleCounter
    global outSingleRecs
    if not outputSingle:
        fileName = os.path.join(workingDirectory, 'by-rec', 'text-{:07d}.html'.format(outputSingleCounter))
        outputSingle = open(fileName, "wt")
        outputSingleCounter+=1
        outputSingle.write("<html>\n<head>\n")
        outputSingle.write("<title>Records</title>\n")
        outputSingle.write("<link href=\"../styles.css\" type=text/css rel=stylesheet>\n")
        outputSingle.write("\n")
        outputSingle.write("</head>\n")
        outputSingle.write("<body>\n")

    outputSingle.write("<a name=\"rec{:d}\">\n".format(recid))
    outputSingle.write("{}\n".format(text))
    outputSingle.write("\n")
    outputSingle.write("\n")
    outputSingle.write("\n")

    outSingleRecs+=1
    if outSingleRecs > PAGE_RECS:
        outputSingle.write("</body>\n")
        outputSingle.write("</html>\n")
        outputSingle.close()
        outputSingle = None
        outSingleRecs = 0


def _styleStream(styleName):
    if styleName == None or len(styleName)==0:
        styleName = "_none_"
    if styleName not in dictStyles:
        dictStyles[styleName] = GPDebuggerStyleStream()
    gps = dictStyles[styleName]
    fileName = os.path.join(workingDirectory,"by-style", styleName + ".html")
    gps.file = open(fileName, "wt",encoding='utf-8')
    gps.file.write("<html>\n<head>\n")
    gps.file.write("<title>Records</title>\n")
    gps.file.write("<link href=\"../styles.css\" type=text/css rel=stylesheet>\n")
    gps.file.write("\n")
    gps.file.write("</head>\n")
    gps.file.write("<body>\n")
    gps.file.write("<h1>Style: {}</h1>\n".format(styleName))
    gps.file.write("\n")
    gps.file.write("\n")
    gps.file.write("\n")
    gps.file.write("<table border=1 color=black>\n")
    return gps

def _fontStream(fontName):
    if fontName == None: fontName = "_none_"
    if fontName not in dictFonts:
        dictFonts[fontName] = GPDebuggerStyleStream()
    gps = dictFonts[fontName]
    fileName = os.path.join(workingDirectory,"by-font", fontName + ".html")
    gps.file = open(fileName, "wt")
    gps.file.write("<html>\n<head>\n")
    gps.file.write("<title>Records</title>\n")
    gps.file.write("<link href=\"../styles.css\" type=text/css rel=stylesheet>\n")
    gps.file.write("\n")
    gps.file.write("</head>\n")
    gps.file.write("<body>\n")
    gps.file.write("<h1>Font: {}</h1>\n".format(fontName))
    gps.file.write("\n")
    gps.file.write("\n")
    gps.file.write("\n")
    gps.file.write("<table border=1 color=black>\n")
    return gps

def _tagStream(tagName):
    if tagName == None: return None
    if tagName not in dictTags: dictTags[fontName] = GPDebuggerStyleStream()
    gps = dictTags[tagName]
    fileName = os.path.join(workingDirectory,"by-tag", tagName + ".txt")
    gps.file = open(fileName, "wt")
    return gps

def writeTag(tagName,aText):
    if g_is_debug == False: return
    gps = _tagStream(tagName)
    if gps:
        gps.file.write(f'{aText}\n')

def fileLocation():
    return f"File:&nbsp;{fileName}<br>line:&nbsp;{lineNum}"

def fileLocationPlain():
    return f"File: {fileName}, line: {lineNum}"

def _writeByStyle(text, style, fileLoc, rid):
    recid = int(int(rid)/PAGE_RECS)
    gps = _styleStream(style)
    gps.file.write("<tr>\n")
    gps.file.write(f"<td><p><a style='font-size:10pt' href=\"../by-rec/text-{recid}.html#rec{rid}\">{fileLoc}</a></td>\n")
    gps.file.write(f"<td>{text}</td>")
    gps.file.write("</tr>\n")

def _writeByFont(text, fonts, fileLoc, rid):
    if not fonts: return
    for font in fonts:
        recid = int(rid/PAGE_RECS)
        gps = _fontStream(font)
        gps.file.write("<tr>\n")
        gps.file.write(f"<td><p><a style='font-size:10pt' href=\"../by-rec/text-{recid}.html#rec{rid}\">{fileLoc}</a></td>\n")
        gps.file.write(f"<td>{text}</td>")
        gps.file.write("</tr>\n")

def _writeByFormating(begin, endStr, filePrefix, text, style, dict):
    if begin in text:
        range = (text.find(begin), len(begin))
        range2 = (range[0] + range[1], len(text) - range[0] - range[1])
        r3 = text.find(endStr,range[0] + range[1])
        if r3>=0:
            r4 = text[:r3].find(';')
            if r4 < 0:
                style = filePrefix + text[range[0] + range[1]:r3]
                _writeByStyle(text, style, dict['fileLoc'], dict['id'])

def writeText(text, aStyle, dict):
    if write_style == WRITE_BY_RECORD:
        _writeSingle(text, dict['id'])
    if write_style == WRITE_BY_STYLE:
        _writeByStyle(text, aStyle, dict['fileLoc'], dict["id"])
    if write_style == WRITE_BY_FORMAT:
        _writeByFormating("font-size:", "%", "fontsize", text, aStyle, dict)
        _writeByFormating("text-indent:", "pt", "textindent", text, aStyle, dict)
    if write_style == WRITE_BY_FONT:
        _writeByFont(text, dd(dict,"fonts",[]), dict["fileLoc"], dict["id"])

def endWrite():
    global outputSingle
    global dictStyles
    global dictFonts
    global dictTags

    if outputSingle:
        outputSingle.close()
        outputSingle = None

    if dictStyles:
        for key,gps in dictStyles.items():
            gps.file.write("</body>\n")
            gps.file.write("</html>\n")
            gps.file.close()
            gps.file = None
        dictStyles = {}

    if dictFonts:
        fileName = os.path.join(workingDirectory,'by-font','index.html')
        with open(fileName,'wt',encoding='utf-8') as wf:
            wf.write('''<html>
            <head>
            <title>Fonts Overview</title></head>
            <body>
            <h1>Fonts | <a href=\"../example-styles.html\">Styles</a></h1>
            ''')

            for key,gps in dictFonts.items():
                gps.file.write("</body>\n")
                gps.file.write("</html>\n")
                gps.file.close()
                gps.file = None
                wf.write(f"<p><a href=\"{key}.html\">{key}</a></p>")

            dictFonts = {}
            wf.write("</body></html>")

    if dictTags:
        for key,gps in dictTags.items():
            gps.file.close()
            gps.file = None
        dictTags = {}

def setLineNumber(a):
    lineNum = a

def setFileName(text):
    fileName = text
