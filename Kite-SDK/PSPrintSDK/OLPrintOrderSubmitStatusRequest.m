//
//  OLPrintOrderSubmitStatusRequest.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 12/11/15.
//  Copyright © 2015 Kite.ly. All rights reserved.
//

#import "OLPrintOrderSubmitStatusRequest.h"
#import "OLKitePrintSDK.h"
#import "OLPrintOrder.h"

@interface OLKitePrintSDK (Private)

+ (NSString *)apiEndpoint;
+ (NSString *)apiVersion;

@end

@interface OLPrintOrder (Private)

@property (assign, nonatomic) OLPrintOrderSubmitStatus submitStatus;

@end

@interface OLPrintOrderSubmitStatusRequest ()

@property (strong, nonatomic) OLPrintOrder *printOrder;
@property (nonatomic, strong) OLBaseRequest *req;

@end

@implementation OLPrintOrderSubmitStatusRequest

- (id)initWithPrintOrder:(OLPrintOrder *)printOrder {
    if (self = [super init]) {
        self.printOrder = printOrder;
    }
    
    return self;
}

- (void)checkStatusWithCompletionHandler:(void(^)(OLPrintOrderSubmitStatus status, NSError *error)) handler{
    NSDictionary *headers = @{@"Authorization": [NSString stringWithFormat:@"ApiKey %@:", [OLKitePrintSDK apiKey]]};
NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/order/%@", [OLKitePrintSDK apiEndpoint], [OLKitePrintSDK apiVersion], self.printOrder.receipt]];

    self.req = [[OLBaseRequest alloc] initWithURL:url httpMethod:kOLHTTPMethodGET headers:headers body:nil];
    [self.req startWithCompletionHandler:^(NSInteger httpStatusCode, id json, NSError *error) {
        if (error) {
            self.req = nil;
            handler(self.printOrder.submitStatus, error);
            return;
        }
        
        if (httpStatusCode >= 200 & httpStatusCode <= 299) {
            self.req = nil;
            
            id errorObj = json[@"error"];
            if ([errorObj isKindOfClass:[NSDictionary class]]) {
                id errorMessage = errorObj[@"message"];
                if ([errorMessage isKindOfClass:[NSString class]]) {
                    NSError *error = [NSError errorWithDomain:kOLKiteSDKErrorDomain code:kOLKiteSDKErrorCodeOrderValidationFailed userInfo:@{NSLocalizedDescriptionKey:errorMessage}];
                    self.req = nil;
                    self.printOrder.submitStatus = OLPrintOrderSubmitStatusError;
                    self.printOrder.submitStatusErrorMessage = (NSString *)errorMessage;
                    handler(OLPrintOrderSubmitStatusError, error);
                    return;
                }
            }
            
            id status = json[@"status"];
            if ([status isKindOfClass:[NSString class]]){
                self.printOrder.submitStatus = [OLPrintOrder submitStatusFromIdentifier:status];
                handler(self.printOrder.submitStatus, nil);
                return;
            }
            
            handler(OLPrintOrderSubmitStatusUnknown, [NSError errorWithDomain:kOLKiteSDKErrorDomain code:kOLKiteSDKErrorCodeServerFault userInfo:@{NSLocalizedDescriptionKey: NSLocalizedStringFromTableInBundle(@"Failed to validate the order. Please try again.", @"KitePrintSDK", [OLConstants bundle], @"")}]);
        } else {
            id errorObj = json[@"error"];
            if ([errorObj isKindOfClass:[NSDictionary class]]) {
                id errorMessage = errorObj[@"message"];
                if ([errorMessage isKindOfClass:[NSString class]]) {
                    NSError *error = [NSError errorWithDomain:kOLKiteSDKErrorDomain code:kOLKiteSDKErrorCodeServerFault userInfo:@{NSLocalizedDescriptionKey:errorMessage}];
                    self.req = nil;
                    self.printOrder.submitStatus = OLPrintOrderSubmitStatusError;
                    self.printOrder.submitStatusErrorMessage = (NSString *)errorMessage;
                    handler(OLPrintOrderSubmitStatusError, error);
                    return;
                }
            }
            
            self.req = nil;
            handler(self.printOrder.submitStatus, [NSError errorWithDomain:kOLKiteSDKErrorDomain code:kOLKiteSDKErrorCodeServerFault userInfo:@{NSLocalizedDescriptionKey: NSLocalizedStringFromTableInBundle(@"Failed to validate the order. Please try again.", @"KitePrintSDK", [OLConstants bundle], @"")}]);
        }
    }];
}

@end
