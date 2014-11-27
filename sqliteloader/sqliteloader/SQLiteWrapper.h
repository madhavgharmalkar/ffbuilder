//
//  SQLiteWrapper.h
//  VedabaseB
//
//  Created by Peter Kollath on 11/8/12.
//  Copyright (c) 2012 GPSL. All rights reserved.
//

#import <sqlite3.h>

#import <Foundation/Foundation.h>

@interface SQLiteWrapper : NSObject

@end

@interface SQLiteBlob : NSObject {
    sqlite3_blob * _blob;
}
-(id)initWithBlob:(sqlite3_blob *)theBlob;
-(NSData *)data;
-(NSMutableData *)mutableData;
-(void)close;
-(int)length;
-(int)readBytes:(void *)aBuffer length:(int)aLength offset:(int)aOffset;

@end

@class SQLiteDatabase;

@interface SQLiteCommand : NSObject {
    sqlite3_stmt * _statement;
}

@property (assign) SQLiteDatabase * database;

-(id)initWithStatement:(sqlite3_stmt *)theStat database:(SQLiteDatabase *)db;
-(void)close;
-(void)bindString:(NSString *)str toVariable:(int)theVar;
-(void)bindData:(NSData *)objectData toVariable:(int)theVar;
-(void)bindInteger:(int)number toVariable:(int)theVar;
-(int)execute;
-(void)reset;
-(NSString *)stringValue:(int)index;
-(int)intValue:(int)index;
-(int64_t)int64Value:(int)index;
@end


@interface SQLiteDatabase : NSObject {
    sqlite3 * _database;
//    NSLock * _lock;
}

-(sqlite3 *)database;
-(int)open:(NSString *)filePath;
-(void)close;
-(int)execute:(NSString *)statement;
-(int)startTransaction;
-(int)endTransaction;
-(int)commit;
-(SQLiteCommand *)createCommand:(NSString *)statement;
-(SQLiteBlob *)openBlob:(int64_t)rowId database:(NSString *)theDBName table:(NSString *)theTableName column:(NSString *)theColumnName;
-(void)lock;
-(void)unlock;

@property NSLock * lockInstance;

@end


