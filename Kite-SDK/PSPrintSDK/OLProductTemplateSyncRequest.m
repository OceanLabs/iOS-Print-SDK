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

#import "OLProductTemplateSyncRequest.h"
#import "OLKitePrintSDK.h"
#import "OLProductTemplate.h"
#import "OLConstants.h"
#import "OLKiteABTesting.h"
#import "OLKiteUtils.h"
#import "OLArtboardTemplate.h"
#import "OLProductRepresentation.h"
#import "OLProductTemplateCollection.h"
#import "OLUserSession.h"
#import "OLShippingClass.h"
#import "OLAPIClient.h"

@import PayPalDynamicLoader;
@import Stripe;

@interface OLProductTemplateSyncRequest ()
@property (strong, nonatomic) NSURL *nextPage;
@property (nonatomic, strong) NSNumber *requestIdentifier;
@end

@interface OLKitePrintSDK (Private)

+ (NSString *)apiEndpoint;
+ (NSString *)apiVersion;

@end

@implementation OLProductTemplateSyncRequest

- (void)sync:(OLTemplateSyncRequestCompletionHandler)handler {
    NSAssert(self.requestIdentifier == nil, @"Oops only one template sync request should be in progress at any given time");
    NSString *urlString;
    if (self.templateId){
        urlString = [NSString stringWithFormat:@"%@/%@/template/?template_id__in=%@&limit=1", [OLKitePrintSDK apiEndpoint], [OLKitePrintSDK apiVersion], self.templateId];
    } else {
        urlString = [NSString stringWithFormat:@"%@/%@/template/?limit=1000", [OLKitePrintSDK apiEndpoint], [OLKitePrintSDK apiVersion]];
    }
    NSURL *url = [NSURL URLWithString:urlString];
    [self fetchTemplatesWithURL:url templateAccumulator:[[NSMutableArray alloc] init] handler:handler];
}

