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

#import "OLKiteUtils.h"
#import "OLKitePrintSDK.h"
#import "OLProductHomeViewController.h"
#import "OLKiteABTesting.h"
#import "OLKiteViewController.h"
#import "OLUserSession.h"
#import "OLPayPalWrapper.h"
#import "OLKiteViewController+Private.h"

@import Contacts;
@import PassKit;
@import Stripe;

@interface OLKitePrintSDK (Private)
+ (NSString *)appleMerchantID;
+ (NSString *)instagramRedirectURI;
+ (NSString *)instagramSecret;
+ (NSString *)instagramClientID;
@end

@implementation OLKiteUtils

+ (NSBundle *)kiteLocalizationBundle{
    return [NSBundle bundleWithPath:[[NSBundle bundleForClass:[OLKiteViewController class]] pathForResource:@"OLKiteLocalizationResources" ofType:@"bundle"]];
}

+ (NSBundle *)kiteResourcesBundle{
    NSBundle *bundle = [NSBundle bundleWithPath:[[NSBundle bundleForClass:[OLKiteViewController class]] pathForResource:@"OLKiteResources" ofType:@"bundle"]];
    if (!bundle) {
        bundle = [NSBundle bundleForClass:[OLKiteViewController class]];
    }
    return bundle;
}

+ (BOOL)qrCodeUploadEnabled {
    return [OLUserSession currentSession].kiteVc.qrCodeUploadEnabled;
}

+ (BOOL)recentsAvailable{
    return [OLUserSession currentSession].appAssets.count != 0 || [OLUserSession currentSession].recentPhotos.count != 0;
}

+ (NSInteger)numberOfProvidersAvailable{
    NSInteger providers = 0;
    if ([self cameraRollEnabled]){
        providers++;
    }
    if ([self qrCodeUploadEnabled]){
        providers++;
    }
    if ([self recentsAvailable]){
        providers++;
    }
    providers += [OLUserSession currentSession].kiteVc.customImageProviders.count;
    
    return providers;
}

+ (BOOL)imageProvidersAvailable{
    if ([OLUserSession currentSession].kiteVc.disallowUserToAddMorePhotos){
        return NO;
    }
    
    return [self numberOfProvidersAvailable] > 0;
}

+ (BOOL)cameraRollEnabled{
    if ([OLUserSession currentSession].kiteVc.disableCameraRoll){
        return NO;
    }
    
    return YES;
}

+ (UIFont *)fontWithName:(NSString *)name size:(CGFloat)size{
    UIFont *font = [UIFont fontWithName:name size:size];
    if (!font){
        font = [UIFont systemFontOfSize:size];
    }
    
    return font;
}

+ (BOOL)assetArrayContainsPDF:(NSArray *)array{
    for (OLAsset *asset in array){
        if (![asset isKindOfClass:[OLAsset class]]){
            continue;
        }
//        if (asset.mimeType == kOLMimeTypePDF){
//            return YES;
//        }
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
