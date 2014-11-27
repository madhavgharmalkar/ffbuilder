//
//  PlaylistBuilder.h
//  ffplaylists
//
//  Created by Peter Kollath on 13/11/14.
//  Copyright (c) 2014 Peter Kollath. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kMaxLevel 100

@interface PlaylistBuilder : NSObject
{
    FILE * outputFile;
    FILE * outputFile2;
    NSString * levelRecs[kMaxLevel];
    NSInteger levelRecIds[kMaxLevel];
}

@property NSString * outputDir;
@property NSString * inputFile;
@property NSString * levelFile;

@property NSMutableDictionary * levels;
@property NSUInteger maxLevel;
@property NSInteger gid;
@property NSRegularExpression * regex1;
@property NSRegularExpression * regex2;
@property NSMutableDictionary * printedRecs;

-(BOOL)validate;
-(void)process;


@end
