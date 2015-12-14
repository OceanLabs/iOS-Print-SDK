//
//  OLAnalytics.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 1/27/15.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import "OLAnalytics.h"
#import "OLPrintOrder.h"
#import "OLAddress.h"
#import "OLCountry.h"
#import "OLProduct.h"
#import "OLPrintJob.h"
#import "OLKitePrintSDK.h"
#import "AFNetworking.h"
#include <sys/sysctl.h>
#import "OLKiteABTesting.h"
#import "UICKeyChainStore.h"

static NSString *const kKeyUserDistinctId = @"ly.kite.sdk.kKeyUserDistinctId";
static NSString *const kOLMixpanelToken = @"cdf64507670dd359c43aa8895fb87676";
static NSString *const kOLMixpanelURL = @"https://api.mixpanel.com/track/";
static NSString *const kKeySDKLaunchCount = @"ly.kite.sdk.kKeySDKLaunchCount";

static NSString *const kKeyServiceName = @"ly.kite.sdk.kKeyServiceName";

static NSDictionary *extraInfo;

static NSString *nonNilStr(NSString *str) {
    return str == nil ? @"" : str;
}

static __weak id<OLKiteDelegate> kiteDelegate;

@implementation OLAnalytics

+ (void)incrementLaunchSDKCount{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *n = [defaults objectForKey:kKeySDKLaunchCount];
    
    if (!n){
        n = [NSNumber numberWithInteger:0];
    }
    
    n = [NSNumber numberWithInteger:[n integerValue] + 1];
    [defaults setObject:n forKey:kKeySDKLaunchCount];
    [defaults synchronize];
}

+ (NSString *)userDistinctId{
    UICKeyChainStore *keychain = [UICKeyChainStore keyChainStoreWithService:kKeyServiceName];
    NSData *data = [keychain dataForKey:kKeyUserDistinctId];
    NSString *uuid;
    if (data){
        uuid = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }
    else{
        uuid = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        keychain.synchronizable = YES;
        [keychain setData:[NSKeyedArchiver archivedDataWithRootObject:uuid] forKey:kKeyUserDistinctId];
    }
    
    return uuid;
}

+ (NSString *) platform{
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platform = [NSString stringWithUTF8String:machine];
    free(machine);
    return platform;
}

+ (void)sendToMixPanelWithDictionary:(NSDictionary *)dict{
    NSError *error;
    NSData * jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
    
    NSURL *baseURL = [NSURL URLWithString:kOLMixpanelURL];
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithBaseURL:baseURL];
    [manager POST:@"" parameters:@{@"ip": @"1",@"data" : [jsonData base64EncodedStringWithOptions:0]} success:NULL failure:NULL];
}

+ (NSDictionary *)defaultDictionaryForEventName:(NSString *)eventName{
    NSString *environment = @"Live";
    if ([OLKitePrintSDK environment] == kOLKitePrintSDKEnvironmentSandbox) {
        environment = @"Sandbox";
    }
    NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
    NSString *bundleName = nil;
    if ([info objectForKey:@"CFBundleDisplayName"] == nil) {
        bundleName = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *) kCFBundleNameKey];
    } else {
        bundleName = [NSString stringWithFormat:@"%@", [info objectForKey:@"CFBundleDisplayName"]];
    }
    NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    NSString *apiKey = [OLKitePrintSDK apiKey] == nil ? @"Unknown" : [OLKitePrintSDK apiKey];
    
    NSString *localeCountry = @"Unknown";
    if ([OLCountry countryForCurrentLocale] != nil) {
        localeCountry = nonNilStr([OLCountry countryForCurrentLocale].name);
    }
    
    NSMutableDictionary *propertiesDict = [@{
                                             @"token" : kOLMixpanelToken,
                                             @"distinct_id" : [OLAnalytics userDistinctId],
                                             @"App Bundle Id" : [[NSBundle mainBundle] bundleIdentifier],
                                             @"App Name" : bundleName,
                                             @"App Version" : appVersion,
                                             @"platform" : @"iOS",
                                             @"platform version" : [[UIDevice currentDevice] systemVersion],
                                             @"model" : [OLAnalytics platform],
                                             @"Screen Height" : @([UIScreen mainScreen].bounds.size.height),
                                             @"Screen Width" : @([UIScreen mainScreen].bounds.size.width),
                                             @"Environment" : environment,
                                             @"API Key": apiKey,
                                             @"Kite SDK Version": kOLKiteSDKVersion,
                                             @"Locale Country": localeCountry
                                             } mutableCopy];
    if ([extraInfo isKindOfClass:[NSDictionary class]]){
        for (id key in extraInfo.allKeys){
            if ([key isKindOfClass:[NSString class]]){
                propertiesDict[[@"App Extra-" stringByAppendingString:key]] = extraInfo[key];
            }
        }
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *n = [defaults objectForKey:kKeySDKLaunchCount];
    if (n){
        propertiesDict[@"SDK Launch Count"] = n;
    }
    
    NSDictionary *dict = @{@"event" : eventName,
                           @"properties" : propertiesDict};
    return dict;
}

