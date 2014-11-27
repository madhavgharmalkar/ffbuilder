#!/bin/sh
#
# loading files into tables

./bin/sqliteloader -table playlists -cols "id:integer,parent:integer,title:text" -i playlists.txt -t vb2014.ivd
./bin/sqliteloader -table playlists_detail -cols "parent:integer,ordernum:integer,objectName:text" -i playlists_detail.txt -t vb2014.ivd


