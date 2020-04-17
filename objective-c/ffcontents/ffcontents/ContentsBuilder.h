//
//  ContentsBuilder.h
//  ffcontents
//
//  Created by Peter Kollath on 13/11/14.
//  Copyright (c) 2014 Peter Kollath. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kStackMax     64
#define kContStripMax 240

@interface ContentsBuilder : NSObject
{
    FILE * outputFile;
    FILE * textFile;
    NSMutableDictionary  * contStrips[kContStripMax];
    NSUInteger             levelMapping[kContStripMax];
    NSInteger              lastLevelRecord[kContStripMax];

}

@property NSString * outputDir;
@property NSString * inputFile;
@property NSString * levelFile;
@property NSMutableDictionary * levels;
@property NSCharacterSet * whiteSpaces;
@property NSMutableDictionary * contentTaggedItems;
@property NSMutableDictionary * stpdefs;
@property NSMutableArray * contentArray;

@property (strong) NSMutableDictionary * lastContentItemInserted;

-(BOOL)validate;
-(void)process;

@end
