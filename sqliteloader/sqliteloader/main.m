//
//  main.m
//  sqliteloader
//
//  Created by Peter Kollath on 12/11/14.
//  Copyright (c) 2014 Peter Kollath. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Loader.h"

/*
 * arguments:
 
 -table <tablename>        filename with configuration
 -cols <configstring>
 -i <inputfilename>
 -t <targetdatabasefilename>
 */

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSString *tableName;
        NSString *colsSpec;
        NSString *inputFile;
        NSString *targetFile;
        Loader * loader = [Loader new];
        
        for(int i = 1; i < argc; i++)
        {
            //printf("%s\n", argv[i]);
            if (strcmp(argv[i], "-table")==0 && (i + 1 < argc))
            {
                tableName = [NSString stringWithCString:argv[i+1] encoding:NSASCIIStringEncoding];
                i++;
            }
            else if (strcmp(argv[i], "-cols")==0 && (i + 1 < argc))
            {
                colsSpec = [NSString stringWithCString:argv[i+1] encoding:NSASCIIStringEncoding];
                i++;
            }
            else if (strcmp(argv[i], "-i")==0 && (i + 1 < argc))
            {
                inputFile = [NSString stringWithCString:argv[i+1] encoding:NSASCIIStringEncoding];
                i++;
            }
            else if (strcmp(argv[i], "-t")==0 && (i + 1 < argc))
            {
                targetFile = [NSString stringWithCString:argv[i+1] encoding:NSASCIIStringEncoding];
                i++;
            }
            else if (strcmp(argv[i], "-noclean")==0)
            {
                loader.noClean = YES;
            }
        }
        
        NSLog(@"SQLiteLoader-------------------");
        NSLog(@"  tableName   : %@", tableName);
        NSLog(@"  columns     : %@", colsSpec);
        NSLog(@"  input file  : %@", inputFile);
        NSLog(@"  target file : %@", targetFile);
        NSLog(@"  ================================== ");
        
        if ([tableName length] == 0 || [colsSpec length] == 0 ||
            [inputFile length] == 0 || [targetFile length] == 0)
        {
            NSLog(@"==Usage======");
            NSLog(@"                -table <tablename>        filename with configuration\
                  -cols <configstring>\
                  -i <inputfilename>\
                  -t <targetdatabasefilename>\
                  -noclean");
            NSLog(@"\nFormat of configstring example:\n\n -cols \"id:integer,name:text,data:blob,ref:integer\"");
            NSLog(@"string consists of parts separated by comma, each part has two subparts divided by :");
            NSLog(@"first subpart is column name, second subpart is column data type");
            NSLog(@"accepted data types are: integer, text, blob, blobfile (file url of data file)");
            NSLog(@"-noclean mean, that table will not be deleted before loading (used for updates)");
        }
        else
        {
            loader.tableName = tableName;
            loader.columns = colsSpec;
            loader.inputFile = inputFile;
            loader.targetFile = targetFile;
            
            [loader load];
        }
    }
    return 0;
}
