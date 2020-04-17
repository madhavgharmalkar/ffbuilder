//
//  GPTagHelper.m
//  Builder
//
//  Created by Peter Kollath on 10/15/10.
//  Copyright 2010 GPSL. All rights reserved.
//

#import "GPTagHelper.h"



@implementation GPTagHelper


//
// returns in startIndex such value
// that is assumes, that after incrementing with value 1
// index will point at next TAG
//
+(void)readColor:(NSArray *)tagArr withPrefix:(NSString *)prefix index:(int *)startIndex target:(NSMutableDictionary *)obj
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
		vg = [[tagArr objectAtIndex:*startIndex] intValue];
		*startIndex += 2;
		vb = [[tagArr objectAtIndex:*startIndex] intValue];
		
		[obj setObject:[NSString stringWithFormat:@"#%02x%02x%02x", vr, vg, vb] forKey:prefix];
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

+(NSString *)readColor:(NSArray *)tagArr index:(int *)startIndex 
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
		vg = [[tagArr objectAtIndex:*startIndex] intValue];
		*startIndex += 2;
		vb = [[tagArr objectAtIndex:*startIndex] intValue];
		
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

+(NSArray *)sideTextFromAbbr:(NSString *)side
{
	if ([side isEqual:@"AL"]) return [NSArray arrayWithObjects:@"", nil];
	if ([side isEqual:@"LF"]) return [NSArray arrayWithObjects:@"-left", nil ];
	if ([side isEqual:@"RT"]) return [NSArray arrayWithObjects:@"-right", nil ];
	if ([side isEqual:@"BT"]) return [NSArray arrayWithObjects:@"-bottom", nil ];
	if ([side isEqual:@"TP"]) return [NSArray arrayWithObjects:@"-top", nil];
	if ([side isEqual:@"HZ"]) return [NSArray arrayWithObjects:@"-top", @"-bottom", nil];
	if ([side isEqual:@"VT"]) return [NSArray arrayWithObjects:@"-right", @"-left", nil];
	return nil;
}

+(NSString *)inchToPoints:(NSString *)value
{
    if ([value hasSuffix:@"pt"])
        return value;
	NSScanner * scan = [NSScanner scannerWithString:value];
	double d;
	if ([scan scanDouble:&d])
		return [NSString stringWithFormat:@"%dpt", (int)(d * 72.0)];
	return nil;
}
			  
+(NSString *)percentValue:(NSString *)value
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

+(NSString *)readBorderFormating:(NSDictionary *)dict 
							 withPrefix:(NSString *)prefix 
								forSide:(NSString *)side
								 target:(NSMutableDictionary *)obj
{
	NSMutableString * str = [[NSMutableString alloc] initWithCapacity:32];
	NSMutableString * res = nil;
	NSString * key = nil;
	NSString * key2 = nil;
	NSString * val2 = nil;
	
	id value;
	
	[str setString:@""];
	if (prefix) { [str appendFormat:@"%@_",prefix]; }
	[str appendFormat:@"BR_%@_WIDTH",side];
	
	value = [dict objectForKey:str];
	//NSLog(@"value = %@\n", value);
	if (value) {
		res = [NSMutableString stringWithCapacity:32];
		//[str setString:@"border"];
		//[str appendFormat:@"%@",[GPTagHelper sideTextFromAbbr:side]];
		//[str appendFormat:@"-width"];
		val2 = [GPTagHelper inchToPoints:value];
        NSArray * sides = [GPTagHelper sideTextFromAbbr:side];
        for(NSString * sideitem in sides)
        {
            key = [NSString stringWithFormat:@"border%@-width", sideitem];
            key2 = [NSString stringWithFormat:@"border%@-style", sideitem];
            if (obj)
            {
                [obj setValue:val2 forKey:key];
                [obj setValue:@"solid" forKey:key2];
            }
            if (res)
            {
                [res appendFormat:@"%@:%@;\n", key, val2];
                [res appendFormat:@"%@:solid;\n", key2];
            }
        }
		
		
		[str setString:@""];
		if (prefix) { [str appendFormat:@"%@_",prefix]; }
		[str appendFormat:@"BR_%@_INSIDE",side];
		value = [dict objectForKey:str];
		if (value) {
			val2 = [GPTagHelper inchToPoints:value];
            for(NSString * sideitem in sides)
            {
                key = [NSString stringWithFormat:@"padding%@",sideitem];
                if (obj)
                    [obj setValue:val2 forKey:key];
                if (res)
                    [res appendFormat:@"%@:%@;\n", key, val2];
            }
		}

		[str setString:@""];
		if (prefix)
			[str appendFormat:@"%@_BR_FC_%@",prefix,side];
		else
			[str appendFormat:@"BR_FC_%@",side];
		//int i = 0;
		//value = [GPTagHelper readColor:dict withPrefix:str index:&i target:obj];
		if (value) {
            for(NSString * sideitem in sides)
            {
                key = [NSString stringWithFormat:@"border%@-color", sideitem];
                if (obj)
                    [obj setValue:value forKey:key];
                if (res)
                    [res appendFormat:@"%@:%@;\n", key, value];
            }
		}
	}

	return res;
}

