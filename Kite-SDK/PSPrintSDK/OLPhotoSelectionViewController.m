//
//  PhotoSelectionViewController.m
//  Print Studio
//
//  Created by Elliott Minns on 12/12/2013.
//  Copyright (c) 2013 Ocean Labs. All rights reserved.
//

#ifdef COCOAPODS
#import <UIColor-HexString/UIColor+HexString.h>
#else
#import "UIColor+HexString.h"
#endif

#import "OLPhotoSelectionViewController.h"
#import "OLPhotoSelectionButton.h"
#import "OLPrintPhoto.h"
#import "OLOrderReviewViewController.h"

#import "OLAssetsPickerController.h"

#ifdef OL_KITE_AT_LEAST_IOS8
#import <CTAssetsPickerController/CTAssetsPickerController.h>
#endif

#ifdef OL_KITE_OFFER_INSTAGRAM
#import <InstagramImagePicker/OLInstagramImagePickerController.h>
#import <InstagramImagePicker/OLInstagramImage.h>
#endif

#ifdef OL_KITE_OFFER_FACEBOOK
#import <FacebookImagePicker/OLFacebookImagePickerController.h>
#import <FacebookImagePicker/OLFacebookImage.h>
#endif

#import "OLPrintJob.h"
#import "OLAddress.h"
#import "OLAsset.h"
#import "OLProductPrintJob.h"
#import "OLConstants.h"
#import "LXReorderableCollectionViewFlowLayout.h"
#import "NSArray+QueryingExtras.h"
#import "OLKitePrintSDK.h"
#import "NSObject+Utils.h"
#import "UIViewController+TraitCollectionCompatibility.h"
#import "OLAnalytics.h"
#import "OLKiteUtils.h"
#import "OLKiteABTesting.h"

#import "OLRemoteImageView.h"
#import "OLImageCachingManager.h"
#import "UIImage+ImageNamedInKiteBundle.h"
#import "UIViewController+OLMethods.h"
#import "OLPaymentViewController.h"

NSInteger OLPhotoSelectionMargin = 0;

#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)

static const NSUInteger kTagAlertViewSelectMorePhotos = 99;

@interface OLKitePrintSDK (Private)

#ifdef OL_KITE_OFFER_INSTAGRAM
+ (NSString *) instagramRedirectURI;
+ (NSString *) instagramSecret;
+ (NSString *) instagramClientID;
#endif

@end

@interface OLPhotoSelectionViewController () <UINavigationControllerDelegate,
#ifdef OL_KITE_AT_LEAST_IOS8
                                            CTAssetsPickerControllerDelegate,
#endif
                                            OLAssetsPickerControllerDelegate,
                                            UICollectionViewDataSource,
                                            UICollectionViewDelegate,
                                            UICollectionViewDelegateFlowLayout,
#ifdef OL_KITE_OFFER_INSTAGRAM
                                            OLInstagramImagePickerControllerDelegate,
#endif
#ifdef OL_KITE_OFFER_FACEBOOK
                                            OLFacebookImagePickerControllerDelegate,
#endif
                                            LXReorderableCollectionViewDataSource,
                                            UICollectionViewDelegateFlowLayout>

@property (nonatomic, weak) IBOutlet OLPhotoSelectionButton *galleryButton;
@property (nonatomic, weak) IBOutlet OLPhotoSelectionButton *instagramButton;
@property (nonatomic, weak) IBOutlet OLPhotoSelectionButton *facebookButton;
@property (weak, nonatomic) IBOutlet UIView *cameraRollContainer;
@property (weak, nonatomic) IBOutlet UIView *instagramContainer;
@property (weak, nonatomic) IBOutlet UIView *facebookContainer;

@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) OLAssetsPickerController *picker;
@property (strong, nonatomic) NSMutableArray *userDisabledPhotos;

@property (nonatomic, weak) IBOutlet UILabel *chooseImportSourceLabel;
@property (nonatomic, weak) IBOutlet UIButton *buttonGalleryImport, *buttonInstagramImport, *buttonFacebookImport;

@property (nonatomic, weak) IBOutlet UIButton *buttonNext;
@property (nonatomic, weak) IBOutlet UIView *noSelectedPhotosView;
@property (weak, nonatomic) IBOutlet UIView *clearButtonContainerView;
//@property (weak, nonatomic) IBOutlet UIButton *clearButton;
@property (strong, nonatomic) UIVisualEffectView *visualEffectView;

@property (assign, nonatomic) CGSize rotationSize;

@property (strong, nonatomic) NSMutableDictionary *indexPathsToRemoveDict;
@end

@interface OLKiteViewController ()

@property (strong, nonatomic) OLPrintOrder *printOrder;
- (void)dismiss;

@end

