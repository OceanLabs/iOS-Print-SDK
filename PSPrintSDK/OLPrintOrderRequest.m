//
//  OLPrintPostcardRequest.m
//  PS SDK
//
//  Created by Deon Botha on 28/12/2013.
//  Copyright (c) 2013 Deon Botha. All rights reserved.
//

#import "OLPrintOrderRequest.h"
#import "OLBaseRequest.h"
#import "OLConstants.h"
#import "OLPSPrintSDK.h"
#import "OLPrintOrder.h"

@interface OLPrintOrder (FriendInterface)
@property (nonatomic, readonly) NSDictionary *jsonRepresentation;
@end


@interface OLPrintOrderRequest ()
@property (nonatomic, strong) NSDictionary *printOrderJSON;
@property (nonatomic, strong) OLBaseRequest *req;
@end

@implementation OLPrintOrderRequest

- (id)initWithPrintOrder:(OLPrintOrder *)printOrder {
    if (self = [super init]) {
        self.printOrderJSON = printOrder.jsonRepresentation;
        NSAssert([NSJSONSerialization isValidJSONObject:self.printOrderJSON], @"Please generate valid JSON for your PrintOrderJobs jsonRepresentation");
    }
    
    return self;
}

- (void)submitForPrinting {
    NSAssert(self.req == nil, @"only one print order request can be in progress at a time");
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/v1.1/print", [OLPSPrintSDK apiEndpoint]]];
    NSDictionary *headers = @{@"Authorization": [NSString stringWithFormat:@"ApiKey %@:", [OLPSPrintSDK apiKey]]};
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:self.printOrderJSON options:0 error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    self.req = [[OLBaseRequest alloc] initWithURL:url httpMethod:kOLHTTPMethodPOST headers:headers body:jsonString];
    
    [self.req startWithCompletionHandler:^(NSInteger httpStatusCode, id json, NSError *error) {
        if ((httpStatusCode < 200 || httpStatusCode > 299) && httpStatusCode != 0) { // 0 status code comes through when we didn't even get a response from the server... i.e. no network connectivity
            NSString *errorMessage = NSLocalizedString(([NSString stringWithFormat:@"Print order submission failed with a %lu HTTP response status code. Please try again.", (unsigned long) httpStatusCode]), @"");
            id responseError = [json objectForKey:@"error"];
            if ([responseError isKindOfClass:[NSDictionary class]]) {
                id responseErrorMessage = responseError[@"message"];
                if ([responseErrorMessage isKindOfClass:[NSString class]]) {
                    errorMessage = responseErrorMessage;
                }
                
                id errorCode = responseError[@"code"];
                if ([errorCode isEqualToString:@"20"]) {
                    // this error code indicates an original success response for the request. It's handy to report a success in this
                    // case as it may be that the client never received the original success response.
                    id orderId = [json objectForKey:@"print_order_id"];
                    if ([orderId isKindOfClass:[NSNumber class]]) {
                        orderId = [orderId stringValue];
                    }
                    
                    [self.delegate printOrderRequest:self didSucceedWithOrderReceiptId:orderId];
                    return;
                }
            }
            
            error = [NSError errorWithDomain:kOLPSSDKErrorDomain code:kOLPSSDKErrorCodeServerFault userInfo:@{NSLocalizedDescriptionKey: errorMessage}];
        }
        
        if (error) {
            [self.delegate printOrderRequest:self didFailWithError:error];
        } else {
            id orderId = [json objectForKey:@"print_order_id"];
            if ([orderId isKindOfClass:[NSNumber class]]) {
                orderId = [orderId stringValue];
            }
            [self.delegate printOrderRequest:self didSucceedWithOrderReceiptId:orderId];
        }
    }];
}

- (void)cancelSubmissionForPrinting {
    [self.req cancel];
    self.req = nil;
}

@end
