//
//  Modified MIT License
//
//  Copyright (c) 2010-2017 Kite Tech Ltd. https://www.kite.ly
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

#import "OLPayPalWrapper.h"

@implementation OLPayPalWrapper

+ (id)payPalShippingAddressWithRecipientName:(NSString *)name withLine1:(NSString *)line1 withLine2:(NSString *)line2 withCity:(NSString *)city withState:(NSString *)state withPostalCode:(NSString *)postalCode withCountryCode:(NSString *)countryCode{
    Class PayPalShippingAddressClass = NSClassFromString(@"PayPalShippingAddress");
    
    SEL aSelector = NSSelectorFromString(@"shippingAddressWithRecipientName:withLine1:withLine2:withCity:withState:withPostalCode:withCountryCode:");
    IMP imp = [PayPalShippingAddressClass methodForSelector:aSelector];
    id (*func)(id, SEL, id, id, id, id, id, id, id) = (void *)imp;
    
    id shippingAddress = func(PayPalShippingAddressClass, aSelector, name, line1, line2, city, state, postalCode, countryCode);
    return shippingAddress;
}

+ (id)payPalPaymentWithAmount:(NSDecimalNumber *)amount currencyCode:(NSString *)currencyCode shortDescription:(NSString *)shortDescription intent:(NSInteger)intent shippingAddress:(id)shippingAddress{
    Class PayPalPaymentClass = NSClassFromString(@"PayPalPayment");
    id payment = [[PayPalPaymentClass alloc] init];
    
    SEL aSelector = NSSelectorFromString(@"setAmount:");
    IMP imp = [payment methodForSelector:aSelector];
    void (*func)(id, SEL, id) = (void *)imp;
    func(payment, aSelector, amount);
    
    aSelector = NSSelectorFromString(@"setCurrencyCode:");
    imp = [payment methodForSelector:aSelector];
    func = (void *)imp;
    func(payment, aSelector, currencyCode);

    aSelector = NSSelectorFromString(@"setShortDescription:");
    imp = [payment methodForSelector:aSelector];
    func = (void *)imp;
    func(payment, aSelector, shortDescription);
    
    aSelector = NSSelectorFromString(@"setIntent:");
    imp = [payment methodForSelector:aSelector];
    void (*func1)(id, SEL, NSInteger) = (void *)imp;
    func1(payment, aSelector, intent);
    
    aSelector = NSSelectorFromString(@"setShippingAddress:");
    imp = [payment methodForSelector:aSelector];
    func = (void *)imp;
    func(payment, aSelector, shippingAddress);
    
#ifdef DEBUG
    aSelector = NSSelectorFromString(@"processable");
    imp = [payment methodForSelector:aSelector];
    BOOL (*func2)(id, SEL) = (void *)imp;
    NSAssert(func2(payment, aSelector), @"oops, payment not processable");
#endif
    
    return payment;
}

+ (id)payPalConfigurationWithShippingAddressOption:(NSInteger)option acceptCreditCards:(BOOL)acceptCCs{
    Class payPalConfigurationClass = NSClassFromString(@"PayPalConfiguration");
    id config = [[payPalConfigurationClass alloc] init];
    
    SEL aSelector = NSSelectorFromString(@"setAcceptCreditCards:");
    IMP imp = [config methodForSelector:aSelector];
    void (*func)(id, SEL, BOOL) = (void *)imp;
    func(config, aSelector, acceptCCs);
    
    aSelector = NSSelectorFromString(@"setPayPalShippingAddressOption:");
    imp = [config methodForSelector:aSelector];
    void (*func1)(id, SEL, NSInteger) = (void *)imp;
    func1(config, aSelector, option);
    
    return config;
}

+ (id)payPalPaymentViewControllerWithPayment:(id)payment
                               configuration:(id)configuration
                                    delegate:(id)delegate{
    Class payPalPaymentViewControllerClass = NSClassFromString(@"PayPalPaymentViewController");
    id payPalPaymentViewController = [payPalPaymentViewControllerClass alloc];
    
    SEL aSelector = NSSelectorFromString(@"initWithPayment:configuration:delegate:");
    IMP imp = [payPalPaymentViewController methodForSelector:aSelector];
    id (*func)(id, SEL, id, id, id) = (void *)imp;
    
    payPalPaymentViewController = func(payPalPaymentViewController, aSelector, payment, configuration, delegate);
    return payPalPaymentViewController;
}