@implementation OLPhotoSelectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackPhotoSelectionScreenViewed:self.product.productTemplate.name];
#endif
    
    self.navigationItem.titleView = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 44)];
    [(UILabel *)self.navigationItem.titleView setTextAlignment:NSTextAlignmentCenter];
    [(UILabel *)self.navigationItem.titleView setFont:[UIFont preferredFontForTextStyle:UIFontTextStyleHeadline]];
    self.userDisabledPhotos = [[NSMutableArray alloc] init];
    
    self.galleryButton.image = [UIImage imageNamedInKiteBundle:@"import_gallery"];
    self.galleryButton.title = NSLocalizedString(@"Camera Roll", @"");
    self.galleryButton.mainColor = [UIColor colorWithRed:0.227 green:0.706 blue:0.600 alpha:1.000];
    
    self.instagramButton.image = [UIImage imageNamedInKiteBundle:@"import_instagram"];
    self.instagramButton.title = NSLocalizedString(@"Instagram", @"");
    self.instagramButton.mainColor = [UIColor colorWithRed:0.965 green:0.733 blue:0.259 alpha:1.000];
    
    self.facebookButton.image = [UIImage imageNamedInKiteBundle:@"import_facebook"];
    self.facebookButton.title = NSLocalizedString(@"Facebook", @"");
    self.facebookButton.mainColor = [UIColor colorWithRed:0.290 green:0.537 blue:0.863 alpha:1.000];
    
    [self.buttonFacebookImport setBackgroundImage:[self imageWithColor:[UIColor colorWithHexString:@"#497aba"]] forState:UIControlStateHighlighted];
    [self.buttonGalleryImport setBackgroundImage:[self imageWithColor:[UIColor colorWithHexString:@"#369c82"]] forState:UIControlStateHighlighted];
    [self.buttonInstagramImport setBackgroundImage:[self imageWithColor:[UIColor colorWithHexString:@"#c29334"]] forState:UIControlStateHighlighted];
    
    self.rotationSize = CGSizeZero;
    
    if (![self instagramEnabled]){
        [self.instagramButton removeFromSuperview];
        [self.buttonInstagramImport removeFromSuperview];
        [self.instagramContainer removeFromSuperview];
    }
    
    if (![self facebookEnabled]){
        [self.facebookButton removeFromSuperview];
        [self.buttonFacebookImport removeFromSuperview];
        [self.facebookContainer removeFromSuperview];
    }
    
    LXReorderableCollectionViewFlowLayout *layout = (LXReorderableCollectionViewFlowLayout *)[self.collectionView collectionViewLayout];
    layout.headerReferenceSize = CGSizeMake(0, 50);
    
    if ((self.product.productTemplate.templateUI == kOLTemplateUICase || self.product.productTemplate.templateUI == kOLTemplateUIPoster || self.product.productTemplate.templateUI == kOLTemplateUIPostcard || self.product.productTemplate.templateUI == kOLTemplateUIPhotobook) && self.userSelectedPhotos.count > self.product.quantityToFulfillOrder){
        self.userSelectedPhotos = [[self.userSelectedPhotos subarrayWithRange:NSMakeRange(0, self.product.quantityToFulfillOrder)] mutableCopy];
    }
    
    [self.collectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"headerView"];
    
    if (self.userSelectedPhotos.count > 0) {
            self.noSelectedPhotosView.alpha = 0;
    }
    else if (self.userSelectedPhotos.count == 0) {
            self.noSelectedPhotosView.alpha = 1;
    }
    [self onUserSelectedPhotoCountChange];
    
}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    
    self.collectionView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
}

- (BOOL)instagramEnabled{
#ifdef OL_KITE_OFFER_INSTAGRAM
    return [OLKitePrintSDK instagramSecret] && ![[OLKitePrintSDK instagramSecret] isEqualToString:@""] && [OLKitePrintSDK instagramClientID] && ![[OLKitePrintSDK instagramClientID] isEqualToString:@""] && [OLKitePrintSDK instagramRedirectURI] && ![[OLKitePrintSDK instagramRedirectURI] isEqualToString:@""];
#else 
    return NO;
#endif
}

- (BOOL)facebookEnabled{
#ifdef OL_KITE_OFFER_FACEBOOK
    return YES;
#else
    return NO;
#endif
}

- (void)viewWillAppear:(BOOL)animated{
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
    
    if (self.userSelectedPhotos.count > 0){
        [self.collectionView reloadData];
    }
    [self updateTitleBasedOnSelectedPhotoQuanitity];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self updateNoSelectedPhotosView];
    [self.collectionView.collectionViewLayout invalidateLayout];
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    
#ifndef OL_NO_ANALYTICS
    if (!self.navigationController){
        [OLAnalytics trackPhotoSelectionScreenHitBack:self.product.productTemplate.name];
    }
#endif
}

