//
//  TextDiffTracker.h
//  fftextdiff
//
//  Created by Peter Kollath on 19/11/14.
//  Copyright (c) 2014 Peter Kollath. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TextDiffTracker : NSObject


@property int firstRec;
@property int lastRec;
@property int lastDiff;
@property NSMutableArray * list;


-(void)insertRec:(int)rec diff:(int)diff;
-(void)flush;

@end
