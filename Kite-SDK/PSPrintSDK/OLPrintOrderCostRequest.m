//
//  Modified MIT License
//
//  Copyright (c) 2010-2017 Kite Tech Ltd. https://www.kite.ly
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

#import "OLPrintOrderCostRequest.h"
#import "OLBaseRequest.h"
#import "OLConstants.h"
#import "OLKitePrintSDK.h"
#import "OLPrintJob.h"
#import "OLPrintOrder.h"
#import "OLPaymentLineItem.h"
#import "OLProductPrintJob.h"
#import "OLPrintOrderCost.h"
#import "NSObject+Utils.h"
#import "OLKiteUtils.h"
#import "OLPaymentViewController.h"

@interface OLKitePrintSDK (Private)

+ (NSString *)apiEndpoint;
+ (NSString *)apiVersion;

@end

@interface OLProductPrintJob ()
@property (strong, nonatomic) NSMutableSet <OLUpsellOffer *>*declinedOffers;
@property (strong, nonatomic) NSMutableSet <OLUpsellOffer *>*acceptedOffers;
@property (strong, nonatomic) OLUpsellOffer *redeemedOffer;
@property (strong, nonatomic) NSMutableDictionary *options;
@end

@interface OLPrintOrder ()
@property (assign, nonatomic) BOOL shipToStore;
@property (assign, nonatomic) BOOL payInStore;

@end

static NSDictionary *cachedResponse; // we cache the last response
static NSDate *cacheDate;
static NSUInteger cacheOrderHash; // cached response is only valid for orders with this hash

@interface OLPrintOrderCostRequest ()
@property (nonatomic, strong) OLBaseRequest *req;

@end

@interface OLPrintOrderCost ()
@property (strong, nonatomic) NSDictionary *specialTotalCosts;
@property (strong, nonatomic) NSDictionary *specialPromoDiscount;
@property (strong, nonatomic) NSString *specialPromoCodeInvalidReason;
@property (strong, nonatomic) NSString *paymentMethod;
@end

@implementation OLPrintOrderCostRequest

- (NSDictionary *)jsonFromOrder:(OLPrintOrder *)order {
    NSString *shippingCountryCode = order.shippingAddress.country ? [order.shippingAddress.country codeAlpha3] : [[OLCountry countryForCurrentLocale] codeAlpha3];
    
    NSMutableArray *basket = [[NSMutableArray alloc] initWithCapacity:order.jobs.count];
    for (id<OLPrintJob> job in order.jobs){
        [basket addObject:[[job jsonRepresentation] mutableCopy]];
    }

    NSDictionary *dict = @{@"basket" : basket,
                           @"shipping_country_code" : shippingCountryCode,
                           @"promo_code" : order.promoCode ? order.promoCode : @"",
                           @"ship_to_store" : [NSNumber numberWithBool:order.shipToStore],
                           @"pay_in_store" : [NSNumber numberWithBool:order.payInStore]
                           };
    
    NSDictionary *extraDict = [order.userData objectForKey:@"extra_dict_for_cost"];
    if (extraDict && [extraDict isKindOfClass:[NSDictionary class]]){
        dict = [dict mutableCopy];
        [dict setValue:[extraDict objectForKey:[[extraDict allKeys] firstObject]] forKey:[[extraDict allKeys] firstObject]];
    }
    
    if ([OLKiteUtils isApplePayAvailable]){
        dict = [dict mutableCopy];
        [dict setValue:@"APPLE_PAY" forKey:@"payment_gateway"];
    }

    return dict;
}

+ (NSDictionary *)cachedResponseForOrder:(OLPrintOrder *)order {
    if (cachedResponse == nil || cacheDate == nil) {
        return nil;
    }
    
    if (cacheOrderHash != order.hash) {
        return nil;
    }
    
    NSTimeInterval elapsedSecondsSinceLastCache = -[cacheDate timeIntervalSinceNow];
    if (elapsedSecondsSinceLastCache > (60 * 60)) { // if > 1hr has passed since last successful sync then cache is invalid
        cachedResponse = nil;
        cacheDate = nil;
        return nil;
    }
    
    return cachedResponse;
}

