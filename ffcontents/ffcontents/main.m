//
//  main.m
//  ffcontents
//
//  Created by Peter Kollath on 13/11/14.
//  Copyright (c) 2014 Peter Kollath. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ContentsBuilder.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {

        ContentsBuilder * cb = [ContentsBuilder new];
    
        for(int i = 1; i < argc; i++)
        {
            if (strcmp(argv[i], "-l")==0 && (i + 1 < argc))
            {
                cb.levelFile = [NSString stringWithCString:argv[i+1] encoding:NSASCIIStringEncoding];
                i++;
            }
            else if (strcmp(argv[i], "-i")==0 && (i + 1 < argc))
            {
                cb.inputFile = [NSString stringWithCString:argv[i+1] encoding:NSASCIIStringEncoding];
                i++;
            }
            else if (strcmp(argv[i], "-odir")==0 && (i + 1 < argc))
            {
                cb.outputDir = [NSString stringWithCString:argv[i+1] encoding:NSASCIIStringEncoding];
                i++;
            }
        }
        
        if ([cb validate])
        {
            [cb process];
        }
        else
        {
            NSLog(@"usage:\n\nffcontents -i <inputfile> -odir <outputdir> -l <levelsfile>");
        }
        
    }
    return 0;
}
