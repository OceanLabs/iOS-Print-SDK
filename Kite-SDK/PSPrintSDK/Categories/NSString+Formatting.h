//
//  NSString+Formatting.h
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 2/18/15.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Formatting)

+ (NSString *)stringByTrimmingSpecialCharacters:(NSString *)input;
+ (NSString *)stringByFormattingCreditCardExpiry:(NSString *)input;
+ (NSString *)stringByFormattingCreditCardNumber:(NSString *)input;
+ (NSString *)stringByURLEncoding:(NSString *)string;

@end