+(NSString *)alignFromString:(NSString *)str
{
	NSString * a = @"left";
	if ([str isEqual:@"CN"]) a = @"center";
	if ([str isEqual:@"RT"]) a = @"right";
	if ([str isEqual:@"FL"]) a = @"justify";
	if ([str isEqual:@"CA"]) a = @"left";
	return a;
}

+(NSSet *)readTabSpaces:(NSDictionary *)dict withPrefix:(NSString *)prefix
{
	NSMutableString * str = [[NSMutableString alloc] initWithCapacity:30];
	NSMutableSet * mset = nil;
	
	id value, value2, value3;
	
	[str setString:@""];
	if (prefix)
		[str appendFormat:@"%@_",prefix];
	[str appendFormat:@"TS_JU"];
	value = [dict objectForKey:str];
	if (value) {
		[str setString:@""];
		if (prefix)
			[str appendFormat:@"%@_",prefix];
		[str appendFormat:@"TS_LDR"];
		value2 = [dict objectForKey:str];
		
		[str setString:@""];
		if (prefix)
			[str appendFormat:@"%@_",prefix];
		[str appendFormat:@"TS_TABS"];
		value3 = [dict objectForKey:str];
		if (value2 && value3) {
			NSArray * arr1 = (NSArray *)value;
			NSArray * arr2 = (NSArray *)value2;
			NSArray * arr3 = (NSArray *)value3;
			
			mset = [[NSMutableSet alloc] initWithCapacity:1];
			
			int m;
			int i = [arr1 count];
			if ( [arr1 count] == [arr2 count] && [arr2 count] == [arr3 count])
			{
				for(m = 0; m < i; m++)
				{
					/*NSManagedObject * obj2 = [NSEntityDescription insertNewObjectForEntityForName:@"GPTabSpaces"
																		   inManagedObjectContext:ctx];
					[obj2 setValue:[GPTagHelper alignFromString:[arr1 objectAtIndex:m]] forKey:@"align"];
					[obj2 setValue:[arr2 objectAtIndex:m] forKey:@"leader"];
					value = [arr3 objectAtIndex:m];
					if ([value isEqual:@"Center"]) {
						[obj2 setValue:[NSNumber numberWithDouble:0.0] forKey:@"offset"];
						[obj2 setValue:[NSNumber numberWithInt:1] forKey:@"base"];
					}
					else if ([value isEqual:@"Right"]) {
						[obj2 setValue:[NSNumber numberWithDouble:0.0] forKey:@"offset"];
						[obj2 setValue:[NSNumber numberWithInt:2] forKey:@"base"];
					}
					else {
						[obj2 setValue:[NSNumber numberWithInt:0] forKey:@"base"];
						[obj2 setValue:[arr3 objectAtIndex:m] forKey:@"offset"];
					}
					[obj2 setValue:[NSNumber numberWithInt:m] forKey:@"order"];

					
					//value = [obj primitiveValueForKey:@"tab_spaces"];
					[mset addObject:obj2];*/
				}
			}
		}
	}

	return mset;
}

id getValue(NSDictionary * dict, NSMutableString * str, NSString * prefix, NSString * name)
{
	[str setString:prefix];
	[str appendFormat:@"%@",name];
	return [dict objectForKey:str];
}

NSMutableDictionary * fontSubx = nil;

