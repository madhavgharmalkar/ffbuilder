from io import StringIO
import Flat
import uni2deva

r1 = ['<CR> <CR>', '(r) [ṅga]', '&174; [ṅga]', 'M [m_]', 'S [s_]', 'P [p_]', 'T [t_]', 'N [n_]', 'D [dh_]', 'Y [y_]', 'J [j_]', '} [tr_]', '< [ṇ_]', '+ [kṣ_]', 'Z [ṣ_]', 'X [ś_]', 'V [v_]', 'K [k_]','> [bh_]', 'Q [th_]', 'B [b_]', 't [tt_]', '* [_ṛ]', 'a [_a]', 'q [_ī]', 'u [_u]', '( [_.]', 'U [_ū]', 'e [_e]', 'i [__i]', 'E [_ai]', 'aaE [_au]', '&amp; [ṁ]', 'd [da]', 'v [va]', 'c [ca]', 'h [ha]', '@ [ḍa]', '! [ḍha]', 'b [ba]', '] [_r_]', '&233; [śa]', '&234; [śca]', '&237; [ṣṭa]', 'r [ra]', '&167;- [kra]', '&224; [nna]', '&220; [dva]', 'j [jña]', 'ik- [ki]', 'ke- [ke]', 'k [ka]', 'R [r__]', '&229; [ru]', '&197; [ñja]', '&238; [ṣṭva]', '&237;\ [ṣṭra]', 'W [e]', 'We [ai]', 'A [a]', '1 [1]', '2 [2]', '3 [3]', '4 [4]', '5 [5]', '6 [6]', '7 [7]', '8 [8]', '9 [9]', '0 [0]', ') [|]', 'o [u]', '" [ḥ]', '$= [ṭa]', '| [r__][ṁ]', '&236; [śva]', '&162; [kta]', '&241; [stra]', '&214; [ddha]', '[ [_r_]', '&225; [pta]', 'l [la]', 'z [ṣa]', 'G [g_]', '&219; [dya]', '&192; [cca]', '&171; [ṅkha]', '% [kha]', '&196; [ñca]', '&244; [hṛ]', '_ [\']', '\\ [_r_]', '&239; [ṣṭha]', 'g [gh_]', 'n [na]', '&223; [dhva]', 'C [c_]', 'I [_ī]', '&230; [r_][_ū]', '&155; [_ṝ]', '&243; [sra]', '&249; [hya]', '&165; [kna]', 'w [i]', 'x [ṅ_]', '&164; [ktva]', 's [sa]', '&191; [ṅkṣa]', '^ [cha]', '&194; [jja]', '&217; [dbha]', '&242; [sna]', '&170; [ṅka]', ': [kh_]', 'L [l_]', '&218; [dma]', '&130; [s]', '&210; [tna]', '&245; [hṇa]', '&176; [ṅgra]', 'y [ya]', 'f [pha]', '&248; [hma]', '&187; [ṅkta]', '&167; [kra]', '&246; [hna]', '&140; [r__][_ai]', '&251; [hva]', '&226; [pla]', '&213; [dda]', 'H [ñ_]', '&129; [_r_]', '&211; [dga]', 'p [oṁ]', '&137; [ṛ]', '&250; [hla]', '&135; [jha]', '&163; [ktra]', '&186; [ṅgha]', '&163; [ktra]', 'O [ū]', '&200; [ṭva]', '&227; [mla]', '&161; [kka]', '&216; [dba]', '$ [ṭa]', '# [ṭha]', '&235; [śla]', '&205; [ḍva]', '&128; [jñ_]', '&174; [ṅga]', '&156; [kḷ]', '&201; [ḍga]', '... [r_]', '&198; [ṭṭa]', '&193; [cña]', '&232; [ś_]', '&204; [ḍbh_]', '&212; [dgha]', '&206; [ḍhva]', '&131; [--]', '&203; [ḍḍha]', '&138; [ṛ_]', '. [.]', ', [,]', '&202; [ḍḍa]', '&169; [kla]', '(c) [kla]', 'm [^^]', '&231; [lla]', 'm&231; [ḹla]']
r = [a.split(' ') for a in r1]
r.append([' ', ' '])
r.append(['-', ''])
r.append(['/', ''])
r.append(['=', ''])
r.append(['&132;', ''])
#r.append(['<CR>', '\n'])
r = sorted(r, key = lambda k: len(k[0]), reverse=True)

