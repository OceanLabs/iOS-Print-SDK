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

#import "OLKiteUtils.h"
#import "OLKitePrintSDK.h"
#import "OLProductHomeViewController.h"
#ifdef OL_KITE_OFFER_APPLE_PAY
#ifdef COCOAPODS
#import <Stripe/Stripe.h>
#else
#import "Stripe.h"
#endif
#endif
#import "OLPaymentViewController.h"
#import "OLKiteABTesting.h"
#import "OLCheckoutViewController.h"
#import "OLIntegratedCheckoutViewController.h"
#import "OLKiteViewController.h"
#import "OLUserSession.h"
#import "FBSDKLoginManager.h"

@class OLCustomPhotoProvider;

@interface OLKitePrintSDK (Private)

+(NSString *)appleMerchantID;

+ (NSString *) instagramRedirectURI;
+ (NSString *) instagramSecret;
+ (NSString *) instagramClientID;

+ (BOOL)QRCodeUploadEnabled;

@end

@interface OLKiteViewController (Private)
@property (strong, nonatomic) NSMutableArray <OLCustomPhotoProvider *> *customImageProviders;
@end

@implementation OLKiteUtils

+ (NSBundle *)kiteBundle{
    return [NSBundle bundleForClass:[OLKiteViewController class]];
}

+ (NSString *)userEmail:(UIViewController *)topVC {
    OLKiteViewController *kiteVC = [self kiteVcForViewController:topVC];
    return kiteVC.userEmail;
}

+ (NSString *)userPhone:(UIViewController *)topVC {
    OLKiteViewController *kiteVC = [self kiteVcForViewController:topVC];
    return kiteVC.userPhone;
}

+ (BOOL)instagramEnabled{
    if (YES){ //Check what needs to be checked in terms of installation
        return [OLKitePrintSDK instagramSecret] && ![[OLKitePrintSDK instagramSecret] isEqualToString:@""] && [OLKitePrintSDK instagramClientID] && ![[OLKitePrintSDK instagramClientID] isEqualToString:@""] && [OLKitePrintSDK instagramRedirectURI] && ![[OLKitePrintSDK instagramRedirectURI] isEqualToString:@""];
    }
    
    return NO;
}

+ (BOOL)qrCodeUploadEnabled {
    return [OLKitePrintSDK QRCodeUploadEnabled];
}

+ (BOOL)facebookEnabled{
    //TODO check that it is actually set up
    if ([FBSDKLoginManager class]){
        return YES;
    }
    
    return NO;
}

+ (BOOL)imageProvidersAvailable:(UIViewController *)topVc{
    OLKiteViewController *kiteVc = [OLKiteUtils kiteVcForViewController:topVc];
    id<OLKiteDelegate> delegate = kiteVc.delegate;
    
    if ([delegate respondsToSelector:@selector(kiteControllerShouldAllowUserToAddMorePhotos:)] && ![delegate kiteControllerShouldAllowUserToAddMorePhotos:kiteVc]){
        return NO;
    }
    
    return [OLKiteUtils cameraRollEnabled:topVc] || [OLKiteUtils instagramEnabled] || [OLKiteUtils facebookEnabled] || kiteVc.customImageProviders.count > 0;
}

+ (BOOL)cameraRollEnabled:(UIViewController *)topVc{
    OLKiteViewController *kiteVc = [OLKiteUtils kiteVcForViewController:topVc];
    id<OLKiteDelegate> delegate = kiteVc.delegate;
    
    if ([delegate respondsToSelector:@selector(kiteControllerShouldDisableCameraRoll:)] && [delegate kiteControllerShouldDisableCameraRoll:kiteVc]){
        return NO;
    }
    
    return YES;
}

+ (id<OLKiteDelegate>)kiteDelegate:(UIViewController *)topVC {
    OLKiteViewController *kiteVC = [self kiteVcForViewController:topVC];
    return kiteVC.delegate;
}

+ (void)checkoutViewControllerForPrintOrder:(OLPrintOrder *)printOrder handler:(void(^)(id vc))handler{
    OLPaymentViewController *vc = [[OLPaymentViewController alloc] initWithPrintOrder:printOrder];
    handler(vc);
}

+ (void)shippingControllerForPrintOrder:(OLPrintOrder *)printOrder handler:(void(^)(OLCheckoutViewController *vc))handler{
    OLCheckoutViewController *vc;
    if ([[OLKiteABTesting sharedInstance].checkoutScreenType isEqualToString:@"Classic"]){
        vc = [[OLCheckoutViewController alloc] initWithPrintOrder:printOrder];
    }
    else{
        vc = [[OLIntegratedCheckoutViewController alloc] initWithPrintOrder:printOrder];
    }
    handler(vc);
}

