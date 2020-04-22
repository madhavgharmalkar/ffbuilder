from PlaylistBuilder import PlaylistBuilder
import os

def PlaylistBuilderRun(output_dir):
    vb = PlaylistBuilder()
    vb.levelFile = os.path.join(output_dir, 'tables', 'levels.txt')
    vb.inputFile = os.path.join(output_dir, 'tables', 'texts-b.txt')
    vb.outputDir = os.path.join(output_dir, 'tables')
    if vb.validate():
        vb.process()

if __name__=='__main__':
    if os.environ.get('FBUILD_OUT')==None:
        print('Missing environment variable FBUILD_OUT with output directory for folio building files (e.g. ../flat-output)')
        exit(0)
    # working directory
    output_dir = os.environ.get('FBUILD_OUT')
    PlaylistBuilderRun(output_dir)
