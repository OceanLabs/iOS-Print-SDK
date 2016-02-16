//
//  Modified MIT License
//
//  Copyright (c) 2010-2016 Kite Tech Ltd. https://www.kite.ly
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The software MAY ONLY be used with the Kite Tech Ltd platform and MAY NOT be modified
//  to be used with any competitor platforms. This means the software MAY NOT be modified
//  to place orders with any competitors to Kite Tech Ltd, all orders MUST go through the
//  Kite Tech Ltd platform servers.
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
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
        return NSLocalizedString(@"Free", @"");
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
