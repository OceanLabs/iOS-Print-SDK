//
//  OLCheckPromoCodeRequest.m
//  Kite SDK
//
//  Created by Deon Botha on 12/02/2014.
//  Copyright (c) 2014 Deon Botha. All rights reserved.
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

@interface OLKitePrintSDK (Private)

+ (NSString *)apiEndpoint;
+ (NSString *)apiVersion;

@end

static NSString *urlencode(NSString *str) {
    NSMutableString *output = [NSMutableString string];
    const unsigned char *source = (const unsigned char *)[str UTF8String];
    int sourceLen = (int) strlen((const char *)source);
    for (int i = 0; i < sourceLen; ++i) {
        const unsigned char thisChar = source[i];
        if (thisChar == ' ') {
            [output appendString:@"+"];
        } else if (thisChar == '.' || thisChar == '-' || thisChar == '_' || thisChar == '~' ||
                   (thisChar >= 'a' && thisChar <= 'z') ||
                   (thisChar >= 'A' && thisChar <= 'Z') ||
                   (thisChar >= '0' && thisChar <= '9')) {
            [output appendFormat:@"%c", thisChar];
        } else {
            [output appendFormat:@"%%%02X", thisChar];
        }
    }
    return output;
}

static NSDictionary *cachedResponse; // we cache the last response
static NSDate *cacheDate;
static NSUInteger cacheOrderHash; // cached response is only valid for orders with this hash

@interface OLPrintOrderCostRequest ()
@property (nonatomic, strong) OLBaseRequest *req;

@end

@implementation OLPrintOrderCostRequest

- (NSString *)stringFromOrder:(OLPrintOrder *)order {
    NSString *basketString = @"";
    for (id<OLPrintJob> job in order.jobs){
        if (job.address){
            basketString = [basketString stringByAppendingString:[NSString stringWithFormat:@"%@:%d:%@,", [job templateId], (int)[job quantity] * (int)([job extraCopies]+1), job.address.country.codeAlpha3]];
        }
        else{
            basketString = [basketString stringByAppendingString:[NSString stringWithFormat:@"%@:%d,", [job templateId], (int)[job quantity] * (int)([job extraCopies]+1)]];
        }
    }
    basketString = [basketString stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@","]];

    NSDictionary *dict = @{@"basket" : basketString,
                           @"shipping_country_code" : order.shippingAddress.country ? [order.shippingAddress.country codeAlpha3] : [[OLCountry countryForCurrentLocale] codeAlpha3],
                           @"promo_code" : order.promoCode ? urlencode(order.promoCode) : @""
                           };
    
    NSDictionary *extraDict = [order.userData objectForKey:@"extra_dict_for_cost"];
    if (extraDict && [extraDict isKindOfClass:[NSDictionary class]]){
        dict = [dict mutableCopy];
        [dict setValue:[extraDict objectForKey:[[extraDict allKeys] firstObject]] forKey:[[extraDict allKeys] firstObject]];
    }

    NSString *orderString = @"";
    for (NSString *key in [dict allKeys]){
        orderString = [orderString stringByAppendingString:[NSString stringWithFormat:@"%@=%@&", key, [dict objectForKey:key]]];
    }
    orderString = [orderString stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"&"]];
    return orderString;
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
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/price/?%@", [OLKitePrintSDK apiEndpoint], [OLKitePrintSDK apiVersion], [self stringFromOrder:order]]];
    
    self.req = [[OLBaseRequest alloc] initWithURL:url httpMethod:kOLHTTPMethodGET headers:headers body:nil];
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
            handler(nil, [NSError errorWithDomain:kOLKiteSDKErrorDomain code:kOLKiteSDKErrorCodeServerFault userInfo:@{NSLocalizedDescriptionKey: NSLocalizedStringFromTableInBundle(@"Failed to get the price of the order. Please try again.", @"KitePrintSDK", [OLConstants bundle], @"")}]);
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
    NSInteger idx = 0;
    for (NSDictionary *lineItemDict in json[@"line_items"]){
        NSDictionary *productCosts = [self createCostsDictionaryFromJSON:lineItemDict[@"product_cost"]];
        NSDictionary *shippingCosts = [self createCostsDictionaryFromJSON:lineItemDict[@"shipping_cost"]];
        NSString *description = lineItemDict[@"description"];
        OLPaymentLineItem * item = [[OLPaymentLineItem alloc] initWithDescription:description costs:productCosts];
        [lineItems addObject:item];
        
        OLProductPrintJob *job = order.jobs[idx];
        [jobCosts setObject:@{@"product_cost" : productCosts, @"shipping_cost" : shippingCosts} forKey:job];
        idx++;
    }

    NSDictionary *totalCosts = [self createCostsDictionaryFromJSON:json[@"total"]];
    NSDictionary *totalShippingCosts = [self createCostsDictionaryFromJSON:json[@"total_shipping_cost"]];
    
    OLPaymentLineItem *shippingItem = [[OLPaymentLineItem alloc] initWithDescription:NSLocalizedString(@"Shipping", @"") costs:totalShippingCosts];
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
            OLPaymentLineItem *discountItem = [[OLPaymentLineItem alloc] initWithDescription:NSLocalizedString(@"Promotional Discount", @"") costs:[self makeAllDiscountValuesNegative: discount]];
            [lineItems addObject:discountItem];
            break;
        }
    }
    
    OLPrintOrderCost *orderCost = [[OLPrintOrderCost alloc] initWithTotalCosts:totalCosts shippingCosts:totalShippingCosts jobCosts:jobCosts lineItems:lineItems promoDiscount:discount promoCodeInvalidReason:promoDiscountInvalidReason];
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
