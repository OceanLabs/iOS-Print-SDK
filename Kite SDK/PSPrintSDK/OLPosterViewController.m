//
//  OLPosterViewController.m
//  Photo Mosaic
//
//  Created by Konstadinos Karayannis on 27/10/14.
//  Copyright (c) 2014 Ocean Labs App Ltd. All rights reserved.
//

#import "OLPosterViewController.h"
#import "OLPrintPhoto.h"
#import "OLProductPrintJob.h"
#import "OLCheckoutViewController.h"
#import "OLConstants.h"
#import "OLProductTemplate.h"
#import "OLScrollCropViewController.h"
#import <SDWebImageManager.h>
#import "OLAsset+Private.h"
#import "OLAnalytics.h"
#import "OLKitePrintSDK.h"

@interface OLKitePrintSDK (InternalUtils)
+ (NSString *)userEmail:(UIViewController *)topVC;
+ (NSString *)userPhone:(UIViewController *)topVC;
+ (id<OLKiteDelegate>)kiteDelegate:(UIViewController *)topVC;
@end

@interface OLPosterViewController () <UINavigationControllerDelegate, OLScrollCropViewControllerDelegate>

@property (strong, nonatomic) NSMutableArray *imageViews;
@property (strong, nonatomic) NSMutableArray *posterPhotos;
@property (strong, nonatomic) NSNumber *selectedImage;
@property (assign, nonatomic) BOOL hasShownHelp;
@property (weak, nonatomic) UIImageView *imageTapped;
@property (weak, nonatomic) OLPrintPhoto *editingPrintPhoto;

@end

@implementation OLPosterViewController

-(NSMutableArray *) userSelectedPhotos{
    if (!_userSelectedPhotos){
        NSMutableArray *mutableUserSelectedPhotos = [[NSMutableArray alloc] init];
        for (id asset in self.assets){
            OLPrintPhoto *printPhoto = [[OLPrintPhoto alloc] init];
            printPhoto.asset = asset;
            [mutableUserSelectedPhotos addObject:printPhoto];
        }
        _userSelectedPhotos = mutableUserSelectedPhotos;
    }
    return _userSelectedPhotos;
}

-(NSMutableArray *) posterPhotos{
    if (!_posterPhotos){
        _posterPhotos = [[NSMutableArray alloc] init];
    }
    return _posterPhotos;
}

-(void)viewDidLoad{
    [super viewDidLoad];
    
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackReviewScreenViewed:self.product.productTemplate.name];
#endif
    
    [self.posterPhotos addObjectsFromArray:self.userSelectedPhotos];
    
    self.imageViews = [[NSMutableArray alloc] initWithCapacity:self.product.quantityToFulfillOrder];
    for (NSUInteger i = 0; i < self.product.quantityToFulfillOrder; i++){
        UIView *view = [self.view viewWithTag:i + 1];
        if (view){
            [self.imageViews addObject:view];
        }
        
        if (self.posterPhotos.count < self.product.quantityToFulfillOrder){
            [self.posterPhotos addObject:self.userSelectedPhotos[i % self.userSelectedPhotos.count]];
        }
    }
        
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                   initWithTitle:@"Next"
                                   style:UIBarButtonItemStylePlain
                                   target:self
                                   action:@selector(onButtonNextClicked)];
    [self setTitle:NSLocalizedString(@"Tap to Crop", @"")];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.view layoutIfNeeded];
    [self reloadImageViews];
}

-(void)reloadImageViews {
    dispatch_async(dispatch_get_main_queue(), ^{
        for (NSUInteger i = 0; i < MIN([self.imageViews count], [self.posterPhotos count]); i++) {
            
            OLPrintPhoto *printPhoto = (OLPrintPhoto*)[self.posterPhotos objectAtIndex:i];
            [printPhoto setImageSize:[(UIView *)self.imageViews[i] frame].size forImageView:self.imageViews[i]];
        }
    });
}
- (IBAction)onGestureRecognizerTapped:(UITapGestureRecognizer *)sender {
    [self userDidTapOnImage:(UIImageView *)sender.view];
}

