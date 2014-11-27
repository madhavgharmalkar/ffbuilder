//
//  FolioTextDatabase.m
//  Builder
//
//  Created by Peter Kollath on 10/14/10.
//  Copyright 2010 GPSL. All rights reserved.
//

#import "VBFolioBuilder.h"
#import "FlatFileImporter.h"
#import "GPTagHelper.h"
#import "FlatFileUtils.h"
#import "GPDebugger.h"

#define OUTPUT_UNICODE 1

@implementation VBFolioBuilder

@synthesize currentRecordID;
@synthesize levels;
@synthesize spanClass;
@synthesize whiteSpaces;
@synthesize excludedQueryLinks;
@synthesize fileInfo;
@synthesize supressIndexing;
@synthesize speedFontGroupStyle, speedFontNameStyle, speedFontGroupName;
@synthesize targetHtmlRec, contentDict;

#pragma mark -
#pragma mark Object Life Time



-(id)initWithDirectory:(NSString *)directory
{
    self = [super init];
    
	if (self)
	{
        [GPDebugger createInstanceWithDirectory:directory];
		int i;
		shouldFlush = 0;
		fontGroup = 0;
		for(i = 0; i < kContStripMax; i++)
		{
			contStrips[i] = nil;
			levelMapping[i] = i;
            lastLevelRecord[i] = -1;
		}
        self.fileInfo = [[NSMutableString alloc] init];
		contRoot = [[NSMutableArray alloc] initWithCapacity:10];
		strHelper = [[NSMutableString alloc] initWithCapacity:120];

		bCharToBuff = YES;
        includesIndex = 1;
        currentRecordID = 1;
		strBuff = [[NSMutableString alloc] initWithCapacity:3000];
		self.whiteSpaces = [NSCharacterSet whitespaceAndNewlineCharacterSet];
		wordList = [[RKSortedList alloc] init];
        [wordList setKeyName:@"text"];
        linkRefs = [[NSMutableArray alloc] initWithCapacity:1000];
        records = [[NSMutableArray alloc] initWithCapacity:1000000];
        recordStack = [[NSMutableArray alloc] init];
        contentStack = [[NSMutableArray alloc] init];
        contentArray = nil;
        notes = [[NSMutableArray alloc] initWithCapacity:1000];
		textSizeMultiplier = 1.0;
		temparrStyles = [[NSMutableArray alloc] initWithCapacity:1000];
        NSMutableDictionary * dct = [[NSMutableDictionary alloc] init];
        self.paraUsageCounter = dct;
        speedFontGroupStyle = [[NSMutableDictionary alloc] init];
        speedFontNameStyle = [[NSMutableDictionary alloc] init];
        speedFontGroupName = [[NSMutableDictionary alloc] init];
        HtmlString * tmpHS = [[HtmlString alloc] init];
        self.targetHtmlRec = tmpHS;
        contentTaggedItems = [[NSMutableDictionary alloc] init];
        self.lastInlinePopup = 1;
        _stpdefs = [[NSMutableDictionary alloc] init];
        self.groupMap = [RKKeySet new];
	}
	
	return self;
}

-(void)dealloc
{
    [self closeDumpFiles];
}

#define VBFB_FONTGROUP_BALARAM    0
#define VBFB_FONTGROUP_DEVANAGARI 1
#define VBFB_FONTGROUP_SANSKRIT   2
#define VBFB_FONTGROUP_BENGALI    3
#define VBFB_FONTGROUP_WINDGDINGS 4

#pragma mark -
#pragma mark Helper Functions

NSSet * balaramFontSet = nil;
NSSet * devanagariFontSet = nil;

-(int)fontGroupFromFontName:(NSString *)fname
{
    NSNumber * number = [self.speedFontGroupName valueForKey:fname];
    
    if (number == nil)
    {
        number = [NSNumber numberWithInt:[self fontGroupFromFontNameInt:fname]];
        [self.speedFontGroupName setValue:number forKey:fname];
    }
    
    return [number intValue];
}

-(int)fontGroupFromFontNameInt:(NSString *)fname
{
    if (balaramFontSet == nil) {
        balaramFontSet = [[NSSet alloc] initWithObjects:@"Balaram",
                          @"Terminal", @"Dravida", @"scagoudy", @"Basset",
                          @"Times New Roman", @"Times New Roman Greek", @"Bold PS 12cpi",
                          @"Times New Roman Baltic", @"Times New Roman Special G1",
                          @"Arial Narrow", @"Univers", @"Times New", @"MS Sans Serif",
                          @"CG Times", @"TimesN", @"Bookman Old Style", @"Poetica",
                          @"Microsoft Sans Serif", @"Helvetica Narrow", @"France", @"Sanvito Roman",
                          @"C Helvetica Condensed", @"Garamond BoldCondensed", @"Drona",
                          @"Garamond BookCondensed", @"TimesTen Roman", @"Tms Rmn", @"Chn JSong SG",
                          @"Book Antiqua", @"Courier New", @"Courier", @"Monaco", @"Font13399",
                          @"Geneva", @"Arial", @"Times", @"New York", @"GillSans Bold",
                          @"Symbol", @"Font14956", @"Arial Unicode MS",
                          @"Galliard", @"Tamalten", @"Bhaskar", @"Tahoma", @"Time Roman",
                          @"Timingala", @"Tamal", @"Garamond", @"Gaudiya", @"Helvetica",
                          @"BhaskarItal", @"Calibri", @"HGoudyOldStyleBTBoldItalic", nil];
    }
    if (devanagariFontSet == nil) {
        devanagariFontSet = [[NSSet alloc] initWithObjects:@"Indevr",
                             @"RM Devanagari", @"Helv", @"indevr", nil];
    }
	if ([fname hasPrefix:@"Sanskrit-"])
		return VBFB_FONTGROUP_SANSKRIT;
	if ([fname hasPrefix:@"Sca"] || [balaramFontSet containsObject:fname])
		return VBFB_FONTGROUP_BALARAM;
    
	if ([devanagariFontSet containsObject:fname])
		return VBFB_FONTGROUP_DEVANAGARI;
    
    if ([fname isEqualToString:@"Wingdings"]) {
        return VBFB_FONTGROUP_WINDGDINGS;
    }
	
    if ([fname isEqual:@"Inbeni"] || [fname isEqual:@"Inbenr"]
        || [fname isEqual:@"Inbeno"] || [fname isEqual:@"Inbenb"])
		return VBFB_FONTGROUP_BENGALI;
	
    NSLog(@"%@ / %@", fname, [GPDebugger fileLocationPlain]);
	return VBFB_FONTGROUP_BALARAM;
}

-(NSString *)fontNameFromStyle:(NSString *)sname
{
    NSString * str = [self.speedFontNameStyle valueForKey:sname];
    if (str == nil)
    {
        str = [self fontNameFromStyleInt:sname];
        [self.speedFontNameStyle setValue:str forKey:sname];
    }
    
    return str;
}


-(NSString *)fontNameFromStyleInt:(NSString *)sname
{
	for(int i = 0; i < [temparrStyles count]; i++)
	{
		NSDictionary * dict = [temparrStyles objectAtIndex:i];
		if (dict)
		{
			NSString * strName = [dict objectForKey:@"name"];
			if ([strName compare:sname] == NSOrderedSame)
			{
				//NSLog(@"style dict = %@\n", dict);
				NSDictionary * dictFormat = [dict objectForKey:@"format"];
				if (dictFormat)
				{
					return [dictFormat objectForKey:@"font-family"];
				}
			}
		}
	}
    
    return nil;
}

-(int)fontGroupFromStyle:(NSString *)fname
{
    NSNumber * number = [self.speedFontGroupStyle valueForKey:fname];
    
    if (number == nil)
    {
        number = [NSNumber numberWithInt:[self fontGroupFromStyleInt:fname]];
        [self.speedFontGroupStyle setValue:number forKey:fname];
    }
    
    return [number intValue];
}

-(int)fontGroupFromStyleInt:(NSString *)sname
{
    if ([sname compare:@"Bengro"] == NSOrderedSame)
    {
        return VBFB_FONTGROUP_BENGALI;
    }

    NSString * fontName = [self fontNameFromStyle:sname];
    
    if (fontName == nil)
        return VBFB_FONTGROUP_BALARAM;
    return [self fontGroupFromFontName:fontName];
}

