import sqlite3
import os
import os.path
from io import BytesIO

create_queries = [
'create table docinfo(name text, valuex text, idx integer)',
'create table objects(objectName text, objectType text, objectData blob)',
'create index iobject on objects(objectName)',
'create table groups(groupid integer, groupname text)',
'create table groups_detail(groupid integer, recid integer)',
'create index igroup on groups(groupname)',
'create index igroup2 on groups_detail(groupid)',
'create table levels(level text, id integer, original text)',
'create table histrec(rec2014 integer, rec2019 integer)',
'create table popup(title text, class text, plain text)',
'create index ipopup on popup(title)',
'create table jumplinks(title text, recid integer)',
'create table styles(name text, id integer)',
'create table styles_detail(styleid integer, name text, valuex text)',
'create table playlists(id integer, parent integer, title text)',
'create table playlists_detail(parent integer, ordernum integer, objectName text)',
'create table textviews(id integer, parent integer, title text)',
'create table textviews_texts(parent integer, textid integer)',
'create table dictionary(id integer, name text)',
'create table dict_words(id integer, word text, simple text)',
'create table dict_means(wordid integer, dictid integer, recid integer PRIMARY KEY ASC ON CONFLICT REPLACE AUTOINCREMENT, meaning text)',
'create index idict_means on dict_means(dictid,wordid)',
'create index ihist1 on histrec(rec2014)',
'create table contents(title text, record integer, parent integer, level integer, simpletitle text, subtext text, node_children integer, node_code text, node_type integer, next_sibling integer)',
'create index icontents on contents(parent)',
'create index icontents2 on contents(level)',
'create table words(word text, uid integer, indexbase integer, data blob, idx text)',
'create index iwords on words(word)',
'create table texts(plain text, recid integer, showid integer, levelname text, stylename text)',
'create index itexts on texts(recid)',
'create index itxstyle on texts(stylename)']


tables = [
   {
       "table":"contents",
       "columns":"level:integer,record:integer,parent:integer,title:text,simpletitle:text,subtext:text,node_children:integer,node_code:text,node_type:integer,next_sibling:integer",
       "file":"contents.txt",
       "f_old": True,
       "f_new": False
   },
   {
       "table":"words",
       "columns":"idx:text,uid:integer,word:text,indexbase:integer,data:blob",
       "file":"words_a.txt",
       "f_old": True,
       "f_new": False
   },
   {
       "table":"words",
       "columns":"idx:text,uid:integer,word:text,indexbase:integer,data:blobfile",
       "file":"words_b.txt",
       "f_old": True,
       "f_new": False
   },
   {
      "table":"docinfo",
      "columns":"name:text,valuex:text,idx:integer",
      "file":"docinfo.txt",
      "f_old": True,
      "f_new": True
   },
   {
      "table":"objects",
      "columns":"objectName:text,objectData:blobfile,objectType:text",
      "file":"objects.txt",
      "f_old": True,
      "f_new": True
   },
   {
      "table":"groups",
      "columns":"groupname:text,groupid:integer",
      "file":"groups.txt",
      "f_old": True,
      "f_new": True
   },
   {
      "table":"groups_detail",
      "columns":"groupid:integer,recid:integer",
      "file":"groups_detail.txt",
      "f_old": True,
      "f_new": True
   },
   {
       "table":"texts",
       "columns":"recid:integer,plain:text,levelname:text,stylename:text",
       "file":"texts-b.txt",
       "f_old": True,
       "f_new": False
   },
   {
       "table":"histrec",
       "columns":"rec2014:integer,rec2019:integer",
       "file":"historec.txt",
       "f_old": True,
       "f_new": False
   },
   {
      "table":"levels",
      "columns":"id:integer,original:text,level:text",
      "file":"levels.txt",
      "f_old": True,
      "f_new": True
   },
   {
      "table":"popup",
      "columns":"title:text,class:text,plain:text",
      "file":"popup.txt",
      "f_old": True,
      "f_new": True
   },
   {
      "table":"jumplinks",
      "columns":"title:text,recid:integer",
      "file":"jumplinks.txt",
      "f_old": True,
      "f_new": True
   },
   {
      "table":"styles",
      "columns":"id:integer,name:text",
      "file":"styles.txt",
      "f_old": True,
      "f_new": True
   },
   {
      "table":"styles_detail",
      "columns":"styleid:integer,name:text,valuex:text",
      "file":"styles_detail.txt",
      "f_old": True,
      "f_new": True
   },
   {
      "table":"playlists",
      "columns":"id:integer,parent:integer,title:text",
      "file":"playlists.txt",
      "f_old": True,
      "f_new": True
   },
   {
      "table":"playlists_detail",
      "columns":"parent:integer,ordernum:integer,objectName:text",
      "file":"playlists_details.txt",
      "f_old": True,
      "f_new": True
   },
   {
      "table":"textviews",
      "columns":"parent:integer,id:integer,title:text",
      "file":"views.txt",
      "f_old": True,
      "f_new": True
   },
   {
      "table":"textviews_texts",
      "columns":"parent:integer,textid:integer",
      "file":"view_details.txt",
      "f_old": True,
      "f_new": True
   },
   {
      "table":"dictionary",
      "columns":"id:integer,name:text",
      "file":"dictionary.txt",
      "f_old": True,
      "f_new": True
   },
   {
      "table":"dict_words",
      "columns":"id:integer,word:text,simple:text",
      "file":"dict_words.txt",
      "f_old": True,
      "f_new": True
   },
   {
      "table":"dict_means",
      "columns":"wordid:integer,dictid:integer,recid:integer,meaning:text",
      "file":"dict_means.txt",
      "f_old": True,
      "f_new": True
   }
]

