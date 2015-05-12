//
//  OLPaymentLineItemPercentage.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 5/12/15.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import "OLPaymentLineItemPercentage.h"

static NSString *const kKeyLineItemJob = @"co.oceanlabs.kKeyLineItemJob";

@implementation OLPaymentLineItemPercentage

- (NSDecimalNumber *)price{
    if (self.printJob && self.currencyCode){
        return [self.value decimalNumberByMultiplyingBy:[self.printJob costInCurrency:self.currencyCode]];
    }
    else{
        return [super price];
    }
}

#pragma mark - NSCoding protocol methods

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.printJob forKey:kKeyLineItemJob];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        self.printJob = [aDecoder decodeObjectForKey:kKeyLineItemJob];
    }
    
    return self;
}

@end
