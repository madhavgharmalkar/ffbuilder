//
//  Loader.m
//  sqliteloader
//
//  Created by Peter Kollath on 12/11/14.
//  Copyright (c) 2014 Peter Kollath. All rights reserved.
//

#import "Loader.h"

@implementation Loader

-(id)init
{
    self = [super init];
    if (self) {
        self.noClean = NO;
    }
    return self;
}

-(void)analyzeColumns
{
    self.columnNames = [NSMutableArray new];
    self.columnTypes = [NSMutableArray new];
    self.columnSubst = [NSMutableArray new];
    int i = 1;
    NSArray * parts = [self.columns componentsSeparatedByString:@","];
    for(NSString * part in parts)
    {
        NSArray * subparts = [part componentsSeparatedByString:@":"];
        if (subparts.count == 2)
        {
            [self.columnNames addObject:subparts[0]];
            [self.columnTypes addObject:subparts[1]];
            [self.columnSubst addObject:[NSString stringWithFormat:@"?%d", i]];
            i++;
        }
    }
}

-(void)prepareCommand
{
    NSMutableString * str = [[NSMutableString alloc] init];
    
    [str appendFormat:@"insert into %@ (%@) values (%@)", self.tableName, [self.columnNames componentsJoinedByString:@","], [self.columnSubst componentsJoinedByString:@","]];
    
    self.command = [self.database createCommand:str];
    
}

-(void)load
{
    [self analyzeColumns];

    
    self.database = [[SQLiteDatabase alloc] init];
    [self.database open:self.targetFile];

    [self prepareCommand];
    
    if (self.noClean == NO)
    {
        [self.database execute:[NSString stringWithFormat:@"delete from %@", self.tableName]];
    }
    
    FILE * i = fopen([self.inputFile UTF8String], "r");

    int count = 0;
    int len = 0;
    char *c = malloc(200000);
    [self.database startTransaction];
    while((c = fgets(c, 200000, i)) != NULL)
    {
        len = (int)strlen(c);
        if (len > 0 && c[len-1] == '\n')
            c[len-1] = '\0';
        NSString * line = [NSString stringWithUTF8String:c];
        
        //NSLog(@"line: %@", line);
        [self processline:line];
        count ++;
        if (count % 1024 == 0)
        {
            [self.database endTransaction];
            [self.database startTransaction];
            printf("*");
        }
        if (count % 20480 == 0)
        {
            printf("...processed %d lines\n", count);
        }
    }
    
    [self.database endTransaction];

    NSLog(@"Lines processed: %d", count);

    free(c);
    fclose(i);
    [self.database close];
}


-(void)processline:(NSString *)line
{
    NSArray * arr = [line componentsSeparatedByString:@"\t"];
    if (arr.count != self.columnTypes.count)
    {
        NSLog(@"ERROR: columns count does not match for line:\n  %@", line);
    }
    else
    {
        [self.command reset];
        int i = 1;
        for(NSString * str in self.columnTypes)
        {
            if ([str isEqualToString:@"integer"])
            {
                [self.command bindInteger:[(NSString *)arr[i-1] intValue] toVariable:i];
            }
            else if ([str isEqualToString:@"text"])
            {
                [self.command bindString:arr[i-1] toVariable:i];
            }
            else if ([str isEqualToString:@"blob"])
            {
                [self.command bindData:[self dataFromHexText:arr[i-1]] toVariable:i];
            }
            else if ([str isEqualToString:@"blobfile"])
            {
                NSURL * url = [NSURL URLWithString:arr[i-1]];
                NSData * data = [NSData dataWithContentsOfURL:url];
                [self.command bindData:data toVariable:i];
            }
            i++;
        }
        if ([self.command execute] != SQLITE_DONE)
        {
            NSLog(@"Error when inserting.");
        }
    }
}

-(int)hexaValue:(unichar)uc
{
    if (uc >= 'a' && uc <= 'f')
        return uc - 'a' + 10;
    if (uc >= 'A' && uc <= 'F')
        return uc - 'A' + 10;
    if (uc >= '0' && uc <= '9')
        return uc - '0';
    return 0;
}

-(NSData *)dataFromHexText:(NSString *)str
{
    NSUInteger length = str.length;
    unsigned char * output = calloc(length + 1, sizeof(char));
    unichar * buffer = calloc(length + 1, sizeof(unichar));
    [str getCharacters:buffer];
    for(NSUInteger i = 0; i < length; i+=2)
    {
        int a = [self hexaValue:buffer[i]];
        int b = [self hexaValue:buffer[i+1]];
        
        output[i/2] = (unsigned char)((a << 4) + b);
    }
    
    NSData * data = [NSData dataWithBytes:output length:length/2];
    free(output);
    free(buffer);

    return data;
}

@end