def blob2data(blob):
    stream = BytesIO()
    for i in range(0,len(blob),2):
        stream.write(int(blob[i:i+2],16).to_bytes(1,byteorder='little',signed=False))
    return stream.getvalue()

def applicable_query(query,new_db):
    if new_db:
        return 'f_new' in query and query['f_new']==True
    else:
        return 'f_old' in query and query['f_old']==True

#
# new_db is flag that tells if created database is in new format or old format
# new format means that texts, contents and indexing is outside of sqlite database file
# old format means that everything is included in sqlite db file
#
def CreateDatabase(outdir,initial_queries=create_queries,table_defs=None,new_db=False):
    filename = os.path.join(outdir,'data','folio.ivd')

    if os.path.exists(filename):
        os.remove(filename)

    db = sqlite3.connect(filename)

    c = db.cursor()

    for query in initial_queries:
        c.execute(query)

    db.commit()
    for query in tables:
        if not applicable_query(query,new_db): continue
        columns = [a.split(':') for a in query['columns'].split(',')]
        querytext = 'INSERT INTO ' + query['table'] + '(' + ','.join([c[0] for c in columns]) + ')' + ' VALUES (' + ('?,'*len(columns)).strip(',') + ')'
        data = []
        filePath = os.path.join(outdir,'tables',query['file'])
        if os.path.exists(filePath):
            with open(filePath,'rt',encoding='utf-8') as rf:
                for line in rf:
                    d = []
                    line = line.strip('\n').split('\t')
                    if len(line)==len(columns):
                        for i in range(len(line)):
                            if columns[i][1] == 'integer':
                                d.append(int(line[i]))
                            elif columns[i][1] == 'blobfile':
                                with open(line[i],'rb') as rbf:
                                    d.append(rbf.read())
                            elif columns[i][1] == 'blob':
                                d.append(blob2data(line[i]))
                            else:
                                d.append(line[i])
                        data.append(d)
            print('Query:', querytext, end=' ')
            print('Data:', len(data))
            c.executemany(querytext,data)
            db.commit()
    db.commit()
    db.close()


if __name__=='__main__':
    if os.environ.get('FBUILD_OUT')==None:
        print('Missing environment variable FBUILD_OUT with output directory for folio building files (e.g. ../flat-output)')
        exit(0)
    # working directory
    output_dir = os.environ.get('FBUILD_OUT')
    CreateDatabase(output_dir)
