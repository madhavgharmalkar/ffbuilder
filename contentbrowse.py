
c = []

with open('../fff-out/tables/contents.txt','rt',encoding='utf-8') as file:
    for line in file:
        p = line.split('\t')
        while len(p)<6:
            p.append('')
        c.append(p)


def print_par(par):
    count = 0
    for line in c:
        if line[2]==par:
            print(line)
            count += 1
    return count

hist = []

par = '0'
while True:
    cnt = print_par(par)
    if cnt==0:
        print(f'-- No items for {par} --')
    else:
        hist.append(par)
    par = input('>')
    if par=='exit': break
    if par=='back' or par=='-1':
        par = hist[-1]
        if len(hist)>1:
            hist = hist[:-1]