- (IBAction)userDidTapOnImage:(UIImageView *)imageView {
    self.selectedImage = [NSNumber numberWithInteger:imageView.tag];
    [self doCrop];
    return;
}

-(void)onButtonNextClicked{
    [self doCheckout];
}

-(void)doCrop{
    OLPrintPhoto *tempPrintPhoto = [[OLPrintPhoto alloc] init];
    tempPrintPhoto.asset = self.assets[0];
    self.editingPrintPhoto = self.userSelectedPhotos[0];
    
    UINavigationController *nav = [self.storyboard instantiateViewControllerWithIdentifier:@"CropViewNavigationController"];
    OLScrollCropViewController *cropVc = (id)nav.topViewController;
    cropVc.delegate = self;
    cropVc.aspectRatio = [(UIView *)self.imageViews[0] frame].size.height / [(UIView *)self.imageViews[0] frame].size.width;
    
    [tempPrintPhoto getImageWithProgress:NULL completion:^(UIImage *image){
        [cropVc setFullImage:image];
        [self presentViewController:nav animated:YES completion:NULL];
    }];
}

-(void) doCheckout{
    NSUInteger iphonePhotoCount = 0;
    for (OLPrintPhoto *photo in self.posterPhotos) {
        if (photo.type == kPrintPhotoAssetTypeALAsset) ++iphonePhotoCount;
    }
    
    // Avoid uploading assets if possible. We can avoid uploading where the image already exists at a remote
    // URL and the user did not manipulate it in any way.
    NSMutableArray *photoAssets = [[NSMutableArray alloc] init];
    for (OLPrintPhoto *photo in self.posterPhotos) {
        if(photo.type == kPrintPhotoAssetTypeOLAsset){
            [photoAssets addObject:photo.asset];
        }
        else {
            [photoAssets addObject:[OLAsset assetWithDataSource:photo]];
        }
    }
    
    
    OLProductPrintJob *job = [[OLProductPrintJob alloc] initWithTemplateId:self.product.templateId OLAssets:@[[photoAssets firstObject]]]; //Only adding the first photo since we only support buying one image at a time.
    OLPrintOrder *printOrder = [[OLPrintOrder alloc] init];
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString *appVersion = [infoDict objectForKey:@"CFBundleShortVersionString"];
    NSNumber *buildNumber = [infoDict objectForKey:@"CFBundleVersion"];
    printOrder.userData = @{@"photo_count_iphone": [NSNumber numberWithUnsignedInteger:iphonePhotoCount],
                            @"sdk_version": kOLKiteSDKVersion,
                            @"platform": @"iOS",
                            @"uid": [[[UIDevice currentDevice] identifierForVendor] UUIDString],
                            @"app_version": [NSString stringWithFormat:@"Version: %@ (%@)", appVersion, buildNumber]
                            };
    [printOrder addPrintJob:job];
    
    OLCheckoutViewController *vc = [[OLCheckoutViewController alloc] initWithPrintOrder:printOrder];
    vc.userEmail = [OLKitePrintSDK userEmail:self];
    vc.userPhone = [OLKitePrintSDK userPhone:self];
    vc.kiteDelegate = [OLKitePrintSDK kiteDelegate:self];
    
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - OLImageEditorViewControllerDelegate methods

-(void)userDidCropImage:(UIImage *)croppedImage{
    [self.editingPrintPhoto unloadImage];
    self.editingPrintPhoto.asset = [OLAsset assetWithImageAsJPEG:croppedImage];
    
    self.posterPhotos[0] = self.editingPrintPhoto;
    
    [self reloadImageViews];
    
}

#pragma mark - Autorotate and Orientation Methods
// Currently here to disable landscape orientations and rotation on iOS 7. When support is dropped, these can be deleted.

- (BOOL)shouldAutorotate {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8) {
        return YES;
    }
    else{
        return NO;
    }
}

- (NSUInteger)supportedInterfaceOrientations {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8) {
        return UIInterfaceOrientationMaskAll;
    }
    else{
        return UIInterfaceOrientationMaskPortrait;
    }
}

@end
