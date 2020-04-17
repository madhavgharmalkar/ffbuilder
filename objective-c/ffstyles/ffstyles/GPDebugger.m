//
//  GPDebugger.m
//  Builder_iPad
//
//  Created by Peter Kollath on 3/9/13.
//
//

#import "GPDebugger.h"
#import "GPDebuggerStyleStream.h"

#define PAGE_RECS 10000

GPDebugger * g_instance = nil;
BOOL g_is_debug = NO;
FILE * outputSingle = NULL;
int outputSingleCounter = 0;
int outSingleRecs = 0;
char fileName[256];
NSInteger lineNum = 0;


@implementation GPDebugger


@synthesize dictStyles, dictTags, dictFonts;
@synthesize newerTags;
@synthesize workingDirectory, dumpDirectory, dumpObjectDirectory;

-(id)initWithDirectory:(NSString *)directory
{
    self = [super init];
    if (self) {
        self.workingDirectory = directory;
        self.dictStyles = [[NSMutableDictionary alloc] init];
        self.dictTags = [[NSMutableDictionary alloc] init];
        self.dictFonts = [[NSMutableDictionary alloc] init];
        self.newerTags = [[NSMutableSet alloc] init];
        self.dumpDirectory = [directory stringByAppendingPathComponent:@"tables"];
        self.dumpObjectDirectory = [self.dumpDirectory stringByAppendingPathComponent:@"obj"];
        NSFileManager * manager = [NSFileManager defaultManager];
        [manager createDirectoryAtPath:self.workingDirectory
           withIntermediateDirectories:YES
                            attributes:nil
                                 error:NULL];
        [manager createDirectoryAtPath:self.dumpObjectDirectory
           withIntermediateDirectories:YES
                            attributes:nil
                                 error:NULL];
    }
    return self;
}

+(void)createInstanceWithDirectory:(NSString *)directory
{
    g_instance = nil;
    g_instance = [[GPDebugger alloc] initWithDirectory:directory];
}

+(GPDebugger *)instance
{
    return g_instance;
}

+(void)releaseInstance
{
    if (g_instance) {
        g_instance = nil;
    }
}

+(void)writeFile:(NSString *)fileName text:(NSString *)strText
{
    [strText writeToFile:[[g_instance workingDirectory] stringByAppendingPathComponent:fileName]
              atomically:YES
                encoding:NSUTF8StringEncoding
                   error:NULL];
}

void _writeSingle(NSString *text, NSNumber * num)
{

}


GPDebuggerStyleStream * _styleStream(NSString * styleName)
{
    return nil;
}

GPDebuggerStyleStream * _fontStream(NSString * fontName)
{
    return nil;
}

GPDebuggerStyleStream * _tagStream(NSString * tagName)
{
    return nil;
}

+(void)writeTag:(NSString *)tagName text:(NSString *)aText
{
}

+(NSString *)fileLocation
{
    return [NSString stringWithFormat:@"File:&nbsp;%s<br>line:&nbsp;%ld", fileName, lineNum];
}

+(NSString *)fileLocationPlain
{
    return [NSString stringWithFormat:@"File: %s, line: %ld", fileName, lineNum];
}


void _writeByStyle(NSString *text, NSString *style, NSString * fileLoc, NSNumber * rid)
{
}

void _writeByFont(NSString *text, NSSet *fonts, NSString * fileLoc, NSNumber * rid)
{
}

void _writeByFormating(NSString * begin, NSString * endStr, NSString * filePrefix, NSString *text, NSString *style, NSDictionary * dict)
{
}

+(void)writeText:(NSString *)text style:(NSString *)aStyle dictionary:(NSDictionary *)dict
{
}

+(void)endWrite
{
    GPDebugger * inst = [GPDebugger instance];
    if (outputSingle != NULL) {
        fclose(outputSingle);
        outputSingle = NULL;
    }
    
    if (inst.dictStyles) {
        NSString * key;
        NSEnumerator * enume = [inst.dictStyles keyEnumerator];
        while(key = [enume nextObject]) {
            GPDebuggerStyleStream * gps = [inst.dictStyles objectForKey:key];
            fprintf(gps.file, "</body>\n");
            fprintf(gps.file, "</html>\n");
            fclose(gps.file);
            gps.file = NULL;
        }
        [inst.dictStyles removeAllObjects];
    }

    if (inst.dictFonts) {
        NSMutableString * fontOverviewContent = [[NSMutableString alloc] init];
        NSString * key;
        NSEnumerator * enume = [inst.dictFonts keyEnumerator];
        
        [fontOverviewContent appendFormat:@"<html><head><title>Fonts Overview</title></head>\n"];
        [fontOverviewContent appendFormat:@"<body><h1>Fonts | <a href=\"../example-styles.html\">Styles</a></h1>\n"];
        
        while(key = [enume nextObject]) {
            GPDebuggerStyleStream * gps = [inst.dictFonts objectForKey:key];
            fprintf(gps.file, "</body>\n");
            fprintf(gps.file, "</html>\n");
            fclose(gps.file);
            gps.file = NULL;
            
            [fontOverviewContent appendFormat:@"<p><a href=\"%@.html\">%@</a></p>", key, key];
        }
        [inst.dictFonts removeAllObjects];
        
        [fontOverviewContent appendFormat:@"</body></html>"];
        [fontOverviewContent writeToFile:[[g_instance workingDirectory] stringByAppendingPathComponent:@"by-font/index.html"] atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    }

    if (inst.dictTags) {
        NSString * key;
        NSEnumerator * enume = [inst.dictTags keyEnumerator];
        while(key = [enume nextObject]) {
            GPDebuggerStyleStream * gps = [inst.dictTags objectForKey:key];
            fclose(gps.file);
            gps.file = NULL;
        }
        [inst.dictTags removeAllObjects];
    }
}

+(void)setFileName:(NSString *)str
{
    strcpy(fileName, [str UTF8String]);
}

+(void)setLineNumber:(NSInteger)aLineNum
{
    lineNum = aLineNum;
}


@end
