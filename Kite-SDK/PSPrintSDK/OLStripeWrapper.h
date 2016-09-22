//
//  OLStripeWrapper.h
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 22/09/2016.
//  Copyright © 2016 Kite.ly. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OLStripeWrapper : NSObject

+ (id)initSTPAPIClientWithPublishableKey:(NSString *)key;
+ (void)client:(id)client createTokenWithPayment:payment completion:(void(^)(id token, NSError *error))handler;
+ (NSString *)tokenIdFromToken:(id)token;
+ (void)setDefaultPublishableKey:(NSString *)key;

@end
