//
//  ViewDir.m
//  ffviews
//
//  Created by Peter Kollath on 13/11/14.
//  Copyright (c) 2014 Peter Kollath. All rights reserved.
//

#import "ViewDir.h"


int gid = 1;

@implementation ViewDir


-(id)init
{
    self = [super init];
    if (self)
    {
        self.name = @"";
        self.pid = -1;
    }
    return self;
}

-(ViewDir *)getChild:(NSString *)text
{
    if (self.subs == nil)
    {
        self.subs = [NSMutableArray new];
    }
    
    for (ViewDir * vv in self.subs)
    {
        if ([vv.name isEqualToString:text])
            return vv;
    }
    
    ViewDir * vv = [ViewDir new];
    vv.name = text;
    vv.pid = [ViewDir nextGid];
    [self.subs addObject:vv];
    
    return vv;
}

+(int)nextGid
{
    int g = gid;
    gid++;
    return g;
}


@end
