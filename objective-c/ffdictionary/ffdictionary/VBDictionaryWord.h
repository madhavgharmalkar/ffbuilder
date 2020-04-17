//
//  VBDictionaryWord.h
//  Builder_iPad
//
//  Created by Peter Kollath on 07/11/14.
//
//

#import <Foundation/Foundation.h>

@interface VBDictionaryWord : NSObject

@property FILE * storage;
@property (assign) int ID;
@property (retain) NSString * word;
@property (retain) NSString * simple;

-(id)initWithStorage:(FILE *)store;
-(void)write;
-(void)createTables;
@end
