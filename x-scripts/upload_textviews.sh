#!/bin/sh
#
# loading files into tables

./bin/sqliteloader -table textviews -cols "parent:integer,id:integer,title:text" -i views.txt -t vb2014.ivd
./bin/sqliteloader -table textviews_texts -cols "parent:integer,textid:integer" -i view_details.txt -t vb2014.ivd


