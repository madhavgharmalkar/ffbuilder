#!/bin/sh
#
# loading files into tables

./bin/sqliteloader -table contents -cols "level:integer,record:integer,parent:integer,title:text,simpletitle:text,subtext:text" -i contents.txt -t vb2014.tbase
./bin/sqliteloader -table words -cols "idx:text,uid:integer,word:text,doffset:integer,dsize:integer" -i words.txt -t vb2014.ivd
./bin/sqliteloader -table docinfo -cols "name:text,valuex:text,idx:integer" -i docinfo.txt -t vb2014.tbase
./bin/sqliteloader -table objects -cols "objectName:text,objectData:blobfile,objectType:text" -i objects.txt -t vb2014.tbase
./bin/sqliteloader -table groups -cols "groupname:text,groupid:integer" -i groups.txt -t vb2014.tbase
./bin/sqliteloader -table groups_detail -cols "groupid:integer,recid:integer" -i groups_detail.txt -t vb2014.tbase
./bin/sqliteloader -table texts -cols "recid:integer,plain:text,levelname:text,stylename:text" -i texts-b.txt -t vb2014.tbase
./bin/sqliteloader -table levels -cols "id:integer,original:text,level:text" -i levels.txt -t vb2014.tbase
./bin/sqliteloader -table popup -cols "title:text,class:text,plain:text" -i popup.txt -t vb2014.tbase
./bin/sqliteloader -table jumplinks -cols "title:text,recid:integer" -i jumplinks.txt -t vb2014.tbase
./bin/sqliteloader -table styles -cols "id:integer,name:text" -i styles.txt -t vb2014.tbase
./bin/sqliteloader -table styles_detail -cols "styleid:integer,name:text,valuex:text" -i styles_detail.txt -t vb2014.tbase
./bin/sqliteloader -table playlists -cols "id:integer,parent:integer,title:text" -i playlists.txt -t vb2014.tbase
./bin/sqliteloader -table playlists_detail -cols "parent:integer,ordernum:integer,objectName:text" -i playlists_detail.txt -t vb2014.tbase
./bin/sqliteloader -table textviews -cols "parent:integer,id:integer,title:text" -i views.txt -t vb2014.tbase
./bin/sqliteloader -table textviews_texts -cols "parent:integer,textid:integer" -i view_details.txt -t vb2014.tbase
./bin/sqliteloader -table dictionary -cols "id:integer,name:text" -i dictionary.txt -t vb2014.tbase
./bin/sqliteloader -table dict_words -cols "id:integer,word:text,simple:text" -i dict_words.txt -t vb2014.tbase
./bin/sqliteloader -table dict_means -cols "wordid:integer,dictid:integer,meaning:text" -i dict_means.txt -t vb2014.tbase

