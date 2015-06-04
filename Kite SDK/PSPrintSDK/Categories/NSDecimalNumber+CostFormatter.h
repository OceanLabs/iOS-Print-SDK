//
//  NSDecimalNumber+CostFormatter.h
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 6/3/15.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDecimalNumber (CostFormatter)

- (NSString *)formatCostForCurrencyCode:(NSString *)currencyCode;

@end
