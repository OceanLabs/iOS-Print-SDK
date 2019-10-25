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
 * For Internal Kite.ly use ONLY
 **********************************************************************/
static NSString *const kAPIKeySandbox = @"REPLACE_WITH_YOUR_API_KEY"; // replace with your Sandbox API key found under the Profile section in the developer portal
static NSString *const kAPIKeyLive = @"REPLACE_WITH_YOUR_API_KEY"; // replace with your Live API key found under the Profile section in the developer portal

static NSString *const kApplePayMerchantIDKey = @"merchant.ly.kite.sdk"; // Replace with your merchant ID
static NSString *const kApplePayBusinessName = @"Kite.ly"; //Replace with your business name

static NSString *const kURLScheme = @"kitely";

#import "CI-ViewController.h"
#import "OLKitePrintSDK.h"
#import "OLImageCachingManager.h"
#import "OLUserSession.h"
#import "OLImagePickerViewController.h"
#import "OLImageDownloader.h"
#import "KITAssetsPickerController.h"
#import "CustomAssetCollectionDataSource.h"
#import "AssetDataSource.h"
#import "OLKiteUtils.h"
#import "AppDelegate.h"
#import "OLAnalytics.h"

@import Photos;

@interface CIViewController () <UINavigationControllerDelegate, OLKiteDelegate, OLImagePickerViewControllerDelegate, KITAssetsPickerControllerDelegate, OLAnalyticsDelegate>
@property (nonatomic, weak) IBOutlet UISegmentedControl *environmentPicker;
@property (strong, nonatomic) NSArray *customDataSources;
@end

@interface OLKitePrintSDK (Private)
+ (void)setUseStaging:(BOOL)staging;
@end

@implementation CIViewController

- (void)viewDidAppear:(BOOL)animated{
    if ([(AppDelegate *)[UIApplication sharedApplication].delegate setupProperties]){
        [self showKiteVcForAPIKey:nil assets:nil];
    }
}

