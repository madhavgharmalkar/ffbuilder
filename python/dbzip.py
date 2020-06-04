import zlib
import os


def ZipDatabase(outdir):
    filename = os.path.join(outdir,'data','folio.ivd')
    filetar = os.path.join(outdir,'data','folio.zlib')

    cdata = None
    with open(filename,'rb') as rbb:
        udata = rbb.read()
        cdata = zlib.compress(udata)

    with open(filetar,'wb') as wbb:
        wbb.write(cdata)



if __name__=='__main__':
    if os.environ.get('FBUILD_OUT')==None:
        print('Missing environment variable FBUILD_OUT with output directory for folio building files (e.g. ../flat-output)')
        exit(0)
    # working directory
    output_dir = os.environ.get('FBUILD_OUT')
    ZipDatabase(output_dir)
