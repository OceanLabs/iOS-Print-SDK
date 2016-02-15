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

#import "OLPrintOrderCost.h"

static NSString *const kKeyTotalCosts = @"ly.kite.iossdk.kKeyTotalCosts";
static NSString *const kKeyShippingCosts = @"ly.kite.iossdk.kKeyShippingCosts";
static NSString *const kKeyLineItems = @"ly.kite.iossdk.kKeyLineItems";
static NSString *const kKeyJobCosts = @"ly.kite.iossdk.kKeyJobCosts";
static NSString *const kKeyPromoCodeInvalidReason = @"ly.kite.iossdk.kKeyPromoCodeInvalidReason";
static NSString *const kKeyPromoDiscount = @"ly.kite.iossdk.kKeyPromoDiscount";

@interface OLPrintOrderCost ()
@property (nonatomic, strong) NSDictionary *jobCosts;
@property (nonatomic, strong) NSDictionary *shippingCosts;
@property (nonatomic, strong) NSDictionary *totalCosts;
@property (nonatomic, strong) NSDictionary *promoDiscount;
@end

@interface OLDecimalNumberBehavior : NSObject <NSDecimalNumberBehaviors>

@end

@implementation OLDecimalNumberBehavior

- (NSRoundingMode)roundingMode{
    return NSRoundPlain;
}

- (short)scale{
    return 2;
}

- (NSDecimalNumber *)exceptionDuringOperation:(SEL)operation error:(NSCalculationError)error leftOperand:(NSDecimalNumber *)leftOperand rightOperand:(NSDecimalNumber *)rightOperand{
    if (error != NSCalculationDivideByZero){
        return nil;
    }
    else{
        NSException* exception = [NSException
                                  exceptionWithName:@"DivideByZeroException"
                                  reason:@"Attempted to divide a number by zero."
                                  userInfo:nil];
        @throw exception;
    }
}

@end


@implementation OLPrintOrderCost

- (id)initWithTotalCosts:(NSDictionary/*<String, NSDecimalNumber>*/ *)totalCosts
           shippingCosts:(NSDictionary/*<String, NSDecimalNumber>*/ *)shippingCosts
                jobCosts:(NSDictionary *)jobCosts lineItems:(NSArray *)lineItems
           promoDiscount:(NSDictionary *)promoDiscount
  promoCodeInvalidReason:(NSString *)invalidReason {
    if (self = [super init]) {
        _totalCosts = totalCosts;
        _shippingCosts = shippingCosts;
        _jobCosts = jobCosts;
        _lineItems = lineItems;
        _promoDiscount = promoDiscount;
        _promoCodeInvalidReason = invalidReason;
    }
    
    return self;
}

- (NSDecimalNumber *)costForJob:(id<OLPrintJob>)job inCurrency:(NSString *)currencyCode {
    NSDictionary *costs = [self.jobCosts objectForKey:job];
    return costs[@"product_cost"][currencyCode];
}

- (NSDecimalNumber *)shippingCostForJob:(id<OLPrintJob>)job inCurrency:(NSString *)currencyCode {
    NSDictionary *costs = [self.jobCosts objectForKey:job];
    return costs[@"shipping_cost"][currencyCode];
}

- (NSDecimalNumber *)promoCodeDiscountInCurrency:(NSString *)currencyCode {
    NSDecimalNumber *discount = self.promoDiscount[currencyCode];
    return discount == nil ? [NSDecimalNumber zero] : discount;
}

- (NSDecimalNumber *)totalCostInCurrency:(NSString *)currencyCode {
    if ([self.totalCosts.allKeys containsObject:currencyCode]){
        return [[self.totalCosts objectForKey:currencyCode] decimalNumberByRoundingAccordingToBehavior:[[OLDecimalNumberBehavior alloc] init]];
    }
    
    return nil;
}

- (NSDecimalNumber *)shippingCostInCurrency:(NSString *)currencyCode {
    return [self.shippingCosts objectForKey:currencyCode];
}

#pragma mark - NSCopying protocol

- (id)copyWithZone:(NSZone *)zone{
    // Absolute hack but simple code, archive then unarchive copy :) Slower than doing it properly but still fast enough!
    return [NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:self]];
}

#pragma mark - NSCoding protocol

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.totalCosts forKey:kKeyTotalCosts];
    [aCoder encodeObject:self.shippingCosts forKey:kKeyShippingCosts];
    [aCoder encodeObject:self.lineItems forKey:kKeyLineItems];
    [aCoder encodeObject:self.jobCosts forKey:kKeyJobCosts];
    [aCoder encodeObject:self.promoDiscount forKey:kKeyPromoDiscount];
    [aCoder encodeObject:self.promoCodeInvalidReason forKey:kKeyPromoCodeInvalidReason];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        _totalCosts = [aDecoder decodeObjectForKey:kKeyTotalCosts];
        _shippingCosts = [aDecoder decodeObjectForKey:kKeyShippingCosts];
        _lineItems = [aDecoder decodeObjectForKey:kKeyLineItems];
        _jobCosts = [aDecoder decodeObjectForKey:kKeyJobCosts];
        _promoDiscount = [aDecoder decodeObjectForKey:kKeyPromoDiscount];
        _promoCodeInvalidReason = [aDecoder decodeObjectForKey:kKeyPromoCodeInvalidReason];
    }
    
    return self;
}

@end