- (UIImage *)imageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (void)onUserSelectedPhotoCountChange {
    NSMutableArray *toRemove = [[NSMutableArray alloc] init];
    for (OLPrintPhoto *printPhoto in self.userDisabledPhotos){
        if (![self.userSelectedPhotos containsObjectIdenticalTo:printPhoto]){
            [toRemove addObject:printPhoto];
        }
    }
    [self.userDisabledPhotos removeObjectsInArray:toRemove];
    
    [self updateNoSelectedPhotosView];
    [self updateTitleBasedOnSelectedPhotoQuanitity];
}

- (void)updateNoSelectedPhotosView {
    NSTimeInterval delay = 0.35;
    NSTimeInterval duration = 0.3;
    self.collectionView.alpha = self.userSelectedPhotos.count == 0 ? 0 : 1;
    if (self.userSelectedPhotos.count > 0 && self.noSelectedPhotosView.alpha >= 0.9f) {
        self.noSelectedPhotosView.alpha = 1;
        [UIView animateWithDuration:duration delay:delay options:UIViewAnimationOptionCurveEaseIn animations:^{
            self.noSelectedPhotosView.alpha = 0;
        } completion:^(BOOL finished) {}];
    }
    else if (self.userSelectedPhotos.count == 0 && self.noSelectedPhotosView.alpha <= 0.1f) {
        self.noSelectedPhotosView.alpha = 0;
        [UIView animateWithDuration:duration delay:delay options:UIViewAnimationOptionCurveEaseIn animations:^{
            self.noSelectedPhotosView.alpha = 1;
        } completion:^(BOOL finished) {}];
    }
}

-(NSUInteger) totalNumberOfExtras{
    if (self.product.productTemplate.templateUI == kOLTemplateUIFrame || self.product.productTemplate.templateUI == kOLTemplateUIPoster || self.product.productTemplate.templateUI == kOLTemplateUIPhotobook){
        return 0;
    }
    
    NSUInteger res = 0;
    for (OLPrintPhoto *photo in self.userSelectedPhotos){
        res += photo.extraCopies;
    }
    return res;
}

- (void)updateTitleBasedOnSelectedPhotoQuanitity {
    if (self.userSelectedPhotos.count == 0) {
        [(UILabel *)self.navigationItem.titleView setText:NSLocalizedString(@"Choose Photos", @"")];
    } else {
        if (self.product.quantityToFulfillOrder > 1){
            NSUInteger numOrders = 1 + (MAX(0, self.userSelectedPhotos.count - 1 + [self totalNumberOfExtras]) / self.product.quantityToFulfillOrder);
            NSUInteger quanityToFulfilOrder = numOrders * self.product.quantityToFulfillOrder;
            [(UILabel *)self.navigationItem.titleView setText:[NSString stringWithFormat:@"%lu / %lu", (unsigned long)self.userSelectedPhotos.count - self.userDisabledPhotos.count + [self totalNumberOfExtras], (unsigned long)quanityToFulfilOrder]];
        }
        else{
            [(UILabel *)self.navigationItem.titleView setText:[NSString stringWithFormat:@"%lu", (unsigned long)self.userSelectedPhotos.count - self.userDisabledPhotos.count]];
        }
    }
    
    if ([self.userDisabledPhotos count] > 0){
        [UIView animateKeyframesWithDuration:0.15 delay:0 options:UIViewKeyframeAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveLinear animations:^{
            self.clearButtonContainerView.transform = CGAffineTransformMakeTranslation(0, -40);
            self.collectionView.contentInset = UIEdgeInsetsMake(self.collectionView.contentInset.top, self.collectionView.contentInset.left, self.collectionView.contentInset.bottom + 40, self.collectionView.contentInset.left);
        }completion:NULL];
    }
    else{
        if (self.clearButtonContainerView.transform.ty != 0){
            [UIView animateKeyframesWithDuration:0.15 delay:0 options:UIViewKeyframeAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveLinear animations:^{
                self.clearButtonContainerView.transform = CGAffineTransformIdentity;
                self.collectionView.contentInset = UIEdgeInsetsMake(self.collectionView.contentInset.top, self.collectionView.contentInset.left, 0, self.collectionView.contentInset.left);
            }completion:NULL];
        }
    }
}

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
        if (![object.asset isKindOfClass:class] || [photoArray containsObject:object]) {
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

    [self.userSelectedPhotos addObjectsFromArray:addArray];
    
    // Reload the collection view.
    [self.collectionView reloadData];
    
    [self onUserSelectedPhotoCountChange];
}

- (NSArray *)createAssetArray {
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:self.userSelectedPhotos.count];
    for (OLPrintPhoto *object in self.userSelectedPhotos) {
        [array addObject:object.asset];
    }
    return array;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    self.rotationSize = size;
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinator> context){
        [self.collectionView reloadData];
        [self.collectionView.collectionViewLayout invalidateLayout];
    }completion:^(id<UIViewControllerTransitionCoordinator> context){
        
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    for (OLPrintPhoto *photo in self.userSelectedPhotos) {
        [photo unloadImage];
    }
}

#pragma mark - Actions

