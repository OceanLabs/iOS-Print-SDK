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
#import "OLProduct.h"
#import "OLPrintJob.h"
#import "OLKitePrintSDK.h"
#include <sys/sysctl.h>
#import "OLKiteABTesting.h"
#import "NSDictionary+RequestParameterData.h"
#import "OLKiteUtils.h"

static NSString *const kKeyUserDistinctId = @"ly.kite.sdk.kKeyUserDistinctId";
static NSString *const kKeySDKLaunchCount = @"ly.kite.sdk.kKeySDKLaunchCount";
static NSString *const kKeyOLDevicePushToken = @"ly.kite.sdk.kKeyOLDevicePushToken";

static NSString *const kKeyServiceName = @"ly.kite.sdk.kKeyServiceName";

static NSDictionary *extraInfo;

static NSString *nonNilStr(NSString *str) {
    return str == nil ? @"" : str;
}

static BOOL optInToRemoteAnalytics = NO;

@interface OLKitePrintSDK (Private)

+ (NSString *)apiEndpoint;
+ (NSString *)apiVersion;

@end

@interface OLAnalytics () <AnalyticsDelegate>
@end

@implementation OLAnalytics

+ (instancetype)sharedInstance {
    static dispatch_once_t once;
    static OLAnalytics * sharedInstance;
    dispatch_once(&once, ^ {
        sharedInstance = [[self alloc] init];
        [Analytics shared].delegate = sharedInstance;
    });
    return sharedInstance;
}

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

+ (void)setOptInToRemoteAnalytics:(BOOL)optIn {
    optInToRemoteAnalytics = optIn;
    [Analytics shared].optInToRemoteAnalytics = optIn;
}

+ (NSString *)userDistinctId{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *uuid = [defaults objectForKey:kKeyUserDistinctId];
    if (!uuid){
        uuid = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        [defaults setObject:uuid forKey:kKeyUserDistinctId];
        [defaults synchronize];
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
    return [OLKitePrintSDK environment] == OLKitePrintSDKEnvironmentLive ? @"Live" : @"Development";
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

+ (NSDictionary *)dictionaryForJob:(id<OLPrintJob>)job{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    OLProductTemplate *template = [OLProductTemplate templateWithId:[job templateId]];
    if (template){
        dict[kOLAnalyticsProductName] = template.name;
        dict[kOLAnalyticsProductId] = template.identifier;
        dict[kOLAnalyticsNumberOfPhotosInItem] = [NSNumber numberWithInteger:[job quantity]];
        dict[kOLAnalyticsQuantity] = [NSNumber numberWithInteger:[job extraCopies]+1];
    }
    return dict;
}

+ (void)reportAnalyticsEventToDelegate:(NSString *)eventName job:(id<OLPrintJob>)job extraInfo:(NSDictionary *)info{
    if (![OLAnalytics sharedInstance].delegate){
        return;
    }
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    dict[kOLAnalyticsEventName] = nonNilStr(eventName);
    if (job){
        [dict addEntriesFromDictionary:[OLAnalytics dictionaryForJob:job]];
    }
    if (info){
        [dict addEntriesFromDictionary:info];
    }
    
    [[OLAnalytics sharedInstance].delegate logKiteAnalyticsEventWithInfo:dict];
}

#pragma mark Track Events

+ (void)trackKiteViewControllerLoadedWithEntryPoint:(NSString *)entryPoint {
    [OLAnalytics incrementLaunchSDKCount];
    
    NSString *eventName = kOLAnalyticsEventNameKiteLoaded;
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:nil extraInfo:@{kOLAnalyticsEventType : kOLAnalyticsEventTypeAction,}];
}

+ (void)trackCategoryListScreenViewed{
    NSString *eventName = kOLAnalyticsEventNameCategoryListScreenViewed;
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:nil extraInfo:@{kOLAnalyticsEventType : kOLAnalyticsEventTypeScreenViewed,}];
}

+ (void)trackQualityInfoScreenViewed{
    NSString *eventName = kOLAnalyticsEventNameQualityInfoScreenViewed;
    
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:nil extraInfo:@{kOLAnalyticsEventType : kOLAnalyticsEventTypeScreenViewed,}];
}

+ (void)trackPrintAtHomeTapped{
    NSString *eventName = kOLAnalyticsEventNamePrintAtHomeTapped;
    
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:nil extraInfo:@{}];
}

+ (void)trackProductDetailsScreenViewed:(OLProductTemplate *)productTemplate hidePrice:(BOOL)hidePrice{
    NSString *eventName = kOLAnalyticsEventNameProductDetailsScreenViewed;
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:nil extraInfo:@{kOLAnalyticsProductName : nonNilStr(productTemplate.name), kOLAnalyticsProductId : nonNilStr(productTemplate.identifier), kOLAnalyticsEventType : kOLAnalyticsEventTypeScreenViewed,}];
}

+ (void)trackProductListScreenViewedWithTemplateClass:(NSString *)templateClassString{
    NSString *eventName = kOLAnalyticsEventNameProductListScreenViewed;
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:nil extraInfo:@{kOLAnalyticsProductCategory : templateClassString, kOLAnalyticsEventType : kOLAnalyticsEventTypeScreenViewed,}];
}

+ (void)trackImagePickerScreenViewed:(NSString *)productName{
    NSString *eventName = kOLAnalyticsEventNameImagePickerScreenViewed;
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:nil extraInfo:@{kOLAnalyticsProductName : productName, kOLAnalyticsEventType : kOLAnalyticsEventTypeScreenViewed,}];
}

+ (void)trackReviewScreenViewed:(NSString *)productName{
    NSString *eventName = kOLAnalyticsEventNameReviewScreenViewed;
    [OLAnalytics reportAnalyticsEventToDelegate:eventName job:nil extraInfo:@{kOLAnalyticsProductName : productName, kOLAnalyticsEventType : kOLAnalyticsEventTypeScreenViewed,}];
}

+ (void)setExtraInfo:(NSDictionary *)info{
    extraInfo = info;
}

+ (NSDictionary *)extraInfo{
    return extraInfo;
}

- (void)photobookAnalyticsEventDidFireWithType:(enum AnalyticsEventType)type name:(NSString * _Nonnull)name properties:(NSDictionary<NSString *, id> * _Nonnull)properties {
    NSMutableDictionary *dict = [properties mutableCopy];
    dict[kOLAnalyticsEventType] = type == AnalyticsEventTypeScreenViewed ? kOLAnalyticsEventTypeScreenViewed : type == AnalyticsEventTypeAction ? kOLAnalyticsEventTypeAction : kOLAnalyticsEventTypeError;
    dict[kOLAnalyticsEventName] = name;
    [self.delegate logKiteAnalyticsEventWithInfo:dict];
}

@end
