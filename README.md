# Folio Database Builder

Ths utility converts FFF files into sqlite3 database.

## Setup

We need to have directory with input files, that contains .FFF file, .DEF file, also subdirectory with objects.
Set this output directory in environment variable, for example by this:

```
export FBUILD_INPUT='/users/myuser/flatfile/VB2000.FFF'
```

Then we need to have prepared empty output directory, where new subdirectories will be writen and all output files.

```
export FBUILD_OUTPUT='/users/myuser/output'
```

## Preparation

These files needs to be checked or corrected before build so we derive maximum benefit from new database. These steps
are optional actually, but may improve the final experience from build and also may enhance user experience at the end.

* names of content items for ffviews.py (`ViewsBuilder.contentItems`)
* keywords file for Indexer.py (`Indexer.keywordFileName`)
* choose if output files are in new or old format (`build_all.py`, `new_db` module variable)

## Run

For complete build of sqlite3 database, go to directory python of this repository and run:

```
cd ffbuilder/python
python3 build_all.py
```

##
