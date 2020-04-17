//
//  VBDictionaryInstance.m
//  Builder_iPad
//
//  Created by Peter Kollath on 07/11/14.
//
//

#import "VBDictionaryInstance.h"

@implementation VBDictionaryInstance

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
    fprintf(self.storage, "%d\t%s\n", self.ID, self.name.UTF8String);
}

@end
