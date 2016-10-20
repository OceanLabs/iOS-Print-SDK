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

#import "OLProductTemplateSyncRequest.h"
#import "OLBaseRequest.h"
#import "OLKitePrintSDK.h"
#import "OLProductTemplate.h"
#import "OLConstants.h"
#import "OLKiteABTesting.h"
#import "OLKiteTheme.h"
#import "OLCountry.h"
#import "OLKiteUtils.h"
#import "OLPageLayout.h"
#import "OLProductRepresentation.h"
#import "OLProductTemplateCollection.h"

@interface OLProductTemplateSyncRequest ()
@property (nonatomic, strong) OLBaseRequest *req;
@end

@interface OLKitePrintSDK (Private)

+ (NSString *)apiEndpoint;
+ (NSString *)apiVersion;
+ (void)setPayPalAccountId:(NSString *)accountId;
+ (void)setPayPalPublicKey:(NSString *)publicKey;
+ (void)setStripeAccountId:(NSString *)accountId;
+ (void)setStripePublicKey:(NSString *)publicKey;

@end

@interface OLAddress ()
@property (strong, nonatomic) NSString *companyName;

@end

@implementation OLProductTemplateSyncRequest

- (void)sync:(OLTemplateSyncRequestCompletionHandler)handler {
    NSAssert(self.req == nil, @"Oops only one template sync request should be in progress at any given time");
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/template/?limit=200", [OLKitePrintSDK apiEndpoint], [OLKitePrintSDK apiVersion]]];
    [self fetchTemplatesWithURL:url templateAccumulator:[[NSMutableArray alloc] init] handler:handler];
}

