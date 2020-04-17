//
//  Loader.h
//  sqliteloader
//
//  Created by Peter Kollath on 12/11/14.
//  Copyright (c) 2014 Peter Kollath. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SQLiteWrapper.h"

@interface Loader : NSObject


@property NSString * tableName;
@property NSString * columns;
@property NSString * inputFile;
@property NSString * targetFile;
@property NSString * updateColumn;


@property NSMutableArray * columnTypes;
@property NSMutableArray * columnNames;
@property NSMutableArray * columnSubst;
@property SQLiteDatabase * database;
@property SQLiteCommand * command;
@property BOOL noClean;

-(void)load;


@end