-(int)createLinkRef:(NSString *)str
{
    int ret = [linkRefs count] + 1;
    [linkRefs addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:ret], @"linkid", 
                         str, @"query", nil]];
    return ret;
}


#pragma mark -
#pragma mark Tag acceptance functions

-(void)acceptTagArray:(NSArray *)tagArr tagBuffer:(FlatFileTagString *)tagStr
{
	if (tagArr == nil || [tagArr count] == 0) return;
	int count = [tagArr count];
	NSString * str = [tagArr objectAtIndex:0];
	if ([str isEqual:@"AS"] || [str isEqual:@"AU"] || [str isEqual:@"RM"] || [str isEqual:@"SU"]
        || [str caseInsensitiveCompare:@"InclusionPath"] == NSOrderedSame) {
		[strBuff setString:@""];
		bCharToBuff = YES;
		return;
	}
	else if ([str isEqual:@"/AS"] || [str isEqual:@"/AU"] || [str isEqual:@"/RM"] || [str isEqual:@"/SU"]) {
        NSString * propertyName = [str substringFromIndex:1];
        fprintf(fileTableDocinfo, "%s\t%s\t%ld\n", [propertyName UTF8String], [strBuff UTF8String], 0L);
		bCharToBuff = NO;
		return;
	}
	else if ([str isEqual:@"PR"] 
             || [str isEqual:@"DQ"] 
             || [str caseInsensitiveCompare:@"Collection"] == NSOrderedSame
             || [str caseInsensitiveCompare:@"SortKey"] == NSOrderedSame)
    {
        fprintf(fileTableDocinfo, "%s\t%s\t%ld\n", [str UTF8String], [[tagArr objectAtIndex:2] UTF8String], 0L);
	}
	else if ([str caseInsensitiveCompare:@"CollectionName"] == NSOrderedSame)
    {
        [self.fileInfo appendFormat:@"CNAME=%@\n", [tagArr objectAtIndex:2]];
        fprintf(fileTableDocinfo, "%s\t%s\t%ld\n", [str UTF8String], [[tagArr objectAtIndex:2] UTF8String], 0L);
	}
	else if ([str caseInsensitiveCompare:@"Key"] == NSOrderedSame)
    {
        [self.fileInfo appendFormat:@"KEY=%@\n", [tagArr objectAtIndex:2]];
        fprintf(fileTableDocinfo, "%s\t%s\t%ld\n", [str UTF8String], [[tagArr objectAtIndex:2] UTF8String], 0L);
	}
    else if ([str isEqualToString:@"CH"]) {
        [self acceptChar:[[tagArr objectAtIndex:2] integerValue]];
    }
    else if ([str caseInsensitiveCompare:@"InjectionPath"] == NSOrderedSame) {
        // this is actually the same tag as InclusionPath but difference is that
        // InclusionPath tag is writen in source file as
        //     <InclusionPath>... text ... </InclusionPath>
        // while InjectionPath is written as:
        //     <InjectionPath:"....text....">
        fprintf(fileTableDocinfo, "%s\t%s\t%ld\n", "InclusionPath", [[tagArr objectAtIndex:2] UTF8String], inclusionPathIndex);
        inclusionPathIndex++;
    }
    else if ([str caseInsensitiveCompare:@"InclusionPath"] == NSOrderedSame) {
		[strBuff setString:@""];
		bCharToBuff = YES;
    } 
    else if ([str caseInsensitiveCompare:@"/InclusionPath"] == NSOrderedSame) {
		bCharToBuff = NO;
        fprintf(fileTableDocinfo, "%s\t%s\t%ld\n", "InclusionPath", [strBuff UTF8String], inclusionPathIndex);
        inclusionPathIndex++;
    }
    else if ([str caseInsensitiveCompare:@"Includes"] == NSOrderedSame) {
        [self.fileInfo appendFormat:@"INCLUDES=%@\n", [tagArr objectAtIndex:2]];
        fprintf(fileTableDocinfo, "%s\t%s\t%ld\n", "Includes", [[tagArr objectAtIndex:2] UTF8String], includesIndex);
        includesIndex++;
    }
	else if ([str isEqual:@"AP"]) {
	}
	else if ([str isEqual:@"BP"]) {
	}
	else if ([str isEqual:@"BK"]) {
	}
	else if ([str isEqual:@"BC"]) {
		if (count == 1 || [[tagArr objectAtIndex:2] isEqual:@"DC"]) { } else { }
	}
	else if ([str isEqual:@"BR"]) {
	}
	else if ([str isEqual:@"BD-"]) {
	}
	else if ([str isEqual:@"BD"]) {
		//[self endCharTag:@"font-weight"];
	}
	else if ([str isEqual:@"BH"]) {
        NSMutableDictionary * d = [self currentRecord];
        [d setObject:[NSNumber numberWithInt:([[d objectForKey:@"plain"] length])] forKey:@"bh"];
		//bhIndex = [self.currentPlain length];
	}
	else if ([str isEqual:@"EH"]) { 
        NSMutableDictionary * d = [self currentRecord];
        [d setObject:[NSNumber numberWithInt:([[d objectForKey:@"plain"] length])] forKey:@"eh"];
		//ehIndex = [self.currentPlain length];
	}
	else if ([str isEqual:@"BD+"]) {
		//[self startCharTag:@"font-weight" data:@"bold"];
	}
	else if ([str isEqual:@"UN-"]) {
		//[self startCharTag:@"text-decoration" data:@"none"];
	}
	else if ([str isEqual:@"UN"]) {
		//[self endCharTag:@"text-decoration"];
	}
	else if ([str isEqual:@"UN+"]) {
		//[self startCharTag:@"text-decoration" data:@"underline"];
	}
	else if ([str isEqual:@"SO-"]) {
		//[self startCharTag:@"text-decoration" data:@"none"];
	}
	else if ([str isEqual:@"SO"]) {
		//[self endCharTag:@"text-decoration"];
	}
	else if ([str isEqual:@"SO+"]) {
		//[self startCharTag:@"text-decoration" data:@"line-through"];
	}
	else if ([str isEqual:@"HD-"]) {
		//[self startCharTag:@"visibility" data:@"visible"];
	}
	else if ([str isEqual:@"HD"]) {
	}
	else if ([str isEqual:@"HD+"]) {
	}
	else if ([str isEqual:@"CM"]) {
		commentText = YES;
	}
	else if ([str isEqual:@"/CM"]) {
		commentText = NO;
	}
	else if ([str isEqual:@"CR"]) {
	}
	else if ([str isEqual:@"CS"]) {
        NSString * paraName = [tagArr objectAtIndex:2];
        if ([self.safeStringReplace objectForKey:paraName]) {
            paraName = [self.safeStringReplace objectForKey:paraName];
        }
        
        [self.currentPlain appendFormat:@"<CS:\"%@\">", paraName];
	}
	else if ([str isEqual:@"/CS"]) {
	}
	else if ([str isEqual:@"DI"] || [str isEqual:@"FI"]) {
        self.requestedFileName = [self.inputPath URLByAppendingPathComponent:[[tagArr objectAtIndex:2] stringByReplacingOccurrencesOfString:@"\\" withString:@"/"]];
        return;
	}
	else if ([str isEqual:@"DF"]) {
        for(int i = 2; i <= 6; i+= 4)
        {
            if ([tagArr count] > (i+2))
            {
                if ([[tagArr objectAtIndex:i] isEqual:@"FT"])
                {
                    fprintf(fileTableDocinfo, "DefaultFontFamily\t%s\t%ld\n", [[tagArr objectAtIndex:(i+2)] UTF8String], 0L);
                }
                else if ([[tagArr objectAtIndex:i] isEqual:@"PT"])
                {
                    fprintf(fileTableDocinfo, "DefaultFontSize\t%s\t%ld\n", [[tagArr objectAtIndex:(i+2)] UTF8String], 0L);
                }
            }
        }
	}
	else if ([str isEqual:@"DP"]) {
        NSMutableDictionary * dict = [self recordWillStartRead:str];
		if (count == 7)
		{
			[dict setObject:[tagArr objectAtIndex:2] forKey:@"width"];
			[dict setObject:[tagArr objectAtIndex:4] forKey:@"height"];
			[dict setObject:[tagArr objectAtIndex:6] 
                     forKey:@"title"];
		}
		else if (count == 3)
		{
			[dict setObject:[tagArr objectAtIndex:2] 
                     forKey:@"title"];
		}
		else {
			[dict setObject:@"" forKey:@"title"];
		}
	}
	else if ([str isEqual:@"/DP"]) 
    {
		[self restoreCurrentTarget];
	}
	else if ([str isEqual:@"FO"] || [str isEqual:@"HE"]) 
    {
		commentText = YES;
	}
	else if ([str isEqual:@"/FO"] || [str isEqual:@"/HE"]) {
		commentText = NO;
	}
	else if ([str isEqual:@"FC"]) {
		if (count == 1 || [[tagArr objectAtIndex:2] isEqual:@"DC"])
		{
			//[self endCharTag:@"color"];
		}
		else {
			//NSMutableDictionary * dict = [[NSMutableDictionary alloc] initWithCapacity:2];
			//int i = 2;
			//[GPTagHelper readColor:tagArr withPrefix:@"value" index:&i target:dict];
			//if ([dict objectForKey:@"value"])
			//	[self startCharTag:@"color" data:[dict objectForKey:@"value"]];
			//[dict release];
		}
	}
	else if ([str isEqual:@"FT"]) {
		if (count == 1)
		{
			//[self endCharTag:@"font-family"];
			fontGroup = previousFontGroup;
		}
		else {
			NSString * fontName = [tagArr objectAtIndex:2];
            NSMutableSet * fonts = [[self currentRecord] objectForKey:@"fonts"];
            if (fonts == nil)
            {
                fonts = [[NSMutableSet alloc] init];
                [[self currentRecord] setObject:fonts forKey:@"fonts"];
            }
            [fonts addObject:fontName];
			//[self startCharTag:@"font-family" data:[GPTagHelper substitutionFontName:fontName]];
            previousFontGroup = fontGroup;
			fontGroup = [self fontGroupFromFontName:fontName];
		}
	}
	else if ([str isEqual:@"HR"]) {
			//[self.currentText appendFormat:@"<br>"];
	}
	else if ([str isEqual:@"GR"]) {
        NSInteger grpId = [self.groupMap idForKey:tagArr[2]];
        fprintf(fileTableGroups, "%ld\t%d\n", grpId, self.currentRecordID);
	}
	else if ([str isEqual:@"HS"]) {
		//[self.currentText appendFormat:@"&nsbp;"];
	}
	else if ([str isEqual:@"IT-"]) {
		//[self startCharTag:@"font-style" data:@"normal"];
	}
	else if ([str isEqual:@"IT"]) {
		//[self endCharTag:@"font-style"];
	}
	else if ([str isEqual:@"IT+"]) {
		//[self startCharTag:@"font-style" data:@"italic"];
	}
	else if ([str isEqual:@"JD"]) {
		NSString * o = [[tagArr objectAtIndex:2] stringByReplacingOccurrencesOfString:@"'" withString:@"-"];
        fprintf(fileTableJumplinks, "%s\t%d\n", [o UTF8String], self.currentRecordID);
	}
	else if ([str isEqual:@"JU"]) {
        //[self.currentFormat appendFormat:@"text-align:%@;", 
        //[GPTagHelper alignFromString:[tagArr objectAtIndex:2]]];
	}
	else if ([str isEqual:@"LT"]) {

        NSMutableDictionary * dict = [self currentRecord];
        [self restoreCurrentTarget];
        [[self currentPlain] appendFormat:@"<PX:\"%@\",\"%@\">", [dict valueForKey:@"pwLinkStyle"], [dict valueForKey:@"title"]];
        self.linkTagStarted = YES;

    }
	else if ([str isEqual:@"LH"]) {
        //double v = [[tagArr objectAtIndex:2] doubleValue];
        //if ([self.currentFormat length] > 0) [self.currentFormat appendFormat:@";"];
        //[self.currentFormat appendFormat:@"line-height:%f%%;", v*100.0];
	}
	else if ([str isEqual:@"IN"]) {
	}
	else if ([str isEqual:@"LE"] || [str isEqual:@"PA"]) {
		NSMutableDictionary * obj = [NSMutableDictionary dictionaryWithCapacity:5];
		NSMutableDictionary * form = [NSMutableDictionary dictionaryWithCapacity:10];
		[form setValue:@"0pt" forKey:@"margin-bottom"];
		[form setValue:@"0pt" forKey:@"margin-top"];
		[GPTagHelper readParaFormating:tagArr fromIndex:4 target:form];
		[GPTagHelper readCharFormating:tagArr target:form];
		[obj setValue:form forKey:@"format"];
		[obj setValue:str forKey:@"cat"];
        NSString * paraName = [tagArr objectAtIndex:2];
        [obj setValue:paraName forKey:@"originalName"];
        if ([str isEqualToString:@"PA"] && [self.safeStringReplace objectForKey:paraName])
            paraName = [self.safeStringReplace objectForKey:paraName];
        [obj setValue:paraName forKey:@"substitutedName"];
        NSString * name = [FlatFileString stringToSafe:paraName tag:str];
        [obj setValue:name forKey:@"name"];
        [temparrStyles addObject:obj];
        //[[self currentRecord] setObject:name forKey:@"styleName"];
	}
	else if ([str isEqual:@"LN"]) {
		int idx = 2;
		NSString * sx;
		//NSMutableArray * tarr = [NSMutableArray arrayWithCapacity:(count/2)];
		self.levels = [[NSMutableArray alloc] init];
		for(idx = 2; idx < count; idx+=2)
		{
            NSString * originalLevelName = [tagArr objectAtIndex:idx];
            //if ([self.safeStringReplace objectForKey:originalLevelName])
            //    originalLevelName = [self.safeStringReplace objectForKey:originalLevelName];
			sx = [FlatFileString stringToSafe:originalLevelName tag:@"LE"];
            NSDictionary * levelDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                        originalLevelName, @"original", 
                                        sx, @"safe", 
                                        [NSNumber numberWithInt:idx/2], @"index", 
                                        nil];
            fprintf(fileTableLevels, "%d\t%s\t%s\n", idx/2, [originalLevelName UTF8String], [sx UTF8String]);
			[self.levels addObject:levelDict];
		}
	}
	else if ([str isEqual:@"OB"]) {
        // !!!!!!!
        // must remain here after removing production of HTML strings
        //
		NSString * ob_type = [tagArr objectAtIndex:2];
		NSString * ob_name = [tagArr objectAtIndex:4];
		NSString * ob_width = nil;
		NSString * ob_height = nil;
		if (count > 6)
			ob_width = [tagArr objectAtIndex:6];
		if (count > 8)
			ob_height = [tagArr objectAtIndex:8];
        ob_type = [definedObjects valueForKey:ob_name];
		//NSMutableDictionary * form = [[NSMutableDictionary alloc] initWithCapacity:10];
		//[GPTagHelper readParaFormating:rfTag withPrefix:str target:form];
		NSMutableString * s = [[NSMutableString alloc] initWithCapacity:100];
		//[s appendFormat:@"<object"];
		//if (ob_type != nil)
		//{
			//[s appendFormat:@" type=\"%@\"", ob_type];
		//}
		//if (ob_width != nil && ob_height != nil)
		//{
			//[s appendFormat:@" width=%@pt height=%@pt",
			 //[GPTagHelper inchToPoints:ob_width],
			 //[GPTagHelper inchToPoints:ob_height]];
		//}
		//if (ob_name != nil)
		//{
			//[s appendFormat:@" data=\"vbase://objects/%@\"", ob_name];
		//}
		//if ([form count] > 0)
		//{
			//[s appendFormat:@" style='"];
			//[GPTagHelper appendCssStyleFromDictionary:form toString:s];
			//[s appendFormat:@"'"];
		//}
		//[s appendFormat:@"></object>"];
		//[self.currentText appendFormat:@"%@",s];
		//[form release];
        [s setString:@""];
        [s appendFormat:@"<OB:\"%@\";\"%@\"", ob_type, ob_name];
        if (count > 6)
        {
            [s appendFormat:@";%@", ob_width];
        }
        if (count > 8)
        {
            [s appendFormat:@";%@", ob_height];
        }
        [s appendFormat:@">"];
        [self.currentPlain appendFormat:@"%@", s];
		return;
	}
    else if ([str isEqualToString:@"OptimizeStyles"]) {
        //[self saveStylesRefactoring];
    }
	else if ([str isEqual:@"OD"]) {
        NSString * objectName = [tagArr objectAtIndex:4];
        NSString * objectFile = [tagArr objectAtIndex:8];
        //NSString * objectType = [tagArr objectAtIndex:6];
        NSURL * fullFilePath = [self.inputPath URLByAppendingPathComponent:[objectFile stringByReplacingOccurrencesOfString:@"\\" withString:@"/"]];
        
        fprintf(fileTableObjects, "%s\t%s\t%s\n",
                [objectName UTF8String],
                [[fullFilePath absoluteString] UTF8String],
                [[GPTagHelper getMIMETypeFromExtension:[objectFile pathExtension]] UTF8String]);
        
        [definedObjects setValue:[GPTagHelper getMIMETypeFromExtension:[objectFile pathExtension]] forKey:objectName];
	}
	else if ([str isEqualToString:@"PT"])  {
		if (count == 1)
		{
			//[self endCharTag:@"font-size"];
		}
		else {
			//NSString * ptSizeDescr = [tagArr objectAtIndex:2];
			//[self startCharTag:@"font-size" data:[NSString stringWithFormat:@"%@pt", ptSizeDescr]];
		}
	}
    else if ([str isEqualToString:@"PW"]) {
        NSMutableDictionary * dict = [self recordWillStartRead:str];
        [dict setObject:@"" forKey:@"title"];
        [dict setObject:@"Popup" forKey:@"pwLinkStyle"];
        if (count > 2) {
			[dict setObject:[tagArr objectAtIndex:2] forKey:@"pwLinkStyle"];
        }
        if (count > 4) {
			[dict setObject:[tagArr objectAtIndex:4] forKey:@"width"];
        }
        if (count > 6) {
			[dict setObject:[tagArr objectAtIndex:6] forKey:@"height"];
        }
        if (count > 8) {
			[dict setObject:[tagArr objectAtIndex:8] forKey:@"title"];
		}
        self.lastInlinePopup ++;
        [dict setObject:[NSString stringWithFormat:@"InlinePopupText_%d", self.lastInlinePopup]
                 forKey:@"title"];
    }
	else if ([str isEqualToString:@"QL"] || [str isEqualToString:@"EN"]) {
        //[self finishLink];
		//[self pushLinkStack:str];
        //NSString * query = [tagArr objectAtIndex:4];
        NSString * query = [tagArr objectAtIndex:4];

        [GPDebugger writeTag:str text:query];
        [[[GPDebugger instance] newerTags] addObject:query];
        //[self createLinkRef:query];
        //[[self currentText] appendFormat:@"<a name=\"loc\">"];
        
        BOOL afterTest = YES;
        
        /*if ([query hasPrefix:@"[Headings"]) {
            NSRange firstComma = [query rangeOfString:@","];
            if (firstComma.location != NSNotFound) {
                NSCharacterSet * whites = [NSCharacterSet whitespaceAndNewlineCharacterSet];
                NSString * levelName = [[query substringWithRange:NSMakeRange(9, firstComma.location-9)] stringByTrimmingCharactersInSet:whites];
                NSString * subquery = [[query substringFromIndex:firstComma.location+1] stringByTrimmingCharactersInSet:whites];
                if ([subquery hasSuffix:@"]"])
                {
                    subquery = [subquery substringToIndex:([subquery length] - 1)];
                }
                
                NSDictionary * dict = [self.contentDict objectForKey:levelName];
                if (dict != nil)
                {
                    NSString * val = [dict objectForKey:subquery];
                    if (val != nil)
                    {
                        [self.currentPlain appendString:[tagStr buffer]];
                        self.linkTagStarted = YES;
                        afterTest = NO;
                    }
                }
            }
        }*/
        
        if (afterTest && [self.excludedQueryLinks containsObject:query] == NO) {
            [self.currentPlain appendString:[tagStr buffer]];
            self.linkTagStarted = YES;
        }
	}
	else if ([str isEqual:@"PX"]) {
        //[self finishLink];
		//[self pushLinkStack:str];
        //NSDictionary * dict = [self findPopupByName:[tagArr objectAtIndex:4]];
		//[self.currentText appendFormat:@"<a class=\"%@\" href=\"vbase://popup/0\">",  [tagArr objectAtIndex:2]//, [dict objectForKey:@"id"] ];
        self.linkTagStarted = YES;
	}
	else if ([str isEqual:@"DL"] || [str isEqual:@"ML"] || [str isEqual:@"PL"] || [str isEqual:@"WW"]) {
        //[self finishLink];
		//[self pushLinkStack:str];
        [GPDebugger writeTag:str text:[tagArr objectAtIndex:4]];
		//[self.currentText appendFormat:@"<a class=\"%@\" href=\"vbase://links/%@/%@\">",
		// [tagArr objectAtIndex:2], str, [tagArr objectAtIndex:4] ];
		//[self.currentPlain appendFormat:@" "];
        self.linkTagStarted = YES;
	}
	else if (   [str isEqual:@"/DL"] || [str isEqual:@"/ML"]
			 || [str isEqual:@"/JL"] || [str isEqual:@"/PX"]
             || [str isEqual:@"/OL"] || [str isEqual:@"/PL"]
			 || [str isEqual:@"/PW"] || [str isEqual:@"/WW"]) {
		//NSString * lastLinkTag = [self peekLinkStack];
        //[self finishLink];
        self.linkTagStarted = NO;
	}
    else if ([str isEqualToString:@"/QL"] || [str isEqual:@"/EN"]) {
        if (self.linkTagStarted) {
            [self.currentPlain appendFormat:@"<%@>", str];
            self.linkTagStarted = NO;
        }
    }
    else if ([str isEqualToString:@"EL"]) {
        if (self.linkTagStarted) {
            [self.currentPlain appendFormat:@"<%@>", str];
            self.linkTagStarted = NO;
        }
    }
	else if ([str isEqual:@"JL"]) {
        //[self finishLink];
        //[self pushLinkStack:str];
        [self.currentPlain appendString:[[tagStr buffer] stringByReplacingOccurrencesOfString:@"'" withString:@""]];
        self.linkTagStarted = YES;
	}
	else if ([str isEqual:@"RO"])
	{
		//[self finishHtmlText];
		//[self.currentText appendFormat:@"<tr>"];
		//self.curr_rows++;
		//self.curr_columns=0;
	}
	else if ([str isEqual:@"PS"]) {
        NSString * paraName = [tagArr objectAtIndex:2];
        if ([self.safeStringReplace objectForKey:paraName]) {
            paraName = [self.safeStringReplace objectForKey:paraName];
        }

		NSString * safeString = [FlatFileString stringToSafe:paraName tag:@"PA"];

        GPMutableInteger * counter = [self.paraUsageCounter objectForKey:safeString];
        if (counter == nil) {
            counter = [[GPMutableInteger alloc] init];
            [self.paraUsageCounter setObject:counter forKey:safeString];
            counter.value = 0;
        }
        counter.value++;
		[self.currentClass setString:safeString];
        [[self currentRecord] setObject:safeString forKey:@"styleName"];
		fontGroup = [self fontGroupFromStyle:safeString];
        [self.currentPlain appendFormat:@"<PS:\"%@\">", paraName];
        
        NSString * font = [self fontNameFromStyle:safeString];
        if (font)
        {
            NSMutableSet * fonts = [[self currentRecord] objectForKey:@"fonts"];
            if (fonts == nil)
            {
                fonts = [[NSMutableSet alloc] init];
                [[self currentRecord] setObject:fonts forKey:@"fonts"];
            }
            [fonts addObject:font];
        }
	}
	else if ([str isEqual:@"RD"])
	{
        NSMutableDictionary * dict = [self recordWillStartRead:str];
        
        previousFontGroup = 0;
		NSString * strLevel = nil;
		NSString * strItem = nil;
        if (count == 3)
        {
            strLevel = [tagArr objectAtIndex:2];
        }
		else if (count == 5)
		{
			if ([[tagArr objectAtIndex:2] isEqual:@"ID"]) {
			} else if ([[tagArr objectAtIndex:2] isEqual:@"CH"]) {
                strLevel = [tagArr objectAtIndex:4];
            } else if ([[tagArr objectAtIndex:4] isEqual:@"CH"]) {
                strLevel = [tagArr objectAtIndex:2];
            }
			else {
				strItem = nil;
			}

		}
		else if (count == 7) {
			if ([[tagArr objectAtIndex:2] isEqual:@"ID"]) {
				strLevel = [tagArr objectAtIndex:6];
			}
			else {
				strItem = nil;
			}
		}
		else if (count == 9) {
			if ([[tagArr objectAtIndex:2] isEqual:@"ID"] && [[tagArr lastObject] isEqual:@"CH"]) {
				strLevel = [tagArr objectAtIndex:6];
			}
			else {
				strItem = nil;
			}
		}
		else 
		{
			strItem = nil;
		}
        
        if (strLevel != nil)
        {
            //if ([self.safeStringReplace objectForKey:strLevel])
            //    strLevel = [self.safeStringReplace objectForKey:strLevel];
            NSString * safeString = [FlatFileString stringToSafe:strLevel tag:@"LE"];
            [dict setObject:safeString forKey:@"styleName"];
            [dict setObject:[NSNumber numberWithUnsignedInt:[self getLevelIndex:safeString]] forKey:@"level"];
            [dict setObject:safeString forKey:@"levelName"];
            fontGroup = [self fontGroupFromStyle:safeString];

            NSString * font = [self fontNameFromStyle:safeString];
            if (font)
            {
                NSMutableSet * fonts = [dict objectForKey:@"fonts"];
                if (fonts == nil)
                {
                    fonts = [[NSMutableSet alloc] init];
                    [dict setObject:fonts forKey:@"fonts"];
                }
                [fonts addObject:font];
            }
        }
	}
	else if ([str isEqual:@"LV"])
	{
        NSString * paraName = [tagArr objectAtIndex:2];
        //if ([self.safeStringReplace objectForKey:paraName]) {
        //    paraName = [self.safeStringReplace objectForKey:paraName];
        //}
		NSString * safeString = [FlatFileString stringToSafe:paraName tag:@"LE"];
        
        NSMutableDictionary * dict = [self currentRecord];
        [dict setObject:safeString forKey:@"levelName"];
        fontGroup = [self fontGroupFromStyle:safeString];
        [self.currentPlain appendFormat:@"<LV:\"%@\">", safeString];
        
        
        NSString * font = [self fontNameFromStyle:safeString];
        if (font)
        {
            NSMutableSet * fonts = [[self currentRecord] objectForKey:@"fonts"];
            if (fonts == nil)
            {
                fonts = [[NSMutableSet alloc] init];
                [[self currentRecord] setObject:fonts forKey:@"fonts"];
            }
            [fonts addObject:font];
        }
	}
	else if ([str isEqual:@"SD"]) {
		if (count == 1 || [[tagArr objectAtIndex:2] isEqual:@"NO"])
		{
		}
		else {
			//NSMutableDictionary * dict = [[NSMutableDictionary alloc] initWithCapacity:2];
			//int i = 2;
			//[GPTagHelper readColor:tagArr withPrefix:@"value" index:&i target:dict];
			//if ([dict objectForKey:@"value"])
				//[self.currentFormat appendFormat:@"background-color:%@;", [dict objectForKey:@"value"]];
			//[dict release];
		}
	}
	else if ([str isEqual:@"ST"]) {
		NSMutableDictionary * obj = [NSMutableDictionary dictionaryWithCapacity:5];
		NSMutableDictionary * form = [NSMutableDictionary dictionaryWithCapacity:10];
        NSString * paraName = [tagArr objectAtIndex:2];
        [obj setValue:paraName forKey:@"originalName"];
        if ([self.safeStringReplace objectForKey:paraName]) {
            paraName = [self.safeStringReplace objectForKey:paraName];
        }
        [obj setValue:paraName forKey:@"substitutedName"];
        NSString * name = [FlatFileString stringToSafe:paraName tag:[tagArr objectAtIndex:4]];
		[GPTagHelper readCharFormating:tagArr target:form];
		[obj setValue:form forKey:@"format"];
		[obj setValue:str forKey:@"cat"];
		[obj setValue:name forKey:@"name"];
		[temparrStyles addObject:obj];
	}
	else if ([str isEqual:@"PD"]) {
		NSMutableDictionary * obj = [NSMutableDictionary dictionaryWithCapacity:5];
		NSMutableDictionary * form = [NSMutableDictionary dictionaryWithCapacity:10];
        NSString * paraName = [tagArr objectAtIndex:2];
        [obj setValue:paraName forKey:@"originalName"];
        if ([self.safeStringReplace objectForKey:paraName]) {
            paraName = [self.safeStringReplace objectForKey:paraName];
        }
        [obj setValue:paraName forKey:@"substitutedName"];
        NSString * name = [FlatFileString stringToSafe:paraName tag:str];
		[GPTagHelper readCharFormating:tagArr target:form];
		[obj setValue:form forKey:@"format"];
		[obj setValue:str forKey:@"cat"];
		[obj setValue:name forKey:@"name"];
		[temparrStyles addObject:obj];
	}
	else if ([str isEqual:@"SP"]) {
	}
	else if ([str isEqual:@"SB"]) {
	}
	else if ([str isEqual:@"/SS"]) {
	}
	else if ([str isEqual:@"TB"]) {
	}
	else if ([str isEqual:@"TA"]) {
        [GPDebugger writeTag:str text:[GPDebugger fileLocationPlain]];
	}
	else if ([str isEqual:@"CE"]) {
	}
	else if ([str isEqual:@"/CE"]) {

	}
	else if ([str isEqual:@"/TA"])
	{

	}
	else if ([str isEqual:@"TT"]) {
        
        [self.fileInfo appendFormat:@"TT=%@\n", [tagArr objectAtIndex:2]];
        fprintf(fileTableDocinfo, "%s\t%s\t%ld\n", "TT", [[tagArr objectAtIndex:2] UTF8String], 0L);

		NSDate *today = [NSDate date];
		NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
		NSDateComponents * ts =
		[gregorian components:(NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit 
							   | NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:today];
		NSString * dateTimeStamp = [NSString stringWithFormat:@"%ld.%02ld%02ld.%02ld%02ld",
									[ts year], [ts month], [ts day], [ts hour], [ts minute]];

        fprintf(fileTableDocinfo, "%s\t%s\t%ld\n", "BUILD", [dateTimeStamp UTF8String], 0L);
        
		dateTimeStamp = [NSString stringWithFormat:@"%02ld/%02ld %ld %02ld:%02ld",
									[ts month], [ts day], [ts year], [ts hour], [ts minute]];

        fprintf(fileTableDocinfo, "%s\t%s\t%ld\n", "DATE", [dateTimeStamp UTF8String], 0L);
	}
	else {
		NSLog(@"--------------------------------------------------\nUnrecognized tag: %@\n", tagArr);
	}

}


