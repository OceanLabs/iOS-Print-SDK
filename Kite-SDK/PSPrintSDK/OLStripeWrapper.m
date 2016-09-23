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
    void (*func)(id, SEL, id) = (void *)imp;
    
    func(StripeClass, aSelector, key);
}

+ (BOOL)isStripeAvailable{
    Class StripeClass = NSClassFromString(@"Stripe");
    if (![StripeClass class]){
        return NO;
    }
    
    Class STPAPIClientClass = NSClassFromString(@"STPAPIClient");
    if (![STPAPIClientClass class]){
        NSLog(@"Warning: Stripe API version mismatch.");
        return NO;
    }
    for (NSString *s in @[@"createTokenWithPayment:completion:", @"initWithPublishableKey:"]){
        SEL aSelector = NSSelectorFromString(s);
        if (![STPAPIClientClass instancesRespondToSelector:aSelector]){
            NSLog(@"Warning: Stripe API version mismatch.");
            return NO;
        }
    }
    
    return YES;
}

@end
