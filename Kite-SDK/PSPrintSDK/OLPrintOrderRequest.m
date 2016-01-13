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

#import "OLPrintOrderRequest.h"
#import "OLBaseRequest.h"
#import "OLConstants.h"
#import "OLKitePrintSDK.h"
#import "OLPrintOrder.h"

@interface OLPrintOrder (FriendInterface)
@property (nonatomic, readonly) NSDictionary *jsonRepresentation;
@end


@interface OLPrintOrderRequest ()
@property (nonatomic, strong) NSDictionary *printOrderJSON;
@property (nonatomic, strong) OLBaseRequest *req;
@end

@interface OLKitePrintSDK (Private)

+ (NSString *)apiEndpoint;
+ (NSString *)apiVersion;

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
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/print", [OLKitePrintSDK apiEndpoint], [OLKitePrintSDK apiVersion]]];
    NSDictionary *headers = @{@"Authorization": [NSString stringWithFormat:@"ApiKey %@:", [OLKitePrintSDK apiKey]]};
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:self.printOrderJSON options:0 error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    self.req = [[OLBaseRequest alloc] initWithURL:url httpMethod:kOLHTTPMethodPOST headers:headers body:jsonString];
    
    [self.req startWithCompletionHandler:^(NSInteger httpStatusCode, id json, NSError *error) {
        if ((httpStatusCode < 200 || httpStatusCode > 299) && httpStatusCode != 0) { // 0 status code comes through when we didn't even get a response from the server... i.e. no network connectivity
            NSString *errorMessage = ([NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Print order submission failed with a %lu HTTP response status code. Please try again.", @"KitePrintSDK", [OLConstants bundle], @""), (unsigned long) httpStatusCode]);
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
            
            error = [NSError errorWithDomain:kOLKiteSDKErrorDomain code:kOLKiteSDKErrorCodeServerFault userInfo:@{NSLocalizedDescriptionKey: errorMessage}];
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
