import GPDebugger

VBFB_FONTGROUP_BALARAM    = 0
VBFB_FONTGROUP_DEVANAGARI = 1
VBFB_FONTGROUP_SANSKRIT   = 2
VBFB_FONTGROUP_BENGALI    = 3
VBFB_FONTGROUP_WINDGDINGS = 4
VBFB_FONTGROUP_RMDEVA     = 5

balaramFontSet = ["Balaram", "Terminal", "Dravida", "scagoudy", "Basset", "Times New Roman", "Times New Roman Greek", "Bold PS 12cpi", "Times New Roman Baltic", "Times New Roman Special G1", "Arial Narrow", "Univers", "Times New", "MS Sans Serif", "CG Times", "TimesN", "Bookman Old Style", "Poetica", "Microsoft Sans Serif", "Helvetica Narrow", "France", "Sanvito Roman", "C Helvetica Condensed", "Garamond BoldCondensed", "Drona", "Garamond BookCondensed", "TimesTen Roman", "Tms Rmn", "Chn JSong SG", "Book Antiqua", "Courier New", "Courier", "Monaco", "Font13399", "Geneva", "Arial", "Times", "New York", "GillSans Bold", "Symbol", "Font14956", "Arial Unicode MS", "Galliard", "Tamalten", "Bhaskar", "Tahoma", "Time Roman", "Timingala", "Tamal", "Garamond", "Gaudiya", "Helvetica", "BhaskarItal", "Calibri", "HGoudyOldStyleBTBoldItalic", "Lucida Grande", "Goudy Old Style", "Cambria CE", "Cambria", "StarBats", "BellCentennial"]
devanagariFontSet = ["Indevr", "Helv", "indevr"]
devanagariRMFontSet = ["RM Devanagari"]
bengaliFontSet = ["Inbeni", "Inbenr", "Inbeno", "Inbenb"]

def fontGroupFromFontNameInt(fname):
    if fname.startswith("Sanskrit-"):
        return VBFB_FONTGROUP_SANSKRIT
    if fname.startswith("Sca") or fname in balaramFontSet:
        return VBFB_FONTGROUP_BALARAM

    if fname in devanagariFontSet:
        return VBFB_FONTGROUP_DEVANAGARI

    if fname in devanagariRMFontSet:
        return VBFB_FONTGROUP_RMDEVA

    if fname=="Wingdings":
        return VBFB_FONTGROUP_WINDGDINGS

    if fname in bengaliFontSet:
        return VBFB_FONTGROUP_BENGALI

    print("\n{} / {}".format(fname, GPDebugger.fileLocation))
    return VBFB_FONTGROUP_BALARAM

def changeFontName(fontName):
    group = fontGroupFromFontNameInt(fontName)
    if group == VBFB_FONTGROUP_SANSKRIT or group == VBFB_FONTGROUP_BALARAM or group == VBFB_FONTGROUP_WINDGDINGS:
        return 'Times'
    elif group == VBFB_FONTGROUP_BENGALI:
        return fontName
    elif group == VBFB_FONTGROUP_DEVANAGARI or group == VBFB_FONTGROUP_RMDEVA:
        return 'Sanskrit 2003'
    else:
        return fontName