-(void)acceptChar:(NSInteger)rfChar
{
	if (commentText)
		return;
	
    NSInteger convertedChar = 0;
    
    if (fontGroup == VBFB_FONTGROUP_SANSKRIT)
    {
        convertedChar = [VBFolioBuilder sanskritTimesToUnicode:rfChar];
    }
    else if (fontGroup == VBFB_FONTGROUP_BALARAM)
    {
        convertedChar = [VBFolioBuilder balaramToUnicode:rfChar];
    }
    else if (fontGroup == VBFB_FONTGROUP_WINDGDINGS)
    {
        convertedChar = [VBFolioBuilder wingdingsToUnicode:rfChar];
    }
    else if (fontGroup == VBFB_FONTGROUP_BENGALI)
    {
        convertedChar = [VBFolioBuilder bengaliToUnicode:rfChar];
    }
    else if (fontGroup == VBFB_FONTGROUP_DEVANAGARI) 
    {
        convertedChar = rfChar;
    }

    NSMutableString * target = bCharToBuff ? strBuff : self.currentPlain;

    if (convertedChar == '<')
        [target appendString:@"<<"];
    else
        [target appendFormat:@"%C", (unichar)convertedChar];

}

-(void)saveStylesExamples
{
    int i = 0;
//    NSMutableString * strStyles = [[NSMutableString alloc] init];
    NSMutableSet * exported = [[NSMutableSet alloc] init];
    NSMutableString * examples = [[NSMutableString alloc] init];
//    NSMutableDictionary * refaStyle = [[NSMutableDictionary alloc] init];
    [examples appendString:@"<html><head><title>Styles Examples</title><link href=\"styles.css\" type=text/css rel=stylesheet></head><body><h1><a href=\"by-font/index.html\">Fonts</a> | Styles</h1><p><table border=1>\n"];
    for(i = 0; i < [temparrStyles count]; i++)
    {
        NSDictionary * dict = [temparrStyles objectAtIndex:i];
        if (!dict)
            continue;

        NSString * styleName = [dict objectForKey:@"name"];
        if ([exported containsObject:styleName])
            continue;
        
        GPMutableInteger * counter = [self.paraUsageCounter objectForKey:styleName];
        if (counter.value == 0)
            continue;
        
        [examples appendFormat:@"<tr><td width=200px><a href=\"./by-style/%@.html\">%@</a></td><td>%ld</td><td><p class=\"%@\">Lorem ipsum textum examples<br>haribol - Hare Rama this is some example of some dummy text, but what can be done?</p></td></tr>\n", styleName, styleName, counter.value, styleName];
        [exported addObject:styleName];
    }
    
    // finishing examples
    [examples appendString:@"</table></body></html>\n"];
    
    [examples writeToFile:[[[GPDebugger instance] workingDirectory] stringByAppendingPathComponent:  @"example-styles.html"]
               atomically:YES
                 encoding:NSASCIIStringEncoding
                    error:NULL];
}

