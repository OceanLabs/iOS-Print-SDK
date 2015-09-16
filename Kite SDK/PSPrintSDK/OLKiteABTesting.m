//
//  OLKiteABTesting.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 14/7/15.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import "OLKiteABTesting.h"
#import <SkyLab/SkyLab.h>
#import <GroundControl/NSUserDefaults+GroundControl.h>
#import "OLKitePrintSDK.h"

static NSString *const kOLKiteABTestLaunchWithPrintOrderVariant = @"ly.kite.abtest.launch_with_print_order_variant";
static NSString *const kOLKiteABTestOfferAddressSearch = @"ly.kite.abtest.offer_address_search";
static NSString *const kOLKiteABTestRequirePhoneNumber = @"ly.kite.abtest.require_phone";
static NSString *const kOLKiteABTestQualityBannerType = @"ly.kite.abtest.quality_banner_type";
static NSString *const kOLKiteABTestShippingScreen = @"ly.kite.abtest.shippingscreen";
static NSString *const kOLKiteABTestProductTileStyle = @"ly.kite.abtest.product_tile_style";
static NSString *const kOLKiteABTestHidePrice = @"ly.kite.abtest.hide_price";
static NSString *const kOLKiteABTestPromoBannerStyle = @"ly.kite.abtest.promo_banner_style";
static NSString *const kOLKiteABTestPromoBannerText = @"ly.kite.abtest.promo_banner_text";
static NSString *const kOLKiteABTestOfferPayPal = @"ly.kite.abtest.offer_paypal";

id safeObject(id obj){
    return obj ? obj : @"";
}

@implementation OLKiteABTesting

+ (instancetype)sharedInstance {
    static dispatch_once_t once;
    static OLKiteABTesting * sharedInstance;
    dispatch_once(&once, ^ { sharedInstance = [[self alloc] init]; });
    return sharedInstance;
}

- (void)fetchRemotePlistsWithCompletionHandler:(void(^)())handler{
    [OLKiteABTesting fetchRemotePlistWithURL:[NSString stringWithFormat:@"https://sdk-static.s3.amazonaws.com/kite-ios-remote-%@.plist", [OLKitePrintSDK apiKey]] completionHandler:^(NSError *error){
        if (error){
            [OLKiteABTesting fetchRemotePlistWithURL:@"https://sdk-static.s3.amazonaws.com/kite-ios-remote.plist" completionHandler:^(NSError *error2){
                [self setupABTestVariants];
                handler();
            }];
        }
        else{
            [self setupABTestVariants];
            handler();
        }
    }];
}

+ (void)fetchRemotePlistWithURL:(NSString *)urlString completionHandler:(void (^)(NSError *error))handler{
    NSDictionary *oldDefaults = [[NSUserDefaults standardUserDefaults] dictionaryRepresentation];
    
    NSURL *URL = [NSURL URLWithString:urlString];
    [[NSUserDefaults standardUserDefaults] registerDefaultsWithURL:URL success:^(NSDictionary *defaults){
        // reset SKLab A/B tests if the experiment version for any test has been bumped. This allows us to default to sticky SkyLab behaviour
        // and when we want to reset things just bump the experiment version.
        for (NSString *key in defaults) {
            id possibleDict = defaults[key];
            id oldPossibleDict = oldDefaults[key];
            if ([possibleDict isKindOfClass:[NSDictionary class]] && ([oldPossibleDict isKindOfClass:[NSDictionary class]]|| !oldPossibleDict) ) {
                id experimentVersion = [possibleDict objectForKey:@"Experiment Version"];
                id oldExperimentVersion = [oldPossibleDict objectForKey:@"Experiment Version"];
                if (([experimentVersion isKindOfClass:[NSString class]] && (([oldExperimentVersion isKindOfClass:[NSString class]] && ![experimentVersion isEqualToString:oldExperimentVersion]) || !oldExperimentVersion))) {
                    [SkyLab resetTestNamed:key];
                }
            }
        }
        handler(nil);
    }failure:^(NSError *error){
        handler(error);
    }];
}

