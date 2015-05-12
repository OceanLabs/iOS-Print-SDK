//
//  OLPaymentLineItem.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 5/12/15.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import "OLPaymentLineItem.h"

@implementation OLPaymentLineItem

- (NSDecimalNumber *)price{
    return self.value;
}

- (NSString *)priceString{
    if ([[self price] isEqualToNumber:@0]){
        return NSLocalizedString(@"FREE", @"");
    }
    else{
        if (!self.currencyCode || [self.currencyCode isEqualToString:@""]){
            return [[self price] description];
        }
        
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
        [formatter setCurrencyCode:self.currencyCode];
        return [formatter stringFromNumber:[self price]];
    }
}

@end
