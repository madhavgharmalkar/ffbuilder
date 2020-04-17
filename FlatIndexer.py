import Flat

def removeTrailingNonAlphanumeric(word):
    for i in range(len(word)-1,-1,-1):
        if word[i].isalnum():
            return word[:i+1]
    return ''

def parse(text):
    status = 0
    start = 0
    end = 0
    tagIdentified = 0

    data = Flat.toOEM(text)
    word = ''
    contains = 0 # 0 - none, 1 - alpha, 2 - num, 3 - alphanum, 4-minus,plus

    for i,bi in enumerate(data):
        if status==0:
            if bi == '<':
                status = 1;
        elif status==1:
            if bi == '<':
                status = 0
            else:
                start = i-1
                status = 2
        elif status==2:
            if bi == '>':
                end = i
                tagIdentified = 1
                status = 0
            elif bi == '"':
                status = 3
        elif status==3:
            if bi == '"':
                status = 4
        elif status==4:
            if bi == '"':
                status = 3
            elif bi == '>':
                end = i
                tagIdentified = 1
                status = 0

        if tagIdentified == 1:
            tagIdentified = 0
            yield 'tag', data[start:end+1]
            contains = 0
        elif status>1:
            if len(word)>0:
                word = removeTrailingNonAlphanumeric(word)
                if len(word)>0: yield 'text', word
                word = ''
        elif status==0:
            rc=bi
            if contains == 0:
                if rc == '-' or rc=='+':
                    word += rc
                    contains = 4
                elif rc.isdigit():
                    word += rc
                    contains = 2
                elif rc.isalpha():
                    word += rc.lower()
                    contains = 1
            elif contains == 1 or contains == 3:
                if rc.isdigit() or rc=='.':
                    word += rc
                    contains = 3
                elif rc.isalpha() or rc=='\'':
                    word += rc.lower()
                else:
                    word = removeTrailingNonAlphanumeric(word)
                    if len(word)>0: yield 'text', word
                    word = ''
                    contains = 0
            elif contains == 2:
                if rc == '.' or rc == ',':
                    word += rc
                elif rc.isalpha():
                    word += rc.lower()
                    contains = 3;
                elif rc.isdigit():
                    word += rc
                else:
                    if len(word)>0: yield 'text', word
                    word = ''
                    contains = 0
            elif contains == 4:
                if rc.isdigit():
                    word += rc
                    contains = 2
                else:
                    word = ''
                    contains = 0
            else:
                if len(word)>0: yield 'text', word
                word = ''
                contains = 0

    if len(word)>0: yield 'text', word
    word = ''
