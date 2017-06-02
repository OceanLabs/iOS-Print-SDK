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

#import "OLImageDownloader.h"
#import "OLKiteABTesting.h"
#import "OLKitePrintSDK.h"
#import "OLKiteUtils.h"
#import "UIColor+OLHexString.h"
#include <stdlib.h>


static NSString *const kOLKiteABTestLaunchWithPrintOrderVariant = @"ly.kite.abtest.launch_with_print_order_variant";
static NSString *const kOLKiteABTestOfferAddressSearch = @"ly.kite.abtest.offer_address_search";
static NSString *const kOLKiteABTestQualityBannerType = @"ly.kite.abtest.quality_banner_type";
static NSString *const kOLKiteABTestProductTileStyle = @"ly.kite.abtest.product_tile_style";
static NSString *const kOLKiteABTestHidePrice = @"ly.kite.abtest.hide_price";
static NSString *const kOLKiteABTestPromoBannerStyle = @"ly.kite.abtest.promo_banner_style";
static NSString *const kOLKiteABTestPromoBannerText = @"ly.kite.abtest.promo_banner_text";
static NSString *const kOLKiteABTestOfferPayPal = @"ly.kite.abtest.offer_paypal";
static NSString *const kOLKiteABTestPaymentScreen = @"ly.kite.abtest.payment_screen";
static NSString *const kOLKiteABTestCoverPhotoVariants = @"ly.kite.abtest.cover_photo_variants";
static NSString *const kOLKiteABTestProgressiveTemplateLoading = @"ly.kite.abtest.progressive_template_loading";

static NSString *const kOLKiteABTestSkipProductOverview = @"ly.kite.abtest.skip_product_overview";
static NSString *const kOLKiteABTestDisableProductCategories = @"ly.kite.abtest.disable_product_categories";
static NSString *const kOLKiteABTestMinimalNavigationBar = @"ly.kite.abtest.minimal_navigationbar";

id safeObject(id obj){
    return obj ? obj : @"";
}

static dispatch_once_t srand48OnceToken;

@interface OLKiteABTesting ()

@property (assign, nonatomic, readwrite) BOOL offerAddressSearch;
@property (assign, nonatomic, readwrite) BOOL skipProductOverview;
@property (assign, nonatomic, readwrite) BOOL disableProductCategories;
@property (assign, nonatomic) BOOL minimalNavigationBar;
@property (assign, nonatomic, readwrite) BOOL hidePrice;
@property (assign, nonatomic, readwrite) BOOL offerPayPal;
@property (assign, nonatomic, readwrite) BOOL progressiveTemplateLoading;
@property (strong, nonatomic, readwrite) NSString *qualityBannerType;
@property (strong, nonatomic, readwrite) NSString *checkoutScreenType;
@property (strong, nonatomic, readwrite) NSString *productTileStyle;
@property (strong, nonatomic, readwrite) NSString *promoBannerText;
@property (strong, nonatomic, readwrite) NSString *launchWithPrintOrderVariant;
@property (strong, nonatomic, readwrite) NSString *paymentScreen;
@property (strong, nonatomic, readwrite) NSString *coverPhotoId;

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
    NSString *user = [self userTheme];
    
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
    
    s = userConfig[kOLKiteThemeCancelButtonIcon];
    if (!s && user){
        s = [NSString stringWithFormat:@"https://s3.amazonaws.com/sdk-static/themes/%@/x.png", user];
    }
    [defaults setObject:s forKey:kOLKiteThemeCancelButtonIcon];
    
    s = userConfig[kOLKiteThemeSupportEmail];
    if (!s && user){
        s = [NSString stringWithFormat:@"appsupport@%@.com", user];
    }
    [defaults setObject:s forKey:kOLKiteThemeSupportEmail];
    [defaults synchronize];
}