-(void)cleaningStyles
{
    NSDictionary * dict;
    NSString * newValue;
	for(int i = 0; i < [temparrStyles count]; i++)
	{
		dict = [temparrStyles objectAtIndex:i];
		if (dict)
		{
			NSMutableDictionary * dictFormat = [dict objectForKey:@"format"];
			if (dictFormat && [dictFormat count] > 0)
			{
				NSString * fontName = [dictFormat objectForKey:@"font-family"];
				if (fontName != nil)
				{
                    NSInteger myFontGroup = [self fontGroupFromFontName:fontName];
                    if (myFontGroup == VBFB_FONTGROUP_BALARAM) {
                        newValue = @"Times";
                    } else {
                        newValue = fontName;
                    }
					//newValue = [GPTagHelper substitutionFontName:fontName];
					if ([newValue isEqualToString:@"Times"] || [newValue isEqualToString:@"Helvetica"]) {
						[dictFormat removeObjectForKey:@"font-family"];
                    } else {
                        [dictFormat setObject:newValue forKey:@"font-family"];
                        if (myFontGroup == VBFB_FONTGROUP_BALARAM) {
                            NSLog(@"Font in Styles - %@", newValue);
                        }
                    }
				}
                
                NSString * textAlign = [dictFormat objectForKey:@"text-align"];
                if (textAlign && ([textAlign isEqualToString:@"left"] || [textAlign isEqualToString:@"justify"]))
                {
                    [dictFormat removeObjectForKey:@"text-align"];
                }
                
                NSString * fontSize = [dictFormat objectForKey:@"font-size"];
                if (fontSize != nil)
                {
                    int size = 0;
                    if ([fontSize hasSuffix:@"pt"])
                    {
                        size = [[fontSize substringToIndex:[fontSize length] - 2] intValue];
                        if (size > 0)
                        {
                            if (size == 14) {
                                [dictFormat removeObjectForKey:@"font-size"];
                            } else {
                                newValue = [NSString stringWithFormat:@"%d%%", size*100/14];
                                [dictFormat setObject:newValue forKey:@"font-size"];
                                if ([dictFormat valueForKey:@"line-height"] == nil)
                                {
                                    [dictFormat setValue:@"120%" forKey:@"line-height"];
                                }
                            }
                        }
                        else
                        {
                            NSLog(@"font size = %@, size = %d", fontSize, size);
                        }
                    }
                    else
                    {
                        NSLog(@"font size = %@, size = %d", fontSize, size);
                    }
                }
			}
		}
	}
}

