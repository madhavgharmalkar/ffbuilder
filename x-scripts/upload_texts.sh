#!/bin/sh
#
# loading files into tables

./bin/sqliteloader -table texts -cols "recid:integer,plain:text,levelname:text,stylename:text" -i texts-b.txt -t vb2014.ivd
