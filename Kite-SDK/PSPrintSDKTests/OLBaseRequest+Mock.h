//
//  OLBaseRequest+Mock.h
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 20/01/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

#import "OLBaseRequest.h"

@interface OLBaseRequest (Mock)
- (void)mockTemplateStartWithCompletionHandler:(void(^)(NSInteger httpStatusCode, id json, NSError *error))handler;
- (void)mockTemplateServerErrorWithCompletionHandler:(void(^)(NSInteger httpStatusCode, id json, NSError *error))handler;
- (void)mockCostServerErrorWithCompletionHandler:(void(^)(NSInteger httpStatusCode, id json, NSError *error))handler;
- (void)mockCostRequestWithCompletionHandler:(void(^)(NSInteger httpStatusCode, id json, NSError *error))handler;
- (void)mockPrintOrderRequestWithCompletionHandler:(void(^)(NSInteger httpStatusCode, id json, NSError *error))handler;
@end
