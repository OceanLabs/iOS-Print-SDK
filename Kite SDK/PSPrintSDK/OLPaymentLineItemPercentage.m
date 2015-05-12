//
//  OLPaymentLineItemPercentage.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 5/12/15.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import "OLPaymentLineItemPercentage.h"

@implementation OLPaymentLineItemPercentage

- (NSDecimalNumber *)price{
    if (self.printJob && self.currencyCode){
        return [self.value decimalNumberByMultiplyingBy:[self.printJob costInCurrency:self.currencyCode]];
    }
    else{
        return [super price];
    }
}

@end