+ (NSDictionary *)dictionaryForJob:(id<OLPrintJob>)job{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    OLProductTemplate *template = [OLProductTemplate templateWithId:[job templateId]];
    if (template){
        dict[kOLAnalyticsProductName] = template.name;
        dict[kOLAnalyticsNumberOfPhotosInItem] = [NSNumber numberWithInteger:[job quantity]];
        dict[kOLAnalyticsQuantity] = [NSNumber numberWithInteger:[job extraCopies]+1];
        dict[kOLAnalyticsItemPrice] = nonNilStr([[OLProduct productWithTemplateId:[job templateId]] unitCost]);
    }
    return dict;
}

+ (void)reportAnalyticsEventToDelegate:(NSString *)eventName
                                   job:(id<OLPrintJob>)job
                            printOrder:(OLPrintOrder *)order
                             extraInfo:(NSDictionary *)info{
    if ([kiteDelegate respondsToSelector:@selector(logKiteAnalyticsEventWithInfo:)]){
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        dict[kOLAnalyticsEventName] = nonNilStr(eventName);
        if (job){
            [dict addEntriesFromDictionary:[OLAnalytics dictionaryForJob:job]];
        }
        if (info){
            [dict addEntriesFromDictionary:info];
        }
        if (order){
            NSMutableArray *items = [[NSMutableArray alloc] init];
            for (id<OLPrintJob> job in order.jobs){
                [items addObject:[OLAnalytics dictionaryForJob:job]];
            }
            dict[kOLAnalyticsItemsInOrder] = items;
            
            dict[kOLAnalyticsNumberOfPhotosInOrder] = [NSNumber numberWithInteger:order.totalAssetsToUpload];
            dict[kOLAnalyticsPromoCode] = order.promoCode;
            [order costWithCompletionHandler:^(OLPrintOrderCost *cost, NSError *error){
                dict[kOLAnalyticsOrderCost] = [cost totalCostInCurrency:order.currencyCode];
                dict[kOLAnalyticsOrderShippingCost] = [cost shippingCostInCurrency:order.currencyCode];
                
                [kiteDelegate logKiteAnalyticsEventWithInfo:dict];
            }];
        }
        else{
            [kiteDelegate logKiteAnalyticsEventWithInfo:dict];
        }
    }
}

+ (void)trackKiteViewControllerLoadedWithEntryPoint:(NSString *)entryPoint {
    [OLAnalytics incrementLaunchSDKCount];
    
    NSDictionary *dict = [OLAnalytics defaultDictionaryForEventName:@"Kite Loaded"];
    [dict[@"properties"] setObject:nonNilStr(entryPoint) forKey:@"Entry Point"];
    [OLAnalytics sendToMixPanelWithDictionary:dict];
    
    [OLAnalytics reportAnalyticsEventToDelegate:@"Kite Loaded" job:nil printOrder:nil extraInfo:nil];
}

+ (void)trackProductSelectionScreenViewed{
    NSString *eventName = @"Product Categories Screen Viewed";
    NSDictionary *dict = [OLAnalytics defaultDictionaryForEventName:eventName];
    [dict[@"properties"] setObject:nonNilStr([OLKiteABTesting sharedInstance].qualityBannerType) forKey:@"Quality Banner Type"];
    [dict[@"properties"] setObject:nonNilStr([OLKiteABTesting sharedInstance].productTileStyle) forKey:@"Product Tile Style"];
    [dict[@"properties"] setObject:nonNilStr([OLKiteABTesting sharedInstance].promoBannerText) forKey:@"Promo Banner Variant"];
    [OLAnalytics sendToMixPanelWithDictionary:dict];
    
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:nil printOrder:nil extraInfo:nil];
}

