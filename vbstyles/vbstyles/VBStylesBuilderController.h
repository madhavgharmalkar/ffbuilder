//
//  VBStylesBuilderController.h
//  Builder_iPad
//
//  Created by Peter Kollath on 1/26/13.
//
//

#import "GeneralBuilderController.h"

@interface VBStylesBuilderController : GeneralBuilderController


@property (copy, nonatomic) NSString * targetFile;
@property (copy, nonatomic) NSString * currentDirectory;
@property (strong, nonatomic) NSMutableDictionary * images;
@property (strong, nonatomic) NSMutableDictionary * styles;
@property (strong, nonatomic) NSMutableDictionary * colors;
@property (strong) NSString * altStylesFile;
@end
