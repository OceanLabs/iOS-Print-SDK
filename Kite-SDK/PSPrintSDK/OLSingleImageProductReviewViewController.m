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

#import "NSArray+QueryingExtras.h"
#import "NSObject+Utils.h"
#ifdef COCOAPODS
#import <SDWebImage/SDWebImageManager.h>
#else
#import "SDWebImageManager.h"
#endif

#import "OLSingleImageProductReviewViewController.h"
#import "OLPrintPhoto.h"
#import "OLAnalytics.h"
#import "OLAsset+Private.h"
#import "OLProductPrintJob.h"
#import "OLAsset+Private.h"
#import "OLAssetsPickerController.h"
#import "OLCustomPhotoProvider.h"
#import "OLImageCachingManager.h"
#import "OLKiteABTesting.h"
#import "OLKitePrintSDK.h"
#import "OLKiteUtils.h"
#ifdef OL_KITE_AT_LEAST_IOS8
#ifdef COCOAPODS
#import <CTAssetsPickerController/CTAssetsPickerController.h>
#else
#import "CTAssetsPickerController.h"
#endif
#endif
#import "NSArray+QueryingExtras.h"
#import "OLKiteViewController.h"
#import "OLPaymentViewController.h"
#import "OLPrintPhoto.h"
#import "OLProductPrintJob.h"
#import "OLProductTemplateOption.h"
#import "OLRemoteImageCropper.h"
#import "OLRemoteImageView.h"
#import "OLRemoteImageCropper.h"
#import "OLAsset+Private.h"
#import "OLProductTemplateOption.h"
#import "OLPaymentViewController.h"
#import "UIViewController+OLMethods.h"
#import "OLSingleImageProductReviewViewController.h"

#ifdef OL_KITE_OFFER_CUSTOM_IMAGE_PROVIDERS
#import "OLCustomPhotoProvider.h"
#import <KITAssetsPickerController.h>
#endif

#ifdef OL_KITE_OFFER_INSTAGRAM
#import <InstagramImagePicker/OLInstagramImagePickerController.h>
#import <InstagramImagePicker/OLInstagramImage.h>
#endif

#ifdef OL_KITE_OFFER_FACEBOOK
#import <FacebookImagePicker/OLFacebookImagePickerController.h>
#import <FacebookImagePicker/OLFacebookImage.h>
#endif

#import "OLImagePreviewViewController.h"

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

@interface OLPaymentViewController (Private)

-(void)saveAndDismissReviewController;

@end

@interface OLPrintOrder (Private)

- (void)saveOrder;

@end

@interface OLKiteViewController ()

@property (strong, nonatomic) OLPrintOrder *printOrder;
#ifdef OL_KITE_OFFER_CUSTOM_IMAGE_PROVIDERS
@property (strong, nonatomic) NSMutableArray <OLCustomPhotoProvider *> *customImageProviders;
#endif
- (void)dismiss;

@end

@interface OLKitePrintSDK (InternalUtils)
#ifdef OL_KITE_OFFER_INSTAGRAM
+ (NSString *) instagramRedirectURI;
+ (NSString *) instagramSecret;
+ (NSString *) instagramClientID;
#endif
@end

@interface OLSingleImageProductReviewViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UINavigationControllerDelegate, UIActionSheetDelegate, UIAlertViewDelegate, UIGestureRecognizerDelegate,
#ifdef OL_KITE_OFFER_INSTAGRAM
OLInstagramImagePickerControllerDelegate,
#endif
#ifdef OL_KITE_OFFER_FACEBOOK
OLFacebookImagePickerControllerDelegate,
#endif
#ifdef OL_KITE_AT_LEAST_IOS8
CTAssetsPickerControllerDelegate,
#endif
#ifdef OL_KITE_OFFER_CUSTOM_IMAGE_PROVIDERS
KITAssetsPickerControllerDelegate,
#endif
OLAssetsPickerControllerDelegate, RMImageCropperDelegate, UIViewControllerPreviewingDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *imagesCollectionView;

@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet OLRemoteImageCropper *imageCropView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *maskAspectRatio;
@property (strong, nonatomic) OLPrintPhoto *imagePicked;
@property (strong, nonatomic) OLPrintPhoto *imageDisplayed;
@property (strong, nonatomic) NSIndexPath *previewingIndexPath;
@property (nonatomic, copy) void (^saveJobCompletionHandler)();

@end

static BOOL hasMoved;

@implementation OLSingleImageProductReviewViewController