- (void)setupQualityBannerTypeTest{
    self.qualityBannerType = nil;
    
    NSDictionary *experimentDict = [[NSUserDefaults standardUserDefaults] objectForKey:kOLKiteABTestQualityBannerType];
    if (!experimentDict) {
        experimentDict = @{@"None" : @1, @"A" : @0, @"B" : @0, @"C" : @0};
    }
    [SkyLab splitTestWithName:kOLKiteABTestQualityBannerType
                   conditions:@{
                                @"None" : safeObject(experimentDict[@"None"]),
                                @"A" : safeObject(experimentDict[@"A"]),
                                @"B" : safeObject(experimentDict[@"B"]),
                                @"C" : safeObject(experimentDict[@"C"])
                                } block:^(id choice) {
                                    self.qualityBannerType= choice;
                                }];
}

- (void)setupProductTileStyleTest{
    self.productTileStyle = nil;
    
    NSDictionary *experimentDict = [[NSUserDefaults standardUserDefaults] objectForKey:kOLKiteABTestProductTileStyle];
    if (!experimentDict) {
        experimentDict = @{@"Classic" : @1, @"A" : @0, @"B" : @0};
    }
    [SkyLab splitTestWithName:kOLKiteABTestProductTileStyle
                   conditions:@{
                                @"Classic" : safeObject(experimentDict[@"Classic"]),
                                @"A" : safeObject(experimentDict[@"A"]),
                                @"B" : safeObject(experimentDict[@"B"])
                                } block:^(id choice) {
                                    self.productTileStyle = choice;
                                }];
}

- (void)setupShowProductDescriptionScreenBeforeShippingTest{
    self.launchWithPrintOrderVariant = nil;
    NSDictionary *experimentDict = [[NSUserDefaults standardUserDefaults] objectForKey:kOLKiteABTestLaunchWithPrintOrderVariant];
    if (!experimentDict) {
        experimentDict = @{@"Checkout" : @0.2, @"Overview-Checkout" : @0.2, @"Review-Overview-Checkout": @0.2, @"Review-Checkout" : @0.2, @"Overview-Review-Checkout" : @0.2};
    }
    [SkyLab splitTestWithName:kOLKiteABTestLaunchWithPrintOrderVariant
                   conditions:@{
                                @"Checkout" : safeObject(experimentDict[@"Checkout"]),
                                @"Overview-Checkout" : safeObject(experimentDict[@"Overview-Checkout"]),
                                @"Review-Overview-Checkout" : safeObject(experimentDict[@"Review-Overview-Checkout"]),
                                @"Review-Checkout" : safeObject(experimentDict[@"Review-Checkout"]),
                                @"Overview-Review-Checkout" : safeObject(experimentDict[@"Overview-Review-Checkout"])
                                } block:^(id choice) {
                                    self.launchWithPrintOrderVariant = choice;
                                }];
}

- (void)setupOfferAddressSearchTest{
    self.offerAddressSearch = nil;
    NSDictionary *experimentDict = [[NSUserDefaults standardUserDefaults] objectForKey:kOLKiteABTestOfferAddressSearch];
    if (!experimentDict) {
        experimentDict = @{@"Yes" : @0.5, @"No" : @0.5};
    }
    [SkyLab splitTestWithName:kOLKiteABTestOfferAddressSearch
                   conditions:@{
                                @"Yes" : safeObject(experimentDict[@"Yes"]),
                                @"No" : safeObject(experimentDict[@"No"])
                                } block:^(id choice) {
                                    self.offerAddressSearch = [choice isEqualToString:@"Yes"];
                                }];
}

- (void)setupRequirePhoneNumberTest{
    self.requirePhoneNumber = nil;
    NSDictionary *experimentDict = [[NSUserDefaults standardUserDefaults] objectForKey:kOLKiteABTestRequirePhoneNumber];
    if (!experimentDict) {
        experimentDict = @{@"Yes" : @0.5, @"No" : @0.5};
    }
    [SkyLab splitTestWithName:kOLKiteABTestRequirePhoneNumber
                   conditions:@{
                                @"Yes" : safeObject(experimentDict[@"Yes"]),
                                @"No" : safeObject(experimentDict[@"No"])
                                } block:^(id choice) {
                                    self.requirePhoneNumber = [choice isEqualToString:@"Yes"];
                                }];
}

