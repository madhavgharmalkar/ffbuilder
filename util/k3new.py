import os

if os.environ.get('FBUILD_OUT')==None:
    print('Missing environment variable FBUILD_OUT with output directory for folio building files (e.g. ../flat-output)')
    exit(0)

# working directory
output_dir = os.environ.get('FBUILD_OUT')

keywords = []
with open('../data/keywords3.txt','rt',encoding='utf-8') as kf:
    for line in kf:
        p = line.strip('\n').split('\t')
        keywords.append([int(p[0]),p[1]])

mapping = {}
with open(os.path.join(output_dir,'tables','historec.txt'),'rt',encoding='utf-8') as hf:
    for line in hf:
        p = line.strip('\n').split('\t')
        mapping[int(p[0])] = int(p[1])

with open('../data/keywords4.txt','wt',encoding='utf-8') as wf:
    for krec in keywords:
        if krec[0] in mapping:
            nrec = mapping[krec[0]]
            if nrec>0:
                print(f'{nrec}\t{krec[1]}', file=wf)

print('OK')
