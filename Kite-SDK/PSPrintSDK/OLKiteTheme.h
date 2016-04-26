//
//  OLKiteTheme.h
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 25/04/16.
//  Copyright © 2016 Kite.ly. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OLKiteTheme : NSObject

@property (strong, nonatomic) NSURL *secretReveal;
@property (strong, nonatomic) NSURL *shippingOption1;
@property (strong, nonatomic) NSURL *shippingOption2;
@property (strong, nonatomic) NSURL *termsAndConditions;
@property (strong, nonatomic) NSURL *privacyPolicy;
@property (strong, nonatomic) NSURL *startScreen;
@property (strong, nonatomic) NSURL *splashScreen;
@property (strong, nonatomic) NSURL *navigationIcon;
@property (strong, nonatomic) NSURL *burgerMenuHeader;
@property (strong, nonatomic) NSURL *endSessionButton;
@property (strong, nonatomic) NSURL *receiptLogo;
@property (strong, nonatomic) NSString *ctaColor;
@property (assign, nonatomic) BOOL kioskEnablePayAtTheTill;
@property (assign, nonatomic) BOOL kioskEnableShipToStore;

@end
