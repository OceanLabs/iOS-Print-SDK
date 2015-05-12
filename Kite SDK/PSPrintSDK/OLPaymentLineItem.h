//
//  OLPaymentLineItem.h
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 5/12/15.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OLPaymentLineItem : NSObject

@property (strong, nonatomic) NSDecimalNumber *value;
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *currencyCode;

- (NSDecimalNumber *)price;
- (NSString *)priceString;

@end