def Indevr2Unicode(text, normalize=False):
    i = 0
    replaced = 0
    res = StringIO()
    arr = []
    debug = False
    if normalize:
        for cr in text:
            res.write(uni2deva.NormalizeChar(cr))
        text = res.getvalue()
    while i<len(text):
        found = False
        for a in r:
            k = len(a[0])
            if text[i:i+k]==a[0]:
                i += k
                if len(a[1])>0:
                    arr.append(a[1])
                found = True
                break
        if not found:
            if text[i]=='&':
                end = text.find(';',i)
                arr.append(text[i:end+1])
                i = end + 1
                replaced += 1
            else:
                arr.append(text[i])
                replaced += 1
                i += 1
    def is_spolu(a):
        return a.endswith('_]') and not a.endswith('__]') and not a.startswith('[_')
    i = 0
    replaced = 0
    if debug:
        print()
        print()
        print('----->  ', arr)
    while i < len(arr):
        al = '' if i==0 else arr[i-1]
        ai = arr[i]
        aj = '' if i==len(arr)-1 else arr[i+1]
        if arr[i]=='[r__]':
            j = i-1
            while j>=0:
                if not arr[j].startswith('[_'):
                    arr[j] = '[r' + arr[j][1:]
                    break
                j -= 1
            if debug: print('----->  ', arr)
            del arr[i]
            i -= 1
        elif arr[i]=='[^^]':
            j = i + 1
            while j < len(arr):
                if arr[j]=='[lla]':
                    arr[j]='[ḹla]'
                    del arr[i]
                    i -= 1
                    break
                j+=1
        elif ai == '[_r_]':
            arr[i-1] = al[:-2] + 'r' + al[-2:]
            if debug: print('----->  ', arr)
            del arr[i]
            i -= 1
        elif ai == '[_.]':
            if (al.endswith('a]') or al.endswith('_]')):
                arr[i-1] = al[:-2] + ']'
            if debug: print('----->  ', arr)
            del arr[i]
            i -= 1
        elif ai=='[_a]' and is_spolu(arr[i-1]):
            arr[i-1] = al[:-2] + 'a]'
            if debug: print('----->  ', arr)
            del arr[i]
            i -= 1
        elif ai=='[_a]' and (al.endswith('a]') or al.endswith('_]')):
            arr[i-1] = al[:-2] + 'ā]'
            if debug: print('----->  ', arr)
            del arr[i]
            i -= 1
        elif ai=='[_u]' and (al.endswith('u]') or al.endswith('_]')):
            arr[i-1] = al[:-2] + 'u]'
            if debug: print('----->  ', arr)
            del arr[i]
            i -= 1
        elif ai=='[_ṛ]' and (al.endswith('a]') or al.endswith('_]')):
            arr[i-1] = al[:-2] + 'ṛ]'
            if debug: print('----->  ', arr)
            del arr[i]
            i -= 1
        elif ai=='[_a]' and al=='[sṁ]':
            arr[i-1] = '[saṁ]'
            del arr[i]
            i -= 1
        elif ai=='[_e]' and (al.endswith('a]') or al.endswith('_]')):
            arr[i-1] = al[:-2] + 'e]'
            if debug: print('----->  ', arr)
            del arr[i]
            i -= 1
        elif ai=='[_ṝ]' and (al.endswith('a]') or al.endswith('_]')):
            arr[i-1] = al[:-2] + 'ṝ]'
            if debug: print('----->  ', arr)
            del arr[i]
            i -= 1
        elif ai=='[_u]' and (al.endswith('a]') or al.endswith('_]')):
            arr[i-1] = al[:-2] + 'u]'
            if debug: print('----->  ', arr)
            del arr[i]
            i -= 1
        elif ai=='[_ū]' and (al.endswith('a]') or al.endswith('_]')):
            arr[i-1] = al[:-2] + 'ū]'
            if debug: print('----->  ', arr)
            del arr[i]
            i -= 1
        elif ai=='[_ī]' and (al.endswith('a]') or al.endswith('_]')):
            arr[i-1] = al[:-2] + 'ī]'
            if debug: print('----->  ', arr)
            del arr[i]
            i -= 1
        elif ai=='[_au]' and (al.endswith('a]') or al.endswith('_]')):
            arr[i-1] = al[:-2] + 'au]'
            if debug: print('----->  ', arr)
            del arr[i]
            i -= 1
        elif ai=='[_ai]' and (al.endswith('a]') or al.endswith('_]')):
            arr[i-1] = al[:-2] + 'ai]'
            if debug: print('----->  ', arr)
            del arr[i]
            i -= 1
        elif ai=='[_ai]' and al.endswith('ā]'):
            arr[i-1] = al[:-2] + 'au]'
            if debug: print('----->  ', arr)
            del arr[i]
            i -= 1
        elif not ai.startswith('[_') and ai.startswith('[') and al.endswith('_]'):
            arr[i] = arr[i-1][:-2] + arr[i][1:]
            if debug: print('----->  ', arr)
            del arr[i-1]
            i -= 2
        elif ai=='[_a]' and al.endswith('^^]') and aj.startswith('[ll'):
            arr[i-1] = arr[i-1][:-3] + 'a]'
            arr[i+1] = '[ḹ' + arr[i+1][2:]
            del arr[i]
            i -= 1
        elif al.endswith('_]'):
            if ai==' ':
                arr[i-1] = arr[i-1][:-2] + ']'
            else:
                arr[i-1] = arr[i-1][:-2] + 'a]'
        i += 1
    i = 0
    while i < len(arr):
        al = '' if i==0 else arr[i-1]
        ai = arr[i]
        if arr[i]=='[__i]':
            j = i + 1
            if debug: print('----->  ', arr)
            while j < i + 4 and j < len(arr):
                if arr[j].endswith('a]') or arr[j].endswith('ā]'):
                    arr[j] = arr[j][:-2] + 'i]'
                    del arr[i]
                    i -= 1
                    break
                j+=1
        elif ai=='[_e]' and al.endswith('ā]'):
            arr[i-1] = al[:-2] + 'o]'
            if debug: print('----->  ', arr)
            del arr[i]
            i -= 1
        i += 1
    if len(arr)>0 and arr[0]=='[_a]':
        arr[0] = '[a]'
    if debug: print('----->  ', arr)
    res.truncate(0)
    res.seek(0)
    for b in arr:
        if not b.startswith('[_') and not b.endswith('_]') and b[0]=='[' and b[-1]==']':
                res.write(b[1:-1])
        elif b=='<CR>':
            res.write('\n')
        else:
            res.write(b)
    text = uni2deva.ConvertToDevanagari(res.getvalue())
    return text
