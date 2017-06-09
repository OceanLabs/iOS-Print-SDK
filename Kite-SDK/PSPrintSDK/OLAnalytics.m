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

#import "OLAnalytics.h"
#import "OLPrintOrder.h"
#import "OLAddress.h"
#import "OLCountry.h"
#import "OLProduct.h"
#import "OLPrintJob.h"
#import "OLKitePrintSDK.h"
#include <sys/sysctl.h>
#import "OLKiteABTesting.h"
#import "OLKeyChainStore.h"
#import "NSDictionary+RequestParameterData.h"
#import "OLUserSession.h"
#import "OLKiteUtils.h"

static NSString *const kKeyUserDistinctId = @"ly.kite.sdk.kKeyUserDistinctId";
static NSString *const kOLMixpanelToken = @"cdf64507670dd359c43aa8895fb87676";
static NSString *const kOLMixpanelURL = @"https://api.mixpanel.com/track/";
static NSString *const kKeySDKLaunchCount = @"ly.kite.sdk.kKeySDKLaunchCount";
static NSString *const kKeyOLDevicePushToken = @"ly.kite.sdk.kKeyOLDevicePushToken";

static NSString *const kKeyServiceName = @"ly.kite.sdk.kKeyServiceName";

static NSDictionary *extraInfo;

static NSString *nonNilStr(NSString *str) {
    return str == nil ? @"" : str;
}

@interface OLProduct (Private)

- (NSDecimalNumber*) unitCostDecimalNumber;

@end

@interface OLKitePrintSDK (Private)

+ (NSString *)apiEndpoint;
+ (NSString *)apiVersion;

@end

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
    OLKeyChainStore *keychain = [OLKeyChainStore keyChainStoreWithService:kKeyServiceName];
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

+ (NSString *)environment {
    NSString *environment = @"Live";
#ifdef PAYMENT_SANDBOX
    environment = @"Development";
#endif
    return environment;
}

+ (void)addPushDeviceToken:(NSData *)deviceToken {
    if (![OLKitePrintSDK apiKey]){
        NSLog(@"Push token NOT submitted. Please set your API key in OLKitePrintSDK first");
        return;
    }
    
    const unsigned char *buffer = (const unsigned char *)[deviceToken bytes];
    if (!buffer) {
        return;
    }
    NSMutableString *hex = [NSMutableString stringWithCapacity:(deviceToken.length * 2)];
    for (NSUInteger i = 0; i < deviceToken.length; i++) {
        [hex appendString:[NSString stringWithFormat:@"%02lx", (unsigned long)buffer[i]]];
    }
    
    NSString *pushToken = [NSString stringWithString:hex];
    if (!pushToken) {
        return;
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *savedToken = [defaults objectForKey:kKeyOLDevicePushToken];
    if ([savedToken isEqualToString:pushToken]){
        return;
    }
    
    NSString *uuid = [self userDistinctId];
    NSDictionary *properties = @{
                                 @"uuid": uuid,
                                 @"set" : @{
                                         @"push_token" : @{
                                                 @"platform" : @"iOS",
                                                 @"token" : pushToken
                                                 },
                                         @"platform" : @"iOS",
                                         @"environment": [self environment]
                                         }
                                 };
    NSError *error;
    NSData * jsonData = [NSJSONSerialization dataWithJSONObject:properties options:NSJSONWritingPrettyPrinted error:&error];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/person/", [OLKitePrintSDK apiEndpoint], [OLKitePrintSDK apiVersion]]]];
    request.HTTPMethod = @"POST";
    request.HTTPBody = jsonData;
    [request addValue:[NSString stringWithFormat:@"apikey %@", [OLKitePrintSDK apiKey]] forHTTPHeaderField:@"Authorization"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig
                                                          delegate:nil
                                                     delegateQueue:nil];
    [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error){
            NSLog(@"There was an error posting the push notification token: %@", error.localizedDescription);
        }
        else if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            if ([(NSHTTPURLResponse *)response statusCode] >= 200 && [(NSHTTPURLResponse *)response statusCode] <= 299){
                NSLog(@"Successfully posted push notification token.");
                [defaults setObject:pushToken forKey:kKeyOLDevicePushToken];
                [defaults synchronize];
            }
            else{
                NSLog(@"There was an error posting the push notification token: %ld", (long)[(NSHTTPURLResponse *)response statusCode]);
            }
        }
    }] resume];
    [session finishTasksAndInvalidate];
}