-(void)viewDidLoad{
    [super viewDidLoad];
    
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackReviewScreenViewed:self.product.productTemplate.name];
#endif
    
    if ([UITraitCollection class] && [self.traitCollection respondsToSelector:@selector(forceTouchCapability)] && self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable){
        [self registerForPreviewingWithDelegate:self sourceView:self.imagesCollectionView];
        [self registerForPreviewingWithDelegate:self sourceView:self.imageCropView];
    }
    
    if ([OLKiteABTesting sharedInstance].launchedWithPrintOrder){
        if ([[OLKiteABTesting sharedInstance].launchWithPrintOrderVariant isEqualToString:@"Review-Overview-Checkout"]){
            [self.ctaButton setTitle:NSLocalizedString(@"Next", @"") forState:UIControlStateNormal];
        }
        
        if(!self.editingPrintJob){
            OLKiteViewController *kiteVc = [OLKiteUtils kiteVcForViewController:self];
            self.editingPrintJob = [kiteVc.printOrder.jobs firstObject];
            self.product.uuid = self.editingPrintJob.uuid;
        }
    }
    
    if ([self.presentingViewController respondsToSelector:@selector(viewControllers)] || !self.presentingViewController) {
        UIViewController *paymentVc = [(UINavigationController *)self.presentingViewController viewControllers].lastObject;
        if ([paymentVc respondsToSelector:@selector(saveAndDismissReviewController)]){
            [self.ctaButton setTitle:NSLocalizedString(@"Save", @"") forState:UIControlStateNormal];
        	[self.ctaButton removeTarget:self action:@selector(onButtonNextClicked) forControlEvents:UIControlEventTouchUpInside];
        	[self.ctaButton addTarget:paymentVc action:@selector(saveAndDismissReviewController) forControlEvents:UIControlEventTouchUpInside];
        }
    }
    
    self.title = NSLocalizedString(@"Reposition the Photo", @"");
    
    if (self.imageCropView){
        self.imageCropView.delegate = self;
        OLPrintPhoto *photo = [self.userSelectedPhotos firstObject];
        self.imageDisplayed = photo;
        [photo getImageWithProgress:NULL completion:^(UIImage *image){
            if (self.imageDisplayed.edits.counterClockwiseRotations > 0 || self.imageDisplayed.edits.flipHorizontal || self.imageDisplayed.edits.flipVertical){
                self.imageCropView.image = [UIImage imageWithCGImage:image.CGImage scale:image.scale orientation:[OLPhotoEdits orientationForNumberOfCounterClockwiseRotations:self.imageDisplayed.edits.counterClockwiseRotations andInitialOrientation:image.imageOrientation horizontalFlip:self.imageDisplayed.edits.flipHorizontal verticalFlip:self.imageDisplayed.edits.flipVertical]];
            }
            else{
                [self.imageCropView setImage:image];
            }
            self.imageCropView.imageView.transform = self.imageDisplayed.edits.cropTransform;
        }];
    }
    
    for (OLPrintPhoto *printPhoto in self.userSelectedPhotos){
        [printPhoto unloadImage];
    }
    
    [self.imageCropView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapGestureRecognized)]];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", @"")
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:nil
                                                                            action:nil];
    
    self.imagesCollectionView.dataSource = self;
    self.imagesCollectionView.delegate = self;
    
    if (![OLKiteUtils imageProvidersAvailable:self] && self.userSelectedPhotos.count == 1){
        self.imagesCollectionView.hidden = YES;
    }
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    if ([OLKiteUtils imageProvidersAvailable:self] && self.userSelectedPhotos.count == 0 && [[[UIDevice currentDevice] systemVersion] floatValue] >= 8){
        [self collectionView:self.imagesCollectionView didSelectItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
    }
}

- (void)onTapGestureRecognized{
    [self enterFullCrop:YES];
}

- (void)enterFullCrop:(BOOL)animated{
    OLScrollCropViewController *cropVc = [self.storyboard instantiateViewControllerWithIdentifier:@"OLScrollCropViewController"];
    cropVc.enableCircleMask = self.product.productTemplate.templateUI == kOLTemplateUICircle;
    cropVc.delegate = self;
    cropVc.aspectRatio = self.imageCropView.frame.size.height / self.imageCropView.frame.size.width;
    
    if (!animated){
        cropVc.skipPresentAnimation = YES;
    }
    cropVc.previewView = [self.imageCropView snapshotViewAfterScreenUpdates:YES];
    cropVc.previewView.frame = [self.imageCropView.superview convertRect:self.imageCropView.frame toView:nil];
    cropVc.previewSourceView = self.imageCropView;
    
    cropVc.forceSourceViewDimensions = YES;
    cropVc.providesPresentationContextTransitionStyle = true;
    cropVc.definesPresentationContext = true;
    cropVc.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    
    [self.imageDisplayed getImageWithProgress:^(float progress){
        [cropVc.cropView setProgress:progress];
    }completion:^(UIImage *image){
        [cropVc setFullImage:image];
        OLPhotoEdits *edits = [self.imageDisplayed.edits copy];
        edits.cropImageFrame = [self.imageCropView getFrameRect];
        edits.cropImageRect = [self.imageCropView getImageRect];
        edits.cropImageSize = [self.imageCropView croppedImageSize];
        edits.cropTransform = self.imageCropView.imageView.transform;
        cropVc.edits = edits;
        //        cropVc.modalPresentationStyle = [OLKiteUtils kiteVcForViewController:self].modalPresentationStyle;
        [self presentViewController:cropVc animated:NO completion:NULL];
        
#ifndef OL_NO_ANALYTICS
        [OLAnalytics trackReviewScreenEnteredCropScreenForProductName:self.product.productTemplate.name];
#endif
    }];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    if ([self.presentingViewController respondsToSelector:@selector(viewControllers)]) {
        UIViewController *presentingVc = [(UINavigationController *)self.presentingViewController viewControllers].lastObject;
        if (![presentingVc isKindOfClass:[OLPaymentViewController class]]){
            [self addBasketIconToTopRight];
        }
    }
    else{
        [self addBasketIconToTopRight];
    }
    
    hasMoved = NO;
    self.imageCropView.imageView.transform = self.imageDisplayed.edits.cropTransform;
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    
#ifndef OL_NO_ANALYTICS
    if (!self.navigationController){
        [OLAnalytics trackReviewScreenHitBack:self.product.productTemplate.name numberOfPhotos:self.userSelectedPhotos.count];
    }
#endif
}

-(IBAction)onButtonNextClicked{
    [self doCheckout];
}

