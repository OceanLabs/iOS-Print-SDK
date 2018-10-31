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

@class OLProductTemplate;
@protocol OLPrintJob;

@protocol OLAnalyticsDelegate <NSObject>
/**
 *  Notifies the delegate of an analytics event.
 *
 *  @param info The dictionary containing the information about the event
 */
- (void)logKiteAnalyticsEventWithInfo:(NSDictionary *)info;
@end

static NSString *const kOLAnalyticsEventNameKiteLoaded = @"Kite Loaded";
static NSString *const kOLAnalyticsEventNameCategoryListScreenViewed = @"Category List Screen Viewed";
static NSString *const kOLAnalyticsEventNameQualityInfoScreenViewed = @"Quality Info Screen Viewed";
static NSString *const kOLAnalyticsEventNamePrintAtHomeTapped = @"Print At Home Tapped";
static NSString *const kOLAnalyticsEventNameProductDetailsScreenViewed = @"Product Details Screen Viewed";
static NSString *const kOLAnalyticsEventNameProductListScreenViewed = @"Product List Screen Viewed";
static NSString *const kOLAnalyticsEventNameImagePickerScreenViewed = @"Image Picker Screen Viewed";
static NSString *const kOLAnalyticsEventNameReviewScreenViewed = @"Review Screen Viewed";

// Property Names
static NSString *const kOLAnalyticsEventName = @"Event Name";
static NSString *const kOLAnalyticsEventType = @"Event Type";
static NSString *const kOLAnalyticsProductCategory = @"Product Category";
static NSString *const kOLAnalyticsProductName = @"Product Name";
static NSString *const kOLAnalyticsProductId = @"Product ID";
static NSString *const kOLAnalyticsNumberOfPhotos = @"Number of Photos";
static NSString *const kOLAnalyticsNumberOfPhotosInItem = @"Number of Photos in Item";
static NSString *const kOLAnalyticsQuantity = @"Quantity";

// Event Types
static NSString *const kOLAnalyticsEventTypeScreenViewed = @"Screen Viewed";
static NSString *const kOLAnalyticsEventTypeAction = @"Action";
static NSString *const kOLAnalyticsEventTypeError = @"Error";

@interface OLAnalytics : NSObject

+ (void)addPushDeviceToken:(NSData *)deviceToken;
+ (void)setOptInToRemoteAnalytics:(BOOL)optIn;
+ (void)trackKiteViewControllerLoadedWithEntryPoint:(NSString *)entryPoint;
+ (void)trackCategoryListScreenViewed;
+ (void)trackProductDetailsScreenViewed:(OLProductTemplate *)productTemplate hidePrice:(BOOL)hidePrice;
+ (void)trackProductListScreenViewedWithTemplateClass:(NSString *)templateClassString;
+ (void)trackImagePickerScreenViewed:(NSString *)productName;
+ (void)trackReviewScreenViewed:(NSString *)productName;
+ (void)trackQualityInfoScreenViewed;
+ (void)trackPrintAtHomeTapped;

+ (void)incrementLaunchSDKCount;
+ (void)setExtraInfo:(NSDictionary *)info;
+ (NSString *)userDistinctId;

+ (NSDictionary *)extraInfo;

+ (instancetype)sharedInstance;
@property (nonatomic, weak) id<OLAnalyticsDelegate> delegate;
@end