-(void)saveStylesObject
{
    int i;
    NSEnumerator * enumerator = nil;
    NSString * key = nil;
    NSString * value = nil;
    NSMutableSet * exported = [[NSMutableSet alloc] init];
    NSMutableString * strStyles = [[NSMutableString alloc] init];

    [self cleaningStyles];
    
    [self saveStylesExamples];
    
    NSLog(@"started Generating Styles");
	for(i = 0; i < [temparrStyles count]; i++)
	{
		NSDictionary * dict = [temparrStyles objectAtIndex:i];
		if (dict)
		{
            NSString * styleName = [dict objectForKey:@"name"];
            if ([exported containsObject:styleName])
                continue;
            
            fprintf(fileTableStyles, "%d\t%s\n", (i+1), [styleName UTF8String]);

			NSMutableDictionary * dictFormat = [dict objectForKey:@"format"];
			if (dictFormat && [dictFormat count] > 0)
			{
                [exported addObject:styleName];
                enumerator = [dictFormat keyEnumerator];
                
                [strStyles appendFormat:@".%@ {\n", styleName];
                while ((key = [enumerator nextObject]) != nil)
                {
                    value = [dictFormat objectForKey:key];
                    fprintf(fileTableStylesDetail, "%d\t%s\t%s\n", (i+1), [key UTF8String], [value UTF8String]);
                    NSRange rang = [value rangeOfCharacterFromSet:whiteSpaces];
                    if (rang.location == NSNotFound)
                    {
                        [strStyles appendFormat:@"  %@:%@;\n",key,value];
                    }
                    else
                    {
                        [strStyles appendFormat:@"  %@:\"%@\";\n",key,value];
                    }
                }
                [strStyles appendFormat:@"}\n"];
			}
		}
	}
    NSLog(@"done Generating Styles");

    [GPDebugger writeFile:@"styles.css" text:strStyles];
    //[self.storage startTransaction];
    //[self.storage insertObject:[strStyles dataUsingEncoding:NSASCIIStringEncoding] name:@"styles.css" type:@"text/css"];
    //[self.storage endTransaction];
}