- (void)saveJobWithCompletionHandler:(void(^)())handler{
    
    self.imageDisplayed.edits.cropImageFrame = [self.imageCropView getFrameRect];
    self.imageDisplayed.edits.cropImageRect = [self.imageCropView getImageRect];
    self.imageDisplayed.edits.cropImageSize = [self.imageCropView croppedImageSize];
    self.imageDisplayed.edits.cropTransform = self.imageCropView.imageView.transform;
    
    OLSingleImageProductReviewViewController *this = self;
    OLAsset *asset = [OLAsset assetWithDataSource:[self.imageDisplayed copy]];
    [asset dataLengthWithCompletionHandler:^(long long dataLength, NSError *error){
        if (dataLength < 40000){
            if ([UIAlertController class]){
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Image Is Too Small", @"") message:NSLocalizedString(@"Please zoom out or pick a higher quality image", @"") preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"") style:UIAlertActionStyleDefault handler:NULL]];
                [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Print It Anyway", @"") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                    [self saveJobNowWithCompletionHandler:handler];
                }]];
                [self presentViewController:alert animated:YES completion:NULL];
            }
            else{
                self.saveJobCompletionHandler = handler;
                UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Image Too Small", @"") message:NSLocalizedString(@"Please zoom out or pick higher quality image", @"") delegate:this cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:@"Print it anyway", nil];
                av.tag = 100;
                [av show];
            }
            return;
            
        }
        
        [self saveJobNowWithCompletionHandler:handler];
    }];
}

- (void)saveJobNowWithCompletionHandler:(void(^)())handler {
    OLAsset *asset = [OLAsset assetWithDataSource:[self.imageDisplayed copy]];
    NSArray *assetArray = @[asset];
    
    NSUInteger iphonePhotoCount = 1;
    OLPrintOrder *printOrder = [OLKiteUtils kiteVcForViewController:self].printOrder;
    
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString *appVersion = [infoDict objectForKey:@"CFBundleShortVersionString"];
    NSNumber *buildNumber = [infoDict objectForKey:@"CFBundleVersion"];
    printOrder.userData = @{@"photo_count_iphone": [NSNumber numberWithUnsignedInteger:iphonePhotoCount],
                            @"sdk_version": kOLKiteSDKVersion,
                            @"platform": @"iOS",
                            @"uid": [OLAnalytics userDistinctId],
                            @"app_version": [NSString stringWithFormat:@"Version: %@ (%@)", appVersion, buildNumber]
                            };
    
    OLProductPrintJob *job = [[OLProductPrintJob alloc] initWithTemplateId:self.product.templateId OLAssets:assetArray];
    for (NSString *option in self.product.selectedOptions.allKeys){
        [job setValue:self.product.selectedOptions[option] forOption:option];
    }
    NSArray *jobs = [NSArray arrayWithArray:printOrder.jobs];
    for (id<OLPrintJob> existingJob in jobs){
        if ([existingJob.uuid isEqualToString:self.product.uuid]){
            if ([existingJob extraCopies] > 0){
                [existingJob setExtraCopies:[existingJob extraCopies]-1];
            }
            else{
                [printOrder removePrintJob:existingJob];
            }
            job.uuid = self.product.uuid;
        }
    }
    self.product.uuid = job.uuid;
    self.editingPrintJob = job;
    if ([printOrder.jobs containsObject:self.editingPrintJob]){
        id<OLPrintJob> existingJob = printOrder.jobs[[printOrder.jobs indexOfObject:self.editingPrintJob]];
        [existingJob setExtraCopies:[existingJob extraCopies]+1];
    }
    else{
        [printOrder addPrintJob:self.editingPrintJob];
    }
    
    [printOrder saveOrder];
    
    if (handler){
        handler();
    }
    
    self.saveJobCompletionHandler = nil;
}

-(void) doCheckout{
    if (!self.imageCropView.image) {
        return;
    }
    
    [self saveJobWithCompletionHandler:^{
        if ([OLKiteABTesting sharedInstance].launchedWithPrintOrder && [[OLKiteABTesting sharedInstance].launchWithPrintOrderVariant isEqualToString:@"Review-Overview-Checkout"]){
            UIViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"OLProductOverviewViewController"];
            [vc safePerformSelector:@selector(setUserEmail:) withObject:[(OLKiteViewController *)vc userEmail]];
            [vc safePerformSelector:@selector(setUserPhone:) withObject:[(OLKiteViewController *)vc userPhone]];
            [vc safePerformSelector:@selector(setKiteDelegate:) withObject:self.delegate];
            [vc safePerformSelector:@selector(setProduct:) withObject:self.product];
            [self.navigationController pushViewController:vc animated:YES];
        }
        else{
            OLPrintOrder *printOrder = [OLKiteUtils kiteVcForViewController:self].printOrder;
            [OLKiteUtils checkoutViewControllerForPrintOrder:printOrder handler:^(id vc){
                [vc safePerformSelector:@selector(setUserEmail:) withObject:[OLKiteUtils userEmail:self]];
                [vc safePerformSelector:@selector(setUserPhone:) withObject:[OLKiteUtils userPhone:self]];
                [vc safePerformSelector:@selector(setKiteDelegate:) withObject:[OLKiteUtils kiteDelegate:self]];
                
                [self.navigationController pushViewController:vc animated:YES];
            }];
        }
    }];
}

- (void)imageCropperDidTransformImage:(RMImageCropper *)imageCropper{
#ifndef OL_NO_ANALYTICS
    if (!hasMoved){
        hasMoved = YES;
        [OLAnalytics trackReviewScreenDidCropPhotoForProductName:self.product.productTemplate.name];
    }
#endif
}

