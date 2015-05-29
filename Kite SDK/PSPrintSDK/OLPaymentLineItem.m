//
//  OLPaymentLineItem.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 5/12/15.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import "OLPaymentLineItem.h"

static NSString *const kKeyLineItemDescription = @"ly.kite.iossdk.kKeyLineItemDescription";
static NSString *const kKeyLineItemCosts = @"ly.kite.iossdk.kKeyLineItemCosts";
static NSString *const kKeyLineItemShippingCosts = @"ly.kite.iossdk.kKeyLineItemShippingCosts";

@interface OLPaymentLineItem ()
@property (nonatomic, strong) NSDictionary *costs;
@property (nonatomic, strong) NSString *itemDescription;
@end

@implementation OLPaymentLineItem

- (instancetype)initWithDescription:(NSString *)description
                              costs:(NSDictionary/*<NSString, NSDecimalNumber>*/ *)costs {
    if (self = [super init]){
        _itemDescription = description;
        _costs = costs;
    }
    
    return self;
}

- (NSString *)description {
    return self.itemDescription;
}

- (NSDecimalNumber *)costInCurrency:(NSString *)currencyCode {
    return self.costs[currencyCode];
}

- (NSString *)costStringInCurrency:(NSString *)currencyCode {
    NSDecimalNumber *cost = [self costInCurrency:currencyCode];
    if ([cost isEqualToNumber:@0]){
        return NSLocalizedString(@"FREE", @"");
    } else {
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
        [formatter setCurrencyCode:currencyCode];
        return [formatter stringFromNumber:cost];
    }
}

#pragma mark - NSCoding protocol methods

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.itemDescription forKey:kKeyLineItemDescription];
    [aCoder encodeObject:self.costs forKey:kKeyLineItemCosts];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        _itemDescription = [aDecoder decodeObjectForKey:kKeyLineItemDescription];
        _costs = [aDecoder decodeObjectForKey:kKeyLineItemCosts];
    }
    
    return self;
}

@end
