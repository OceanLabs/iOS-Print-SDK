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

/**********************************************************************
 * For Internal Kite.ly use ONLY
 **********************************************************************/
static NSString *const kAPIKeySandbox = @"REPLACE_WITH_YOUR_API_KEY"; // replace with your Sandbox API key found under the Profile section in the developer portal
static NSString *const kAPIKeyLive = @"REPLACE_WITH_YOUR_API_KEY"; // replace with your Live API key found under the Profile section in the developer portal

static NSString *const kApplePayMerchantIDKey = @"merchant.ly.kite.sdk"; // Replace with your merchant ID
static NSString *const kApplePayBusinessName = @"Kite.ly"; //Replace with your business name

#import "CI-ViewController.h"
#import "OLKitePrintSDK.h"
#import "OLImageCachingManager.h"
#import "OLUserSession.h"
#import "OLImagePickerViewController.h"
#import "CustomImagePickerViewController.h"

@import Photos;

@interface CIViewController () <UINavigationControllerDelegate, OLKiteDelegate, OLImagePickerViewControllerDelegate>
@property (nonatomic, weak) IBOutlet UISegmentedControl *environmentPicker;
@property (nonatomic, strong) OLPrintOrder* printOrder;
@end

@interface OLKitePrintSDK (Private)
+ (void)setUseStaging:(BOOL)staging;
@end

@implementation CIViewController

-(void)viewDidAppear:(BOOL)animated{
    self.printOrder = [[OLPrintOrder alloc] init];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [OLKitePrintSDK setInstagramEnabledWithClientID:@"1af4c208cbdc4d09bbe251704990638f" secret:@"c8a5b1b1806f4586afad2f277cee1d5c" redirectURI:@"kitely://instagram-callback"];
    
    [OLKitePrintSDK setApplePayMerchantID:kApplePayMerchantIDKey];
    [OLKitePrintSDK setApplePayPayToString:kApplePayBusinessName];
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (IBAction)onButtonPrintLocalPhotos:(id)sender {
    if (![self isAPIKeySet]) return;
    
    OLImagePickerViewController *vc = [[UIStoryboard storyboardWithName:@"OLKiteStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"OLImagePickerViewController"];
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
    [self setupCIDeploymentWithAssets:assets];
    return;
}
- (IBAction)onButtonPrintRemotePhotos:(id)sender {
    if (![self isAPIKeySet]) return;
    NSArray *assets = @[[OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/1.jpg"]],
                        [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/2.jpg"]],
                        [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/3.jpg"]],
                        [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/4.jpg"]]];
    
    [self printWithAssets:assets];
}

- (void)addCatsAndDogsImagePickersToKite:(OLKiteViewController *)kvc{
    OLImagePickerProviderCollection *dogsCollection = [[OLImagePickerProviderCollection alloc] initWithArray:@[[OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/5.jpg"]], [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/6.jpg"]]] name:@"Dogs"];
    OLImagePickerProviderCollection *catsCollection = [[OLImagePickerProviderCollection alloc] initWithArray:@[[OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/1.jpg"]], [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/2.jpg"]], [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/3.jpg"]], [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/4.jpg"]]] name:@"Cats"];
    [kvc addCustomPhotoProviderWithCollections:@[catsCollection, dogsCollection] name:@"Pets" icon:[UIImage imageNamed:@"dog"]];
}

- (void)imagePicker:(OLImagePickerViewController *)vc didFinishPickingAssets:(NSMutableArray *)assets added:(NSArray<OLAsset *> *)addedAssets removed:(NSArray *)removedAssets{
    [vc dismissViewControllerAnimated:YES completion:^{
        [self printWithAssets:assets];
    }];
}

- (void)logKiteAnalyticsEventWithInfo:(NSDictionary *)info{
#ifdef OL_KITE_VERBOSE
    NSLog(@"%@", info);
#endif
}

#pragma mark Internal

- (void)setupCIDeploymentWithAssets:(NSArray *)assets{
    BOOL shouldOfferAPIChange = YES;
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    
    if (!([pasteboard containsPasteboardTypes: [NSArray arrayWithObject:@"public.utf8-plain-text"]] && pasteboard.string.length == 40)) {
        shouldOfferAPIChange = NO;
    }
    
    if (shouldOfferAPIChange){
        UIAlertController *ac = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Possible API key detected in clipboard", @"") message:NSLocalizedString(@"Do you want to use this instead of the built-in ones?", @"") preferredStyle:UIAlertControllerStyleAlert];
        [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"No", @"") style:UIAlertActionStyleDefault handler:^(id action){
#define STRINGIZE(x) #x
#define STRINGIZE2(x) STRINGIZE(x)
#define OL_KITE_CI_DEPLOY_KEY @ STRINGIZE2(OL_KITE_CI_DEPLOY)
            [self showKiteVcForAPIKey:OL_KITE_CI_DEPLOY_KEY assets:assets];
        }]];
        [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Yes", @"") style:UIAlertActionStyleDefault handler:^(id action){
            [self showKiteVcForAPIKey:pasteboard.string assets:assets];
        }]];
        [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Yes and use staging", @"") style:UIAlertActionStyleDefault handler:^(id action){
            [OLKitePrintSDK setUseStaging:YES];
            [self showKiteVcForAPIKey:pasteboard.string assets:assets];
        }]];
        [self presentViewController:ac animated:YES completion:NULL];
    }
    else{
#define STRINGIZE(x) #x
#define STRINGIZE2(x) STRINGIZE(x)
#define OL_KITE_CI_DEPLOY_KEY @ STRINGIZE2(OL_KITE_CI_DEPLOY)
        [self showKiteVcForAPIKey:OL_KITE_CI_DEPLOY_KEY assets:assets];
    }
}

- (void)showKiteVcForAPIKey:(NSString *)s assets:(NSArray *)assets{
    [OLKitePrintSDK setAPIKey:s withEnvironment:[self environment]];
    
    [OLKitePrintSDK setApplePayMerchantID:kApplePayMerchantIDKey];
    [OLKitePrintSDK setApplePayPayToString:kApplePayBusinessName];
    
    OLKiteViewController *vc = [[OLKiteViewController alloc] initWithAssets:assets];
    vc.userEmail = @"";
    vc.userPhone = @"";
    vc.delegate = self;
    vc.qrCodeUploadEnabled = YES;
    
    [self addCatsAndDogsImagePickersToKite:vc];
    
    [vc addCustomPhotoProviderWithViewController:[[CustomImagePickerViewController alloc] init] name:@"Custom" icon:[UIImage imageNamed:@"cat"]];
    
    [self presentViewController:vc animated:YES completion:NULL];
}

- (void)didCancelPrintFlow:(UIViewController *)printViewController{
    [printViewController dismissViewControllerAnimated:YES completion:NULL];
}
- (void)didFinishPrintFlow:(UIViewController *)printViewController{
    [printViewController dismissViewControllerAnimated:YES completion:NULL];
}

@end
