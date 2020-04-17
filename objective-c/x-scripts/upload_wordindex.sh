#!/bin/sh
#
# loading files into tables

./bin/sqliteloader -table words -cols "idx:text,uid:integer,word:text,indexbase:integer,data:blob" -i words_a.txt -t vb2014.ivd
./bin/sqliteloader -table words -cols "idx:text,uid:integer,word:text,indexbase:integer,data:blob" -i words_b.txt -t vb2014.ivd


