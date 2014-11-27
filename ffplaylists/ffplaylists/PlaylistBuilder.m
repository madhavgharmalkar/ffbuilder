//
//  PlaylistBuilder.m
//  ffplaylists
//
//  Created by Peter Kollath on 13/11/14.
//  Copyright (c) 2014 Peter Kollath. All rights reserved.
//

#import "PlaylistBuilder.h"
#import "FlatFileUtils.h"

@implementation PlaylistBuilder

-(id)init
{
    self = [super init];
    if (self)
    {
        for(NSInteger i = 0; i < kMaxLevel; i++)
        {
            levelRecIds[i] = -1;
            levelRecs[i] = nil;
            self.gid = 1;
            self.printedRecs = [NSMutableDictionary new];

        }
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
    
    self->outputFile = fopen([[self.outputDir stringByAppendingPathComponent:@"playlists.txt"] UTF8String], "wt");
    self->outputFile2 = fopen([[self.outputDir stringByAppendingPathComponent:@"playlists_detail.txt"] UTF8String], "wt");
    
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
    
    fclose(i);
    fclose(self->outputFile);
    fclose(self->outputFile2);
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

-(void)processText:(NSString *)text
          recordId:(int)recId
         styleName:(NSString *)style
         levelName:(NSString *)levelName
{
    NSUInteger level = [self getLevelIndex:levelName];
    
    if (level != NSNotFound && level <= self.maxLevel)
    {
        for(NSInteger i = level; i < kMaxLevel; i++)
        {
            levelRecIds[i] = -1;
            levelRecs[i] = nil;
        }
    }
    
    if ([style isEqualToString:@"PA_Audio_Bg"])
    {
        NSRange r1, r2;
        
        r1 = [text rangeOfString:@"<AUDIO:\""];
        if (r1.location == NSNotFound)
        {
            r1 = [text rangeOfString:@"<DL:Data,\""];
        }
        
        if (r1.location != NSNotFound)
        {
            r2 = [text rangeOfString:@"\"" options:0 range:NSMakeRange(r1.location + r1.length, text.length - r1.location - r1.length)];
        }
        
        NSString * object = nil;
        
        if (r1.location != NSNotFound && r2.location != NSNotFound)
        {
            object = [text substringWithRange:NSMakeRange(r1.location + r1.length, r2.location - r1.location - r1.length)];
        }
        
        if (object)
        {
            NSInteger prevLevId = -1;
            for(NSInteger i = 0; i < kMaxLevel; i++)
            {
                if (levelRecIds[i] == -1)
                    continue;
                NSString * key = [NSString stringWithFormat:@"%ld", levelRecIds[i]];
                if (![self.printedRecs valueForKey:key])
                {
                    NSString * title = [FlatFileUtils removeTags:levelRecs[i]];
                    // PLAYLT  levelRecs[i]   prevLevId     title
                    fprintf(self->outputFile, "%ld\t%ld\t%s\n", levelRecIds[i], prevLevId, [title UTF8String]);
                    [self.printedRecs setValue:@"1" forKey:key];
                }
                
                prevLevId = levelRecIds[i];
            }
            
            fprintf(self->outputFile2, "%ld\t%ld\t%s\n", prevLevId, self.gid, [object UTF8String]);
            //OBJECT   self.gid   prevLevId    object
            self.gid++;
        }
    }
    else
    {
        if (level != NSNotFound && level <= self.maxLevel)
        {
            self->levelRecs[level] = text;
            self->levelRecIds[level] = self.gid;
            self.gid++;
        }
    }
}


@end