+ (void)sendToMixPanelWithDictionary:(NSDictionary *)dict{
    NSError *error;
    NSData * jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
    
    NSDictionary *params = @{@"ip": @"1",@"data" : [jsonData base64EncodedStringWithOptions:0]};
    
    NSURL *baseURL = [NSURL URLWithString:kOLMixpanelURL];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:baseURL];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [params requestParameterData];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig
                                                          delegate:nil
                                                     delegateQueue:nil];
    [[session dataTaskWithRequest:request] resume];
    [session finishTasksAndInvalidate];
}

+ (NSDictionary *)defaultDictionaryForEventName:(NSString *)eventName{
    NSString *environment = @"Live";
    if ([OLKitePrintSDK environment] == OLKitePrintSDKEnvironmentSandbox) {
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
                                             @"Locale Country": localeCountry,
                                             @"Progressive Template Loading" : @([OLKiteABTesting sharedInstance].progressiveTemplateLoading)
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
        
        OLProduct *product = [OLProduct productWithTemplateId:[job templateId]];
        NSDecimalNumber *numUnitsInJob = [job numberOfItemsInJob];
        NSDecimalNumber *jobPrice = [numUnitsInJob decimalNumberByMultiplyingBy:[[product unitCostDecimalNumber] decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%ld", (long)[job extraCopies]+1]]]];
        dict[kOLAnalyticsItemPrice] = jobPrice;
    }
    return dict;
}

+ (void)reportAnalyticsEventToDelegate:(NSString *)eventName
                                   job:(id<OLPrintJob>)job
                            printOrder:(OLPrintOrder *)order
                             extraInfo:(NSDictionary *)info{
    if ([[OLUserSession currentSession].kiteVc.delegate respondsToSelector:@selector(logKiteAnalyticsEventWithInfo:)]){
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
            dict[kOLAnalyticsCurrencyCode] = order.currencyCode;
            [order costWithCompletionHandler:^(OLPrintOrderCost *cost, NSError *error){
                dict[kOLAnalyticsOrderCost] = [cost totalCostInCurrency:order.currencyCode];
                dict[kOLAnalyticsOrderShippingCost] = [cost shippingCostInCurrency:order.currencyCode];
                
                [[OLUserSession currentSession].kiteVc.delegate logKiteAnalyticsEventWithInfo:dict];
            }];
        }
        else{
            [[OLUserSession currentSession].kiteVc.delegate logKiteAnalyticsEventWithInfo:dict];
        }
    }
}

#pragma mark Track Main Events - Sent to MixPanel

+ (void)trackKiteViewControllerLoadedWithEntryPoint:(NSString *)entryPoint {
    [OLAnalytics incrementLaunchSDKCount];
    
    NSString *eventName = kOLAnalyticsEventNameKiteLoaded;
    NSDictionary *dict = [OLAnalytics defaultDictionaryForEventName:eventName];
    [dict[@"properties"] setObject:nonNilStr(entryPoint) forKey:@"Entry Point"];
    [OLAnalytics sendToMixPanelWithDictionary:dict];
    
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:nil printOrder:nil extraInfo:@{kOLAnalyticsEventLevel : @1}];
}

+ (void)trackCategoryListScreenViewed{
    NSString *eventName = kOLAnalyticsEventNameCategoryListScreenViewed;
    NSDictionary *dict = [OLAnalytics defaultDictionaryForEventName:eventName];
    [dict[@"properties"] setObject:nonNilStr([OLKiteABTesting sharedInstance].qualityBannerType) forKey:@"Quality Banner Type"];
    [dict[@"properties"] setObject:nonNilStr([OLKiteABTesting sharedInstance].productTileStyle) forKey:@"Product Tile Style"];
    [dict[@"properties"] setObject:nonNilStr([OLKiteABTesting sharedInstance].promoBannerText) forKey:@"Promo Banner Variant"];
    [OLAnalytics sendToMixPanelWithDictionary:dict];
    
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:nil printOrder:nil extraInfo:@{kOLAnalyticsEventLevel : @1}];
}

+ (void)trackQualityInfoScreenViewed{
    NSString *eventName = kOLAnalyticsEventNameQualityInfoScreenViewed;
    NSDictionary *dict = [OLAnalytics defaultDictionaryForEventName:eventName];
    [dict[@"properties"] setObject:[OLKiteABTesting sharedInstance].qualityBannerType forKey:@"Quality Banner Type"];
    [OLAnalytics sendToMixPanelWithDictionary:dict];
    
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:nil printOrder:nil extraInfo:@{kOLAnalyticsEventLevel : @1}];
}

