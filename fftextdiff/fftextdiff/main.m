//
//  main.m
//  fftextdiff
//
//  Created by Peter Kollath on 19/11/14.
//  Copyright (c) 2014 Peter Kollath. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TextDiff.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        TextDiff * cb = [TextDiff new];
        
        for(int i = 1; i < argc; i++)
        {
            if (strcmp(argv[i], "-inew")==0 && (i + 1 < argc))
            {
                cb.fileNewName = [NSString stringWithCString:argv[i+1] encoding:NSASCIIStringEncoding];
                i++;
            }
            else if (strcmp(argv[i], "-iold")==0 && (i + 1 < argc))
            {
                cb.fileOldName = [NSString stringWithCString:argv[i+1] encoding:NSASCIIStringEncoding];
                i++;
            }
            else if (strcmp(argv[i], "-ipos")==0 && (i + 1 < argc))
            {
                cb.indexPos = atoi(argv[i+1]);
                i++;
            }
            else if (strcmp(argv[i], "-tpos")==0 && (i + 1 < argc))
            {
                cb.textPos = atoi(argv[i+1]);
                i++;
            }
            else if (strcmp(argv[i], "-o")==0 && (i + 1 < argc))
            {
                cb.outputFileName = [NSString stringWithCString:argv[i+1] encoding:NSASCIIStringEncoding];
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
