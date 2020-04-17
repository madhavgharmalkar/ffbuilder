//
//  RKSortedList.h
//  Builder_iPad
//
//  Created by Peter Kollath on 4/22/12.
//  Copyright (c) 2012 GPSL. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RKSortedList : NSObject
{
    NSString * sortingKey;
    NSMutableArray * array;
    BOOL modified;
    NSString * keyName;
}

@property (nonatomic, retain) NSString * sortingKey; 
@property (assign) BOOL modified;
@property (nonatomic, retain) NSString * keyName;

-(int)count;
-(id)objectAtIndex:(NSUInteger)a;
-(void)addObject:(id)obj;
-(id)objectForKey:(NSString *)key;

-(void)loadFile:(NSString *)fileName;
-(void)writeToFile:(NSString *)fileName atomically:(BOOL)useAuxiliaryFile;

@end
