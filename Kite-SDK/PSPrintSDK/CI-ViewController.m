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

#import "CI-ViewController.h"
#import "OLKitePrintSDK.h"
#import "OLImageCachingManager.h"
#import "OLUserSession.h"
#import "OLImagePickerViewController.h"
#import "OLImageDownloader.h"
#import "OLProgressHUD.h"
#import "KITAssetsPickerController.h"
#import "CustomAssetCollectionDataSource.h"
#import "AssetDataSource.h"
#import "OLKiteTestHelper.h"
#import "OLKiteUtils.h"
#import "JDStatusBarNotification/JDStatusBarNotification.h"
#import "AppDelegate.h"

@import Photos;

@interface CIViewController () <UINavigationControllerDelegate, OLKiteDelegate, OLImagePickerViewControllerDelegate, OLPromoViewDelegate, KITAssetsPickerControllerDelegate>
@property (nonatomic, weak) IBOutlet UISegmentedControl *environmentPicker;
@property (nonatomic, strong) OLPrintOrder* printOrder;
@property (strong, nonatomic) OLKiteViewController *kiteViewController;
@property (strong, nonatomic) NSArray *customDataSources;
@end

@interface OLKitePrintSDK (Private)
+ (void)setUseStaging:(BOOL)staging;
@end

@implementation CIViewController

-(void)viewDidAppear:(BOOL)animated{
    self.printOrder = [[OLPrintOrder alloc] init];
    
    if ([(AppDelegate *)[UIApplication sharedApplication].delegate setupProperties]){
        [self showKiteVcForAPIKey:nil assets:nil];
    }
}

