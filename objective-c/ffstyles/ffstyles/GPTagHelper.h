//
//  GPTagHelper.h
//  Builder
//
//  Created by Peter Kollath on 10/15/10.
//  Copyright 2010 GPSL. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface GPTagHelper : NSObject {

}

+(void)readParaFormating:(NSArray *)dict  fromIndex:(int)stidx  target:(NSMutableDictionary *)targ;
+(void)readCharFormating:(NSArray *)dict target:(NSMutableDictionary *)targ;
+(void)readColor:(NSArray *)dict withPrefix:(NSString *)prefix index:(int *)idx target:(NSMutableDictionary *)obj;
+(NSString *)readBorderFormating:(NSDictionary *)dict withPrefix:(NSString *)prefix forSide:(NSString *)side target:(NSMutableDictionary *)targ;
+(NSSet *)readTabSpaces:(NSDictionary *)dict withPrefix:(NSString *)prefix;
+(NSString *)alignFromString:(NSString *)str;
+(NSString *)inchToPoints:(id)value;
+(void)appendCssStyleFromDictionary:(NSDictionary *)dict toString:(NSMutableString *)s;
+(NSString *)substitutionFontName:(NSString *)fname;
+(NSString *)getMIMEType:(NSString *)str;
+(NSString *)getMIMETypeFromExtension:(NSString *)str;
+(void)readBorders:(NSArray *)arrTag index:(int *)startIndex target:(NSMutableDictionary *)obj;
+(void)readIndentFormating:(NSArray *)arrTag index:(int *)startIdx target:(NSMutableDictionary *)obj;

@end
