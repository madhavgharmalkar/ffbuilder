#!/bin/sh
#--*** queries to create tables in database ***

sqlite3 vb2014.tbase <<EOF

create table contents(title text, record integer, parent integer, level integer, simpletitle text, subtext text);
create index icontents on contents(parent);
create index icontents2 on contents(level);

create table words_map(wordid integer, word text);
create index iwordsm on words_map(word);
create table words_scope(idxid integer, idxname text);
create index iwordss on words_scope(idxname);
create table words_idx(wordid integer, idxid integer, recid integer, proximity integer);
create index iwordsi on words_idx(wordid);

--create table words(word text, uid integer, indexbase integer, data blob, idx text);
--create index iwords on words(word);

create table docinfo(name text, valuex text, idx integer);
create table objects(objectName text, objectType text, objectData blob);
create index iobject on objects(objectName);
create table groups(groupid integer, groupname text);
create table groups_detail(groupid integer, recid integer);
create index igroup on groups(groupname);
create index igroup2 on groups_detail(groupid);
create table texts(plain text, recid integer, showid integer, levelname text, stylename text);
create index itexts on texts(recid);
create index itxstyle on texts(stylename);
create table levels(level text, id integer, original text);
create table popup(title text, class text, plain text);
create index ipopup on popup(title);
create table jumplinks(title text, recid integer);
create table styles(name text, id integer);
create table styles_detail(styleid integer, name text, valuex text);
create table playlists(id integer, parent integer, title text);
create table playlists_detail(parent integer, ordernum integer, objectName text);
create table textviews(id integer, parent integer, title text);
create table textviews_texts(parent integer, textid integer);
create table dictionary(id integer, name text);
create table dict_words(id integer, word text, simple text);
create table dict_means(wordid integer, dictid integer, recid integer PRIMARY KEY ASC ON CONFLICT REPLACE AUTOINCREMENT, meaning text);
create index idict_means on dict_means(dictid,wordid);


EOF