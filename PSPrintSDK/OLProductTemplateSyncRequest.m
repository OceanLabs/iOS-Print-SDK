//
//  OLTemplateSyncRequest.m
//  PS SDK
//
//  Created by Deon Botha on 18/03/2014.
//  Copyright (c) 2014 Deon Botha. All rights reserved.
//

#import "OLProductTemplateSyncRequest.h"
#import "OLBaseRequest.h"
#import "OLPSPrintSDK.h"
#import "OLProductTemplate.h"
#import "OLConstants.h"

@interface OLProductTemplateSyncRequest ()
@property (nonatomic, strong) OLBaseRequest *req;
@end

@implementation OLProductTemplateSyncRequest

- (void)sync:(OLTemplateSyncRequestCompletionHandler)handler {
    NSAssert(self.req == nil, @"Oops only one template sync request should be in progress at any given time");
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/v1.1/template/", [OLPSPrintSDK apiEndpoint]]];
    [self fetchTemplatesWithURL:url templateAccumulator:[[NSMutableArray alloc] init] handler:handler];
}

- (void)fetchTemplatesWithURL:(NSURL *)url templateAccumulator:(NSMutableArray *)acc handler:(OLTemplateSyncRequestCompletionHandler)handler {
    NSDictionary *headers = @{@"Authorization": [NSString stringWithFormat:@"ApiKey %@:", [OLPSPrintSDK apiKey]]};
    self.req = [[OLBaseRequest alloc] initWithURL:url httpMethod:kOLHTTPMethodGET headers:headers body:nil];
    [self.req startWithCompletionHandler:^(NSInteger httpStatusCode, id json, NSError *error) {
        if (error) {
            self.req = nil;
            handler(nil, error);
        } else {
            if (httpStatusCode >= 200 & httpStatusCode <= 299) {
                NSURL *nextPage = nil;
                id meta = json[@"meta"];
                if ([meta isKindOfClass:[NSDictionary class]]) {
                    id next = meta[@"next"];
                    if ([next isKindOfClass:[NSString class]]) {
                        nextPage = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", [OLPSPrintSDK apiEndpoint], next]];
                    }
                }
                
                id objects = json[@"objects"];
                if ([objects isKindOfClass:[NSArray class]]) {
                    for (id template in objects) {
                        if ([template isKindOfClass:[NSDictionary class]]) {
                            id name = template[@"name"];
                            id identifier = template[@"template_id"];
                            id costs = template[@"cost"];
                            id imagesPerSheet = template[@"images_per_page"];
                            NSNumber *enabledNumber = template[@"enabled"];
                            BOOL enabled = enabledNumber == nil ? YES : [enabledNumber boolValue];
                            
                            if ([name isKindOfClass:[NSString class]]
                                && [identifier isKindOfClass:[NSString class]]
                                && [costs isKindOfClass:[NSArray class]]
                                && (imagesPerSheet == nil || [imagesPerSheet isKindOfClass:[NSNumber class]])) {
                            
                                NSMutableDictionary *costPerSheetByCurrencyCode = [[NSMutableDictionary alloc] init];
                                for (id cost in costs) {
                                    if ([cost isKindOfClass:[NSDictionary class]]) {
                                        id currencyCode = cost[@"currency"];
                                        id amount = cost[@"amount"];
                                        if ([currencyCode isKindOfClass:[NSString class]] && [amount isKindOfClass:[NSString class]]) {
                                            costPerSheetByCurrencyCode[currencyCode] = [NSDecimalNumber decimalNumberWithString:amount];
                                        }
                                    }
                                }
                                
                                if (costPerSheetByCurrencyCode.count > 0) {
                                    OLProductTemplate *t = [[OLProductTemplate alloc] initWithIdentifier:identifier name:name quantity:[imagesPerSheet unsignedIntegerValue] costsByCurrencyCode:costPerSheetByCurrencyCode enabled:enabled];
                                    [acc addObject:t];
                                }
                            }
                        }
                    }
                }
                
                if (nextPage != nil) {
                    [self fetchTemplatesWithURL:nextPage templateAccumulator:acc handler:handler];
                } else {
                    self.req = nil;
                    handler(acc, nil);
                }
            } else {
                id errorObj = json[@"error"];
                if ([errorObj isKindOfClass:[NSDictionary class]]) {
                    id errorMessage = errorObj[@"message"];
                    if ([errorMessage isKindOfClass:[NSString class]]) {
                        NSError *error = [NSError errorWithDomain:kOLPSSDKErrorDomain code:kOLPSSDKErrorCodeServerFault userInfo:@{NSLocalizedDescriptionKey:errorMessage}];
                        handler(nil, error);
                        return;
                    }
                }
                
                handler(nil, [NSError errorWithDomain:kOLPSSDKErrorDomain code:kOLPSSDKErrorCodeServerFault userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Failed to synchronize product templates. Please try again.", @"")}]);
            }
        }
    }];
}

- (void)cancel {
    [self.req cancel];
    self.req = nil;
}

@end
