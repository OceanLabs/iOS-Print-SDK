//
//  ViewController.m
//  Kite SDK
//
//  Created by Deon Botha on 18/12/2013.
//  Copyright (c) 2013 Deon Botha. All rights reserved.
//

#import "ViewController.h"
#import "OLKitePrintSDK.h"
#import "OLAssetsPickerController.h"

#import <AssetsLibrary/AssetsLibrary.h>

/**********************************************************************
 * Insert your API keys here. These are found under your profile 
 * by logging in to the developer portal at https://www.kite.ly
 **********************************************************************/
static NSString *const kAPIKeySandbox = @"REPLACE_WITH_YOUR_API_KEY"; // replace with your Sandbox API key found under the Profile section in the developer portal
static NSString *const kAPIKeyLive = @"REPLACE_WITH_YOUR_API_KEY"; // replace with your Live API key found under the Profile section in the developer portal

static NSString *const kApplePayMerchantIDKey = @"merchant.ly.kite.sdk"; // For internal use only.

@interface ViewController () <OLAssetsPickerControllerDelegate, UINavigationControllerDelegate, OLKiteDelegate>
@property (weak, nonatomic) IBOutlet UIButton *localPhotosButton;
@property (weak, nonatomic) IBOutlet UIButton *remotePhotosButton;
@property (nonatomic, weak) IBOutlet UISegmentedControl *environmentPicker;
@property (nonatomic, strong) OLPrintOrder* printOrder;
@end

@implementation ViewController

-(void)viewDidAppear:(BOOL)animated{
    self.printOrder = [[OLPrintOrder alloc] init];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserSuppliedShippingDetails:) name:kOLNotificationUserSuppliedShippingDetails object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserCompletedPayment:) name:kOLNotificationUserCompletedPayment object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onPrintOrderSubmission:) name:kOLNotificationPrintOrderSubmission object:nil];
    
#ifdef OL_KITE_OFFER_INSTAGRAM
    [OLKitePrintSDK setInstagramEnabledWithClientID:@"a6a09c92a14d488baa471e5209906d3d" secret:@"bfb814274cd041a5b7e06f32608e0e87" redirectURI:@"kite://instagram-callback"];
#endif
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (IBAction)onButtonPrintLocalPhotos:(id)sender {
    if (![self isAPIKeySet]) return;
    OLAssetsPickerController *picker = [[OLAssetsPickerController alloc] init];
    picker.delegate = self;
    picker.assetsFilter = [ALAssetsFilter allPhotos];
    
    [self presentViewController:picker animated:YES completion:nil];
}