+ (void)trackPrintAtHomeTapped{
    NSString *eventName = kOLAnalyticsEventNamePrintAtHomeTapped;
    NSDictionary *dict = [OLAnalytics defaultDictionaryForEventName:eventName];
    [OLAnalytics sendToMixPanelWithDictionary:dict];
    
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:nil printOrder:nil extraInfo:@{kOLAnalyticsEventLevel : @1}];
}

+ (void)trackProductDetailsScreenViewed:(NSString *)productName hidePrice:(BOOL)hidePrice{
    NSString *eventName = kOLAnalyticsEventNameProductDetailsScreenViewed;
    NSDictionary *dict = [OLAnalytics defaultDictionaryForEventName:eventName];
    [dict[@"properties"] setObject:productName forKey:@"Product Name"];
    [dict[@"properties"] setObject:hidePrice ? @"YES" : @"NO" forKey:@"Hide Price on Product Description"];
    [OLAnalytics sendToMixPanelWithDictionary:dict];
    
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:nil printOrder:nil extraInfo:@{kOLAnalyticsProductName : productName, kOLAnalyticsEventLevel : @1}];
}

+ (void)trackProductListScreenViewedWithTemplateClass:(NSString *)templateClassString{
    NSString *eventName = kOLAnalyticsEventNameProductListScreenViewed;
    NSDictionary *dict = [OLAnalytics defaultDictionaryForEventName:eventName];
    [dict[@"properties"] setObject:nonNilStr(templateClassString) forKey:@"Product Class"];
    [OLAnalytics sendToMixPanelWithDictionary:dict];
    
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:nil printOrder:nil extraInfo:@{kOLAnalyticsProductCategory : templateClassString, kOLAnalyticsEventLevel : @1}];
}

+ (void)trackImagePickerScreenViewed:(NSString *)productName{
    NSString *eventName = kOLAnalyticsEventNameImagePickerScreenViewed;
    NSDictionary *dict = [OLAnalytics defaultDictionaryForEventName:eventName];
    [dict[@"properties"] setObject:productName forKey:@"Product Name"];
    [OLAnalytics sendToMixPanelWithDictionary:dict];
    
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:nil printOrder:nil extraInfo:@{kOLAnalyticsProductName : productName, kOLAnalyticsEventLevel : @1}];
}

+ (void)trackPhotobookEditScreenViewed:(NSString *)productName{
    NSString *eventName = kOLAnalyticsEventNamePhotobookEditScreenViewed;
    NSDictionary *dict = [OLAnalytics defaultDictionaryForEventName:eventName];
    [dict[@"properties"] setObject:productName forKey:@"Product Name"];
    [OLAnalytics sendToMixPanelWithDictionary:dict];
    
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:nil printOrder:nil extraInfo:@{kOLAnalyticsProductName : productName, kOLAnalyticsEventLevel : @1}];
}

+ (void)trackReviewScreenViewed:(NSString *)productName{
    NSString *eventName = kOLAnalyticsEventNameReviewScreenViewed;
    NSDictionary *dict = [OLAnalytics defaultDictionaryForEventName:eventName];
    [dict[@"properties"] setObject:productName forKey:@"Product Name"];
    [OLAnalytics sendToMixPanelWithDictionary:dict];
    
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:nil printOrder:nil extraInfo:@{kOLAnalyticsProductName : productName, kOLAnalyticsEventLevel : @1}];
}

+ (void)trackContinueShoppingButtonPressed:(OLPrintOrder *)printOrder{
    NSString *eventName = kOLAnalyticsEventNameContinueShoppingButtonTapped;
    NSDictionary *dict = [OLAnalytics defaultDictionaryForEventName:eventName];
    [dict[@"properties"] setObject:[NSNumber numberWithInteger:printOrder.jobs.count] forKey:@"Number of Jobs in Basket"];
    [OLAnalytics sendToMixPanelWithDictionary:dict];
    
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:nil printOrder:printOrder extraInfo:@{kOLAnalyticsEventLevel : @1}];
}

