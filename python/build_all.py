import ffanalyzer
import ffcontents
import ffindexer
import Indexer
import ffviews
import ffplaylists
import ffdictionary
import dbload
import os

if os.environ.get('FBUILD_OUT')==None:
    print('Missing environment variable FBUILD_OUT with output directory for folio building files (e.g. ../flat-output)')
    exit(0)

if os.environ.get('FBUILD_IN')==None:
    print('Missing environment variable FBUILD_IN with input file (e.g. ../flat-input/VB2020.FFF)')
    exit(0)
# working directory
output_dir = os.environ.get('FBUILD_OUT')
input_file = os.environ.get('FBUILD_IN')
new_db = False

print('==== ANALYZER ====')
ffanalyzer.FFAnalyzerRun(output_dir,input_file)

print('==== CONTENTS ====')
ffcontents.ContentBuilderRun(output_dir)

print('==== INDEXING ====')
if new_db:
    ffindexer.FFIndexerRun(output_dir)
else:
    # file keywords3 serves as example
    # there should format for each line:
    # <recordid> TAB <keyword1> SP <keyword2> SP ..... NL
    Indexer.BlobIndexerRun(output_dir,kwFile='../data/keywords3.txt')

print('==== VIEWS ====')
ffviews.ViewBuilderRun(output_dir)

print('==== PLAYLISTS ====')
ffplaylists.PlaylistBuilderRun(output_dir)

print('==== DICTIONARIES ====')
dir_files = ['../data/dict_sp.txt', '../data/dict-monier.txt', '../data/dict-vbase.txt']
ffdictionary.DictionaryBuilderRun(dir_files, output_dir)

print('==== CREATE DATABASE ====')
dbload.CreateDatabase(output_dir,new_db=new_db)
