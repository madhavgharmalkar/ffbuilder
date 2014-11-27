//
//  Indexer.m
//  ffindexer
//
//  Created by Peter Kollath on 13/11/14.
//  Copyright (c) 2014 Peter Kollath. All rights reserved.
//

#import "Indexer.h"
#import "FlatFileUtils.h"
#import "RKSortedList.h"

@implementation Indexer

-(id)init
{
    self = [super init];
    if (self) {
        self.wordList = [RKSortedList new];
        self.wordList.keyName = @"text";
        
        self.wordsMap = [RKKeySet new];
        self.idxMap = [RKKeySet new];
      

    }
    return self;
}

-(void)doIndexLine:(NSString *)text recordId:(int)recId
{
    FlatFileStringIndexer * indexer = [[FlatFileStringIndexer alloc] init];
    [indexer setText:text];
    [indexer setDelegate:self];
    [indexer setObject:[NSNumber numberWithInt:recId] forKey:@"record"];
    [indexer setObject:[[NSMutableSet alloc] init] forKey:@"fields"];
    [indexer setObject:[[NSMutableSet alloc] init] forKey:@"all"];
    [indexer setObject:[[GPMutableInteger alloc] init] forKey:@"position"];
    [indexer setObject:[[GPMutableInteger alloc] init] forKey:@"level"];
    [indexer setObject:[[GPMutableInteger alloc] init] forKey:@"note"];
    [indexer parse];
}

