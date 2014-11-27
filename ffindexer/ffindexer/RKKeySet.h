//
//  RKKeySet.h
//  ffanalyzer
//
//  Created by Peter Kollath on 16/11/14.
//  Copyright (c) 2014 Peter Kollath. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RKKeySet : NSObject

@property NSInteger nextId;
@property NSMutableDictionary * map;

-(void)addObject:(NSString *)str;
-(NSInteger)idForKey:(NSString *)str;
-(NSEnumerator *)keyEnumerator;

@end