- (void)prefetchRemoteImages{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    for (NSString *s in @[kOLKiteThemeHeaderLogoImageURL, kOLKiteThemeCheckoutProgress1, kOLKiteThemeCheckoutProgress2, kOLKiteThemeCheckoutProgress1Bg, kOLKiteThemeCheckoutProgress2Bg, kOLKiteThemeReceiptSuccess, kOLKiteThemeReceiptFailure, kOLKiteThemeReceiptSuccessBg, kOLKiteThemeReceiptFailureBg, kOLKiteThemeCancelButtonIcon, kOLKiteLightThemeSecretReveal]){
        NSURL *url = [NSURL URLWithString:[defaults objectForKey:s]];
        if (url){
            [[OLImageDownloader sharedInstance] downloadImageAtURL:url withCompletionHandler:^(UIImage *image, NSError *error){
                if (!image){
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [defaults removeObjectForKey:s];
                        [defaults synchronize];
                    });
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

- (NSString *)backButtonText{
    return self.minimalNavigationBar ? @"" : NSLocalizedStringFromTableInBundle(@"Back", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"");
}

- (NSString *)headerLogoURL{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:kOLKiteThemeHeaderLogoImageURL];
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

- (NSString *)cancelButtonIconURL{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:kOLKiteThemeCancelButtonIcon];
}

- (NSString *)lightThemeSecretRevealURL{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:kOLKiteLightThemeSecretReveal];
}

- (NSString *)supportEmail{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:kOLKiteThemeSupportEmail];
}

- (UIColor *)lightThemeColor1{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    UIColor *color;
    NSString *hex = [defaults objectForKey:kOLKiteLightThemeColor1];
    if (hex){
        color = [UIColor colorWithHexString:hex];
    }
    return color;
}

- (UIColor *)lightThemeColor2{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    UIColor *color;
    NSString *hex = [defaults objectForKey:kOLKiteLightThemeColor2];
    if (hex){
        color = [UIColor colorWithHexString:hex];
    }
    return color;
}

- (UIColor *)lightThemeColor3{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    UIColor *color;
    NSString *hex = [defaults objectForKey:kOLKiteLightThemeColor3];
    if (hex){
        color = [UIColor colorWithHexString:hex];
    }
    return color;
}

- (UIColor *)lightThemeColor4{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    UIColor *color;
    NSString *hex = [defaults objectForKey:kOLKiteLightThemeColor4];
    if (hex){
        color = [UIColor colorWithHexString:hex];
    }
    return color;
}

- (UIColor *)lightThemeColorReviewCounter{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    UIColor *color;
    NSString *hex = [defaults objectForKey:kOLKiteLightThemeColorReviewCounter];
    if (hex){
        color = [UIColor colorWithHexString:hex];
    }
    return color;
}

- (UIColor *)lightThemeColorDescriptionSeparator{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    UIColor *color;
    NSString *hex = [defaults objectForKey:kOLKiteLightThemeColorDescriptionSeparator];
    if (hex){
        color = [UIColor colorWithHexString:hex];
    }
    return color;
}

- (UIColor *)lightThemeTitleColor1{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    UIColor *color;
    NSString *hex = [defaults objectForKey:kOLKiteLightThemeTitleColor1];
    if (hex){
        color = [UIColor colorWithHexString:hex];
    }
    return color;
}

- (UIFont *)lightThemeFont1WithSize:(CGFloat)size{
    UIFont *font;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *fontName = [defaults objectForKey:kOLKiteLightThemeFont1];
    
    if (fontName){
        font = [UIFont fontWithName:fontName size:size];
    }
    
    return font;
}

- (UIFont *)lightThemeHeavyFont1WithSize:(CGFloat)size{
    UIFont *font;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *fontName = [defaults objectForKey:kOLKiteLightThemeHeavyFont1];
    
    if (fontName){
        font = [UIFont fontWithName:fontName size:size];
    }
    
    return font;
}

- (NSNumber *)lightThemeButtonRoundCorners{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:kOLKiteLightThemeButtonRoundCorners];
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
    [defaults removeObjectForKey:kOLKiteLightThemeSecretReveal];
    [defaults removeObjectForKey:kOLKiteThemeSupportEmail];
    [defaults removeObjectForKey:kOLKiteLightThemeFont1];
    [defaults removeObjectForKey:kOLKiteLightThemeColor1];
    [defaults removeObjectForKey:kOLKiteLightThemeColor2];
    [defaults removeObjectForKey:kOLKiteLightThemeColor3];
    [defaults removeObjectForKey:kOLKiteLightThemeColor4];
    [defaults removeObjectForKey:kOLKiteLightThemeColorReviewCounter];
    [defaults removeObjectForKey:kOLKiteLightThemeColorDescriptionSeparator];
    [defaults removeObjectForKey:kOLKiteLightThemeTitleColor1];
    
    [defaults synchronize];
}

