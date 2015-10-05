//
//  OLCheckPromoCodeRequest.h
//  Kite SDK
//
//  Created by Deon Botha on 12/02/2014.
//  Copyright (c) 2014 Deon Botha. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OLPrintOrder;
@class OLPrintOrderCost;

typedef void (^OLPrintOrderCostRequestCompletionHandler)(OLPrintOrderCost *cost, NSError * error);

@interface OLPrintOrderCostRequest : NSObject

- (void)orderCost:(OLPrintOrder *)order completionHandler:(OLPrintOrderCostRequestCompletionHandler)handler;
- (void)cancel;
- (BOOL)isInProgress;

@end
