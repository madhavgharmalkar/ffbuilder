//
//  GPStreamReadFile.m
//  Builder
//
//  Created by Peter Kollath on 9/25/10.
//  Copyright 2010 GPSL. All rights reserved.
//

#import "GPStreamReadFile.h"


@implementation GPStreamReadFile

@synthesize fileName;

#pragma mark -
#pragma mark Memory Management

-(id)init
{
	if ((self = [super init]) != nil)
	{
		fileName = nil;
		fileHandle = NULL;
        self.lineNumber = 1;
	}
	
	return self;
}

-(id)initWithFile:(NSURL *)fileNameIn
{
	if ([self init] == nil)
		return nil;
	
	self.fileName = fileNameIn;
    if ([[[self fileName] filePathURL] path] == nil)
        return nil;
	fileHandle = fopen([[[[self fileName] filePathURL] path] UTF8String], "rb");
	
	return self;
}

-(void)dealloc
{
	[self closeFile];
}


#pragma mark -
#pragma mark File Operations

-(void)closeFile
{
	if (fileHandle != NULL)
	{
		fclose(fileHandle);
		fileHandle = NULL;
	}
	
    fileName = nil;
}


-(NSInteger)getChar
{
	if (fileHandle == NULL)
		return -1;
	int a;
	char c;
	if (fread(&c, 1, 1, fileHandle) == 0)
	{
		[self closeFile];
		return -1;
	}
	
	a = (int)(unsigned char)c;
	
	//NSLog(@"Readed char %d\n", a);
	
	return a;
}

-(uint16_t)getInt16
{
	if (fileHandle == NULL)
		return -1;
	
	uint16_t rdval;
	
	if (fread(&rdval, sizeof(uint16_t), 1, fileHandle) != 1)
	{
		@throw [NSException exceptionWithName:@"FileReadError"
									   reason:[NSString stringWithFormat:@"Error reading file %@", self.fileName]
									 userInfo:nil];
	}
	
	rdval = CFSwapInt16LittleToHost(rdval);
	
	return rdval;
}

-(uint32_t)getInt32
{
	if (fileHandle == NULL)
		return -1;
	
	uint32_t rdval;
	
	if (fread(&rdval, sizeof(uint32_t), 1, fileHandle) != 1)
	{
		@throw [NSException exceptionWithName:@"FileReadError"
									   reason:[NSString stringWithFormat:@"Error reading file %@", self.fileName]
									 userInfo:nil];
	}
	
	rdval = CFSwapInt32LittleToHost(rdval);
	
	return rdval;
}

-(uint64_t)getInt64
{
	if (fileHandle == NULL)
		return -1;
	
	uint64_t rdval;
	
	if (fread(&rdval, sizeof(uint64_t), 1, fileHandle) != 1)
	{
		@throw [NSException exceptionWithName:@"FileReadError"
									   reason:[NSString stringWithFormat:@"Error reading file %@", self.fileName]
									 userInfo:nil];
	}
	
	rdval = CFSwapInt64LittleToHost(rdval);
	
	return rdval;
}

-(NSInteger)size
{
	int pos = ftell(fileHandle);
	int siz = 0;
	
	fseek(fileHandle, 0, SEEK_END);
	siz = ftell(fileHandle);
	fseek(fileHandle, pos, SEEK_SET);
	//NSLog(@"retrieved file size: %d\n", siz);
	return (NSInteger)siz;
}


@end
