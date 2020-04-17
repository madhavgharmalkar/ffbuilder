//
//  VBStylesBuilderController.m
//  Builder_iPad
//
//  Created by Peter Kollath on 1/26/13.
//
//

#import "VBStylesBuilderController.h"

@implementation VBStylesBuilderController


-(void)willExecuteScript
{
    NSMutableDictionary * dict = [[NSMutableDictionary alloc] init];
    self.images = dict;
    
    dict = [[NSMutableDictionary alloc] init];
    self.styles = dict;

    dict = [[NSMutableDictionary alloc] init];
    self.colors = dict;
    
}

-(void)useLineWithParameter:(NSString *)paramName withValue:(NSString *)paramValue
{
    if ([paramName isEqualToString:@"Directory"]) {
        self.currentDirectory = paramValue;
    } else if ([paramName isEqualToString:@"TargetFile"]) {
        self.targetFile = paramValue;
    } else if ([paramName isEqualToString:@"StylesFile"]) {
        self.altStylesFile = [self.currentDirectory stringByAppendingPathComponent:paramValue];
    }
}

-(void)useLineWithParameter:(NSString *)paramName withIndex:(NSString *)aIndex withValue:(NSString *)aValue
{
    if ([paramName isEqualToString:@"File"]) {
        [self.images setObject:[self.currentDirectory stringByAppendingPathComponent:aValue]
                        forKey:aIndex];
    } else if ([paramName isEqualToString:@"Text"]) {
        [self.styles setObject:[self.currentDirectory stringByAppendingPathComponent:aValue]
                        forKey:aIndex];
    } else if ([paramName isEqualToString:@"Color"]) {
        [self.colors setObject:aValue forKey:aIndex];
    }
}

-(void)didExecuteScript
{
    
    NSString * key;

    NSLog(@"Started - Building vbstylist");

    NSMutableData * data = [[NSMutableData alloc] init];
    NSKeyedArchiver * ka = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    NSMutableDictionary * arr = [[NSMutableDictionary alloc] init];

    //
    // writing colors
    NSEnumerator * enumColors = [self.colors keyEnumerator];
    while(key = [enumColors nextObject])
    {
        NSString * color = [self.colors valueForKey:key];
        //NSData * data = [color dataUsingEncoding:NSUTF8StringEncoding];
        [arr setObject:color forKey:key];
    }
    [ka encodeObject:arr forKey:@"colors"];
    
    //
    // writing images
    //
    arr = [[NSMutableDictionary alloc] init];
    NSEnumerator * enumImages = [self.images keyEnumerator];
    while(key = [enumImages nextObject])
    {
        NSString * fileName = [self.images valueForKey:key];
        NSData * data = [[NSData alloc] initWithContentsOfFile:fileName];
        if (data == nil) {
            NSLog(@"Unknown file for key %@", key);
        } else {
            [arr setObject:data forKey:key];
        }
    }
    
    [ka encodeObject:arr forKey:@"images"];

    //
    // writing styles
    //
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.altStylesFile])
    {
        arr = [[NSMutableDictionary alloc] init];
        NSString * strStyles = [NSString stringWithContentsOfFile:self.altStylesFile
                                                         encoding:NSUTF8StringEncoding
                                                            error:NULL];
        NSCharacterSet * wscs = [NSCharacterSet whitespaceCharacterSet];
        NSArray * lines = [strStyles componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        NSString * currentStyle;
        int lno = 1;
        NSString * line;
        for(NSString * lineA in lines)
        {
            line = lineA;
            //NSLog(@"Line %d - Reading styles", lno);
            if ([line hasPrefix:@" "]) {
                line = [lineA stringByTrimmingCharactersInSet:wscs];
            }
            if ([line hasPrefix:@"style"]) {
                NSArray * parts = [line componentsSeparatedByString:@"\t"];
                if (parts.count == 2)
                {
                    currentStyle = parts[1];
                }
            }
            if ([line hasPrefix:@"prop"]) {
                NSArray * parts = [line componentsSeparatedByString:@"\t"];
                if (parts.count == 3)
                {
                    NSMutableDictionary * sd = [arr objectForKey:currentStyle];
                    if (sd == nil)
                    {
                        sd = [[NSMutableDictionary alloc] init];
                        [arr setObject:sd forKey:currentStyle];
                    }
                    [sd setObject:parts[2] forKey:parts[1]];
                }
            }
            lno++;
        }
        //[self.delegate logValue:@"Done" forKey:@"Reading styles"];
        [ka encodeObject:arr forKey:@"styles"];
    }

    //
    // writing signature
    //
    [ka encodeObject:@"VedabaseLayout" forKey:@"content"];
    [ka finishEncoding];

    [data writeToFile:self.targetFile atomically:YES];

    NSLog(@"Output writen to file: %@", self.targetFile);
    NSLog(@"Done - Building vbstylist");
}


@end
