//
//  OLKiteABTesting.h
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 14/7/15.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString *const kOLKiteThemeHeaderLogoImageURL = @"themeLogoImageURL";
static NSString *const kOLKiteThemeCheckoutProgress1 = @"themeCheckoutProgress1";
static NSString *const kOLKiteThemeCheckoutProgress2 = @"themeCheckoutProgress2";
static NSString *const kOLKiteThemeCheckoutProgress1Bg = @"themeCheckoutProgress1Bg";
static NSString *const kOLKiteThemeCheckoutProgress2Bg = @"themeCheckoutProgress2Bg";
static NSString *const kOLKiteThemeReceiptSuccess = @"themeReceiptSuccess";
static NSString *const kOLKiteThemeReceiptFailure = @"themeReceiptFailure";
static NSString *const kOLKiteThemeReceiptSuccessBg = @"themeReceiptSuccessBg";
static NSString *const kOLKiteThemeReceiptFailureBg = @"themeReceiptFailureBg";
static NSString *const kOLKiteThemeSupportEmail = @"themeSupportEmail";

@interface OLKiteABTesting : NSObject

@property (assign, nonatomic) BOOL launchedWithPrintOrder;

@property (assign, nonatomic, readonly) BOOL offerAddressSearch;
@property (assign, nonatomic, readonly) BOOL requirePhoneNumber;
@property (assign, nonatomic, readonly) BOOL hidePrice;
@property (assign, nonatomic, readonly) BOOL offerPayPal;
@property (strong, nonatomic, readonly) NSString *qualityBannerType;
@property (strong, nonatomic, readonly) NSString *checkoutScreenType;
@property (strong, nonatomic, readonly) NSString *productTileStyle;
@property (strong, nonatomic, readonly) NSString *promoBannerText;
@property (strong, nonatomic, readonly) NSString *launchWithPrintOrderVariant;
@property (assign, nonatomic, readonly) BOOL allowsMultipleRecipients;

@property (strong, nonatomic, readonly) NSString *headerLogoURL;
@property (strong, nonatomic, readonly) NSString *checkoutProgress1URL;
@property (strong, nonatomic, readonly) NSString *checkoutProgress2URL;
@property (strong, nonatomic, readonly) NSString *checkoutProgress1BgURL;
@property (strong, nonatomic, readonly) NSString *checkoutProgress2BgURL;
@property (strong, nonatomic, readonly) NSString *receiptSuccessURL;
@property (strong, nonatomic, readonly) NSString *receiptFailureURL;
@property (strong, nonatomic, readonly) NSString *receiptSuccessBgURL;
@property (strong, nonatomic, readonly) NSString *receiptFailureBgURL;
@property (strong, nonatomic, readonly) NSString *supportEmail;

@property (strong, nonatomic) NSDictionary *userConfig;

+ (instancetype)sharedInstance;
- (void)fetchRemotePlistsWithCompletionHandler:(void(^)())handler;
- (void)prefetchRemoteImages;

@end