+ (UIFont *)fontWithName:(NSString *)name size:(CGFloat)size{
    UIFont *font = [UIFont fontWithName:name size:size];
    if (!font){
        font = [UIFont systemFontOfSize:size];
    }
    
    return font;
}

+ (NSString *)reviewViewControllerIdentifierForProduct:(OLProduct *)product photoSelectionScreen:(BOOL)photoSelectionScreen{
    OLTemplateUI templateUI = product.productTemplate.templateUI;
    if (templateUI == kOLTemplateUICase){
        return @"OLCaseViewController";
    }
    else if (templateUI == kOLTemplateUIApparel){
        return @"OLTShirtReviewViewController";
    }
    else if (templateUI == kOLTemplateUIPostcard){
        return @"OLPostcardViewController";
    }
    else if (templateUI == kOLTemplateUIPoster && product.productTemplate.gridCountX == 1 && product.productTemplate.gridCountY == 1){
        return @"OLSingleImageProductReviewViewController";
    }
    else if (templateUI == kOLTemplateUIPhotobook){
        return @"OLEditPhotobookViewController";
    }
    else if (templateUI == kOLTemplateUINonCustomizable){
        return @"OLPaymentViewController";
    }
    else if (photoSelectionScreen){
        return @"OLImagePickerViewController";
    }
    else if (templateUI == kOLTemplateUIPoster){
        return @"OLPosterViewController";
    }
    else if (templateUI == kOLTemplateUIFrame){
        return @"FrameOrderReviewViewController";
    }
    else{
        return @"OrderReviewViewController";
    }
}

+ (OLKiteViewController *)kiteVcForViewController:(UIViewController *)theVc{
    if ([theVc isKindOfClass:[OLKiteViewController class]]){
        return (OLKiteViewController *)theVc;
    }
    
    UIViewController *vc = theVc.parentViewController;
    while (vc) {
        if ([vc isKindOfClass:[OLKiteViewController class]]){
            return (OLKiteViewController *)vc;
            break;
        }
        else{
            vc = vc.parentViewController;
        }
    }
    vc = theVc.presentingViewController;
    while (vc) {
        if ([vc isKindOfClass:[OLKiteViewController class]]){
            return (OLKiteViewController *)vc;
            break;
        }
        else{
            vc = vc.presentingViewController;
        }
    }
    
    for (UIViewController *vc in theVc.navigationController.viewControllers){
        if ([vc isKindOfClass:[OLKiteViewController class]]){
            return (OLKiteViewController *)vc;
        }
    }
    
    return [self kiteVcForViewController:theVc.presentingViewController];
}

+ (BOOL)assetArrayContainsPDF:(NSArray *)array{
    for (OLAsset *asset in array){
        if (![asset isKindOfClass:[OLAsset class]]){
            continue;
        }
        if (asset.mimeType == kOLMimeTypePDF){
            return YES;
        }
    }
    
    return NO;
}

+ (void)registerDefaultsWithURL:(NSURL *)url
                        success:(void (^)(NSDictionary *defaults))success
                        failure:(void (^)(NSError *error))failure{
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
    
    NSCachedURLResponse *cachedResponse = [[NSURLCache sharedURLCache] cachedResponseForRequest:request];
    if (cachedResponse.data){
        [[NSURLCache sharedURLCache] removeCachedResponseForRequest:request];
    }
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:nil delegateQueue:nil];
    
    NSURLSessionDataTask *downloadTask = [session
                                          dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                              if (error){
                                                  failure(error);
                                              }
                                              else if (!((data && [(NSHTTPURLResponse *)response statusCode] >= 200 && [(NSHTTPURLResponse *)response statusCode] <= 299))){
                                                  failure([NSError errorWithDomain:@"ly.kite.remoteconfig" code:[(NSHTTPURLResponse *)response statusCode] userInfo:nil]);
                                              }
                                              else if (data){
                                                  NSURL *fileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"remote.plist"]];
                                                  [data writeToURL:fileURL atomically:YES];
                                                  NSDictionary *dict = [NSDictionary dictionaryWithContentsOfURL:fileURL];
                                                  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                                                  [defaults registerDefaults:dict];
                                                  [defaults synchronize];
                                                  success(dict);
                                              }
                                          }];
    [downloadTask resume];
    [session finishTasksAndInvalidate];
}

@end
