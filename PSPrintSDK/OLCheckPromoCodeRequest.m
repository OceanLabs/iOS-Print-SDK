//
//  OLCheckPromoCodeRequest.m
//  Kite SDK
//
//  Created by Deon Botha on 12/02/2014.
//  Copyright (c) 2014 Deon Botha. All rights reserved.
//

#import "OLCheckPromoCodeRequest.h"
#import "OLBaseRequest.h"
#import "OLConstants.h"
#import "OLKitePrintSDK.h"
#import "OLPrintJob.h"
#import "OLPrintOrder.h"

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

@interface OLCheckPromoCodeRequest ()
@property (nonatomic, strong) OLBaseRequest *req;
@end

@implementation OLCheckPromoCodeRequest

- (void)checkPromoCode:(NSString *)promoCode withOrder:(OLPrintOrder *)order andCompletionHandler:(OLCheckPromoCodeCompletionHandler)handler {
    NSAssert(self.req == nil, @"only one check promo code request can be in progress at a time");
    
    NSString *currencyCode = order.currencyCode;
    NSMutableString *templateCostBreakdown = [[NSMutableString alloc] init];
    for (id<OLPrintJob> job in order.jobs) {
        if (templateCostBreakdown.length > 0) {
            [templateCostBreakdown appendFormat:@","];
        }
        [templateCostBreakdown appendFormat:@"%@:%@", job.templateId, [job costInCurrency:currencyCode]];
    }
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/v1.1/promo_code/check?code=%@&templates=%@&currency=%@", [OLKitePrintSDK apiEndpoint], urlencode(promoCode), templateCostBreakdown, order.currencyCode]];
    NSDictionary *headers = @{@"Authorization": [NSString stringWithFormat:@"ApiKey %@:", [OLKitePrintSDK apiKey]]};
    
    self.req = [[OLBaseRequest alloc] initWithURL:url httpMethod:kOLHTTPMethodGET headers:headers body:nil];
    [self.req startWithCompletionHandler:^(NSInteger httpStatusCode, id json, NSError *error) {
        if (error) {
            handler(nil, error);
        } else {
            id discountNum = json[@"discount"];
            if ([discountNum isKindOfClass:[NSNumber class]]) {
                NSDecimalNumber *discount = [NSDecimalNumber decimalNumberWithString:[discountNum stringValue]];
                handler(discount, nil);
            } else {
                id errorObj = json[@"error"];
                if ([errorObj isKindOfClass:[NSDictionary class]]) {
                    id errorMessage = errorObj[@"message"];
                    if ([errorMessage isKindOfClass:[NSString class]]) {
                        NSError *error = [NSError errorWithDomain:kOLKiteSDKErrorDomain code:kOLKiteSDKErrorCodeServerFault userInfo:@{NSLocalizedDescriptionKey:errorMessage}];
                        handler(nil, error);
                        return;
                    }
                }
                
                handler(nil, [NSError errorWithDomain:kOLKiteSDKErrorDomain code:kOLKiteSDKErrorCodeServerFault userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Failed to validate your promo code. Please try again.", @"")}]);
            }
        }
    }];
}

- (void)cancel {
    [self.req cancel];
    self.req = nil;
}

@end
