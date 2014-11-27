//
//  Appender.h
//  ffappendkeywords
//
//  Created by Peter Kollath on 24/11/14.
//  Copyright (c) 2014 Peter Kollath. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Appender : NSObject
{
    FILE * input;
    FILE * output;
}

@property NSString * inputFile;
@property NSString * keywordFile;
@property NSString * outputFile;

-(void)process;

@end