- (void)fetchTemplatesWithURL:(NSURL *)url templateAccumulator:(NSMutableArray *)acc handler:(OLTemplateSyncRequestCompletionHandler)handler {
    NSDictionary *headers = @{@"Authorization": [NSString stringWithFormat:@"ApiKey %@:", [OLKitePrintSDK apiKey]]};
    
    NSNumber *identifier = nil;
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [[OLAPIClient shared] getWithURL:url parameters:nil headers:headers requestIdentifier:&identifier completionHandler:^(NSInteger httpStatusCode, id json, NSError *error) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        if (error) {
            if (httpStatusCode == 401) {
                // unauthorized
                error = [NSError errorWithDomain:kOLKiteSDKErrorDomain code:kOLKiteSDKErrorCodeUnauthorized userInfo:@{NSLocalizedDescriptionKey: kOLKiteSDKErrorMessageUnauthorized}];
            }
            
            self.requestIdentifier = nil;
            handler(nil, error);
        } else {
            if (httpStatusCode >= 200 & httpStatusCode <= 299) {
                self.nextPage = nil;
                id meta = json[@"meta"];
                if ([meta isKindOfClass:[NSDictionary class]]) {
                    id next = meta[@"next"];
                    if ([next isKindOfClass:[NSString class]]) {
                        self.nextPage = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", [OLKitePrintSDK apiEndpoint], next]];
                    }
                }
                
                id paymentKeys = json[@"payment_keys"];
                if ([paymentKeys isKindOfClass:[NSDictionary class]]){
                    id paypalKeys = paymentKeys[@"paypal"];
                    if([OLPayPalWrapper isPayPalAvailable] && [paypalKeys isKindOfClass:[NSDictionary class]]){
                        id publicKey = paypalKeys[@"public_key"];
                        if ([publicKey isKindOfClass:[NSString class]]){
                            if ([OLKitePrintSDK environment] == OLKitePrintSDKEnvironmentSandbox){
                                [OLPayPalWrapper initializeWithClientIdsForEnvironments:@{@"sandbox": publicKey}];
                                [OLPayPalWrapper preconnectWithEnvironment:@"sandbox"];
                            } else {
                                [OLPayPalWrapper initializeWithClientIdsForEnvironments:@{@"live": publicKey}];
                                [OLPayPalWrapper preconnectWithEnvironment:@"live"];
                            }
                        }
                    }
                    
                    id stripeKeys = paymentKeys[@"stripe"];
                    if([stripeKeys isKindOfClass:[NSDictionary class]]){
                        id publicKey = stripeKeys[@"public_key"];
                        if ([publicKey isKindOfClass:[NSString class]]){
                            [Stripe setDefaultPublishableKey:publicKey];
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
                            NSString *name = collection[@"option_label"];
                            NSString *code = collection[@"name"];
                            NSArray *templates = collection[@"templates"];
                            OLProductTemplateCollection *templateCollection = [[OLProductTemplateCollection alloc] initWithName:name code:code templates:templates];
                            [templateCollections addObject:templateCollection];
                        }
                    }
                }
                
                id payPalSupportedCurrencies = json[@"paypal_supported_currencies"];
                if ([payPalSupportedCurrencies isKindOfClass:[NSArray class]]){
                    [OLKiteABTesting sharedInstance].paypalSupportedCurrencies = payPalSupportedCurrencies;
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
                            
                            NSNumber *enabledNumber = productTemplate[@"enabled"];
                            NSString *description = productTemplate[@"description"];
                            NSString *descriptionMarkdown = [productTemplate[@"description_markdown"] isKindOfClass:[NSString class]] ? productTemplate[@"description_markdown"] : @"";
                            BOOL enabled = enabledNumber == nil ? YES : [enabledNumber boolValue];
                            
                            NSNumber *printInStoreNumber = productTemplate[@"print_in_store"];
                            BOOL printInStore = printInStoreNumber == nil ? NO : [printInStoreNumber boolValue];
                            
                            NSMutableDictionary *templateShippingClasses = [[NSMutableDictionary alloc] init];
                            NSDictionary *shippingRegions = productTemplate[@"shipping_regions"];
                            if ([shippingRegions isKindOfClass:[NSDictionary class]]){
                                for (NSString *key in shippingRegions.allKeys){
                                    NSDictionary *region = shippingRegions[key];
                                    if ([region isKindOfClass:[NSDictionary class]]){
                                        NSArray *shippingClasses = region[@"shipping_classes"];
                                        if ([shippingClasses isKindOfClass:[NSArray class]]){
                                            for (NSDictionary *shippingClassDict in shippingClasses){
                                                if ([shippingClassDict isKindOfClass:[NSDictionary class]]){
                                                    OLShippingClass *shippingClass = [[OLShippingClass alloc] init];
                                                    shippingClass.displayName = [shippingClassDict[@"display_name"] isKindOfClass:[NSString class]] ? shippingClassDict[@"display_name"] : nil;
                                                    shippingClass.minDeliveryTime = [shippingClassDict[@"min_delivery_time"] isKindOfClass:[NSNumber class]] ? shippingClassDict[@"min_delivery_time"] : nil;
                                                    shippingClass.maxDeliveryTime = [shippingClassDict[@"max_delivery_time"] isKindOfClass:[NSNumber class]] ? shippingClassDict[@"max_delivery_time"] : nil;
                                                    shippingClass.tracked = [shippingClassDict[@"tracked"] isKindOfClass:[NSNumber class]] ? [shippingClassDict[@"tracked"] boolValue] : NO;
                                                    shippingClass.className = [shippingClassDict[@"mobile_shipping_name"] isKindOfClass:[NSString class]] && ![shippingClassDict[@"mobile_shipping_name"] isEqualToString:@""] ? shippingClassDict[@"mobile_shipping_name"] : nil;
                                                    shippingClass.identifier = [shippingClassDict[@"id"] isKindOfClass:[NSNumber class]] ? [shippingClassDict[@"id"] integerValue] : 0;
                                                    NSMutableDictionary *costs = [[NSMutableDictionary alloc] init];
                                                    NSArray *costsArray = [shippingClassDict[@"costs"] isKindOfClass:[NSArray class]] ? shippingClassDict[@"costs"] : nil;
                                                    for (NSDictionary *dict in costsArray){
                                                        if ([dict isKindOfClass:[NSDictionary class]]){
                                                            costs[dict[@"currency"]] = dict[@"amount"];
                                                        }
                                                    }
                                                    shippingClass.costs = costs;
                                                    
                                                    NSMutableArray *existingClassesArray = templateShippingClasses[key];
                                                    if (!existingClassesArray){
                                                        existingClassesArray = [[NSMutableArray alloc] init];
                                                    }
                                                    BOOL exists = NO;
                                                    for (OLShippingClass *existingShippingClass in existingClassesArray){
                                                        if ([shippingClass.displayName isEqualToString:existingShippingClass.displayName] && shippingClass.tracked == existingShippingClass.tracked){
                                                            exists = YES;
                                                            break;
                                                        }
                                                    }
                                                    
                                                    if (!exists){
                                                        [existingClassesArray addObject:shippingClass];
                                                    }
                                                    templateShippingClasses[key] = existingClassesArray;
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            
                            NSDictionary *countryMapping = [productTemplate[@"country_to_region_mapping"] isKindOfClass:[NSDictionary class]] ? productTemplate[@"country_to_region_mapping"] : nil;
                            
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
                                NSString *blendMode;
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
                                NSMutableArray *fulfilmentItems;
                                BOOL supportsTextOnBorder = NO;
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
                                    
                                    supportsTextOnBorder = [product[@"supports_text_on_border"] isKindOfClass:[NSNumber class]] ? [product[@"supports_text_on_border"] boolValue] : NO;
                                    
                                    NSArray *fulfilmentFields = product[@"fulfilment_fields"];
                                    if ([fulfilmentFields isKindOfClass:[NSArray class]]){
                                        fulfilmentItems = [[NSMutableArray alloc] init];
                                        for (NSDictionary *dict in fulfilmentFields){
                                            OLFulfilmentItem *item = [[OLFulfilmentItem alloc] init];
                                            item.costs = [dict[@"cost"] isKindOfClass:[NSArray class]] ? dict[@"cost"] : nil;
                                            item.itemDescription = [dict[@"description"] isKindOfClass:[NSString class]] ? dict[@"description"] : nil;
                                            item.identifier = [dict[@"field_name"] isKindOfClass:[NSString class]] ? dict[@"field_name"] : nil;
                                            item.required = [dict[@"required"] isKindOfClass:[NSNumber class]] ? [dict[@"required"] boolValue] : NO;
                                            item.name = [dict[@"verbose_name"] isKindOfClass:[NSString class]] ? dict[@"verbose_name"] : nil;
                                            
                                            id s = dict[@"product_highlights_url"];
                                            item.productHighlightsUrl = [s isKindOfClass:[NSString class]] && ![s isEqualToString:@""] ? [NSURL URLWithString:s] : nil;
                                            s = dict[@"mask_url"];
                                            item.maskUrl = [s isKindOfClass:[NSString class]] && ![s isEqualToString:@""] ? [NSURL URLWithString:s] : nil;
                                            s = dict[@"product_background_image_url"];
                                            item.productBackGroundImageURL = [s isKindOfClass:[NSString class]] && ![s isEqualToString:@""] ? [NSURL URLWithString:s] : nil;
                                            
                                            [fulfilmentItems addObject:item];
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
                                    blendMode = [product[@"mask_blend_mode"] isKindOfClass:[NSString class]] ? product[@"mask_blend_mode"] : nil;
                                    
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
                                            
                                            OLArtboardTemplate *pageLayout = [[OLArtboardTemplate alloc] init];
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
                                                OLArtboardTemplate *layout = layouts[[pageDict[@"allowed_layouts"] firstObject]];
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
                                        OLArtboardTemplate *pageLayout = [[OLArtboardTemplate alloc] init];
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
                                    t.gridCountX = [gridCountX integerValue];
                                    t.gridCountY = [gridCountY integerValue];
                                    t.supportedOptions = supportedOptions;
                                    t.productRepresentation = productRepresentation;
                                    t.printInStore = printInStore;
                                    
                                    t.collectionId = collectionId;
                                    t.collectionName = collectionName;
                                    t.logo = logo;
                                    t.representationAssets = representationAssets;
                                    t.fulfilmentItems = fulfilmentItems;
                                    t.supportsTextOnBorder = supportsTextOnBorder;
                                    
                                    t.countryMapping = countryMapping;
                                    t.shippingClasses = templateShippingClasses;
                                    
                                    if ([blendMode isEqualToString:@"MULTIPLY"]){
                                        t.blendMode = OLImageBlendModeMultiply;
                                    }
                                    
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
                
                if (self.nextPage != nil) {
                    if ([[OLUserSession currentSession] shouldLoadTemplatesProgressively] && [OLKiteABTesting sharedInstance].progressiveTemplateLoading){
                        handler(acc, nil);
                    }
                    [self fetchTemplatesWithURL:self.nextPage templateAccumulator:acc handler:handler];
                }
                else {
                    self.requestIdentifier = nil;
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
            }
            else {
                id errorObj = json[@"error"];
                if ([errorObj isKindOfClass:[NSDictionary class]]) {
                    id errorMessage = errorObj[@"message"];
                    if ([errorMessage isKindOfClass:[NSString class]]) {
                        NSError *error = [NSError errorWithDomain:kOLKiteSDKErrorDomain code:kOLKiteSDKErrorCodeServerFault userInfo:@{NSLocalizedDescriptionKey:errorMessage}];
                        handler(nil, error);
                        return;
                    }
                }
                
                handler(nil, [NSError errorWithDomain:kOLKiteSDKErrorDomain code:kOLKiteSDKErrorCodeServerFault userInfo:@{NSLocalizedDescriptionKey: NSLocalizedStringFromTableInBundle(@"Failed to synchronize product templates. Please try again.", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"")}]);
            }
        }
    }];
    self.requestIdentifier = identifier;
}

- (void)cancel {
    if (self.requestIdentifier == nil) {
        return;
    }
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [[OLAPIClient shared] cancelRequestWithIdentifier:self.requestIdentifier];
    self.requestIdentifier = nil;
}

- (BOOL)isInProgress{
    return self.requestIdentifier != nil || self.nextPage;
}

@end
