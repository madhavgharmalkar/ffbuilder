//
//  TextStream.m
//  fftextdiff
//
//  Created by Peter Kollath on 19/11/14.
//  Copyright (c) 2014 Peter Kollath. All rights reserved.
//

#import "TextStream.h"

@implementation TextStream

-(id)init
{
    self = [super init];
    if (self)
    {
        self.eof = NO;
        self.recBuffer = [NSMutableArray new];
    }
    return self;
}

-(void)openReadTextFile:(NSString *)fileName
{
    bufferSize = 200000;
    buffer = malloc(bufferSize);
    self->file = fopen([fileName UTF8String], "rt");
}

-(void)openWriteTextFile:(NSString *)fileName
{
    bufferSize = 200000;
    buffer = malloc(bufferSize);
    self->file = fopen([fileName UTF8String], "wt");
}

-(void)closeFile
{
    fclose(self->file);
    free(buffer);
}

-(NSString *)readLine
{
    if (self.eof)
        return nil;
    
    char * c;
    int len;
    NSString * line;
    if((c = fgets(self->buffer, self->bufferSize, self->file)) != NULL)
    {
        len = (int)strlen(c);
        if (len > 0 && c[len-1] == '\n')
        {
            c[len-1] = '\0';
            line = [NSString stringWithUTF8String:c];
        }
        
        return line;
    }

    self.eof = YES;
    return nil;
}

-(TextRecord *)readRecord
{
    NSString * line = [self readLine];
    NSArray * part = nil;
    
    if (line != nil)
        part = [line componentsSeparatedByString:@"\t"];
    
    if (part != nil && part.count > 3)
    {
        TextRecord * tr = [TextRecord new];
        tr.recId = [part[self.indexPos] intValue];
        tr.text = part[self.textPos];
        return tr;
    }

    return nil;
}

-(void)readRecsUpTo:(NSInteger)idx
{
    while(self.recBuffer.count <= idx)
    {
        TextRecord * tr = [self readRecord];
        if (tr == nil)
            break;
        [self.recBuffer addObject:tr];
    }
}

-(TextRecord *)recordAtIndex:(NSInteger)index
{
    [self readRecsUpTo:index];
    
    if (index >= self.recBuffer.count)
        return nil;
    
    return [self.recBuffer objectAtIndex:index];
}

-(NSInteger)recordCount
{
    return [self.recBuffer count];
}

-(void)shift
{
    [self shift:1];
}

-(void)shift:(NSInteger)recs
{
    [self readRecsUpTo:recs];
    [self.recBuffer removeObjectsInRange:NSMakeRange(0, recs)];
}

-(NSRange)rangeOfRecords
{
    if (self.recBuffer.count == 0)
        return NSMakeRange(NSNotFound, 0);
    TextRecord * tra = [self.recBuffer objectAtIndex:0];
    TextRecord * trb = [self.recBuffer objectAtIndex:(int)(self.recBuffer.count) - 1];
    
    return NSMakeRange(tra.recId, trb.recId - tra.recId + 1);
}

-(NSRange)rangeOfRecords:(NSInteger)toIndex
{
    if (self.recBuffer.count == 0
        || (toIndex) >= self.recBuffer.count
        || toIndex <= 0)
        return NSMakeRange(NSNotFound, 0);
    TextRecord * tra = [self.recBuffer objectAtIndex:0];
    TextRecord * trb = [self.recBuffer objectAtIndex:toIndex];
    
    return NSMakeRange(tra.recId, trb.recId - tra.recId);
}


@end
