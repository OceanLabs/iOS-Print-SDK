//
//  OLPaymentLineItem.h
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 5/12/15.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OLPaymentLineItem : NSObject <NSCoding>

@property (readonly, copy) NSString *description;

- (instancetype) initWithDescription:(NSString *)description
                               costs:(NSDictionary/*<NSString, NSDecimalNumber>*/ *)costs;

- (NSDecimalNumber *)costInCurrency:(NSString *)currencyCode;
- (NSString *)costStringInCurrency:(NSString *)currencyCode;

@end
