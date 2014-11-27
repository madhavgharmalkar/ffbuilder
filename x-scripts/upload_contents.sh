#!/bin/sh
#
# loading files into tables

./bin/sqliteloader -table contents -cols "level:integer,record:integer,parent:integer,title:text,simpletitle:text,subtext:text" -i contents.txt -t vb2014.ivd


