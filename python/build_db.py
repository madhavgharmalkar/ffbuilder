import dbload

import os
import time

if os.environ.get('FBUILD_OUT')==None:
    print('Missing environment variable FBUILD_OUT with output directory for folio building files (e.g. ../flat-output)')
    exit(0)

# working directory
output_dir = os.environ.get('FBUILD_OUT')
new_db = False



print('==== CREATE DATABASE ====')
dbload.CreateDatabase(output_dir,new_db=new_db)