+ (void)trackDeliveryDetailsScreenViewedForOrder:(OLPrintOrder *)printOrder variant:(NSString *)variant showPhoneEntryField:(BOOL)showPhoneEntryField {
    NSString *eventName = kOLAnalyticsEventNameDeliveryDetailsScreenViewed;
    NSDictionary *dict = [OLAnalytics defaultDictionaryForEventName:eventName];
    NSMutableDictionary *p = [self propertiesForPrintOrder:printOrder];
    [dict[@"properties"] addEntriesFromDictionary:p];
    [dict[@"properties"] addEntriesFromDictionary:@{@"Shipping Screen Variant" : variant,
                                                    @"Showing Phone Entry Field" : showPhoneEntryField ? @"Yes" : @"No"}];
    [OLAnalytics sendToMixPanelWithDictionary:dict];
    
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:nil printOrder:printOrder extraInfo:@{kOLAnalyticsEventLevel : @1}];
}

+ (void)trackAddressSelectionScreenViewed {
    [OLAnalytics reportAnalyticsEventToDelegate:kOLAnalyticsEventNameAddressSelectionScreenViewed job:nil printOrder:nil extraInfo:@{kOLAnalyticsEventLevel : @1}];
}

+ (void)trackAddEditAddressScreenViewed {
    [OLAnalytics reportAnalyticsEventToDelegate:kOLAnalyticsEventNameAddEditAddressScreenViewed job:nil printOrder:nil extraInfo:@{kOLAnalyticsEventLevel : @1}];
}

+ (void)trackSearchAddressScreenViewed {
    [OLAnalytics reportAnalyticsEventToDelegate:kOLAnalyticsEventNameSearchAddressScreenViewed job:nil printOrder:nil extraInfo:@{kOLAnalyticsEventLevel : @1}];
}

+ (void)trackBasketScreenViewedForOrder:(OLPrintOrder *)printOrder applePayIsAvailable:(NSString *)applePayIsAvailable{
    NSString *eventName = kOLAnalyticsEventNameBasketScreenViewed;
    NSDictionary *dict = [OLAnalytics defaultDictionaryForEventName:eventName];
    NSMutableDictionary *p = [self propertiesForPrintOrder:printOrder];
    [dict[@"properties"] addEntriesFromDictionary:p];
    [dict[@"properties"] setObject:applePayIsAvailable forKey:@"Apple Pay Available"];
    [dict[@"properties"] setObject:[OLKiteABTesting sharedInstance].offerPayPal ? @"Yes" : @"No" forKey:@"Offer PayPal"];
    [OLAnalytics sendToMixPanelWithDictionary:dict];
    
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:nil printOrder:printOrder extraInfo:@{kOLAnalyticsApplePayAvailable : applePayIsAvailable, kOLAnalyticsEventLevel : @1}];
}

+ (void)trackPaymentCompletedForOrder:(OLPrintOrder *)printOrder paymentMethod:(NSString *)method applePayIsAvailable:(NSString *)applePayIsAvailable{
    NSString *eventName = kOLAnalyticsEventNamePaymentCompleted;
    NSDictionary *dict = [OLAnalytics defaultDictionaryForEventName:eventName];
    NSMutableDictionary *p = [self propertiesForPrintOrder:printOrder];
    p[@"Payment Method"] = method;
    [dict[@"properties"] addEntriesFromDictionary:p];
    [dict[@"properties"] setObject:applePayIsAvailable forKey:@"Apple Pay Available"];
    [OLAnalytics sendToMixPanelWithDictionary:dict];
    
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:nil printOrder:printOrder extraInfo:@{kOLAnalyticsApplePayAvailable : applePayIsAvailable, kOLAnalyticsPaymentMethod : method, kOLAnalyticsEventLevel : @1}];
}

+ (void)trackOrderSubmission:(OLPrintOrder *)printOrder{
    NSString *eventName = kOLAnalyticsEventNamePrintOrderSubmission;
    NSDictionary *dict = [OLAnalytics defaultDictionaryForEventName:eventName];
    NSMutableDictionary *p = [self propertiesForPrintOrder:printOrder];
    [dict[@"properties"] addEntriesFromDictionary:p];
    [OLAnalytics sendToMixPanelWithDictionary:dict];
    
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:nil printOrder:printOrder extraInfo:@{kOLAnalyticsEventLevel : @1}];
}

