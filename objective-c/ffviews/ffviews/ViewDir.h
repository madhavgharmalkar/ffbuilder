//
//  ViewDir.h
//  ffviews
//
//  Created by Peter Kollath on 13/11/14.
//  Copyright (c) 2014 Peter Kollath. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ViewDir : NSObject


@property NSString * name;
@property NSInteger pid;

@property NSMutableArray * subs;

-(ViewDir *)getChild:(NSString *)text;

@end