- (UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location{
    if (previewingContext.sourceView == self.imagesCollectionView){
        NSIndexPath *indexPath = [self.imagesCollectionView indexPathForItemAtPoint:location];
        UICollectionViewCell *cell = [self.imagesCollectionView cellForItemAtIndexPath:indexPath];
        
        OLRemoteImageView *imageView = (OLRemoteImageView *)[cell viewWithTag:11];
        if (!imageView.image){
            return nil;
        }
        
        self.previewingIndexPath = indexPath;
        
        UIImageView *cellImageView = [cell viewWithTag:1];
        
        [previewingContext setSourceRect:[cell convertRect:cellImageView.frame toView:self.imagesCollectionView]];
        
        OLImagePreviewViewController *previewVc = [self.storyboard instantiateViewControllerWithIdentifier:@"OLImagePreviewViewController"];
        [self.userSelectedPhotos[indexPath.item] getImageWithProgress:NULL completion:^(UIImage *image){
            previewVc.image = image;
        }];
        previewVc.providesPresentationContextTransitionStyle = true;
        previewVc.definesPresentationContext = true;
        previewVc.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        return previewVc;
    }
    else if (previewingContext.sourceView == self.imageCropView){
        OLImagePreviewViewController *previewVc = [self.storyboard instantiateViewControllerWithIdentifier:@"OLImagePreviewViewController"];
        [self.imageDisplayed getImageWithProgress:NULL completion:^(UIImage *image){
            previewVc.image = image;
        }];
        previewVc.providesPresentationContextTransitionStyle = true;
        previewVc.definesPresentationContext = true;
        previewVc.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        return previewVc;
    }
    else{
        return nil;
    }
}

- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit{
    if (previewingContext.sourceView == self.imagesCollectionView){
        [self collectionView:self.imagesCollectionView didSelectItemAtIndexPath:self.previewingIndexPath];
    }
    else if (previewingContext.sourceView == self.imageCropView){
        [self enterFullCrop:NO];
    }
}

#pragma mark CollectionView delegate and data source

- (NSInteger) sectionForMoreCell{
    return 0;
}

- (NSInteger) sectionForImageCells{
    return [OLKiteUtils imageProvidersAvailable:self] ? 1 : 0;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    if (section == [self sectionForImageCells]){
        return self.userSelectedPhotos.count;
    }
    else if (section == [self sectionForMoreCell]){
        return 1;
    }
    else{
        return 0;
    }
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    if ([OLKiteUtils imageProvidersAvailable:self]){
        return 2;
    }
    else{
        return 1;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == [self sectionForImageCells]){
        UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"imageCell" forIndexPath:indexPath];
        
        for (UIView *view in cell.subviews){
            if ([view isKindOfClass:[OLRemoteImageView class]]){
                [view removeFromSuperview];
            }
        }
        
        OLRemoteImageView *imageView = [[OLRemoteImageView alloc] initWithFrame:CGRectMake(0, 0, 138, 138)];
        imageView.tag = 11;
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        [cell addSubview:imageView];
        imageView.translatesAutoresizingMaskIntoConstraints = NO;
        NSDictionary *views = NSDictionaryOfVariableBindings(imageView);
        NSMutableArray *con = [[NSMutableArray alloc] init];
        
        NSArray *visuals = @[@"H:|-0-[imageView]-0-|",
                             @"V:|-0-[imageView]-0-|"];
        
        
        for (NSString *visual in visuals) {
            [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
        }
        
        [imageView.superview addConstraints:con];
        
        
        [self.userSelectedPhotos[indexPath.item] setImageSize:imageView.frame.size cropped:NO progress:^(float progress){
            [imageView setProgress:progress];
        }completionHandler:^(UIImage *image){
            dispatch_async(dispatch_get_main_queue(), ^{
                imageView.image = image;
            });
        }];
        
        return cell;
    }
    
    else {
        UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"moreCell" forIndexPath:indexPath];
        return cell;
    }
    
    
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    return CGSizeMake(collectionView.frame.size.height, collectionView.frame.size.height);
}

- (CGFloat) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section{
    return 0;
}

- (CGFloat) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section{
    return 0;
}

- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    
    BOOL customProviders = NO;
    NSInteger numberOfProviders = 0;
#ifdef OL_KITE_OFFER_CUSTOM_IMAGE_PROVIDERS
    NSInteger numberOfCustomProviders = [OLKiteUtils kiteVcForViewController:self].customImageProviders.count;
    customProviders = numberOfCustomProviders > 0;
    numberOfProviders += numberOfCustomProviders;
