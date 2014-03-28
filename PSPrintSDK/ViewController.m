//
//  ViewController.m
//  PS SDK
//
//  Created by Deon Botha on 18/12/2013.
//  Copyright (c) 2013 Deon Botha. All rights reserved.
//

#import "ViewController.h"
#import "OLAddress.h"
#import "OLCountry.h"
#import "OLAssetUploadRequest.h"
#import "OLPrintJob.h"
#import "OLPrintOrder.h"
#import "OLAddressPickerController.h"
#import "OLCountryPickerController.h"
#import "OLPayPalCard.h"
#import "OLPSPrintSDK.h"
#import "OLAsset.h"
#import "OLURLDataSource.h"
#import "OLProductPrintJob.h"
#import "OLPostcardPrintJob.h"
#import "OLCheckoutViewController.h"
#import "OLProductTemplateSyncRequest.h"
#import "OLProductTemplate.h"
#import "ProductSelectionViewController.h"
#import "OLAddress.h"

/**********************************************************************
 * Insert your API keys here. These are found under your profile 
 * by logging in to the developer portal at http://developer.psilov.eu
 **********************************************************************/
static NSString *const kAPIKeySandbox = @"REPLACE_ME"; // replace with your Sandbox API key found under the Profile section in the developer portal
static NSString *const kAPIKeyLive = @"REPLACE_ME"; // replace with your Live API key found under the Profile section in the developer portal

@interface ViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, ProductSelectionViewControllerDelegate>
@property (nonatomic, weak) IBOutlet UISegmentedControl *environmentPicker;
@property (nonatomic, weak) IBOutlet UITextField *apiKeyTextField;
@property (nonatomic, weak) IBOutlet UIButton *productButton;
@property (nonatomic, assign) Product selectedProduct;
@end

@implementation ViewController

- (void)viewDidLoad {
    [OLPSPrintSDK setAPIKey:kAPIKeySandbox withEnvironment:kOLPSPrintSDKEnvironmentSandbox];
    
    [super viewDidLoad];
    self.selectedProduct = kProductSquares;
    [self.productButton setTitle:displayNameWithProduct(self.selectedProduct) forState:UIControlStateNormal];
    self.productButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.productButton.titleLabel.minimumScaleFactor = 0.5;
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (IBAction)onButtonPrintLocalPhotos:(id)sender {
    if (![self isAPIKeySet]) return;
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.delegate = self;
    [self presentViewController:imagePicker animated:YES completion:nil];
}

- (NSString *)apiKey {
    if ([self environment] == kOLPSPrintSDKEnvironmentSandbox) {
        return kAPIKeySandbox;
    } else {
        return kAPIKeyLive;
    }
}

- (BOOL)isAPIKeySet {
    if ([[self apiKey] isEqualToString:@"REPLACE_ME"]) {
        [[[UIAlertView alloc] initWithTitle:@"API Key Required" message:@"Set your API keys at the top of ViewController.m before you can print. This can be found under your profile at http://developer.psilov.eu" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        return NO;
    }
    
    return YES;
}

- (OLPSPrintSDKEnvironment)environment {
    if (self.environmentPicker.selectedSegmentIndex == 0) {
        return kOLPSPrintSDKEnvironmentSandbox;
    } else {
        return kOLPSPrintSDKEnvironmentLive;
    }
}

- (IBAction)onButtonSelectProductClicked:(id)sender {
    ProductSelectionViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"ProductSelectionViewController"];
    vc.selectedProduct = self.selectedProduct;
    vc.delegate = self;
    [self presentViewController:[[UINavigationController alloc] initWithRootViewController:vc] animated:YES completion:nil];
}

- (IBAction)onButtonPrintRemotePhotos:(id)sender {
    if (![self isAPIKeySet]) return;
    [[[UIAlertView alloc] initWithTitle:@"Remote URLS" message:@"Change hardcoded remote image URLs in ViewController.m onButtonPrintRemotePhotos:" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    NSArray *assets = @[[OLAsset assetWithURL:[NSURL URLWithString:@"http://psps.s3.amazonaws.com/sdk_static/1.jpg"]],
                        [OLAsset assetWithURL:[NSURL URLWithString:@"http://psps.s3.amazonaws.com/sdk_static/2.jpg"]],
                        [OLAsset assetWithURL:[NSURL URLWithString:@"http://psps.s3.amazonaws.com/sdk_static/3.jpg"]],
                        [OLAsset assetWithURL:[NSURL URLWithString:@"http://psps.s3.amazonaws.com/sdk_static/4.jpg"]]];
    [self printWithAssets:assets];
}

- (void)printWithAssets:(NSArray *)assets {
    if (![self isAPIKeySet]) return;
    
    OLPrintOrder *printOrder = [[OLPrintOrder alloc] init];
    if (self.selectedProduct == kProductPostcard) {
        [printOrder addPrintJob:[OLPrintJob postcardWithTemplateId:templateWithProduct(self.selectedProduct) frontImageOLAsset:[assets objectAtIndex:0] textOnPhotoImageOLAsset:nil message:@"Hello World" address:[OLAddress psTeamAddress] location:@[@"Ps HQ", @"London"]]];
    } else {
        [printOrder addPrintJob:[OLPrintJob printJobWithTemplateId:templateWithProduct(self.selectedProduct) OLAssets:assets]];
    }
    
    OLCheckoutViewController *vc = [[OLCheckoutViewController alloc] initWithPrintOrder:printOrder];
    [self.navigationController pushViewController:vc animated:YES];
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

#pragma mark - ProductSelectionViewControllerDelegate

- (void)productSelectionViewControllerUserDidSelectProduct:(Product)product {
    self.selectedProduct = product;
    [self.productButton setTitle:displayNameWithProduct(self.selectedProduct) forState:UIControlStateNormal];
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
