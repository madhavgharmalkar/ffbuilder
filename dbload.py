import sqlite3
import os
import os.path

create_queries = [
'create table docinfo(name text, valuex text, idx integer)',
'create table objects(objectName text, objectType text, objectData blob)',
'create index iobject on objects(objectName)',
'create table groups(groupid integer, groupname text)',
'create table groups_detail(groupid integer, recid integer)',
'create index igroup on groups(groupname)',
'create index igroup2 on groups_detail(groupid)',
'create table levels(level text, id integer, original text)',
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
'create table contents(title text, record integer, parent integer, level integer, simpletitle text, subtext text)',
'create index icontents on contents(parent)',
'create index icontents2 on contents(level)',
'create table words(word text, uid integer, indexbase integer, data blob, idx text)',
'create index iwords on words(word)',
'create table texts(plain text, recid integer, showid integer, levelname text, stylename text)',
'create index itexts on texts(recid)',
'create index itxstyle on texts(stylename)']


tables = [
   {
      "table":"docinfo",
      "columns":"name:text,valuex:text,idx:integer",
      "file":"docinfo.txt"
   },
   {
      "table":"objects",
      "columns":"objectName:text,objectData:blobfile,objectType:text",
      "file":"objects.txt"
   },
   {
      "table":"groups",
      "columns":"groupname:text,groupid:integer",
      "file":"groups.txt"
   },
   {
      "table":"groups_detail",
      "columns":"groupid:integer,recid:integer",
      "file":"groups_detail.txt"
   },
   {
      "table":"levels",
      "columns":"id:integer,original:text,level:text",
      "file":"levels.txt"
   },
   {
      "table":"popup",
      "columns":"title:text,class:text,plain:text",
      "file":"popup.txt"
   },
   {
      "table":"jumplinks",
      "columns":"title:text,recid:integer",
      "file":"jumplinks.txt"
   },
   {
      "table":"styles",
      "columns":"id:integer,name:text",
      "file":"styles.txt"
   },
   {
      "table":"styles_detail",
      "columns":"styleid:integer,name:text,valuex:text",
      "file":"styles_detail.txt"
   },
   {
      "table":"playlists",
      "columns":"id:integer,parent:integer,title:text",
      "file":"playlists.txt"
   },
   {
      "table":"playlists_detail",
      "columns":"parent:integer,ordernum:integer,objectName:text",
      "file":"playlists_details.txt"
   },
   {
      "table":"textviews",
      "columns":"parent:integer,id:integer,title:text",
      "file":"views.txt"
   },
   {
      "table":"textviews_texts",
      "columns":"parent:integer,textid:integer",
      "file":"view_details.txt"
   },
   {
      "table":"dictionary",
      "columns":"id:integer,name:text",
      "file":"dictionary.txt"
   },
   {
      "table":"dict_words",
      "columns":"id:integer,word:text,simple:text",
      "file":"dict_words.txt"
   },
   {
      "table":"dict_means",
      "columns":"wordid:integer,dictid:integer,recid:integer,meaning:text",
      "file":"dict_means.txt"
   }
]

tables_extra = [
    {
        "table":"contents",
        "columns":"level:integer,record:integer,parent:integer,title:text,simpletitle:text,subtext:text",
        "file":"contents.txt"
    },
    {
        "table":"texts",
        "columns":"recid:integer,plain:text,levelname:text,stylename:text",
        "file":"texts-b.txt"
    }
]

#
# new_db is flag that tells if created database is in new format or old format
# new format means that texts, contents and indexing is outside of sqlite database file
# old format means that everything is included in sqlite db file
#
def CreateDatabase(outdir,initial_queries=create_queries,table_defs=None,new_db=False):
    filename = os.path.join(outdir,'data','folio.db')

    if os.path.exists(filename):
        os.remove(filename)

    db = sqlite3.connect(filename)

    c = db.cursor()

    for query in initial_queries:
        c.execute(query)

    db.commit()
    if table_defs==None:
        if new_db:
            table_defs = tables
        else:
            table_defs = tables + tables_extra
    for query in table_defs:
        columns = [a.split(':') for a in query['columns'].split(',')]
        querytext = 'INSERT INTO ' + query['table'] + ' VALUES (' + ('?,'*len(columns)).strip(',') + ')'
        data = []
        with open(os.path.join(outdir,'tables',query['file']),'rt',encoding='utf-8') as rf:
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
