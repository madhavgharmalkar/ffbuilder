//
//  FlatFileImporter.m
//  Builder
//
//  Created by Peter Kollath on 9/25/10.
//  Copyright 2010 GPSL. All rights reserved.
//

#import "FlatFileImporter.h"
#import "GPStreamReadFile.h"
#import "VBFolioBuilder.h"
#import "GPDebugger.h"

@implementation FlatFileImporter


@synthesize storePath, outputFileName;
@synthesize excludedQLFileName, workingDirectory, indexing, validateQueries, divideFiles;
@synthesize inputPath;
@synthesize requestedCancel;

-(id)init
{
	if ((self = [super init]) != nil)
	{
        _propertiesArray = [[NSMutableArray alloc] init];
		fileQueue = [[NSMutableArray alloc] initWithCapacity:10];
		isUnread = NO;
        self.indexing = YES;
        self.validateQueries = YES;
        self.divideFiles = YES;
        NSMutableArray * dd = [[NSMutableArray alloc] init];
        self.sansDictionaries = dd;
	}
	return self;
}

-(void)dealloc
{
    fileQueue = nil;
    self.propertiesArray = nil;
}


#pragma mark -
#pragma mark File Operations


-(void)openFile:(NSURL *)fileName
{
	GPStreamReadFile * file = [[GPStreamReadFile alloc] initWithFile:fileName];
	[fileQueue insertObject:file atIndex:0];
    [GPDebugger setFileName:[fileName lastPathComponent]];
}

-(NSURL *)currentFileName
{
	if (fileQueue != nil && [fileQueue count] > 0)
		return [((GPStreamReadFile *)[fileQueue objectAtIndex:0]) fileName];
	
	return nil;
}

-(GPStreamReadFile *)currentFile
{
	if (fileQueue != nil && [fileQueue count] > 0)
		return [fileQueue objectAtIndex:0];
	
	return nil;
}

/*
 * This function serves as reading from the succession of files without need
 * of managing moving from one file to another
 * Returns -1 if all files were read.
 */

-(void)unreadChar:(NSInteger)chr
{
	isUnread = YES;
	unreadChar = chr;
}

-(NSInteger)readChar
{
	if (isUnread)
	{
		isUnread = NO;
		return unreadChar;
	}
	
	GPStreamReadFile * gpf = nil;
	NSInteger rc = 0;

	if (fileQueue == nil)
		return -1;

	
	while([fileQueue count] > 0)
	{
		gpf = (GPStreamReadFile *)[fileQueue objectAtIndex:0];

		rc = [gpf getChar];
		if (rc >= 0)
		{
			// this is in most cases
			return rc;
		}
		
		// this will occur only at the end of file
		[fileQueue removeObjectAtIndex:0];
	}
	
	return -1;
}


-(void)openOutputFile:(NSString *)outputFile
{
	NSFileManager * fm = [NSFileManager defaultManager];
	BOOL isdir;
	NSString * outDir = nil;

  
    self.outputFileName = outputFile;
    
	outDir = [outputFile stringByDeletingLastPathComponent];
	
	
	// recreates directory
	[fm createDirectoryAtPath:outDir withIntermediateDirectories:YES attributes:NULL error:NULL];
	
    // sqlite database
	// removes directory
	if ([fm fileExistsAtPath:outputFile isDirectory:&isdir] == YES)
		[fm removeItemAtPath:outputFile error:NULL];

	
}


#pragma mark -
#pragma mark Main Importing Process


-(void)start
{
	[self performSelectorInBackground:@selector(parseFile) withObject:nil];
}

-(void)cancel
{
    cancelPending = YES;
}

//
// process tag in the buffer
//

- (void)processTag:(VBFolioBuilder *)textDB
         tagBuffer:(FlatFileTagString *)tagBuffer
    predefinedKeys:(NSMutableSet *)predefinedKeys
        tagsToOmit:(NSSet *)tagsToOmit
  tagsAddedToPlain:(NSSet *)tagsAddedToPlain

{
    NSString * tagText;
    @try {
        tagText = [tagBuffer tag];
        
        if ([tagsAddedToPlain containsObject:tagText])
        {
            [textDB.currentPlain appendString:[tagBuffer mutableBuffer]];
        }
        
        if ( ! [tagsToOmit containsObject:tagText]
            && ![predefinedKeys containsObject:tagText]) {
            @autoreleasepool {
                NSArray * arr = [tagBuffer createArray];
                [textDB acceptTagArray:arr tagBuffer:tagBuffer];
                if (textDB.requestedFileName != nil) {
                    [self openFile:textDB.requestedFileName];
                    textDB.requestedFileName = nil;
                }
                arr = nil;
            }
        }
    }
    @catch (NSException * e) {
        NSLog(@"Error for tag %@\n%@\n", tagText, [GPDebugger fileLocation]);
    }
    @finally {
    }
}