+(NSString *)substitutionFontName:(NSString *)fname
{
    if (fontSubx == nil) {
        fontSubx = [[NSMutableDictionary alloc] init];
        [fontSubx setObject:@"Times" forKey:@"Balaram"];
        [fontSubx setObject:@"Times" forKey:@"Dravida"];
        [fontSubx setObject:@"Times" forKey:@"scagoudy"];
        [fontSubx setObject:@"Times" forKey:@"Rama-Palatino"];
        [fontSubx setObject:@"Times" forKey:@"Times New Roman"];
        [fontSubx setObject:@"Times" forKey:@"Tamal"];
        [fontSubx setObject:@"Times" forKey:@"Rama Garamond Plus"];
        [fontSubx setObject:@"Times" forKey:@"New York"];
        [fontSubx setObject:@"Times" forKey:@"Bhaskar"];
        [fontSubx setObject:@"Times" forKey:@"HGoudyOldStyleBTBoldItalic"];
        [fontSubx setObject:@"Times" forKey:@"Poetica"];
        [fontSubx setObject:@"Times" forKey:@"Shiksha"];
        [fontSubx setObject:@"Times" forKey:@"Drona"];
        [fontSubx setObject:@"Times" forKey:@"Sanskrit_Times"];
        [fontSubx setObject:@"Times" forKey:@"Sanskrit Benguiat"];
        [fontSubx setObject:@"Times" forKey:@"Palatino Sanskrit Hu 2"];
        [fontSubx setObject:@"Times" forKey:@"Font13399"];
        [fontSubx setObject:@"Times" forKey:@"Calibri"];
        [fontSubx setObject:@"Helvetica" forKey:@"Tahoma"];
        [fontSubx setObject:@"Helvetica" forKey:@"Arial"];
        [fontSubx setObject:@"Helvetica" forKey:@"Arial Unicode MS"];
        [fontSubx setObject:@"Helvetica" forKey:@"Courier New"];
        [fontSubx setObject:@"Helvetica" forKey:@"ScaHelvetica"];
        [fontSubx setObject:@"Helvetica" forKey:@"Sanskrit-Helvetica"];
        [fontSubx setObject:@"Helvetica" forKey:@"ScaOptima"];
    }
    
	if ([fname hasPrefix:@"Sanskrit-"])
		return @"Times";
	if ([fname hasPrefix:@"Sca"])
		return @"Times";

    NSString * ret = [fontSubx objectForKey:fname];
    if (ret != nil)
        return ret;
	
	return fname;
}

