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
        [manager createDirectoryAtPath:[self.workingDirectory stringByAppendingPathComponent:@"by-tag"]
           withIntermediateDirectories:YES
                            attributes:nil
                                 error:NULL];
        [manager createDirectoryAtPath:[self.workingDirectory stringByAppendingPathComponent:@"by-style"]
           withIntermediateDirectories:YES
                            attributes:nil
                                 error:NULL];
        [manager createDirectoryAtPath:[self.workingDirectory stringByAppendingPathComponent:@"by-rec"]
           withIntermediateDirectories:YES
                            attributes:nil
                                 error:NULL];
        [manager createDirectoryAtPath:[self.workingDirectory stringByAppendingPathComponent:@"by-font"]
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
    NSInteger recid = [num integerValue];
    
    if (outputSingle == NULL) {
        NSString * fileName = [[g_instance workingDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"by-rec/text-%07d.html", outputSingleCounter]];
        outputSingle = fopen([fileName UTF8String], "wt");
        outputSingleCounter++;
        
        fprintf(outputSingle, "<html>\n<head>\n");
        fprintf(outputSingle, "<title>Records</title>\n");
        fprintf(outputSingle, "<link href=\"../styles.css\" type=text/css rel=stylesheet>\n");
        fprintf(outputSingle, "\n");
        fprintf(outputSingle, "</head>\n");
        fprintf(outputSingle, "<body>\n");
    }
    
    fprintf(outputSingle, "<a name=\"rec%ld\">\n", recid);
    fprintf(outputSingle, "%s\n", [text UTF8String]);
    fprintf(outputSingle, "\n");
    fprintf(outputSingle, "\n");
    fprintf(outputSingle, "\n");
    
    outSingleRecs++;
    if (outSingleRecs > PAGE_RECS) {
        fprintf(outputSingle, "</body>\n");
        fprintf(outputSingle, "</html>\n");
        fclose(outputSingle);
        outputSingle = NULL;
        outSingleRecs = 0;
    }
}


GPDebuggerStyleStream * _styleStream(NSString * styleName)
{
    GPDebugger * inst = [GPDebugger instance];
    if (styleName == nil || [styleName length] == 0)
        styleName = @"_none_";
    GPDebuggerStyleStream * gps = [inst.dictStyles objectForKey:styleName];
    if (gps == nil) {
        gps = [[GPDebuggerStyleStream alloc] init];
        NSString * fileName = [[g_instance workingDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"by-style/%@.html", styleName]];
        gps.file = fopen([fileName UTF8String], "wt");
        [inst.dictStyles setObject:gps forKey:styleName];
        fprintf(gps.file, "<html>\n<head>\n");
        fprintf(gps.file, "<title>Records</title>\n");
        fprintf(gps.file, "<link href=\"../styles.css\" type=text/css rel=stylesheet>\n");
        fprintf(gps.file, "\n");
        fprintf(gps.file, "</head>\n");
        fprintf(gps.file, "<body>\n");
        fprintf(gps.file, "<h1>Style: %s</h1>\n", [styleName UTF8String]);
        fprintf(gps.file, "\n");
        fprintf(gps.file, "\n");
        fprintf(gps.file, "\n");
        fprintf(gps.file, "<table border=1 color=black>\n");
    }
    return gps;
}

GPDebuggerStyleStream * _fontStream(NSString * fontName)
{
    GPDebugger * inst = [GPDebugger instance];
    if (fontName == nil)
        fontName = @"_none_";
    GPDebuggerStyleStream * gps = [inst.dictFonts objectForKey:fontName];
    if (gps == nil) {
        gps = [[GPDebuggerStyleStream alloc] init];
        NSString * fileName = [[g_instance workingDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"by-font/%@.html", fontName]];
        gps.file = fopen([fileName UTF8String], "wt");
        [inst.dictFonts setObject:gps forKey:fontName];
        fprintf(gps.file, "<html>\n<head>\n");
        fprintf(gps.file, "<title>Records</title>\n");
        fprintf(gps.file, "<link href=\"../styles.css\" type=text/css rel=stylesheet>\n");
        fprintf(gps.file, "\n");
        fprintf(gps.file, "</head>\n");
        fprintf(gps.file, "<body>\n");
        fprintf(gps.file, "<h1>Font: %s</h1>\n", [fontName UTF8String]);
        fprintf(gps.file, "\n");
        fprintf(gps.file, "\n");
        fprintf(gps.file, "\n");
        fprintf(gps.file, "<table border=1 color=black>\n");
    }
    return gps;
}

