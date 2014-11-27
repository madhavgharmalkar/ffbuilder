//
//  GeneralBuilderController.m
//  Builder_iPad
//
//  Created by Peter Kollath on 1/26/13.
//
//

#import "GeneralBuilderController.h"

@implementation GeneralBuilderController

//
// subclasses must override this methods
//
-(void)cancelTaskExecution:(id)sender
{
    assert(false);
}

//
// subclasses must not override this methods
//
-(void)executeScript:(NSString *)script
{
    [self willExecuteScript];
    
    NSCharacterSet * whites = [NSCharacterSet whitespaceCharacterSet];
    NSArray * lines = [script componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    for (NSString * rawLine in lines)
    {
        NSString * line = [rawLine stringByTrimmingCharactersInSet:whites];
        NSRange eqRange = [line rangeOfString:@"="];
        if ([line hasPrefix:@"#"]) {
            // ignore this line, it is comment
        } else if (eqRange.location != NSNotFound) {
            // we have property line
            NSString * propertyName = [[line substringToIndex:eqRange.location] stringByTrimmingCharactersInSet:whites];
            NSString * propertyValue = [line substringFromIndex:(eqRange.location + eqRange.length)];

            NSRange rangeIndexStart = [propertyName rangeOfString:@"["];
            NSRange rangeIndexStop = [propertyName rangeOfString:@"]"];
            if (rangeIndexStart.location != NSNotFound && rangeIndexStop.location != NSNotFound) {
                NSString * aName = [propertyName substringToIndex:rangeIndexStart.location];
                NSString * aIndex = [propertyName substringWithRange:NSMakeRange(rangeIndexStart.location + 1, rangeIndexStop.location - rangeIndexStart.location - 1)];
                [self useLineWithParameter:aName withIndex:aIndex withValue:propertyValue];
            } else {
                [self useLineWithParameter:propertyName withValue:propertyValue];
            }
        } else {
            [self useLineWithStatement:line];
        }
    }

    [self didExecuteScript];
}

-(void)willExecuteScript
{
}

// for lines:
// name=value
-(void)useLineWithParameter:(NSString *)paramName withValue:(NSString *)paramValue
{
}

// for lines:
// name[index]=value
-(void)useLineWithParameter:(NSString *)paramName withIndex:(NSString *)aIndex withValue:(NSString *)aValue
{
}

// for lines:
// name
-(void)useLineWithStatement:(NSString *)statement
{
}

-(void)didExecuteScript
{
}

@end