- (void)viewWillDisappear:(BOOL)animated{
    [(AppDelegate *)[UIApplication sharedApplication].delegate setSetupProperties:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [OLKitePrintSDK setApplePayMerchantID:kApplePayMerchantIDKey];
    [OLKitePrintSDK setApplePayPayToString:kApplePayBusinessName];
    [OLKitePrintSDK setURLScheme:kURLScheme];
    
    [OLAnalytics sharedInstance].delegate = self;
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
    NSArray *assets = @[[OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/1.jpg"] size:CGSizeMake(1824,1216)],
                        [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/2.jpg"] size: CGSizeMake(612, 612)],
                        [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/3.jpg"] size: CGSizeMake(843, 960)],
                        [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/4.jpg"] size: CGSizeMake(1034, 1034)],
                        ];
    
    [self printWithAssets:assets];
}

- (IBAction)onButtonExtraTapped:(UIButton *)sender {
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"Extras" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [ac addAction:[UIAlertAction actionWithTitle:@"Clear Web Image Cache" style:UIAlertActionStyleDefault handler:^(id action){
        [[NSURLCache sharedURLCache] removeAllCachedResponses];
    }]];
    [ac addAction:[UIAlertAction actionWithTitle:@"Checkout iPhone 6 case" style:UIAlertActionStyleDefault handler:^(id action){
        id<OLPrintJob> printJob = [OLPrintJob printJobWithTemplateId:@"i6_case" OLAssets:@[[OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/1.jpg"] size:CGSizeMake(1824,1216)]]];
#define STRINGIZE(x) #x
#define STRINGIZE2(x) STRINGIZE(x)
#define OL_KITE_CI_DEPLOY_KEY @ STRINGIZE2(OL_KITE_CI_DEPLOY)
        [OLKitePrintSDK setAPIKey:OL_KITE_CI_DEPLOY_KEY withEnvironment:[self environment]];
        
        [OLKitePrintSDK setApplePayMerchantID:kApplePayMerchantIDKey];
        [OLKitePrintSDK setApplePayPayToString:kApplePayBusinessName];
        
        UIViewController *vc = [OLKitePrintSDK checkoutViewControllerWithPrintJobs:@[printJob]];
        [self presentViewController:vc animated:YES completion:NULL];
    }]];
    [ac addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:NULL]];
    ac.popoverPresentationController.sourceRect = sender.frame;
    ac.popoverPresentationController.sourceView = self.view;
    
    [self presentViewController:ac animated:YES completion:NULL];
}


- (void)addCatsAndDogsImagePickersToKite:(OLKiteViewController *)kvc{
    OLImagePickerProviderCollection *dogsCollection = [[OLImagePickerProviderCollection alloc] initWithArray:@[[OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/5.jpg"] size: CGSizeMake(2048, 1362)], [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/6.jpg"] size: CGSizeMake(2048, 1152)], [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/7.jpg"] size: CGSizeMake(1600, 1144)], [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/8.jpg"] size: CGSizeMake(1882, 2509)], [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/14.jpg"] size: CGSizeMake(2359, 2268)], [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/17.jpg"] size: CGSizeMake(5616, 3744)], [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/20.jpg"] size: CGSizeMake(2345, 1465)]] name:@"Dogs"];
    OLImagePickerProviderCollection *catsCollection = [[OLImagePickerProviderCollection alloc] initWithArray:@[[OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/1.jpg"] size:CGSizeMake(1824,1216)], [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/2.jpg"] size:CGSizeMake(612, 612)], [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/3.jpg"] size:CGSizeMake(843, 960)], [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/4.jpg"] size:CGSizeMake(1034, 1034)], [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/9.jpg"] size:CGSizeMake(3264, 2448)], [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/10.jpg"] size:CGSizeMake(3456, 2592)], [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/16.jpg"] size:CGSizeMake(3456, 2592)]] name:@"Cats"];
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
        [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Yes, in staging", @"") style:UIAlertActionStyleDefault handler:^(id action){
            [OLKitePrintSDK setUseStaging:YES];
            [self showKiteVcForAPIKey:pasteboard.string assets:assets];
        }]];
        [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Yes, with single external picker", @"") style:UIAlertActionStyleDefault handler:^(id action){
            [OLKitePrintSDK setAPIKey:pasteboard.string withEnvironment:[self environment]];
            
            [OLKitePrintSDK setApplePayMerchantID:kApplePayMerchantIDKey];
            [OLKitePrintSDK setApplePayPayToString:kApplePayBusinessName];
            
            KITAssetsPickerController *customVc = [[KITAssetsPickerController alloc] init];
            self.customDataSources = @[[[CustomAssetCollectionDataSource alloc] init]];
            customVc.collectionDataSources = self.customDataSources;
            customVc.delegate = self;
            
            [self presentViewController:customVc animated:YES completion:NULL];
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

- (void)kiteControllerDidFinish:(OLKiteViewController *)controller{
    [controller dismissViewControllerAnimated:YES completion:NULL];
}

- (void)showKiteVcForAPIKey:(NSString *)s assets:(NSArray *)assets{
    [OLKitePrintSDK setAPIKey:s withEnvironment:[self environment]];
        
    [OLKitePrintSDK setApplePayMerchantID:kApplePayMerchantIDKey];
    [OLKitePrintSDK setApplePayPayToString:kApplePayBusinessName];
    
    OLKiteViewController *vc = [[OLKiteViewController alloc] initWithAssets:assets];
    vc.delegate = self;
//    vc.filterProducts = @[@""];
    
    if ([(AppDelegate *)[UIApplication sharedApplication].delegate setupProperties][@"filter"]){
        vc.filterProducts = @[[(AppDelegate *)[UIApplication sharedApplication].delegate setupProperties][@"filter"]];
    }
    
    [self addCatsAndDogsImagePickersToKite:vc];
    
    [vc addCustomPhotoProviderWithViewController:nil name:@"External" icon:[UIImage imageNamed:@"cat"] prepopulatedAssets:assets];
    
    vc.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:vc animated:YES completion:NULL];
}

- (void)assetsPickerController:(id)ipvc didFinishPickingAssets:(NSMutableArray *)assets{
    OLKiteViewController *vc = [[OLKiteViewController alloc] initWithAssets:assets];
    vc.delegate = self;
    vc.disableFacebook = YES;
    vc.disableRecents = YES;
    vc.disableCameraRoll = YES;
    
    [vc addCustomPhotoProviderWithViewController:nil name:@"External" icon:[UIImage imageNamed:@"cat"] prepopulatedAssets:assets];
    
    [ipvc dismissViewControllerAnimated:YES completion:^{
        [self presentViewController:vc animated:YES completion:NULL];
    }];
}

- (UIViewController<OLCustomPickerController> *_Nonnull)imagePickerViewControllerForName:(NSString *_Nonnull)name{
    KITAssetsPickerController *customVc = [[KITAssetsPickerController alloc] init];
    self.customDataSources = @[[[CustomAssetCollectionDataSource alloc] init]];
    customVc.collectionDataSources = self.customDataSources;
    
    return (UIViewController<OLCustomPickerController> *)customVc;
}

@end