-(void)doIndexing
{
    self.dotsCharset = [NSCharacterSet characterSetWithCharactersInString:@".,?"];
    int count = 0;
    int len = 0;
    FILE * i = fopen([self.inputFile UTF8String], "rt");
    //self->fileOutputRaw = fopen([[self.outputDir stringByAppendingPathComponent:@"words_raw.data"] UTF8String], "wb");
    //self->fileWordsMap = fopen([[self.outputDir stringByAppendingPathComponent:@"words_map.txt"] UTF8String], "wt");
    //self->fileIdxMap = fopen([[self.outputDir stringByAppendingPathComponent:@"words_idx.txt"] UTF8String], "wt");
    
    
    if (self.keywordFileName.length > 0)
    {
        NSLog(@"START KEYWORDS INDEXING");
        NSString * str = [NSString stringWithContentsOfFile:self.keywordFileName encoding:NSUTF8StringEncoding error:NULL];
        NSArray * arr = [str componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        int lineCount = 0;
        for (NSString * line in arr)
        {
            NSArray * p = [line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            if (p.count >= 2)
            {
                int recId = [(NSString *)p[0] intValue];
                for (NSInteger j = 1; j < p.count; j++)
                {
                    [self addWordOccurence:p[j] inRecord:recId withPosition:j forIndex:@"keywords"];
                }
                lineCount++;
            }
        }
        NSLog(@"END OF KEYWORDS INDEXING - %d lines processed", lineCount);
    }
    
    NSLog(@"START INDEXING");
    
    char *c = malloc(200000);
    while((c = fgets(c, 200000, i)) != NULL)
    {
        len = (int)strlen(c);
        if (len > 0 && c[len-1] == '\n')
            c[len-1] = '\0';
        NSString * line = [NSString stringWithUTF8String:c];
        NSArray * part = [line componentsSeparatedByString:@"\t"];

        [self doIndexLine:part[1] recordId:[(NSString *)part[0] intValue]];
        count ++;
        if (count % 1000 == 0) {
            printf("*");
        }
        if (count % 40000 == 0) {
            printf("...Processes %d lines\n", count);
        }
    }

    self->fileB = fopen([[self.outputDir stringByAppendingPathComponent:@"words_b.txt"] UTF8String], "wt");
    self->fileA = fopen([[self.outputDir stringByAppendingPathComponent:@"words_a.txt"] UTF8String], "wt");

    [self saveWordsIndex];

    fclose(i);
    fclose(self->fileA);
    fclose(self->fileB);

    NSLog(@"STOP INDEXING");
}

-(NSInteger)nextId
{
    self.counter++;
    return self.counter;
}

-(void)saveWordsIndex
{
    
        self.counter = 0;
        NSString * objDir = [self.outputDir stringByAppendingPathComponent:@"obj"];
        NSFileManager * fm = [NSFileManager defaultManager];
        BOOL isDir = NO;
        
        if ([fm fileExistsAtPath:objDir isDirectory:&isDir])
        {
            if (!isDir)
            {
                NSLog(@"Could not save object files, because name %@ is already the name of existing file", objDir);
                return;
            }
        }
        else
        {
            [fm createDirectoryAtPath:objDir withIntermediateDirectories:YES attributes:nil error:NULL];
        }

        for(unsigned i = 0; i < [self.wordList count]; i++)
        {
            NSDictionary * dict = [self.wordList objectAtIndex:i];
            NSDictionary * blobs = [dict objectForKey:@"blobs"];
            [blobs enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL * stop) {
                NSString * word = [dict objectForKey:[self.wordList keyName]];
                NSData * data = (NSData *)value;
            

                if ([data length] > 50000)
                {
                    NSURL * fileURL = [NSURL fileURLWithPath:[objDir stringByAppendingPathComponent:[NSString stringWithFormat:@"w_%ld", self.counter]]];
                    self.counter++;
                    [data writeToURL:fileURL atomically:YES];
                    fprintf(self->fileB, "%s\t%d\t%s\t%ld\t",
                            [(NSString *)key UTF8String],
                            [[dict objectForKey:@"uid"] unsignedIntValue],
                            [word UTF8String],
                            0L);
                    fprintf(self->fileB, "%s\n", [[fileURL absoluteString] UTF8String]);
                }
                else
                {
                    fprintf(self->fileA, "%s\t%d\t%s\t%ld\t",
                            [(NSString *)key UTF8String],
                            [[dict objectForKey:@"uid"] unsignedIntValue],
                            [word UTF8String],
                            0L);
                    const unsigned char * bytes = [data bytes];
                    NSInteger k, m;
                    m = [data length];
                    for (k =0; k < m; k++)
                    {
                        fprintf(self->fileA, "%02x", bytes[k]);
                    }
                    fprintf(self->fileA, "\n");
                }

            }];
            //NSLog(@"word %@ length = %ld", [dict objectForKey:@"text"], [[dict objectForKey:@"blob"] length]/6);
            
        }
    
    /*
    NSEnumerator * ek = [self.wordsMap keyEnumerator];
    NSString * key;
    while((key = [ek nextObject]) != nil)
    {
        fprintf(self->fileWordsMap, "%ld\t%s\n", [self.wordsMap idForKey:key], key.UTF8String);
    }
    
    ek = [self.idxMap keyEnumerator];
    while((key = [ek nextObject]) != nil)
    {
        fprintf(self->fileIdxMap, "%ld\t%s\n", [self.idxMap idForKey:key], key.UTF8String);
    }
    */
}

-(BOOL)validate
{
    return !(self.outputDir.length == 0 ||
             self.inputFile.length == 0);
}


#pragma mark -
#pragma mark Indexer Delegate


-(void)pushTag:(FlatFileTagString *)tag fromIndexer:(FlatFileStringIndexer *)indexer
{
    NSMutableSet * fields = [indexer objectForKey:@"fields"];
    NSMutableSet * all = [indexer objectForKey:@"all"];
    GPMutableInteger * level = [indexer objectForKey:@"level"];
    GPMutableInteger * note = [indexer objectForKey:@"note"];
    
    NSString * tagStr = [tag tag];
    if ([tagStr compare:@"NT"] == NSOrderedSame) {
        [note increment];
        [all addObject:@"Note"];
    } else if ([tagStr compare:@"/NT"] == NSOrderedSame) {
        [note decrement];
    } else if ([tagStr compare:@"PW"] == NSOrderedSame) {
        [level increment];
        [all addObject:@"Popup"];
    } else if ([tagStr compare:@"LT"] == NSOrderedSame) {
        [level decrement];
    } else if ([tagStr compare:@"FD"] == NSOrderedSame) {
        NSArray * arr = [tag createArray];
        if ([arr count] >= 3) {
            [fields addObject:[arr objectAtIndex:2]];
            [all addObject:[arr objectAtIndex:2]];
            [all addObject:@"<all>"];
        }
    } else if ([tagStr compare:@"/FD"] == NSOrderedSame) {
        NSArray * arr = [tag createArray];
        if ([arr count] >= 3) {
            [fields removeObject:[arr objectAtIndex:2]];
        }
    }
}

-(void)pushWord:(NSString *)aWord fromIndexer:(FlatFileStringIndexer *)indexer
{
    NSString * word = [aWord stringByTrimmingCharactersInSet:self.dotsCharset];
    GPMutableInteger * position = [indexer objectForKey:@"position"];
    NSMutableSet * fields = [indexer objectForKey:@"fields"];
    GPMutableInteger * level = [indexer objectForKey:@"level"];
    NSNumber * record = [indexer objectForKey:@"record"];
    GPMutableInteger * note = [indexer objectForKey:@"note"];

    if ([fields containsObject:@"Devanagari"])
        return;
    
    if ([level intValue] > 0) {
        [self addWordOccurence:word
                      inRecord:[record intValue]
                  withPosition:[position intValue]
                      forIndex:@"Popup"];
    } else if ([note intValue] > 0) {
        [self addWordOccurence:word
                      inRecord:[record intValue]
                  withPosition:[position intValue]
                      forIndex:@"Note"];
    } else {
        [self addWordOccurence:word
                      inRecord:[record intValue]
                  withPosition:[position intValue]
                      forIndex:@""];
    }
    
    [fields enumerateObjectsUsingBlock:^(id obj, BOOL *stop){
        [self addWordOccurence:word
                      inRecord:[record intValue]
                  withPosition:[position intValue]
                      forIndex:obj];
    }];
    
    // increase word position
    [position increment];
}

-(void)pushEndfromIndexer:(FlatFileStringIndexer *)indexer
{
    NSMutableSet * all = [indexer objectForKey:@"all"];
    NSNumber * record = [indexer objectForKey:@"record"];
    [all enumerateObjectsUsingBlock:^(id obj, BOOL *stop){
        [self addWordOccurence:@"<all>"
                      inRecord:[record intValue]
                  withPosition:0
                      forIndex:obj];
    }];
}

-(void)addWordOccurence:(NSString *)aWord inRecord:(uint32_t)aRecord withPosition:(uint16_t)aPosition forIndex:(NSString *)idxTag
{
    NSDictionary * wordObject = [self.wordList objectForKey:aWord];
    if (wordObject == nil)
    {
        NSMutableDictionary * blobs = [[NSMutableDictionary alloc] init];
        
        wordObject = [NSDictionary dictionaryWithObjectsAndKeys:aWord, [self.wordList keyName],
                      [NSNumber numberWithUnsignedInt:([self.wordList count] + 1)], @"uid",
                      blobs, @"blobs", nil];
        [self.wordList addObject:wordObject];
    }
    
    //NSDictionary * wid = [self getWordID:aWord];
    NSMutableDictionary * blobs = [wordObject objectForKey:@"blobs"];
    if ([blobs objectForKey:idxTag] == nil) {
        NSMutableData * md = [[NSMutableData alloc] initWithCapacity:1000];
        [blobs setObject:md forKey:idxTag];
    }
    NSMutableData * recs = [blobs objectForKey:idxTag];
    // zapisuje rec_id aj proximity
    uint32_t adx1 = CFSwapInt32HostToLittle(aRecord);
    uint16_t adx2 = CFSwapInt16HostToLittle(aPosition);
    
    [recs appendBytes:&adx1 length:4];
    [recs appendBytes:&adx2 length:2];
    
    //NSInteger wordId = [self.wordsMap idForKey:aWord];
    //NSInteger idxId = [self.idxMap idForKey:idxTag];
    
    //fprintf(self->fileOutputRaw, "%ld\t%ld\t%d\t%d\n", wordId, idxId, aRecord, aPosition);
}


@end