+ (void)trackQualityInfoScreenViewed{
    NSString *eventName = @"Quality Info Screen Viewed";
    NSDictionary *dict = [OLAnalytics defaultDictionaryForEventName:eventName];
    [dict[@"properties"] setObject:[OLKiteABTesting sharedInstance].qualityBannerType forKey:@"Quality Banner Type"];
    [OLAnalytics sendToMixPanelWithDictionary:dict];
    
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:nil printOrder:nil extraInfo:nil];
}

+ (void)trackProductDescriptionScreenViewed:(NSString *)productName hidePrice:(BOOL)hidePrice{
    NSString *eventName = @"Product Description Screen Viewed";
    NSDictionary *dict = [OLAnalytics defaultDictionaryForEventName:eventName];
    [dict[@"properties"] setObject:productName forKey:@"Product Name"];
    [dict[@"properties"] setObject:hidePrice ? @"YES" : @"NO" forKey:@"Hide Price on Product Description"];
    [OLAnalytics sendToMixPanelWithDictionary:dict];
    
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:nil printOrder:nil extraInfo:@{kOLAnalyticsProductName : productName}];
}

+ (void)trackProductTypeSelectionScreenViewedWithTemplateClass:(NSString *)templateClassString{
    NSString *eventName = @"Product Category Screen Viewed";
    NSDictionary *dict = [OLAnalytics defaultDictionaryForEventName:eventName];
    [dict[@"properties"] setObject:nonNilStr(templateClassString) forKey:@"Product Class"];
    [OLAnalytics sendToMixPanelWithDictionary:dict];
    
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:nil printOrder:nil extraInfo:@{kOLAnalyticsProductCategory : templateClassString}];
}

+ (void)trackPhotoSelectionScreenViewed:(NSString *)productName{
    NSString *eventName = @"Photo Selection Screen Viewed";
    NSDictionary *dict = [OLAnalytics defaultDictionaryForEventName:eventName];
    [dict[@"properties"] setObject:productName forKey:@"Product Name"];
    [OLAnalytics sendToMixPanelWithDictionary:dict];
    
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:nil printOrder:nil extraInfo:@{kOLAnalyticsProductName : productName}];
}

+ (void)trackReviewScreenViewed:(NSString *)productName{
    NSString *eventName = @"Review Screen Viewed";
    NSDictionary *dict = [OLAnalytics defaultDictionaryForEventName:eventName];
    [dict[@"properties"] setObject:productName forKey:@"Product Name"];
    [OLAnalytics sendToMixPanelWithDictionary:dict];
    
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:nil printOrder:nil extraInfo:@{kOLAnalyticsProductName : productName}];
}

+ (void)trackContinueShoppingButtonPressed:(OLPrintOrder *)printOrder{
    NSString *eventName = @"Continue Shopping Button Pressed";
    NSDictionary *dict = [OLAnalytics defaultDictionaryForEventName:eventName];
    [dict[@"properties"] setObject:[NSNumber numberWithInteger:printOrder.jobs.count] forKey:@"Number of Jobs in Basket"];
    [OLAnalytics sendToMixPanelWithDictionary:dict];
    
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:nil printOrder:printOrder extraInfo:nil];
}

+ (void)trackShippingScreenViewedForOrder:(OLPrintOrder *)printOrder variant:(NSString *)variant showPhoneEntryField:(BOOL)showPhoneEntryField {
    NSString *eventName = @"Shipping Screen Viewed";
    NSDictionary *dict = [OLAnalytics defaultDictionaryForEventName:eventName];
    NSMutableDictionary *p = [self propertiesForPrintOrder:printOrder];
    [dict[@"properties"] addEntriesFromDictionary:p];
    [dict[@"properties"] addEntriesFromDictionary:@{@"Shipping Screen Variant" : variant,
                                                    @"Showing Phone Entry Field" : showPhoneEntryField ? @"Yes" : @"No"}];
    [OLAnalytics sendToMixPanelWithDictionary:dict];
    
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:nil printOrder:printOrder extraInfo:nil];
}

+ (void)trackPaymentScreenViewedForOrder:(OLPrintOrder *)printOrder applePayIsAvailable:(NSString *)applePayIsAvailable{
    NSString *eventName = @"Payment Screen Viewed";
    NSDictionary *dict = [OLAnalytics defaultDictionaryForEventName:eventName];
    NSMutableDictionary *p = [self propertiesForPrintOrder:printOrder];
    [dict[@"properties"] addEntriesFromDictionary:p];
    [dict[@"properties"] setObject:applePayIsAvailable forKey:@"Apple Pay Available"];
    [dict[@"properties"] setObject:[OLKiteABTesting sharedInstance].offerPayPal ? @"Yes" : @"No" forKey:@"Offer PayPal"];
    [OLAnalytics sendToMixPanelWithDictionary:dict];
    
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:nil printOrder:printOrder extraInfo:@{kOLAnalyticsApplePayAvailable : applePayIsAvailable}];
}

