//
//  main.m
//  ffindexer
//
//  Created by Peter Kollath on 13/11/14.
//  Copyright (c) 2014 Peter Kollath. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Indexer.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {


        Indexer * idx = [Indexer new];
        
        for(int i = 1; i < argc; i++)
        {
            if (strcmp(argv[i], "-o")==0 && (i + 1 < argc))
            {
                idx.outputDir = [NSString stringWithCString:argv[i+1] encoding:NSASCIIStringEncoding];
                i++;
            }
            else if (strcmp(argv[i], "-i")==0 && (i + 1 < argc))
            {
                idx.inputFile = [NSString stringWithCString:argv[i+1] encoding:NSASCIIStringEncoding];
                i++;
            }
            else if (strcmp(argv[i], "-k")==0 && (i + 1 < argc))
            {
                idx.keywordFileName = [NSString stringWithCString:argv[i+1] encoding:NSASCIIStringEncoding];
                i++;
            }
        }

        if ([idx validate])
        {
            [idx doIndexing];
        }
        else
        {
            NSLog(@"Usage: ffindexer -o <outputdir> -i <inputfile>");
        }
    }

    return 0;
}
