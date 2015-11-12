//
//  OLPrintOrderSubmitStatusRequest.h
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 12/11/15.
//  Copyright © 2015 Kite.ly. All rights reserved.
//

#import "OLBaseRequest.h"
#import "OLPrintOrder.h"

@interface OLPrintOrderSubmitStatusRequest : NSObject
- (id)initWithPrintOrder:(OLPrintOrder *)printOrder;
- (void)checkStatusWithCompletionHandler:(void(^)(OLPrintOrderSubmitStatus status, NSError *error)) handler;

@end