+ (void)trackPaymentCompletedForOrder:(OLPrintOrder *)printOrder paymentMethod:(NSString *)method applePayIsAvailable:(NSString *)applePayIsAvailable{
    NSString *eventName = @"Payment Completed";
    NSDictionary *dict = [OLAnalytics defaultDictionaryForEventName:eventName];
    NSMutableDictionary *p = [self propertiesForPrintOrder:printOrder];
    p[@"Payment Method"] = method;
    [dict[@"properties"] addEntriesFromDictionary:p];
    [dict[@"properties"] setObject:applePayIsAvailable forKey:@"Apple Pay Available"];
    [OLAnalytics sendToMixPanelWithDictionary:dict];
    
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:nil printOrder:printOrder extraInfo:@{kOLAnalyticsApplePayAvailable : applePayIsAvailable, kOLAnalyticsPaymentMethod : method}];
}

+ (void)trackOrderSubmission:(OLPrintOrder *)printOrder{
    NSString *eventName = @"Print Order Submission";
    NSDictionary *dict = [OLAnalytics defaultDictionaryForEventName:eventName];
    NSMutableDictionary *p = [self propertiesForPrintOrder:printOrder];
    [dict[@"properties"] addEntriesFromDictionary:p];
    [OLAnalytics sendToMixPanelWithDictionary:dict];
    
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:nil printOrder:printOrder extraInfo:nil];
}

#pragma mark Analytics overload - Don't send these to Mixpanel.

+ (void)trackProductTypeSelectionScreenHitBackTemplateClass:(NSString *)templateClassString{
    //    NSDictionary *dict = [OLAnalytics defaultDictionaryForEventName:@"Product Type Selection Screen Hit Back"];
    //    [dict[@"properties"] setObject:nonNilStr(templateClassString) forKey:@"Template Class"];
    //    [OLAnalytics sendToMixPanelWithDictionary:dict];
    
    [OLAnalytics reportAnalyticsEventToDelegate:@"Product Category Screen Hit Back" job:nil printOrder:nil extraInfo:@{kOLAnalyticsProductCategory : templateClassString}];
}

+ (void)trackKiteDismissed{
    NSString *eventName = @"Kite Dismissed";
    //    NSDictionary *dict = [OLAnalytics defaultDictionaryForEventName:eventName];
    //    [OLAnalytics sendToMixPanelWithDictionary:dict];
    
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:nil printOrder:nil extraInfo:nil];
}

+ (void)trackPhotoProviderPicked:(NSString *)provider forProductName:(NSString *)productName{
    NSString *eventName = @"Photo Provider Selected";
    //    NSDictionary *dict = [OLAnalytics defaultDictionaryForEventName:eventName];
    //    [dict[@"properties"] setObject:nonNilStr(productName) forKey:@"Product Name"];
    //    [dict[@"properties"] setObject:nonNilStr(provider) forKey:@"Photo Provider"];
    //    [OLAnalytics sendToMixPanelWithDictionary:dict];
    
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:nil printOrder:nil extraInfo:@{kOLAnalyticsProductName : productName, kOLAnalyticsPhotoSource : nonNilStr(provider)}];
}

+ (void)trackQualityScreenHitBack{
    [OLAnalytics reportAnalyticsEventToDelegate:@"Quality Info Screen Hit Back" job:nil printOrder:nil extraInfo:nil];
}

+ (void)trackFeedbackScreenFinishedWithResult:(NSInteger)result{
    [OLAnalytics reportAnalyticsEventToDelegate:@"Feedback Button" job:nil printOrder:nil extraInfo:@{kOLAnalyticsFeedbackResult : [NSNumber numberWithInteger:result]}];
}

+ (void)trackOrderHistoryScreenViewed{
    [OLAnalytics reportAnalyticsEventToDelegate:@"Order History Viewed" job:nil printOrder:nil extraInfo:nil];
}

+ (void)trackOrderHistoryScreenDismissed{
    [OLAnalytics reportAnalyticsEventToDelegate:@"Order History Dismissed" job:nil printOrder:nil extraInfo:nil];
}

+ (void)trackFeedbackButtonTapped{
    [OLAnalytics reportAnalyticsEventToDelegate:@"Feedback Button Tapped" job:nil printOrder:nil extraInfo:nil];
}

