//
//  OLStripeCard+OLCardIcon.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 31/05/16.
//  Copyright © 2016 Kite.ly. All rights reserved.
//

#import "OLStripeCard+OLCardIcon.h"
#import "OLLuhn.h"
#import "UIImage+ImageNamedInKiteBundle.h"

@implementation OLStripeCard (OLCardIcon)

-(UIImage *)cardIcon{
    OLCreditCardType type = [[self number] creditCardType];
    
    if (type == OLCreditCardTypeAmex){
        return [UIImage imageNamedInKiteBundle:@"amex-logo"];
    }
    else if (type == OLCreditCardTypeVisa){
        return [UIImage imageNamedInKiteBundle:@"visa-logo"];
    }
    else if(type == OLCreditCardTypeMastercard){
        return [UIImage imageNamedInKiteBundle:@"mastercard-logo"];
    }
    else{
        return [UIImage imageNamedInKiteBundle:@"credit-card-method"];
    }
}

- (BOOL)isValidCardNumber{
    OLCreditCardType type = [[self number] creditCardType];
    
    return type == OLCreditCardTypeAmex || type == OLCreditCardTypeVisa || type == OLCreditCardTypeMastercard;
}

@end
