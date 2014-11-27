//
//  TextDiffTracker.m
//  fftextdiff
//
//  Created by Peter Kollath on 19/11/14.
//  Copyright (c) 2014 Peter Kollath. All rights reserved.
//

#import "TextDiffTracker.h"

@implementation TextDiffTracker

-(id)init
{
    self = [super init];
    if (self)
    {
        self.firstRec = -1;
        self.lastDiff = -10000000;
        self.list = [NSMutableArray new];
    }
    return self;
}

-(void)insertRec:(int)rec diff:(int)diff
{
    if (diff != self.lastDiff)
    {
        if (self.firstRec >= 0)
        {
            [self flush];
        }
        self.lastDiff = diff;
        self.firstRec = rec;
        self.lastRec = rec;
    }
    else
    {
        self.lastRec = rec;
    }
}

-(void)flush
{
    [self.list addObject:[NSString stringWithFormat:@"MAP %d %d %d", self.firstRec, self.lastRec, self.lastDiff]];
}

@end
