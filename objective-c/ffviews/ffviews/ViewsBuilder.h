//
//  ViewsBuilder.h
//  ffviews
//
//  Created by Peter Kollath on 13/11/14.
//  Copyright (c) 2014 Peter Kollath. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ViewDir.h"
#define kMaxLevel 100


@interface ViewsBuilder : NSObject
{
    FILE * outputFile;
    FILE * outputFile2;
    NSString * levelRecs[kMaxLevel];
    NSInteger levelRecIds[kMaxLevel];
    BOOL levelBuildViews[kMaxLevel];
}

@property NSString * outputDir;
@property NSString * inputFile;
@property NSString * levelFile;

@property NSMutableDictionary * levels;
@property NSInteger gid;
@property NSInteger maxLevel;
@property NSInteger globLastLevel;
@property ViewDir * views;

-(BOOL)validate;
-(void)process;

@end