- (IBAction)cameraRollSelected:(id)sender {
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

- (IBAction)instagramSelected:(id)sender {
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

- (IBAction)facebookSelected:(id)sender {
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

- (IBAction)onButtonClearClicked:(id)sender {
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackPhotoSelectionScreenNumberOfPhotosRemoved:self.userDisabledPhotos.count forProductName:self.product.productTemplate.name];
#endif
    NSInteger initialSections = [self numberOfSectionsInCollectionView:self.collectionView];
    
    self.indexPathsToRemoveDict = [[NSMutableDictionary alloc] init];
    for (id photo in self.userDisabledPhotos){
        NSUInteger index = [self.userSelectedPhotos indexOfObjectIdenticalTo:photo];
        NSUInteger section = [self shouldGroupPhotosInOneSection] ? 0 : index / self.product.quantityToFulfillOrder;
        NSUInteger item = [self shouldGroupPhotosInOneSection] ? index : index % self.product.quantityToFulfillOrder;
        
        if (!self.indexPathsToRemoveDict[[NSNumber numberWithInteger:section]]){
            self.indexPathsToRemoveDict[[NSNumber numberWithInteger:section]] = [[NSMutableArray alloc] init];
        }
        [self.indexPathsToRemoveDict[[NSNumber numberWithInteger:section]] addObject:[NSIndexPath indexPathForItem:item inSection:section]];
    }
    for (id photo in self.userDisabledPhotos){
        [self.userSelectedPhotos removeObjectIdenticalTo:photo];
    }
    
    [self.userDisabledPhotos removeAllObjects];
    [self updateTitleBasedOnSelectedPhotoQuanitity];
    
    [self.collectionView performBatchUpdates:^{
        if ([self numberOfSectionsInCollectionView:self.collectionView] < initialSections){
            NSUInteger sectionsDeleted = initialSections - [self numberOfSectionsInCollectionView:self.collectionView];
            NSRange range = NSMakeRange(initialSections - sectionsDeleted, sectionsDeleted);
            [self.collectionView deleteSections:[NSIndexSet indexSetWithIndexesInRange:range]];
        }
        for (NSNumber *sectionNumber in self.indexPathsToRemoveDict.allKeys){
            NSNumber *n = [NSNumber numberWithLong:[sectionNumber longValue]];
            [self.collectionView deleteItemsAtIndexPaths:self.indexPathsToRemoveDict[n]];
        }
    }completion:^(BOOL finished){
        [self.indexPathsToRemoveDict removeAllObjects];
        [self.collectionView performSelector:@selector(reloadData) withObject:0 afterDelay:0.05];
        [self updateNoSelectedPhotosView];
    }];
    
}

#pragma mark - CTAssetsPickerControllerDelegate Methods

- (OLKiteViewController *)kiteViewController {
    for (UIViewController *vc in self.navigationController.viewControllers) {
        if ([vc isMemberOfClass:[OLKiteViewController class]]) {
            return (OLKiteViewController *) vc;
        }
    }
    
    return nil;
}

#if __IPHONE_OS_VERSION_MIN_REQUIRED < 80000
- (BOOL)assetsPickerController:(OLAssetsPickerController *)picker isDefaultAssetsGroup:(ALAssetsGroup *)group {
    if ([self.delegate respondsToSelector:@selector(kiteController:isDefaultAssetsGroup:)]) {
        return [self.delegate kiteController:[self kiteViewController] isDefaultAssetsGroup:group];
    }
    
    return NO;
}
#endif

- (void)assetsPickerController:(id)picker didFinishPickingAssets:(NSArray *)assets {
    NSInteger originalCount = self.userSelectedPhotos.count;
    [self populateArrayWithNewArray:assets dataType:[picker isKindOfClass:[OLAssetsPickerController class]] ? [ALAsset class] : [PHAsset class]];
    [picker dismissViewControllerAnimated:YES completion:^(void){}];
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackPhotoProvider:@"Camera Roll" numberOfPhotosAdded:self.userSelectedPhotos.count - originalCount forProductName:self.product.productTemplate.name];
#endif
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
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.networkAccessAllowed = YES;
    [[OLImageCachingManager sharedInstance].photosCachingManager stopCachingImagesForAssets:@[asset] targetSize:PHImageManagerMaximumSize contentMode:PHImageContentModeAspectFill options:options];
}

- (void)assetsPickerController:(CTAssetsPickerController *)picker didSelectAsset:(PHAsset *)asset{
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8){
        return;
    }
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.networkAccessAllowed = YES;
    [[OLImageCachingManager sharedInstance].photosCachingManager startCachingImagesForAssets:@[asset] targetSize:PHImageManagerMaximumSize contentMode:PHImageContentModeAspectFill options:options];
}

