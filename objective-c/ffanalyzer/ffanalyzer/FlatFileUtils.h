//
//  FFFUtils.h
//  Builder_iPad
//
//  Created by Peter Kollath on 11/9/12.
//  Copyright (c) 2012 GPSL. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol FolioObjectValidator <NSObject>

-(BOOL)jumpExists:(NSString *)jumpDest;


@end

//////////////////////////////////////////////////////////////////////////////////
//
//

@interface FlatFileUtils : NSObject {
}

+(NSString *)encodeLinkSafeString:(NSString *)string;
+(NSString *)decodeLinkSafeString:(NSString *)string;
+(NSString *)removeTags:(NSString *)str;
+(NSString *)removeTagsAndNotes:(NSString *)str;
+(NSString *)makeIndexableString:(NSString *)aString;
+(NSString *)makeDictionaryString:(NSString *)aString;
@end


//////////////////////////////////////////////////////////////////////////////////
//
//

@interface FlatFileTagString : NSObject {

    NSMutableString * _buffer;
    NSMutableString * _extractedTag;
}
-(void)clear;
-(void)appendChar:(char)c;
-(void)appendString:(NSString *)str;
-(NSString *)buffer;
-(NSMutableString *)mutableBuffer;
-(NSArray *)createArray;
-(NSString *)tag;

@end

//////////////////////////////////////////////////////////////////////////////////
//
//

@interface HtmlStyle : NSObject {
    NSString * styleName;
    NSMutableDictionary * format;
    BOOL styleNameChanged;
}
@property (nonatomic,retain) NSString * styleName;
-(NSMutableDictionary *)format;
-(NSString *)valueForKey:(NSString *)str;
-(void)setValue:(NSString *)strValue forKey:(NSString *)strKey;
-(void)clearFormat;
-(NSString *)styleCssText;
-(NSString *)htmlTextForTag:(NSString *)tag;
-(BOOL)styleNameChanged;
-(void)clear;
@end

//////////////////////////////////////////////////////////////////////////////////
//
//


@interface HtmlStyleTracker : HtmlStyle {
    NSMutableDictionary * formatOld;
    NSMutableSet * formatChanges;
}
-(NSMutableSet *)formatChanges;
-(void)clearChanges;
-(BOOL)hasChanges;
@end

//////////////////////////////////////////////////////////////////////////////////
//
//

@interface HtmlStylesCollection : NSObject {
    NSMutableArray * _styles;
}
-(void)addStyle:(HtmlStyle *)style;
-(NSString *)substitutionFontName:(NSString *)fname;
-(NSString *)getMIMEType:(NSString *)str;
@end

//////////////////////////////////////////////////////////////////////////////////
//
//

@interface HtmlString : NSObject {
    NSMutableString * _buffer;
    BOOL acceptText;
}
@property (assign) BOOL acceptText;
-(NSString *)string;
-(BOOL)setString:(NSString *)str;
-(void)clear;
-(BOOL)addCharacter:(unichar)chr;
-(BOOL)appendString:(NSString *)str;
-(NSInteger)indexfOfFirstOccurenceOfTag:(NSString *)strTag;
-(void)insertString:(NSString *)str atIndex:(NSInteger)pos;
@end


//////////////////////////////////////////////////////////////////////////////////
//
//

@interface FlatFileString : NSObject {
    NSMutableString * _buffer;
    BOOL hcParaStarted;
    BOOL hcSpanStarted;
    BOOL hcSup;
    BOOL hcSupChanged;
    BOOL hcSub;
    BOOL hcSubChanged;
    BOOL linkStarted;
    BOOL buttonStarted;
    BOOL ethDefaultExpanded;
    int hcPwCounter;
    int hcNtCounter;
    int hcTableRows;
    int hcTableColumns;
    int catchPwLevel;
    int catchPwCounter;
    int catchNtCounter;
    NSString * ethStyle;
    NSString * ethListImage;
    NSMutableDictionary * ethDict;
    NSMutableArray * ethStack;
    NSString * dataObjectName;
    HtmlStyle * paraStyleRead;
    id validator;
}

@property (copy, nonatomic) NSString * dataObjectName;
@property (strong) HtmlStyle * paraStyleRead;
@property (strong) id<FolioObjectValidator> validator;
@property (nonatomic, retain) NSMutableArray * ethStack;
@property (nonatomic, retain) NSMutableDictionary * ethDict;
@property (nonatomic, copy) NSString * ethListImage;
@property (nonatomic, copy) NSString * ethStyle;
@property (assign) BOOL ethDefaultExpanded;

+(NSString *)stringToSafe:(NSString *)str tag:(NSString *)tag;
+(BOOL)dataLinkAsButton;
+(void)setDataLinkAsButton:(BOOL)bValue;
-(NSString *)string;
-(void)reset;
-(void)setString:(NSString *)string;
-(void)setCatchPwCounter:(int)val;
-(void)setCatchPwLevel:(int)val;
-(void)setCatchNtCounter:(int)val;
+(NSString *)removeTags:(NSString *)str;

@end

//////////////////////////////////////////////////////////////////////////////////
//
//

@class FlatFileStringIndexer;

@protocol FlatFileStringIndexerDelegate <NSObject>

-(void)pushWord:(NSString *)word fromIndexer:(FlatFileStringIndexer *)indexer;
-(void)pushTag:(FlatFileTagString *)tag fromIndexer:(FlatFileStringIndexer *)indexer;
-(void)pushEndfromIndexer:(FlatFileStringIndexer *)indexer;
@end

//////////////////////////////////////////////////////////////////////////////////
//
//

@interface GPMutableInteger : NSObject
{
    NSInteger value;
}

@property (assign,readwrite) NSInteger value;

-(NSInteger)intValue;
-(void)increment;
-(void)decrement;

@end

//////////////////////////////////////////////////////////////////////////////////
//
//

@interface FlatFileStringIndexer : NSObject
{
    id <FlatFileStringIndexerDelegate> delegate;
    NSString * text;
    NSMutableDictionary * properties;
}
@property (nonatomic, copy) NSString * text;
@property (nonatomic, retain) id <FlatFileStringIndexerDelegate> delegate;

-(void)parse;

-(id)objectForKey:(NSString *)key;
-(void)setObject:(id)property forKey:(NSString *)key;

@end






