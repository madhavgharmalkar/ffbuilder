//
//  Appender.m
//  ffappendkeywords
//
//  Created by Peter Kollath on 24/11/14.
//  Copyright (c) 2014 Peter Kollath. All rights reserved.
//

#import "Appender.h"

@implementation Appender


-(void)process
{
    NSMutableDictionary * dict = [NSMutableDictionary new];
    NSString * str = [NSString stringWithContentsOfFile:self.inputFile encoding:NSUTF8StringEncoding error:NULL];
    NSArray * arr = [str componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    for(NSString * line in arr)
    {
        NSArray * p = [line componentsSeparatedByString:@"\t"];
        if (p.count == 2)
            [dict setValue:p[1] forKey:p[0]];
    }
    int len = 0;
    
    self->output = fopen([self.outputFile UTF8String], "wt");
    FILE * i = fopen([self.inputFile UTF8String], "rt");
    
    char *c = malloc(200000);
    while((c = fgets(c, 200000, i)) != NULL)
    {
        len = (int)strlen(c);
        if (len > 0 && c[len-1] == '\n')
            c[len-1] = '\0';
        NSString * line = [NSString stringWithUTF8String:c];
        NSArray * part = [line componentsSeparatedByString:@"\t"];
        
        if (part.count == 4)
        {
            if ([dict valueForKey:part[1]])
            {
                NSLog(@"line found");
            }
        }
    }
    
    fclose(self->output);
    fclose(i);
}

@end
