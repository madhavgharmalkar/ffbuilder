//
//  TextStream.h
//  fftextdiff
//
//  Created by Peter Kollath on 19/11/14.
//  Copyright (c) 2014 Peter Kollath. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TextRecord.h"
#import "TrianglePosition.h"

@interface TextStream : NSObject
{
    FILE * file;
    char * buffer;
    int bufferSize;
}

@property BOOL eof;
@property NSMutableArray * recBuffer;
@property int indexPos;
@property int textPos;


-(void)openReadTextFile:(NSString *)fileName;
-(void)openWriteTextFile:(NSString *)fileName;
-(void)closeFile;

-(NSString *)readLine;
-(TextRecord *)readRecord;

-(TextRecord *)recordAtIndex:(NSInteger)index;
-(NSInteger)recordCount;
-(void)shift;
-(void)shift:(NSInteger)recs;
-(NSRange)rangeOfRecords;
-(NSRange)rangeOfRecords:(NSInteger)toIndex;
@end