+ (void)trackKiteDismissed{
    NSString *eventName = kOLAnalyticsEventNameKiteDismissed;
    
    NSDictionary *dict = [OLAnalytics defaultDictionaryForEventName:eventName];
    [OLAnalytics sendToMixPanelWithDictionary:dict];
    
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:nil printOrder:nil extraInfo:@{kOLAnalyticsEventLevel : @1}];
}

+ (void)trackUpsellDismissed:(BOOL)optedIn {
    NSString *eventName = kOLAnalyticsEventNameUpsellScreenDismissed;
    NSDictionary *dict = [OLAnalytics defaultDictionaryForEventName:eventName];
    NSString *how = optedIn ? @"Yes Please" : @"Not Thanks";
    [dict[@"properties"] setObject:how forKey:@"How"];
    [OLAnalytics sendToMixPanelWithDictionary:dict];
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:nil printOrder:nil extraInfo:@{@"How": how, kOLAnalyticsEventLevel : @1}];
}

+ (void)trackBasketIconTappedWithNumberBadged:(NSInteger)number{
    NSString *eventName = kOLAnalyticsEventNameBasketIconTapped;
    
    NSDictionary *dict = [OLAnalytics defaultDictionaryForEventName:eventName];
    [dict[@"properties"] setObject:[NSNumber numberWithInteger:number] forKey:kOLAnalyticsNumberOnBadge];
    [OLAnalytics sendToMixPanelWithDictionary:dict];
    
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:nil printOrder:nil extraInfo:@{kOLAnalyticsNumberOnBadge : [NSNumber numberWithInteger:number], kOLAnalyticsEventLevel : @1}];
}

+ (void)trackPaymentMethodScreenViewed:(OLPrintOrder *)printOrder{
    NSString *eventName = kOLAnalyticsEventNamePaymentMethodScreenViewed;
    NSString *applePayIsAvailable = [OLKiteUtils isApplePayAvailable] ? @"Yes" : @"No" ;
    
    NSDictionary *dict = [OLAnalytics defaultDictionaryForEventName:eventName];
    NSMutableDictionary *p = [self propertiesForPrintOrder:printOrder];
    [dict[@"properties"] addEntriesFromDictionary:p];
    [dict[@"properties"] setObject:applePayIsAvailable forKey:@"Apple Pay Available"];
    [OLAnalytics sendToMixPanelWithDictionary:dict];
    
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:nil printOrder:printOrder extraInfo:@{kOLAnalyticsApplePayAvailable : applePayIsAvailable, kOLAnalyticsEventLevel : @1}];
}

+ (void)trackShippingMethodScreenViewed:(OLPrintOrder *)printOrder{
    NSString *eventName = kOLAnalyticsEventNameShippingMethodScreenViewed;
    NSString *applePayIsAvailable = [OLKiteUtils isApplePayAvailable] ? @"Yes" : @"No" ;
    
    NSDictionary *dict = [OLAnalytics defaultDictionaryForEventName:eventName];
    NSMutableDictionary *p = [self propertiesForPrintOrder:printOrder];
    [dict[@"properties"] addEntriesFromDictionary:p];
    [dict[@"properties"] setObject:applePayIsAvailable forKey:@"Apple Pay Available"];
    [OLAnalytics sendToMixPanelWithDictionary:dict];
    
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:nil printOrder:printOrder extraInfo:@{kOLAnalyticsApplePayAvailable : applePayIsAvailable, kOLAnalyticsEventLevel : @1}];
}

+ (void)trackPaymentMethodSelected:(OLPrintOrder *)printOrder methodName:(NSString *)methodName{
    NSString *eventName = kOLAnalyticsEventNamePaymentMethodSelected;
    NSString *applePayIsAvailable = [OLKiteUtils isApplePayAvailable] ? @"Yes" : @"No" ;
    
    NSDictionary *dict = [OLAnalytics defaultDictionaryForEventName:eventName];
    NSMutableDictionary *p = [self propertiesForPrintOrder:printOrder];
    [dict[@"properties"] addEntriesFromDictionary:p];
    [dict[@"properties"] setObject:applePayIsAvailable forKey:@"Apple Pay Available"];
    [dict[@"properties"] setObject:methodName forKey:@"Payment Method Name"];
    [OLAnalytics sendToMixPanelWithDictionary:dict];
    
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:nil printOrder:printOrder extraInfo:@{kOLAnalyticsApplePayAvailable : applePayIsAvailable, kOLAnalyticsPaymentMethod : methodName,kOLAnalyticsEventLevel : @1}];
}