#endif
    
    if ([OLKiteUtils cameraRollEnabled:self]){
        numberOfProviders++;
    }
    if ([OLKiteUtils facebookEnabled]){
        numberOfProviders++;
    }
    if ([OLKiteUtils instagramEnabled]){
        numberOfProviders++;
    }
    
    BOOL qrCodeUploadEnabled = YES;
    if (qrCodeUploadEnabled) {
        numberOfProviders++;
    }
    
    if (indexPath.section == [self sectionForImageCells]){
        OLRemoteImageView *imageView = (OLRemoteImageView *)[cell viewWithTag:11];
        if (!imageView.image){
            return;
        }
        
        self.imageDisplayed = self.userSelectedPhotos[indexPath.item];
        
        self.imageCropView.image = nil;
        [self.imageDisplayed getImageWithProgress:^(float progress){
            //            [self.imageCropView setProgress:progress];
        }completion:^(UIImage *image){
            if (self.imageDisplayed.edits.counterClockwiseRotations > 0 || self.imageDisplayed.edits.flipHorizontal || self.imageDisplayed.edits.flipVertical){
                self.imageCropView.image = [UIImage imageWithCGImage:image.CGImage scale:image.scale orientation:[OLPhotoEdits orientationForNumberOfCounterClockwiseRotations:self.imageDisplayed.edits.counterClockwiseRotations andInitialOrientation:image.imageOrientation horizontalFlip:self.imageDisplayed.edits.flipHorizontal verticalFlip:self.imageDisplayed.edits.flipVertical]];
            }
            else{
                [self.imageCropView setImage:image];
            }
            [self.view setNeedsLayout];
            [self.view layoutIfNeeded];
            self.imageCropView.imageView.transform = self.imageDisplayed.edits.cropTransform;
        }];
    }
    else if (numberOfProviders > 1){
        if ([UIAlertController class]){
            UIAlertController *ac = [UIAlertController alertControllerWithTitle:nil message:NSLocalizedString(@"Add photos from:", @"") preferredStyle:UIAlertControllerStyleActionSheet];
            if ([OLKiteUtils cameraRollEnabled:self]){
                [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Camera Roll", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
                    [self showCameraRollImagePicker];
                }]];
            }
            if ([OLKiteUtils instagramEnabled]){
                [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Instagram", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
                    [self showInstagramImagePicker];
                }]];
            }
            if ([OLKiteUtils facebookEnabled]){
                [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Facebook", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
                    [self showFacebookImagePicker];
                }]];
            }
            if (qrCodeUploadEnabled) {
                [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"QR Code", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
                    UIViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"OLQRCodeUploadViewController"];
                    vc.modalPresentationStyle = UIModalPresentationFormSheet;
                    [self presentViewController:vc animated:YES completion:nil];
                    
                    UITapGestureRecognizer *tapBehindGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapBehindQRCodeScannerModal:)];
                    tapBehindGesture.delegate = self;
                    [tapBehindGesture setNumberOfTapsRequired:1];
                    [tapBehindGesture setCancelsTouchesInView:NO]; // So the user can still interact with controls in the modal view
                    [self.view.window addGestureRecognizer:tapBehindGesture];
                    
                }]];
            }
#ifdef OL_KITE_OFFER_CUSTOM_IMAGE_PROVIDERS
            for (OLCustomPhotoProvider *provider in [OLKiteUtils kiteVcForViewController:self].customImageProviders){
                [ac addAction:[UIAlertAction actionWithTitle:provider.name style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
                    [self showPickerForProvider:provider];
                }]];
            }
#endif
            
            [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action){
                [ac dismissViewControllerAnimated:YES completion:NULL];
            }]];
            ac.popoverPresentationController.sourceView = cell;
            ac.popoverPresentationController.sourceRect = cell.frame;
            [self presentViewController:ac animated:YES completion:NULL];
        }
        else{
            UIActionSheet *as = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Add photos from:", @"")
                                                            delegate:self
                                                   cancelButtonTitle:nil
                                              destructiveButtonTitle:nil
                                                   otherButtonTitles:nil];
            
            if ([OLKiteUtils cameraRollEnabled:self]){
                [as addButtonWithTitle:NSLocalizedString(@"Camera Roll", @"")];
            }
            if ([OLKiteUtils facebookEnabled]){
                [as addButtonWithTitle:@"Facebook"];
            }
            if ([OLKiteUtils instagramEnabled]){
                [as addButtonWithTitle:@"Instagram"];
            }
#ifdef OL_KITE_OFFER_CUSTOM_IMAGE_PROVIDERS
            for (OLCustomPhotoProvider *provider in [OLKiteUtils kiteVcForViewController:self].customImageProviders){
                [as addButtonWithTitle:provider.name];
            }
#endif
            as.cancelButtonIndex = [as addButtonWithTitle:@"Cancel"];
            
            [as showInView:self.view];
        }
    }
    else{
        if ([OLKiteUtils cameraRollEnabled:self]){
            [self showCameraRollImagePicker];
        }
        else if ([OLKiteUtils facebookEnabled]){
            [self showFacebookImagePicker];
        }
        else if ([OLKiteUtils instagramEnabled]){
            [self showInstagramImagePicker];
        }
#ifdef OL_KITE_OFFER_CUSTOM_IMAGE_PROVIDERS
        else{
            [self showPickerForProvider:[OLKiteUtils kiteVcForViewController:self].customImageProviders.firstObject];
        }
#endif
        
    }
}

- (void)onTapBehindQRCodeScannerModal:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        CGPoint location = [sender locationInView:nil]; // Passing nil gives us coordinates in the window
        // swap (x,y) on iOS 8 in landscape
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
            if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
                location = CGPointMake(location.y, location.x);
            }
        }
        
        // Convert tap location into the local view's coordinate system. If outside, dismiss the view.
        if (![self.presentedViewController.view pointInside:[self.presentedViewController.view convertPoint:location fromView:self.view.window] withEvent:nil]) {
            if(self.presentedViewController) {
                [self dismissViewControllerAnimated:YES completion:nil];
                [self.view.window removeGestureRecognizer:sender];
            }
        }
    }
}

- (NSArray *)createAssetArray {
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:self.userSelectedPhotos.count];
    for (OLPrintPhoto *object in self.userSelectedPhotos) {
        if ([object.asset isKindOfClass:[OLAsset class]] && [object.asset dataSource]){
            [array addObject:[object.asset dataSource]];
        }
        else if (![object.asset isKindOfClass:[OLAsset class]]){
            [array addObject:object.asset];
        }
    }
    return array;
}

