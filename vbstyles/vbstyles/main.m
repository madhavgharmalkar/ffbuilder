//
//  main.m
//  vbstyles
//
//  Created by Peter Kollath on 17/11/14.
//  Copyright (c) 2014 Peter Kollath. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VBStylesBuilderController.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSString * file;
        VBStylesBuilderController * builder = [[VBStylesBuilderController alloc] init];
        for(int i = 1; i < argc; i++)
        {
            if (strcmp(argv[i], "-i")==0 && (i + 1 < argc))
            {
                file = [NSString stringWithCString:argv[i+1] encoding:NSASCIIStringEncoding];
                i++;
            }
        }
        NSString * script = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:NULL];
        [builder executeScript:script];
    }
    return 0;
}


