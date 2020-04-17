from DictionaryBuilder import DictionaryBuilder

def DictionaryBuilderRun(dict_files, output_dir):
    vb = DictionaryBuilder()
    vb.inputFiles = dict_files
    vb.outputDir = '../fff-out/tables'

    if vb.validate():
        vb.process()


if __name__=='__main__':
    if os.environ.get('FBUILD_OUT')==None:
        print('Missing environment variable FBUILD_OUT with output directory for folio building files (e.g. ../flat-output)')
        exit(0)
    # working directory
    output_dir = os.environ.get('FBUILD_OUT')
    dir_files = ['../fff-dict/dict_sp.txt', '../fff-dict/dict-monier.txt']
    DictionaryBuilderRun(dir_files, output_dir)
