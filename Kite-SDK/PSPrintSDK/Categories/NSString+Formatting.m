//
//  NSString+Formatting.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 2/18/15.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import "NSString+Formatting.h"

@implementation NSString (Formatting)

+ (NSString *)stringByTrimmingSpecialCharacters:(NSString *)input {
    NSCharacterSet *special = [NSCharacterSet characterSetWithCharactersInString:@"/+-() "];
    return [[input componentsSeparatedByCharactersInSet:special] componentsJoinedByString:@""];
}

+ (NSString *)stringByFormattingCreditCardExpiry:(NSString *)input {
    input = [NSString stringByTrimmingSpecialCharacters:input];
    switch (input.length) {
        case 0:
            return @"";
        case 1:
            if ([input isEqualToString:@"0"] || [input isEqualToString:@"1"]) {
                return input;
            }
            
            input = [@"0" stringByAppendingString:input];
        default:
            return [[NSString stringWithFormat:@"%@/%@", [input substringToIndex:2], [input substringFromIndex:2]] substringToIndex:MIN(input.length + 1, 5)];
    }
}

+ (NSString *)stringByFormattingCreditCardNumber:(NSString *)input{
    input = [NSString stringByTrimmingSpecialCharacters:input];
    NSString *result = @"";
    NSUInteger i = 0;
    while (i < input.length && i < 16){
        NSString *substring = [input substringFromIndex:i];
        result = [result stringByAppendingString:[NSString stringWithFormat:@"%@ ", [substring substringToIndex:MIN(4, substring.length)]]];
        i += 4;
    }
    return [result stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]];
}

/* This code is adapted from the code by David DeLong in this StackOverflow post:
 http://stackoverflow.com/questions/3423545/objective-c-iphone-percent-encode-a-string .  It is protected under the terms of a Creative Commons
 license: http://creativecommons.org/licenses/by-sa/3.0/
 */
+ (NSString *)stringByURLEncoding:(NSString *)string {
    NSMutableString *output = [NSMutableString string];
    const unsigned char *source = (const unsigned char *)[string UTF8String];
    NSInteger sourceLen = strlen((const char *)source);
    for (int i = 0; i < sourceLen; ++i) {
        const unsigned char thisChar = source[i];
        if (thisChar == ' ') {
            [output appendString:@"+"];
        } else if (thisChar == '.' || thisChar == '-' || thisChar == '_' || thisChar == '~' || (thisChar >= 'a' && thisChar <= 'z') ||
                   (thisChar >= 'A' && thisChar <= 'Z') || (thisChar >= '0' && thisChar <= '9')) {
            [output appendFormat:@"%c", thisChar];
        } else {
            [output appendFormat:@"%%%02X", thisChar];
        }
    }
    return output;
}

@end