+ (void)trackDetailsViewProductOptionsTappedForProductName:(NSString *)productName{
    [OLAnalytics reportAnalyticsEventToDelegate:@"Details View Product Options Tapped" job:nil printOrder:nil extraInfo:@{kOLAnalyticsProductName : productName}];
}

+ (void)trackDetailsViewProductOptionsHitBackForProductName:(NSString *)productName{
    [OLAnalytics reportAnalyticsEventToDelegate:@"Details View Product Options Hit Back" job:nil printOrder:nil extraInfo:@{kOLAnalyticsProductName : productName}];
}

+ (void)trackDetailsViewProductOptionsSelectedOption:(NSString *)option forProductName:(NSString *)productName{
    [OLAnalytics reportAnalyticsEventToDelegate:@"Details View Product Options Selected Option" job:nil printOrder:nil extraInfo:@{kOLAnalyticsProductName : productName, kOLAnalyticsSelectedOption : nonNilStr(option)}];
}

+ (void)trackPaymentScreenHitItemQtyDownForItem:(id<OLPrintJob>)item inOrder:(OLPrintOrder *)printOrder applePayIsAvailable:(NSString *)applePayIsAvailable{
    NSString *eventName = @"Payment Screen Item Quantity Down";
    //    NSDictionary *dict = [OLAnalytics defaultDictionaryForEventName:eventName];
    //    [dict[@"properties"] setObject:nonNilStr([OLProductTemplate templateWithId:[item templateId]].name) forKey:@"Product Name"];
    //    [dict[@"properties"] setObject:[NSNumber numberWithInteger:[item quantity]] forKey:@"Number of Photos"];
    //    [dict[@"properties"] setObject:[NSNumber numberWithInteger:[item extraCopies]] forKey:@"Extra Copies"];
    //    [OLAnalytics sendToMixPanelWithDictionary:dict];
    
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:item printOrder:printOrder extraInfo:nil];
}

+ (void)trackReviewScreenHitBack:(NSString *)productName numberOfPhotos:(NSInteger)numberOfPhotos{
    NSString *eventName = @"Review Screen Hit Back";
    //    NSDictionary *dict = [OLAnalytics defaultDictionaryForEventName:eventName];
    //    [dict[@"properties"] setObject:nonNilStr(productName) forKey:@"Product Name"];
    //    [dict[@"properties"] setObject:[NSNumber numberWithInteger:numberOfPhotos] forKey:@"Number of Photos"];
    //    [OLAnalytics sendToMixPanelWithDictionary:dict];
    
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:nil printOrder:nil extraInfo:@{kOLAnalyticsProductName : productName, kOLAnalyticsNumberOfPhotos : [NSNumber numberWithInteger:numberOfPhotos]}];
}

+ (void)trackPaymentScreenHitItemQtyUpForItem:(id<OLPrintJob>)item inOrder:(OLPrintOrder *)printOrder applePayIsAvailable:(NSString *)applePayIsAvailable{
    NSString *eventName = @"Payment Screen Item Quantity Up";
    //    NSDictionary *dict = [OLAnalytics defaultDictionaryForEventName:eventName];
    //    [dict[@"properties"] setObject:nonNilStr([OLProductTemplate templateWithId:[item templateId]].name) forKey:@"Product Name"];
    //    [dict[@"properties"] setObject:[NSNumber numberWithInteger:[item quantity]] forKey:@"Number of Photos"];
    //    [dict[@"properties"] setObject:[NSNumber numberWithInteger:[item extraCopies]] forKey:@"Extra Copies"];
    //    [OLAnalytics sendToMixPanelWithDictionary:dict];
    
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:item printOrder:printOrder extraInfo:nil];
}

+ (void)trackReviewScreenDidCropPhotoForProductName:(NSString *)productName{
    NSString *eventName = @"Review Screen Did Crop Photo";
    //    NSDictionary *dict = [OLAnalytics defaultDictionaryForEventName:eventName];
    //    [dict[@"properties"] setObject:nonNilStr(productName) forKey:@"Product Name"];
    //    [OLAnalytics sendToMixPanelWithDictionary:dict];
    
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:nil printOrder:nil extraInfo:@{kOLAnalyticsProductName : productName}];
}

+ (void)trackReviewScreenDecrementedPhotoQtyForProductName:(NSString *)productName{
    NSString *eventName = @"Review Screen Decremented Photo Quantity";
    //    NSDictionary *dict = [OLAnalytics defaultDictionaryForEventName:eventName];
    //    [dict[@"properties"] setObject:nonNilStr(productName) forKey:@"Product Name"];
    //    [OLAnalytics sendToMixPanelWithDictionary:dict];
    
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:nil printOrder:nil extraInfo:@{kOLAnalyticsProductName : productName}];
}

