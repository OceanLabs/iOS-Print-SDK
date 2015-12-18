//
//  OLSingleImageProductReviewViewController.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 2/24/15.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import "NSArray+QueryingExtras.h"
#import "NSObject+Utils.h"
#import "OLAnalytics.h"
#import "OLAsset+Private.h"
#import "OLAsset+Private.h"
#import "OLAssetsPickerController.h"
#import "OLCustomPhotoProvider.h"
#import "OLImageCachingManager.h"
#import "OLKiteABTesting.h"
#import "OLKitePrintSDK.h"
#import "OLKiteUtils.h"
#import "OLKiteViewController.h"
#import "OLPaymentViewController.h"
#import "OLPrintPhoto.h"
#import "OLProductPrintJob.h"
#import "OLProductTemplateOption.h"
#import "OLRemoteImageCropper.h"
#import "OLRemoteImageView.h"
#import "OLSingleImageProductReviewViewController.h"
#import "SDWebImageManager.h"

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

#ifdef OL_KITE_AT_LEAST_IOS8
#import <CTAssetsPickerController/CTAssetsPickerController.h>
#endif

@interface OLPaymentViewController (Private)

-(void)saveAndDismissReviewController;

@end

@interface OLPrintOrder (Private)

- (void)saveOrder;

@end

@interface OLKiteViewController ()

@property (strong, nonatomic) OLPrintOrder *printOrder;
@property (strong, nonatomic) NSMutableArray <OLCustomPhotoProvider *> *customImageProviders;
- (void)dismiss;

@end

@interface OLKitePrintSDK (InternalUtils)
#ifdef OL_KITE_OFFER_INSTAGRAM
+ (NSString *) instagramRedirectURI;
+ (NSString *) instagramSecret;
+ (NSString *) instagramClientID;
#endif
@end

@interface OLSingleImageProductReviewViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UINavigationControllerDelegate, UIActionSheetDelegate, UIAlertViewDelegate,
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
OLAssetsPickerControllerDelegate, RMImageCropperDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *imagesCollectionView;

@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet OLRemoteImageCropper *imageCropView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *maskAspectRatio;
@property (strong, nonatomic) OLPrintPhoto *imagePicked;
@property (strong, nonatomic) OLPrintPhoto *imageDisplayed;

-(void) doCheckout;

@end

static BOOL hasMoved;

@implementation OLSingleImageProductReviewViewController

-(id<OLPrintJob>)editingPrintJob{
    if (_editingPrintJob){
        return _editingPrintJob;
    }
    else if([OLKiteABTesting sharedInstance].launchedWithPrintOrder){
        OLKiteViewController *kiteVc = [OLKiteUtils kiteVcForViewController:self];
        return [kiteVc.printOrder.jobs firstObject];
    }
    
    return nil;
}