- (BOOL)assetsPickerController:(id)picker shouldSelectAsset:(id)asset
{
    if (self.product.productTemplate.templateUI != kOLTemplateUICase && self.product.productTemplate.templateUI != kOLTemplateUIPoster && self.product.productTemplate.templateUI != kOLTemplateUIPostcard && self.product.productTemplate.templateUI != kOLTemplateUIPhotobook){
        return YES;
    }
    NSInteger max = self.product.quantityToFulfillOrder;
    
    NSMutableArray *tempUserSelected = [[NSMutableArray alloc] init];
    [tempUserSelected addObjectsFromArray:self.userSelectedPhotos];

    if ([picker respondsToSelector:@selector(selectedAssets)]){
        [self populateArrayWithNewArray:[picker selectedAssets] dataType:[asset class]];
    }
    else if ([picker respondsToSelector:@selector(selected)]){
        [self populateArrayWithNewArray:[picker selected] dataType:[asset class]];
    }
    else{ // ¯\_(ツ)_/¯
        return YES;
    }
    
    // show alert gracefully
    if (self.userSelectedPhotos.count >= max)
    {
        if ([UIAlertController class]){
            UIAlertController *alert =
            [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Maximum Photos Reached", @"")
                                                message:[NSString stringWithFormat:max == 1 ? NSLocalizedString(@"Please select only %ld photo", @"") : NSLocalizedString(@"Please select not more than %ld photos", @""), (long)max]
                                         preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *action =
            [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"")
                                     style:UIAlertActionStyleDefault
                                   handler:nil];
            
            [alert addAction:action];
            
            [picker presentViewController:alert animated:YES completion:nil];
        }
        else{
            UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Maximum Photos Reached", @"") message:[NSString stringWithFormat:max == 1 ? NSLocalizedString(@"Please select only %ld photo", @"") : NSLocalizedString(@"Please select not more than %ld photos", @""), (long)max] delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
            [av show];
        }
    }
    
    // limit selection to max
    BOOL result = (self.userSelectedPhotos.count < max);
    [self.userSelectedPhotos removeAllObjects];
    [self.userSelectedPhotos addObjectsFromArray:tempUserSelected];
    return result;
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
    [self populateArrayWithNewArray:images dataType:[OLInstagramImage class]];
    [self dismissViewControllerAnimated:YES completion:^(void){}];
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackPhotoProvider:@"Instagram" numberOfPhotosAdded:self.userSelectedPhotos.count - originalCount forProductName:self.product.productTemplate.name];
#endif
}

- (void)instagramImagePickerDidCancelPickingImages:(OLInstagramImagePickerController *)imagePicker {
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (BOOL)instagramImagePicker:(OLInstagramImagePickerController *)imagePicker shouldSelectImage:(OLInstagramImage *)image{
    return [self assetsPickerController:(id)imagePicker shouldSelectAsset:(id)image];
}
#endif

#ifdef OL_KITE_OFFER_FACEBOOK
#pragma mark - OLFacebookImagePickerControllerDelegate Methods

- (void)facebookImagePicker:(OLFacebookImagePickerController *)imagePicker didFailWithError:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)facebookImagePicker:(OLFacebookImagePickerController *)imagePicker didFinishPickingImages:(NSArray *)images {
    NSInteger originalCount = self.userSelectedPhotos.count;
    [self populateArrayWithNewArray:images dataType:[OLFacebookImage class]];
    [self dismissViewControllerAnimated:YES completion:^(void){}];
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackPhotoProvider:@"Facebook" numberOfPhotosAdded:self.userSelectedPhotos.count - originalCount forProductName:self.product.productTemplate.name];
#endif
}

- (void)facebookImagePickerDidCancelPickingImages:(OLFacebookImagePickerController *)imagePicker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)facebookImagePicker:(OLFacebookImagePickerController *)imagePicker shouldSelectImage:(OLFacebookImage *)image{
    return [self assetsPickerController:(id)imagePicker shouldSelectAsset:(id)image];
}
#endif

- (NSInteger) findFactorOf:(NSInteger)qty maximum:(NSInteger)max minimum:(NSInteger)min{
    if (qty == 1){
        return 3;
    }
    min = MAX(1, min);
    max = MAX(1, max);
    NSInteger factor = max;
    while (factor > min) {
        if (qty % factor == 0){
            return factor;
        }
        else{
            factor--;
        }
    }
    return min;
}

- (NSUInteger)numberOfCellsPerRow{
    CGSize size = self.rotationSize.width != 0 ? self.rotationSize : self.view.frame.size;
    if (self.product.quantityToFulfillOrder == 3){
        return 3;
    }
    
    if (![self isHorizontalSizeClassCompact]){
        if (size.height > size.width){
            return [self findFactorOf:self.product.quantityToFulfillOrder maximum:6 minimum:6];
        }
        else{
            return [self findFactorOf:self.product.quantityToFulfillOrder maximum:6 minimum:6];
        }
    }
    else{
        if (size.height > size.width){
            return [self findFactorOf:self.product.quantityToFulfillOrder maximum:3 minimum:3];
        }
        else{
            return [self findFactorOf:self.product.quantityToFulfillOrder maximum:6 minimum:6];
        }
    }
}

