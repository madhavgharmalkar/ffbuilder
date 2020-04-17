//
//  DictionaryBuilder.m
//  ffdictionary
//
//  Created by Peter Kollath on 13/11/14.
//  Copyright (c) 2014 Peter Kollath. All rights reserved.
//

#import "DictionaryBuilder.h"
#import "VBDictionaryInstance.h"
#import "VBDictionaryMeaning.h"
#import "VBDictionaryWord.h"
#import "FlatFileUtils.h"

@implementation DictionaryBuilder

-(id)init
{
    self = [super init];
    if (self)
    {
        self.inputFiles = [NSMutableArray new];
    }
    return self;
}


-(BOOL)validate
{
    return (self.inputFiles.count > 0 && self.outputDir.length > 0);
}

- (void)writeMeanings:(NSMutableDictionary *)meanings
{
    NSString *ekey;
    NSEnumerator * emen = [meanings keyEnumerator];

    while((ekey = [emen nextObject]) != nil)
    {
        NSArray * keys = [ekey componentsSeparatedByString:@"_"];
        NSSet * means = [meanings objectForKey:ekey];
        [means enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
            VBDictionaryMeaning * dm = [[VBDictionaryMeaning alloc] initWithStorage:self->fileMean];
            dm.wordID = [(NSString *)keys[1] intValue];
            dm.dictionaryID = [(NSString *)keys[0] intValue];
            dm.meaning = (NSString *)obj;
            [dm write];
        }];
    }
}

-(void)process
{
    self->fileMean = fopen([self.outputDir stringByAppendingPathComponent:@"dict_means.txt"].UTF8String, "wt");
    self->fileInst = fopen([self.outputDir stringByAppendingPathComponent:@"dictionary.txt"].UTF8String, "wt");
    self->fileWord = fopen([self.outputDir stringByAppendingPathComponent:@"dict_words.txt"].UTF8String, "wt");

    if ([self.inputFiles count] > 0)
    {
        NSMutableDictionary * dictionaries = [[NSMutableDictionary alloc] init];
        NSMutableDictionary * currentDictionary = nil;
        int lastDictionaryId = 1;
        NSMutableDictionary * words = [[NSMutableDictionary alloc] init];
        int lastWordId = 1;
        NSMutableDictionary * meanings = [[NSMutableDictionary alloc] init];
        NSCharacterSet * wscs = [NSCharacterSet newlineCharacterSet];
        for(NSString * str in self.inputFiles)
        {
            NSString * fileContent = [NSString stringWithContentsOfFile:str
                                                               encoding:NSUTF8StringEncoding
                                                                  error:NULL];
            NSArray * lines = [fileContent componentsSeparatedByCharactersInSet:wscs];
            for(NSString * line in lines)
            {
                if ([line hasPrefix:@"<D>"])
                {
                    // name of dictionary is here [line substringFromIndex:3]
                    NSString * name = [line substringFromIndex:3];
                    currentDictionary = [dictionaries objectForKey:name];
                    if (currentDictionary == nil)
                    {
                        VBDictionaryInstance * di = [[VBDictionaryInstance alloc] initWithStorage:self->fileInst];
                        di.ID = lastDictionaryId;
                        di.name = name;
                        [di write];
                        
                        currentDictionary = [[NSMutableDictionary alloc] init];
                        [currentDictionary setObject:[NSNumber numberWithInt:lastDictionaryId]
                                              forKey:@"DICTID"];
                        [currentDictionary setObject:name forKey:@"NAME"];
                        [dictionaries setObject:currentDictionary
                                         forKey:name];
                        lastDictionaryId++;
                        
                    }
                }
                else if ([line hasPrefix:@"<H>"] && [line hasSuffix:@"<E>"])
                {
                    // split by <L>
                    NSArray * parts = [[line substringWithRange:NSMakeRange(3, line.length - 6)] componentsSeparatedByString:@"<L>"];
                    if (parts.count == 2)
                    {
                        NSString * word = parts[0];
                        NSString * meaning = parts[1];
                        NSMutableDictionary * wordDict = [words objectForKey:word];
                        if (wordDict == nil)
                        {
                            VBDictionaryWord * dw = [[VBDictionaryWord alloc] initWithStorage:self->fileWord];
                            dw.ID = lastWordId;
                            dw.word = word;
                            dw.simple = [FlatFileUtils makeDictionaryString:word];
                            [dw write];
                            
                            wordDict = [[NSMutableDictionary alloc] init];
                            [wordDict setObject:dw.word forKey:@"WORD"];
                            [wordDict setObject:dw.simple forKey:@"SIMPLE"];
                            [wordDict setObject:[NSNumber numberWithInt:lastWordId]
                                         forKey:@"WORDID"];
                            [words setObject:wordDict forKey:word];
                            lastWordId++;
                            
                            if (lastWordId % 12800 == 0)
                            {
                                NSLog(@"Word %d - Importing Dictionaries", lastWordId);
                            }
                            
                        }
                        
                        NSString * meaningKey = [NSString stringWithFormat:@"%@_%@", [currentDictionary valueForKey:@"DICTID"], [wordDict valueForKey:@"WORDID"]];
                        NSMutableSet * meaningDict = [meanings objectForKey:meaningKey];
                        if (meaningDict == nil)
                        {
                            meaningDict = [[NSMutableSet alloc] init];
                            [meanings setObject:meaningDict forKey:meaningKey];
                        }
                        
                        [meaningDict addObject:meaning];
                    }
                    else
                    {
                        NSLog(@"==== line ====\n%@", line);
                    }
                }
            }
        }
        
        NSLog(@"Write meanings - Importing Dictionaries");

        [self writeMeanings:meanings];
        
        
    }

}

@end
