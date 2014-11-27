//
//  TextDiff.m
//  fftextdiff
//
//  Created by Peter Kollath on 19/11/14.
//  Copyright (c) 2014 Peter Kollath. All rights reserved.
//

#import "TextDiff.h"
#import "TextStream.h"

@implementation TextDiff


-(id)init
{
    self = [super init];
    if (self) {
        self->idxfind = 0;
        self.indexPos = 0;
        self.textPos = 1;
    }
    return self;
}

-(BOOL)validate
{
    //return YES;
    if (self.fileNewName.length > 0 && self.fileOldName.length > 0 && self.outputFileName.length > 0)
    {
        return YES;
    }
    
    return NO;
}

// comparision can be done for various purposes
//   - create record id remapping
//   - create list of updates for DB update

-(void)process
{
    self.printChanged = NO;
    self.printDeleted = NO;
    self.printEqual = NO;
    self.printInserted = NO;
    
    TrianglePosition * tp = [TrianglePosition new];

    TextRecord * tra;
    TextRecord * trb;
    BOOL bothEof = YES;
    TextDiffTracker * dt = [TextDiffTracker new];
    
    self.fileNew = [TextStream new];
    self.fileOld = [TextStream new];
    self.fileOutput = [TextStream new];
    
    self.fileNew.indexPos = self.indexPos;
    self.fileNew.textPos = self.textPos;
    self.fileOld.indexPos = self.indexPos;
    self.fileOld.textPos = self.textPos;
    
    [self.fileNew openReadTextFile:self.fileNewName];
    [self.fileOld openReadTextFile:self.fileOldName];
    
    FILE * op = fopen(self.outputFileName.UTF8String, "wt");
    
    int i = 0;
    BOOL prevEq = NO;
    NSInteger recStart = -1;
    NSInteger recStop = -1;
    NSInteger diffNewToOld = -1;
    
    while (bothEof)
    {
        [self findTriangleLine:i toPos:tp];
        tra = [self.fileOld recordAtIndex:tp.indexA];
        trb = [self.fileNew recordAtIndex:tp.indexB];
        
        if (tra != nil && trb != nil)
        {
            if (i == 0 && tra.recId % 10000 == 0)
            {
                printf("Record %d\n", tra.recId);
            }
            if (i > 10000 && i % 100000 == 0)
            {
                printf("   i = %d\n", i);
            }
            if ([tra.text isEqualToString:trb.text])
            {
                // lines are equal
                
                // here range from A is different from B
                //NSLog(@"<Different Ranges>");
                NSRange rangeA = [self.fileOld rangeOfRecords:tp.indexA];
                NSRange rangeB = [self.fileNew rangeOfRecords:tp.indexB];
                if (rangeA.location != NSNotFound)
                {
                    prevEq = NO;
                    if (self.printDeleted)
                    {
                        fprintf(op, "DELETED %ld %ld (position,count in old file)\n", rangeA.location, rangeA.length);
                    }
                    if (rangeB.location != NSNotFound)
                    {
                        if (self.printInserted)
                        {
                            fprintf(op, "INSERTED %ld %ld (position,count in new file)\n", rangeB.location, rangeB.length);
                        }
                        if (rangeA.length == rangeB.length)
                        {
                            prevEq = YES;
                            if (self.printChanged)
                            {
                                fprintf(op, "CHANGED %ld (records)\n", rangeA.length);
                            }
                        }
                    }
                }
                if (rangeB.location != NSNotFound)
                {
                    if (self.printInserted)
                    {
                        fprintf(op, "INSERTED %ld %ld (position,count in new file)\n", rangeB.location, rangeB.length);
                    }
                    prevEq = NO;
                }

                if (prevEq == YES)
                {
                    recStop = trb.recId;
                }
                else
                {
                    if (recStart >= 0)
                    {
                        //printf("MAPRANGE %ld - %ld DIFF %ld (new to old recid)\n", recStart, recStop, diffNewToOld);
                    }
                    recStart = trb.recId;
                    recStop = trb.recId;
                    diffNewToOld = trb.recId - tra.recId;
                }
                
                [dt insertRec:tra.recId diff:(trb.recId - tra.recId)];
                if (dt.list.count > 0)
                {
                    for(NSString * str in dt.list)
                    {
                        fprintf(op, "%s\n", str.UTF8String);
                    }
                    [dt.list removeAllObjects];
                }
                //printf("MAP %d %d\n", trb.recId, trb.recId - tra.recId);
                if (self.printEqual)
                {
                    fprintf(op, "EQUALS %d %d (old,new recid)\n", tra.recId, trb.recId);
                }
                prevEq = YES;
                
                [self.fileOld shift:(tp.indexA + 1)];
                [self.fileNew shift:(tp.indexB + 1)];
                
                i = -1;
            }
            else
            {
            }
        }
        else if (trb == nil && tra == nil)
        {
            // here all remaining lines from both files are different
            NSRange rangeA = [self.fileOld rangeOfRecords];
            NSRange rangeB = [self.fileNew rangeOfRecords];
            if (rangeA.length == rangeB.length && rangeA.location != NSNotFound && rangeB.location != NSNotFound && self.printChanged)
                fprintf(op, "CHANGED %ld (records)\n", rangeA.length);
            if (rangeA.location != NSNotFound && self.printDeleted)
                fprintf(op, "DELETED %ld %ld (position,count in old file)\n", rangeA.location, rangeA.length);
            if (rangeB.location != NSNotFound && self.printInserted)
                fprintf(op, "INSERTED %ld %ld (position,count in new file)\n", rangeB.location, rangeB.length);
            break;
        }
        
        i++;
    }

    [dt flush];

    [self.fileNew closeFile];
    [self.fileOld closeFile];
    

    for(NSString * str in dt.list)
    {
        fprintf(op, "%s\n", str.UTF8String);
    }
    
    fclose(op);
}


-(int)findTriangleLine:(int)index toPos:(TrianglePosition *)tp
{
    int i;
    int index2 = index + 1;
    int count = 1;
    int lastLine = 1;
    for(i = 1; i < index2; i++)
    {
        if (count + i > index2)
            break;
        count += i;
        lastLine = i;
    }

    int sum = i - 1;
    int offset = index2 - count;
    
    tp.indexA = offset;
    tp.indexB = sum - offset;
    
    //NSLog(@"tp(%ld,%ld)", tp.indexA, tp.indexB);
    return 0;
}


@end
