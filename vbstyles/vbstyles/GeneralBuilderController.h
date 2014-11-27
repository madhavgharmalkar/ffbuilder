//
//  GeneralBuilderController.h
//  Builder_iPad
//
//  Created by Peter Kollath on 1/26/13.
//
//

#import <Foundation/Foundation.h>

@interface GeneralBuilderController : NSObject

-(void)cancelTaskExecution:(id)sender;
-(void)executeScript:(NSString *)script;



-(void)willExecuteScript;
-(void)useLineWithParameter:(NSString *)paramName withValue:(NSString *)paramValue;
-(void)useLineWithParameter:(NSString *)paramName withIndex:(NSString *)aIndex withValue:(NSString *)aValue;
-(void)useLineWithStatement:(NSString *)statement;
-(void)didExecuteScript;

@end