- (void)showCameraRollImagePicker{
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackPhotoProviderPicked:@"Camera Roll" forProductName:self.product.productTemplate.name];
#endif
    __block UIViewController *picker;
    __block Class assetClass;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8 || !definesAtLeastiOS8){
        picker = [[OLAssetsPickerController alloc] init];
        [(OLAssetsPickerController *)picker setAssetsFilter:[ALAssetsFilter allPhotos]];
        assetClass = [ALAsset class];
        ((OLAssetsPickerController *)picker).delegate = self;
    }
#ifdef OL_KITE_AT_LEAST_IOS8
    else{
        if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusNotDetermined){
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status){
                if (status == PHAuthorizationStatusAuthorized){
                    picker = [[CTAssetsPickerController alloc] init];
                    ((CTAssetsPickerController *)picker).showsEmptyAlbums = NO;
                    PHFetchOptions *options = [[PHFetchOptions alloc] init];
                    options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %d", PHAssetMediaTypeImage];
                    ((CTAssetsPickerController *)picker).assetsFetchOptions = options;
                    assetClass = [PHAsset class];
                    ((CTAssetsPickerController *)picker).delegate = self;
                    NSArray *allAssets = [[self createAssetArray] mutableCopy];
                    NSMutableArray *alAssets = [[NSMutableArray alloc] init];
                    for (id asset in allAssets){
                        if ([asset isKindOfClass:assetClass]){
                            [alAssets addObject:asset];
                        }
                    }
                    [(id)picker setSelectedAssets:alAssets];
                    picker.modalPresentationStyle = [OLKiteUtils kiteVcForViewController:self].modalPresentationStyle;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self presentViewController:picker animated:YES completion:nil];
                    });
                }
            }];
        }
        else{
            picker = [[CTAssetsPickerController alloc] init];
            ((CTAssetsPickerController *)picker).showsEmptyAlbums = NO;
            PHFetchOptions *options = [[PHFetchOptions alloc] init];
            options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %d", PHAssetMediaTypeImage];
            ((CTAssetsPickerController *)picker).assetsFetchOptions = options;
            assetClass = [PHAsset class];
            ((CTAssetsPickerController *)picker).delegate = self;
        }
    }
#endif
    
    if (picker){
        NSArray *allAssets = [[self createAssetArray] mutableCopy];
        NSMutableArray *alAssets = [[NSMutableArray alloc] init];
        for (id asset in allAssets){
            if ([asset isKindOfClass:assetClass]){
                [alAssets addObject:asset];
            }
        }
        [(id)picker setSelectedAssets:alAssets];
        picker.modalPresentationStyle = [OLKiteUtils kiteVcForViewController:self].modalPresentationStyle;
        [self presentViewController:picker animated:YES completion:nil];
    }
}

- (void)showFacebookImagePicker{
#ifdef OL_KITE_OFFER_FACEBOOK
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackPhotoProviderPicked:@"Facebook" forProductName:self.product.productTemplate.name];
#endif
    OLFacebookImagePickerController *picker = nil;
    picker = [[OLFacebookImagePickerController alloc] init];
    picker.delegate = self;
    picker.selected = [self createAssetArray];
    picker.modalPresentationStyle = [OLKiteUtils kiteVcForViewController:self].modalPresentationStyle;
    [self presentViewController:picker animated:YES completion:nil];
#endif
}

- (void)showInstagramImagePicker{
#ifdef OL_KITE_OFFER_INSTAGRAM
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackPhotoProviderPicked:@"Instagram" forProductName:self.product.productTemplate.name];
#endif
    OLInstagramImagePickerController *picker = nil;
    picker = [[OLInstagramImagePickerController alloc] initWithClientId:[OLKitePrintSDK instagramClientID] secret:[OLKitePrintSDK instagramSecret] redirectURI:[OLKitePrintSDK instagramRedirectURI]];
    picker.delegate = self;
    picker.selected = [self createAssetArray];
    picker.modalPresentationStyle = [OLKiteUtils kiteVcForViewController:self].modalPresentationStyle;
    [self presentViewController:picker animated:YES completion:nil];
#endif
}

#ifdef OL_KITE_OFFER_CUSTOM_IMAGE_PROVIDERS
- (void)showPickerForProvider:(OLCustomPhotoProvider *)provider{
    UIViewController<KITCustomAssetPickerController> *vc;
    if (provider.vc){
        vc = provider.vc;
    }
    else{
        KITAssetsPickerController *kvc = [[KITAssetsPickerController alloc] init];
        kvc.collectionDataSources = provider.collections;
        vc = kvc;
    }
    
    if ([vc respondsToSelector:@selector(setSelectedAssets:)]){
        [vc performSelector:@selector(setSelectedAssets:) withObject:[[self createAssetArray] mutableCopy]];
    }
    vc.delegate = self;
    vc.modalPresentationStyle = [OLKiteUtils kiteVcForViewController:self].modalPresentationStyle;
    [self presentViewController:vc animated:YES completion:NULL];
}
#endif

#pragma mark - CTAssetsPickerControllerDelegate Methods

