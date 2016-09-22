//
//  OLStripeWrapper.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 22/09/2016.
//  Copyright © 2016 Kite.ly. All rights reserved.
//

#import "OLStripeWrapper.h"

@implementation OLStripeWrapper

+ (id)initSTPAPIClientWithPublishableKey:(NSString *)key{
    Class STPAPIClientClass = NSClassFromString(@"STPAPIClient");
    id client = [STPAPIClientClass alloc];
    
    SEL aSelector = NSSelectorFromString(@"initWithPublishableKey:");
    IMP imp = [client methodForSelector:aSelector];
    id (*func)(id, SEL, id) = (void *)imp;
    
    client = func(client, aSelector, key);
    return client;
}

+ (void)client:(id)client createTokenWithPayment:payment completion:(void(^)(id token, NSError *error))handler{
    SEL aSelector = NSSelectorFromString(@"createTokenWithPayment:completion:");
    IMP imp = [client methodForSelector:aSelector];
    id (*func)(id, SEL, id, id) = (void *)imp;
    
    func(client, aSelector, payment, handler);
}

+ (NSString *)tokenIdFromToken:(id)token{
    SEL aSelector = NSSelectorFromString(@"tokenId");
    IMP imp = [token methodForSelector:aSelector];
    id (*func)(id, SEL) = (void *)imp;
    
    return func(token, aSelector);
}

+ (void)setDefaultPublishableKey:(NSString *)key{
    Class StripeClass = NSClassFromString(@"Stripe");
    
    SEL aSelector = NSSelectorFromString(@"setDefaultPublishableKey:");
    IMP imp = [StripeClass methodForSelector:aSelector];
    id (*func)(id, SEL, id) = (void *)imp;
    
    func(StripeClass, aSelector, key);
}

@end
