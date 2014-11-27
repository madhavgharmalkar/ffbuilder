#!/bin/sh
#
#  build all



./bin/ffanalyzer -i VB00.FFF -dir /Users/gopalapriya/Projects/iFolio/00\ Data/VB2014 -odir /Work/vb2014 -e /Work/errors2014.txt

./bin/ffcontents -l /Work/vb2014/tables/levels.txt -i /Work/vb2014/tables/texts.txt -odir /Work/vb2014/tables

./bin/ffindexer -i /Work/vb2014/tables/texts-b.txt -o /Work/vb2014/tables -k /Work/vb2014/tables/keywords3.txt

./bin/ffviews -i /Work/vb2014/tables/texts-b.txt -l /Work/vb2014/tables/levels.txt -odir /Work/vb2014/tables

./bin/ffplaylists -i /Work/vb2014/tables/texts-b.txt -l /Work/vb2014/tables/levels.txt -odir /Work/vb2014/tables

./bin/ffdictionary -i /Work/dict_sp.txt -i /Work/dict-monier.txt -odir /Work/vb2014/tables

echo -e "Collection\tVB2014\t0" >> docinfo.txt
echo -e "CollectionName\tBhaktivedanta Vedabase 2014\t0" >> docinfo.txt
echo -e "SortKey\t1000\t0" >> docinfo.txt