- (NSString *)apiKey {
    if ([self environment] == kOLKitePrintSDKEnvironmentSandbox) {
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
    if ([[self apiKey] isEqualToString:@"REPLACE_WITH_YOUR_API_KEY"]) {
        [[[UIAlertView alloc] initWithTitle:@"API Key Required" message:@"Set your API keys at the top of ViewController.m before you can print. This can be found under your profile at http://kite.ly" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        return NO;
    }
    
    return YES;
}

- (OLKitePrintSDKEnvironment)environment {
    if (self.environmentPicker.selectedSegmentIndex == 0) {
        return kOLKitePrintSDKEnvironmentSandbox;
    } else {
        return kOLKitePrintSDKEnvironmentLive;
    }
}

- (void)printWithAssets:(NSArray *)assets {
    if (![self isAPIKeySet]) return;

    [OLKitePrintSDK setAPIKey:[self apiKey] withEnvironment:[self environment]];
    
#ifdef OL_KITE_OFFER_APPLE_PAY
    [OLKitePrintSDK setApplePayMerchantID:kApplePayMerchantIDKey];
#endif
    
    OLKiteViewController *vc = [[OLKiteViewController alloc] initWithAssets:assets];
    vc.userEmail = @"";
    vc.userPhone = @"";
    vc.delegate = self;
    [self presentViewController:vc animated:YES completion:NULL];

}

- (IBAction)onButtonPrintRemotePhotos:(id)sender {
    if (![self isAPIKeySet]) return;
    [[[UIAlertView alloc] initWithTitle:@"Remote URLS" message:@"Feel free to Change hardcoded remote image URLs in ViewController.m onButtonPrintRemotePhotos:" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

#pragma mark - UIAlertViewDelegate methods
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSArray *assets = @[[OLAsset assetWithURL:[NSURL URLWithString:@"http://psps.s3.amazonaws.com/sdk_static/1.jpg"]],
                        [OLAsset assetWithURL:[NSURL URLWithString:@"http://psps.s3.amazonaws.com/sdk_static/2.jpg"]],
                        [OLAsset assetWithURL:[NSURL URLWithString:@"http://psps.s3.amazonaws.com/sdk_static/3.jpg"]],
                        [OLAsset assetWithURL:[NSURL URLWithString:@"http://psps.s3.amazonaws.com/sdk_static/4.jpg"]]];
    [self printWithAssets:assets];
}

#pragma mark - UIImagePickerControllerDelegate methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [self dismissViewControllerAnimated:YES completion:^(void) {
        UIImage *chosenImage = info[UIImagePickerControllerOriginalImage];
        [self printWithAssets:@[[OLAsset assetWithImageAsJPEG:chosenImage]]];
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - CTAssetsPickerControllerDelegate Methods

- (void)assetsPickerController:(OLAssetsPickerController *)picker didFinishPickingAssets:(NSArray *)assets {
    [picker dismissViewControllerAnimated:YES completion:^(void){
        NSMutableArray *assetObjects = [[NSMutableArray alloc] initWithCapacity:assets.count];
        for (ALAsset *asset in assets){
            [assetObjects addObject:[OLAsset assetWithALAsset:asset]];
        }
        [self printWithAssets:assetObjects];
    }];
    
}

- (BOOL)assetsPickerController:(OLAssetsPickerController *)picker shouldShowAssetsGroup:(ALAssetsGroup *)group{
    if (group.numberOfAssets == 0){
        return NO;
    }
    return YES;
}

- (BOOL)assetsPickerController:(OLAssetsPickerController *)picker shouldShowAsset:(ALAsset *)asset{
    NSString *fileName = [[[asset defaultRepresentation] filename] lowercaseString];
    if (!([fileName hasSuffix:@".jpg"] || [fileName hasSuffix:@".jpeg"] || [fileName hasSuffix:@"png"])) {
        return NO;
    }
    return YES;
}

#pragma mark - OLKiteDelete

- (BOOL)kiteController:(OLKiteViewController *)controller isDefaultAssetsGroup:(ALAssetsGroup *)group {
//    if ([[group valueForProperty:ALAssetsGroupPropertyName] isEqualToString:@"Instagram"]) {
//        return YES;
//    }
    return NO;
}

- (BOOL)kiteControllerShouldAllowUserToAddMorePhotos:(OLKiteViewController *)controller {
    return YES;
}

//- (BOOL)shouldShowPhoneEntryOnCheckoutScreen{
//    return YES;
//}

- (IBAction)onButtonKiteClicked:(UIButton *)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.kite.ly"]];
}
#pragma mark - notification events

// useful if you want to fire off Anlaytic events for conversion funnel analysis, etc.

- (void)onUserSuppliedShippingDetails:(NSNotification*)n {
    NSLog(@"onUserSuppliedShippingDetails for print order with shipping address: %@", [n.userInfo[kOLKeyUserInfoPrintOrder] shippingAddress] );
}

- (void)onUserCompletedPayment:(NSNotification*)n {
    NSLog(@"onUserCompletedPayment for print order with proof of payment: %@", [n.userInfo[kOLKeyUserInfoPrintOrder] proofOfPayment]);
}

- (void)onPrintOrderSubmission:(NSNotification*)n {
    NSLog(@"onPrintOrderSubmission for print order with order receipt: %@", [n.userInfo[kOLKeyUserInfoPrintOrder] receipt]);
    _printOrder = [[OLPrintOrder alloc] init];
}

@end