+(void)readParaFormating:(NSDictionary *)dict withPrefix:(NSString *)prefix target:(NSMutableDictionary *)obj
{
	id value = nil;
	//id value2 = nil;	
	//id value3 = nil;
	//NSLog(@"input dict:\n%@\n", dict);
		
	NSMutableString * str = [[NSMutableString alloc] initWithCapacity:64];
	//double dval = 0.0;
	//NSString * tempstr;
	
	// AP
	value = getValue(dict,str,prefix,@"_AP");
	if (value)
	{
		//[str setString:@""];
		//[str appendFormat:@"%@%@", value, @"in"];
		//NSLog(@"String content: %@\n", str);
		[obj setValue:[GPTagHelper inchToPoints:value] forKey:@"margin-bottom"];
	}
	//BP
	value = getValue(dict,str,prefix,@"_BP");
	if (value)
	{
		//[str setString:@""];
		//[str appendFormat:@"%@%@", value, @"in"];
		//NSLog(@"String content: %@\n", str);
		[obj setValue:[GPTagHelper inchToPoints:value] forKey:@"margin-top"];
	}
		//JU
	value = getValue(dict,str,prefix,@"_JU");
	if (value)
	{
		//[str setString:@""];
		//tempstr = [GPTagHelper alignFromString:value];
		//NSLog(@"align from string:%@  forkey :%@\n", tempstr);
		//[str appendFormat:@"%@", tempstr];
		[obj setValue:[GPTagHelper alignFromString:value] forKey:@"text-align"];
	}
	value = getValue(dict,str,prefix,@"_IN_LEFT");
	if (value)
	{
		//[str setString:@""];
		//[str appendFormat:@"%@%@", value, @"in"];
		//NSLog(@"String content: %@\n", str);
		[obj setValue:[GPTagHelper inchToPoints: value] forKey:@"margin-left"];
	}
	// IN_RIGHT
	value = getValue(dict,str,prefix,@"_IN_RIGHT");
	if (value)
	{
		//[str setString:@""];
		//[str appendFormat:@"%@%@", value, @"in"];
		//NSLog(@"String content: %@\n", str);
		[obj setValue:[GPTagHelper inchToPoints: value] forKey:@"margin-right"];
	}
	// IN_FIRST
	value = getValue(dict,str,prefix,@"_IN_FIRST");
	if (value)
	{
		//[str setString:@""];
		//[str appendFormat:@"%@%@", value, @"in"];
		//NSLog(@"String content: %@\n", str);
		[obj setValue:[GPTagHelper inchToPoints: value] forKey:@"text-indent"];
	}
	// LH
	value = getValue(dict,str,prefix,@"_LH");
	if (value)
	{
		//[str setString:@""];
		//[str appendFormat:@"%@%@", value, @"in"];
		//NSLog(@"String content: %@\n", str);
		[obj setValue:[GPTagHelper inchToPoints: value] forKey:@"line-height"];
	}
	// LS
	value = getValue(dict,str,prefix,@"_LS");
	if (value)
	{
		//[str setString:@""];
		double d= [[value description] doubleValue];
		if (d > 0.3)
		{
			//[str appendFormat:@"%f%%",  d];
			//NSLog(@"String content: %@\n", str);
			[obj setValue:[NSString stringWithFormat:@"%d%%", (int)(d*100.0)] forKey:@"line-height"];
		}
	}
	// LW
	/*value = getValue(dict,str,prefix,@"_LW");
	if (value)
	{
		[str setString:@""];
		[str appendFormat:@"%@%@", value, @"in"];
		[obj setValue:str forKey:@"width"];
	}*/
	// TS_
	//value = [GPTagHelper readTabSpaces:dict withPrefix:prefix inManagedObjectContext:ctx];
	//if (value) [obj addTab_spaces:value];
	// BR_
	[GPTagHelper readBorderFormating:dict withPrefix:prefix forSide:@"AL" target:obj];
	[GPTagHelper readBorderFormating:dict withPrefix:prefix forSide:@"RT" target:obj];
	[GPTagHelper readBorderFormating:dict withPrefix:prefix forSide:@"LF" target:obj];
	[GPTagHelper readBorderFormating:dict withPrefix:prefix forSide:@"BT" target:obj];
	[GPTagHelper readBorderFormating:dict withPrefix:prefix forSide:@"TP" target:obj];
	[GPTagHelper readBorderFormating:dict withPrefix:prefix forSide:@"HZ" target:obj];
	[GPTagHelper readBorderFormating:dict withPrefix:prefix forSide:@"VT" target:obj];

	
}

+(void)appendCssStyleFromDictionary:(NSDictionary *)dict toString:(NSMutableString *)s
{
	//NSMutableString * s = [[NSMutableString alloc] initWithCapacity:100];
	int ole = [s length];
	NSEnumerator *enumerator = [dict keyEnumerator];
	NSString * key;
	NSString * value;
	NSCharacterSet * whiteSpaces = [NSCharacterSet whitespaceCharacterSet];
	
	while ((key = [enumerator nextObject])) {
		value = [dict objectForKey:key];
		if (![key isEqual:@"class"])
		{
			NSRange rang = [value rangeOfCharacterFromSet:whiteSpaces];
			if (([s length] - ole) > 0)
				[s appendFormat:@";"];
			if (rang.location == NSNotFound)
			{
				[s appendFormat:@"%@:%@",key,value];
			}
			else
			{
				[s appendFormat:@"%@:\"%@\"",key,value];
			}
		}
	}
	
	//return s;
}

+(NSString *)readSuperSubScript:(NSDictionary *)dict withPrefix:(NSString *)prefix forScript:(NSString *)subp
{
	id value;
	NSMutableString * str = [[NSMutableString alloc] initWithCapacity:64];
	NSString * obj = nil;
	
	[str setString:prefix];
	[str appendFormat:@"_%@_VALUE",subp];
	value = [dict objectForKey:str];
	if (value) {
		[str setString:prefix];
		[str appendFormat:@"_%@_POINT",subp];
		if ([dict objectForKey:str])
		{
			obj = [NSString stringWithFormat:@"%@pt",value];
		}
		else {
			obj = [NSString stringWithFormat:@"%@in",value];
		}		
	}

	return obj;
}

+(NSString *)getBoldText:(NSNumber *)num
{
	int i = [num intValue];
	switch (i) {
		case 0: return @"normal";
		case 1: return @"";
		default: return @"bold";
	}
}

+(NSString *)getItalicText:(NSNumber *)num
{
	int i = [num intValue];
	switch (i) {
		case 0: return @"normal";
		case 1: return @"";
		default: return @"italic";
	}
}