+ (void)trackReviewScreenEnteredCropScreenForProductName:(NSString *)productName{
    NSString *eventName = @"Review Screen Did Enter Crop Screen";
    //    NSDictionary *dict = [OLAnalytics defaultDictionaryForEventName:eventName];
    //    [dict[@"properties"] setObject:nonNilStr(productName) forKey:@"Product Name"];
    //    [OLAnalytics sendToMixPanelWithDictionary:dict];
    
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:nil printOrder:nil extraInfo:@{kOLAnalyticsProductName : productName}];
}

+ (void)trackPhotoSelectionScreenNumberOfPhotosRemoved:(NSUInteger)number forProductName:(NSString *)productName{
    NSString *eventName = @"Photo Selection Screen Removed Photos";
    //    NSDictionary *dict = [OLAnalytics defaultDictionaryForEventName:eventName];
    //    [dict[@"properties"] setObject:nonNilStr(productName) forKey:@"Product Name"];
    //    [dict[@"properties"] setObject:[NSNumber numberWithInteger:number] forKey:@"Number of Photos Removed"];
    //    [OLAnalytics sendToMixPanelWithDictionary:dict];
    
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:nil printOrder:nil extraInfo:@{kOLAnalyticsProductName : productName, kOLAnalyticsNumberOfPhotos : [NSNumber numberWithInteger:number]}];
}

+ (void)trackPaymentScreenDidDeleteItem:(id<OLPrintJob>)item inOrder:(OLPrintOrder *)printOrder applePayIsAvailable:(NSString *)applePayIsAvailable{
    NSString *eventName = @"Payment Screen Delete Item";
    //    NSDictionary *dict = [OLAnalytics defaultDictionaryForEventName:eventName];
    //    [dict[@"properties"] setObject:nonNilStr([OLProductTemplate templateWithId:[item templateId]].name) forKey:@"Product Name"];
    //    [dict[@"properties"] setObject:[NSNumber numberWithInteger:[item quantity]] forKey:@"Number of Photos"];
    //    [dict[@"properties"] setObject:[NSNumber numberWithInteger:[item extraCopies]] forKey:@"Extra Copies"];
    //    [OLAnalytics sendToMixPanelWithDictionary:dict];
    
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:item printOrder:printOrder extraInfo:nil];
}

+ (void)trackPaymentScreenHitEditItemDone:(id<OLPrintJob>)item inOrder:(OLPrintOrder *)printOrder applePayIsAvailable:(NSString *)applePayIsAvailable{
    NSString *eventName = @"Payment Screen Did Edit Item";
    //    NSDictionary *dict = [OLAnalytics defaultDictionaryForEventName:eventName];
    //    [dict[@"properties"] setObject:nonNilStr([OLProductTemplate templateWithId:[item templateId]].name) forKey:@"Product Name"];
    //    [dict[@"properties"] setObject:[NSNumber numberWithInteger:[item quantity]] forKey:@"Number of Photos"];
    //    [dict[@"properties"] setObject:[NSNumber numberWithInteger:[item extraCopies]] forKey:@"Extra Copies"];
    //    [OLAnalytics sendToMixPanelWithDictionary:dict];
    
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:item printOrder:printOrder extraInfo:nil];
}

+ (void)trackProductDetailsViewOpened:(NSString *)productName hidePrice:(BOOL)hidePrice{
    NSString *eventName = @"Product Details Opened";
    //    NSDictionary *dict = [OLAnalytics defaultDictionaryForEventName:eventName];
    //    [dict[@"properties"] setObject:nonNilStr(productName) forKey:@"Product Name"];
    //    [OLAnalytics sendToMixPanelWithDictionary:dict];
    
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:nil printOrder:nil extraInfo:@{kOLAnalyticsProductName : productName}];
}

+ (void)trackProductDetailsViewClosed:(NSString *)productName hidePrice:(BOOL)hidePrice{
    NSString *eventName = @"Product Details Closed";
    //    NSDictionary *dict = [OLAnalytics defaultDictionaryForEventName:eventName];
    //    [dict[@"properties"] setObject:nonNilStr(productName) forKey:@"Product Name"];
    //    [OLAnalytics sendToMixPanelWithDictionary:dict];
    
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:nil printOrder:nil extraInfo:@{kOLAnalyticsProductName : productName}];
}

