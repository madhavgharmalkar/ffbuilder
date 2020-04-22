
class StringScanner:
    def __init__(self,text):
        self.text = text
        self.found = None
        self.idx = 0
    def Test(self,input_list):
        self.found = None
        i = 0
        for cr in input_list:
            self.found = cr
            i = 0
            crtext = cr['Text']
            while self.found != None and i < len(cr["Text"]):
                if self.idx + i < len(self.text):
                    if self.text[self.idx + i] != crtext[i]:
                        self.found = None
                else:
                    self.found = None
                i += 1

            if self.found != None:
              break

        return self.found != None
    @property
    def curr(self):
        return self.text[self.idx]
    def skip(self):
        self.idx += 1
    def skipFound(self):
        self.idx += len(self.found["Text"]) - 1
    def IsWhiteSpaceAfter(self):
        return self.IsWhiteSpace(self.idx + len(self.found["Text"]))
    def IsWhiteSpace(self,index=-1):
        if index>=len(self.text):
            return True
        if index==-1:
            sc = self.curr
        else:
            sc = self.text[index]
        return sc in [' ', '\t', '\n', '\r']
    @property
    def length(self):
        return len(self.text)

    def int2uc(self,ucvalue):
        return chr(ucvalue)



unics = {
    "Words" : [
      { "Text": "oṁ", "Unicode": 2384 }
    ],
    # starts sylable at start of the word
    "Starting": [
      { "Text": "ai", "Unicode": 2320 },
      { "Text": "au", "Unicode": 2324 },
      { "Text": "a", "Unicode": 2309 },
      { "Text": "ā", "Unicode": 2310 },
      { "Text": "i", "Unicode": 2311 },
      { "Text": "ī", "Unicode": 2312 },
      { "Text": "u", "Unicode": 2313 },
      { "Text": "ū", "Unicode": 2314 },
      { "Text": "ṛ", "Unicode": 2315 },
      { "Text": "ḷ", "Unicode": 2316 },
      { "Text": "o", "Unicode": 2323 },
      { "Text": "e", "Unicode": 2319 },
      { "Text": "ṝ", "Unicode": 2400 }
    ],
    # starts sylable within word
    "InWord": [
      { "Text": "ṁ", "Unicode": 2306 },
      { "Text": "ḥ", "Unicode": 2307 }
    ],

    # starts sylable at start of within word
    # and expects vowel afterward
    "Selfers": [
      { "Text": "kh", "Unicode": 2326 },
      { "Text": "gh", "Unicode": 2328 },
      { "Text": "ch", "Unicode": 2331 },
      { "Text": "jh", "Unicode": 2333 },
      { "Text": "ṭh", "Unicode": 2336 },
      { "Text": "ḍh", "Unicode": 2338 },
      { "Text": "th", "Unicode": 2341 },
      { "Text": "dh", "Unicode": 2343 },
      { "Text": "ph", "Unicode": 2347 },
      { "Text": "bh", "Unicode": 2349 },

      { "Text": "k", "Unicode": 2325 },
      { "Text": "g", "Unicode": 2327 },
      { "Text": "ṅ", "Unicode": 2329 },
      { "Text": "c", "Unicode": 2330 },
      { "Text": "j", "Unicode": 2332 },
      { "Text": "ñ", "Unicode": 2334 },
      { "Text": "ṭ", "Unicode": 2335 },
      { "Text": "ḍ", "Unicode": 2337 },
      { "Text": "ṇ", "Unicode": 2339 },
      { "Text": "t", "Unicode": 2340 },
      { "Text": "d", "Unicode": 2342 },
      { "Text": "n", "Unicode": 2344 },
      { "Text": "p", "Unicode": 2346 },
      { "Text": "b", "Unicode": 2348 },
      { "Text": "m", "Unicode": 2350 },
      { "Text": "y", "Unicode": 2351 },
      { "Text": "r", "Unicode": 2352 },
      { "Text": "l", "Unicode": 2354 },
      { "Text": "ḻ", "Unicode": 2355 },
      { "Text": "v", "Unicode": 2357 },
      { "Text": "ś", "Unicode": 2358 },
      { "Text": "ṣ", "Unicode": 2359 },
      { "Text": "s", "Unicode": 2360 },
      { "Text": "h", "Unicode": 2361 }
    ],

    # anywhere
    "Anywhere": [
      { "Text": "'", "Unicode": 2365 },
      { "Text": "or", "Unicode": 2405 },
      { "Text": "|", "Unicode": 2404 },
      { "Text": "0", "Unicode": 2406 },
      { "Text": "1", "Unicode": 2407 },
      { "Text": "2", "Unicode": 2408 },
      { "Text": "3", "Unicode": 2409 },
      { "Text": "4", "Unicode": 2410 },
      { "Text": "5", "Unicode": 2411 },
      { "Text": "6", "Unicode": 2412 },
      { "Text": "7", "Unicode": 2413 },
      { "Text": "8", "Unicode": 2414 },
      { "Text": "9", "Unicode": 2415 }
    ],

    # ending vowel
    "Vowels": [
      { "Text": "ai", "Unicode": 2376 },
      { "Text": "au", "Unicode": 2380 },
      { "Text": "a", "Unicode": 0 },
      { "Text": "ā", "Unicode": 2366 },
      { "Text": "i", "Unicode": 2367 },
      { "Text": "ī", "Unicode": 2368 },
      { "Text": "u", "Unicode": 2369 },
      { "Text": "ū", "Unicode": 2370 },
      { "Text": "ṛ", "Unicode": 2371 },
      { "Text": "ṝ", "Unicode": 2372 },
      { "Text": "e", "Unicode": 2375 },
      { "Text": "o", "Unicode": 2379 },
      { "Text": "ḷ", "Unicode": 2402 },
      { "Text": "ḹ", "Unicode": 2403 },
    ]
}


