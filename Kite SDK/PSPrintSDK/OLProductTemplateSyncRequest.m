//
//  OLTemplateSyncRequest.m
//  Kite SDK
//
//  Created by Deon Botha on 18/03/2014.
//  Copyright (c) 2014 Deon Botha. All rights reserved.
//

#import "OLProductTemplateSyncRequest.h"
#import "OLBaseRequest.h"
#import "OLKitePrintSDK.h"
#import "OLProductTemplate.h"
#import "OLConstants.h"

@interface OLProductTemplateSyncRequest ()
@property (nonatomic, strong) OLBaseRequest *req;
@end

@interface OLKitePrintSDK (Private)

+ (NSString *)apiEndpoint;
+ (NSString *)apiVersion;

@end

@implementation OLProductTemplateSyncRequest

- (void)sync:(OLTemplateSyncRequestCompletionHandler)handler {
    NSAssert(self.req == nil, @"Oops only one template sync request should be in progress at any given time");
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/template/?limit=100", [OLKitePrintSDK apiEndpoint], [OLKitePrintSDK apiVersion]]];
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
                
                id objects = json[@"objects"];
                if ([objects isKindOfClass:[NSArray class]]) {
                    for (id template in objects) {
                        if ([template isKindOfClass:[NSDictionary class]]) {
                            id name = template[@"name"];
                            id identifier = template[@"template_id"];
                            id costs = template[@"cost"];
                            id imagesPerSheet = template[@"images_per_page"];
                            id product = template[@"product"];
                            NSNumber *enabledNumber = template[@"enabled"];
                            NSString *description = template[@"description"];
                            BOOL enabled = enabledNumber == nil ? YES : [enabledNumber boolValue];
                            
                            NSDictionary *shippingCosts = [template[@"shipping_costs"] isKindOfClass:[NSDictionary class]] ? template[@"shipping_costs"] : nil;
                            
                            NSNumber *gridCountX = [template[@"grid_count_x"] isKindOfClass:[NSNumber class]] ? template[@"grid_count_x"] : nil;
                            NSNumber *gridCountY = [template[@"grid_count_y"] isKindOfClass:[NSNumber class]] ? template[@"grid_count_y"] : nil;
                            
                            if ([name isKindOfClass:[NSString class]]
                                && [identifier isKindOfClass:[NSString class]]
                                && [costs isKindOfClass:[NSArray class]]
                                && (imagesPerSheet == nil || [imagesPerSheet isKindOfClass:[NSNumber class]])
                                && (product == nil || [product isKindOfClass:[NSDictionary class]])) {
                                
                                NSString *coverPhoto;
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
                                NSString *code;
                                CGSize sizePx = CGSizeZero;
                                NSString *classPhoto;
                                if (product){
                                    coverPhoto = [product[@"ios_sdk_cover_photo"] isKindOfClass:[NSString class]] ? product[@"ios_sdk_cover_photo"] : nil;
                                    
                                    maskImageURL = [product[@"mask_url"] isKindOfClass:[NSString class]] ? product[@"mask_url"] : nil;
                                    
                                    if ([product[@"ios_sdk_product_shots"] isKindOfClass:[NSArray class]]){
                                        productShots = product[@"ios_sdk_product_shots"];
                                    }
                                    
                                    classPhoto = [product[@"ios_sdk_class_photo"] isKindOfClass:[NSString class]] ? product[@"ios_sdk_class_photo"] : nil;
                                    
                                    productClass = [product[@"ios_sdk_product_class"] isKindOfClass:[NSString class]] ? product[@"ios_sdk_product_class"] : nil;
                                    
                                    productType = [product[@"ios_sdk_product_type"] isKindOfClass:[NSString class]] ? product[@"ios_sdk_product_type"] : nil;
                                    
                                    uiClass = [product[@"ios_sdk_ui_class"] isKindOfClass:[NSString class]] ? product[@"ios_sdk_ui_class"] : nil;
                                    
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
                                for (id cost in costs) {
                                    if ([cost isKindOfClass:[NSDictionary class]]) {
                                        id currencyCode = cost[@"currency"];
                                        id amount = cost[@"amount"];
                                        if ([currencyCode isKindOfClass:[NSString class]] && [amount isKindOfClass:[NSString class]]) {
                                            costPerSheetByCurrencyCode[currencyCode] = [NSDecimalNumber decimalNumberWithString:amount];
                                        }
                                    }
                                }
                                
                                if (costPerSheetByCurrencyCode.count > 0) {
                                    OLProductTemplate *t = [[OLProductTemplate alloc] initWithIdentifier:identifier name:name sheetQuantity:[imagesPerSheet unsignedIntegerValue] sheetCostsByCurrencyCode:costPerSheetByCurrencyCode enabled:enabled];
                                    t.coverPhotoURL = [NSURL URLWithString:coverPhoto];
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
                                    t.sizePx = sizePx;
                                    t.classPhotoURL = [NSURL URLWithString:classPhoto];
                                    t.imageBorder = imageBorder;
                                    t.productDescription = description;
                                    t.shippingCosts = shippingCosts;
                                    t.gridCountX = [gridCountX integerValue];
                                    t.gridCountY = [gridCountY integerValue];
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
                
                handler(nil, [NSError errorWithDomain:kOLKiteSDKErrorDomain code:kOLKiteSDKErrorCodeServerFault userInfo:@{NSLocalizedDescriptionKey: NSLocalizedStringFromTableInBundle(@"Failed to synchronize product templates. Please try again.", @"KitePrintSDK", [OLConstants bundle], @"")}]);
            }
        }
    }];
}

- (void)cancel {
    [self.req cancel];
    self.req = nil;
}

@end
