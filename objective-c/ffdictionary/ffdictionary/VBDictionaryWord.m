//
//  VBDictionaryWord.m
//  Builder_iPad
//
//  Created by Peter Kollath on 07/11/14.
//
//

#import "VBDictionaryWord.h"

@implementation VBDictionaryWord

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
    fprintf(self.storage, "%d\t%s\t%s\n", self.ID, self.word.UTF8String, self.simple.UTF8String);
}

@end
