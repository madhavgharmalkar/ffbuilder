from ContentsBuilder import ContentsBuilder
from Flat import *
import os
import os.path

def ContentBuilderRun(output_dir):
    cc = ContentsBuilder()

    cc.levelFile = os.path.join(output_dir, 'tables', 'levels.txt')
    cc.inputFile = os.path.join(output_dir, 'tables', 'texts.txt')
    cc.outputDir = os.path.join(output_dir, 'tables')

    if cc.validate():
        cc.process()

if __name__=='__main__':
    if os.environ.get('FBUILD_OUT')==None:
        print('Missing environment variable FBUILD_OUT with output directory for folio building files (e.g. ../flat-output)')
        exit(0)
    # working directory
    output_dir = os.environ.get('FBUILD_OUT')
    ContentBuilderRun(output_dir)
