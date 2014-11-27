//
//  main.m
//  ffanalyzer
//
//  Created by Peter Kollath on 12/11/14.
//  Copyright (c) 2014 Peter Kollath. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FlatFileImporter.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSString * currentDir;
        NSString * mainFile;
        NSString * outputDir;
        NSString * errorFile;
        for(int i = 1; i < argc; i++)
        {
            if (strcmp(argv[i], "-dir")==0 && (i + 1 < argc))
            {
                currentDir = [NSString stringWithCString:argv[i+1] encoding:NSASCIIStringEncoding];
                i++;
            }
            else if (strcmp(argv[i], "-i")==0 && (i + 1 < argc))
            {
                mainFile = [NSString stringWithCString:argv[i+1] encoding:NSASCIIStringEncoding];
                i++;
            }
            else if (strcmp(argv[i], "-odir")==0 && (i + 1 < argc))
            {
                outputDir = [NSString stringWithCString:argv[i+1] encoding:NSASCIIStringEncoding];
                i++;
            }
            else if (strcmp(argv[i], "-e")==0 && (i + 1 < argc))
            {
                errorFile = [NSString stringWithCString:argv[i+1] encoding:NSASCIIStringEncoding];
                i++;
            }
        }
        
        
        if (currentDir.length == 0 || mainFile.length == 0
            || outputDir.length == 0 || errorFile.length == 0)
        {
            NSLog(@"Not all arguments provided. Usage:\nffanalyzer -i <inputfilename> -dir <inputdir> -odir <outputdir> -e <errorfile>");
        }
        else
        {
            NSMutableDictionary * safeStringReplace = [[NSMutableDictionary alloc] init];
            
            FlatFileImporter * ffi = [[FlatFileImporter alloc] init];
            ffi.safeStringReplace = safeStringReplace;
            ffi.inputPath = currentDir;
            ffi.storePath = [NSURL fileURLWithPath:currentDir];
            [ffi openFile:[NSURL fileURLWithPath:[currentDir stringByAppendingPathComponent:mainFile]]];
            ffi.workingDirectory = outputDir;
            [ffi parseFile];
        }
    }
    return 0;
}
