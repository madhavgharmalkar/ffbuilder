from ViewsBuilder import ViewsBuilder
import os


def ViewBuilderRun(output_dir):
    vb = ViewsBuilder()
    vb.levelFile = os.path.join(output_dir, 'tables', 'levels.txt')
    vb.inputFile = os.path.join(output_dir, 'tables', 'texts-b.txt')
    vb.outputDir = os.path.join(output_dir, 'tables')
    vb.contentItems = [
        '02 bhagavad gita as it is',
        '03 srimad bhagavatam bhagavata purana',
        '04 sri caitanya caritamrta'
    ]


    if vb.validate():
        vb.process()


if __name__=='__main__':
    if os.environ.get('FBUILD_OUT')==None:
        print('Missing environment variable FBUILD_OUT with output directory for folio building files (e.g. ../flat-output)')
        exit(0)
    # working directory
    output_dir = os.environ.get('FBUILD_OUT')
    ViewBuilderRun(output_dir)