+ (void)trackPaymentScreenHitBackForOrder:(OLPrintOrder *)printOrder applePayIsAvailable:(NSString *)applePayIsAvailable{
    NSString *eventName = @"Payment Screen Hit Back";
    //    NSDictionary *dict = [OLAnalytics defaultDictionaryForEventName:eventName];
    //    [OLAnalytics sendToMixPanelWithDictionary:dict];
    
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:nil printOrder:printOrder extraInfo:nil];
}

+ (void)trackBasketScreenHitBackForOrder:(OLPrintOrder *)printOrder applePayIsAvailable:(NSString *)applePayIsAvailable{
    NSString *eventName = @"Basket Screen Hit Cancel";
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:nil printOrder:printOrder extraInfo:nil];
}

+ (void)trackReviewScreenIncrementedPhotoQtyForProductName:(NSString *)productName{
    NSString *eventName = @"Review Screen Incremented Photo Quantity";
    //    NSDictionary *dict = [OLAnalytics defaultDictionaryForEventName:eventName];
    //    [dict[@"properties"] setObject:nonNilStr(productName) forKey:@"Product Name"];
    //    [OLAnalytics sendToMixPanelWithDictionary:dict];
    
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:nil printOrder:nil extraInfo:@{kOLAnalyticsProductName : productName}];
}

+ (void)trackPaymentScreenHitEditItem:(id<OLPrintJob>)item inOrder:(OLPrintOrder *)printOrder applePayIsAvailable:(NSString *)applePayIsAvailable{
    NSString *eventName = @"Payment Screen Hit Edit Item";
    //    NSDictionary *dict = [OLAnalytics defaultDictionaryForEventName:eventName];
    //    [dict[@"properties"] setObject:nonNilStr([OLProductTemplate templateWithId:[item templateId]].name) forKey:@"Product Name"];
    //    [dict[@"properties"] setObject:[NSNumber numberWithInteger:[item quantity]] forKey:@"Number of Photos"];
    //    [dict[@"properties"] setObject:[NSNumber numberWithInteger:[item extraCopies]] forKey:@"Extra Copies"];
    //    [OLAnalytics sendToMixPanelWithDictionary:dict];
    
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:item printOrder:printOrder extraInfo:nil];
}

+ (void)trackPaymentScreenHitCheckoutForOrder:(OLPrintOrder *)printOrder{
    [OLAnalytics reportAnalyticsEventToDelegate:@"Payment Screen Hit Checkout" job:nil printOrder:printOrder extraInfo:nil];
}

+ (void)trackPaymentScreenHitBackToApplePayForOrder:(OLPrintOrder *)printOrder{
    [OLAnalytics reportAnalyticsEventToDelegate:@"Payment Screen Hit Back to Apple Pay" job:nil printOrder:printOrder extraInfo:nil];
}

+ (void)trackShippingScreenHitBackForOrder:(OLPrintOrder *)printOrder{
    [OLAnalytics reportAnalyticsEventToDelegate:@"Shipping Screen Hit Back" job:nil printOrder:printOrder extraInfo:nil];
}

+ (void)trackReviewScreenDeletedPhotoForProductName:(NSString *)productName{
    NSString *eventName = @"Review Screen Deleted Photo";
    //    NSDictionary *dict = [OLAnalytics defaultDictionaryForEventName:eventName];
    //    [dict[@"properties"] setObject:nonNilStr(productName) forKey:@"Product Name"];
    //    [OLAnalytics sendToMixPanelWithDictionary:dict];
    
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:nil printOrder:nil extraInfo:@{kOLAnalyticsProductName : productName}];
}

+ (void)trackPhotoProvider:(NSString *)provider numberOfPhotosAdded:(NSInteger)number forProductName:(NSString *)productName{
    NSString *eventName = @"Photo Provider Added Photos";
    //    NSDictionary *dict = [OLAnalytics defaultDictionaryForEventName:eventName];
    //    [dict[@"properties"] setObject:nonNilStr(productName) forKey:@"Product Name"];
    //    [dict[@"properties"] setObject:nonNilStr(provider) forKey:@"Photo Provider"];
    //    [OLAnalytics sendToMixPanelWithDictionary:dict];
    
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:nil printOrder:nil extraInfo:@{kOLAnalyticsProductName : productName, kOLAnalyticsNumberOfPhotos : [NSNumber numberWithInteger:number], kOLAnalyticsPhotoSource : nonNilStr(provider)}];
}

