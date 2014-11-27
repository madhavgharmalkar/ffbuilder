//
//  ContentsBuilder.m
//  ffcontents
//
//  Created by Peter Kollath on 13/11/14.
//  Copyright (c) 2014 Peter Kollath. All rights reserved.
//

#import "ContentsBuilder.h"
#import "FlatFileUtils.h"

@implementation ContentsBuilder

-(id)init
{
    self = [super init];
    if (self)
    {
        self.whiteSpaces = [NSCharacterSet whitespaceAndNewlineCharacterSet];
        self.contentTaggedItems = [[NSMutableDictionary alloc] init];
        self.stpdefs = [[NSMutableDictionary alloc] init];
        self.contentArray = [[NSMutableArray alloc] init];

    }
    return self;
}


-(BOOL)validate
{
    return (self.inputFile.length > 0 && self.outputDir.length > 0 && self.levelFile.length > 0);
}

-(void)loadLevels
{
    self.levels = [NSMutableDictionary new];
    NSString * str = [NSString stringWithContentsOfFile:self.levelFile
                                               encoding:NSUTF8StringEncoding
                                                  error:NULL];
    NSArray * lines = [str componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    for (NSString * line in lines)
    {
        NSArray * parts = [line componentsSeparatedByString:@"\t"];
        if (parts.count == 3)
        {
            [[self levels] setObject:[NSNumber numberWithInt:[(NSString *)parts[0] intValue]]
                              forKey:parts[2]];
        }
    }
}

-(void)process
{
    [self loadLevels];
    
    int count = 0;
    int len = 0;
    FILE * i = fopen([self.inputFile UTF8String], "rt");
    
    self->outputFile = fopen([[self.outputDir stringByAppendingPathComponent:@"contents.txt"] UTF8String], "wt");
    self->textFile = fopen([[self.outputDir stringByAppendingPathComponent:@"texts-b.txt"] UTF8String], "wt");

    char *c = malloc(200000);
    while((c = fgets(c, 200000, i)) != NULL)
    {
        len = (int)strlen(c);
        if (len > 0 && c[len-1] == '\n')
            c[len-1] = '\0';
        NSString * line = [NSString stringWithUTF8String:c];
        NSArray * part = [line componentsSeparatedByString:@"\t"];
        NSString * text = part[1];
        NSString * levelName = part[2];
        NSString * styleName = part[3];
        NSInteger recId = [part[0] integerValue];

        NSMutableDictionary * dict = [NSMutableDictionary new];
        [dict setObject:[NSNumber numberWithInteger:recId] forKey:@"RECORDID"];
        [dict setObject:part[2] forKey:@"LEVELNAME"];
        [dict setObject:part[3] forKey:@"STYLENAME"];
        [dict setObject:@"plain" forKey:@"curr_flow"];
        [dict setObject:[NSMutableString new] forKey:@"plain"];
        [self setDict:dict withText:text];
        
        fprintf(self->textFile, "%ld\t%s\t%s\t%s\n", recId,
                [(NSString *)[dict valueForKey:@"plain"] UTF8String],
                (levelName ? [levelName UTF8String] : ""),
                (styleName ? [styleName UTF8String] : ""));
        
        [self processText:dict];
        count ++;
        
        if (count % 1000 == 0) {
            NSString * str = [NSString stringWithFormat:@"processed %d lines", count];
            printf("%s", str.UTF8String);
            for(int i = 0; i < str.length; i++)
            {
                printf("\b");
            }
            fflush(stdout);
        }
    }
    
    [self saveContents];
    
    fclose(i);
    fclose(self->outputFile);
    fclose(self->textFile);
}


-(void)processText:(NSDictionary *)dict
{
    NSString * text = [dict valueForKey:@"plain"];
    NSInteger recId = [[dict valueForKey:@"RECORDID"] integerValue];
    NSString * style = [dict valueForKey:@"STYLENAME"];
    NSString * level = [dict valueForKey:@"LEVELNAME"];
    
    NSDictionary * contentBuilding = [self.lastContentItemInserted objectForKey:@"STPDEF"];
    if (contentBuilding != nil)
    {
        NSString * hook = [contentBuilding objectForKey:level];
        
        if (hook == nil)
        {
            hook = [contentBuilding objectForKey:style];
        }
        
        if (hook != nil)
        {
            NSString * plainText = [self makeContentTextFromRecord:text];
            NSString * addedText = [NSString stringWithFormat:@"<STP:%@>%@", hook, plainText];
            NSMutableString * target = [self.lastContentItemInserted objectForKey:@"subtext"];
            [target appendString:addedText];
        }
    }
    
    // save record to contents
    [self saveRecordToContents:dict];

}

-(NSString *)makeContentTextFromRecord:(NSString *)plainText
{
    NSString * contentTextCandidate = plainText;
    
    NSRange bh = [plainText rangeOfString:@"<BH>"];
    NSRange eh = [plainText rangeOfString:@"<EH>"];
    NSRange rng;
    
    if (bh.location != NSNotFound)
    {
        if (eh.location != NSNotFound && eh.location > bh.location) {
            rng = NSMakeRange(bh.location + bh.length, eh.location - bh.location - bh.length);
        } else {
            rng = NSMakeRange(bh.location + bh.length, plainText.length - bh.location - bh.length);
        }
        contentTextCandidate = [[contentTextCandidate substringWithRange:rng] stringByTrimmingCharactersInSet:self.whiteSpaces];
    }
    else {
        contentTextCandidate = [contentTextCandidate stringByTrimmingCharactersInSet:self.whiteSpaces];
    }
    
    return [FlatFileUtils removeTagsAndNotes:contentTextCandidate];
}

-(NSUInteger)getLevelIndex:(NSString *)levelName
{
    if (levelName == nil || [levelName length] == 0)
        return NSNotFound;
    
    NSNumber * index = [self.levels objectForKey:levelName];
    if (index != nil) {
        return [index unsignedIntegerValue];
    }

    return NSNotFound;
}

-(BOOL)checkSupressedContentLevel:(NSUInteger)nLevel
{
    for (int i = kContStripMax - 1; i >= 0; i--)
    {
        if (contStrips[i] != nil && [contStrips[i] valueForKey:@"STPLAST"] != nil)
        {
            NSString * str = [contStrips[i] valueForKey:@"STPLAST"];
            if (str != nil) {
                NSUInteger level = [self getLevelIndex:str];
                // first STPLAST found is actually last STPLAST defined
                // so last STPLAST overrides all previously defined
                // therefore return after evaluating level index
                // :: current level (nLevel) must not be higher than level of found STPLAST
                // :: in order to write content item into contents
                return (level < nLevel);
            }
        }
    }
    
    return NO;
}

-(void)setDict:(NSMutableDictionary *)dict withText:(NSString *)str
{
    if (str == nil)
        return;
    
    int start = 0;
    int end = 0;
    int status = 0;
    BOOL foundTag = NO;
    BOOL foundChar = NO;
    BOOL foundCharSpec = NO;
    
    for(int i = 0; i < [str length]; i++)
    {
        if (status == 0) {
            if ([str characterAtIndex:i] == '<') {
                status = 1;
            } else {
                foundChar = YES;
            }
        } else if (status == 1) {
            if ([str characterAtIndex:i] == '<') {
                status = 0;
                foundCharSpec = YES;
            } else {
                start = i-1;
                status = 2;
            }
        } else if (status == 2) {
            if ([str characterAtIndex:i] == '>') {
                end = i;
                foundTag = YES;
                status = 0;
            } else if ([str characterAtIndex:i] == '"') {
                status = 3;
            }
        } else if (status == 3) {
            if ([str characterAtIndex:i] == '"') {
                status = 4;
            }
        } else if (status == 4) {
            if ([str characterAtIndex:i] == '"') {
                status = 3;
            } else if ([str characterAtIndex:i] == '>') {
                end = i;
                foundTag = YES;
                status = 0;
            }
        }
        
        if (foundTag == YES) {
            NSRange foundRange = NSMakeRange(start, end - start + 1);
            NSString * extractedTag = [str substringWithRange:foundRange];
            FlatFileTagString * tag = [FlatFileTagString new];
            [tag clear];
            [tag appendString:extractedTag];
            foundTag = NO;
            NSArray * arr = [tag createArray];

            if ([arr[0] isEqualToString:@"FLOW"])
            {
                [dict setObject:arr[2] forKey:@"curr_flow"];
            }
            else if ([arr[0] isEqualToString:@"STPLAST"])
            {
                if ([arr count] == 1)
                {
                    [dict setValue:@"" forKey:@"STPLAST"];
                }
                else if ([arr count] == 3)
                {
                    NSString * paraName = [arr objectAtIndex:2];
                    NSString * safeString = [FlatFileString stringToSafe:paraName tag:@"LE"];
                    [dict setValue:safeString forKey:@"STPLAST"];
                }
            }
            else if ([arr[0] isEqualToString:@"CTDEF"]) {
                if ([arr count] > 2)
                {
                    [dict setValue:[arr objectAtIndex:2] forKey:@"ctdef"];
                }
            }
            else if ([arr[0] isEqualToString:@"CTUSE"]) {
                if ([arr count] > 2)
                {
                    [dict setValue:[arr objectAtIndex:2] forKey:@"ctuse"];
                }
            } else if ([arr[0] isEqualToString:@"STPDEF"]) {
                if ([arr count] == 1)
                {
                    [self.stpdefs removeAllObjects];
                }
                else if ([arr count] == 5)
                {
                    [self.stpdefs removeObjectForKey:[arr objectAtIndex:4]];
                }
                else if ([arr count] == 13)
                {
                    // tagArr[2] must be equal to LV
                    // tagArr[10] must be equal to STP
                    NSString * targetString = [FlatFileString stringToSafe:arr[4] tag:@"LE"];
                    NSString * hookString = [FlatFileString stringToSafe:[arr objectAtIndex:8]
                                                                     tag:[arr objectAtIndex:6]];
                    NSMutableDictionary * targetDict = nil;
                    
                    targetDict = [self.stpdefs objectForKey:targetString];
                    if (targetDict == nil)
                    {
                        targetDict = [[NSMutableDictionary alloc] init];
                        [self.stpdefs setObject:targetDict forKey:targetString];
                    }
                    
                    [targetDict setObject:[arr objectAtIndex:12] forKey:hookString];
                }
            }
            else
            {
                NSMutableString * ms = [self currentFlowText:dict];
                [ms appendString:extractedTag];
            }
        }
        else if (foundChar == YES)
        {
            NSMutableString * ms = [self currentFlowText:dict];
            [ms appendFormat:@"%C", [str characterAtIndex:i]];
            foundChar = NO;
        }
        else if (foundCharSpec == YES)
        {
            NSMutableString * ms = [self currentFlowText:dict];
            [ms appendFormat:@"<<"];
            foundCharSpec = NO;
        }
    }
    
    return;

}

-(NSMutableString *)currentFlowText:(NSMutableDictionary *)dict
{
    NSMutableString * ms = [dict objectForKey:[dict objectForKey:@"curr_flow"]];
    if (ms == nil) {
        ms = [NSMutableString new];
        [dict setObject:ms forKey:[dict objectForKey:@"curr_flow"]];
    }
    return ms;
}

-(void)saveRecordToContents:(NSDictionary *)dict
{
    NSInteger parentRecordId;
    NSInteger thisRecordId = [(NSNumber *)[dict valueForKey:@"RECORDID"] integerValue];
    NSString * levelName = [dict valueForKey:@"LEVELNAME"];
    NSUInteger level = NSNotFound;
    
    if (levelName == nil)
        return;
    
    if ([dict valueForKey:@"ctuse"] != nil)
    {
        NSString * contentText = [self makeContentTextFromRecord:[dict valueForKey:@"plain"]];
        NSString * simpleContentText = [self makeSimpleContentText:contentText];
        NSMutableDictionary * contentItem =  [[NSMutableDictionary alloc] initWithCapacity:6];
        
        [contentItem setValue:[dict valueForKey:@"id"] forKey:@"record"];
        [contentItem setValue:contentText forKey:@"text"];
        [contentItem setValue:simpleContentText forKey:@"simpletitle"];
        
        NSMutableArray * children = [self.contentTaggedItems valueForKey:[dict valueForKey:@"ctuse"]];
        [children addObject:contentItem];
    }
    
    level = [self getLevelIndex:levelName];
    
    
    if ([self checkSupressedContentLevel:level])
        return;
    
    // if no level defined, then this record is not part of contents
    if (level == NSNotFound || level >= kContStripMax)
        return;
    
    // writes last record to level
    for(NSUInteger i = level; i < kContStripMax; i++) {
        lastLevelRecord[i] = -1;
        contStrips[i] = nil;
    }
    
    lastLevelRecord[level] = thisRecordId;
    contStrips[level] = [[NSMutableDictionary alloc] init];
    [contStrips[level] setValue:[dict valueForKey:@"STPLAST"] forKey:@"STPLAST"];
    
    // gets parent for current record level
    parentRecordId = 0;
    for(NSInteger i = (NSInteger)level - 1; i >= 0; i--) {
        if (lastLevelRecord[i] >= 0) {
            parentRecordId = lastLevelRecord[i];
            break;
        }
    }
    
    
    NSString * contentText = [self makeContentTextFromRecord:[dict valueForKey:@"plain"]];
    NSString * simpleContentText = [self makeSimpleContentText:contentText];
    NSMutableDictionary * contentItem =  [[NSMutableDictionary alloc] initWithCapacity:7];
    
    [contentItem setValue:[NSNumber numberWithInteger:thisRecordId] forKey:@"record"];
    [contentItem setValue:[NSNumber numberWithInteger:parentRecordId] forKey:@"parent"];
    [contentItem setValue:contentText forKey:@"text"];
    [contentItem setValue:[NSNumber numberWithInteger:level] forKey:@"level"];
    [contentItem setValue:simpleContentText forKey:@"simpletitle"];
    NSString * strSubtext = [dict valueForKey:@"subtext"];
    if (strSubtext == nil)
        strSubtext = @"";
    NSMutableString * ms = [[NSMutableString alloc] initWithString:strSubtext];
    [contentItem setValue:ms forKey:@"subtext"];
    if ([dict valueForKey:@"ctdef"] != nil)
    {
        NSMutableArray * children = [[NSMutableArray alloc] init];
        [contentItem setValue:children forKey:@"children"];
        [self.contentTaggedItems setValue:children forKey:[dict valueForKey:@"ctdef"]];
    }
    
    [self.contentArray addObject:contentItem];
    
    self.lastContentItemInserted = contentItem;
    [contentItem setValue:[self.stpdefs objectForKey:levelName] forKey:@"STPDEF"];
    

    
    return;
}


-(NSString *)makeSimpleContentText:(NSString *)orig
{
    NSData * data = [[[orig lowercaseString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSMutableString * str = [[NSMutableString alloc] init];
    const char * bytes = [data bytes];
    NSUInteger len = [data length];
    int lastType = 0;
    for (NSUInteger i = 0; i < len; i++)
    {
        unichar uc = bytes[i];
        if (isalpha(uc)) {
            if (lastType == 3) {
                [str replaceCharactersInRange:NSMakeRange([str length] - 1, 1) withString:@" "];
            }
            [str appendFormat:@"%C", uc];
            lastType = 1;
        } else if (isdigit(uc)) {
            [str appendFormat:@"%C", uc];
            lastType = 2;
        } else if (uc == '.') {
            if (lastType == 2) {
                [str appendString:@"."];
                lastType = 3;
            }
        } else if (uc == '-' || uc == 150) {
            if (lastType == 3) {
                [str replaceCharactersInRange:NSMakeRange([str length] - 1, 1) withString:@" "];
            } else if (lastType == 2) {
                [str appendString:@"-"];
                lastType = 4;
            } else if (lastType != 6) {
                [str appendString:@" "];
                lastType = 6;
            }
        } else if (uc == '\'') {
            [str appendString:@"'"];
            lastType = 5;
        } else if (uc == ' ') {
            if (lastType == 3) {
                [str replaceCharactersInRange:NSMakeRange([str length] - 1, 1) withString:@" "];
            } else if (![str hasSuffix:@" "] && [str length] > 0) {
                [str appendString:@" "];
            }
            lastType = 6;
        } else {
            if (lastType != 6) {
                [str appendString:@" "];
                lastType = 6;
            }
        }
    }
    
    while ([str hasSuffix:@" "]) {
        [str replaceCharactersInRange:NSMakeRange([str length] - 1, 1) withString:@""];
    }
    
    return str;
}

-(void)saveContents
{
    int ai = 0;
    int contentItemId = 0;
    for(NSMutableDictionary * contItem in self.contentArray)
    {
        contentItemId++;
        ai++;
        [contItem setValue:[NSNumber numberWithInt:contentItemId] forKey:@"itemid"];
        NSNumber * level = [contItem objectForKey:@"level"];
        NSNumber * parent = [contItem objectForKey:@"record"];
        if ([contItem valueForKey:@"children"] != nil)
        {
            NSSortDescriptor * sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"simpletitle" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
            NSArray * children = [(NSArray *)[contItem valueForKey:@"children"] sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDesc]];
            
            for(NSMutableDictionary * contChild in children)
            {
                contentItemId++;
                [contChild setValue:[NSNumber numberWithInt:contentItemId] forKey:@"itemid"];
                [contChild setValue:parent forKey:@"parent"];
                [contChild setValue:[NSNumber numberWithInt:([level intValue] + 1)] forKey:@"level"];
            }
        }
        
        // writes to dump file
        fprintf(self->outputFile, "%d\t%d\t%d\t%s\t%s\t%s\n",
                [(NSNumber *)[contItem objectForKey:@"level"] intValue],
                [(NSNumber *)[contItem objectForKey:@"record"] intValue],
                [(NSNumber *)[contItem objectForKey:@"parent"] intValue],
                [[contItem objectForKey:@"text"] UTF8String],
                [[contItem objectForKey:@"simpletitle"] UTF8String],
                [[contItem objectForKey:@"subtext"] UTF8String]);
    }
    
    NSLog(@"Done - Saving Content");
}


@end