+(NSString *)getHiddenText:(NSNumber *)num
{
	int i = [num intValue];
	switch (i) {
		case 0: return @"inherit";
		case 1: return @"";
		default: return @"none";
	}
}

+(NSString *)getUnderlineText:(NSNumber *)num
{
	int i = [num intValue];
	switch (i) {
		case 0: return @"normal";
		case 1: return @"";
		default: return @"underline";
	}
}

+(NSString *)getStrikeoutText:(NSNumber *)num
{
	int i = [num intValue];
	switch (i) {
		case 0: return @"normal";
		case 1: return @"normal";
		default: return @"line-through";
	}
}

+(void)readFont:(NSArray *)arrTag index:(int *)idx target:(NSMutableDictionary *)obj
{
	if (*idx < [arrTag count])
	{
		[obj setObject:[arrTag objectAtIndex:*idx] forKey:@"font-family"];
		//NSLog(@"count = %d    index=%d\n", [arrTag count], *idx);
		*idx += 1;
		//NSLog(@"count = %d    index=%d\n", [arrTag count], *idx);
		while (*idx < [arrTag count] && ([[arrTag objectAtIndex:(*idx)] isEqual:@";"] == NO)) {
			//NSLog(@"idx[%d] = %@\n", *idx, [arrTag objectAtIndex:(*idx)]);
			*idx += 1;
		}
	}
}

+(void)readCharFormating:(NSArray *)arrTag target:(NSMutableDictionary *)obj
{	
	int i = 4;
	for (i = 4; i < [arrTag count]; i++) {
		NSString * tag = [arrTag objectAtIndex:i];
		if ([tag isEqual:@"FT"]) {
			i+=2;
			[GPTagHelper readFont:arrTag index:&i target:obj];
		}
		else if ([tag isEqual:@"PT"]) {
			[obj setValue:[NSString stringWithFormat:@"%@pt", [arrTag objectAtIndex:(i+2)]] forKey:@"font-size"];
			i+=2;
		}
		else if ([tag isEqual:@"BC"]) {
			i+= 2;
			[GPTagHelper readColor:arrTag withPrefix:@"background-color" index:&i target:obj];
		}
		else if ([tag isEqual:@"FC"]) {
			i+= 2;
			[GPTagHelper readColor:arrTag withPrefix:@"color" index:&i target:obj];
		}
		else if ([tag isEqual:@"BD+"]) {
			[obj setObject:@"bold" forKey:@"font-weight"];
		}
		else if ([tag isEqual:@"BD-"]) {
			[obj setObject:@"normal" forKey:@"font-weight"];
		}
		else if ([tag isEqual:@"IT+"]) {
			[obj setObject:@"italic" forKey:@"font-style"];
		}
		else if ([tag isEqual:@"IT-"]) {
			[obj setObject:@"normal" forKey:@"font-style"];
		}
		else if ([tag isEqual:@"UN+"]) {
			[obj setObject:@"underline" forKey:@"text-decoration"];
		}
		else if ([tag isEqual:@"HD+"]) {
			[obj setObject:@"hidden" forKey:@"visibility"];
		}
		else if ([tag isEqual:@"HD-"]) {
			[obj setObject:@"visible" forKey:@"visibility"];
		}
		else if ([tag isEqual:@"SO+"]) {
			[obj setObject:@"line-through" forKey:@"text-decoration"];
		}
		else {
			while (i < [arrTag count] && [[arrTag objectAtIndex:i] isEqual:@";"] == NO) {
				i++;
			}
		}
		
	}
}

+(NSString *)getMIMEType:(NSString *)str
{
	if ([str isEqual:@"mp3file"])
		return @"audio/mpeg";
	if ([str isEqual:@"AcroExch.Document"])
		return @"application/pdf";
	
	return str;
}

+(NSString *)getMIMETypeFromExtension:(NSString *)str
{
	if ([str isEqual:@"mp3"])
		return @"audio/mpeg";
	if ([str isEqual:@"pdf"])
		return @"application/pdf";
    if ([str isEqualToString:@"png"])
        return @"image/png";
	
	return str;
}