+ (NSDictionary *)confirmationWithPayment:(id)payment{
    SEL aSelector = NSSelectorFromString(@"confirmation");
    IMP imp = [payment methodForSelector:aSelector];
    id (*func)(id, SEL) = (void *)imp;
    
    return func(payment, aSelector);
}

+ (void)initializeWithClientIdsForEnvironments:(NSDictionary *)dict{
    Class PayPalMobileClass = NSClassFromString(@"PayPalMobile");
    
    SEL aSelector = NSSelectorFromString(@"initializeWithClientIdsForEnvironments:");
    IMP imp = [PayPalMobileClass methodForSelector:aSelector];
    void (*func)(id, SEL, id) = (void *)imp;
    
    func(PayPalMobileClass, aSelector, dict);
}

+ (void)preconnectWithEnvironment:(NSString *)env{
    Class PayPalMobileClass = NSClassFromString(@"PayPalMobile");
    
    SEL aSelector = NSSelectorFromString(@"preconnectWithEnvironment:");
    IMP imp = [PayPalMobileClass methodForSelector:aSelector];
    void (*func)(id, SEL, id) = (void *)imp;
    
    func(PayPalMobileClass, aSelector, env);
}

+ (BOOL)isPayPalAvailable{
    Class PayPalMobileClass = NSClassFromString(@"PayPalMobile");
    if (![PayPalMobileClass class]){
        return NO;
    }
    
    Class PayPalShippingAddressClass = NSClassFromString(@"PayPalShippingAddress");
    if (![PayPalShippingAddressClass class]){
        NSLog(@"Warning: PayPal API version mismatch.");
        return NO;
    }
    SEL aSelector = NSSelectorFromString(@"shippingAddressWithRecipientName:withLine1:withLine2:withCity:withState:withPostalCode:withCountryCode:");
    if (![PayPalShippingAddressClass respondsToSelector:aSelector]){
        NSLog(@"Warning: PayPal API version mismatch.");
        return NO;
    }
    
    Class PayPalPaymentClass = NSClassFromString(@"PayPalPayment");
    if (![PayPalPaymentClass class]){
        NSLog(@"Warning: PayPal API version mismatch.");
        return NO;
    }
    for (NSString *s in @[@"setAmount:", @"setCurrencyCode:", @"setShortDescription:", @"setIntent:", @"setShippingAddress:", @"processable"]){
        aSelector = NSSelectorFromString(s);
        if (![PayPalPaymentClass instancesRespondToSelector:aSelector]){
            NSLog(@"Warning: PayPal API version mismatch.");
            return NO;
        }
    }
    
    Class payPalConfigurationClass = NSClassFromString(@"PayPalConfiguration");
    if (![payPalConfigurationClass class]){
        NSLog(@"Warning: PayPal API version mismatch.");
        return NO;
    }
    for (NSString *s in @[@"setAcceptCreditCards:", @"setPayPalShippingAddressOption:"]){
        aSelector = NSSelectorFromString(s);
        if (![payPalConfigurationClass instancesRespondToSelector:aSelector]){
            NSLog(@"Warning: PayPal API version mismatch.");
            return NO;
        }
    }
    
    Class payPalPaymentViewControllerClass = NSClassFromString(@"PayPalPaymentViewController");
    if (![payPalPaymentViewControllerClass class]){
        NSLog(@"Warning: PayPal API version mismatch.");
        return NO;
    }
    aSelector = NSSelectorFromString(@"initWithPayment:configuration:delegate:");
    if (![payPalPaymentViewControllerClass instancesRespondToSelector:aSelector]){
        NSLog(@"Warning: PayPal API version mismatch.");
        return NO;
    }
    
    return YES;
}

@end
