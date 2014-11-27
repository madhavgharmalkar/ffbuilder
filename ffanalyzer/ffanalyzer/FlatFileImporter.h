//
//  FlatFileImporter.h
//  Builder
//
//  Created by Peter Kollath on 9/25/10.
//  Copyright 2010 GPSL. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FlatFileUtils.h"


#define NUMFLAG_DECIMAL 10
#define NUMFLAG_INT     20
#define NUMFLAG_HEXA    30

//#define NEXT_ACTION(a,b) {rf1status=a; rf1actions=b; }


#define RF2STRING    180
#define RF2DOUBLEDOT 200
#define RF2PLUS      220
#define RF2MINUS     240
#define RF2PERCENT   260
#define RF2EOT       280
#define RF2NUM       300
#define RF2DOLLAR    320
#define RF2COMMA     330
#define RF2SEMICOLON 350


@interface FlatFileImporter : NSObject {


	NSMutableArray * fileQueue;

    BOOL cancelPending;
	NSURL * storePath;
	
	NSInteger unreadChar;
	BOOL isUnread;
    
    NSString * outputFileName;
    NSString * excludedQLFileName;
    BOOL indexing;
    BOOL validateQueries;
    BOOL divideFiles;
    NSString * workingDirectory;
    NSMutableArray * _propertiesArray;
    NSString * inputPath;
    BOOL requestedCancel;
    id delegate;
}

@property (strong, nonatomic) NSMutableDictionary * safeStringReplace;
@property (strong, nonatomic) NSMutableArray * propertiesArray;
@property (nonatomic,copy) NSURL * storePath;
@property (nonatomic, copy) NSString * inputPath;
@property (assign) BOOL requestedCancel;
@property (strong, nonatomic) NSString * excludedQLFileName;
@property (nonatomic, copy) NSString * outputFileName;
@property (nonatomic, copy) NSString * workingDirectory;
@property (assign) BOOL indexing;
@property (assign) BOOL validateQueries;
@property (assign) BOOL divideFiles;
@property (retain) NSString * playlistsFileName;
@property (retain) NSString * viewsFileName;
@property (retain) NSMutableArray * sansDictionaries;

-(void)start;
-(void)openFile:(NSURL *)fileName;
-(NSURL *)currentFileName;
-(void)openOutputFile:(NSString *)outputDir;
-(void)cancel;
-(void)parseFile;

-(NSInteger)readChar;


@end
