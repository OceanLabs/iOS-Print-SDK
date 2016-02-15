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

#import "OLPrintOrderSubmitStatusRequest.h"
#import "OLKitePrintSDK.h"
#import "OLPrintOrder.h"

@interface OLKitePrintSDK (Private)

+ (NSString *)apiEndpoint;
+ (NSString *)apiVersion;

@end

@interface OLPrintOrder (Private)

@property (strong, nonatomic, readwrite) NSString *submitStatusErrorMessage;
@property (assign, nonatomic, readwrite) OLPrintOrderSubmitStatus submitStatus;
@property (nonatomic, readwrite) NSString *receipt;

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
            
            id status = json[@"status"];
            
            id errorObj = json[@"error"];
            if ([errorObj isKindOfClass:[NSDictionary class]]) {
                id errorMessage = errorObj[@"message"];
                id errorCode = errorObj[@"code"];
                id successPrintId = errorObj[@"print_order_id"];
                if ([errorCode isEqualToString:@"E20"] && [successPrintId isKindOfClass:[NSString class]]){
                    self.printOrder.receipt = successPrintId;
                    status = @"Validated";
                }
                else if ([errorMessage isKindOfClass:[NSString class]]) {
                    NSError *error = [NSError errorWithDomain:kOLKiteSDKErrorDomain code:kOLKiteSDKErrorCodeOrderValidationFailed userInfo:@{NSLocalizedDescriptionKey:errorMessage}];
                    self.req = nil;
                    self.printOrder.submitStatus = OLPrintOrderSubmitStatusError;
                    self.printOrder.submitStatusErrorMessage = (NSString *)errorMessage;
                    handler(OLPrintOrderSubmitStatusError, error);
                    return;
                }
            }
            
            if ([status isKindOfClass:[NSString class]]){
                self.printOrder.submitStatus = [OLPrintOrder submitStatusFromIdentifier:status];
                self.req = nil;
                handler(self.printOrder.submitStatus, nil);
                return;
            }
            
            self.req = nil;
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
