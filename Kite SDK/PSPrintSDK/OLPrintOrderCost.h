//
//  OLPrintOrderCost.h
//  KitePrintSDK
//
//  Created by Deon Botha on 26/05/2015.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OLPrintJob;

@interface OLPrintOrderCost : NSObject <NSCopying, NSCoding>
- (id)initWithTotalCosts:(NSDictionary/*<String, NSDecimalNumber>*/ *)totalCosts
           shippingCosts:(NSDictionary/*<String, NSDecimalNumber>*/ *)shippingCosts
                jobCosts:(NSDictionary *)jobCosts lineItems:(NSArray *)lineItems
           promoDiscount:(NSDictionary *)promoDiscount
  promoCodeInvalidReason:(NSString *)invalidReason;

@property (nonatomic, strong, readonly) NSArray/*<OLPaymentLineItem>*/ *lineItems;
@property (nonatomic, strong, readonly) NSString *promoCodeInvalidReason; // non-nil if the OLPrintOrders promo code is invalid

- (NSDecimalNumber *)costForJob:(id<OLPrintJob>)job inCurrency:(NSString *)currencyCode;
- (NSDecimalNumber *)shippingCostForJob:(id<OLPrintJob>)job inCurrency:(NSString *)currencyCode;
- (NSDecimalNumber *)totalCostInCurrency:(NSString *)currencyCode;
- (NSDecimalNumber *)shippingCostInCurrency:(NSString *)currencyCode;
- (NSDecimalNumber *)promoCodeDiscountInCurrency:(NSString *)currencyCode;
@end
