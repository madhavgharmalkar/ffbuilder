//
//  GPDebuggerStyleStream.h
//  Builder_iPad
//
//  Created by Peter Kollath on 3/9/13.
//
//

#import <Foundation/Foundation.h>
@class GPDebugger;


@interface GPDebuggerStyleStream : NSObject


@property (assign) FILE * file;
@property (assign) GPDebugger * parent;

-(void)writeText:(NSString *)str;

@end
