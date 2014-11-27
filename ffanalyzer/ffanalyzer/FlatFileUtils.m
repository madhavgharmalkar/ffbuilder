//
//  FFFUtils.m
//  Builder_iPad
//
//  Created by Peter Kollath on 11/9/12.
//  Copyright (c) 2012 GPSL. All rights reserved.
//

#import "FlatFileUtils.h"


#pragma mark -

int gEthCounter = 1;

NSString * highlighterColors[] = {
    nil,
    @"#ffff00",
    @"#00ff00",
    @"#00ffff",
    @"#ff0000",
    @"#ff00ff",
    @"#ff6600",
    @"#ff6699",
    @"#6666ff",
    @"#7f7fff",
    @"#ff7f7f"
};

@implementation FlatFileUtils


+(NSString *)encodeLinkSafeString:(NSString *)string
{
    NSString * str = [string stringByReplacingOccurrencesOfString:@"/" withString:@"%2F"];
    return [str stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

+(NSString *)decodeLinkSafeString:(NSString *)string
{
    NSString * str = [string stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return [str stringByReplacingOccurrencesOfString:@"%2F" withString:@"/"];
}

+(NSString *)removeTags:(NSString *)str
{
    if (str == nil)
        return nil;
    
    NSMutableString * text = [[NSMutableString alloc] initWithString:str];
    
    int start = 0;
    int end = 0;
    int status = 0;
    int removeRange = 0;
    int removedCount = 1;
    
    NSSet * spaceTags = [NSSet setWithObjects:@"<CR>", @"<HR>", @"<HS>", @"<SP>", 
                         @"<SB>", @"</SS>", @"<TA>", @"</TA>", @"<CE>",
                         @"</CE>", @"<GP>", @"<GD>", @"<GM>", @"<GT>",
                         @"<GQ>", @"<GI>", @"<GA>", @"<GF>", nil];
    
    while (removedCount > 0) {
        removedCount = 0;
        for(int i = 0; (removedCount == 0) && (i < [text length]); i++)
        {
            if (status == 0) {
                if ([text characterAtIndex:i] == '<') {
                    status = 1;
                }
            } else if (status == 1) {
                if ([text characterAtIndex:i] == '<') {
                    status = 0;
                } else {
                    start = i-1;
                    status = 2;
                }
            } else if (status == 2) {
                if ([text characterAtIndex:i] == '>') {
                    end = i;
                    removeRange = 1;
                    status = 0;
                } else if ([text characterAtIndex:i] == '"') {
                    status = 3;
                }
            } else if (status == 3) {
                if ([text characterAtIndex:i] == '"') {
                    status = 4;
                }
            } else if (status == 4) {
                if ([text characterAtIndex:i] == '"') {
                    status = 3;
                } else if ([text characterAtIndex:i] == '>') {
                    end = i;
                    removeRange = 1;
                    status = 0;
                }
            }
            
            if (removeRange == 1) {
                NSRange foundRange = NSMakeRange(start, end - start + 1);
                NSString * extractedTag = [text substringWithRange:foundRange];
                if ([spaceTags containsObject:extractedTag])
                    [text replaceCharactersInRange:foundRange withString:@" "];
                else
                    [text replaceCharactersInRange:foundRange withString:@""];
                removeRange = 0;
                removedCount++;
            }
        }
    }
    
    return text;
}

+(NSString *)removeTagsAndNotes:(NSString *)str
{
    if (str == nil)
        return nil;
    
    NSMutableString * text = [[NSMutableString alloc] initWithString:str];
    
    int start = 0;
    int end = 0;
    int status = 0;
    int removeRange = 0;
    int removedCount = 1;
    int pwLevel = 0;
    int pwStart = 0;
    
    NSSet * spaceTags = [NSSet setWithObjects:@"<CR>", @"<HR>", @"<HS>", @"<SP>", 
                         @"<SB>", @"</SS>", @"<TA>", @"</TA>", @"<CE>",
                         @"</CE>", @"<GP>", @"<GD>", @"<GM>", @"<GT>",
                         @"<GQ>", @"<GI>", @"<GA>", @"<GF>", nil];
    
    while (removedCount > 0) {
        removedCount = 0;
        for(int i = 0; (removedCount == 0) && (i < [text length]); i++)
        {
            if (status == 0) {
                if ([text characterAtIndex:i] == '<') {
                    status = 1;
                }
            } else if (status == 1) {
                if ([text characterAtIndex:i] == '<') {
                    status = 0;
                } else {
                    start = i-1;
                    status = 2;
                }
            } else if (status == 2) {
                if ([text characterAtIndex:i] == '>') {
                    end = i;
                    removeRange = 1;
                    status = 0;
                } else if ([text characterAtIndex:i] == '"') {
                    status = 3;
                }
            } else if (status == 3) {
                if ([text characterAtIndex:i] == '"') {
                    status = 4;
                }
            } else if (status == 4) {
                if ([text characterAtIndex:i] == '"') {
                    status = 3;
                } else if ([text characterAtIndex:i] == '>') {
                    end = i;
                    removeRange = 1;
                    status = 0;
                }
            }
            
            if (removeRange == 1) {
                NSRange foundRange = NSMakeRange(start, end - start + 1);
                NSString * extractedTag = [text substringWithRange:foundRange];
                if ([extractedTag hasPrefix:@"<PW"]) {
                    if (pwLevel == 0)
                        pwStart = start;
                    pwLevel++;
                } else if ([extractedTag hasPrefix:@"<LT"]) {
                    pwLevel--;
                    if (pwLevel == 0) {
                        foundRange = NSMakeRange(pwStart, end - pwStart + 1);
                        [text replaceCharactersInRange:foundRange withString:@""];
                        removedCount++;
                    }
                } else if (pwLevel == 0) {
                    if ([spaceTags containsObject:extractedTag])
                        [text replaceCharactersInRange:foundRange withString:@" "];
                    else
                        [text replaceCharactersInRange:foundRange withString:@""];
                    removedCount++;
                }
                removeRange = 0;
            }
        }
    }
    
    return text;
}

+(NSString *)makeDictionaryString:(NSString *)aString
{
    NSData * data = [aString dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSMutableData * mdata = [[NSMutableData alloc] initWithLength:([data length] + 4)];
    
    const unsigned char * src = [data bytes];
    unsigned char * md = [mdata mutableBytes];
    int count = [data length];
    int j = 0;
    for(int i = 0; i < count; i++)
    {
        if (isalnum(src[i]))
        {
            md[j] = tolower(src[i]);
            j++;
        }
    }
    [mdata setLength:j];
    
    NSString * str = [[NSString alloc] initWithData:mdata encoding:NSASCIIStringEncoding];
    mdata = nil;
    
    return str;
}

+(NSString *)makeIndexableString:(NSString *)aString
{
	NSData * data = [aString dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
	NSMutableData * mdata = [[NSMutableData alloc] initWithLength:([data length] + 4)];
	
	const unsigned char * src = [data bytes];
	unsigned char * md = [mdata mutableBytes];
	int count = [data length];
	for(int i = 0; i < count; i++)
	{
		if (isalnum(src[i]))
		{
			md[i] = tolower(src[i]);
		}
		else if (src[i] == '.' || src[i] == '_' || /*src[i] == '-' ||*/ src[i] == '@')
		{
			md[i] = src[i];
		}
		else 
		{
			md[i] = 32;
			if (i > 0 && md[i-1] == '.')
				md[i-1] = ' ';
		}
	}
	if (count > 0 && md[count-1] == '.')
		md[count-1] = ' ';
	[mdata setLength:count];
    
	NSString * str = [[NSString alloc] initWithData:mdata encoding:NSASCIIStringEncoding];
	mdata = nil;
    
    return str;
}

@end

#pragma mark -
#pragma mark -
#pragma mark -



@implementation FlatFileTagString

-(id)init
{
    self = [super init];
    if (self)
    {
        _buffer = [[NSMutableString alloc] init];
        _extractedTag = [[NSMutableString alloc] init];
    }
    return self;
}

-(void)appendChar:(char)c
{
    [_buffer appendFormat:@"%c", c];
}

-(void)appendString:(NSString *)str
{
    [_buffer appendString:str];
}

-(NSMutableString *)mutableBuffer
{
    return _buffer;
}

-(void)clear
{
    [_buffer setString:@""];
    [_extractedTag setString:@""];
}

-(NSString *)buffer
{
    return [NSString stringWithString:_buffer];
}

#define MAKEARRAY_STATUS_DEFAULT 0
#define MAKEARRAY_STATUS_START_DECISION 1
#define MAKEARRAY_STATUS_QUOTE_READ 2
#define MAKEARRAY_STATUS_END_QUOTE 3
#define MAKEARRAY_STATUS_READ_TAG  4
-(NSArray *)createArray
{
	//NSString * tempPart = nil;
	NSMutableString * part = [[NSMutableString alloc] initWithCapacity:16];
	NSMutableArray * tagParts = [[NSMutableArray alloc] initWithCapacity:3];
	int brackets = 0;
	int status = MAKEARRAY_STATUS_DEFAULT;
    int nextStatus = MAKEARRAY_STATUS_DEFAULT;
    
	// main import procedure
	for(int idx = 0; idx < [_buffer length]; idx++)
	{
		unichar rd = [_buffer characterAtIndex:idx];
        if (status == MAKEARRAY_STATUS_DEFAULT) {
            if (rd == '<') {
                status = MAKEARRAY_STATUS_START_DECISION;
                nextStatus = MAKEARRAY_STATUS_DEFAULT;
            }
        } else if (status == MAKEARRAY_STATUS_START_DECISION) {
            if (rd == '<') {
                status = nextStatus;
            } else {
                [part appendFormat:@"%c", rd];
                brackets++;
                status = MAKEARRAY_STATUS_READ_TAG;
            }
        } else if (status == MAKEARRAY_STATUS_QUOTE_READ) {
            if (rd == '\"') {
                status = MAKEARRAY_STATUS_END_QUOTE;
            } else {
                [part appendFormat:@"%c", rd];
            }
        } else if (status == MAKEARRAY_STATUS_END_QUOTE) {
            if (rd == '\"') {
                [part appendFormat:@"\""];
                status = MAKEARRAY_STATUS_QUOTE_READ;
            } else {
                [self pushCopy:part toArray:tagParts];
                [part setString:@""];
                idx--;
                status = MAKEARRAY_STATUS_READ_TAG;
                continue;
            }
        } else if (status == MAKEARRAY_STATUS_READ_TAG) {
            if (rd == '<') {
                brackets++;
                [part appendFormat:@"<"];
            } else if (rd == ':' || rd == ' ' || rd == ';' || rd == ',') {
                if ([part length] > 0)
                {
                    //NSLog(@"Part = %@\n", part);
                    [self pushCopy:part toArray:tagParts];
                    [part setString:@""];
                }
                if (rd != ' ')
                {
                    [part setString:@""];
                    [part appendFormat:@"%C", rd];
                    [self pushCopy:part toArray:tagParts];
                    [part setString:@""];
                }
            }
            else if (rd == '>')
            {
                brackets--;
                if (brackets == 0)
                {
                    if ([part length] > 0)
                    {
                        [self pushCopy:part toArray:tagParts];
                        [part setString:@""];
                    }
                    break;
                }
                else 
                {
                    [part appendFormat:@">"];
                }
            }
            else if (rd == '\"')
            {
                if ([part length] > 0)
                {
                    [self pushCopy:part toArray:tagParts];
                    [part setString:@""];
                }
                status = MAKEARRAY_STATUS_QUOTE_READ;
            }
            else {
                [part appendFormat:@"%c", rd];
            }
		}
        
	}
    
    if ([part length] > 0)
    {
        [self pushCopy:part toArray:tagParts];
    }

    return tagParts;
}


-(void)pushCopy:(NSString *)str toArray:(NSMutableArray *)array
{
    [array addObject:[NSString stringWithString:str]];
}

NSCharacterSet * g_flatFileTagString_charSet = nil;

-(NSString *)tag
{
    if ([_extractedTag isEqual:@""])
    {
        if (g_flatFileTagString_charSet == nil)
        {
            g_flatFileTagString_charSet = [NSCharacterSet characterSetWithCharactersInString:@"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz+-/"];
        }
        
        NSCharacterSet * tagSet = g_flatFileTagString_charSet;
        int startIdx = 0;
        if ([_buffer characterAtIndex:0] == '<')
            startIdx++;
        for (int i = startIdx; i < [_buffer length]; i++)
        {
            if ([tagSet characterIsMember:[_buffer characterAtIndex:i]])
                [_extractedTag appendFormat:@"%C", [_buffer characterAtIndex:i]];
            else
                break;
        }
    }
    return _extractedTag;
}


@end

#pragma mark -
#pragma mark -
#pragma mark -

@implementation HtmlString

@synthesize acceptText;

-(id)init
{
    self = [super init];
    if (self) {
        _buffer = [[NSMutableString alloc] init];
        acceptText = NO;
    }
    return self;
}

-(void)clear
{
    [_buffer setString:@""];
    acceptText = NO;
}

-(NSString *)string
{
    return _buffer;
}

-(BOOL)setString:(NSString *)str
{
    if (acceptText)
        [_buffer setString:str];
    return acceptText;
}

-(BOOL)addCharacter:(unichar)chr
{
    if (acceptText) {
        if (chr == '<') {
            [_buffer appendString:@"&gt;"];
        } else if (chr == '>') {
            [_buffer appendString:@"&lt;"];
        } else if (chr == '&') {
            [_buffer appendString:@"&amp;"];
        } else if (chr < 128 ) {
            [_buffer appendFormat:@"%C", chr];
        } else {
            [_buffer appendFormat:@"&#%d;", chr];
        }
    }
    
    return acceptText;
}

-(BOOL)appendString:(NSString *)str
{
    if (acceptText)
        [_buffer appendString:str];
    return acceptText;
}

-(NSInteger)indexfOfFirstOccurenceOfTag:(NSString *)strTag
{
    NSString * adjusted = [NSString stringWithFormat:@"<%@ ", strTag];
    NSRange range = [_buffer rangeOfString:adjusted options:NSCaseInsensitiveSearch];
    if (range.location == NSNotFound)
    {
        adjusted = [NSString stringWithFormat:@"<%@>", strTag];
        range = [_buffer rangeOfString:adjusted options:NSCaseInsensitiveSearch];
    }
    return range.location;
}

-(void)insertString:(NSString *)str atIndex:(NSInteger)pos
{
    [_buffer insertString:str atIndex:pos];
}

@end

#pragma mark -
#pragma mark -
#pragma mark -


BOOL g_FlastFileString_DataLinkAsButton = NO;

@implementation FlatFileString

@synthesize paraStyleRead;
@synthesize validator;
@synthesize dataObjectName, ethStack, ethDict, ethListImage, ethStyle;
@synthesize ethDefaultExpanded;

-(id)init
{
    self = [super init];
    if (self) {
        _buffer = [[NSMutableString alloc] init];
        NSMutableArray * arr = [[NSMutableArray alloc] init];
        self.ethStack = arr;
        NSMutableDictionary * dict = [[NSMutableDictionary alloc] init];
        self.ethDict = dict;
        NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
        self.ethDefaultExpanded = [userDefaults boolForKey:@"text_eth_expanded"];
        [self reset];
    }
    return self;
}

-(void)reset
{
    hcParaStarted = NO;
    hcSpanStarted = NO;
    hcSub = NO;
    hcSup = NO;
    hcSupChanged = NO;
    hcSubChanged = NO;
    hcPwCounter = 0;
    hcNtCounter = 0;
    hcTableRows = 0;
    hcTableColumns = 0;
    catchPwLevel = 0;
    catchPwCounter = 0;
    catchNtCounter = 0;
    linkStarted = NO;
    buttonStarted = NO;
}

+(BOOL)dataLinkAsButton
{
    return g_FlastFileString_DataLinkAsButton;
}

+(void)setDataLinkAsButton:(BOOL)bValue
{
    g_FlastFileString_DataLinkAsButton = bValue;
}


-(NSString *)string
{
    return _buffer;
}

-(void)setString:(NSString *)str
{
    [_buffer setString:str];
}

-(void)setCatchPwCounter:(int)val
{
    catchPwCounter = val;
}

-(void)setCatchPwLevel:(int)val
{
    catchPwLevel = val;
}

-(void)setCatchNtCounter:(int)val
{
    catchNtCounter = val;
}

-(void)checkParagraphStart:(HtmlString *)target paragraphStyle:(HtmlStyle *)paraStyle
{
    if (hcParaStarted == NO) {
        hcParaStarted = YES;
        
        [target appendString:[paraStyle htmlTextForTag:@"p"]];
    }
}

-(void)processChar:(unichar)chr forHtmlTarget:(HtmlString *)target paragraphStyle:(HtmlStyle *)paraStyle characterStyle:(HtmlStyleTracker *)charStyle
{
    [self checkParagraphStart:target paragraphStyle:paraStyle];

    // finishing previous formating tags
    if (hcSubChanged && !hcSub) {
        [target appendString:@"</sub>"];
    }
    if (hcSupChanged && !hcSup) {
        [target appendString:@"</sup>"];
    }
    if ([charStyle hasChanges])
    {
        if (hcSpanStarted) {
            [target appendString:@"</span>"];
            hcSpanStarted = NO;
        }
    }
    
    // starting new formating tags
    if ([charStyle hasChanges])
    {
        NSString * spanText = [charStyle htmlTextForTag:@"span"];
        if (![spanText isEqualToString:@"<span>"]) {
            [target appendString:spanText];
            hcSpanStarted = YES;
        }
        [charStyle clearChanges];
    }
    if (hcSupChanged && hcSup) {
        [target appendString:@"<sup>"];
    }
    if (hcSubChanged && hcSub) {
        [target appendString:@"<sub>"];
    }
    hcSubChanged = NO;
    hcSupChanged = NO;
    [target addCharacter:chr];
}

-(void)finishHtmlFormating:(HtmlString *)target paragraphStyle:(HtmlStyle *)paraStyle characterStyle:(HtmlStyleTracker *)charStyle
{
    if (hcSub) {
        [target appendString:@"</sub>"];
        hcSub = NO;
    }
    if (hcSup) {
        [target appendString:@"</sup>"];
        hcSup = NO;
    }
    if (hcSpanStarted) {
        [target appendString:@"</span>"];
        hcSpanStarted = NO;
    }
    
    [target appendString:@"</p>"];
    hcParaStarted = NO;
}

#pragma mark -

-(NSArray *)sideTextFromAbbr:(NSString *)side
{
	if ([side isEqual:@"AL"]) return [NSArray arrayWithObjects:@"", nil];
	if ([side isEqual:@"LF"]) return [NSArray arrayWithObjects:@"-left", nil ];
	if ([side isEqual:@"RT"]) return [NSArray arrayWithObjects:@"-right", nil ];
	if ([side isEqual:@"BT"]) return [NSArray arrayWithObjects:@"-bottom", nil ];
	if ([side isEqual:@"TP"]) return [NSArray arrayWithObjects:@"-top", nil];
	if ([side isEqual:@"VT"]) return [NSArray arrayWithObjects:@"-top", @"-bottom", nil];
	if ([side isEqual:@"HZ"]) return [NSArray arrayWithObjects:@"-right", @"-left", nil];
	return nil;
}

-(NSString *)inchToPoints:(NSString *)value
{
    if ([value hasSuffix:@"pt"])
        return value;
	NSScanner * scan = [NSScanner scannerWithString:value];
	double d;
	if ([scan scanDouble:&d])
		return [NSString stringWithFormat:@"%dpt", (int)(d * 72.0)];
	return nil;
}

-(NSString *)readColor:(NSArray *)tagArr index:(int *)startIndex 
{
	int vr, vg, vb;
	NSString * str;
	NSString * strColor = @"";
	
	if (*startIndex < [tagArr count]) {
		str = [tagArr objectAtIndex:*startIndex];
		if ([str isEqual:@"DC"] || [str isEqual:@"NO"])
		{
			*startIndex += 1;
			return @"";
		}
		vr = [str intValue];
		*startIndex += 2;
		vg = [(NSString *)[tagArr objectAtIndex:*startIndex] intValue];
		*startIndex += 2;
		vb = [(NSString *)[tagArr objectAtIndex:*startIndex] intValue];
		
		strColor = [NSString stringWithFormat:@"#%02x%02x%02x", vr, vg, vb];
		*startIndex +=2;
		if (*startIndex >= [tagArr count])
			return strColor;
		if ([[tagArr objectAtIndex:*startIndex] isEqual:@"DC"])
		{
			*startIndex += 1;
		}
		else {
			*startIndex -= 1;
		}
	}
	return strColor;
}


-(void)readBorders:(NSArray *)arrTag index:(int *)startIndex target:(HtmlStyle *)obj
{
	NSString * side;
	NSArray  * postfix;
	NSString * value;
	
	NSString * strWidth = nil;
	NSString * strStyle = nil;
	NSString * strColor = nil;
	
	while (*startIndex < [arrTag count]) 
	{
		strWidth = @"0";
		strStyle = @"solid";
		strColor = @"";
		side = [arrTag objectAtIndex:*startIndex];
		if ([side isEqual:@";"])
			return;
		postfix = [self sideTextFromAbbr:side];
		if (postfix == nil) {
			*startIndex -= 1;
			return;
		}
		//NSLog(@"postifx: %@\n", postfix);
		*startIndex += 2;
		strWidth = [self inchToPoints:[arrTag objectAtIndex:*startIndex]];
		//if (value) {
		//strWidth = value;
        //[obj setObject:value forKey:[NSString stringWithFormat:@"border%@-width", postfix]];
        //}
		*startIndex += 2;
		value = [self inchToPoints:[arrTag objectAtIndex:*startIndex]];
		if (value) {
            for (NSString * postfixitem in postfix)
            {
                [obj setValue:value forKey:[NSString stringWithFormat:@"padding%@", postfixitem]];
            }
		}
		*startIndex += 1;
		if (*startIndex >= [arrTag count])
			return;
		*startIndex += 1;
		value = [arrTag objectAtIndex:*startIndex];
		if ([value isEqual:@"FC"]) {
			*startIndex += 2;
			strColor = [self readColor:arrTag index:startIndex];
			*startIndex += 1;
		}
		else {
			strColor = @"";
		}
		//NSString * temp1 = [NSString stringWithFormat:@"%@ %@ %@", strWidth, strStyle, strColor];
		//NSString * temp2 = [NSString stringWithFormat:@"border%@", postfix];
		//NSLog(@"key: (%@) value:(%@)", temp2, temp1);
        for (NSString * item in postfix)
        {
            [obj setValue:[NSString stringWithString:strWidth]
                   forKey:[NSString stringWithFormat:@"border%@-width", item]];
            [obj setValue:[NSString stringWithString:strStyle]
                   forKey:[NSString stringWithFormat:@"border%@-style", item]];
            [obj setValue:[NSString stringWithString:strColor]
                   forKey:[NSString stringWithFormat:@"border%@-color", item]];
        }
	}
}

-(NSString *)alignFromString:(NSString *)str
{
	NSString * a = @"left";
	if ([str isEqual:@"CN"]) a = @"center";
	if ([str isEqual:@"RT"]) a = @"right";
	if ([str isEqual:@"FL"]) a = @"justify";
	if ([str isEqual:@"CA"]) a = @"left";
	return a;
}

-(void)readIndentFormating:(NSArray *)arrTag index:(int *)startIdx target:(HtmlStyle *)obj
{
	NSString * str;
	NSString * paramName = @"margin-left";
	
	str = [self inchToPoints:[arrTag objectAtIndex:*startIdx]];
	if (str == nil) {
		if ([arrTag count] <= *startIdx || [[arrTag objectAtIndex:*startIdx] isEqual:@";"]) {
			return;
		}
		while ([arrTag count] > *startIdx) {
			str = [arrTag objectAtIndex:*startIdx];
			if ([str isEqual:@"LF"]) paramName = @"margin-left";
			else if ([str isEqual:@"RT"]) paramName = @"margin-right";
			else if ([str isEqual:@"FI"]) paramName = @"text-indent";
			else {
				*startIdx -= 1;
				return;
			}
            ;
			*startIdx += 2;
			if ([arrTag count] <= *startIdx || [[arrTag objectAtIndex:*startIdx] isEqual:@";"]) {
				return;
			}
			str = [self inchToPoints:[arrTag objectAtIndex:*startIdx]];
			[obj setValue:str forKey:paramName];
			*startIdx += 1;
			if ([arrTag count] <= *startIdx || [[arrTag objectAtIndex:*startIdx] isEqual:@";"]) {
				return;
			}
			*startIdx += 1;
		}
	} else {
		[obj setValue:str forKey:@"margin-left"];	
		*startIdx += 1;
		if ([arrTag count] <= *startIdx || [[arrTag objectAtIndex:*startIdx] isEqual:@";"]) {
			return;
		}
		*startIdx += 1;
		str = [self inchToPoints:[arrTag objectAtIndex:*startIdx]];
		[obj setValue:str forKey:@"margin-right"];
		*startIdx += 1;
		if ([arrTag count] <= *startIdx || [[arrTag objectAtIndex:*startIdx] isEqual:@";"]) {
			return;
		}
		*startIdx += 1;
		str = [self inchToPoints:[arrTag objectAtIndex:*startIdx]];
		[obj setValue:str forKey:@"text-indent"];
		return;
	}		
    
	return;
}

-(void)readColor:(NSArray *)tagArr withPrefix:(NSString *)prefix index:(int *)startIndex target:(HtmlStyle *)obj
{
	int vr, vg, vb;
	NSString * str;
	
	if (*startIndex < [tagArr count]) {
		str = [tagArr objectAtIndex:*startIndex];
		if ([str isEqual:@"DC"] || [str isEqual:@"NO"])
		{
			*startIndex += 1;
			return;
		}
		vr = [str intValue];
		*startIndex += 2;
		vg = [(NSString *)[tagArr objectAtIndex:*startIndex] intValue];
		*startIndex += 2;
		vb = [(NSString *)[tagArr objectAtIndex:*startIndex] intValue];
		
		[obj setValue:[NSString stringWithFormat:@"#%02x%02x%02x", vr, vg, vb] 
               forKey:prefix];
		*startIndex +=2;
		if (*startIndex >= [tagArr count])
			return;
		if ([[tagArr objectAtIndex:*startIndex] isEqual:@"DC"])
		{
			*startIndex += 1;
		}
		else {
			*startIndex -= 1;
		}
	}
}

//
// converts string to safe form which can be used as name of CSS style
// this function is primary used for conversion of non-uniform names of styles
// in FFF file, into their canonical safe form
// all non-letters are replaced by _{d} string, where {d} is their ASCII code value
//
+(NSString *)stringToSafe:(NSString *)str tag:(NSString *)tag
{
	NSData * s = [str dataUsingEncoding:NSWindowsCP1252StringEncoding];
    NSMutableString * result = [[NSMutableString alloc] initWithCapacity:[s length]];
    
	const unsigned char * bt = [s bytes];
	int len = [s length];
	
    [result appendString:tag];
    [result appendString:@"_"];
    
	for(int i = 0; i < len; i++)
	{
        if (isalpha(bt[i])) {
            [result appendFormat:@"%c", bt[i]];
        } else if (bt[i] == ' ') {
            [result appendString:@"_"];
        } else {
            [result appendFormat:@"_%d", bt[i]];
        }
	}
	
    return result;
}

//
// conversion of number from range 0.0 .. 1.0
// into percentage from range 0% - 100%
// both numbers (input / output) are in the form of NSString-s
//
-(NSString *)percentValue:(NSString *)value
{
	NSScanner * scan = [NSScanner scannerWithString:value];
	double d;
	if ([scan scanDouble:&d])
	{
		if (d > 0.3)
		{
			return [NSString stringWithFormat:@"%d%%", (int)(d*100.0)];
		}
	}
	return nil;
}

-(void)readParaFormating:(NSArray *)arrTag fromIndex:(int)stidx target:(HtmlStyle *)obj
{
	NSString * value = nil;
	
	NSMutableString * str = [[NSMutableString alloc] initWithCapacity:64];
	
	for(int i = stidx; i < [arrTag count]; i++)
	{
		NSString * tag = [arrTag objectAtIndex:i];
		if ([tag isEqual:@"AP"]) {
			value = [self inchToPoints:[arrTag objectAtIndex:(i+2)]];
			[obj setValue:value forKey:@"margin-bottom"];
			i += 2;
		}
		else if ([tag isEqual:@"BP"]) {
			value = [self inchToPoints:[arrTag objectAtIndex:(i+2)]];
			[obj setValue:value forKey:@"margin-top"];
			i += 2;
		}
		else if ([tag isEqual:@"JU"]) {
			value = [self alignFromString:[arrTag objectAtIndex:(i+2)]];
			[obj setValue:value forKey:@"text-align"];
			i+=  2;
		}
		else if ([tag isEqual:@"SD"]) {
			i+= 2;
			[self readColor:arrTag withPrefix:@"background-color" index:&i target:obj];
		}
		else if ([tag isEqual:@"LH"]) {
			value = [self inchToPoints:[arrTag objectAtIndex:(i+2)]];
			[obj setValue:value forKey:@"line-height"];
			i+= 2;
		}
		else if ([tag isEqual:@"LS"]) {
			value = [self percentValue:[arrTag objectAtIndex:(i+2)]];
			[obj setValue:value forKey:@"line-height"];
			i+= 2;
		}
		else if ([tag isEqual:@"IN"]) {
			i+=2;
			[self readIndentFormating:arrTag index:&i target:obj];
		}
		else if ([tag isEqual:@"BR"]) {
			i+=2;
			[self readBorders:arrTag index:&i target:obj];
		}
		else {
			while (i < [arrTag count] && [[arrTag objectAtIndex:i] isEqual:@";"] == NO) {
				i++;
			}
		}
        
	}

}

-(void)finishEtlStarted:(HtmlString *)target
{
    if ([self.ethDict valueForKey:@"ETL_STARTED"]) {
        [target appendString:@"</table>"];
        [self.ethDict setValue:nil forKey:@"ETL_STARTED"];
    }
}

-(NSString *)fullPathStylistImage:(NSString *)file
{
    return [NSString stringWithFormat:@"vbase://stylist_image/%@", file];
}

-(NSString *)getObjectMIMEType:(NSString *)ob_type objectName:(NSString *)ob_name
{
    return @"image/png";
}

#pragma mark -

-(void)processTag:(FlatFileTagString *)tag forHtmlTarget:(HtmlString *)target 
       withStyles:(HtmlStylesCollection *)styles
        paragraphStyle:(HtmlStyle *)paraStyle
        characterStyle:(HtmlStyleTracker *)charStyle
         record:(NSDictionary *)recordDict
         pwLevels:(NSMutableArray *)pwLevel
     pwParaStarts:(NSMutableArray *)pwParaStart 
     pwLinkStyles:(NSMutableArray *)pwLinkStyle
{
    NSArray * tagArr = [tag createArray];
    NSString * str = [tagArr objectAtIndex:0];

    //
    // first processing is for taga, which can influence levels of text
    //
    if ([str isEqual:@"PW"]) {
        hcPwCounter++;
        [pwLevel addObject:[NSNumber numberWithInt:hcPwCounter]];
        [pwParaStart addObject:[NSNumber numberWithBool:hcParaStarted]];
        hcParaStarted = NO;
        [target setAcceptText:(hcPwCounter == catchPwCounter)];
        [pwLinkStyle addObject:([tagArr count] > 2 ? [tagArr objectAtIndex:2] : @"")];
    }
    else if ([str isEqual:@"LT"]) {
        int restCount = 0;
        if ([pwLevel count] > 0)
            [pwLevel removeLastObject];
        if ([pwLevel count] > 0)
            restCount = [(NSNumber *)[pwLevel lastObject] intValue];
        else
            restCount = 0;
        if ([pwParaStart count] > 0) {
            hcParaStarted = [(NSNumber *)[pwParaStart lastObject] boolValue];
            [pwParaStart removeLastObject];
        }
        NSString * classFormat = @"Popup";
        if ([pwLinkStyle count] > 0) {
            classFormat = [pwLinkStyle lastObject];
        }
        [target setAcceptText:(restCount == catchPwCounter)];
        [self checkParagraphStart:target paragraphStyle:paraStyle];

        
        if ([recordDict objectForKey:@"NamedPopup"]) {
            [target appendString:[NSString stringWithFormat:@"<a class=\"LK_%@\" href=\"vbase://inlinepopup/DP/%@/%d\">", classFormat, [FlatFileUtils encodeLinkSafeString:[recordDict valueForKey:@"NamedPopup"]], hcPwCounter]];
            linkStarted = YES;
        }
        else {
            [target appendString:[NSString stringWithFormat:@"<a class=\"LK_%@\" href=\"vbase://inlinepopup/RD/%@/%d\">", classFormat, [recordDict valueForKey:@"record"], hcPwCounter]];
            //NSLog(@"record id = %@", [recordDict valueForKey:@"record"]);
            linkStarted = YES;
        }
        if ([pwLinkStyle count] > 0) {
            [pwLinkStyle removeLastObject];
        }
    }
    else if ([str isEqual:@"NT"]) 
    {
        hcNtCounter++;
        [target setAcceptText:(hcNtCounter == catchNtCounter)];
    }
    else if ([str isEqual:@"/NT"])
    {
        hcNtCounter--;
        [target setAcceptText:(hcNtCounter == catchNtCounter)];
    }

    //
    // if text is not accepted, then also tags are rejected to write
    //
    if ( ! [target acceptText])
    {
        return;
    }

    if ([str isEqualToString:@"ETH"]) {
        [self finishHtmlFormating:target paragraphStyle:paraStyle characterStyle:charStyle];
        [paraStyle clear];
        [charStyle clearChanges];
        NSString * ethArg = nil;
        [self.ethStack addObject:[NSDictionary dictionaryWithDictionary:self.ethDict]];
        ethArg = ([tagArr count] >= 3) ? [tagArr objectAtIndex:2] : @"cont_book_open";
        [self.ethDict setValue:ethArg forKey:@"A"];
        ethArg = ([tagArr count] >= 5) ? [tagArr objectAtIndex:4] : @"cont_book_closed";
        [self.ethDict setValue:ethArg forKey:@"B"];
        gEthCounter++;
        [self.ethDict setValue:[NSString stringWithFormat:@"ethimg%d", gEthCounter] forKey:@"C"];
        [self.ethDict setValue:[NSString stringWithFormat:@"eth_%d", gEthCounter] forKey:@"D"];
        [target appendString:@"<table style='font-family:Helvetica;font-size:14pt;text-align:left'>"];
        [target appendString:[NSString stringWithFormat:@"<tr><td><img id='%@' src='vbase://stylist_images/%@' style='cursor:pointer;' onclick=\"eth_show_hide('%@');eth_expand('%@', '%@', '%@');\"></td><td>", [self.ethDict valueForKey:@"C"], [self.ethDict valueForKey:(ethDefaultExpanded ? @"A" : @"B")], [self.ethDict valueForKey:@"D"], [self.ethDict valueForKey:@"C"], [self.ethDict valueForKey:@"A"], [self.ethDict valueForKey:@"B"]]];
        
    } else if ([str isEqualToString:@"ETB"]) {
        [self finishHtmlFormating:target paragraphStyle:paraStyle characterStyle:charStyle];
        [self finishEtlStarted:target];
        [target appendString:[NSString stringWithFormat:@"</td></tr><tr><td></td><td id='%@' style='display:%@;'>", [self.ethDict valueForKey:@"D"], (ethDefaultExpanded ? @"block" : @"none")]];
    } else if ([str isEqualToString:@"/ETH"]) {
        [self finishHtmlFormating:target paragraphStyle:paraStyle characterStyle:charStyle];
        [paraStyle clear];
        [charStyle clearChanges];
        [self finishEtlStarted:target];
        [self.ethDict removeAllObjects];
        if ([self.ethStack count] > 0) {
            [self.ethDict setValuesForKeysWithDictionary:[self.ethStack lastObject]];
            [self.ethStack removeLastObject];
        }
        [target appendString:@"</td></tr></table>"];
        self.ethStyle = @"";
        
    } else if ([str isEqualToString:@"ETL"]) {
        [self finishHtmlFormating:target paragraphStyle:paraStyle characterStyle:charStyle];
        [paraStyle clear];
        [charStyle clearChanges];
        self.ethListImage = ([tagArr count] >= 3) ? [tagArr objectAtIndex:2] : @"cont_text";
        if ([self.ethDict valueForKey:@"ETL_STARTED"]) {
            [target appendString:@"</td></tr>"];
        } else {
            [target appendString:@"<table style='font-size:14pt;' cellpadding=4>"];
        }
        [target appendString:@"<tr>"];
        [target appendString:[NSString stringWithFormat:@"<td width=20 valign=top><img src='vbase://stylist_images/%@'></td><td>", self.ethListImage]];
        [self.ethDict setValue:@"1" forKey:@"ETL_STARTED"];
    } else if ([str isEqualToString:@"ETX"]) {
        [self finishHtmlFormating:target paragraphStyle:paraStyle characterStyle:charStyle];
        [paraStyle clear];
        [charStyle clearChanges];
        if ([self.ethDict valueForKey:@"ETL_STARTED"]) {
            [target appendString:@"</td></tr>"];
        } else {
            [target appendString:@"<table style='font-size:14pt;'>"];
        }
        [target appendString:@"<tr>"];
        [target appendString:@"<td valign=top colspan=2>"];
        [self.ethDict setValue:@"1" forKey:@"ETL_STARTED"];
    } else if ([str isEqualToString:@"/ETL"]) {
        [self finishHtmlFormating:target paragraphStyle:paraStyle characterStyle:charStyle];
        [paraStyle clear];
        [charStyle clearChanges];
        [self finishEtlStarted:target];
    } else if ([str isEqualToString:@"ETS"]) {
        if ([tagArr count] >= 3) {
            self.ethStyle = [tagArr objectAtIndex:2];
        } else {
            self.ethStyle = @"";
        }
    }
    
    // extended para styles
    if ([str isEqual:@"PS"]) {
        NSString * safeString = [FlatFileString stringToSafe:[tagArr objectAtIndex:2] tag:@"PA"];
        [paraStyle setStyleName:safeString];
    }
    else if ([str isEqual:@"LV"])
    {
        NSString * safeString = [FlatFileString stringToSafe:[tagArr objectAtIndex:2] tag:@"LE"];
        [paraStyle setStyleName:safeString];
    }
    
    // reading paragraph styles
    if ([str isEqual:@"AP"]) {
        [paraStyle setValue:[NSString stringWithFormat:@"%@in", [tagArr objectAtIndex:2]]
                     forKey:@"margin-bottom"];
    }
    else if ([str isEqual:@"BP"]) {
        [paraStyle setValue:[NSString stringWithFormat:@"%@in", [tagArr objectAtIndex:2]]
                     forKey:@"margin-top"];
    }
    else if ([str isEqual:@"BR"]) {
        int index = 2;
        [self readBorders:tagArr index:&index target:paraStyle];
    }
    else if ([str isEqual:@"JU"]) {
        [paraStyle setValue:[self alignFromString:[tagArr objectAtIndex:2]]
                     forKey:@"text-align"]; 
    }
    else if ([str isEqual:@"LH"]) {
        double v = [[tagArr objectAtIndex:2] doubleValue];
        [paraStyle setValue:[NSString stringWithFormat:@":%f%%", v*100.0 ]
                     forKey:@"line-height"];
    }
    else if ([str isEqual:@"IN"]) {
        int index2 = 2;
        [self readIndentFormating:tagArr index:&index2 target:paraStyle];
    }
    else if ([str isEqual:@"SD"]) {
        if ([tagArr count] == 1 || [[tagArr objectAtIndex:2] isEqual:@"NO"])
        {
            [paraStyle setValue:nil forKey:@"background-color-x"];
        }
        else {
            int i = 2;
            [self readColor:tagArr withPrefix:@"background-color-x" index:&i target:paraStyle];
        }
    }
    else if ([str isEqual:@"TS"]) { 
    }

    
    
    
    
    if ([str isEqual:@"BC"]) {
        if ([tagArr count] == 1 || [[tagArr objectAtIndex:2] isEqual:@"DC"])
        {
            [charStyle setValue:nil forKey:@"background-color-x"];
        }
        else {
            int i = 2;
            [self readColor:tagArr withPrefix:@"background-color-x" index:&i target:charStyle];
        }
    }
    else if ([str isEqual:@"BD-"]) {
        [charStyle setValue:@"normal" forKey:@"font-weight"];
    }
    else if ([str isEqual:@"BD"]) {
        [charStyle setValue:nil forKey:@"font-weight"];
    }
    else if ([str isEqual:@"BD+"]) {
        [charStyle setValue:@"bold" forKey:@"font-weight"];
    }
    else if ([str isEqual:@"UN-"]) {
        [charStyle setValue:@"none" forKey:@"text-decoration"];
    }
    else if ([str isEqual:@"UN"]) {
        [charStyle setValue:nil forKey:@"text-decoration"];
    }
    else if ([str isEqual:@"UN+"]) {
        [charStyle setValue:@"underline" forKey:@"text-decoration"];
    }
    else if ([str isEqual:@"SO-"]) {
        [charStyle setValue:@"none" forKey:@"text-decoration"];
    }
    else if ([str isEqual:@"SO"]) {
        [charStyle setValue:nil forKey:@"text-decoration"];
    }
    else if ([str isEqual:@"SO+"]) {
        [charStyle setValue:@"line-through" forKey:@"text-decoration"];
    }
    else if ([str isEqual:@"HD-"]) {
        [charStyle setValue:@"visible" forKey:@"visibility"];
    }
    else if ([str isEqual:@"HD"]) {
        [charStyle setValue:nil forKey:@"visibility"];
    }
    else if ([str isEqual:@"HD+"]) {
        [charStyle setValue:@"hidden" forKey:@"visibility"];
    }
    else if ([str isEqual:@"CS"]) {
        [charStyle setStyleName:[FlatFileString stringToSafe:[tagArr objectAtIndex:2] tag:@"CS"]];
    }
    else if ([str isEqual:@"/CS"]) {
        [charStyle setStyleName:@""];
    }
    else if ([str isEqual:@"FC"]) {
        if ([tagArr count] == 1 || [[tagArr objectAtIndex:2] isEqual:@"DC"])
        {
            [charStyle setValue:nil forKey:@"color"];
        }
        else {
            int i = 2;
            [self readColor:tagArr withPrefix:@"color" index:&i target:charStyle];
        }
    }
    else if ([str isEqual:@"FT"]) {
        if ([tagArr count] == 1)
        {
            [charStyle setValue:nil forKey:@"font-family"];
        }
        else {
            NSString * fontName = [tagArr objectAtIndex:2];
            [charStyle setValue:[styles substitutionFontName:fontName] forKey:@"font-family"];
        }
    }
    else if ([str isEqual:@"IT-"]) {
        [charStyle setValue:@"normal" forKey:@"font-style"];
    }
    else if ([str isEqual:@"IT"]) {
        [charStyle setValue:nil forKey:@"font-style"];
    }
    else if ([str isEqual:@"IT+"]) {
        [charStyle setValue:@"italic" forKey:@"font-style"];
    }
    else if ([str isEqual:@"PN"]) {
        [charStyle setStyleName:[FlatFileString stringToSafe:[tagArr objectAtIndex:2] tag:@"PD"]];
    }
    else if ([str isEqual:@"/PN"]) {
        [charStyle setStyleName:@""];
    }
    else if ([str isEqual:@"PT"])  {
        if ([tagArr count] == 1)
        {
            [charStyle setValue:nil forKey:@"font-size"];
        }
        else {
            NSString * ptSizeDescr = [tagArr objectAtIndex:2];
            if ([ptSizeDescr hasSuffix:@"pt"])
                ptSizeDescr = [ptSizeDescr substringToIndex:([ptSizeDescr length] - 2)];
            if ([ptSizeDescr isEqualToString:@"14"] == NO)
            {
                [charStyle setValue:[NSString stringWithFormat:@"%d%%", [ptSizeDescr intValue]*100/14]
                             forKey:@"font-size"];
                if ([charStyle valueForKey:@"line-height"] == nil)
                {
                    [charStyle setValue:@"120%" forKey:@"line-height"];
                }
            }
        }
    }
    else if ([str isEqual:@"SP"]) {
        hcSup = YES;
        hcSupChanged = YES;
    }
    else if ([str isEqual:@"SB"]) {
        hcSub = YES;
        hcSubChanged = YES;
    }
    else if ([str isEqual:@"/SS"]) {
        if (hcSub) {
            hcSub = NO;
            hcSubChanged = YES;
        }
        if (hcSup) {
            hcSup = NO;
            hcSupChanged = YES;
        }
    }
    
    //
    // tag for controlling
    //
    
    if ([str isEqual:@"CR"]) {
        [target appendString:@"<br>"];
    }
    else if ([str isEqual:@"HR"]) {
        hcParaStarted = NO;
    }
    else if ([str isEqual:@"HS"]) {
        [target appendString:@"&nbsp;"];
    }
    else if ([str isEqual:@"OB"]) {
        NSString * ob_type = [tagArr objectAtIndex:2];
        NSString * ob_name = [tagArr objectAtIndex:4];
        NSString * ob_width = nil;
        NSString * ob_height = nil;
        if ([tagArr count] > 6)
            ob_width = [tagArr objectAtIndex:6];
        if ([tagArr count] > 8)
            ob_height = [tagArr objectAtIndex:8];
        //NSMutableDictionary * form = [[NSMutableDictionary alloc] initWithCapacity:10];
        NSMutableString * s = [[NSMutableString alloc] initWithCapacity:100];
        NSString * objectExtension = [[ob_name pathExtension] lowercaseString];
        NSSet * imageExtensions = [NSSet setWithObjects:@"png", @"tif", @"tiff", @"jpg", @"gif", @"bmp", nil];
        [self checkParagraphStart:target paragraphStyle:paraStyle];
        if ([imageExtensions containsObject:objectExtension])
        {
            [s appendFormat:@"<img src=\"vbase://objects/%@\"", ob_name];
            if (ob_width != nil && ob_height != nil)
            {
                [s appendFormat:@" width=%@ height=%@",
                 [self inchToPoints:ob_width],
                 [self inchToPoints:ob_height]];
            }
            [s appendString:@">"];
        } else {
            [s appendFormat:@"<object data=\"vbase://objects/%@\"", ob_name];
            if (ob_type != nil)
            {
                [s appendFormat:@" type=\"%@\"", [self getObjectMIMEType:ob_type objectName:ob_name]];
            }
            if (ob_width != nil && ob_height != nil)
            {
                [s appendFormat:@" width=%@ height=%@",
                 [self inchToPoints:ob_width],
                 [self inchToPoints:ob_height]];
            }

            [s appendFormat:@"></object>"];
        }
        [target appendString:s];

        return;
    }
    else if ([str isEqual:@"QL"] || [str isEqual:@"EN"]) {
        NSString * query = [tagArr objectAtIndex:4];
        [target appendString:[NSString stringWithFormat:@"<a class=\"%@\" href=\"vbase://links/%@/%@\">",
                              [FlatFileString stringToSafe:[tagArr objectAtIndex:2] tag:@"LK"], 
                              str,
                              [FlatFileUtils encodeLinkSafeString:query]]];
        linkStarted = YES;
        //NSLog(@"ORIGINAL QUERY: %@\nNEW QUERY: %@\n-------------------", query, [FlatFileUtils encodeLinkSafeString:query]);
    }
    else if ([str isEqual:@"PX"]) {
        [self checkParagraphStart:target paragraphStyle:paraStyle];
        [target appendString:[NSString stringWithFormat:@"<a class=\"%@\" href=\"vbase://popup/%@\">",
                              [FlatFileString stringToSafe:[tagArr objectAtIndex:2] tag:@"LK"], 
                              [FlatFileUtils encodeLinkSafeString:[tagArr objectAtIndex:4]]]];
        linkStarted = YES;
    }
    else if ([str isEqual:@"DL"] || [str isEqual:@"ML"] || [str isEqual:@"PL"])
    {
        [self checkParagraphStart:target paragraphStyle:paraStyle];
        self.dataObjectName = [tagArr objectAtIndex:4];
        if ([FlatFileString dataLinkAsButton])
        {
            [target appendString:[NSString stringWithFormat:@"<input style=\"font-size:100%%\" type=\"button\" name=\"b1\" onclick=\"location.href='vbase://links/%@/%@'\" value=\"", str, [FlatFileUtils encodeLinkSafeString:self.dataObjectName]]];
            buttonStarted = YES;
        }
        else
        {
            [target appendString:[NSString stringWithFormat:@"<a class=\"%@\" style=\"font-size:0pt;\" href=\"vbase://links/%@/%@\"><img src=\"vbase://stylist_images/speaker\" width=40 height=40 border=0>",
                                  [FlatFileString stringToSafe:[tagArr objectAtIndex:2] tag:@"LK"],
                                  str,
                                  [FlatFileUtils encodeLinkSafeString:self.dataObjectName]]];
            linkStarted = YES;
        }
    }
    else if ([str isEqual:@"WW"])
    {
        [self checkParagraphStart:target paragraphStyle:paraStyle];
        [target appendString:[NSString stringWithFormat:@"<a class=\"%@\" href=\"%@\">",
                              [FlatFileString stringToSafe:[tagArr objectAtIndex:2] tag:@"LK"],
                              [tagArr objectAtIndex:4]]];
        linkStarted = YES;
    }
    else if ([str isEqual:@"/DL"] || [str isEqual:@"/ML"] || [str isEqual:@"EL"]
             || [str isEqual:@"/EN"] || [str isEqual:@"/JL"]
             || [str isEqual:@"/PX"] || [str isEqual:@"/OL"] || [str isEqual:@"/PL"] || [str isEqual:@"/QL"]
             || [str isEqual:@"/PW"] || [str isEqual:@"/WW"]) 
    {
        if (linkStarted) {
            [target appendString:@"</a>"];
            linkStarted = NO;
        } else if (buttonStarted) {
            [target appendString:@"\">"];
            buttonStarted = NO;
        }
    }
    else if ([str isEqual:@"JL"]) {
        if ([tagArr count] > 4)
        {
            NSString * s2 = [tagArr objectAtIndex:4];
            if (s2 != nil)
            {
                if ([self.validator jumpExists:s2]) {
                    [target appendString:@"<a href=\"vbase://links/JL/"];
                    [target appendString:[FlatFileUtils encodeLinkSafeString:s2]];
                    [target appendString:@"\">"];
                    linkStarted = YES;
                } else {
                    [charStyle setValue:@"#909090" forKey:@"color"];
                }
            }
        }
    }
    else if ([str isEqual:@"RO"])
    {
        [self finishHtmlFormating:target paragraphStyle:paraStyle characterStyle:charStyle];
        [target appendString:@"<tr>"];
        hcTableRows++;
        hcTableColumns=0;
    }
    else if ([str isEqual:@"TB"]) {
        [target appendString:@"  &nbsp;&nbsp;&nbsp; "];
    }
    else if ([str isEqual:@"TA"]) {
        [self finishHtmlFormating:target paragraphStyle:paraStyle characterStyle:charStyle];
        NSMutableString * tableTag = [[NSMutableString alloc] initWithCapacity:10];
        [tableTag setString:@"<table"];
        if ([tagArr count] > 2)
        {
            HtmlStyle * dict = [[HtmlStyle alloc] init];
            int counts = [(NSString *)[tagArr objectAtIndex:2] intValue];
            if (counts > 0)
            {
                [self readParaFormating:tagArr fromIndex:(4+counts*2) target:dict];
            }
            else 
            {
                [self readParaFormating:tagArr fromIndex:2 target:dict];
            }
            [tableTag appendFormat:@" style='"];
            [tableTag appendString:[dict styleCssText]];
            [tableTag appendFormat:@"'>"];

        }
        else {
            [tableTag appendFormat:@">"];
        }

        [target appendString:tableTag];
        hcTableRows = 0;
        hcTableColumns = 0;
    }
    else if ([str isEqual:@"CE"])
    {
        hcTableColumns++;
        [target appendString:@"<td>"];
    }
    else if ([str isEqual:@"/CE"]) {
        [target appendString:@"</td>"];
    }
    else if ([str isEqual:@"/TA"])
    {
        [target appendString:@"</table>"];
    }
    
}

+(NSString *)removeTags:(NSString *)str
{
    if (str == nil)
        return nil;
    
    NSMutableString * text = [[NSMutableString alloc] initWithString:str];
    
    int start = 0;
    int end = 0;
    int status = 0;
    int removeRange = 0;
    int removedCount = 1;
    
    NSSet * spaceTags = [NSSet setWithObjects:@"<CR>", @"<HR>", @"<HS>", @"<SP>",
                         @"<SB>", @"</SS>", @"<TA>", @"</TA>", @"<CE>",
                         @"</CE>", @"<GP>", @"<GD>", @"<GM>", @"<GT>",
                         @"<GQ>", @"<GI>", @"<GA>", @"<GF>", nil];
    
    while (removedCount > 0) {
        removedCount = 0;
        for(int i = 0; (removedCount == 0) && (i < [text length]); i++)
        {
            if (status == 0) {
                if ([text characterAtIndex:i] == '<') {
                    status = 1;
                }
            } else if (status == 1) {
                if ([text characterAtIndex:i] == '<') {
                    status = 0;
                } else {
                    start = i-1;
                    status = 2;
                }
            } else if (status == 2) {
                if ([text characterAtIndex:i] == '>') {
                    end = i;
                    removeRange = 1;
                    status = 0;
                } else if ([text characterAtIndex:i] == '"') {
                    status = 3;
                }
            } else if (status == 3) {
                if ([text characterAtIndex:i] == '"') {
                    status = 4;
                }
            } else if (status == 4) {
                if ([text characterAtIndex:i] == '"') {
                    status = 3;
                } else if ([text characterAtIndex:i] == '>') {
                    end = i;
                    removeRange = 1;
                    status = 0;
                }
            }
            
            if (removeRange == 1) {
                NSRange foundRange = NSMakeRange(start, end - start + 1);
                NSString * extractedTag = [text substringWithRange:foundRange];
                if ([spaceTags containsObject:extractedTag])
                    [text replaceCharactersInRange:foundRange withString:@" "];
                else
                    [text replaceCharactersInRange:foundRange withString:@""];
                removeRange = 0;
                removedCount++;
            }
        }
    }
    
    return text;
}



@end

#pragma mark -
#pragma mark -
#pragma mark -

@implementation HtmlStyle


-(id)init
{
    self = [super init];
    if (self)
    {
        format = [[NSMutableDictionary alloc] init];
        styleNameChanged = NO;
    }
    return self;
}

-(NSString *)styleName
{
    return styleName;
}

-(void)setStyleName:(NSString *)aStyleName
{
    styleName = aStyleName;
    styleNameChanged = YES;
}

-(BOOL)styleNameChanged
{
    return styleNameChanged;
}

-(NSMutableDictionary *)format
{
    return format;
}

-(NSString *)valueForKey:(NSString *)str
{
    return [format valueForKey:str];
}

-(void)setValue:(NSString *)strValue forKey:(NSString *)strKey
{
    [format setValue:strValue forKey:strKey];
}

-(void)clearFormat
{
    [format removeAllObjects];
}

-(void)clear
{
    [self clearFormat];
    self.styleName = nil;
    styleNameChanged = NO;
}

-(NSString *)htmlTextForTag:(NSString *)tag
{
    NSMutableString * target = [[NSMutableString alloc] init];
    [target appendString:@"<"];
    [target appendString:tag];
    if ([self styleName] != nil && [[self styleName] length] > 0) {
        [target appendString:@" class=\""];
        [target appendString:[self styleName]];
        [target appendString:@"\""];
    }
    
    if ([[self format] count] > 0) {
        [target appendString:@" style=\""];
        [target appendString:[self styleCssText]];
        [target appendString:@"\""];
    }
    [target appendString:@">"];
    return target;
}

-(NSString *)styleCssText
{
    NSCharacterSet * whites = [NSCharacterSet whitespaceCharacterSet];
    NSString * key;
    NSMutableString * str = [[NSMutableString alloc] init];
    NSEnumerator * enm = [format keyEnumerator];
    while((key = [enm nextObject]) != nil)
    {
        if ([str length] > 0) {
            [str appendString:@";"];
        }

        NSString * val = [format valueForKey:key];
        NSRange rangeWhite = [val rangeOfCharacterFromSet:whites];
        if (rangeWhite.location == NSNotFound)
            [str appendFormat:@"%@:%@", key, val];
        else {
            [str appendFormat:@"%@:'%@'", key, val];
        }
    }
    
    return str;
}

@end

#pragma mark -
#pragma mark -
#pragma mark -

@implementation HtmlStyleTracker


-(id)init
{
    self = [super init];
    if (self)
    {
        formatOld = [[NSMutableDictionary alloc] init];
        formatChanges = [[NSMutableSet alloc]  init];
    }
    return self;
}

-(void)setValue:(NSString *)strValue forKey:(NSString *)strKey
{
    [super setValue:strValue forKey:strKey];
    [formatChanges addObject:strKey];
}

-(NSMutableSet *)formatChanges
{
    return formatChanges;
}

-(void)clearChanges
{
    styleNameChanged = NO;
    [formatChanges removeAllObjects];
    [formatOld removeAllObjects];
    [formatOld setDictionary:format];
}

-(void)clearFormat
{
    [super clearFormat];
    [formatOld removeAllObjects];
}

-(BOOL)hasChanges
{
    return [self styleNameChanged] || ([formatChanges count] > 0);
}

@end

#pragma mark -
#pragma mark -
#pragma mark -

@implementation HtmlStylesCollection

-(id)init
{
    self = [super init];
    if (self)
    {
        _styles = [[NSMutableArray alloc] init];
    }
    return self;
}

-(void)addStyle:(HtmlStyle *)style
{
    [_styles addObject:style];
}

-(NSString *)substitutionFontName:(NSString *)fname
{
	if ([fname isEqual:@"Sanskrit-Helvetica"])
		return @"Helvetica";
	if ([fname hasPrefix:@"Sanskrit-"])
		return @"Times";
	
	// this is when converting to Unicode Vedabase
	if ([fname isEqual:@"ScaHelvetica"] || [fname isEqual:@"ScaOptima"])
		return @"Helvetica";
	if ([fname hasPrefix:@"Sca"])
		return @"Times";
	if ([fname isEqual:@"Balaram"] || [fname isEqual:@"Dravida"])
		return @"Times";
	if ([fname isEqual:@"scagoudy"])
		return @"Times";
	// end convertion to Unicode Vedabase
	
	return fname;
}

-(NSString *)getMIMEType:(NSString *)str
{
	if ([str isEqual:@"mp3file"])
		return @"audio/mpeg";
	if ([str isEqual:@"AcroExch.Document"])
		return @"application/pdf";
	
	return str;
}


@end

#pragma mark -
#pragma mark -
#pragma mark -

@implementation GPMutableInteger
    
@synthesize value;

-(id)init
{
    self = [super init];
    if (self) {
        value = 0;
    }
    return self;
}

-(NSInteger)intValue
{
    return self.value;
}

-(void)increment
{
    value++;
}

-(void)decrement
{
    value--;
}

@end

#pragma mark -
#pragma mark -
#pragma mark -

@implementation FlatFileStringIndexer

@synthesize text;
@synthesize delegate;


-(id)init
{
    self = [super init];
    if (self) {
        properties = [[NSMutableDictionary alloc] init];
    }
    return self;
}

-(id)objectForKey:(NSString *)key
{
    return [properties objectForKey:key];
}

-(void)setObject:(id)property forKey:(NSString *)key
{
    [properties setObject:property forKey:key];
}

-(void)removeTrailingNonAlphanumeric:(NSMutableString *)word
{
    NSCharacterSet * chs = [NSCharacterSet alphanumericCharacterSet];
    
    NSInteger top = [word length];
    NSInteger index = [word length] - 1;
    for(NSInteger i = index; i >= 0; i--)
    {
        if (![chs characterIsMember:[word characterAtIndex:i]])
        {
            top--;
        }
        else
        {
            break;
        }
    }
    
    if (top != [word length])
    {
        [word setString:[word substringToIndex:index]];
    }
}

-(void)tryProcess:(NSMutableString *)word
{
    if ([word length] > 1) {
        [delegate pushWord:word fromIndexer:self];
        [word setString:@""];
    }
}

-(void)parse
{
    int status = 0;
    int start = 0;
    int end = 0;
    int tagIdentified = 0;
    
    NSData * data = [self.text dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    int length = [data length];
    const char * bytes = [data bytes];
    NSString * strNew = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    NSMutableString * word = [[NSMutableString alloc] init];
    FlatFileTagString * tag = [[FlatFileTagString alloc] init];
    int contains = 0; // 0 - none, 1 - alpha, 2 - num, 3 - alphanum, 4-minus,plus
    
    for(int i = 0; i < length; i++)
    {
        if (status == 0) {
            if (bytes[i] == '<') {
                status = 1;
            }
        } else if (status == 1) {
            if (bytes[i] == '<') {
                status = 0;
            } else {
                start = i-1;
                status = 2;
            }
        } else if (status == 2) {
            if (bytes[i] == '>') {
                end = i;
                tagIdentified = 1;
                status = 0;
            } else if (bytes[i] == '"') {
                status = 3;
            }
        } else if (status == 3) {
            if (bytes[i] == '"') {
                status = 4;
            }
        } else if (status == 4) {
            if (bytes[i] == '"') {
                status = 3;
            } else if (bytes[i] == '>') {
                end = i;
                tagIdentified = 1;
                status = 0;
            }
        }    
        
        if (tagIdentified == 1) {
            tagIdentified = 0;
            [tag clear];
            @try {
                NSString * subTag = [strNew substringWithRange:NSMakeRange(start, end - start + 1)];
                //NSLog(@"indexer tag->%@  ->%d-%d", subTag, start, end);
                [tag appendString:subTag];
            }
            @catch (NSException *exception) {
                NSLog(@"Invalid range: %d, %d in string %@", start, end - start + 1, strNew);
            }
            @finally {
            }
            [self tryProcess:word];
            contains = 0;
            [delegate pushTag:tag fromIndexer:self];
        } else if (status == 0) {
            char rc = bytes[i];
            if (contains == 0)
            {
                if (rc == '-' || rc=='+') {
                    [word appendFormat:@"%c", rc];
                    contains = 4;
                } else if (isdigit(rc)) {
                    [word appendFormat:@"%c", rc];
                    contains = 2;
                } else if (isalpha(rc)) {
                    [word appendFormat:@"%c", tolower(rc)];
                    contains = 1;
                }
            } else if (contains == 1 || contains == 3) {
                if (isdigit(rc) || rc=='.') {
                    [word appendFormat:@"%c", rc];
                    contains = 3;
                } else if (isalpha(rc) || rc=='\'') {
                    [word appendFormat:@"%c", tolower(rc)];
                } else {
                    [self removeTrailingNonAlphanumeric:word];
                    [self tryProcess:word];
                    contains = 0;
                }
            } else if (contains == 2) {
                if (rc == '.' || rc == ',') {
                    [word appendFormat:@"%c", rc];
                } else if (isalpha(rc)) {
                    [word appendFormat:@"%c", tolower(rc)];
                    contains = 3;
                } else if (isdigit(rc)) {
                    [word appendFormat:@"%c", rc];
                } else {
                    [self tryProcess:word];
                }
            } else if (contains == 4) {
                if (isdigit(rc)) {
                    [word appendFormat:@"%c", rc];
                    contains = 2;
                } else {
                    [word setString:@""];
                    contains = 0;
                }
            } else {
                [self tryProcess:word];
                contains = 0;
            }
        }
    }
    
    [self tryProcess:word];
    
    [delegate pushEndfromIndexer:self];
}

@end















