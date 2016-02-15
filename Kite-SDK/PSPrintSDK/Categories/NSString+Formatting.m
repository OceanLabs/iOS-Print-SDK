//
//  Modified MIT License
//
//  Copyright (c) 2010-2015 Kite Tech Ltd. https://www.kite.ly
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The software MAY ONLY be used with the Kite Tech Ltd platform and MAY NOT be modified
//  to be used with any competitor platforms. This means the software MAY NOT be modified
//  to place orders with any competitors to Kite Tech Ltd, all orders MUST go through the
//  Kite Tech Ltd platform servers.
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
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
