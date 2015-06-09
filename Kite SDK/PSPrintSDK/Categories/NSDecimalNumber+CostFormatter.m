//
//  NSDecimalNumber+CostFormatter.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 6/3/15.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import "NSDecimalNumber+CostFormatter.h"


@implementation NSDecimalNumber (CostFormatter)

- (NSString *)formatCostForCurrencyCode:(NSString *)currencyCode{
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [formatter setCurrencyCode:currencyCode];
    return [formatter stringFromNumber:self];
}

@end
