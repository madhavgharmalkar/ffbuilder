import json

r = {
    'images': {},
    'texts': {},
    'colors': {},
    'styles': {}
}
with open('../data/vbstyles.conf','rt',encoding='utf-8') as rt:
    for line in rt:
        line = line.strip()
        if line.startswith('File['):
            p = line[5:].split(']=')
            r['images'][p[0]] = p[1]
            print(line, '-->', p)
        elif line.startswith('Color['):
            p = line[6:].split(']=')
            r['colors'][p[0]] = p[1]
            print(line, '-->', p)
        else:
            print('Discarded:', line)

with open('../data/UISkin.json','wt',encoding='utf-8') as wf:
    wf.write(json.dumps(r,indent=2))
