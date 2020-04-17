//
//  Indexer.h
//  ffindexer
//
//  Created by Peter Kollath on 13/11/14.
//  Copyright (c) 2014 Peter Kollath. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FlatFileUtils.h"
#import "RKKeySet.h"

@class RKSortedList;

@interface Indexer : NSObject <FlatFileStringIndexerDelegate>
{
    FILE * fileA;
    FILE * fileB;
}

@property NSString * inputFile;
@property NSString * keywordFileName;
@property NSString * outputDir;
@property NSString * errorFile;
@property RKSortedList * wordList;
@property NSCharacterSet * dotsCharset;

@property RKKeySet * wordsMap;
@property RKKeySet * idxMap;

@property NSInteger counter;

-(void)doIndexing;
-(BOOL)validate;

@end