+ (void)trackShippingMethodSelected:(OLPrintOrder *)printOrder methodName:(NSString *)methodName{
    NSString *eventName = kOLAnalyticsEventNameShippingMethodSelected;
    NSString *applePayIsAvailable = [OLKiteUtils isApplePayAvailable] ? @"Yes" : @"No" ;
    
    NSDictionary *dict = [OLAnalytics defaultDictionaryForEventName:eventName];
    NSMutableDictionary *p = [self propertiesForPrintOrder:printOrder];
    [dict[@"properties"] addEntriesFromDictionary:p];
    [dict[@"properties"] setObject:applePayIsAvailable forKey:@"Apple Pay Available"];
    [dict[@"properties"] setObject:methodName forKey:@"Shipping Method Name"];
    [OLAnalytics sendToMixPanelWithDictionary:dict];
    
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:nil printOrder:printOrder extraInfo:@{kOLAnalyticsApplePayAvailable : applePayIsAvailable, kOLAnalyticsPaymentMethod : methodName,kOLAnalyticsEventLevel : @1}];
}

#pragma mark Track Secondary Events - Not Sent to MixPanel

+ (void)trackProductListScreenHitBackTemplateClass:(NSString *)templateClassString{
    [OLAnalytics reportAnalyticsEventToDelegate:kOLAnalyticsEventNameProductListScreenHitBack job:nil printOrder:nil extraInfo:@{kOLAnalyticsProductCategory : templateClassString, kOLAnalyticsEventLevel : @2}];
}

+ (void)trackPhotoProviderPicked:(NSString *)provider forProductName:(NSString *)productName{
    NSString *eventName = kOLAnalyticsEventNameKitePhotoProviderSelected;
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:nil printOrder:nil extraInfo:@{kOLAnalyticsProductName : productName, kOLAnalyticsPhotoSource : nonNilStr(provider), kOLAnalyticsEventLevel : @2}];
}

+ (void)trackQualityScreenHitBack{
    [OLAnalytics reportAnalyticsEventToDelegate:kOLAnalyticsEventNameKiteQualityInfoScreenHitBack job:nil printOrder:nil extraInfo:@{kOLAnalyticsEventLevel : @2}];
}

+ (void)trackOrderHistoryScreenViewed{
    [OLAnalytics reportAnalyticsEventToDelegate:kOLAnalyticsEventNameOrderHistoryViewed job:nil printOrder:nil extraInfo:@{kOLAnalyticsEventLevel : @2}];
}

+ (void)trackOrderHistoryScreenDismissed{
    [OLAnalytics reportAnalyticsEventToDelegate:kOLAnalyticsEventNameOrderHistoryDismissed job:nil printOrder:nil extraInfo:@{kOLAnalyticsEventLevel : @2}];
}

+ (void)trackBasketItemQtyDownForItem:(id<OLPrintJob>)item inOrder:(OLPrintOrder *)printOrder applePayIsAvailable:(NSString *)applePayIsAvailable{
    NSString *eventName = kOLAnalyticsEventNameBasketItemQuantityDown;
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:item printOrder:printOrder extraInfo:@{kOLAnalyticsEventLevel : @2}];
}

+ (void)trackReviewScreenHitBack:(NSString *)productName numberOfPhotos:(NSInteger)numberOfPhotos{
    NSString *eventName = kOLAnalyticsEventNameReviewScreenHitBack;
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:nil printOrder:nil extraInfo:@{kOLAnalyticsProductName : productName, kOLAnalyticsNumberOfPhotos : [NSNumber numberWithInteger:numberOfPhotos], kOLAnalyticsEventLevel : @2}];
}

+ (void)trackBasketItemQtyUpForItem:(id<OLPrintJob>)item inOrder:(OLPrintOrder *)printOrder applePayIsAvailable:(NSString *)applePayIsAvailable{
    NSString *eventName = kOLAnalyticsEventNameBasketItemQuantityUp;
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:item printOrder:printOrder extraInfo:@{kOLAnalyticsEventLevel : @2}];
}

+ (void)trackEditScreenFinishedEditingPhotoForProductName:(NSString *)productName{
    NSString *eventName = kOLAnalyticsEventNameEditScreenFinishedEditingPhoto;
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:nil printOrder:nil extraInfo:@{kOLAnalyticsProductName : productName, kOLAnalyticsEventLevel : @2}];
}

