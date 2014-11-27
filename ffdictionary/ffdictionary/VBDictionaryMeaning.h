//
//  VBDictionaryMeaning.h
//  Builder_iPad
//
//  Created by Peter Kollath on 07/11/14.
//
//

#import <Foundation/Foundation.h>

@interface VBDictionaryMeaning : NSObject

@property FILE * storage;
@property (assign) int dictionaryID;
@property (assign) int wordID;
@property (assign) int recordID;
@property (retain) NSString * meaning;

-(id)initWithStorage:(FILE *)store;
-(void)write;
-(void)createTables;
@end