def ConvertToDevanagari(unicodeTransliteration):
    # 0 - start of the word
    mode = 0
    deva = ""

    scan = StringScanner(unicodeTransliteration + " ")
    while scan.idx < scan.length:
        if mode == 0:
            if scan.Test(unics["Words"]) and scan.IsWhiteSpaceAfter():
                deva = deva + scan.int2uc(scan.found["Unicode"])
                scan.skipFound()
            elif scan.Test(unics["Starting"]):
                deva = deva + scan.int2uc(scan.found["Unicode"])
                scan.skipFound()
                mode = 1
            elif scan.Test(unics["Selfers"]):
                deva = deva + scan.int2uc(scan.found["Unicode"])
                scan.skipFound()
                mode = 2
            elif scan.Test(unics["Anywhere"]):
                deva = deva + scan.int2uc(scan.found["Unicode"])
                scan.skipFound()
            else:
                deva = deva + scan.curr
        elif (mode == 1):
            if scan.Test(unics["Anywhere"]):
                deva = deva + scan.int2uc(scan.found["Unicode"])
                scan.skipFound()
                mode = 1
            elif scan.Test(unics["InWord"]):
                deva = deva + scan.int2uc(scan.found["Unicode"])
                scan.skipFound()
                mode = 1
            elif scan.Test(unics["Selfers"]):
                deva = deva + scan.int2uc(scan.found["Unicode"])
                scan.skipFound()
                mode = 2
            elif scan.Test(unics["Starting"]):
                deva = deva + scan.int2uc(scan.found["Unicode"])
                scan.skipFound()
                mode = 1
            else:
                deva = deva + scan.curr
                mode = 0
        elif (mode == 2):
            if scan.Test(unics["Vowels"]):
                if (scan.found["Unicode"] != 0):
                    deva = deva + scan.int2uc(scan.found["Unicode"])
                scan.skipFound()
                mode = 1
            elif scan.Test(unics["Selfers"]):
                deva = deva + scan.int2uc(2381)
                deva = deva + scan.int2uc(scan.found["Unicode"])
                scan.skipFound()
                mode = 2
            elif scan.Test(unics["Anywhere"]):
                deva = deva + scan.int2uc(2381)
                deva = deva + scan.int2uc(scan.found["Unicode"])
                scan.skipFound()
                mode = 1
            elif scan.Test(unics["InWord"]):
                deva = deva + scan.int2uc(2381)
                deva = deva + scan.int2uc(scan.found["Unicode"])
                scan.skipFound()
                mode = 1
            elif (scan.IsWhiteSpace()):
                deva = deva + scan.int2uc(2381)
                deva = deva + scan.curr
                mode = 0
            else:
                deva = deva + scan.int2uc(2381)
                deva = deva + scan.curr
                mode = 1
        scan.skip()

    return deva.strip()

def NormalizeChar(cr):
    if isinstance(cr,str):
        if cr=='&':
            return '&amp;'
        elif ord(cr)>127:
            return '&{};'.format(ord(cr))
        else:
            return cr
    elif isinstance(cr,int):
        if cr==38:
            return '&amp;'
        elif cr>127:
            return '&{};'.format(cr)
        else:
            return chr(cr)



if __name__ == '__main__':
    print(ConvertToDevanagari('sāmago \'jaiminiḥ | kaviḥ'))
