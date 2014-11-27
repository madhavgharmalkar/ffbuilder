//
//  main.m
//  ffviews
//
//  Created by Peter Kollath on 13/11/14.
//  Copyright (c) 2014 Peter Kollath. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ViewsBuilder.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {

        ViewsBuilder * vb = [ViewsBuilder new];
        
        for(int i = 1; i < argc; i++)
        {
            if (strcmp(argv[i], "-l")==0 && (i + 1 < argc))
            {
                vb.levelFile = [NSString stringWithCString:argv[i+1] encoding:NSASCIIStringEncoding];
                i++;
            }
            else if (strcmp(argv[i], "-i")==0 && (i + 1 < argc))
            {
                vb.inputFile = [NSString stringWithCString:argv[i+1] encoding:NSASCIIStringEncoding];
                i++;
            }
            else if (strcmp(argv[i], "-odir")==0 && (i + 1 < argc))
            {
                vb.outputDir = [NSString stringWithCString:argv[i+1] encoding:NSASCIIStringEncoding];
                i++;
            }

        }
        
        if ([vb validate])
        {
            [vb process];
        }
        else
        {
            NSLog(@"Usage:\n\nffviews -i <inputfile> -l <levelsfile> -odir <outputdir>");
        }
        
    }
    return 0;
}