+ (void)trackEditPhotoTappedForProductName:(NSString *)productName{
    NSString *eventName = kOLAnalyticsEventNameEditPhotoTapped;
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:nil printOrder:nil extraInfo:@{kOLAnalyticsProductName : productName, kOLAnalyticsEventLevel : @2}];
}

+ (void)trackReviewScreenDecrementedPhotoQtyForProductName:(NSString *)productName{
    NSString *eventName = kOLAnalyticsEventNameReviewScreenDecrementedPhotoQuantity;
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:nil printOrder:nil extraInfo:@{kOLAnalyticsProductName : productName, kOLAnalyticsEventLevel : @2}];
}

+ (void)trackBasketScreenDidDeleteItem:(id<OLPrintJob>)item inOrder:(OLPrintOrder *)printOrder applePayIsAvailable:(NSString *)applePayIsAvailable{
    NSString *eventName = kOLAnalyticsEventNameBasketScreenDeleteItem;
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:item printOrder:printOrder extraInfo:@{kOLAnalyticsEventLevel : @2}];
}

+ (void)trackBasketScreenHitEditItemDone:(id<OLPrintJob>)item inOrder:(OLPrintOrder *)printOrder applePayIsAvailable:(NSString *)applePayIsAvailable{
    NSString *eventName = kOLAnalyticsEventNameBasketScreenDidEditItem;
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:item printOrder:printOrder extraInfo:@{kOLAnalyticsEventLevel : @2}];
}

+ (void)trackProductDetailsViewOpened:(NSString *)productName hidePrice:(BOOL)hidePrice{
    NSString *eventName = kOLAnalyticsEventNameProductDetailsOpened;
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:nil printOrder:nil extraInfo:@{kOLAnalyticsProductName : productName, kOLAnalyticsEventLevel : @2}];
}

+ (void)trackProductDetailsViewClosed:(NSString *)productName hidePrice:(BOOL)hidePrice{
    NSString *eventName = kOLAnalyticsEventNameProductDetailsClosed;
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:nil printOrder:nil extraInfo:@{kOLAnalyticsProductName : productName, kOLAnalyticsEventLevel : @2}];
}

+ (void)trackBasketScreenHitBackForOrder:(OLPrintOrder *)printOrder applePayIsAvailable:(NSString *)applePayIsAvailable{
    NSString *eventName = kOLAnalyticsEventNameBasketScreenHitBack;
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:nil printOrder:printOrder extraInfo:@{kOLAnalyticsEventLevel : @2}];
}

+ (void)trackBasketScreenSuccessfullyAppliedPromoCode:(NSString *)code forOrder:(OLPrintOrder *)order{
    [OLAnalytics reportAnalyticsEventToDelegate:kOLAnalyticsEventNameBasketScreenSuccessfullyAppliedPromoCode job:nil printOrder:order extraInfo:@{kOLAnalyticsPromoCode : nonNilStr(code), kOLAnalyticsEventLevel : @2}];
}

+ (void)trackBasketScreenUnsuccessfullyAppliedPromoCode:(NSString *)code withError:(NSError *)error forOrder:(OLPrintOrder *)order{
    [OLAnalytics reportAnalyticsEventToDelegate:kOLAnalyticsEventNameBasketScreenPromoCodeFailed job:nil printOrder:order extraInfo:@{kOLAnalyticsPromoCode : nonNilStr(code), kOLAnalyticsError : error ? error : @"", kOLAnalyticsEventLevel : @2}];
}

+ (void)trackBasketScreenDidTapOnPromoCodeBoxforOrder:(OLPrintOrder *)order{
    [OLAnalytics reportAnalyticsEventToDelegate:kOLAnalyticsEventNameBasketScreenDidTaponPromoCodeBox job:nil printOrder:order extraInfo:@{kOLAnalyticsEventLevel : @2}];
}

+ (void)trackBasketScreenPaymentMethodDidCancel:(NSString *)method forOrder:(OLPrintOrder *)order applePayIsAvailable:(NSString *)applePayIsAvailable{
    [OLAnalytics reportAnalyticsEventToDelegate:kOLAnalyticsEventNameBasketScreenPaymentMethodHitBack job:nil printOrder:order extraInfo:@{kOLAnalyticsPaymentMethod : method, kOLAnalyticsEventLevel : @2}];
}

