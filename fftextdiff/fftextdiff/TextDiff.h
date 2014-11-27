//
//  TextDiff.h
//  fftextdiff
//
//  Created by Peter Kollath on 19/11/14.
//  Copyright (c) 2014 Peter Kollath. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TrianglePosition.h"
#import "TextDiffTracker.h"

@class TextStream;

@interface TextDiff : NSObject
{
    int idxfind;
}

@property NSString * fileOldName;
@property NSString * fileNewName;
@property NSString * outputFileName;
@property int indexPos;
@property int textPos;

@property TextStream * fileOld;
@property TextStream * fileNew;
@property TextStream * fileOutput;

@property BOOL printDeleted;
@property BOOL printInserted;
@property BOOL printChanged;
@property BOOL printEqual;


-(BOOL)validate;
-(void)process;

@end
