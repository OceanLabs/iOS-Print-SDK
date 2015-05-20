//
//  OLPaymentLineItem.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 5/12/15.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import "OLPaymentLineItem.h"

static NSString *const kKeyLineItemName = @"co.oceanlabs.kKeyLineItemName";
static NSString *const kKeyLineItemValue = @"co.oceanlabs.kKeyLineItemValue";
static NSString *const kKeyLineItemCurrencyCode = @"co.oceanlabs.kKeyLineItemCurrencyCode";

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

#pragma mark - NSCoding protocol methods

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.name forKey:kKeyLineItemName];
    [aCoder encodeObject:self.value forKey:kKeyLineItemValue];
    [aCoder encodeObject:self.currencyCode forKey:kKeyLineItemCurrencyCode];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.name = [aDecoder decodeObjectForKey:kKeyLineItemName];
        self.value = [aDecoder decodeObjectForKey:kKeyLineItemValue];
        self.currencyCode = [aDecoder decodeObjectForKey:kKeyLineItemCurrencyCode];
    }
    
    return self;
}

@end
