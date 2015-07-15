//
//  OLKiteABTesting.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 14/7/15.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import "OLKiteABTesting.h"
#import <SkyLab.h>
#import <NSUserDefaults+GroundControl.h>
#import "OLKitePrintSDK.h"

static NSString *const kOLKiteABTestProductDescriptionWithPrintOrder = @"ly.kite.abtest.show_product_description_screen";
static NSString *const kOLKiteABTestOfferAddressSearch = @"ly.kite.abtest.offer_address_search";
static NSString *const kOLKiteABTestRequirePhoneNumber = @"ly.kite.abtest.require_phone";
static NSString *const kOLKiteABTestQualityBannerType = @"ly.kite.abtest.quality_banner_type";
static NSString *const kOLKiteABTestShippingScreen = @"ly.kite.abtest.shippingscreen";
static NSString *const kOLKiteABTestProductTileStyle = @"ly.kite.abtest.product_tile_style";

@implementation OLKiteABTesting

+ (instancetype)sharedInstance {
    static dispatch_once_t once;
    static OLKiteABTesting * sharedInstance;
    dispatch_once(&once, ^ { sharedInstance = [[self alloc] init]; });
    return sharedInstance;
}

+ (void)fetchRemotePlistsWithCompletionHandler:(void(^)())handler{
    [OLKiteABTesting fetchRemotePlistWithURL:[NSString stringWithFormat:@"https://sdk-static.s3.amazonaws.com/kite-ios-remote-%@.plist", [OLKitePrintSDK apiKey]] completionHandler:^(NSError *error){
        if (error){
            [OLKiteABTesting fetchRemotePlistWithURL:@"https://sdk-static.s3.amazonaws.com/kite-ios-remote.plist" completionHandler:^(NSError *error2){
                handler();
            }];
        }
        else{
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
            if ([possibleDict isKindOfClass:[NSDictionary class]] && [oldPossibleDict isKindOfClass:[NSDictionary class]]) {
                id experimentVersion = [possibleDict objectForKey:@"Experiment Version"];
                id oldExperimentVersion = [oldPossibleDict objectForKey:@"Experiment Version"];
                if ([experimentVersion isKindOfClass:[NSString class]] && [oldExperimentVersion isKindOfClass:[NSString class]] && ![experimentVersion isEqualToString:oldExperimentVersion]) {
                    [SkyLab resetTestNamed:key];
                }
            }
        }
        handler(nil);
    }failure:^(NSError *error){
        handler(error);
    }];
}

- (void)setupABTestVariantsWillSkipHomeScreens:(BOOL)skipHomeScreen {
    __block NSDictionary *experimentDict;
    
    if (!skipHomeScreen){
        
        // Quality Banner Type
        experimentDict = [[NSUserDefaults standardUserDefaults] objectForKey:kOLKiteABTestQualityBannerType];
        if (!experimentDict) {
            experimentDict = @{@"None" : @0.25, @"A" : @0.25, @"B" : @0.25, @"C" : @0.25};
        }
        [SkyLab splitTestWithName:kOLKiteABTestQualityBannerType
                       conditions:@{
                                    @"None" : experimentDict[@"None"],
                                    @"A" : experimentDict[@"A"],
                                    @"B" : experimentDict[@"B"],
                                    @"C" : experimentDict[@"C"]
                                    } block:^(id choice) {
                                        self.qualityBannerType= choice;
                                    }];
        
        // Product Tile Style
        experimentDict = [[NSUserDefaults standardUserDefaults] objectForKey:kOLKiteABTestProductTileStyle];
        if (!experimentDict) {
            experimentDict = @{@"Classic" : @0.33, @"A" : @0.33, @"B" : @0.33};
        }
        [SkyLab splitTestWithName:kOLKiteABTestProductTileStyle
                       conditions:@{
                                    @"Classic" : experimentDict[@"Classic"],
                                    @"A" : experimentDict[@"A"],
                                    @"B" : experimentDict[@"B"]
                                    } block:^(id choice) {
                                        self.productTileStyle = choice;
                                    }];
    }
    
    if (skipHomeScreen){
        
        // Show Product Description Screen before shipping when starting with Print Order.
        experimentDict = [[NSUserDefaults standardUserDefaults] objectForKey:kOLKiteABTestProductDescriptionWithPrintOrder];
        if (!experimentDict) {
            experimentDict = @{@"Yes" : @0.5, @"No" : @0.5};
        }
        [SkyLab splitTestWithName:kOLKiteABTestProductDescriptionWithPrintOrder
                       conditions:@{
                                    @"Yes" : experimentDict[@"Yes"],
                                    @"No" : experimentDict[@"No"]
                                    } block:^(id choice) {
                                        self.showProductDescriptionWithPrintOrder = [choice isEqualToString:@"Yes"];
                                    }];
    }
    
    // We are not sure if we need the following shipping screen tests right away. If we do (ie we have started up using a Print Order), we will execute inline, otherwise we will execute on another thread so we don't block the current thread, so put them in a block.
    void (^shippingScreenBlock)() = ^() {
        
        // Offer Address Search
        experimentDict = [[NSUserDefaults standardUserDefaults] objectForKey:kOLKiteABTestOfferAddressSearch];
        if (!experimentDict) {
            experimentDict = @{@"Yes" : @0.5, @"No" : @0.5};
        }
        [SkyLab splitTestWithName:kOLKiteABTestOfferAddressSearch
                       conditions:@{
                                    @"Yes" : experimentDict[@"Yes"],
                                    @"No" : experimentDict[@"No"]
                                    } block:^(id choice) {
                                        self.offerAddressSearch = [choice isEqualToString:@"Yes"];
                                    }];
        
        // Require Phone Number
        experimentDict = [[NSUserDefaults standardUserDefaults] objectForKey:kOLKiteABTestRequirePhoneNumber];
        if (!experimentDict) {
            experimentDict = @{@"Yes" : @0.5, @"No" : @0.5};
        }
        [SkyLab splitTestWithName:kOLKiteABTestRequirePhoneNumber
                       conditions:@{
                                    @"Yes" : experimentDict[@"Yes"],
                                    @"No" : experimentDict[@"No"]
                                    } block:^(id choice) {
                                        self.requirePhoneNumber = [choice isEqualToString:@"Yes"];
                                    }];
        
        // Classic vs Integrated Shipping Screen
        experimentDict = [[NSUserDefaults standardUserDefaults] objectForKey:kOLKiteABTestShippingScreen];
        if (!experimentDict){
            experimentDict = @{@"Classic" : @0.66, @"Integrated" : @0.34}; // There are 3 variants Classic+Address Search, Classic no Address Search & Integrated hence Classic gets 2/3 of the chance here as it will further get split 50:50 between the 2 classic variants internally resulting in 1/3 probability each.
        }
        [SkyLab splitTestWithName:kOLKiteABTestShippingScreen conditions:@{
                                                                           @"Classic" : experimentDict[@"Classic"],
                                                                           @"Integrated" : experimentDict[@"Integrated"]
                                                                           }block:^(id choice){
                                                                               
                                                                               self.checkoutScreenType = choice;
                                                                           }];
    };
    
    //Execute on current thread or on another thread, depeding on when we need it
    if (skipHomeScreen && self.showProductDescriptionWithPrintOrder){
        shippingScreenBlock();
    }
    else{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            shippingScreenBlock();
        });
    }
}

@end