#pragma mark - UICollectionViewDataSource Methods

- (BOOL)shouldGroupPhotosInOneSection{
    return self.product.quantityToFulfillOrder == 1 && self.product.productTemplate.templateUI != kOLTemplateUIFrame;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if ([self shouldGroupPhotosInOneSection]){
        return self.userSelectedPhotos.count;
    }
    
    NSInteger number = self.product.quantityToFulfillOrder;
    NSInteger removedImagesInOtherSections = 0;
    for (NSNumber *sectionNumber in self.indexPathsToRemoveDict.allKeys){
        NSNumber *n = [NSNumber numberWithLong:[sectionNumber longValue]];
        if ([n integerValue] != section){
            removedImagesInOtherSections += [self.indexPathsToRemoveDict[n] count];
        }
    }
    NSInteger removedImagesInThisSection = [self.indexPathsToRemoveDict[[NSNumber numberWithInteger:section]] count];
    NSInteger finalNumberOfPhotosRemoved = removedImagesInThisSection + removedImagesInOtherSections;

    return MIN(MAX(self.userSelectedPhotos.count + finalNumberOfPhotosRemoved, number * [self numberOfCellsPerRow]), self.product.quantityToFulfillOrder) - removedImagesInThisSection;
}

- (NSInteger) numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    if ([self shouldGroupPhotosInOneSection]){
        return 1;
    }
    
    NSInteger removedImagesCount = 0;
    for (NSNumber *section in self.indexPathsToRemoveDict.allKeys){
        NSNumber *n = [NSNumber numberWithLong:[section longValue]];
        removedImagesCount += [self.indexPathsToRemoveDict[n] count];
    }
    NSInteger finalNumberOfPhotos = self.userSelectedPhotos.count;
    return ceil(finalNumberOfPhotos / (double)self.product.quantityToFulfillOrder);
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath{
    UICollectionReusableView *cell = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"headerView" forIndexPath:indexPath];
    cell.backgroundColor = [UIColor colorWithHexString:@"#ECEFF2"];
    
    UILabel *label = (UILabel *)[cell viewWithTag:77];
    if (!label){
        label = [[UILabel alloc] init];
        label.tag = 77;
        [cell addSubview:label];
        
        label.translatesAutoresizingMaskIntoConstraints = NO;
        NSDictionary *views = NSDictionaryOfVariableBindings(label);
        NSMutableArray *con = [[NSMutableArray alloc] init];
        
        NSArray *visuals = @[@"H:|-20-[label]-0-|",
                             @"V:|-0-[label]-0-|"];
        
        
        for (NSString *visual in visuals) {
            [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
        }
        
        [label.superview addConstraints:con];
    }
    
    NSString *title;
    OLTemplateUI templateUI = [OLProductTemplate templateWithId:self.product.templateId].templateUI;
    if (templateUI == kOLTemplateUIFrame){
        title = [[NSString alloc]initWithFormat:@"#%ld Frame", (long)indexPath.section + 1];
    }
    else if (templateUI == kOLTemplateUIPhotobook){
        title = [[NSString alloc]initWithFormat:@"#%ld Photobook", (long)indexPath.section + 1];
    }
    else if (templateUI == kOLTemplateUIPoster){
        title = [[NSString alloc]initWithFormat:@"#%ld Poster", (long)indexPath.section + 1];
    }
    else if (templateUI == kOLTemplateUIPostcard){
        title = [[NSString alloc]initWithFormat:@"#%ld Postcard", (long)indexPath.section + 1];
    }
    else{
        title = [[NSString alloc]initWithFormat:@"#%ld Pack of %lu %@", (long)indexPath.section + 1, (unsigned long)self.product.quantityToFulfillOrder, self.product.productTemplate.name];
    }
    label.text = title;
    
    return cell;
}

