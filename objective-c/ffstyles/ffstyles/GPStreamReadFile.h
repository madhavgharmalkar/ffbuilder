//
//  GPStreamReadFile.h
//  Builder
//
//  Created by Peter Kollath on 9/25/10.
//  Copyright 2010 GPSL. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface GPStreamReadFile : NSObject {

	FILE * fileHandle;
	NSURL * fileName;
}

@property (nonatomic,copy) NSURL * fileName;
@property (assign) NSInteger lineNumber;

-(void)closeFile;
-(NSInteger)getChar;
-(uint64_t)getInt64;
-(uint16_t)getInt16;
-(uint32_t)getInt32;
-(id)initWithFile:(NSURL *)fileNameIn;
-(NSInteger)size;

@end