-(void)saveAllPopups
{
    for (NSDictionary * d in notes)
    {
        NSString * fullParaText = [d objectForKey:@"plain"];
        NSString * className = [d objectForKey:@"className"];
        NSString * strTitle = [d objectForKey:@"title"];
        
        fprintf(fileTablePopup, "%s\t%s\t%s\n", [strTitle UTF8String], [className UTF8String], [fullParaText UTF8String]);
    }
    NSLog(@"Done - Saving Popups");
}

-(void)saveDebugRecord:(NSDictionary *)d htmlString:(HtmlString *)target
{
    NSString * plain = [d objectForKey:@"plain"];
    
    [GPDebugger writeText:plain
                    style:[d valueForKey:@"styleName"]
               dictionary:d];
}

-(void)saveAllRecords
{
    HtmlString * target = [[HtmlString alloc] init];
    
    int rangeMax = [records count];
    int rangeLength = 1000;
    for( int rangeStart = 0; rangeStart < rangeMax; rangeStart += rangeLength)
    {
        @autoreleasepool {
            for (int rangeCursor = 0; rangeCursor < rangeLength; rangeCursor++)
            {
                if (rangeCursor + rangeStart >= rangeMax)
                    break;
                NSDictionary * d = [records objectAtIndex:(rangeCursor + rangeStart)];
                NSString * levelName = [d objectForKey:@"levelName"];
                
                [self saveDebugRecord:d htmlString:target];
            }
        }
    }
    NSLog(@"Done - Saving Records");
}

-(void)saveFolio
{
    [self saveStylesObject];
    
    [self saveAllRecords];
    
    [self saveAllPopups];
    
    NSEnumerator * ge = [self.groupMap keyEnumerator];
    NSString * key;
    while((key = [ge nextObject]) != nil)
    {
        fprintf(self->fileTableGroupsMap, "%s\t%ld\n", [key UTF8String], [self.groupMap idForKey:key]);
    }
    
}

