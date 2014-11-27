//
//  RKKeySet.m
//  ffanalyzer
//
//  Created by Peter Kollath on 16/11/14.
//  Copyright (c) 2014 Peter Kollath. All rights reserved.
//

#import "RKKeySet.h"

@implementation RKKeySet

-(id)init
{
    self = [super init];
    if (self) {
        self.nextId = 1;
        self.map = [NSMutableDictionary new];
    }
    return self;
}

-(void)addObject:(NSString *)str
{
    if ([self.map valueForKey:str] == nil)
    {
        [self.map setValue:[NSNumber numberWithInt:self.nextId] forKey:str];
        self.nextId++;
    }
}

-(NSInteger)idForKey:(NSString *)str
{
    NSInteger retVal = self.nextId;
    
    NSNumber * number = [self.map valueForKey:str];
    if (number == nil)
    {
        [self.map setValue:[NSNumber numberWithInt:retVal] forKey:str];
        self.nextId++;
    }
    else
    {
        retVal = [number integerValue];
    }
    
    return retVal;
}

-(NSEnumerator *)keyEnumerator
{
    return self.map.keyEnumerator;
}

@end
