//
//  OLCheckPromoCodeRequest.h
//  Kite SDK
//
//  Created by Deon Botha on 12/02/2014.
//  Copyright (c) 2014 Deon Botha. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^OLCheckPromoCodeCompletionHandler)(NSDecimalNumber *discount, NSError *error);

@class OLPrintOrder;

@interface OLCheckPromoCodeRequest : NSObject

- (void)checkPromoCode:(NSString *)promoCode withOrder:(OLPrintOrder *)order andCompletionHandler:(OLCheckPromoCodeCompletionHandler)handler;
- (void)cancel;

@end
