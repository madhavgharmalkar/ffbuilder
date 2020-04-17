//
//  VBDictionaryMeaning.m
//  Builder_iPad
//
//  Created by Peter Kollath on 07/11/14.
//
//

#import "VBDictionaryMeaning.h"

@implementation VBDictionaryMeaning

-(id)initWithStorage:(FILE *)store
{
    self = [super init];
    if (self)
    {
        self.storage = store;
    }
    return self;
}

-(void)createTables
{
}

-(void)write
{
    fprintf(self.storage, "%d\t%d\t%s\n", self.wordID, self.dictionaryID, self.meaning.UTF8String);
}

@end
