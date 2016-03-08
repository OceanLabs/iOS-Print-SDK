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

#ifdef COCOAPODS
#import <SkyLab/SkyLab.h>
#import <SDWebImage/SDWebImageManager.h>
#else
#import "SkyLab.h"
#import "SDWebImageManager.h"
#endif

#import "OLKiteABTesting.h"
#import "OLKitePrintSDK.h"
#import "UIColor+HexString.h"
#import "OLKiteUtils.h"


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
static NSString *const kOLKiteABTestAllowMultipleRecipients = @"ly.kite.abtest.allow_multiple_recipients";

id safeObject(id obj){
    return obj ? obj : @"";
}

@interface OLKiteABTesting ()

@property (assign, nonatomic, readwrite) BOOL offerAddressSearch;
@property (assign, nonatomic, readwrite) BOOL requirePhoneNumber;
@property (assign, nonatomic, readwrite) BOOL hidePrice;
@property (assign, nonatomic, readwrite) BOOL offerPayPal;
@property (strong, nonatomic, readwrite) NSString *qualityBannerType;
@property (strong, nonatomic, readwrite) NSString *checkoutScreenType;
@property (strong, nonatomic, readwrite) NSString *productTileStyle;
@property (strong, nonatomic, readwrite) NSString *promoBannerText;
@property (strong, nonatomic, readwrite) NSString *launchWithPrintOrderVariant;
@property (assign, nonatomic, readwrite) BOOL allowsMultipleRecipients;

@end

@implementation OLKiteABTesting

+ (instancetype)sharedInstance {
    static dispatch_once_t once;
    static OLKiteABTesting * sharedInstance;
    dispatch_once(&once, ^ { sharedInstance = [[self alloc] init]; });
    return sharedInstance;
}

- (void)setUserConfig:(NSDictionary *)userConfig{
    _userConfig = userConfig;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSString *s;
    NSString *user = [userConfig[@"user_type"] lowercaseString];
    if ([user isEqualToString:@"kite_test"] || [user isEqualToString:@"standard"]) {
        user = nil;
    }
    
    s = userConfig[kOLKiteThemeHeaderLogoImageURL];
    if (!s && user){
        s = [NSString stringWithFormat:@"https://s3.amazonaws.com/sdk-static/themes/%@/logo.png", user];
    }
    [defaults setObject:s forKey:kOLKiteThemeHeaderLogoImageURL];
    
    s = userConfig[kOLKiteThemeCheckoutProgress1];
    if (!s && user){
        s = [NSString stringWithFormat:@"https://s3.amazonaws.com/sdk-static/themes/%@/checkout_progress_indicator.png", user];
    }
    [defaults setObject:s forKey:kOLKiteThemeCheckoutProgress1];
    
    s = userConfig[kOLKiteThemeCheckoutProgress2];
    if (!s && user){
        s = [NSString stringWithFormat:@"https://s3.amazonaws.com/sdk-static/themes/%@/checkout_progress_indicator2.png", user];
    }
    [defaults setObject:s forKey:kOLKiteThemeCheckoutProgress2];
    
    s = userConfig[kOLKiteThemeCheckoutProgress1Bg];
    if (!s && user){
        s = [NSString stringWithFormat:@"https://s3.amazonaws.com/sdk-static/themes/%@/checkout_progress_indicator_bg.png", user];
    }
    [defaults setObject:s forKey:kOLKiteThemeCheckoutProgress1Bg];
    
    s = userConfig[kOLKiteThemeCheckoutProgress2Bg];
    if (!s && user){
        s = [NSString stringWithFormat:@"https://s3.amazonaws.com/sdk-static/themes/%@/checkout_progress_indicator2_bg.png", user];
    }
    [defaults setObject:s forKey:kOLKiteThemeCheckoutProgress2Bg];
    
    s = userConfig[kOLKiteThemeReceiptSuccess];
    if (!s && user){
        s = [NSString stringWithFormat:@"https://s3.amazonaws.com/sdk-static/themes/%@/receipt_success.png", user];
    }
    [defaults setObject:s forKey:kOLKiteThemeReceiptSuccess];
    
    s = userConfig[kOLKiteThemeReceiptFailure];
    if (!s && user){
        s = [NSString stringWithFormat:@"https://s3.amazonaws.com/sdk-static/themes/%@/receipt_failure.png", user];
    }
    [defaults setObject:s forKey:kOLKiteThemeReceiptFailure];
    
    s = userConfig[kOLKiteThemeReceiptSuccessBg];
    if (!s && user){
        s = [NSString stringWithFormat:@"https://s3.amazonaws.com/sdk-static/themes/%@/receipt_success_bg.png", user];
    }
    [defaults setObject:s forKey:kOLKiteThemeReceiptSuccessBg];
    
    s = userConfig[kOLKiteThemeReceiptFailureBg];
    if (!s && user){
        s = [NSString stringWithFormat:@"https://s3.amazonaws.com/sdk-static/themes/%@/receipt_failure_bg.png", user];
    }
    [defaults setObject:s forKey:kOLKiteThemeReceiptFailureBg];
    
    s = userConfig[kOLKiteThemeSupportEmail];
    if (!s && user){
        s = [NSString stringWithFormat:@"appsupport@%@.com", user];
    }
    [defaults setObject:s forKey:kOLKiteThemeSupportEmail];
    [defaults synchronize];
}

- (UIColor *)darkThemeColor1{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    UIColor *color;
    NSString *hex = [defaults objectForKey:@"ly.kite.theme.dark.color1"];
    if (hex){
        color = [UIColor colorWithHexString:hex];
    }
    else{
        color = [UIColor colorWithHexString:@"6867E8"];
    }
    return color;
}

