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
#import <Stripe/Stripe+ApplePay.h>
#endif
#import "OLPaymentViewController.h"
#import "OLKiteABTesting.h"
#import "OLCheckoutViewController.h"
#import "OLIntegratedCheckoutViewController.h"
#import "OLKiteViewController.h"

@class OLCustomPhotoProvider;

@interface OLKitePrintSDK (Private)

+(NSString *)appleMerchantID;

#ifdef OL_KITE_OFFER_INSTAGRAM
+ (NSString *) instagramRedirectURI;
+ (NSString *) instagramSecret;
+ (NSString *) instagramClientID;
#endif

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
#ifdef OL_KITE_OFFER_INSTAGRAM
    return [OLKitePrintSDK instagramSecret] && ![[OLKitePrintSDK instagramSecret] isEqualToString:@""] && [OLKitePrintSDK instagramClientID] && ![[OLKitePrintSDK instagramClientID] isEqualToString:@""] && [OLKitePrintSDK instagramRedirectURI] && ![[OLKitePrintSDK instagramRedirectURI] isEqualToString:@""];
#else
    return NO;
#endif
}

+ (BOOL)qrCodeUploadEnabled {
    return [OLKitePrintSDK QRCodeUploadEnabled];
}

+ (BOOL)facebookEnabled{
#ifdef OL_KITE_OFFER_FACEBOOK
    return YES;
#else
    return NO;
#endif
}

+ (BOOL)imageProvidersAvailable:(UIViewController *)topVc{
    OLKiteViewController *kiteVc = [OLKiteUtils kiteVcForViewController:topVc];
    id<OLKiteDelegate> delegate = kiteVc.delegate;
    
    if ([delegate respondsToSelector:@selector(kiteControllerShouldAllowUserToAddMorePhotos:)] && ![delegate kiteControllerShouldAllowUserToAddMorePhotos:kiteVc]){
        return NO;
    }
    
    BOOL customProvidersAvailable = NO;
#ifdef OL_KITE_OFFER_CUSTOM_IMAGE_PROVIDERS
    customProvidersAvailable = kiteVc.customImageProviders.count > 0;
#endif
    
    return [OLKiteUtils cameraRollEnabled:topVc] || [OLKiteUtils instagramEnabled] || [OLKiteUtils facebookEnabled] || customProvidersAvailable;
}

+ (BOOL)cameraRollEnabled:(UIViewController *)topVc{
    OLKiteViewController *kiteVc = [OLKiteUtils kiteVcForViewController:topVc];
    id<OLKiteDelegate> delegate = kiteVc.delegate;
    
    if ([delegate respondsToSelector:@selector(kiteControllerShouldDisableCameraRoll:)] && [delegate kiteControllerShouldDisableCameraRoll:kiteVc]){
        return NO;
    }
    
    return YES;
}

+ (NSInteger)cameraRollProviderIndex:(UIViewController *)topVc{
    NSInteger index = -1;
    if ([OLKiteUtils cameraRollEnabled:topVc]){
        index++;
    }
    
    return index;
}

+ (NSInteger)facebookProviderIndex:(UIViewController *)topVc{
    NSInteger index = -1;
    if (![OLKiteUtils facebookEnabled]){
        return index;
    }
    else{
        index++;
    }
    
    if ([OLKiteUtils cameraRollEnabled:topVc]){
        index++;
    }
    
    return index;
}

+ (NSInteger)instagramProviderIndex:(UIViewController *)topVc{
    NSInteger index = -1;
    if (![OLKiteUtils instagramEnabled]){
        return index;
    }
    else{
        index++;
    }
    
    if ([OLKiteUtils cameraRollEnabled:topVc]){
        index++;
    }
    if ([OLKiteUtils facebookEnabled]){
        index++;
    }
    
    return index;
}

+ (NSInteger)qrCodeProviderStartIndex:(UIViewController *)topVc{
    NSInteger index = 0;
    
    if ([OLKiteUtils cameraRollEnabled:topVc]){
        index++;
    }
    if ([OLKiteUtils facebookEnabled]){
        index++;
    }
    if ([OLKiteUtils instagramEnabled]){
        index++;
    }
    
    return index;
}

#ifdef OL_KITE_OFFER_CUSTOM_IMAGE_PROVIDERS
+ (NSInteger)customProvidersStartIndex:(UIViewController *)topVc{
    NSInteger index = 0;

    if ([OLKiteUtils cameraRollEnabled:topVc]){
        index++;
    }
    if ([OLKiteUtils facebookEnabled]){
        index++;
    }
    if ([OLKiteUtils instagramEnabled]){
        index++;
    }
    if ([OLKiteUtils qrCodeUploadEnabled]){
        index++;
    }
    
    return index;
}
#endif

+ (id<OLKiteDelegate>)kiteDelegate:(UIViewController *)topVC {
    OLKiteViewController *kiteVC = [self kiteVcForViewController:topVC];
    return kiteVC.delegate;
}

#ifdef OL_KITE_OFFER_APPLE_PAY
+(BOOL)isApplePayAvailable{
    PKPaymentRequest *request = [Stripe paymentRequestWithMerchantIdentifier:[OLKitePrintSDK appleMerchantID]];
    
    return [Stripe canSubmitPaymentRequest:request];
}
#endif

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

+ (NSString *)reviewViewControllerIdentifierForProduct:(OLProduct *)product photoSelectionScreen:(BOOL)photoSelectionScreen{
    OLTemplateUI templateUI = product.productTemplate.templateUI;
    if (templateUI == kOLTemplateUICase){
        return @"OLCaseViewController";
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
        return @"PhotoSelectionViewController";
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
    
    return nil;
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
    NSURLSessionDataTask *downloadTask = [[NSURLSession sharedSession]
                                          dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                              if (error){
                                                  failure(error);
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
}

@end