- (void)populateArrayWithNewArray:(NSArray *)array dataType:(Class)class {
    NSMutableArray *photoArray = [[NSMutableArray alloc] initWithCapacity:array.count];
    
    for (id object in array) {
        OLPrintPhoto *printPhoto = [[OLPrintPhoto alloc] init];
        printPhoto.asset = object;
        [photoArray addObject:printPhoto];
    }
    
    // First remove any that are not returned.
    NSMutableArray *removeArray = [NSMutableArray arrayWithArray:self.userSelectedPhotos];
    for (OLPrintPhoto *object in self.userSelectedPhotos) {
        if ([object.asset isKindOfClass:[OLAsset class]] && [[object.asset dataSource] isKindOfClass:class]){
            if ([photoArray containsObject:object]){
                [removeArray removeObjectIdenticalTo:object];
                [photoArray removeObject:object];
            }
        }
        else if (![object.asset isKindOfClass:class]) {
            [removeArray removeObjectIdenticalTo:object];
        }
        
        else if([photoArray containsObject:object]){
            [removeArray removeObjectIdenticalTo:object];
        }
    }
    
    [self.userSelectedPhotos removeObjectsInArray:removeArray];
    
    // Second, add the remaining objects to the end of the array without replacing any.
    NSMutableArray *addArray = [NSMutableArray arrayWithArray:photoArray];
    for (id object in self.userSelectedPhotos) {
        if ([addArray containsObject:object]){
            [addArray removeObject:object];
        }
    }
    
    for (OLPrintPhoto *photo in addArray){
        if (![removeArray containsObject:photo]){
            self.imagePicked = photo;
            break;
        }
    }
    
    [self.userSelectedPhotos addObjectsFromArray:addArray];
    
    [self.imagesCollectionView reloadData];
}

#if __IPHONE_OS_VERSION_MIN_REQUIRED < 80000
- (BOOL)assetsPickerController:(OLAssetsPickerController *)picker isDefaultAssetsGroup:(ALAssetsGroup *)group {
    if ([self.delegate respondsToSelector:@selector(kiteController:isDefaultAssetsGroup:)]) {
        return [self.delegate kiteController:[OLKiteUtils kiteVcForViewController:self] isDefaultAssetsGroup:group];
    }
    
    return NO;
}
#endif

- (void)assetsPickerController:(id)picker didFinishPickingAssets:(NSArray *)assets {
    NSInteger originalCount = self.userSelectedPhotos.count;
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackPhotoProvider:@"Camera Roll" numberOfPhotosAdded:self.userSelectedPhotos.count - originalCount forProductName:self.product.productTemplate.name];
#endif
    Class assetClass;
    if ([picker isKindOfClass:[OLAssetsPickerController class]]){
        assetClass = [ALAsset class];
    }
#ifdef OL_KITE_AT_LEAST_IOS8
    else if ([picker isKindOfClass:[CTAssetsPickerController class]]){
        assetClass = [PHAsset class];
    }
#endif
#ifdef OL_KITE_OFFER_CUSTOM_IMAGE_PROVIDERS
    else if ([picker isKindOfClass:[KITAssetsPickerController class]]){
        NSMutableArray *olAssets = [[NSMutableArray alloc] init];
        for (id<OLAssetDataSource> asset in assets){
            if ([asset respondsToSelector:@selector(dataWithCompletionHandler:)]){
                [olAssets addObject:[OLAsset assetWithDataSource:asset]];
            }
        }
        assets = olAssets;
        assetClass = [[assets.firstObject dataSource] class];
    }
#endif
    [self populateArrayWithNewArray:assets dataType:assetClass];
    
    if (self.imagePicked){
        self.imageDisplayed = self.imagePicked;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self.imagePicked getImageWithProgress:NULL completion:^(UIImage *image){
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.imageCropView.image = image;
                    self.imagePicked = nil;
                });
            }];
        });
        
    }
    [picker dismissViewControllerAnimated:YES completion:^(void){}];
    
}

- (BOOL)assetsPickerController:(OLAssetsPickerController *)picker shouldShowAssetsGroup:(ALAssetsGroup *)group{
    if (group.numberOfAssets == 0){
        return NO;
    }
    return YES;
}

#ifdef OL_KITE_AT_LEAST_IOS8
- (void)assetsPickerController:(CTAssetsPickerController *)picker didDeSelectAsset:(PHAsset *)asset{
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8){
        return;
    }
    if (![asset isKindOfClass:[PHAsset class]]){
        return;
    }
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.networkAccessAllowed = YES;
    [[OLImageCachingManager sharedInstance].photosCachingManager stopCachingImagesForAssets:@[asset] targetSize:PHImageManagerMaximumSize contentMode:PHImageContentModeAspectFill options:options];
}

- (void)assetsPickerController:(CTAssetsPickerController *)picker didSelectAsset:(PHAsset *)asset{
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8){
        return;
    }
    if (![asset isKindOfClass:[PHAsset class]]){
        return;
    }
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.networkAccessAllowed = YES;
    [[OLImageCachingManager sharedInstance].photosCachingManager startCachingImagesForAssets:@[asset] targetSize:PHImageManagerMaximumSize contentMode:PHImageContentModeAspectFill options:options];
}
#endif

- (BOOL)assetsPickerController:(OLAssetsPickerController *)picker shouldShowAsset:(id)asset{
    NSString *fileName = [[[asset defaultRepresentation] filename] lowercaseString];
    if (!([fileName hasSuffix:@".jpg"] || [fileName hasSuffix:@".jpeg"] || [fileName hasSuffix:@"png"] || [fileName hasSuffix:@"tiff"])) {
        return NO;
    }
    return YES;
}

#ifdef OL_KITE_OFFER_INSTAGRAM
#pragma mark - OLInstagramImagePickerControllerDelegate Methods

