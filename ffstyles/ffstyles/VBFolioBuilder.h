//
//  FolioTextDatabase.h
//  Builder
//
//  Created by Peter Kollath on 10/14/10.
//  Copyright 2010 GPSL. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RKSortedList.h"
#import "FlatFileUtils.h"
#import "RKKeySet.h"

#define CURM_NONE  0
#define CURM_TEXT  1
#define CURM_NOTE  2

#define kStackMax     64
#define kContStripMax 240


//@class FlatFileImporter;

@class FlatFileImporter;

@interface VBFolioBuilder : NSObject {

	//IBOutlet FlatFileImporter * importer;
	NSMutableString      * fileInfo;
	NSMutableDictionary  * currFields;	
    NSMutableDictionary  * definedObjects;
	NSMutableArray       * contRoot;
	NSMutableArray       * temparrStyles;
	RKSortedList         * wordList;
    NSMutableArray       * contentArray;
	NSMutableDictionary  * contStrips[kContStripMax];
    NSMutableArray       * linkRefs;
	NSUInteger             levelMapping[kContStripMax];
    NSInteger              lastLevelRecord[kContStripMax];
	NSMutableString      * strHelper;
	NSMutableString      * strBuff;
    NSMutableString      * strCurrentPlain;
	NSMutableArray       * levels;
	NSString             * spanClass;
	NSCharacterSet       * whiteSpaces;
    NSMutableString      * strInsertA;
    NSMutableDictionary  * contentDict;
    
    // dictionary of type Dictionary<string,List<Dictionary>>
    NSMutableDictionary  * contentTaggedItems;

    // 3rd generation
    NSMutableArray * records;
    NSMutableArray * notes;
    NSMutableArray * recordStack;
    NSMutableArray * contentStack;
    
    NSMutableDictionary * speedFontGroupStyle;
    NSMutableDictionary * speedFontNameStyle;
    NSMutableDictionary * speedFontGroupName;
    HtmlString * targetHtmlRec;
	
	BOOL flagSub;
	BOOL flagSup;
	BOOL flagSpan;
	BOOL commentText;
    NSInteger inclusionPathIndex;
    NSInteger includesIndex;
	BOOL bCharToBuff;
	int fontGroup;
	int  tagCount;
	int  currentRecordID;
	float textSizeMultiplier;
    int previousFontGroup;
	
	int shouldFlush;
    BOOL supressIndexing;
    NSSet * excludedQueryLinks;
    FILE * fileTableDocinfo;
    FILE * fileTableObjects;
    FILE * fileTableLevels;
    FILE * fileTableStyles;
    FILE * fileTableStylesDetail;
	
}

@property (weak) FlatFileImporter * importer;
@property (nonatomic,retain) NSMutableArray * levels;
@property (readonly) NSMutableString * currentPlain;
@property (readonly) NSMutableString * currentClass;
@property (nonatomic,retain) NSMutableString * fileInfo;
@property (assign,readwrite) int currentRecordID;
@property (nonatomic, retain) NSString * spanClass;
@property (nonatomic, retain) NSCharacterSet * whiteSpaces;
@property (assign) double progressMax;
@property (strong, nonatomic) NSMutableDictionary * safeStringReplace;
@property (strong, nonatomic) NSMutableDictionary * paraUsageCounter;
@property (strong, nonatomic) NSMutableDictionary * speedFontGroupStyle;
@property (strong, nonatomic) NSMutableDictionary * speedFontNameStyle;
@property (strong, nonatomic) NSMutableDictionary * speedFontGroupName;
@property (strong, nonatomic) NSMutableDictionary * contentDict;
@property (strong) NSMutableDictionary * lastContentItemInserted;
@property RKKeySet * groupMap;

// dictionary of dictionaries
// stpdefs->{target}
// this should return dictionary for target string, where target string is level name (safe format)
@property (strong, nonatomic) NSMutableDictionary * stpdefs;

@property (strong, nonatomic) NSURL * inputPath;
@property (strong, nonatomic) NSURL * requestedFileName;
@property (strong, nonatomic) NSSet * excludedQueryLinks;
@property (assign) BOOL linkTagStarted;
@property (assign) BOOL supressIndexing;
@property (nonatomic, retain) HtmlString * targetHtmlRec;
@property (assign) int lastInlinePopup;

-(id)initWithDirectory:(NSString *)directory;
-(void)acceptStart;
-(void)acceptEnd;
-(void)acceptTagArray:(NSArray *)tagArr tagBuffer:(FlatFileTagString *)tagStr;
-(void)acceptChar:(NSInteger)rfChar;
-(void)closeDumpFiles;
-(void)saveFolio;

+(NSInteger)balaramToOemSize:(NSInteger)uniChar;
+(NSInteger)sanskritTimesToUnicode:(NSInteger)uniChar;
+(NSInteger)balaramToUnicode:(NSInteger)uniChar;

-(void)restoreCurrentTarget;
-(NSMutableDictionary *)recordWillStartRead:(NSString *)strType;
-(void)recordDidEndRead;
-(NSUInteger)getLevelIndex:(NSString *)levelName;
-(uint32_t)getStyleIndex:(NSString *)styleName;
-(uint32_t)getCurrStyleIndex:(NSMutableDictionary *)rec;
-(int)fontGroupFromFontName:(NSString *)fname;
-(int)fontGroupFromStyle:(NSString *)sname;
-(int)createLinkRef:(NSString *)str;
-(NSMutableString *)currentLevel;

@end
