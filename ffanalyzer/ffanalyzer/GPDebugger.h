//
//  GPDebugger.h
//  Builder_iPad
//
//  Created by Peter Kollath on 3/9/13.
//
//

#import <Foundation/Foundation.h>

@interface GPDebugger : NSObject
{
    NSMutableDictionary * dictStyles;
    NSMutableDictionary * dictTags;
    NSMutableDictionary * dictFonts;
    NSMutableSet * newerTags;
    NSString * workingDirectory;
    NSString * dumpDirectory;
    NSString * dumpObjectDirectory;
}

@property (nonatomic,retain) NSMutableDictionary * dictStyles;
@property (nonatomic,retain) NSMutableDictionary * dictTags;
@property (nonatomic,retain) NSMutableDictionary * dictFonts;
@property (nonatomic,retain) NSMutableSet * newerTags;
@property (nonatomic, copy) NSString * workingDirectory;
@property (nonatomic, copy) NSString * dumpDirectory;
@property (nonatomic, copy) NSString * dumpObjectDirectory;

+(void)createInstanceWithDirectory:(NSString *)directory;
+(GPDebugger *)instance;
+(void)releaseInstance;
+(void)writeFile:(NSString *)fileName text:(NSString *)strText;
+(void)writeText:(NSString *)text style:(NSString *)aStyle dictionary:(NSDictionary *)dict;
+(void)endWrite;
+(NSString *)fileLocation;
+(NSString *)fileLocationPlain;
+(void)setFileName:(NSString *)str;
+(void)setLineNumber:(NSInteger)lineNum;
+(void)writeTag:(NSString *)tagName text:(NSString *)aText;

@end
