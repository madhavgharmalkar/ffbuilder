//
//  SQLiteWrapper.m
//  VedabaseB
//
//  Created by Peter Kollath on 11/8/12.
//  Copyright (c) 2012 GPSL. All rights reserved.
//

#import "SQLiteWrapper.h"

@implementation SQLiteWrapper

@end


@implementation SQLiteDatabase

-(id)init
{
    self = [super init];
    if (self)
    {
        self.lockInstance = [[NSLock alloc] init];
    }
    return self;
}

-(void)dealloc
{
    [self close];
    self.lockInstance = nil;

}


-(sqlite3 *)database
{
    return _database;
}

-(int)open:(NSString *)filePath
{
    [self.lockInstance lock];
    int result = sqlite3_open_v2([filePath UTF8String], &_database, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, NULL);
    [self.lockInstance unlock];
    return result;
}

-(void)close
{
    if (_database != NULL)
    {
        [self.lockInstance lock];
        sqlite3_close(_database);
        _database = NULL;
        [self.lockInstance unlock];
    }
}

-(int)execute:(NSString *)statement
{
    int r = 0;
    [self.lockInstance lock];
    r = sqlite3_exec(_database, [statement UTF8String], NULL, NULL, NULL);
    [self.lockInstance unlock];
    return r;
}

-(int)startTransaction
{
    return [self execute:@"BEGIN"];
}

-(int)endTransaction
{
    return [self execute:@"END"];
}

-(int)commit
{
    return [self execute:@"COMMIT;"];
}

-(SQLiteCommand *)createCommand:(NSString *)statement
{
    sqlite3_stmt * stm;
    [self.lockInstance lock];
    if (sqlite3_prepare_v2(_database, 
                           [statement UTF8String], -1, &stm, NULL) != SQLITE_OK)
    {
        sqlite3_finalize(stm);
        [self.lockInstance unlock];
        return nil;
    }
    [self.lockInstance unlock];
    
    SQLiteCommand * command = [[SQLiteCommand alloc] initWithStatement:stm database:self];
    return command;
}

-(void)lock
{
    [self.lockInstance lock];
}

-(void)unlock
{
    [self.lockInstance unlock];
}

-(SQLiteBlob *)openBlob:(int64_t)rowId database:(NSString *)theDBName table:(NSString *)theTableName column:(NSString *)theColumnName
{
    sqlite3_blob * blob;

    [self.lockInstance lock];
    sqlite3_blob_open(_database, [theDBName UTF8String], [theTableName UTF8String], [theColumnName UTF8String], rowId, 0, &blob);
    [self.lockInstance unlock];
    
    if (blob != NULL)
    {
        return [[SQLiteBlob alloc] initWithBlob:blob];
    }
    
    return nil;
}

@end


@implementation SQLiteBlob

-(id)initWithBlob:(sqlite3_blob *)theBlob
{
    self = [super init];
    if (self)
    {
        _blob = theBlob;
    }
    return self;
}

-(NSData *)data
{
    return (NSData *)[self mutableData];
}

-(NSMutableData *)mutableData
{
    NSMutableData * data = nil;
    int size = [self length];
    data = [[NSMutableData alloc] initWithLength:size];
    if (sqlite3_blob_read(_blob, [data mutableBytes], size, 0) != SQLITE_OK)
    {
        data = nil;
    }
    return data;
}

-(int)length
{
    return sqlite3_blob_bytes(_blob);
}

/*
 * close connection to BLOB
 */
-(void)close
{
    sqlite3_blob_close(_blob);
}

-(int)readBytes:(void *)aBuffer length:(int)aLength offset:(int)aOffset
{
    return sqlite3_blob_read(_blob, aBuffer, aLength, aOffset);
}

@end


@implementation SQLiteCommand

@synthesize database;

-(id)initWithStatement:(sqlite3_stmt *)theStat database:(SQLiteDatabase *)db
{
    self = [super init];
    if (self) {
        _statement = theStat;
        self.database = db;
    }
    
    return self;
}

-(void)dealloc
{
    [self close];
}


-(void)close
{
    if (_statement != NULL)
    {
        sqlite3_finalize(_statement);
        _statement = NULL;
    }
}

-(void)bindString:(NSString *)str toVariable:(int)theVar
{
    sqlite3_bind_text(_statement, theVar, [str UTF8String], -1, NULL);
}

-(void)bindData:(NSData *)objectData toVariable:(int)theVar
{
    sqlite3_bind_blob(_statement, theVar, [objectData bytes], (int)[objectData length], NULL);
}

-(void)bindInteger:(int)number toVariable:(int)theVar
{
    sqlite3_bind_int(_statement, theVar, number);
}


-(int)execute
{
    [self.database lock];
    int r = sqlite3_step(_statement);
    [self.database unlock];
    return r;
}

-(void)reset
{
    [self.database lock];
    sqlite3_reset(_statement);
    [self.database unlock];
}

-(NSString *)stringValue:(int)index
{
    return [NSString stringWithUTF8String:(const char *)sqlite3_column_text(_statement, index)];
}

-(int)intValue:(int)index
{
    return sqlite3_column_int(_statement, index);
}

-(int64_t)int64Value:(int)index
{
    return sqlite3_column_int64(_statement, index);
}

@end



