- (void)viewWillDisappear:(BOOL)animated{
    [(AppDelegate *)[UIApplication sharedApplication].delegate setSetupProperties:nil];
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
    NSArray *assets = @[[OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/1.jpg"]],
                        [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/2.jpg"]],
                        [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/3.jpg"]],
                        [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/4.jpg"]]];
    
    [self printWithAssets:assets];
}

- (IBAction)onButtonExtraTapped:(UIButton *)sender {
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"Extras" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [ac addAction:[UIAlertAction actionWithTitle:@"Print Order History" style:UIAlertActionStyleDefault handler:^(id action){
        [self presentViewController:[OLKiteViewController orderHistoryViewController] animated:YES completion:NULL];
    }]];
    [ac addAction:[UIAlertAction actionWithTitle:@"PDF Photobook" style:UIAlertActionStyleDefault handler:^(id action){
        [OLProgressHUD showWithStatus:@"Downloading PDF 1/2"];
        [[OLImageDownloader sharedInstance] downloadDataAtURL:[NSURL URLWithString:@"https://s3.amazonaws.com/sdk-static/TestImages/inside.pdf"] priority:0 progress:^(NSInteger progress, NSInteger total){
            dispatch_async(dispatch_get_main_queue(), ^{
                [OLProgressHUD showProgress:(float)progress/(float)total status:@"Downloading PDF 1/2"];
            });
        }withCompletionHandler:^(NSData *data, NSError *error){
            OLAsset *inside = [OLAsset assetWithDataAsPDF:data];
            [[OLImageDownloader sharedInstance] downloadDataAtURL:[NSURL URLWithString:@"https://s3.amazonaws.com/sdk-static/TestImages/cover.pdf"] priority:0 progress:^(NSInteger progress, NSInteger total){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [OLProgressHUD showProgress:(float)progress/(float)total status:@"Downloading PDF 2/2"];
                });
            } withCompletionHandler:^(NSData *data, NSError *error){
                OLAsset *cover = [OLAsset assetWithDataAsPDF:data];
                
                id<OLPrintJob> job = [OLPrintJob photobookWithTemplateId:@"rpi_wrap_280x210_sm" OLAssets:@[inside] frontCoverOLAsset:cover backCoverOLAsset:nil];
                OLPrintOrder *printOrder = [[OLPrintOrder alloc] init];
                [printOrder addPrintJob:job];
                
                OLKiteViewController *vc = [[OLKiteViewController alloc] initWithPrintOrder:printOrder];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [OLProgressHUD dismiss];
                    [self presentViewController:vc animated:YES completion:NULL];
                });
            }];
        }];
    }]];
    [ac addAction:[UIAlertAction actionWithTitle:@"Show Promo View" style:UIAlertActionStyleDefault handler:^(id action){
#define STRINGIZE(x) #x
#define STRINGIZE2(x) STRINGIZE(x)
#define OL_KITE_CI_DEPLOY_KEY @ STRINGIZE2(OL_KITE_CI_DEPLOY)
        [OLKitePrintSDK setAPIKey:OL_KITE_CI_DEPLOY_KEY withEnvironment:OLKitePrintSDKEnvironmentSandbox];
        [OLKitePrintSDK setApplePayMerchantID:kApplePayMerchantIDKey];
        self.kiteViewController = [[OLKiteViewController alloc] initWithAssets:@[] info:@{@"Entry Point" : @"OLPromoView"}];
        [self.kiteViewController startLoadingWithCompletionHandler:^{}];
        
        UIView *containerView = [[UIView alloc] init];
        containerView.tag = 1000;
        containerView.backgroundColor = [UIColor clearColor];
        [self.view addSubview:containerView];
        containerView.translatesAutoresizingMaskIntoConstraints = NO;
        NSDictionary *views = NSDictionaryOfVariableBindings(containerView);
        NSMutableArray *con = [[NSMutableArray alloc] init];
        
        float height = 200;
        
        NSArray *visuals = @[@"H:|-0-[containerView]-0-|",
                             [NSString stringWithFormat:@"V:[containerView(%f)]-0-|", height]];
        
        
        for (NSString *visual in visuals) {
            [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
        }
        
        [containerView.superview addConstraints:con];
        
        UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] init];
        activity.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
        [activity startAnimating];
        [containerView addSubview:activity];
        activity.translatesAutoresizingMaskIntoConstraints = NO;
        [activity.superview addConstraint:[NSLayoutConstraint constraintWithItem:activity attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:activity.superview attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
        [activity.superview addConstraint:[NSLayoutConstraint constraintWithItem:activity attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:activity.superview attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
        
        NSArray *assets = @[[OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/1.jpg"]],
                            [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/2.jpg"]]];
        
        [OLPromoView requestPromoViewWithAssets:assets templates:@[@"i6s_case", @"i5_case"] completionHandler:^(OLPromoView *view, NSError *error){
            view.delegate = self;
            [activity stopAnimating];
            if (error){
                UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"Oops" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
                [ac addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:NULL]];
                [self presentViewController:ac animated:YES completion:NULL];
                return;
            }
            
            [containerView addSubview:view];
            view.translatesAutoresizingMaskIntoConstraints = NO;
            NSDictionary *views = NSDictionaryOfVariableBindings(view);
            NSMutableArray *con = [[NSMutableArray alloc] init];
            
            NSArray *visuals = @[@"H:|-0-[view]-0-|",
                                 @"V:|-0-[view]-0-|"];
            
            
            for (NSString *visual in visuals) {
                [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
            }
            
            [view.superview addConstraints:con];

        }];

    }]];
    [ac addAction:[UIAlertAction actionWithTitle:@"Clear Web Image Cache" style:UIAlertActionStyleDefault handler:^(id action){
        [[NSURLCache sharedURLCache] removeAllCachedResponses];
    }]];
    [ac addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:NULL]];
    ac.popoverPresentationController.sourceRect = sender.frame;
    ac.popoverPresentationController.sourceView = self.view;
    
    [self presentViewController:ac animated:YES completion:NULL];
}


- (void)addCatsAndDogsImagePickersToKite:(OLKiteViewController *)kvc{
    OLImagePickerProviderCollection *dogsCollection = [[OLImagePickerProviderCollection alloc] initWithArray:@[[OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/5.jpg"]], [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/6.jpg"]], [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/7.jpg"]], [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/8.jpg"]]] name:@"Dogs"];
    OLImagePickerProviderCollection *catsCollection = [[OLImagePickerProviderCollection alloc] initWithArray:@[[OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/1.jpg"]], [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/2.jpg"]], [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/3.jpg"]], [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/4.jpg"]], [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/9.jpg"]], [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/10.jpg"]]] name:@"Cats"];
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
    
    NSString *status = info[kOLAnalyticsEventName];
    if ([info[kOLAnalyticsEventLevel] integerValue] != 1){
        status = [@"*" stringByAppendingString:status];
    }
    [JDStatusBarNotification showWithStatus:status dismissAfter:2];
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
        [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Yes and use staging", @"") style:UIAlertActionStyleDefault handler:^(id action){
            [OLKitePrintSDK setUseStaging:YES];
            [self showKiteVcForAPIKey:pasteboard.string assets:assets];
        }]];
        [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Yes and LC mode", @"") style:UIAlertActionStyleDefault handler:^(id action){
            [OLKitePrintSDK setAPIKey:pasteboard.string withEnvironment:[self environment]];
            
            [OLKitePrintSDK setApplePayMerchantID:kApplePayMerchantIDKey];
            [OLKitePrintSDK setApplePayPayToString:kApplePayBusinessName];
            
            KITAssetsPickerController *customVc = [[KITAssetsPickerController alloc] init];
            self.customDataSources = @[[[CustomAssetCollectionDataSource alloc] init]];
            customVc.collectionDataSources = self.customDataSources;
            customVc.delegate = self;
            
            [self presentViewController:customVc animated:YES completion:NULL];
        }]];
        [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Yes but mock templates", @"") style:UIAlertActionStyleDefault handler:^(id action){
            [OLKiteTestHelper mockTemplateRequest];
            
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

- (void)promoViewDidFinish:(OLPromoView *)promoView{
    [[self.view viewWithTag:1000] removeFromSuperview];
}

- (void)promoView:(OLPromoView *)promoView didSelectTemplateId:(NSString *)templateId withAsset:(OLAsset *)asset{
    [self.kiteViewController setAssets:@[asset]];
    self.kiteViewController.filterProducts = @[templateId];
    self.kiteViewController.delegate = self;
    
    [self presentViewController:self.kiteViewController animated:YES completion:NULL];
}

- (void)kiteControllerDidFinish:(OLKiteViewController *)controller{
    if (self.kiteViewController){
        self.kiteViewController = [[OLKiteViewController alloc] initWithAssets:@[] info:@{@"Entry Point" : @"OLPromoView"}];
        [self.kiteViewController startLoadingWithCompletionHandler:^{}];
    }
    
    [controller dismissViewControllerAnimated:YES completion:NULL];
}

- (void)showKiteVcForAPIKey:(NSString *)s assets:(NSArray *)assets{
    if ([(AppDelegate *)[UIApplication sharedApplication].delegate setupProperties][@"api_key"]){
        s = [(AppDelegate *)[UIApplication sharedApplication].delegate setupProperties][@"api_key"];
    }
    [OLKitePrintSDK setAPIKey:s withEnvironment:[self environment]];
    
    [OLKitePrintSDK setApplePayMerchantID:kApplePayMerchantIDKey];
    [OLKitePrintSDK setApplePayPayToString:kApplePayBusinessName];
    
    OLKiteViewController *vc = [[OLKiteViewController alloc] initWithAssets:assets];
    vc.userEmail = @"";
    vc.userPhone = @"";
    vc.delegate = self;
    vc.qrCodeUploadEnabled = YES;
    
    if ([(AppDelegate *)[UIApplication sharedApplication].delegate setupProperties][@"filter"]){
        vc.filterProducts = @[[(AppDelegate *)[UIApplication sharedApplication].delegate setupProperties][@"filter"]];
    }
    
    [self addCatsAndDogsImagePickersToKite:vc];
    
    KITAssetsPickerController *customVc = [[KITAssetsPickerController alloc] init];
    self.customDataSources = @[[[CustomAssetCollectionDataSource alloc] init]];
    customVc.collectionDataSources = self.customDataSources;
    
    [vc addCustomPhotoProviderWithViewController:(UIViewController<OLCustomPickerController> *)customVc name:@"External" icon:[UIImage imageNamed:@"cat"] prepopulatedAssets:assets];
    
    [self presentViewController:vc animated:YES completion:NULL];
}

- (void)assetsPickerController:(id)ipvc didFinishPickingAssets:(NSMutableArray *)assets{
    OLKiteViewController *vc = [[OLKiteViewController alloc] initWithAssets:assets];
    vc.userEmail = @"";
    vc.userPhone = @"";
    vc.delegate = self;
    vc.disableFacebook = YES;
    vc.disableRecents = YES;
    vc.disableCameraRoll = YES;
    [OLKitePrintSDK setInstagramEnabledWithClientID:@"" secret:@"" redirectURI:@""];
    
    KITAssetsPickerController *customVc = [[KITAssetsPickerController alloc] init];
    self.customDataSources = @[[[CustomAssetCollectionDataSource alloc] init]];
    customVc.collectionDataSources = self.customDataSources;
    
    [vc addCustomPhotoProviderWithViewController:(UIViewController<OLCustomPickerController> *)customVc name:@"External" icon:[UIImage imageNamed:@"cat"] prepopulatedAssets:assets];
    
    [ipvc dismissViewControllerAnimated:YES completion:^{
        [self presentViewController:vc animated:YES completion:NULL];
    }];
}

@end
