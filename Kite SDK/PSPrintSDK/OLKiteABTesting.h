//
//  OLKiteABTesting.h
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 14/7/15.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OLKiteABTesting : NSObject

@property (assign, nonatomic) BOOL skipHomeScreen;

@property (assign, nonatomic) BOOL offerAddressSearch;
@property (assign, nonatomic) BOOL requirePhoneNumber;
@property (assign, nonatomic) BOOL hidePrice;
@property (assign, nonatomic) BOOL offerPayPal;
@property (strong, nonatomic) NSString *qualityBannerType;
@property (strong, nonatomic) NSString *checkoutScreenType;
@property (strong, nonatomic) NSString *productTileStyle;
@property (strong, nonatomic) NSString *promoBannerText;
@property (strong, nonatomic) NSString *launchWithPrintOrderVariant;

+ (instancetype)sharedInstance;
- (void)fetchRemotePlistsWithCompletionHandler:(void(^)())handler;

@end