- (NSString *)userTheme{
    NSString *user = [_userConfig[@"theme"] lowercaseString];
    if (!user){
        [_userConfig[@"user_type"] lowercaseString];
    }
    if ([user isEqualToString:@"kite_test"] || [user isEqualToString:@"standard"]) {
        user = nil;
    }
    return user;
}

- (void)fetchRemotePlistsWithCompletionHandler:(void(^)())handler{
    [self resetTheme];
    [OLKiteABTesting fetchRemotePlistWithURL:[NSString stringWithFormat:@"https://s3.amazonaws.com/sdk-static/kite-ios-remote-%@.plist", [OLKitePrintSDK apiKey]] completionHandler:^(NSError *error){
        if (error){
            NSString *user = [self userTheme];
            NSString *url;
            if (user){
                url = [NSString stringWithFormat:@"https://s3.amazonaws.com/sdk-static/themes/%@/kite-ios-remote.plist", user];
            }
            else{
                url = @"https://s3.amazonaws.com/sdk-static/kite-ios-remote.plist";
            }
            
            [OLKiteABTesting fetchRemotePlistWithURL:url completionHandler:^(NSError *error2){
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
        // reset A/B tests if the experiment version for any test has been bumped. This allows us to default to sticky OLKiteABTesting behaviour
        // and when we want to reset things just bump the experiment version.
        // Always resets in sanbox mode
        for (NSString *key in defaults) {
            if ([OLKitePrintSDK environment] == OLKitePrintSDKEnvironmentSandbox){
                [OLKiteABTesting resetTestNamed:key];
                continue;
            }
            
            id possibleDict = defaults[key];
            id oldPossibleDict = oldDefaults[key];
            if ([possibleDict isKindOfClass:[NSDictionary class]] && ([oldPossibleDict isKindOfClass:[NSDictionary class]]|| !oldPossibleDict) ) {
                id experimentVersion = [possibleDict objectForKey:@"Experiment Version"];
                id oldExperimentVersion = [oldPossibleDict objectForKey:@"Experiment Version"];
                if (([experimentVersion isKindOfClass:[NSString class]] && (([oldExperimentVersion isKindOfClass:[NSString class]] && ![experimentVersion isEqualToString:oldExperimentVersion]) || !oldExperimentVersion))) {
                    [OLKiteABTesting resetTestNamed:key];
                }
            }
        }
        handler(nil);
    }failure:^(NSError *error){
        handler(error);
    }];
}

//Note: Run in TemplateSyncRequest, not with the other tests
- (void)setupCoverPhotoTestWithExperimentDict:(NSDictionary *)experimentDict{
    self.coverPhotoId = nil;
    
    if ([OLKitePrintSDK environment] == OLKitePrintSDKEnvironmentSandbox){
        [OLKiteABTesting resetTestNamed:kOLKiteABTestCoverPhotoVariants];
    }
    
    if (!experimentDict) {
        return;
    }
    [OLKiteABTesting splitTestWithName:kOLKiteABTestCoverPhotoVariants
                            conditions:experimentDict block:^(id choice) {
                                             self.coverPhotoId = choice;
                                         }];
}

- (void)setupQualityBannerTypeTest{
    self.qualityBannerType = nil;
    
    NSDictionary *experimentDict = [[NSUserDefaults standardUserDefaults] objectForKey:kOLKiteABTestQualityBannerType];
    if (!experimentDict) {
        experimentDict = @{@"None" : @1, @"A" : @0, @"B" : @0, @"C" : @0};
    }
    [OLKiteABTesting splitTestWithName:kOLKiteABTestQualityBannerType
                            conditions:@{
                                         @"None" : safeObject(experimentDict[@"None"]),
                                         @"A" : safeObject(experimentDict[@"A"]),
                                         @"B" : safeObject(experimentDict[@"B"]),
                                         @"C" : safeObject(experimentDict[@"C"])
                                         }
                                 block:^(id choice) {
                                     self.qualityBannerType= choice;
                                 }];
}

- (void)setupProductTileStyleTest{
    self.productTileStyle = nil;
    
    NSDictionary *experimentDict = [[NSUserDefaults standardUserDefaults] objectForKey:kOLKiteABTestProductTileStyle];
    if (!experimentDict) {
        experimentDict = @{@"Classic" : @1, @"A" : @0, @"B" : @0, @"Dark" : @0, @"MinimalWhite" : @0, @"ThemeColor" : @0};
    }
    [OLKiteABTesting splitTestWithName:kOLKiteABTestProductTileStyle
                   conditions:@{
                                @"Classic" : safeObject(experimentDict[@"Classic"]),
                                @"A" : safeObject(experimentDict[@"A"]),
                                @"B" : safeObject(experimentDict[@"B"]),
                                @"Dark" : safeObject(experimentDict[@"Dark"]),
                                @"MinimalWhite" : safeObject(experimentDict[@"MinimalWhite"]),
                                @"ThemeColor" : safeObject(experimentDict[@"ThemeColor"])
                                } block:^(id choice) {
                                    self.productTileStyle = choice;
                                }];
}

- (void)setupPaymentScreenTest{
    self.paymentScreen = nil;
    
    NSDictionary *experimentDict = [[NSUserDefaults standardUserDefaults] objectForKey:kOLKiteABTestPaymentScreen];
    if (!experimentDict) {
        experimentDict = @{@"V2" : @0, @"V3" : @1};
    }
    [OLKiteABTesting splitTestWithName:kOLKiteABTestPaymentScreen
                            conditions:@{
                                         @"V2" : safeObject(experimentDict[@"V2"]),
                                         @"V3" : safeObject(experimentDict[@"V3"]),
                                         } block:^(id choice) {
                                             self.paymentScreen = choice;
                                         }];
}


- (void)setupShowProductDescriptionScreenBeforeShippingTest{
    self.launchWithPrintOrderVariant = nil;
    NSDictionary *experimentDict = [[NSUserDefaults standardUserDefaults] objectForKey:kOLKiteABTestLaunchWithPrintOrderVariant];
    if (!experimentDict) {
        experimentDict = @{@"Checkout" : @0.2, @"Overview-Checkout" : @0.2, @"Review-Overview-Checkout": @0.2, @"Review-Checkout" : @0.2, @"Overview-Review-Checkout" : @0.2};
    }
    [OLKiteABTesting splitTestWithName:kOLKiteABTestLaunchWithPrintOrderVariant
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

- (void)setupDisableProductCategories{
    self.disableProductCategories = NO;
    NSDictionary *experimentDict = [[NSUserDefaults standardUserDefaults] objectForKey:kOLKiteABTestDisableProductCategories];
    if (!experimentDict) {
        experimentDict = @{@"Yes" : @0, @"No" : @1};
    }
    [OLKiteABTesting splitTestWithName:kOLKiteABTestDisableProductCategories
                            conditions:@{
                                         @"Yes" : safeObject(experimentDict[@"Yes"]),
                                         @"No" : safeObject(experimentDict[@"No"])
                                         } block:^(id choice) {
                                             self.disableProductCategories = [choice isEqualToString:@"Yes"];
                                         }];
}

- (void)setupSkipProductOverviewTest{
    self.skipProductOverview = NO;
    NSDictionary *experimentDict = [[NSUserDefaults standardUserDefaults] objectForKey:kOLKiteABTestSkipProductOverview];
    if (!experimentDict) {
        experimentDict = @{@"Yes" : @0, @"No" : @1};
    }
    [OLKiteABTesting splitTestWithName:kOLKiteABTestSkipProductOverview
                            conditions:@{
                                         @"Yes" : safeObject(experimentDict[@"Yes"]),
                                         @"No" : safeObject(experimentDict[@"No"])
                                         } block:^(id choice) {
                                             self.skipProductOverview = [choice isEqualToString:@"Yes"];
                                         }];
}

- (void)setupMinimalNavigationBarTest{
    self.minimalNavigationBar = NO;
    NSDictionary *experimentDict = [[NSUserDefaults standardUserDefaults] objectForKey:kOLKiteABTestMinimalNavigationBar];
    if (!experimentDict) {
        experimentDict = @{@"Yes" : @0, @"No" : @1};
    }
    [OLKiteABTesting splitTestWithName:kOLKiteABTestMinimalNavigationBar
                            conditions:@{
                                         @"Yes" : safeObject(experimentDict[@"Yes"]),
                                         @"No" : safeObject(experimentDict[@"No"])
                                         } block:^(id choice) {
                                             self.minimalNavigationBar = [choice isEqualToString:@"Yes"];
                                         }];
}

- (void)setupOfferAddressSearchTest{
    self.offerAddressSearch = NO;
    NSDictionary *experimentDict = [[NSUserDefaults standardUserDefaults] objectForKey:kOLKiteABTestOfferAddressSearch];
    if (!experimentDict) {
        experimentDict = @{@"Yes" : @0.5, @"No" : @0.5};
    }
    [OLKiteABTesting splitTestWithName:kOLKiteABTestOfferAddressSearch
                   conditions:@{
                                @"Yes" : safeObject(experimentDict[@"Yes"]),
                                @"No" : safeObject(experimentDict[@"No"])
                                } block:^(id choice) {
                                    self.offerAddressSearch = [choice isEqualToString:@"Yes"];
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
    [OLKiteABTesting splitTestWithName:kOLKiteABTestHidePrice
                   conditions:@{
                                @"Yes" : experimentDict[@"Yes"],
                                @"No" : experimentDict[@"No"]
                                } block:^(id choice) {
                                    self.hidePrice = [choice isEqualToString:@"Yes"];
                                }];
}

- (void)setupProgressiveTemplateLoadingTest{
    self.progressiveTemplateLoading = NO;
    if ([OLKitePrintSDK isKiosk]){
        return;
    }
    NSDictionary *experimentDict = [[NSUserDefaults standardUserDefaults] objectForKey:kOLKiteABTestProgressiveTemplateLoading];
    if (!experimentDict) {
        experimentDict = @{@"Yes" : @0, @"No" : @1};
    }
    NSMutableDictionary *options = [[NSMutableDictionary alloc] init];
    for (NSString *s in experimentDict.allKeys){
        [options setObject:safeObject(experimentDict[s]) forKey:s];
    }
    [OLKiteABTesting splitTestWithName:kOLKiteABTestProgressiveTemplateLoading
                            conditions:@{
                                         @"Yes" : experimentDict[@"Yes"],
                                         @"No" : experimentDict[@"No"]
                                         } block:^(id choice) {
                                             self.progressiveTemplateLoading = [choice isEqualToString:@"Yes"];
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
    
    [OLKiteABTesting splitTestWithName:kOLKiteABTestPromoBannerText
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
    [OLKiteABTesting splitTestWithName:kOLKiteABTestOfferPayPal
                   conditions:@{
                                @"Yes" : safeObject(experimentDict[@"Yes"]),
                                @"No" : safeObject(experimentDict[@"No"])
                                } block:^(id choice) {
                                    self.offerPayPal = [choice isEqualToString:@"Yes"];
                                }];
}

- (void)groupSetupShippingScreenTests{
    [self setupOfferAddressSearchTest];
    [self setupPaymentScreenTest];
    [self setupOfferPayPalTest];
}

- (void)setupABTestVariants{
    [self setupQualityBannerTypeTest];
    [self setupProductTileStyleTest];
    [self setupPromoBannerTextTest];
    [self setupHidePriceTest];
    [self setupShowProductDescriptionScreenBeforeShippingTest];
    [self setupProgressiveTemplateLoadingTest];
    [self setupSkipProductOverviewTest];
    [self setupDisableProductCategories];
    [self setupMinimalNavigationBarTest];
    [self groupSetupShippingScreenTests];
}

#pragma mark OLKiteABTesting
//The following methods were adapted from SkyLab: https://github.com/mattt/SkyLab

+ (void)splitTestWithName:(NSString *)name
               conditions:(id <NSFastEnumeration>)conditions
                    block:(void (^)(id))block;
{
    id condition = [[NSUserDefaults standardUserDefaults] objectForKey:[OLKiteABTesting userDefaultsKeyForTestName:name]];
    
    if ([(id <NSObject>)conditions isKindOfClass:[NSDictionary class]]) {
        if (!condition || ![[(NSDictionary *)conditions allKeys] containsObject:condition]) {
            condition = [OLKiteABTesting randomKeyFromDictionaryWithWeightedValues:(NSDictionary *)conditions];
        }
    } else {
        BOOL containsCondition = NO;
        NSMutableArray *mutableCandidates = [NSMutableArray array];
        for (id candidate in conditions) {
            [mutableCandidates addObject:candidate];
            containsCondition = containsCondition || [condition isEqual:candidate];
        }
        
        if (!condition || !containsCondition) {
            condition = [OLKiteABTesting randomValueFromArray:mutableCandidates];
        }
    }
    
    BOOL needsSynchronization = ![condition isEqual:[[NSUserDefaults standardUserDefaults] objectForKey:[OLKiteABTesting userDefaultsKeyForTestName:name]]];
    [[NSUserDefaults standardUserDefaults] setObject:condition forKey:[OLKiteABTesting userDefaultsKeyForTestName:name]];
    if (needsSynchronization) {
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    if (block) {
        block(condition);
    }
}

+ (void)resetTestNamed:(NSString *)name {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[OLKiteABTesting userDefaultsKeyForTestName:name]];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (id)randomKeyFromDictionaryWithWeightedValues:(NSDictionary *)dictionary {
    if ([dictionary count] == 0) {
        return nil;
    }
    
    NSArray *keys = [dictionary allKeys];
    NSMutableArray *mutableWeightedSums = [NSMutableArray arrayWithCapacity:[keys count]];
    
    double total = 0.0;
    for (id key in keys) {
        total += [dictionary[key] doubleValue];
        [mutableWeightedSums addObject:@(total)];
    }
    
    dispatch_once(&srand48OnceToken, ^{
        srand48(time(0));
    });
    
    double r = drand48() * total;
    
    __block id randomObject = nil;
    [mutableWeightedSums enumerateObjectsUsingBlock:^(NSNumber *cumulativeWeightedSum, NSUInteger idx, BOOL *stop) {
        if (r <= [cumulativeWeightedSum doubleValue]) {
            randomObject = keys[idx];
            *stop = YES;
        }
    }];
    
    return randomObject;
}

+ (id)randomValueFromArray:(NSArray *)array {
    if ([array count] == 0) {
        return nil;
    }
    
    return [array objectAtIndex:arc4random_uniform((unsigned int)[array count])];
}

+ (NSString *)userDefaultsKeyForTestName:(NSString *)name {
    return [NSString stringWithFormat:@"OLKiteABTesting-%@", name];
}

@end
