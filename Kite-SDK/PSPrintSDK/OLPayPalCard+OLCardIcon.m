//
//  OLPayPalCard+OLCardIcon.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 31/05/16.
//  Copyright © 2016 Kite.ly. All rights reserved.
//

#import "OLPayPalCard+OLCardIcon.h"
#import "OLLuhn.h"
#import "UIImage+ImageNamedInKiteBundle.h"

@implementation OLPayPalCard (OLCardIcon)

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
    return [[self number] isValidCreditCardNumber];
}

@end