+ (void)cacheResponse:(NSDictionary *)responseJSON forOrder:(OLPrintOrder *)order {
    cachedResponse = responseJSON;
    cacheDate = [NSDate date];
    cacheOrderHash = order.hash;
}

- (void)orderCost:(OLPrintOrder *)order completionHandler:(OLPrintOrderCostRequestCompletionHandler)handler {
    NSAssert(self.req == nil, @"only one check promo code request can be in progress at a time");
    
    NSDictionary *cachedResponse = [OLPrintOrderCostRequest cachedResponseForOrder:order];
    if (cachedResponse) {
        [self order:order parseCostResponseJson:cachedResponse withCompletionHandler:handler];
        return;
    }
    
    const NSUInteger hash = order.hash;
    
    NSDictionary *headers = @{@"Authorization": [NSString stringWithFormat:@"ApiKey %@:", [OLKitePrintSDK apiKey]]};
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/price/", [OLKitePrintSDK apiEndpoint], [OLKitePrintSDK apiVersion]]];
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:[self jsonFromOrder:order] options:0 error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    self.req = [[OLBaseRequest alloc] initWithURL:url httpMethod:kOLHTTPMethodPOST headers:headers body:jsonString];
    [self.req startWithCompletionHandler:^(NSInteger httpStatusCode, id json, NSError *error) {
        if (error) {
            self.req = nil;
            handler(nil, error);
            return;
        }
        
        if (httpStatusCode >= 200 & httpStatusCode <= 299) {
            self.req = nil;
            if (order.hash != hash) {
                // user has mutated the order after trying to get cost. Changes may affect the cost so perform the request again.
                [self orderCost:order completionHandler:handler];
                return;
            }
            
            [OLPrintOrderCostRequest cacheResponse:json forOrder:order];
            [self order:order parseCostResponseJson:json withCompletionHandler:handler];
        } else {
            id errorObj = json[@"error"];
            if ([errorObj isKindOfClass:[NSDictionary class]]) {
                id errorMessage = errorObj[@"message"];
                if ([errorMessage isKindOfClass:[NSString class]]) {
                    NSError *error = [NSError errorWithDomain:kOLKiteSDKErrorDomain code:[errorObj[@"code"] integerValue] userInfo:@{NSLocalizedDescriptionKey:errorMessage}];
                    self.req = nil;
                    handler(nil, error);
                    return;
                }
            }
            
            self.req = nil;
            handler(nil, [NSError errorWithDomain:kOLKiteSDKErrorDomain code:kOLKiteSDKErrorCodeServerFault userInfo:@{NSLocalizedDescriptionKey: NSLocalizedStringFromTableInBundle(@"Failed to get the price of the order. Please try again.", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"")}]);
        }
    }];
}

- (NSDictionary *)createCostsDictionaryFromJSON:(NSDictionary *)json {
    NSMutableDictionary *costs = [[NSMutableDictionary alloc] init];
    for (NSString *currencyCode in json) {
        costs[currencyCode] = [NSDecimalNumber decimalNumberWithDecimal: [json[currencyCode] decimalValue]];
    }
    return costs;
}

- (NSDictionary *)makeAllDiscountValuesNegative:(NSDictionary *)discount {
    NSMutableDictionary *discounts = [[NSMutableDictionary alloc] init];
    for (NSString *currencyCode in discount) {
        NSDecimalNumber *val = discount[currencyCode];
        if ([val doubleValue] > 0) {
            val = [val decimalNumberByMultiplyingBy:(NSDecimalNumber *)[NSDecimalNumber numberWithInteger:-1]];
        }
        
        discounts[currencyCode] = val;
    }
    return discounts;
}