+ (void)trackReviewScreenIncrementedPhotoQtyForProductName:(NSString *)productName{
    NSString *eventName = kOLAnalyticsEventNameReviewScreenIncrementedPhotoQuantity;
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:nil printOrder:nil extraInfo:@{kOLAnalyticsProductName : productName, kOLAnalyticsEventLevel : @2}];
}

+ (void)trackBasketScreenHitEditItem:(id<OLPrintJob>)item inOrder:(OLPrintOrder *)printOrder applePayIsAvailable:(NSString *)applePayIsAvailable{
    NSString *eventName = kOLAnalyticsEventNameBasketScreenHitEditItem;
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:item printOrder:printOrder extraInfo:@{kOLAnalyticsEventLevel : @2}];
}

+ (void)trackShippingScreenHitBackForOrder:(OLPrintOrder *)printOrder{
    [OLAnalytics reportAnalyticsEventToDelegate:kOLAnalyticsEventNameShippingScreenHitBack job:nil printOrder:printOrder extraInfo:@{kOLAnalyticsEventLevel : @2}];
}

+ (void)trackReviewScreenDeletedPhotoForProductName:(NSString *)productName{
    NSString *eventName = kOLAnalyticsEventNameReviewScreenDeletedPhoto;
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:nil printOrder:nil extraInfo:@{kOLAnalyticsProductName : productName, kOLAnalyticsEventLevel : @2}];
}

+ (void)trackProductDescriptionScreenHitBack:(NSString *)productName hidePrice:(BOOL)hidePrice{
    NSString *eventName = kOLAnalyticsEventNameProductDescriptionScreenHitBack;
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:nil printOrder:nil extraInfo:@{kOLAnalyticsProductName : productName, kOLAnalyticsEventLevel : @2}];
}

+ (void)trackImagePickerScreenHitBack:(NSString *)productName{
    NSString *eventName = kOLAnalyticsEventNameImagePickerScreenHitBack;
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:nil printOrder:nil extraInfo:@{kOLAnalyticsProductName : productName, kOLAnalyticsEventLevel : @2}];
}

+ (void)trackPhotobookEditScreenHitBack:(NSString *)productName{
    NSString *eventName = kOLAnalyticsEventNamePhotobookEditScreenHitBack;
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:nil printOrder:nil extraInfo:@{kOLAnalyticsProductName : productName, kOLAnalyticsEventLevel : @2}];
}

+ (void)trackUpsellShown:(BOOL)shown {
    NSString *eventName = kOLAnalyticsEventNameUpsellScreenViewed;
    if (shown) {
        NSDictionary *dict = [OLAnalytics defaultDictionaryForEventName:eventName];
        [OLAnalytics sendToMixPanelWithDictionary:dict];
    }
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:nil printOrder:nil extraInfo:@{@"Shown": [NSNumber numberWithBool:shown], kOLAnalyticsEventLevel : shown ? @1 : @2}];
}

+ (void)trackPaymentMethodScreenHitBack:(OLPrintOrder *)printOrder{
    [OLAnalytics reportAnalyticsEventToDelegate:kOLAnalyticsEventNamePaymentMethodScreenHitBack job:nil printOrder:printOrder extraInfo:@{kOLAnalyticsEventLevel : @2}];
}

+ (void)trackShippingMethodScreenHitBack:(OLPrintOrder *)printOrder{
    [OLAnalytics reportAnalyticsEventToDelegate:kOLAnalyticsEventNameShippingMethodScreenHitBack job:nil printOrder:printOrder extraInfo:@{kOLAnalyticsEventLevel : @2}];
}

+ (void)trackEditScreenDidCancel{
    [OLAnalytics reportAnalyticsEventToDelegate:kOLAnalyticsEventNameEditScreenFinishedEditingPhoto job:nil printOrder:nil extraInfo:@{kOLAnalyticsEventLevel : @2}];
}

+ (void)trackEditScreenButtonTapped:(NSString *)buttonName{
    if (!buttonName){
        return;
    }
    [OLAnalytics reportAnalyticsEventToDelegate:kOLAnalyticsEventNameEditScreenButtonTapped job:nil printOrder:nil extraInfo:@{kOLAnalyticsButtonName : buttonName, kOLAnalyticsEventLevel : @2}];
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
    
    if (printOrder.email) {
        p[@"Shipping Email"] = printOrder.email;
    }
    
    if (printOrder.phone) {
        p[@"Shipping Phone"] = printOrder.phone;
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

+ (NSDictionary *)extraInfo{
    return extraInfo;
}

@end