//
// building folio
//

-(void)parseFile
{
    NSLog(@"start parsing file");

    NSMutableDictionary * contentDict = nil;
    
    @autoreleasepool {
        NSInteger rd = 0;

        int counter = 0;
        int lineNumber = 1;

        VBFolioBuilder * textDB = nil;
        FlatFileTagString * tagBuffer = [[FlatFileTagString alloc] init];
        NSMutableSet * predefinedKeys = [[NSMutableSet alloc] init];
        int brackets = 0;
        
        textDB = [[VBFolioBuilder alloc] initWithDirectory:self.workingDirectory];
        textDB.inputPath = [NSURL fileURLWithPath:self.inputPath];
        [textDB.fileInfo appendFormat:@"FILE=%@\n", [self.outputFileName lastPathComponent]];
        textDB.safeStringReplace = self.safeStringReplace;
        textDB.supressIndexing = !self.indexing;
        textDB.contentDict = contentDict;
        [textDB acceptStart];

        //
        // parse source file
        //
        NSSet * tagsAddedToPlain = [NSSet setWithObjects:@"AUDIO", @"BUILDVIEW", @"BD", @"BD-", @"BD+", @"CTUSE", @"CTDEF", @"CE", @"/CE", @"CR", @"/CS", @"DECOR", @"DL", @"/DL", @"FC", @"FD", @"FLOW", @"FT", @"/FD", @"GP", @"GT", @"GD", @"GM", @"GQ", @"GI", @"GA", @"GF", @"HD", @"HD-", @"HD+", @"HR", @"HS", @"IN", @"IT", @"IT+", @"IT-", @"/JL", @"JU", @"KT", @"KN", @"LH", @"LT", @"LS", @"ML", @"/ML", @"NT", @"/NT", @"PL", @"/PL",  @"PN", @"/PN", @"PT", @"PX", @"/PX", @"RO", @"SB", @"SD", @"SH", @"SO", @"SO-", @"SO+", @"SP", @"/SS", @"TA", @"/TA", @"TB", @"UN", @"UN-", @"UN+", @"WW", @"/WW", @"ETH", @"ETB", @"/ETH", @"ETL", @"/ETL", @"ETS", @"ETX", @"STP", @"STPLAST", @"STPDEF", nil];
        
        NSSet * tagsToOmit = [NSSet setWithObjects:@"AUDIO", @"BUILDVIEW", @"CD", @"CD-", @"CTUSE", @"CTDEF", @"CD+", @"/ETH", @"ETX", @"ETL", @"ETH", @"ETB", @"FLOW", @"FD", @"/FD", @"FE", @"GP", @"KN-", @"KN+", @"KT-", @"KT+", @"HL", @"LS", @"LW", @"OU", @"NT", @"/NT", @"OU-", @"OU+", @"PB", @"PN", @"/PN", @"QT", @"RE", @"RX", @"SH", @"SH+", @"SH-", @"STP", @"STPLAST", @"STPDEF", @"TP", @"TS", @"VI", @"WP", nil];
        // main import procedure
        while (!self.requestedCancel)
        {
            counter++;
            rd = [self readChar];
            if (rd == -1)
                break;
            if (rd == '\n') {
                NSInteger ln = [[self currentFile] lineNumber] + 1;
                [[self currentFile] setLineNumber:ln];
                [GPDebugger setLineNumber:ln];
                lineNumber ++;
            }
            if (brackets == 0) {
                if (rd == '<') {
                    rd = [self readChar];
                    if (rd == -1)
                        break;
                    if (rd == '<') {
                        [textDB acceptChar:rd];
                    } else {
                        [tagBuffer clear];
                        [tagBuffer appendChar:'<'];
                        [tagBuffer appendChar:rd];
                        brackets++;
                    }
                } else {
                    if (rd != '\n' && rd != '\r')
                    {
                        [textDB acceptChar:rd];
                    }
                }
            } else {
                [tagBuffer appendChar:rd];

                if (rd == '<')
                {
                    brackets++;
                }
                else if (rd == '>')
                {
                    brackets--;
                    if (brackets == 0)
                    {
                        [self processTag:textDB tagBuffer:tagBuffer predefinedKeys:predefinedKeys tagsToOmit:tagsToOmit tagsAddedToPlain:tagsAddedToPlain];
                        [tagBuffer clear];
                    }
                }
            }
        }

        [textDB acceptEnd];


        // sending closing message to recognizer
        NSLog(@"Started Saving Files");

        [textDB saveFolio];

        NSMutableString * fileInfo = [[NSMutableString alloc] init];
        [fileInfo setString:textDB.fileInfo];
        [textDB closeDumpFiles];

        
        NSLog(@"Done Saving Files");

        // finishing
        [GPDebugger endWrite];
        [GPDebugger releaseInstance];
        


        NSLog(@"Done Folio Building");
        
    }
    
}

@end