- (void)setupShippingScreenTest{
    self.checkoutScreenType = nil;
    NSDictionary *experimentDict = [[NSUserDefaults standardUserDefaults] objectForKey:kOLKiteABTestShippingScreen];
    if (!experimentDict){
        experimentDict = @{@"Classic" : @0.66, @"Integrated" : @0.34}; // There are 3 variants Classic+Address Search, Classic no Address Search & Integrated hence Classic gets 2/3 of the chance here as it will further get split 50:50 between the 2 classic variants internally resulting in 1/3 probability each.
    }
    [SkyLab splitTestWithName:kOLKiteABTestShippingScreen conditions:@{
                                                                       @"Classic" : safeObject(experimentDict[@"Classic"]),
                                                                       @"Integrated" : safeObject(experimentDict[@"Integrated"])
                                                                       }block:^(id choice){
                                                                           self.checkoutScreenType = choice;
                                                                       }];
}

- (void)setupHidePriceTest{
    self.hidePrice = nil;
    NSDictionary *experimentDict = [[NSUserDefaults standardUserDefaults] objectForKey:kOLKiteABTestHidePrice];
    if (!experimentDict) {
        experimentDict = @{@"Yes" : @0, @"No" : @1};
    }
    NSMutableDictionary *options = [[NSMutableDictionary alloc] init];
    for (NSString *s in experimentDict.allKeys){
        [options setObject:safeObject(experimentDict[s]) forKey:s];
    }
    [SkyLab splitTestWithName:kOLKiteABTestHidePrice
                   conditions:@{
                                @"Yes" : experimentDict[@"Yes"],
                                @"No" : experimentDict[@"No"]
                                } block:^(id choice) {
                                    self.hidePrice = [choice isEqualToString:@"Yes"];
                                }];
}


//  Promo strings look like this: @"<header>Hello World!</header><para>Off to the woods</para>"
- (void)setupPromoBannerTextTest{
    self.promoBannerText = nil;
    NSDictionary *experimentDict = [[NSUserDefaults standardUserDefaults] objectForKey:kOLKiteABTestPromoBannerText];
    if (!experimentDict) {
        return;
    }
    
    // While it is tempting to do the dynamic conditions in other tests as well, DON'T, as typos in the plist can crash the app.
    NSMutableDictionary *conditions = [[NSMutableDictionary alloc] init];
    for (NSString *key in experimentDict.allKeys) {
        id val = experimentDict[key];
        if ([val isKindOfClass:[NSNumber class]]) {
            [conditions setObject:safeObject(val) forKey:key];
        }
    }

    [conditions removeObjectForKey:@"Experiment Version"];
    
    if (conditions.count == 0) {
        return;
    }
    
    [SkyLab splitTestWithName:kOLKiteABTestPromoBannerText
                   conditions:conditions block:^(id choice) {
                       self.promoBannerText = choice;
                   }];
}

- (void)setupOfferPayPalTest{
    self.offerPayPal = nil;
    NSDictionary *experimentDict = [[NSUserDefaults standardUserDefaults] objectForKey:kOLKiteABTestOfferPayPal];
    if (!experimentDict) {
        experimentDict = @{@"Yes" : @0.5, @"No" : @0.5};
    }
    [SkyLab splitTestWithName:kOLKiteABTestOfferPayPal
                   conditions:@{
                                @"Yes" : safeObject(experimentDict[@"Yes"]),
                                @"No" : safeObject(experimentDict[@"No"])
                                } block:^(id choice) {
                                    self.offerPayPal = [choice isEqualToString:@"Yes"];
                                }];
}

- (void)groupSetupShippingScreenTests{
    [self setupOfferAddressSearchTest];
    [self setupRequirePhoneNumberTest];
    [self setupShippingScreenTest];
    [self setupOfferPayPalTest];
}

- (void)setupABTestVariants{
    [self setupQualityBannerTypeTest];
    [self setupProductTileStyleTest];
    [self setupPromoBannerTextTest];
    [self setupHidePriceTest];
    [self setupShowProductDescriptionScreenBeforeShippingTest];
    [self setupHidePriceTest];
    [self groupSetupShippingScreenTests];
}

@end