- (void)order:(OLPrintOrder *)order parseCostResponseJson:(NSDictionary *)json withCompletionHandler:(OLPrintOrderCostRequestCompletionHandler)handler {
    NSMutableArray *lineItems = [[NSMutableArray alloc] init];
    NSMutableDictionary *jobCosts = [[NSMutableDictionary alloc] init];
    for (NSDictionary *lineItemDict in json[@"line_items"]){
        NSDictionary *productCosts = [self createCostsDictionaryFromJSON:lineItemDict[@"product_cost"]];
        NSDictionary *productDiscountedCosts = [self createCostsDictionaryFromJSON:lineItemDict[@"discounted_cost"]];
        NSDictionary *shippingCosts = [self createCostsDictionaryFromJSON:lineItemDict[@"shipping_cost"]];
        NSString *description = lineItemDict[@"description"];
        OLPaymentLineItem * item = [[OLPaymentLineItem alloc] initWithDescription:description costs:productCosts];
        item.discountedCosts = productDiscountedCosts;
        [lineItems addObject:item];
        item.identifier = lineItemDict[@"job_id"];
        
        [jobCosts setObject:@{@"product_cost" : productCosts, @"shipping_cost" : shippingCosts, @"discounted_cost" : productDiscountedCosts} forKey:lineItemDict[@"job_id"]];
    }

    NSDictionary *totalCosts = [self createCostsDictionaryFromJSON:json[@"total"]];
    NSDictionary *totalShippingCosts = [self createCostsDictionaryFromJSON:json[@"total_shipping_cost"]];
    
    OLPaymentLineItem *shippingItem = [[OLPaymentLineItem alloc] initWithDescription:NSLocalizedStringFromTableInBundle(@"Shipping", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") costs:totalShippingCosts];
    [lineItems addObject:shippingItem];
    
    NSDictionary *discount = [self createCostsDictionaryFromJSON:json[@"promo_code"][@"discount"]];
    id promoDiscountInvalidReason = json[@"promo_code"][@"invalid_message"];
    if (promoDiscountInvalidReason == [NSNull null] || [promoDiscountInvalidReason stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length == 0) {
        promoDiscountInvalidReason = nil;
    }

    // if a discount exists, then add a Discount line item
    for (NSString *currencyCode in discount) {
        NSDecimalNumber *currencyDiscount = discount[currencyCode];
        if ([currencyDiscount doubleValue] != 0) {
            OLPaymentLineItem *discountItem = [[OLPaymentLineItem alloc] initWithDescription:NSLocalizedStringFromTableInBundle(@"Promotional Discount", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") costs:[self makeAllDiscountValuesNegative: discount]];
            [lineItems addObject:discountItem];
            break;
        }
    }
    
    // Parse Apple Pay special total and discount items
    NSDictionary *specialTotalCosts = [self createCostsDictionaryFromJSON:json[@"apple_pay_total"]];
    NSDictionary *specialDiscount = [self createCostsDictionaryFromJSON:json[@"apple_pay_promo_code"][@"discount"]];
    id specialPromoDiscountInvalidReason = json[@"apple_pay_promo_code"][@"invalid_message"];
    if (specialPromoDiscountInvalidReason == [NSNull null] || [specialPromoDiscountInvalidReason stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length == 0) {
        specialPromoDiscountInvalidReason = nil;
    }
    
    OLPrintOrderCost *orderCost = [[OLPrintOrderCost alloc] initWithTotalCosts:totalCosts shippingCosts:totalShippingCosts jobCosts:jobCosts lineItems:lineItems promoDiscount:discount promoCodeInvalidReason:promoDiscountInvalidReason];
    
    orderCost.specialTotalCosts = specialTotalCosts;
    orderCost.specialPromoDiscount = specialDiscount;
    orderCost.specialPromoCodeInvalidReason = specialPromoDiscountInvalidReason;
    
    handler(orderCost, nil);
}

- (void)cancel {
    [self.req cancel];
    self.req = nil;
}

- (BOOL)isInProgress {
    return self.req != nil;
}

@end