- (void)fixCellFrameOnIOS7:(UICollectionViewCell *)cell {
    // Ugly hack to fix cell frame on iOS 7 iPad. For whatever reason the frame size is not as per collectionView:layout:sizeForItemAtIndexPath:, others also experiencing this issue http://stackoverflow.com/questions/25804588/auto-layout-in-uicollectionviewcell-not-working
    if (SYSTEM_VERSION_LESS_THAN(@"8")) {
        [[cell contentView] setFrame:[cell bounds]];
        [[cell contentView] setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"PhotoCell";
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    
    [self fixCellFrameOnIOS7:cell];
    
    NSUInteger imageIndex = indexPath.row + indexPath.section * self.product.quantityToFulfillOrder;
    
    UILabel *qtyLabel = (UILabel *)[cell.contentView viewWithTag:50];
    if (self.userSelectedPhotos.count > imageIndex){
        NSInteger qty = [self.userSelectedPhotos[imageIndex] extraCopies];
        if (qty > 0 && self.product.productTemplate.templateUI != kOLTemplateUIFrame && self.product.productTemplate.templateUI != kOLTemplateUIPhotobook && self.product.productTemplate.templateUI != kOLTemplateUIPoster){
            qtyLabel.hidden = NO;
            qtyLabel.text = [NSString stringWithFormat:@"%ld", (long)qty+1];
        }
        else{
            qtyLabel.hidden = YES;
        }
    }
    else{
        qtyLabel.hidden = YES;
    }
    
    OLRemoteImageView *imageView = (OLRemoteImageView *) [cell.contentView viewWithTag:40];
    if (imageView != nil) {
        [imageView removeFromSuperview];
    }
    cell.contentView.backgroundColor = [UIColor whiteColor];
    imageView = [[OLRemoteImageView alloc] init];
    imageView.tag = 40;
    imageView.clipsToBounds = YES;
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [cell.contentView addSubview:imageView];
    [cell.contentView sendSubviewToBack:imageView];
    
    // Auto autolayout constraints to the cell.
    NSDictionary *views = NSDictionaryOfVariableBindings(imageView);
    NSMutableArray *con = [[NSMutableArray alloc] init];
    
    NSArray *visuals = @[@"H:|-0-[imageView]-0-|",
                         @"V:|-0-[imageView]-0-|"];
    
    for (NSString *visual in visuals) {
        [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
    }
    
    [cell.contentView addConstraints:con];
    
    imageView.image = nil;
    
    UIView *disabled = [cell.contentView viewWithTag:42];
    if (!disabled){
        disabled = [[UIView alloc] init];
        disabled.tag = 42;
        disabled.translatesAutoresizingMaskIntoConstraints = NO;
        
        [cell.contentView addSubview:disabled];
        
        // Auto autolayout constraints to the cell.
        NSDictionary *views = NSDictionaryOfVariableBindings(disabled);
        NSMutableArray *con = [[NSMutableArray alloc] init];
        
        NSArray *visuals = @[@"H:|-0-[disabled]-0-|",
                             @"V:|-0-[disabled]-0-|"];
        
        
        for (NSString *visual in visuals) {
            [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
        }
        
        [cell.contentView addConstraints:con];
        
        disabled.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.5];
    }
    
    UIImageView *checkmark = (UIImageView *) [cell.contentView viewWithTag:41];
    if (!checkmark){
        checkmark = [[UIImageView alloc] init];
        checkmark.tag = 41;
        checkmark.clipsToBounds = YES;
        checkmark.contentMode = UIViewContentModeScaleAspectFill;
        checkmark.translatesAutoresizingMaskIntoConstraints = NO;
        
        [cell.contentView addSubview:checkmark];
        
        // Auto autolayout constraints to the cell.
        NSDictionary *views = NSDictionaryOfVariableBindings(checkmark);
        NSMutableArray *con = [[NSMutableArray alloc] init];
        
        NSArray *visuals = @[@"V:|-2-[checkmark]",
                             @"H:[checkmark]-2-|"];
        
        for (NSString *visual in visuals) {
            [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
        }
        
        [cell.contentView addConstraints:con];
        
        checkmark.image = [UIImage imageNamedInKiteBundle:@"checkmark"];
        checkmark.hidden = YES;
    }
    
    NSInteger skipAtNewLine = [self numberOfCellsPerRow] % 2 == 0  && indexPath.item / [self numberOfCellsPerRow] % 2 == 0 ? 1 : 0;
    imageView.backgroundColor = (indexPath.item + skipAtNewLine) % 2 == 0 ? [UIColor colorWithHexString:@"#e6e9ed"] : [UIColor colorWithHexString:@"#dce0e5"];
    
    if (imageIndex < self.userSelectedPhotos.count) {
        OLPrintPhoto *photo = self.userSelectedPhotos[indexPath.row + indexPath.section * self.product.quantityToFulfillOrder];
        [photo setImageSize:[self collectionView:collectionView layout:collectionView.collectionViewLayout sizeForItemAtIndexPath:indexPath] cropped:YES progress:^(float progress){
            [imageView setProgress:progress];
        } completionHandler:^(UIImage *image){
            dispatch_async(dispatch_get_main_queue(), ^{
                if (image){
                    imageView.image = image;
                }
            });
        }];
        checkmark.hidden = ![self.userDisabledPhotos containsObjectIdenticalTo:photo];
        disabled.hidden = checkmark.hidden;
    } else {
        [imageView setImage:nil];
        checkmark.hidden = YES;
        disabled.hidden = YES;
    }
    
    return cell;
}

#pragma mark - UICollectionViewDelegate Methods

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    id photo;
    NSInteger photoIndex = indexPath.row + indexPath.section * self.product.quantityToFulfillOrder;
    if (photoIndex < [self.userSelectedPhotos count]){
        photo = self.userSelectedPhotos[photoIndex];
        if ([self.userDisabledPhotos containsObjectIdenticalTo:photo]){
            [self.userDisabledPhotos removeObjectIdenticalTo:photo];
        }
        else{
            [self.userDisabledPhotos addObject:photo];
        }
    }
    
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    UIImageView *checkmark = [cell viewWithTag:41];
    UIView *disabled = [cell viewWithTag:42];
    if ([self.userDisabledPhotos containsObjectIdenticalTo:photo] && photoIndex < [self.userSelectedPhotos count]){
        checkmark.hidden = NO;
        disabled.hidden = NO;
    }
    else if (photoIndex < [self.userSelectedPhotos count]){
        checkmark.hidden = YES;
        disabled.hidden = YES;
    }
    
    [self updateTitleBasedOnSelectedPhotoQuanitity];
    
    [collectionView deselectItemAtIndexPath:indexPath animated:NO];
}

- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath didMoveToIndexPath:(NSIndexPath *)toIndexPath {
    
    id object = [self.userSelectedPhotos objectAtIndex:fromIndexPath.item + fromIndexPath.section * self.product.quantityToFulfillOrder];
    [self.userSelectedPhotos removeObjectAtIndex:fromIndexPath.item + fromIndexPath.section * self.product.quantityToFulfillOrder];
    [self.userSelectedPhotos insertObject:object atIndex:toIndexPath.item + toIndexPath.section * self.product.quantityToFulfillOrder];
    
}

- (BOOL)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath canMoveToIndexPath:(NSIndexPath *)toIndexPath{
    if (toIndexPath.item >= MIN(self.userSelectedPhotos.count, (self.userSelectedPhotos.count - fromIndexPath.section * self.product.quantityToFulfillOrder))){
        return NO;
    }
    if (fromIndexPath.section != toIndexPath.section){
        return NO;
    }
    return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath{
    if ([self shouldGroupPhotosInOneSection]){
        return NO;
    }
    
    if (indexPath.item >= MIN(self.userSelectedPhotos.count, self.product.quantityToFulfillOrder)){
        return NO;
    }
    return YES;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section{
    return OLPhotoSelectionMargin;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section{
    return OLPhotoSelectionMargin;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGSize size = self.view.bounds.size;
    
    if (self.rotationSize.width != 0){
        size = self.rotationSize;
    }
    
    float numberOfCellsPerRow = [self numberOfCellsPerRow];
    CGFloat width = ceilf(size.width/numberOfCellsPerRow);
    CGFloat height = width;
    
//    if (indexPath.item % [self numberOfCellsPerRow] == 2) {
//        width = size.width - 2 * width;
//    }

    return CGSizeMake(width, height);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section{
    CGSize size = self.rotationSize.width != 0 ? self.rotationSize : self.view.frame.size;
    
    CGSize cellSize = [self collectionView:collectionView layout:collectionView.collectionViewLayout sizeForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
    CGFloat diff = size.width - (cellSize.width * [self numberOfCellsPerRow]);
    return UIEdgeInsetsMake(0, diff/2.0, 0, diff/2.0);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section{
    if ([self shouldGroupPhotosInOneSection]){
        return CGSizeZero;
    }
    else{
        return CGSizeMake(self.view.frame.size.width, 50);
    }
}

#pragma mark - Storyboard Methods

- (BOOL)shouldGoToOrderPreview {
    if (self.userDisabledPhotos.count > 0){
        [self.userDisabledPhotos removeAllObjects];
        [self updateTitleBasedOnSelectedPhotoQuanitity];
        [self.collectionView reloadData];
        return NO;
    }
    
    if (self.userSelectedPhotos.count - self.userDisabledPhotos.count == 0) {
        if ([UIAlertController class]){
            UIAlertController *av = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Oops!", @"") message:NSLocalizedString(@"Please select some images to print first.", @"") preferredStyle:UIAlertControllerStyleAlert];
            [av addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"") style:UIAlertActionStyleDefault handler:NULL]];
            [self presentViewController:av animated:YES completion:NULL];
        }
        else{
            UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Oops!", @"") message:NSLocalizedString(@"Please select some images to print first.", @"") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
            [av show];
        }
        return NO;
    } 
    
    return YES;
}

- (IBAction)onButtonNextClicked {
    if ([self shouldGoToOrderPreview]) {
        [self doSegueToOrderPreview];
    }
}

-(void)doSegueToOrderPreview{
    UIViewController* orvc = [self.storyboard instantiateViewControllerWithIdentifier:[OLKiteUtils reviewViewControllerIdentifierForProduct:self.product photoSelectionScreen:NO]];
    
    [orvc safePerformSelector:@selector(setProduct:) withObject:self.product];
    [orvc safePerformSelector:@selector(setUserSelectedPhotos:) withObject:self.userSelectedPhotos];
    [self.navigationController pushViewController:orvc animated:YES];
}

#pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == kTagAlertViewSelectMorePhotos) {
        if (buttonIndex == 1) {
            [self doSegueToOrderPreview];
        }
    }
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