-(void)acceptEnd
{
    NSLog(@"OK End of import");
	[self recordDidEndRead];
    definedObjects = nil;
    
}

-(void)closeDumpFiles
{
    [self closeDumpFile: &fileTableDocinfo];
    [self closeDumpFile: &fileTableTexts];
    [self closeDumpFile: &fileTableObjects];
    [self closeDumpFile: &fileTableGroups];
    [self closeDumpFile: &fileTableGroupsMap];
    [self closeDumpFile: &fileTableLevels];
    [self closeDumpFile: &fileTablePopup];
    [self closeDumpFile: &fileTableJumplinks];
    [self closeDumpFile: &fileTableStyles];
    [self closeDumpFile: &fileTableStylesDetail];
}


-(FILE *)openDumpFile:(NSString *)fileName debugger:(GPDebugger *)debugger
{
    return fopen([[debugger.dumpDirectory stringByAppendingPathComponent:fileName] UTF8String], "wt");
}

-(void)closeDumpFile:(FILE **)pfile
{
    if (*pfile)
    {
        fclose(*pfile);
    }
    *pfile = NULL;
}

-(void)acceptStart
{
    self.requestedFileName = nil;
	temparrStyles = [[NSMutableArray alloc] initWithCapacity:1000];
	/*NSMutableDictionary * obj = [NSMutableDictionary dictionaryWithCapacity:3];
	NSMutableDictionary * form = [NSMutableDictionary dictionaryWithCapacity:3];
	[form setValue:@"Times" forKey:@"font-family"];
	[form setValue:@"14pt" forKey:@"font-size"];
	[obj setValue:form forKey:@"format"];
	[obj setValue:@"DF" forKey:@"cat"];
	[obj setValue:@"iFolio-Default-Body" forKey:@"name"];
	[temparrStyles addObject:obj];*/
    definedObjects = [[NSMutableDictionary alloc] init];
    contentArray = [[NSMutableArray alloc] init];
    [contentTaggedItems removeAllObjects];
    
    NSLog(@"Started - Folio Building");
	tagCount = 0;
    strCurrentPlain = nil;
    inclusionPathIndex = 1;
    self.linkTagStarted = NO;
    NSString * tBuild = [NSString stringWithFormat:@"%ld", time(NULL)];
    
    [self.fileInfo appendFormat:@"TBUILD=%@\n", tBuild];

    GPDebugger * debugger = [GPDebugger instance];
    fileTableDocinfo = [self openDumpFile:@"docinfo.txt" debugger:debugger];
    fileTableTexts = [self openDumpFile:@"texts.txt" debugger:debugger];
    fileTableObjects = [self openDumpFile:@"objects.txt" debugger:debugger];
    self->fileTableGroups = [self openDumpFile:@"groups_detail.txt" debugger:debugger];
    self->fileTableGroupsMap = [self openDumpFile:@"groups.txt" debugger:debugger];
    fileTableLevels = [self openDumpFile:@"levels.txt" debugger:debugger];
    fileTablePopup = [self openDumpFile:@"popup.txt" debugger:debugger];
    fileTableJumplinks = [self openDumpFile:@"jumplinks.txt" debugger:debugger];
    fileTableStyles = [self openDumpFile:@"styles.txt" debugger:debugger];
    fileTableStylesDetail = [self openDumpFile:@"styles_detail.txt" debugger:debugger];

    fprintf(fileTableDocinfo, "%s\t%s\t%ld\n", "TBUILD", [tBuild UTF8String], 0L);

}


#pragma mark -
#pragma mark Helper Functions

-(void)logTagArray:(NSArray *)arrParts
{
	NSMutableString * str = [[NSMutableString alloc] initWithCapacity:100];
	for(NSString * s in arrParts)
	{
		[str appendFormat:@"%@ ", s];
	}
	NSLog(@"==[TAG_ARRAY]==\n %@", str);
}

-(void)removeLastTailFromPlain
{
    if ([self.currentPlain length] > 0)
    {
        if ([self.currentPlain hasSuffix:@","] || [self.currentPlain hasSuffix:@";"] ||
            [self.currentPlain hasSuffix:@"."] || [self.currentPlain hasSuffix:@":"] ||
            [self.currentPlain hasSuffix:@"?"] || [self.currentPlain hasSuffix:@"!"])
        {
            NSRange aran;
            aran.location = [self.currentPlain length] - 1;
            aran.length = 1;
            [self.currentPlain deleteCharactersInRange:aran];
        }
	}
    
}

+(NSInteger)balaramToOemSize:(NSInteger)uniChar
{
	static NSInteger mconv[] = 
	{ 
		0,    1,   2,   3,  4,   5,   6,   7,   8,   9,  10,  11,  12,  13,  14,  15,
		16,  17,  18,  19, 20,  21,  22,  23,  24,  25,  26,  27,  28,  29,  30,  31,
		32,  32,  32,  32, 32,  32,  32,  32,  32,  32,  32,  32,  32,  32,  46,  32,
		48,  49,  50,  51, 52,  53,  54,  55,  56,  57,  32,  32,  32,  32,  32,  32,
		32,  65,  66,  67, 68,  69,  70,  71,  72,  73,  74,  75,  76,  77,  78,  79,
		80,  81,  82,  83, 84,  85,  86,  87,  88,  89,  90,  32,  32,  32,  32,  32,
		32,  97,  98,  99,100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111,
		112,113, 114, 115,116, 117, 118, 119, 120, 121, 122,  32,  32,  32,  32,  32,
		32,  32,  32,  32,  32,  32,  32,  32,  32,  32,  32,  32, 32,  32,  32,  32,
		32,  32,  32,  32,  32,  32,  32,  32,  32,  32,  32,  32,  32,  32,  32,  32,
		32,  32,  32,  32,  32,  32,  32,  32,  32,  32,  97,  32, 105,  32,  32,  32,
		32,  32,  32,  32,  32,  32,  32,  32,  32,  32, 117,  32,  32,  32,  32,  32,
		109, 97,  97,  97,  97, 114,  32, 115, 117, 105, 101, 110, 110, 105, 111, 110,
		100, 115, 100, 111,  97, 111, 116,  32,  32, 104, 117,  32,117, 121, 32,  108,
		109,  97,  97,  97,  97, 114,  32, 115, 114, 105,  32, 110, 110, 105,  32, 110,
		32, 115, 100, 111,  32, 111, 116,  32,  32, 104, 117, 108, 117, 121,  32, 108,
		0,   0,   0,   0
	};
	
	if (uniChar < 0 || uniChar > 255)
		return 32;
	return mconv[uniChar];
	
}

+(NSInteger)sanskritTimesToUnicode:(NSInteger)uniChar
{
	static NSInteger mconv[] = 
	{
		 257, 7693, 0x201a, 7717, 0x201e, 299, 7735, 108, 7745, 7749, 7751, 0x2039, 0x152, 7771, 7773, 347, 7779,
		0x2018, 0x2019, 0x201c, 0x201d, 0x2022, 0x2013, 0x2014, 7789, 363, 256, 0x203a, 0x153, 7692, 7716, 298,
		160, 161, 7734, 163, 7744, 7748, 7750, 167, 168, 169, 170, 171, 7770, 7772, 346, 175, 176,
		7778, 178, 179, 180, 7788, 362, 183, 184, 185, 186, 187, 188, 189, 190, 191
	};
	
	if (uniChar < 128) return uniChar;
	if (uniChar > 191) return uniChar;
	
	return mconv[uniChar - 128];
}

+(NSInteger)bengaliToUnicode:(NSInteger)uniChar
{
    if (uniChar < 33)
        return uniChar;
	return 0xf000 + uniChar;
}

+(NSInteger)wingdingsToUnicode:(NSInteger)uniChar
{
    if (uniChar == '\\') {
        return 0x0950;
    } if (uniChar == 167) {
        return 0x25fe;
    } else if (uniChar == 10 || uniChar == 13) {
        return ' ';
    } else if (uniChar == 74) {
        return 0x263a;
    }
    NSLog(@"Wingdings char used: %ld", uniChar);
    return ' ';
}

