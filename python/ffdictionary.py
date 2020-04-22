from DictionaryBuilder import DictionaryBuilder

def DictionaryBuilderRun(dict_files, output_dir):
    vb = DictionaryBuilder()
    vb.inputFiles = dict_files
    vb.outputDir = output_dir

    if vb.validate():
        vb.process()


if __name__=='__main__':
    if os.environ.get('FBUILD_OUT')==None:
        print('Missing environment variable FBUILD_OUT with output directory for folio building files (e.g. ../flat-output)')
        exit(0)
    # working directory
    output_dir = os.environ.get('FBUILD_OUT')
    dir_files = ['../data/dict-sp.txt', '../data/dict-monier.txt', '../data/dict-vbase.txt']
    DictionaryBuilderRun(dir_files, output_dir)
