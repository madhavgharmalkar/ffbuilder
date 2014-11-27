//
//  DictionaryBuilder.h
//  ffdictionary
//
//  Created by Peter Kollath on 13/11/14.
//  Copyright (c) 2014 Peter Kollath. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DictionaryBuilder : NSObject
{
    FILE * fileMean;
    FILE * fileInst;
    FILE * fileWord;
}

@property NSString * outputDir;
@property NSMutableArray * inputFiles;
@property NSString * levelFile;


-(BOOL)validate;
-(void)process;

@end
