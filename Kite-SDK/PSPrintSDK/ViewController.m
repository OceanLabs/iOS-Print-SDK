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

/**********************************************************************
 * Insert your API keys here. These are found under your profile
 * by logging in to the developer portal at https://www.kite.ly
 **********************************************************************/
static NSString *const kAPIKeySandbox = @"REPLACE_WITH_YOUR_API_KEY"; // replace with your Sandbox API key found under the Profile section in the developer portal
static NSString *const kAPIKeyLive = @"REPLACE_WITH_YOUR_API_KEY"; // replace with your Live API key found under the Profile section in the developer portal

static NSString *const kApplePayMerchantIDKey = @"merchant.ly.kite.sdk"; // Replace with your merchant ID
static NSString *const kApplePayBusinessName = @"Kite.ly"; //Replace with your business name

static NSString *const kURLScheme = @"kitely";

#import "ViewController.h"
#import "OLKitePrintSDK.h"
#import "OLImageCachingManager.h"
#import "OLImagePickerViewController.h"
#import "OLKiteUtils.h"

@import Photos;

@interface ViewController () <UINavigationControllerDelegate, OLKiteDelegate, OLImagePickerViewControllerDelegate>
@property (nonatomic, weak) IBOutlet UISegmentedControl *environmentPicker;
@end

@interface OLKitePrintSDK (Private)
+ (void)setUseStaging:(BOOL)staging;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [OLKitePrintSDK setApplePayMerchantID:kApplePayMerchantIDKey];
    [OLKitePrintSDK setApplePayPayToString:kApplePayBusinessName];
    [OLKitePrintSDK setURLScheme:kURLScheme];
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (IBAction)onButtonPrintLocalPhotos:(id)sender {
    if (![self isAPIKeySet]) return;
    
    OLImagePickerViewController *vc = [[UIStoryboard storyboardWithName:@"OLKiteStoryboard" bundle:[OLKiteUtils kiteResourcesBundle]] instantiateViewControllerWithIdentifier:@"OLImagePickerViewController"];
    vc.delegate = self;
    [self presentViewController:[[UINavigationController alloc] initWithRootViewController:vc] animated:YES completion:NULL];
}

- (NSString *)apiKey {
    if ([self environment] == OLKitePrintSDKEnvironmentSandbox) {
        return kAPIKeySandbox;
    } else {
        return kAPIKeyLive;
    }
}

- (NSString *)liveKey {
    return kAPIKeyLive;
}

- (NSString *)sandboxKey {
    return kAPIKeySandbox;
}

- (BOOL)isAPIKeySet {
    if (![[[NSProcessInfo processInfo]environment][@"OL_KITE_UI_TEST"] isEqualToString:@"1"]){
        if ([[self apiKey] isEqualToString:@"REPLACE_WITH_YOUR_API_KEY"] && ![OLKitePrintSDK apiKey]) {
            UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"API Key Required" message:@"Set your API keys at the top of ViewController.m before you can print. This can be found under your profile at http://kite.ly" preferredStyle:UIAlertControllerStyleAlert];
            [ac addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:NULL]];
            [self presentViewController:ac animated:YES completion:NULL];
            return NO;
        }
    }
    else{
        [OLKitePrintSDK setAPIKey:[[NSProcessInfo processInfo]environment][@"TEST_API_KEY"] withEnvironment:OLKitePrintSDKEnvironmentSandbox];
    }
    
    return YES;
}

- (OLKitePrintSDKEnvironment)environment {
    if (self.environmentPicker.selectedSegmentIndex == 0) {
        return OLKitePrintSDKEnvironmentSandbox;
    } else {
        return OLKitePrintSDKEnvironmentLive;
    }
}

- (void)printWithAssets:(NSArray *)assets {
    if (![[[NSProcessInfo processInfo]environment][@"OL_KITE_UI_TEST"] isEqualToString:@"1"]){
        if (![self isAPIKeySet]) return;
        [OLKitePrintSDK setAPIKey:[self apiKey] withEnvironment:[self environment]];
    }
    
    OLKiteViewController *vc = [[OLKiteViewController alloc] initWithAssets:assets];
    vc.delegate = self;
    
    [self addCatsAndDogsImagePickersToKite:vc];
    
    vc.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:vc animated:YES completion:NULL];
}
- (IBAction)onButtonPrintRemotePhotos:(id)sender {
    if (![self isAPIKeySet]) return;
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"Remote URLS" message:@"Feel free to Change hardcoded remote image URLs in ViewController.m onButtonPrintRemotePhotos:" preferredStyle:UIAlertControllerStyleAlert];
    [ac addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(id action){
        NSArray *assets = @[[OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/1.jpg"] size:CGSizeMake(1824,1216)],
                            [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/2.jpg"] size: CGSizeMake(612, 612)],
                            [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/3.jpg"] size: CGSizeMake(843, 960)],
                            [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/4.jpg"] size: CGSizeMake(1034, 1034)],
                            ];
        
        [self printWithAssets:assets];
    }]];
    [self presentViewController:ac animated:YES completion:NULL];
}

- (void)addCatsAndDogsImagePickersToKite:(OLKiteViewController *)kvc{
    OLImagePickerProviderCollection *dogsCollection = [[OLImagePickerProviderCollection alloc] initWithArray:@[[OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/5.jpg"] size: CGSizeMake(2048, 1362)], [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/6.jpg"] size: CGSizeMake(2048, 1152)], [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/7.jpg"] size: CGSizeMake(1600, 1144)], [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/8.jpg"] size: CGSizeMake(1882, 2509)]] name:@"Dogs"];
    OLImagePickerProviderCollection *catsCollection = [[OLImagePickerProviderCollection alloc] initWithArray:@[[OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/1.jpg"] size:CGSizeMake(1824,1216)], [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/2.jpg"] size:CGSizeMake(612, 612)], [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/3.jpg"] size:CGSizeMake(843, 960)], [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/4.jpg"] size:CGSizeMake(1034, 1034)], [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/9.jpg"] size:CGSizeMake(3264, 2448)], [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/10.jpg"] size:CGSizeMake(3456, 2592)]] name:@"Cats"];
    [kvc addCustomPhotoProviderWithCollections:@[catsCollection, dogsCollection] name:@"Pets" icon:[UIImage imageNamed:@"dog"]];
}

- (void)imagePicker:(OLImagePickerViewController *)vc didFinishPickingAssets:(NSMutableArray *)assets added:(NSArray<OLAsset *> *)addedAssets removed:(NSArray *)removedAssets{
    [vc dismissViewControllerAnimated:YES completion:^{
        [self printWithAssets:assets];
    }];
}

- (void)logKiteAnalyticsEventWithInfo:(NSDictionary *)info{
    NSLog(@"%@", info);
}

@end
