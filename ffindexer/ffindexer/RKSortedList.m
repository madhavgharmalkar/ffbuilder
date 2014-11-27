//
//  RKSortedList.m
//  Builder_iPad
//
//  Created by Peter Kollath on 4/22/12.
//  Copyright (c) 2012 GPSL. All rights reserved.
//

#import "RKSortedList.h"

@implementation RKSortedList

@synthesize sortingKey;
@synthesize modified;
@synthesize keyName;

-(id)init
{
    self = [super init];
    
    if (self)
    {
        self.modified = NO;
        self.sortingKey = @"text";
        array = [[NSMutableArray alloc] init];
    }
    
    return self;
}

-(id)initWithSortingKey:(NSString *)key
{
    self = [super init];
    
    if (self)
    {
        self.modified = NO;
        self.sortingKey = key;
        array = [[NSMutableArray alloc] init];
    }
    
    return self;
}

#pragma mark -
#pragma mark Loading and saving file


-(void)writeToFile:(NSString *)fileName atomically:(BOOL)useAuxiliaryFile
{
    [array writeToFile:fileName atomically:useAuxiliaryFile];
}


-(void)loadFile:(NSString *)fileName
{
    array = [[NSMutableArray alloc] initWithContentsOfFile:fileName];
}


#pragma mark -
#pragma content access


-(id)objectForKey:(NSString *)key from:(int)a to:(int)b
{
    if (b < a)
        return nil;
    
    if (a == b)
    {
        NSString * str = [[array objectAtIndex:a] objectForKey:keyName];
        if ([str compare:key options:NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch] == NSOrderedSame)
            return [array objectAtIndex:a];
        return nil;
    }

    if (a == b - 1)
    {
        NSString * str = [[array objectAtIndex:a] objectForKey:keyName];
        if ([str compare:key options:NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch] == NSOrderedSame)
            return [array objectAtIndex:a];
        str = [[array objectAtIndex:b] objectForKey:keyName];
        if ([str compare:key options:NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch] == NSOrderedSame)
            return [array objectAtIndex:b];
        return nil;
    }
    
    int c = (a + b) / 2;
    
    NSString * str = [[array objectAtIndex:c] objectForKey:keyName];
    int r = [str compare:key options:NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch];

    if (r == NSOrderedSame)
        return [array objectAtIndex:c];
    if (r == NSOrderedAscending)
        return [self objectForKey:key from:c to:b];
    else {
        return [self objectForKey:key from:a to:c];
    }
    
}

-(id)objectForKey:(NSString *)key
{
    return [self objectForKey:key from:0 to:(int)[array count]-1];
}

-(int)indexForKey:(NSString *)key from:(int)a to:(int)b
{
    if (b < a)
        return a;
    int r = 0;
    if (a == b)
    {
        NSString * str = [[array objectAtIndex:a] objectForKey:keyName];
        r = [str compare:key options:NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch];
        if (r == NSOrderedSame)
            return -1;
        else if (r == NSOrderedAscending)
            return a+1;
        else
            return a;
    }
    
    if (a == b - 1)
    {
        NSString * str = [[array objectAtIndex:a] objectForKey:keyName];
        r = [str compare:key options:NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch];
        if (r == NSOrderedSame)
            return -1;
        else if (r == NSOrderedDescending)
            return a;
        
        str = [[array objectAtIndex:b] objectForKey:keyName];
        r = [str compare:key options:NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch];
        if (r == NSOrderedAscending)
            return b+1;
        else if (r == NSOrderedSame)
            return -1;
        else {
            return b;
        }
    }
    
    int c = (a + b) / 2;
    
    NSString * str = [[array objectAtIndex:c] objectForKey:keyName];
    r = [str compare:key options:NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch];
    
    if (r == NSOrderedSame)
        return -1;
    if (r == NSOrderedAscending)
        return [self indexForKey:key from:c to:b];
    else {
        return [self indexForKey:key from:a to:c];
    }
    
}

-(id)objectAtIndex:(NSUInteger)a
{
    return [array objectAtIndex:a];
}

-(int)count
{
    return (int)[array count];
}

-(void)addObject:(id)obj
{
    NSString * key = [obj objectForKey:keyName];
    int i = [self indexForKey:key from:0 to:(int)[array count]-1];
    if (i < 0)
        return;
    self.modified = YES;
    [array insertObject:obj atIndex:i];
}



@end
