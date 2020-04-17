//
//  main.m
//  ffdictionary
//
//  Created by Peter Kollath on 13/11/14.
//  Copyright (c) 2014 Peter Kollath. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DictionaryBuilder.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        DictionaryBuilder * vb = [DictionaryBuilder new];
        
        for(int i = 1; i < argc; i++)
        {
            if (strcmp(argv[i], "-i")==0 && (i + 1 < argc))
            {
                [vb.inputFiles addObject:[NSString stringWithCString:argv[i+1] encoding:NSASCIIStringEncoding]];
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
            NSLog(@"Usage:\n\nffdictionary -i <inputfile1> -i <inputfile2> ... -odir <outputdir>");
        }
        
    }
    return 0;
}
