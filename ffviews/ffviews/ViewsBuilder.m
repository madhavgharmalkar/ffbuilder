//
//  ViewsBuilder.m
//  ffviews
//
//  Created by Peter Kollath on 13/11/14.
//  Copyright (c) 2014 Peter Kollath. All rights reserved.
//

#import "ViewsBuilder.h"
#import "FlatFileUtils.h"

@implementation ViewsBuilder


-(id)init
{
    self = [super init];
    if (self)
    {
        self.views = [ViewDir new];
        self.gid = 1;
        self.maxLevel = 6;
        for (NSInteger i = 0; i < kMaxLevel; i++)
        {
            self->levelRecs[i] = nil;
            self->levelRecIds[i] = -1;
            self->levelBuildViews[i] = NO;
        }
    }
    return self;
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

-(BOOL)validate
{
    return (self.inputFile.length > 0 && self.outputDir.length > 0 && self.levelFile.length > 0);
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

-(void)process
{
    [self loadLevels];
    
    int count = 0;
    int len = 0;
    FILE * i = fopen([self.inputFile UTF8String], "rt");
    
    self->outputFile = fopen([[self.outputDir stringByAppendingPathComponent:@"views.txt"] UTF8String], "wt");
    self->outputFile2 = fopen([[self.outputDir stringByAppendingPathComponent:@"view_details.txt"] UTF8String], "wt");
    
    char *c = malloc(200000);
    while((c = fgets(c, 200000, i)) != NULL)
    {
        len = (int)strlen(c);
        if (len > 0 && c[len-1] == '\n')
            c[len-1] = '\0';
        NSString * line = [NSString stringWithUTF8String:c];
        NSArray * part = [line componentsSeparatedByString:@"\t"];
        
        [self processText:part[1] recordId:[(NSString *)part[0] intValue] styleName:part[3] levelName:part[2]];
        count ++;
        
        if (count % 100000 == 0) {
            NSString * str = [NSString stringWithFormat:@"processed %d lines", count];
            printf("%s", str.UTF8String);
            for(int i = 0; i < str.length; i++)
            {
                printf("\b");
            }
            fflush(stdout);
        }
    }
    
    [self writeViews:self.views];
    
    fclose(i);
    fclose(self->outputFile);
    fclose(self->outputFile2);
}

-(void)writeViews:(ViewDir *)V
{
    if (V.subs == nil)
        return;
    
    for (ViewDir * A in V.subs)
    {
        fprintf(self->outputFile, "%ld\t%ld\t%s\n", V.pid, A.pid, A.name.UTF8String);
        [self writeViews:A];
    }
}

-(BOOL)eligibleForBuild:(NSString *)text recordId:(int)recId
{
    if (recId == 1415 || recId == 13052 || recId == 203095)
        return true;
    
    NSRange range = [text rangeOfString:@"<BUILDVIEW>"];
    return (range.location != NSNotFound);
}

-(void)processText:(NSString *)text
          recordId:(int)recId
         styleName:(NSString *)style
         levelName:(NSString *)levelName
{
    NSInteger level = [self getLevelIndex:levelName];
    BOOL buildTags = NO;
    
    if (level != NSNotFound)
    {
        for (NSInteger i = level; i < kMaxLevel; i++)
        {
            self->levelRecs[i] = nil;
            self->levelRecIds[i] = -1;
            self->levelBuildViews[i] = NO;
        }
        self->levelBuildViews[level] = [self eligibleForBuild:text recordId:recId];
        self->levelRecs[level] = [FlatFileUtils removeTags:text];
        self->levelRecIds[level] = self.gid;
        self.gid++;
        
        self.globLastLevel = level;

    }

    if (self.globLastLevel != NSNotFound)
    {
        for (NSInteger j = 0; j <= self.globLastLevel; j++)
        {
            if (self->levelBuildViews[j]) {
                buildTags = YES;
                break;
            }
        }
    }
    
    
    if (buildTags)
    {
        if ([style isEqualToString:@"PA_Textnum"])
        {
            [self insertRecord:recId toGroup:@"Translations" maxLevel:self.maxLevel];
            [self insertRecord:recId toGroup:@"Verses" maxLevel:self.maxLevel];
            [self insertRecord:recId toGroup:@"Verses & Translations" maxLevel:self.maxLevel];
        }
        else if ([style isEqualToString:@"PA_Translation"])
        {
            [self insertRecord:recId toGroup:@"Translations" maxLevel:self.maxLevel];
            [self insertRecord:recId toGroup:@"Verses & Translations" maxLevel:self.maxLevel];
        }
        else if ([levelName isEqualToString:@"PA_Verse_Text"] && ![style isEqualToString:@"PA_Audio_Bg"])
        {
            [self insertRecord:recId toGroup:@"Verses" maxLevel:self.maxLevel];
            [self insertRecord:recId toGroup:@"Verses & Translations" maxLevel:self.maxLevel];
        }
    }
}

-(void)insertRecord:(int)recId toGroup:(NSString *)group maxLevel:(NSInteger)maxLev
{
    ViewDir * vw = [self.views getChild:group];
    
    for (NSInteger i = 0; i <= maxLev; i++)
    {
        if (self->levelRecs[i] != nil)
        {
            vw = [vw getChild:self->levelRecs[i]];
        }
    }
    
    fprintf(self->outputFile2, "%ld\t%d\n", vw.pid, recId);
}

@end
