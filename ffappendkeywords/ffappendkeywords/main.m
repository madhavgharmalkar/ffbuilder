//
//  main.m
//  ffappendkeywords
//
//  Created by Peter Kollath on 24/11/14.
//  Copyright (c) 2014 Peter Kollath. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Appender.h"

int main(int argc, const char * argv[]) {
    
    Appender * app = [Appender new];
    
    @autoreleasepool {
        for(int i = 1; i < argc; i++)
        {
            if (strcmp(argv[i], "-i")==0 && (i + 1 < argc))
            {
                app.inputFile = [NSString stringWithCString:argv[i+1] encoding:NSASCIIStringEncoding];
                i++;
            }
            else if (strcmp(argv[i], "-k")==0 && (i + 1 < argc))
            {
                app.keywordFile = [NSString stringWithCString:argv[i+1] encoding:NSASCIIStringEncoding];
                i++;
            }
            else if (strcmp(argv[i], "-o")==0 && (i + 1 < argc))
            {
                app.outputFile = [NSString stringWithCString:argv[i+1] encoding:NSASCIIStringEncoding];
                i++;
            }
        }
        
        
        [app process];

    }
    return 0;
}
