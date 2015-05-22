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

- (instancetype) initWithName:(NSString *)name cost:(NSDecimalNumber *)cost{
    if (self = [super init]){
        _name = name;
        _cost = cost;
    }
    
    return self;
}

- (NSString *)costString{
    if ([[self cost] isEqualToNumber:@0]){
        return NSLocalizedString(@"FREE", @"");
    }
    else{
        if (!self.currencyCode || [self.currencyCode isEqualToString:@""]){
            return [[self cost] description];
        }
        
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
        [formatter setCurrencyCode:self.currencyCode];
        return [formatter stringFromNumber:[self cost]];
    }
}

#pragma mark - NSCoding protocol methods

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.name forKey:kKeyLineItemName];
    [aCoder encodeObject:self.cost forKey:kKeyLineItemValue];
    [aCoder encodeObject:self.currencyCode forKey:kKeyLineItemCurrencyCode];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.name = [aDecoder decodeObjectForKey:kKeyLineItemName];
        self.cost = [aDecoder decodeObjectForKey:kKeyLineItemValue];
        self.currencyCode = [aDecoder decodeObjectForKey:kKeyLineItemCurrencyCode];
    }
    
    return self;
}

@end