- (void)fetchTemplatesWithURL:(NSURL *)url templateAccumulator:(NSMutableArray *)acc handler:(OLTemplateSyncRequestCompletionHandler)handler {
    NSDictionary *headers = @{@"Authorization": [NSString stringWithFormat:@"ApiKey %@:", [OLKitePrintSDK apiKey]]};
    self.req = [[OLBaseRequest alloc] initWithURL:url httpMethod:kOLHTTPMethodGET headers:headers body:nil];
    [self.req startWithCompletionHandler:^(NSInteger httpStatusCode, id json, NSError *error) {
        if (error) {
            
            if (httpStatusCode == 401) {
                // unauthorized
                error = [NSError errorWithDomain:kOLKiteSDKErrorDomain code:kOLKiteSDKErrorCodeUnauthorized userInfo:@{NSLocalizedDescriptionKey: kOLKiteSDKErrorMessageUnauthorized}];
            }
            
            self.req = nil;
            handler(nil, error);
        } else {
            if (httpStatusCode >= 200 & httpStatusCode <= 299) {
                NSURL *nextPage = nil;
                id meta = json[@"meta"];
                if ([meta isKindOfClass:[NSDictionary class]]) {
                    id next = meta[@"next"];
                    if ([next isKindOfClass:[NSString class]]) {
                        nextPage = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", [OLKitePrintSDK apiEndpoint], next]];
                    }
                }
                
                id paymentKeys = json[@"payment_keys"];
                if ([paymentKeys isKindOfClass:[NSDictionary class]]){
                    id paypalKeys = paymentKeys[@"paypal"];
                    if([paypalKeys isKindOfClass:[NSDictionary class]]){
                        id accountId = paypalKeys[@"account_id"];
                        id publicKey = paypalKeys[@"public_key"];
                        if ([publicKey isKindOfClass:[NSString class]]){
                            [OLKitePrintSDK setPayPalAccountId:accountId];
                            [OLKitePrintSDK setPayPalPublicKey:publicKey];
                        }
                    }
                    
                    id stripeKeys = paymentKeys[@"stripe"];
                    if([stripeKeys isKindOfClass:[NSDictionary class]]){
                        id accountId = stripeKeys[@"account_id"];
                        id publicKey = stripeKeys[@"public_key"];
                        if ([publicKey isKindOfClass:[NSString class]]){
                            [OLKitePrintSDK setStripeAccountId:accountId];
                            [OLKitePrintSDK setStripePublicKey:publicKey];
                        }
                    }
                }
                
                id userConfig = json[@"user_config"];
                if ([userConfig isKindOfClass:[NSDictionary class]]){
                    [[OLKiteABTesting sharedInstance] setUserConfig:userConfig];
                }
                
                NSMutableArray *templateCollections = [[NSMutableArray alloc] init];
                id collections = json[@"collections"];
                if ([collections isKindOfClass:[NSArray class]]){
                    for (NSDictionary *collection in collections){
                        if ([collection isKindOfClass:[NSDictionary class]]){
                            NSString *name = collection[@"name"];
                            NSArray *templates = collection[@"templates"];
                            OLProductTemplateCollection *templateCollection = [[OLProductTemplateCollection alloc] initWithName:name templates:templates];
                            [templateCollections addObject:templateCollection];
                        }
                    }
                }
                
                id payPalSupportedCurrencies = json[@"paypal_supported_currencies"];
                if ([payPalSupportedCurrencies isKindOfClass:[NSArray class]]){
                    [OLKiteABTesting sharedInstance].paypalSupportedCurrencies = payPalSupportedCurrencies;
                }
                
                id themeConfig = json[@"kiosk_config"];
                if ([themeConfig isKindOfClass:[NSDictionary class]]){
                    OLKiteTheme *theme = [[OLKiteTheme alloc] init];
                    
                    id valuesDict = themeConfig[[[NSLocale preferredLanguages] objectAtIndex:0]];
                    if (!valuesDict){
                        valuesDict = themeConfig[@"en"];
                    }
                    if (!valuesDict && [themeConfig allKeys].count > 0){
                        valuesDict = themeConfig[[themeConfig allKeys].firstObject];
                    }
                    
                    if (valuesDict){
                        
                        theme.burgerMenuHeader = [NSURL URLWithString:valuesDict[@"kiosk_burger_menu_header"]];
                        theme.endSessionButton = [NSURL URLWithString:valuesDict[@"kiosk_end_session_button"]];
                        theme.navigationIcon = [NSURL URLWithString:valuesDict[@"kiosk_navigation_icon"]];
                        theme.privacyPolicy = [NSURL URLWithString:valuesDict[@"kiosk_privacy_policy_url"]];
                        theme.receiptLogo = [NSURL URLWithString:valuesDict[@"kiosk_receipt_logo"]];
                        theme.secretReveal = [NSURL URLWithString:valuesDict[@"kiosk_secret_reveal"]];
                        theme.shippingOption1 = [NSURL URLWithString:valuesDict[@"kiosk_shipping_option_to_store"]];
                        theme.shippingOption2 = [NSURL URLWithString:valuesDict[@"kiosk_shipping_option_to_home"]];
                        theme.startScreenLandscape = [NSURL URLWithString:valuesDict[@"kiosk_start_screen_landscape"]];
                        theme.startScreenPortrait = [NSURL URLWithString:valuesDict[@"kiosk_start_screen_portrait"]];
                        theme.termsAndConditions = [NSURL URLWithString:valuesDict[@"kiosk_terms_and_conditions_url"]];
                        theme.splashScreen = [NSURL URLWithString:valuesDict[@"kiosk_splash_screen"]];
                        theme.ctaColor = valuesDict[@"kiosk_cta_color"];
                    }
                    
                    if ([themeConfig[@"remove_payment_gateway"] isKindOfClass:[NSNumber class]]){
                        theme.kioskEnablePayAtTheTill = [themeConfig[@"remove_payment_gateway"] boolValue];
                    }
                    
                    if ([themeConfig[@"promo_code_checkout"] isKindOfClass:[NSNumber class]]){
                        theme.kioskRequirePromoCode = [themeConfig[@"promo_code_checkout"] boolValue];
                    }
                    
                    if ([themeConfig[@"ship_to_store"] isKindOfClass:[NSDictionary class]]){
                        NSDictionary *addressDict = themeConfig[@"ship_to_store"];
                        OLAddress *address = [[OLAddress alloc] init];
                        address.companyName = addressDict[@"company_name"];
                        address.line1 = addressDict[@"shipping_address_1"];
                        address.line2 = addressDict[@"shipping_address_2"];
                        address.city = addressDict[@"city"];
                        address.stateOrCounty = addressDict[@"county_state"];
                        address.zipOrPostcode = addressDict[@"postal_code"];
                        address.country = [OLCountry countryForCode:addressDict[@"country_code"]];
                        
                        theme.kioskShipToStoreAddress = address;
                    }
                    
                    [[OLKiteABTesting sharedInstance] setTheme:theme];
                }
                
                id objects = json[@"objects"];
                if ([objects isKindOfClass:[NSArray class]]) {
                    for (id productTemplate in objects) {
                        if ([productTemplate isKindOfClass:[NSDictionary class]]) {
                            if (![productTemplate[@"active"] boolValue] && [OLKitePrintSDK environment] == OLKitePrintSDKEnvironmentLive){
                                continue;
                            }
                            else if (![productTemplate[@"sandbox_active"] boolValue] && [OLKitePrintSDK environment] == OLKitePrintSDKEnvironmentSandbox){
                                continue;
                            }
                            id name = productTemplate[@"name"];
                            id identifier = productTemplate[@"template_id"];
                            id costs = productTemplate[@"cost"];
                            id imagesPerSheet = productTemplate[@"images_per_page"];
                            id product = productTemplate[@"product"];
                            
                            NSDictionary *upsellOffers = [productTemplate[@"upsell_offers"] isKindOfClass:[NSArray class]] ? productTemplate[@"upsell_offers"] : nil;
                            
                            NSNumber *enabledNumber = productTemplate[@"enabled"];
                            NSString *description = productTemplate[@"description"];
                            NSString *descriptionMarkdown = productTemplate[@"description_markdown"];
                            BOOL enabled = enabledNumber == nil ? YES : [enabledNumber boolValue];
                            
                            NSNumber *printInStoreNumber = productTemplate[@"print_in_store"];
                            BOOL printInStore = printInStoreNumber == nil ? NO : [printInStoreNumber boolValue];
                            
                            NSDictionary *shippingCosts = [productTemplate[@"shipping_costs"] isKindOfClass:[NSDictionary class]] ? productTemplate[@"shipping_costs"] : nil;
                            
                            NSNumber *gridCountX = [productTemplate[@"grid_count_x"] isKindOfClass:[NSNumber class]] ? productTemplate[@"grid_count_x"] : nil;
                            NSNumber *gridCountY = [productTemplate[@"grid_count_y"] isKindOfClass:[NSNumber class]] ? productTemplate[@"grid_count_y"] : nil;
                            
                            NSMutableArray<NSURL *> *representationAssets;
                            if ([productTemplate[@"ios_calendar_assets"] isKindOfClass:[NSArray class]]){
                                representationAssets = [[NSMutableArray alloc] init];
                                for (id assetURL in productTemplate[@"ios_calendar_assets"]){
                                    NSURL *url = [NSURL URLWithString:assetURL];
                                    if (url){
                                        [representationAssets addObject:url];
                                    }
                                }
                            }
                            
                            NSURL *logo;
                            if ([productTemplate[@"ios_calendar_logo"] isKindOfClass:[NSString class]]){
                                logo = [NSURL URLWithString:productTemplate[@"ios_calendar_logo"]];
                            }
                            
                            if ([name isKindOfClass:[NSString class]]
                                && [identifier isKindOfClass:[NSString class]]
                                && [costs isKindOfClass:[NSArray class]]
                                && (imagesPerSheet == nil || [imagesPerSheet isKindOfClass:[NSNumber class]])
                                && (product == nil || [product isKindOfClass:[NSDictionary class]])) {
                                
                                NSMutableDictionary<NSString *, NSString *> *coverPhotos = [[NSMutableDictionary<NSString *, NSString *> alloc] init];
                                NSArray *productShots;
                                NSString *productClass;
                                NSString *productType;
                                NSString *uiClass;
                                UIColor *labelColor;
                                CGSize sizeCm = CGSizeZero;
                                CGSize sizeInches = CGSizeZero;
                                UIEdgeInsets imageBleed = UIEdgeInsetsZero;
                                UIEdgeInsets imageBorder = UIEdgeInsetsZero;
                                NSString *maskImageURL;
                                NSString *shortDescription;
                                NSString *productBackgroundImageURL;
                                NSString *productHighlightsURL;
                                NSString *code;
                                CGSize sizePx = CGSizeZero;
                                NSString *classPhoto;
                                NSArray *supportedOptions;
                                NSString *collectionId;
                                NSString *collectionName;
                                OLProductRepresentation *productRepresentation;
                                if (product){
                                    NSArray *coverPhotoDicts = product[@"cover_photo_variants"];
                                    if ([coverPhotoDicts isKindOfClass:[NSArray class]]){
                                        for (NSDictionary *dict in coverPhotoDicts){
                                            if ([dict isKindOfClass:[NSDictionary class]]){
                                                if ([dict[@"variant_id"] isKindOfClass:[NSString class]] && [dict[@"url"] isKindOfClass:[NSString class]]){
                                                    coverPhotos[dict[@"variant_id"]] = dict[@"url"];
                                                }
                                            }
                                        }
                                    }
                                    
                                    collectionId = [product[@"collection_id"] isKindOfClass:[NSString class]] ? product[@"collection_id"] : nil;
                                    collectionName = [product[@"collection_name"] isKindOfClass:[NSString class]] ? product[@"collection_name"] : nil;
                                    
                                    maskImageURL = [product[@"mask_url"] isKindOfClass:[NSString class]] ? product[@"mask_url"] : nil;
                                    productBackgroundImageURL = [product[@"product_background_image_url"] isKindOfClass:[NSString class]] ? product[@"product_background_image_url"] : nil;
                                    productHighlightsURL = [product[@"product_highlights_url"] isKindOfClass:[NSString class]] ? product[@"product_highlights_url"] : nil;
                                    
                                    shortDescription = [product[@"short_description"] isKindOfClass:[NSString class]] ? product[@"short_description"] : nil;
                                    
                                    if ([product[@"ios_sdk_product_shots"] isKindOfClass:[NSArray class]]){
                                        productShots = product[@"ios_sdk_product_shots"];
                                    }
                                    
                                    classPhoto = [product[@"ios_sdk_class_photo"] isKindOfClass:[NSString class]] ? product[@"ios_sdk_class_photo"] : nil;
                                    
                                    productClass = [product[@"ios_sdk_product_class"] isKindOfClass:[NSString class]] ? product[@"ios_sdk_product_class"] : nil;
                                    
                                    productType = [product[@"ios_sdk_product_type"] isKindOfClass:[NSString class]] ? product[@"ios_sdk_product_type"] : nil;
                                    
                                    uiClass = [product[@"ios_sdk_ui_class"] isKindOfClass:[NSString class]] ? product[@"ios_sdk_ui_class"] : nil;
                                    
                                    supportedOptions = [product[@"supported_options"] isKindOfClass:[NSArray class]] ? product[@"supported_options"] : nil;
                                    
                                    NSArray *colorArray = [product[@"ios_sdk_label_color"] isKindOfClass:[NSArray class]] ? product[@"ios_sdk_label_color"] : nil;
                                    if (colorArray){
                                        NSNumber *red = [colorArray[0] isKindOfClass:[NSNumber class]] ? colorArray[0] : nil;
                                        NSNumber *green = [colorArray[1] isKindOfClass:[NSNumber class]] ? colorArray[1] : nil;
                                        NSNumber *blue = [colorArray[2] isKindOfClass:[NSNumber class]] ? colorArray[2] : nil;
                                        if (red && blue && green){
                                            labelColor = [UIColor colorWithRed:[red doubleValue]/255.0 green:[green doubleValue]/255.0 blue:[blue doubleValue]/255.0 alpha:1.0];
                                        }
                                    }
                                    
                                    NSArray *bleedArray = [product[@"mask_bleed"] isKindOfClass:[NSArray class]] ? product[@"mask_bleed"] : nil;
                                    if (bleedArray){
                                        imageBleed = UIEdgeInsetsMake([bleedArray[0] floatValue], [bleedArray[3] floatValue], [bleedArray[2] floatValue], [bleedArray[1] floatValue]);
                                    }
                                    
                                    NSArray *borderArray = [product[@"ios_image_border"] isKindOfClass:[NSArray class]] ? product[@"ios_image_border"] : nil;
                                    if (borderArray){
                                        imageBorder = UIEdgeInsetsMake([borderArray[0] floatValue], [borderArray[3] floatValue], [borderArray[2] floatValue], [borderArray[1] floatValue]);
                                    }
                                    
                                    NSDictionary *representationDict = [product[@"product_representation"] isKindOfClass:[NSDictionary class]] ? product[@"product_representation"] : nil;
                                    
                                    if (representationDict && [representationDict[@"layouts"] isKindOfClass:[NSDictionary class]] && [representationDict[@"pages"] isKindOfClass:[NSArray class]]){
                                        
                                        //Parse layouts
                                        NSMutableDictionary *layouts = [[NSMutableDictionary alloc] init];
                                        for (NSString *layoutKey in [representationDict[@"layouts"] allKeys]){
                                            if (![representationDict[@"layouts"][layoutKey] isKindOfClass:[NSArray class]]){
                                                continue;
                                            }
                                            
                                            OLPageLayout *pageLayout = [[OLPageLayout alloc] init];
                                            NSMutableArray *positions = [[NSMutableArray alloc] init];
                                            for (NSDictionary *layoutInfoDict in representationDict[@"layouts"][layoutKey]){
                                                if (![layoutInfoDict isKindOfClass:[NSDictionary class]]){
                                                    continue;
                                                }
                                                [positions addObject:[NSValue valueWithCGRect:CGRectMake([layoutInfoDict[@"x"] doubleValue]/100.0, [layoutInfoDict[@"y"] doubleValue]/100.0, [layoutInfoDict[@"width"] doubleValue]/100.0, [layoutInfoDict[@"height"] doubleValue]/100.0)]];
                                            }
                                            pageLayout.positions = positions;
                                            layouts[layoutKey] = pageLayout;
                                        }
                                        
                                        //Parse pages
                                        NSMutableArray *pages = [[NSMutableArray alloc] init];
                                        for (NSDictionary *pageDict in representationDict[@"pages"]){
                                            if (![pageDict isKindOfClass:[NSDictionary class]] || ![pageDict[@"allowed_layouts"] isKindOfClass:[NSArray class]]){
                                                continue;
                                            }
                                            
                                            for (int i = 0; i < [pageDict[@"min"] intValue]; i++){
                                                OLPageLayout *layout = layouts[[pageDict[@"allowed_layouts"] firstObject]];
                                                if (layout){
                                                    [pages addObject:layout];
                                                }
                                            }
                                        }
                                        
                                        productRepresentation = [[OLProductRepresentation alloc] init];
                                        productRepresentation.pages = pages;
                                    }
                                    
                                    //Fallback for older photobook products that don't yet have the new product representation
                                    if (!productRepresentation && [uiClass isEqualToString:@"PHOTOBOOK"]){
                                        OLPageLayout *pageLayout = [[OLPageLayout alloc] init];
                                        pageLayout.positions = @[[NSValue valueWithCGRect:CGRectMake(0, 0, 1-imageBorder.top*2, 1-imageBorder.left*2)]];
                                        
                                        productRepresentation = [[OLProductRepresentation alloc] init];
                                        NSMutableArray *pages = [[NSMutableArray alloc] init];
                                        
                                        for (int i = 0; i < [imagesPerSheet intValue]; i++){
                                            [pages addObject:pageLayout];
                                        }
                                        productRepresentation.pages = pages;
                                    }
                                    
                                    
                                    NSDictionary *sizeDict = [product[@"size"] isKindOfClass:[NSDictionary class]] ? product[@"size"] : nil;
                                    if (sizeDict){
                                        NSDictionary *cmDict = [sizeDict[@"cm"] isKindOfClass:[NSDictionary class]] ? sizeDict[@"cm"] : nil;
                                        NSDictionary *inchDict = [sizeDict[@"inch"] isKindOfClass:[NSDictionary class]] ? sizeDict[@"inch"] : nil;
                                        NSDictionary *pxDict = [sizeDict[@"px"] isKindOfClass:[NSDictionary class]] ? sizeDict[@"px"] : nil;
                                        if (cmDict){
                                            NSNumber *cmHeight = [cmDict[@"height"] isKindOfClass:[NSNumber class]] ? cmDict[@"height"] : nil;
                                            NSNumber *cmWidth = [cmDict[@"width"] isKindOfClass:[NSNumber class]] ? cmDict[@"width"] : nil;
                                            if (cmHeight && cmWidth){
                                                sizeCm = CGSizeMake([cmWidth doubleValue], [cmHeight doubleValue]);
                                            }
                                        }
                                        if (inchDict){
                                            NSNumber *inchHeight = [inchDict[@"height"] isKindOfClass:[NSNumber class]] ? inchDict[@"height"] : nil;
                                            NSNumber *inchWidth = [inchDict[@"width"] isKindOfClass:[NSNumber class]] ? inchDict[@"width"] : nil;
                                            if (inchHeight && inchWidth){
                                                sizeInches = CGSizeMake([inchWidth doubleValue], [inchHeight doubleValue]);
                                            }
                                        }
                                        if (pxDict){
                                            NSNumber *pxHeight = [pxDict[@"height"] isKindOfClass:[NSNumber class]] ? pxDict[@"height"] : nil;
                                            NSNumber *pxWidth = [pxDict[@"width"] isKindOfClass:[NSNumber class]] ? pxDict[@"width"] : nil;
                                            if (pxHeight && pxWidth){
                                                sizePx = CGSizeMake([pxWidth doubleValue], [pxHeight doubleValue]);
                                            }
                                        }
                                        
                                        code = [product[@"product_code"] isKindOfClass:[NSString class]] ? product[@"product_code"] : nil;
                                    }
                                }
                                
                                NSMutableDictionary *costPerSheetByCurrencyCode = [[NSMutableDictionary alloc] init];
                                NSMutableDictionary *originalCostPerSheetByCurrencyCode = [[NSMutableDictionary alloc] init];
                                for (id cost in costs) {
                                    if ([cost isKindOfClass:[NSDictionary class]]) {
                                        id currencyCode = cost[@"currency"];
                                        id amount = cost[@"amount"];
                                        id originalAmount = cost[@"original_amount"];
                                        if ([currencyCode isKindOfClass:[NSString class]] && [amount isKindOfClass:[NSString class]]) {
                                            costPerSheetByCurrencyCode[currencyCode] = [NSDecimalNumber decimalNumberWithString:amount];
                                        }
                                        if ([currencyCode isKindOfClass:[NSString class]] && [originalAmount isKindOfClass:[NSString class]]){
                                            originalCostPerSheetByCurrencyCode[currencyCode] = [NSDecimalNumber decimalNumberWithString:originalAmount];
                                        }
                                    }
                                }
                                
                                if (costPerSheetByCurrencyCode.count > 0) {
                                    OLProductTemplate *t = [[OLProductTemplate alloc] initWithIdentifier:identifier name:name sheetQuantity:[imagesPerSheet unsignedIntegerValue] sheetCostsByCurrencyCode:costPerSheetByCurrencyCode enabled:enabled];
                                    t.coverPhotosDict = coverPhotos;
                                    t.originalCostsByCurrencyCode = originalCostPerSheetByCurrencyCode;
                                    t.productPhotographyURLs = productShots;
                                    t.templateUI = [OLProductTemplate templateUIWithIdentifier:uiClass];
                                    t.templateType = productType;
                                    t.templateClass = productClass;
                                    t.labelColor = labelColor;
                                    t.sizeCm = sizeCm;
                                    t.sizeInches = sizeInches;
                                    t.productCode = code;
                                    t.imageBleed = imageBleed;
                                    t.maskImageURL = [NSURL URLWithString:maskImageURL];
                                    t.shortDescription = shortDescription;
                                    t.productBackgroundImageURL = [NSURL URLWithString:productBackgroundImageURL];
                                    t.productHighlightsImageURL = [NSURL URLWithString:productHighlightsURL];
                                    t.sizePx = sizePx;
                                    t.classPhotoURL = [NSURL URLWithString:classPhoto];
                                    t.imageBorder = imageBorder;
                                    t.productDescription = description;
                                    t.productDescriptionMarkdown = descriptionMarkdown;
                                    t.shippingCosts = shippingCosts;
                                    t.gridCountX = [gridCountX integerValue];
                                    t.gridCountY = [gridCountY integerValue];
                                    t.supportedOptions = supportedOptions;
                                    t.productRepresentation = productRepresentation;
                                    t.printInStore = printInStore;
                                    
                                    t.collectionId = collectionId;
                                    t.collectionName = collectionName;
                                    t.logo = logo;
                                    t.representationAssets = representationAssets;
                                    
                                    NSMutableArray <OLUpsellOffer *>*upsellOffersClean = [[NSMutableArray alloc] init];
                                    for (NSDictionary *offerDict in upsellOffers){
                                        if ([offerDict isKindOfClass:[NSDictionary class]]){
                                            [upsellOffersClean addObject:[OLUpsellOffer upsellOfferWithDictionary:offerDict]];
                                        }
                                    }
                                    t.upsellOffers = upsellOffersClean;
                                    
                                    for (OLProductTemplateCollection *collection in templateCollections){
                                        if ([collection containsTemplateIdentifier:identifier]){
                                            OLProductTemplateOption *option = [[OLProductTemplateOption alloc] initWithTemplateCollection:collection];
                                            NSMutableArray *options = [t.options mutableCopy];
                                            [options addObject:option];
                                            t.options = options;
                                        }
                                    }
                                    
                                    [acc addObject:t];
                                }
                            }
                        }
                    }
                }
                
                if (nextPage != nil) {
                    [self fetchTemplatesWithURL:nextPage templateAccumulator:acc handler:handler];
                } else {
                    self.req = nil;
                    NSMutableSet *coverPhotoVariants = [[NSMutableSet alloc] init];
                    
                    for (OLProductTemplate *t in acc){
                        [coverPhotoVariants addObjectsFromArray:t.coverPhotosDict.allKeys];
                    }
                    
                    NSMutableDictionary *experimentDict = [[NSMutableDictionary alloc] init];
                    for (NSString *s in coverPhotoVariants){
                        experimentDict[s] = [NSNumber numberWithDouble:1.0/(double)coverPhotoVariants.count];
                    }
                    [[OLKiteABTesting sharedInstance] setupCoverPhotoTestWithExperimentDict:experimentDict];
                    handler(acc, nil);
                }
            } else {
                id errorObj = json[@"error"];
                if ([errorObj isKindOfClass:[NSDictionary class]]) {
                    id errorMessage = errorObj[@"message"];
                    if ([errorMessage isKindOfClass:[NSString class]]) {
                        NSError *error = [NSError errorWithDomain:kOLKiteSDKErrorDomain code:kOLKiteSDKErrorCodeServerFault userInfo:@{NSLocalizedDescriptionKey:errorMessage}];
                        handler(nil, error);
                        return;
                    }
                }
                
                handler(nil, [NSError errorWithDomain:kOLKiteSDKErrorDomain code:kOLKiteSDKErrorCodeServerFault userInfo:@{NSLocalizedDescriptionKey: NSLocalizedStringFromTableInBundle(@"Failed to synchronize product templates. Please try again.", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"")}]);
            }
        }
    }];
}

- (void)cancel {
    [self.req cancel];
    self.req = nil;
}

@end