+(NSInteger)balaramToUnicode:(NSInteger)uniChar
{
	static NSInteger mconv[] = 
	{ 
		128, 129, 0x201a, 0x192, 0x201e, 0x2026, 0x2020, 0x2021, 136, 0x2030, 138, 0x2039, 0x152, 141, 142, 143,
		144, 0x2018, 0x2019, 0x201c, 0x201d, 0x2022, 0x2013, 0x2014, 152, 153, 154, 0x203a, 0x153, 157, 158, 159,
		160, 161, 162, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175,
		176, 177, 178, 179, 180, 181, 182, 0x2219, 184, 0x131, 186, 187, 188, 189, 190, 191,
		7744, //192
		193, //193
		194, //194
		195, //195
		256, //196
		7770, //197
		198, //198
		346, //199
		7772, //200
		298, //201
		202, //202
		7750, //203
		7748, //204
		205, //205
		206, //206
		209, //207
		208, //208
		7778, //209
		7692, //210
		211, //211
		212, //212
		213, //213
		7788, //214
		215, //215
		216, //216
		7716, //217
		218, //218
		219, //219
		362, //220
		221, //221
		222, //222
		7734, //223
		7745, //224
		225, //225
		226, //226
		227, //227
		257, //228
		7771, //229
		230, //230
		347, //231
		7773, //232
		299, //233
		234, //234
		7751, //235
		7749, //236
		237, //237
		238, //238
		241, //239
		240, //240
		7779, //241
		7693, //242
		243, //243
		244, //244
		245, //245
		7789, //246
		247, //247
		248, //248
		7717, //249
		250, //250
		7737, //251
		363, //252
		253, //253
		254, //254
		7735, //255
		
	};


	if (uniChar < 128)
		return uniChar;
	if (uniChar > 255)
		return 32;
	return mconv[uniChar - 128];
	
}

#pragma mark -
#pragma mark Managing Text within Paragraph

-(void)restoreCurrentTarget
{
	//[self finishHtmlText];
    [recordStack removeLastObject];
    if ([self currentClassDefined])
    {
        fontGroup = [self fontGroupFromStyle:[self currentClass]];
    }
}

#pragma mark -
#pragma mark Paragraph Managemenet 


-(NSMutableDictionary *)recordWillStartRead:(NSString *)strType
{
	flagSub = NO;
	flagSup = NO;
	flagSpan = NO;
	
    NSDictionary * dictionary = [recordStack lastObject];
    NSString * lastType = [dictionary valueForKey:@"type"];

    // ends current paragraph
    if ([recordStack lastObject] != nil)
    {
        if ([strType isEqualToString:@"RD"])
        {
            // previous record should be finished
            [self recordDidEndRead];
        }
	}

    NSMutableDictionary * dict = [[NSMutableDictionary alloc] init];

    [dict setObject:strType forKey:@"type"];
    
    NSMutableString * newParaText = [[NSMutableString alloc] init];
    [dict setObject:newParaText forKey:@"plain"];

    if ([strType compare:@"RD"] == NSOrderedSame)
    {
        [records addObject:dict];

        currentRecordID++;
        [dict setObject:[NSNumber numberWithUnsignedInt:currentRecordID] forKey:@"id"];
        
        [recordStack removeAllObjects];
        [recordStack addObject:dict];
        
    }
    else if ([strType compare:@"DP"] == NSOrderedSame) {
        [notes addObject:dict];

        /*<DP:Width,Height,"Title"> . . . </DP>*/
		//self.currentNoteID++;
        //[dict setObject:[NSNumber numberWithUnsignedInt:self.currentNoteID] forKey:@"id"];
        
        [recordStack addObject:dict];
    }
    else if ([strType compare:@"PW"] == NSOrderedSame) {
        [notes addObject:dict];
        [recordStack addObject:dict];
        /*<PW:Style Name,Width,Height,"Title">
         .
         .	(Popup Window Text)
         .
         <LT>
         .
         .	(Link Text)
         .
         </PW>*/
        /*<PX:Style,"Title"> . . . </PX>*/
    }
    else {
        [recordStack addObject:dict];
    }

    [dict setObject:[GPDebugger fileLocation] forKey:@"fileLoc"];
    if ([records count] > 100) {
        while([records count] > 5)
        {
            NSDictionary * d = [records objectAtIndex:0];
            [self saveDebugRecord:d htmlString:self.targetHtmlRec];
            [records removeObjectAtIndex:0];
        }

    }

	return dict;
}

//
// save record to file foTxMain
//
-(void)recordDidEndRead
{
    NSDictionary * d = [self currentRecord];
    NSString * styleName = [d objectForKey:@"styleName"];
    NSString * levelName = [d objectForKey:@"levelName"];

    fprintf(fileTableTexts, "%d\t%s\t%s\t%s\n",
              [[d objectForKey:@"id"] unsignedIntValue],
              [[d objectForKey:@"plain"] UTF8String],
              (levelName ? [levelName UTF8String] : ""),
              (styleName ? [styleName UTF8String] : ""));
    
    if (currentRecordID % 20000 == 0)
    {
        NSLog(@"Record %d", currentRecordID);
    }

}

#pragma mark -
#pragma mark getter functions

-(NSMutableDictionary *)currentRecord
{
    return (NSMutableDictionary *)[recordStack lastObject];
}

-(BOOL)currentClassDefined
{
    id format = [[self currentRecord] objectForKey:@"className"];
    return format != nil;
}

-(NSMutableString *)currentPlain
{
    NSMutableDictionary * dict = [recordStack lastObject];
    if (dict == nil)
        return nil;
    NSString * key = [dict valueForKey:@"_plainFlow"];
    if (key == nil)
        key = @"plain";
    NSMutableString * str = [dict objectForKey:key];
    if (str == nil)
    {
        str = [[NSMutableString alloc] init];
        [dict setObject:str forKey:key];
    }
    return str;
}

-(NSString *)currentRecordType
{
    return [[recordStack lastObject] objectForKey:@"type"];
}

-(NSMutableString *)currentClass
{
    NSMutableDictionary * dict = (NSMutableDictionary *)[recordStack lastObject];
    NSMutableString * text = [dict objectForKey:@"className"];
    if (text == nil)
    {
        text = [[NSMutableString alloc] init];
        [dict setObject:text forKey:@"className"];
    }
    
    return text;
}

-(NSMutableString *)currentLevel
{
    NSMutableDictionary * dict = (NSMutableDictionary *)[recordStack lastObject];
    NSMutableString * text = [dict objectForKey:@"levelName"];
    if (text == nil)
    {
        text = [[NSMutableString alloc] init];
        [dict setObject:text forKey:@"levelName"];
    }
    
    return text;
}

-(uint32_t)getCurrStyleIndex:(NSMutableDictionary *)rec
{
    NSString * obj = [rec objectForKey:@"levelName"];
    if (obj)
        return [self getStyleIndex:obj];

	obj = [rec objectForKey:@"className"];
	return [self getStyleIndex:obj];
	
}

-(uint32_t)getStyleIndex:(NSString *)styleName
{
	for(int i = 0; i < [temparrStyles count]; i++)
	{
		NSDictionary * dict = [temparrStyles objectAtIndex:i];
		if (dict)
		{
			NSString * strName = [dict objectForKey:@"name"];
			if ([strName compare:styleName] == 0)
			{
				return i;
			}
		}
	}

    return (uint32_t)-1;
}

-(NSUInteger)getLevelIndex:(NSString *)levelName
{
	if (levelName == nil || [levelName length] == 0)
		return NSNotFound;
	
    for(NSDictionary * dict in self.levels)
    {
        if ([[dict objectForKey:@"safe"] compare:levelName options:NSCaseInsensitiveSearch] == NSOrderedSame)
        {
            return [[dict objectForKey:@"index"] unsignedIntValue];
        }
    }
    return NSNotFound;
}

+(NSString *)htmlTextToOEMHtmlText:(NSString *)origHtmlText
{
	NSData * oemedData = [origHtmlText dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
	NSString * oemedText = [[NSString alloc] initWithData:oemedData encoding:NSASCIIStringEncoding];
	return oemedText;
}



@end