+(void)readIndentFormating:(NSArray *)arrTag index:(int *)startIdx target:(NSMutableDictionary *)obj
{
	NSString * str;
	NSString * paramName = @"margin-left";
	
	str = [GPTagHelper inchToPoints:[arrTag objectAtIndex:*startIdx]];
	if (str == nil)
	{
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
			str = [GPTagHelper inchToPoints:[arrTag objectAtIndex:*startIdx]];
			[obj setValue:str forKey:paramName];
			*startIdx += 1;
			if ([arrTag count] <= *startIdx || [[arrTag objectAtIndex:*startIdx] isEqual:@";"]) {
				return;
			}
			*startIdx += 1;
		}
	}
	else {
		[obj setValue:str forKey:@"margin-left"];	
		*startIdx += 1;
		if ([arrTag count] <= *startIdx || [[arrTag objectAtIndex:*startIdx] isEqual:@";"]) {
			return;
		}
		*startIdx += 1;
		str = [GPTagHelper inchToPoints:[arrTag objectAtIndex:*startIdx]];
		[obj setValue:str forKey:@"margin-right"];
		*startIdx += 1;
		if ([arrTag count] <= *startIdx || [[arrTag objectAtIndex:*startIdx] isEqual:@";"]) {
			return;
		}
		*startIdx += 1;
		str = [GPTagHelper inchToPoints:[arrTag objectAtIndex:*startIdx]];
		[obj setValue:str forKey:@"text-indent"];
		return;
	}		
		 
	return;
}

+(void)readParaFormating:(NSArray *)arrTag fromIndex:(int)stidx target:(NSMutableDictionary *)obj
{
	NSString * value = nil;
	
	NSMutableString * str = [[NSMutableString alloc] initWithCapacity:64];
	
	for(int i = stidx; i < [arrTag count]; i++)
	{
		NSString * tag = [arrTag objectAtIndex:i];
		if ([tag isEqual:@"AP"]) {
			value = [GPTagHelper inchToPoints:[arrTag objectAtIndex:(i+2)]];
			[obj setValue:value forKey:@"margin-bottom"];
			i += 2;
		}
		else if ([tag isEqual:@"BP"]) {
			value = [GPTagHelper inchToPoints:[arrTag objectAtIndex:(i+2)]];
			[obj setValue:value forKey:@"margin-top"];
			i += 2;
		}
		else if ([tag isEqual:@"JU"]) {
			value = [GPTagHelper alignFromString:[arrTag objectAtIndex:(i+2)]];
			[obj setValue:value forKey:@"text-align"];
			i+=  2;
		}
		else if ([tag isEqual:@"SD"]) {
			i+= 2;
			[GPTagHelper readColor:arrTag withPrefix:@"background-color" index:&i target:obj];
		}
		else if ([tag isEqual:@"LH"]) {
			value = [GPTagHelper inchToPoints:[arrTag objectAtIndex:(i+2)]];
			[obj setValue:value forKey:@"line-height"];
			i+= 2;
		}
		else if ([tag isEqual:@"LS"]) {
			value = [GPTagHelper percentValue:[arrTag objectAtIndex:(i+2)]];
			[obj setValue:value forKey:@"line-height"];
			i+= 2;
		}
		else if ([tag isEqual:@"IN"]) {
			i+=2;
			[GPTagHelper readIndentFormating:arrTag index:&i target:obj];
		}
		else if ([tag isEqual:@"BR"]) {
			i+=2;
			[GPTagHelper readBorders:arrTag index:&i target:obj];
		}
		else {
			while (i < [arrTag count] && [[arrTag objectAtIndex:i] isEqual:@";"] == NO) {
				i++;
			}
		}

	}
	
}

+(void)readBorders:(NSArray *)arrTag index:(int *)startIndex target:(NSMutableDictionary *)obj
{
	NSString * side;
	NSArray * postfix;
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
		postfix = [GPTagHelper sideTextFromAbbr:side];
		if (postfix == nil) {
			*startIndex -= 1;
			return;
		}
		//NSLog(@"postifx: %@\n", postfix);
		*startIndex += 2;
		strWidth = [GPTagHelper inchToPoints:[arrTag objectAtIndex:*startIndex]];
		//if (value) {
		//strWidth = value;
			//[obj setObject:value forKey:[NSString stringWithFormat:@"border%@-width", postfix]];
			//}
		*startIndex += 2;
		value = [GPTagHelper inchToPoints:[arrTag objectAtIndex:*startIndex]];
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
			strColor = [GPTagHelper readColor:arrTag index:startIndex];
			*startIndex += 1;
		}
		else {
			strColor = @"";
		}
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

@end
