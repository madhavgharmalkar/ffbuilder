//
//  VBDictionaryInstance.h
//  Builder_iPad
//
//  Created by Peter Kollath on 07/11/14.
//
//

#import <Foundation/Foundation.h>

@interface VBDictionaryInstance : NSObject

@property FILE * storage;
@property int ID;
@property (retain) NSString * name;


-(id)initWithStorage:(FILE *)store;
-(void)write;
-(void)createTables;

@end
