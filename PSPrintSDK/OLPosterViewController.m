//
//  OLPosterViewController.m
//  Photo Mosaic
//
//  Created by Konstadinos Karayannis on 27/10/14.
//  Copyright (c) 2014 Ocean Labs App Ltd. All rights reserved.
//

#import "OLPosterViewController.h"
#import "OLPrintPhoto.h"
#import <OLImageEditorViewController.h>
#import <OLInstagramImage.h>
#import <OLFacebookImage.h>
#import "OLProductPrintJob.h"
#import "OLCheckoutViewController.h"
#import "OLConstants.h"
#import "OLProductTemplate.h"

@interface OLPosterViewController () <OLImageEditorViewControllerDelegate, UINavigationControllerDelegate>

@property (strong, nonatomic) NSMutableArray *imageViews;
@property (strong, nonatomic) NSMutableArray *posterPhotos;
@property (strong, nonatomic) NSNumber *selectedImage;
@property (assign, nonatomic) BOOL hasShownHelp;
@property (weak, nonatomic) UIImageView *imageTapped;

@end

@implementation OLPosterViewController

-(NSArray *) userSelectedPhotos{
    if (!_userSelectedPhotos){
        NSMutableArray *mutableUserSelectedPhotos = [[NSMutableArray alloc] init];
        for (OLProductPrintJob *job in self.printOrder.jobs){
            for (id asset in job.assetsForUploading){
                OLPrintPhoto *printPhoto = [[OLPrintPhoto alloc] init];
                printPhoto.serverImageSize = [self.product serverImageSize];
                printPhoto.asset = asset;
                [mutableUserSelectedPhotos addObject:printPhoto];
            }
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
    [self.posterPhotos addObjectsFromArray:self.userSelectedPhotos];
    
    self.imageViews = [[NSMutableArray alloc] initWithCapacity:self.product.quantityToFulfillOrder];
    for (NSUInteger i = 0; i < self.product.quantityToFulfillOrder; i++){
        UIView *view = [self.view viewWithTag:i + 1];
        [self.imageViews addObject:view];
        
        if (self.posterPhotos.count < self.product.quantityToFulfillOrder){
            [self.posterPhotos addObject:self.posterPhotos[i % self.posterPhotos.count]];
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
            
            [((OLPrintPhoto*)[self.posterPhotos objectAtIndex:i]) setThumbImageIdealSizeForImageView:self.imageViews[i]];
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
    OLImageEditorViewController *imageEditor = [[OLImageEditorViewController alloc] init];
    OLPrintPhoto *photo = self.posterPhotos[[self.selectedImage integerValue] - 1];
    imageEditor.image = photo;
    imageEditor.delegate = self;
    imageEditor.hidesDeleteIcon = YES;
    
    // I don't know why this works, but it does. You need to times the image size by 2 in order to keep it accurate
    // with the preview, the crop box and the ultimate image file.
    // Elliott Minns - Wizard of the unknown. If you need to contact me, don't.
    CGSize photoSize = CGSizeMake([self.product serverImageSize].width / 2, [self.product serverImageSize].height / 2);
    
    [imageEditor setCropboxGuideImageToSize:photoSize];
    [self presentViewController:imageEditor animated:YES completion:nil];

}

-(void) doCheckout{
    NSUInteger instagramPhotoCount = 0, facebookPhotoCount = 0, iphonePhotoCount = 0;
    for (OLPrintPhoto *photo in self.posterPhotos) {
        if (photo.type == kPrintPhotoAssetTypeALAsset) ++iphonePhotoCount;
        if (photo.type == kPrintPhotoAssetTypeOLFacebookPhoto) ++facebookPhotoCount;
        if (photo.type == kPrintPhotoAssetTypeOLInstagramPhoto) ++instagramPhotoCount;
    }
    
    // Avoid uploading assets if possible. We can avoid uploading where the image already exists at a remote
    // URL and the user did not manipulate it in any way.
    NSMutableArray *photoAssets = [[NSMutableArray alloc] init];
    for (OLPrintPhoto *photo in self.posterPhotos) {
        if ((photo.type == kPrintPhotoAssetTypeOLFacebookPhoto || photo.type == kPrintPhotoAssetTypeOLInstagramPhoto)
            && CGAffineTransformIsIdentity(photo.transform)) {
            [photoAssets addObject:[OLAsset assetWithURL:[photo.asset fullURL]]];
        }
        else if(photo.type == kPrintPhotoAssetTypeOLAsset && CGAffineTransformIsIdentity(photo.transform)){
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
    printOrder.userData = @{@"photo_count_facebook": [NSNumber numberWithUnsignedInteger:facebookPhotoCount],
                            @"photo_count_instagram": [NSNumber numberWithUnsignedInteger:instagramPhotoCount],
                            @"photo_count_iphone": [NSNumber numberWithUnsignedInteger:iphonePhotoCount],
                            @"sdk_version": kOLKiteSDKVersion,
                            @"platform": @"iOS",
                            @"uid": [[[UIDevice currentDevice] identifierForVendor] UUIDString],
                            @"app_version": [NSString stringWithFormat:@"Version: %@ (%@)", appVersion, buildNumber]
                            };
    [printOrder addPrintJob:job];
    
    OLCheckoutViewController *vc = [[OLCheckoutViewController alloc] initWithPrintOrder:printOrder];
    [self.navigationController pushViewController:vc animated:YES];
    
}

#pragma mark - OLImageEditorViewControllerDelegate methods

- (void)imageEditorUserDidCancel:(OLImageEditorViewController *)imageEditorVC {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imageEditor:(OLImageEditorViewController *)editor userDidSuccessfullyCropImage:(id<OLImageEditorImage>)image {
    OLPrintPhoto *printPhoto = (OLPrintPhoto *) image;
    
    // Clear cache as we have new cropped image and reload all of the images.
    [printPhoto unloadImage];
    [self reloadImageViews];
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
