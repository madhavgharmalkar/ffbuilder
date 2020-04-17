#!/bin/sh
#
# loading files into tables

./bin/sqliteloader -table dictionary -cols "id:integer,name:text" -i dictionary.txt -t vb2014.ivd
./bin/sqliteloader -table dict_words -cols "id:integer,word:text,simple:text" -i dict_words.txt -t vb2014.ivd
./bin/sqliteloader -table dict_means -cols "wordid:integer,dictid:integer,meaning:text" -i dict_means.txt -t vb2014.ivd