- (void)instagramImagePicker:(OLInstagramImagePickerController *)imagePicker didFailWithError:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)instagramImagePicker:(OLInstagramImagePickerController *)imagePicker didFinishPickingImages:(NSArray *)images {
    NSInteger originalCount = self.userSelectedPhotos.count;
#ifdef OL_KITE_OFFER_CUSTOM_IMAGE_PROVIDERS
        NSMutableArray *assets = [[NSMutableArray alloc] init];
        for (id<OLAssetDataSource> asset in images){
            if ([asset isKindOfClass:[OLInstagramImage class]]){
                [assets addObject:asset];
            }
        }
        images = assets;
#endif
    
    [self populateArrayWithNewArray:images dataType:[OLInstagramImage class]];
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackPhotoProvider:@"Instagram" numberOfPhotosAdded:self.userSelectedPhotos.count - originalCount forProductName:self.product.productTemplate.name];
#endif
    if (self.imagePicked){
        [self.imagePicked getImageWithProgress:NULL completion:^(UIImage *image){
            dispatch_async(dispatch_get_main_queue(), ^{
                self.imageCropView.image = image;
            });
        }];
        self.imageDisplayed = self.imagePicked;
        self.imagePicked = nil;
    }
    [self dismissViewControllerAnimated:YES completion:^(void){}];
}

- (void)instagramImagePickerDidCancelPickingImages:(OLInstagramImagePickerController *)imagePicker {
    [self dismissViewControllerAnimated:YES completion:nil];
}
#endif

#ifdef OL_KITE_OFFER_FACEBOOK
#pragma mark - OLFacebookImagePickerControllerDelegate Methods

- (void)facebookImagePicker:(OLFacebookImagePickerController *)imagePicker didFailWithError:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)facebookImagePicker:(OLFacebookImagePickerController *)imagePicker didFinishPickingImages:(NSArray *)images {
    NSInteger originalCount = self.userSelectedPhotos.count;
#ifdef OL_KITE_OFFER_CUSTOM_IMAGE_PROVIDERS
    NSMutableArray *assets = [[NSMutableArray alloc] init];
    for (id<OLAssetDataSource> asset in images){
        if ([asset isKindOfClass:[OLFacebookImage class]]){
            [assets addObject:asset];
        }
    }
    images = assets;
#endif
    
    [self populateArrayWithNewArray:images dataType:[OLFacebookImage class]];
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackPhotoProvider:@"Facebook" numberOfPhotosAdded:self.userSelectedPhotos.count - originalCount forProductName:self.product.productTemplate.name];
#endif
    if (self.imagePicked){
        [self.imagePicked getImageWithProgress:NULL completion:^(UIImage *image){
            dispatch_async(dispatch_get_main_queue(), ^{
                self.imageCropView.image = image;
            });
        }];
        self.imageDisplayed = self.imagePicked;
        self.imagePicked = nil;
    }
    [self dismissViewControllerAnimated:YES completion:^(void){}];
}

- (void)facebookImagePickerDidCancelPickingImages:(OLFacebookImagePickerController *)imagePicker {
    [self dismissViewControllerAnimated:YES completion:nil];
}
#endif

#pragma mark UIActionSheet Delegate (only used on iOS 7)

- (void) actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if (buttonIndex == [OLKiteUtils cameraRollProviderIndex:self]){
            [self showCameraRollImagePicker];
        }
        else if (buttonIndex == [OLKiteUtils instagramProviderIndex:self]){
            [self showInstagramImagePicker];
        }
        else if (buttonIndex == [OLKiteUtils facebookProviderIndex:self]){
            [self showFacebookImagePicker];
        }
#ifdef OL_KITE_OFFER_CUSTOM_IMAGE_PROVIDERS
        else{
            [self showPickerForProvider:[OLKiteUtils kiteVcForViewController:self].customImageProviders[buttonIndex - [OLKiteUtils customProvidersStartIndex:self]]];
        }
#endif
    });
}

#pragma mark - OLImageEditorViewControllerDelegate methods

- (void)scrollCropViewControllerDidCancel:(OLScrollCropViewController *)cropper{
    [cropper dismissViewControllerAnimated:YES completion:^{
    }];
}

-(void)scrollCropViewController:(OLScrollCropViewController *)cropper didFinishCroppingImage:(UIImage *)croppedImage{
    [self.imageDisplayed unloadImage];
    
    self.imageDisplayed.edits = cropper.edits;
    
    [self.imageDisplayed getImageWithProgress:NULL completion:^(UIImage *image){
        if (self.imageDisplayed.edits.counterClockwiseRotations > 0 || self.imageDisplayed.edits.flipHorizontal || self.imageDisplayed.edits.flipVertical){
            self.imageCropView.image = [UIImage imageWithCGImage:image.CGImage scale:image.scale orientation:[OLPhotoEdits orientationForNumberOfCounterClockwiseRotations:self.imageDisplayed.edits.counterClockwiseRotations andInitialOrientation:image.imageOrientation horizontalFlip:self.imageDisplayed.edits.flipHorizontal verticalFlip:self.imageDisplayed.edits.flipVertical]];
        }
        else{
            [self.imageCropView setImage:image];
        }
        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];
        self.imageCropView.imageView.transform = self.imageDisplayed.edits.cropTransform;
    }];
    
    [cropper dismissViewControllerAnimated:YES completion:^{
        [UIView animateWithDuration:0.25 animations:^{
        }];
    }];
    
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackReviewScreenDidCropPhotoForProductName:self.product.productTemplate.name];
#endif
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

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8) {
        return UIInterfaceOrientationMaskAll;
    }
    else{
        return UIInterfaceOrientationMaskPortrait;
    }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 100) {
        if (buttonIndex == 1) {
            [self saveJobNowWithCompletionHandler:self.saveJobCompletionHandler];
        }
    }
}

#pragma mark - UIGestureRecognizer Delegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return YES;
}


@end