+ (void)trackProductDescriptionScreenHitBack:(NSString *)productName hidePrice:(BOOL)hidePrice{
    NSString *eventName = @"Product Description Screen Hit Back";
    //    NSDictionary *dict = [OLAnalytics defaultDictionaryForEventName:eventName];
    //    [dict[@"properties"] setObject:nonNilStr(productName) forKey:@"Product Name"];
    //    [OLAnalytics sendToMixPanelWithDictionary:dict];
    
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:nil printOrder:nil extraInfo:@{kOLAnalyticsProductName : productName}];
}

+ (void)trackPhotoSelectionScreenHitBack:(NSString *)productName{
    NSString *eventName = @"Photo Selection Screen Hit Back";
    //    NSDictionary *dict = [OLAnalytics defaultDictionaryForEventName:eventName];
    //    [dict[@"properties"] setObject:nonNilStr(productName) forKey:@"Product Name"];
    //    [OLAnalytics sendToMixPanelWithDictionary:dict];
    
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:nil printOrder:nil extraInfo:@{kOLAnalyticsProductName : productName}];
}

+ (void)trackBasketIconTappedWithNumberBadged:(NSInteger)number{
    [OLAnalytics reportAnalyticsEventToDelegate:@"Basket Icon Tapped" job:nil printOrder:nil extraInfo:@{kOLAnalyticsNumberOnBadge : [NSNumber numberWithInteger:number]}];
}

+ (void)setKiteDelegate:(id<OLKiteDelegate>)kd{
    kiteDelegate = kd;
}

+ (NSMutableDictionary *)propertiesForPrintOrder:(OLPrintOrder *)printOrder {
    NSMutableDictionary *p = [[NSMutableDictionary alloc] init];
    
    p[@"Product"] = [self listOfProductNamesForJobsInOrder:printOrder];
    
    if (printOrder.proofOfPayment) {
        p[@"Proof of Payment"] = printOrder.proofOfPayment;
    }
    
    if (printOrder.lastPrintSubmissionError) {
        p[@"Print Submission Success"] = @"False";
        p[@"Print Submission Error"] = nonNilStr(printOrder.lastPrintSubmissionError.localizedDescription);
    }
    
    if (printOrder.receipt) {
        p[@"Print Order Id"] = printOrder.receipt;
        p[@"Print Submission Success"] = @"True";
        p[@"Print Submission Error"] = @"None";
    }
    
    if (printOrder.promoCode) {
        p[@"Voucher Code"] = printOrder.promoCode;
    }
    
    if (printOrder.userData) {
        if (printOrder.userData[@"email"]) {
            p[@"Shipping Email"] = printOrder.userData[@"email"];
        }
        
        if (printOrder.userData[@"phone"]) {
            p[@"Shipping Phone"] = printOrder.userData[@"phone"];
        }
    }
    
    if (printOrder.shippingAddress) {
        p[@"Shipping Recipient"] = nonNilStr(printOrder.shippingAddress.fullNameFromFirstAndLast);
        p[@"Shipping Line 1"] = nonNilStr(printOrder.shippingAddress.line1);
        p[@"Shipping Line 2"] = nonNilStr(printOrder.shippingAddress.line2);
        p[@"Shipping City"] = nonNilStr(printOrder.shippingAddress.city);
        p[@"Shipping County"] = nonNilStr(printOrder.shippingAddress.stateOrCounty);
        p[@"Shipping Postcode"] = nonNilStr(printOrder.shippingAddress.zipOrPostcode);
        p[@"Shipping Country"] = nonNilStr(printOrder.shippingAddress.country.name);
        p[@"Shipping Country Code2"] = nonNilStr(printOrder.shippingAddress.country.codeAlpha2);
        p[@"Shipping Country Code3"] = nonNilStr(printOrder.shippingAddress.country.codeAlpha3);
    }
    
    p[@"Job Count"] = [NSString stringWithFormat:@"%lu",  (unsigned long) printOrder.jobs.count];
    
    return p;
}

+ (NSMutableArray*) listOfProductNamesForJobsInOrder:(OLPrintOrder*) printOrder{
    NSMutableArray* productNames = [[NSMutableArray alloc] initWithCapacity:[printOrder.jobs count]];
    for (id<OLPrintJob> printJob in printOrder.jobs){
        id name = [OLProduct productWithTemplateId:printJob.templateId].productTemplate.name;
        if (name){
            [productNames addObject:name];
        }
    }
    return productNames;
}

+ (void)setExtraInfo:(NSDictionary *)info{
    extraInfo = info;
}

@end