- (void)prefetchRemoteImages{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    for (NSString *s in @[kOLKiteThemeHeaderLogoImageURL, kOLKiteThemeCheckoutProgress1, kOLKiteThemeCheckoutProgress2, kOLKiteThemeCheckoutProgress1Bg, kOLKiteThemeCheckoutProgress2Bg, kOLKiteThemeReceiptSuccess, kOLKiteThemeReceiptFailure, kOLKiteThemeReceiptSuccessBg, kOLKiteThemeReceiptFailureBg]){
        NSURL *url = [NSURL URLWithString:[defaults objectForKey:s]];
        if (url){
            [[SDWebImageManager sharedManager] downloadImageWithURL:url options:0 progress:NULL completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL){
                if (!image){
                    [defaults removeObjectForKey:s];
                }
            }];
        }
    }
}

- (NSString *)promoBannerText{
    NSString *userConfig = self.userConfig[@"banner_message"];
    if (userConfig && ![userConfig isEqualToString:@""]){
        return  userConfig;
    }
    
    return _promoBannerText;
}

- (NSString *)headerLogoURL{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:kOLKiteThemeHeaderLogoImageURL];
}

- (NSString *)checkoutProgress1URL{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:kOLKiteThemeCheckoutProgress1];
}

- (NSString *)checkoutProgress2URL{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:kOLKiteThemeCheckoutProgress2];
}

- (NSString *)checkoutProgress1BgURL{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:kOLKiteThemeCheckoutProgress1Bg];
}

- (NSString *)checkoutProgress2BgURL{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:kOLKiteThemeCheckoutProgress2Bg];
}

- (NSString *)receiptSuccessURL{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:kOLKiteThemeReceiptSuccess];
}

- (NSString *)receiptFailureURL{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:kOLKiteThemeReceiptFailure];
}

- (NSString *)receiptSuccessBgURL{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:kOLKiteThemeReceiptSuccessBg];
}

- (NSString *)receiptFailureBgURL{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:kOLKiteThemeReceiptFailureBg];
}

- (NSString *)supportEmail{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:kOLKiteThemeSupportEmail];
}

- (void)resetTheme{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:kOLKiteThemeHeaderLogoImageURL];
    [defaults removeObjectForKey:kOLKiteThemeCheckoutProgress1];
    [defaults removeObjectForKey:kOLKiteThemeCheckoutProgress2];
    [defaults removeObjectForKey:kOLKiteThemeCheckoutProgress1Bg];
    [defaults removeObjectForKey:kOLKiteThemeCheckoutProgress2Bg];
    [defaults removeObjectForKey:kOLKiteThemeReceiptSuccess];
    [defaults removeObjectForKey:kOLKiteThemeReceiptFailure];
    [defaults removeObjectForKey:kOLKiteThemeReceiptSuccessBg];
    [defaults removeObjectForKey:kOLKiteThemeReceiptFailureBg];
    [defaults removeObjectForKey:kOLKiteThemeSupportEmail];
}

- (void)fetchRemotePlistsWithCompletionHandler:(void(^)())handler{
    [self resetTheme];
    [OLKiteABTesting fetchRemotePlistWithURL:[NSString stringWithFormat:@"https://s3.amazonaws.com/sdk-static/kite-ios-remote-%@.plist", [OLKitePrintSDK apiKey]] completionHandler:^(NSError *error){
        if (error){
            [OLKiteABTesting fetchRemotePlistWithURL:@"https://s3.amazonaws.com/sdk-static/kite-ios-remote.plist" completionHandler:^(NSError *error2){
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
    [OLKiteUtils registerDefaultsWithURL:URL success:^(NSDictionary *defaults){
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
        experimentDict = @{@"Classic" : @1, @"A" : @0, @"B" : @0, @"Dark" : @0};
    }
    [SkyLab splitTestWithName:kOLKiteABTestProductTileStyle
                   conditions:@{
                                @"Classic" : safeObject(experimentDict[@"Classic"]),
                                @"A" : safeObject(experimentDict[@"A"]),
                                @"B" : safeObject(experimentDict[@"B"]),
                                @"Dark" : safeObject(experimentDict[@"Dark"])
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
    self.offerAddressSearch = NO;
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
    self.requirePhoneNumber = NO;
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
    self.hidePrice = NO;
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

/**
 *  Promo strings look like this: @"<header>Hello World!</header><para>Off to the woods in [[2015-08-04 18:05 GMT+3]]</para>"
 */
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
    self.offerPayPal = NO;
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

- (void)setupAllowMultipleRecipientsTest{
    self.allowsMultipleRecipients = NO;
    NSDictionary *experimentDict = [[NSUserDefaults standardUserDefaults] objectForKey:kOLKiteABTestAllowMultipleRecipients];
    if (!experimentDict) {
        experimentDict = @{@"Yes" : @0, @"No" : @1};
    }
    [SkyLab splitTestWithName:kOLKiteABTestAllowMultipleRecipients
                   conditions:@{
                                @"Yes" : safeObject(experimentDict[@"Yes"]),
                                @"No" : safeObject(experimentDict[@"No"])
                                } block:^(id choice) {
                                    self.allowsMultipleRecipients = [choice isEqualToString:@"Yes"];
                                }];
}

- (void)groupSetupShippingScreenTests{
    [self setupOfferAddressSearchTest];
    [self setupRequirePhoneNumberTest];
    [self setupShippingScreenTest];
    [self setupOfferPayPalTest];
    [self setupAllowMultipleRecipientsTest];
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