GPDebuggerStyleStream * _tagStream(NSString * tagName)
{
    GPDebugger * inst = [GPDebugger instance];
    if (tagName == nil)
        return nil;
    GPDebuggerStyleStream * gps = [inst.dictTags objectForKey:tagName];
    if (gps == nil) {
        NSString * fileName = [[g_instance workingDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"by-tag/%@.txt", tagName]];
        gps = [[GPDebuggerStyleStream alloc] init];
        gps.file = fopen([fileName UTF8String], "wt");
        [inst.dictTags setObject:gps forKey:tagName];
    }
    return gps;
}

+(void)writeTag:(NSString *)tagName text:(NSString *)aText
{
    if (g_is_debug == NO)
        return;
    GPDebuggerStyleStream * gps = _tagStream(tagName);
    if (gps) {
        fprintf(gps.file, "%s\n", [aText UTF8String]);
    }
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
    /*NSRange range = [text rangeOfString:@" style=\""];
    if (range.location == NSNotFound)
        return;*/
    NSInteger recid = [rid integerValue];
    GPDebuggerStyleStream * gps = _styleStream(style);
    fprintf(gps.file, "<tr>\n");
    fprintf(gps.file, "<td><p><a style='font-size:10pt' href=\"../by-rec/text-%07ld.html#rec%ld\">%s</a></td>\n", recid/PAGE_RECS, recid, [fileLoc UTF8String]);
    fprintf(gps.file, "<td>%s</td>", [text UTF8String]);
    fprintf(gps.file, "</tr>\n");
}

void _writeByFont(NSString *text, NSSet *fonts, NSString * fileLoc, NSNumber * rid)
{
    if (fonts == nil)
        return;
    for(NSString * font in fonts)
    {
        NSInteger recid = [rid integerValue];
        GPDebuggerStyleStream * gps = _fontStream(font);
        fprintf(gps.file, "<tr>\n");
        fprintf(gps.file, "<td><p><a style='font-size:10pt' href=\"../by-rec/text-%07ld.html#rec%ld\">%s</a></td>\n", recid/PAGE_RECS, recid, [fileLoc UTF8String]);
        fprintf(gps.file, "<td>%s</td>", [text UTF8String]);
        fprintf(gps.file, "</tr>\n");
    }
}

void _writeByFormating(NSString * begin, NSString * endStr, NSString * filePrefix, NSString *text, NSString *style, NSDictionary * dict)
{
    NSRange range = [text rangeOfString:begin];
    if (range.location != NSNotFound) {
        NSRange range2 = NSMakeRange(range.location + range.length, [text length] - range.location - range.length);
        NSRange r3 = [text rangeOfString:endStr options:0 range:range2];
        if (r3.location != NSNotFound) {
            NSRange r4 = [text rangeOfString:@";" options:0 range:NSMakeRange(range.location + range.length, r3.location - range.location - range.length)];
            if (r4.location == NSNotFound)
            {
                NSString * style = [NSString stringWithFormat:@"%@%@", filePrefix, [text substringWithRange:NSMakeRange(range.location + range.length, r3.location - range.location - range.length)]];
                _writeByStyle(text, style, [dict objectForKey:@"fileLoc"], [dict objectForKey:@"id"]);
            }
        }
    }
}

+(void)writeText:(NSString *)text style:(NSString *)aStyle dictionary:(NSDictionary *)dict
{
    _writeSingle(text, [dict objectForKey:@"id"]);
    
    _writeByStyle(text, aStyle, [dict objectForKey:@"fileLoc"], [dict objectForKey:@"id"]);

    _writeByFormating(@"font-size:", @"%", @"fontsize", text, aStyle, dict);
    _writeByFormating(@"text-indent:", @"pt", @"textindent", text, aStyle, dict);
    
    _writeByFont(text, [dict objectForKey:@"fonts"], [dict objectForKey:@"fileLoc"], [dict objectForKey:@"id"]);
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