-(void)viewDidLoad{
    [super viewDidLoad];
    
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackReviewScreenViewed:self.product.productTemplate.name];
#endif
    
    if ([self.presentingViewController respondsToSelector:@selector(viewControllers)]) {
        UIViewController *paymentVc = [(UINavigationController *)self.presentingViewController viewControllers].lastObject;
        if ([paymentVc respondsToSelector:@selector(saveAndDismissReviewController)]){
            UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Save", "")
                                                                           style:UIBarButtonItemStyleDone target:paymentVc
                                                                          action:@selector(saveAndDismissReviewController)];
            self.navigationItem.rightBarButtonItem = saveButton;
            [self.ctaButton setTitle:NSLocalizedString(@"Save", @"") forState:UIControlStateNormal];
            [self.ctaButton removeTarget:self action:@selector(onButtonNextClicked) forControlEvents:UIControlEventTouchUpInside];
            [self.ctaButton addTarget:paymentVc action:@selector(saveAndDismissReviewController) forControlEvents:UIControlEventTouchUpInside];
        }
    }
    
    self.title = NSLocalizedString(@"Reposition the Photo", @"");
    
    if (self.imageCropView){
        self.imageCropView.delegate = self;
        OLPrintPhoto *photo = [self.userSelectedPhotos firstObject];
        [photo getImageWithProgress:NULL completion:^(UIImage *image){
            self.imageCropView.image = image;
        }];
        self.imageDisplayed = photo;
    }
    
    for (OLPrintPhoto *printPhoto in self.userSelectedPhotos){
        [printPhoto unloadImage];
    }
    
    if (!self.navigationItem.rightBarButtonItem){
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                                  initWithTitle:NSLocalizedString(@"Next", @"")
                                                  style:UIBarButtonItemStylePlain
                                                  target:self
                                                  action:@selector(onButtonNextClicked)];
    }
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", @"")
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:nil
                                                                            action:nil];
    
    self.imagesCollectionView.dataSource = self;
    self.imagesCollectionView.delegate = self;
    
    if (![OLKiteUtils imageProvidersAvailable:self] && self.userSelectedPhotos.count == 1){
        self.imagesCollectionView.hidden = YES;
    }
    
    if ([OLKiteUtils imageProvidersAvailable:self] && self.userSelectedPhotos.count == 0 && [[[UIDevice currentDevice] systemVersion] floatValue] >= 8){
        [self collectionView:self.imagesCollectionView didSelectItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
    }
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
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
    
    OLAsset *asset = [OLAsset assetWithDataSource:self.imageDisplayed];
    
    [asset dataLengthWithCompletionHandler:^(long long dataLength, NSError *error){
        if (dataLength < 40000){
            if ([UIAlertController class]){
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Image Is Too Small", @"") message:NSLocalizedString(@"Please zoom out or pick a higher quality image", @"") preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"") style:UIAlertActionStyleDefault handler:NULL]];
                [self presentViewController:alert animated:YES completion:NULL];
            }
            else{
                [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Image Too Small", @"") message:NSLocalizedString(@"Please zoom out or pick higher quality image", @"") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil] show];
            }
            return;
        }
        
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
    }];
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
            dispatch_async(dispatch_get_main_queue(), ^{
                self.imageCropView.image = image;
            });
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
                    [self presentViewController:picker animated:YES completion:nil];
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
    KITAssetsPickerController *vc = [[KITAssetsPickerController alloc] init];
    vc.delegate = self;
    vc.collectionDataSources = provider.collections;
    vc.modalPresentationStyle = [OLKiteUtils kiteVcForViewController:self].modalPresentationStyle;
    [self presentViewController:vc animated:YES completion:NULL];
}
#endif

#pragma mark - CTAssetsPickerControllerDelegate Methods

- (void)populateArrayWithNewArray:(NSArray *)array dataType:(Class)class {
    NSMutableArray *photoArray = [[NSMutableArray alloc] initWithCapacity:array.count];
    NSMutableArray *assetArray = [[NSMutableArray alloc] initWithCapacity:array.count];
    
    for (id object in array) {
        OLPrintPhoto *printPhoto = [[OLPrintPhoto alloc] init];
        printPhoto.asset = object;
        [photoArray addObject:printPhoto];
        
        [assetArray addObject:[OLAsset assetWithPrintPhoto:printPhoto]];
    }
    
    // First remove any that are not returned.
    NSMutableArray *removeArray = [NSMutableArray arrayWithArray:self.userSelectedPhotos];
    for (OLPrintPhoto *object in self.userSelectedPhotos) {
        if ([object.asset isKindOfClass:[OLAsset class]] && [object.asset isKindOfClass:class]){
            for (OLPrintPhoto *addedPhoto in photoArray){
                if ([addedPhoto.asset isKindOfClass:[OLAsset class]] && (![[object.asset dataSource] isEqual:[addedPhoto.asset dataSource]] || ![[[object.asset dataSource] class] isKindOfClass:[[addedPhoto.asset dataSource] class]])){
                    [removeArray removeObjectIdenticalTo:object];
                }
            }
        }
        else if (![object.asset isKindOfClass:class]) {
            [removeArray removeObjectIdenticalTo:object];
        }
        
        if([photoArray containsObject:object]){
            [removeArray removeObjectIdenticalTo:object];
        }
    }
    
    [self.userSelectedPhotos removeObjectsInArray:removeArray];
    
    // Second, add the remaining objects to the end of the array without replacing any.
    NSMutableArray *addArray = [NSMutableArray arrayWithArray:photoArray];
    NSMutableArray *addAssetArray = [NSMutableArray arrayWithArray:assetArray];
    for (id object in self.userSelectedPhotos) {
        OLAsset *asset = [OLAsset assetWithPrintPhoto:object];
        
        if ([addAssetArray containsObject:asset]){
            [addArray removeObjectAtIndex:[addAssetArray indexOfObject:asset]];
            [addAssetArray removeObject:asset];
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
        assetClass = [OLAsset class];
        NSMutableArray *olAssets = [[NSMutableArray alloc] init];
        for (id<OLAssetDataSource> asset in assets){
            if ([asset respondsToSelector:@selector(dataWithCompletionHandler:)]){
                [olAssets addObject:[OLAsset assetWithDataSource:asset]];
            }
        }
        assets = olAssets;
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
    if (!([fileName hasSuffix:@".jpg"] || [fileName hasSuffix:@".jpeg"] || [fileName hasSuffix:@"png"])) {
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

@end
