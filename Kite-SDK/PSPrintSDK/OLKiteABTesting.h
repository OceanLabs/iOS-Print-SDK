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

#import <Foundation/Foundation.h>

static NSString *const kOLKiteLightThemeColor1 = @"ly.kite.theme.light.color.1";
static NSString *const kOLKiteLightThemeColor2 = @"ly.kite.theme.light.color.2";
static NSString *const kOLKiteLightThemeColor3 = @"ly.kite.theme.light.color.3";
static NSString *const kOLKiteLightThemeColor4 = @"ly.kite.theme.light.color.4";
static NSString *const kOLKiteLightThemeColorPickerTick = @"ly.kite.theme.light.color.picker.tick";
static NSString *const kOLKiteLightThemeColorReviewCounter = @"ly.kite.theme.light.color.reviewCounter";
static NSString *const kOLKiteLightThemeColorDescriptionSeparator = @"ly.kite.theme.light.color.descriptionSeparator";
static NSString *const kOLKiteLightThemeColorImageEditBg = @"ly.kite.theme.light.color.imageedit.bg";
static NSString *const kOLKiteLightThemeColorImageEditCta = @"ly.kite.theme.light.color.imageedit.cta";
static NSString *const kOLKiteLightThemeColorBasketQtyButtons = @"ly.kite.theme.light.color.basket.qtybuttons";
static NSString *const kOLKiteLightThemeColorBasketContinueShopping = @"ly.kite.theme.light.color.basket.continueshopping";
static NSString *const kOLKiteLightThemeTitleColor1 = @"ly.kite.theme.light.titleColor.1";
static NSString *const kOLKiteLightThemeFont1 = @"ly.kite.theme.light.font.1";
static NSString *const kOLKiteLightThemeHeavyFont1 = @"ly.kite.theme.light.font.1.heavy";
static NSString *const kOLKiteLightThemeButtonRoundCorners = @"ly.kite.theme.light.buttonRoundCorners";

@interface OLKiteABTesting : NSObject

@property (assign, nonatomic, readonly) BOOL hidePrice;
@property (assign, nonatomic, readonly) BOOL skipProductOverview;
@property (assign, nonatomic, readonly) BOOL disableProductCategories;
@property (assign, nonatomic, readonly) BOOL progressiveTemplateLoading;
@property (strong, nonatomic, readonly) NSString *qualityBannerType;
@property (strong, nonatomic, readonly) NSString *checkoutScreenType;
@property (strong, nonatomic, readonly) NSString *productTileStyle;
@property (strong, nonatomic, readonly) NSString *promoBannerText;
@property (strong, nonatomic, readonly) NSString *paymentScreen;
@property (strong, nonatomic, readonly) NSString *coverPhotoId;
@property (strong, nonatomic, readonly) NSString *packReviewStyle;

@property (strong, nonatomic, readonly) NSString *headerLogoURL;
@property (strong, nonatomic, readonly) NSString *cancelButtonIconURL;
@property (strong, nonatomic, readonly) NSString *lightThemeSecretRevealURL;
@property (strong, nonatomic, readonly) NSString *supportEmail;
@property (strong, nonatomic, readonly) UIColor *lightThemeColor1;
@property (strong, nonatomic, readonly) UIColor *lightThemeColor2;
@property (strong, nonatomic, readonly) UIColor *lightThemeColor3;
@property (strong, nonatomic, readonly) UIColor *lightThemeColor4;
@property (strong, nonatomic, readonly) UIColor *lightThemeColorPickerTick;
@property (strong, nonatomic, readonly) UIColor *lightThemeColorReviewCounter;
@property (strong, nonatomic, readonly) UIColor *lightThemeColorDescriptionSeparator;
@property (strong, nonatomic, readonly) UIColor *lightThemeColorImageEditBg;
@property (strong, nonatomic, readonly) UIColor *lightThemeColorImageEditCta;
@property (strong, nonatomic, readonly) UIColor *lightThemeTitleColor1;
@property (strong, nonatomic, readonly) NSNumber *lightThemeButtonRoundCorners;
- (UIFont *)lightThemeFont1WithSize:(CGFloat)size;
- (UIFont *)lightThemeHeavyFont1WithSize:(CGFloat)size;
- (NSString *)backButtonText;

@property (strong, nonatomic) NSDictionary *userConfig;
@property (strong, nonatomic) NSArray *paypalSupportedCurrencies;

+ (instancetype)sharedInstance;
- (void)fetchRemotePlistsWithCompletionHandler:(void(^)(void))handler;
- (void)setupABTestVariants;
- (void)setupCoverPhotoTestWithExperimentDict:(NSDictionary *)experimentDict;
@end
