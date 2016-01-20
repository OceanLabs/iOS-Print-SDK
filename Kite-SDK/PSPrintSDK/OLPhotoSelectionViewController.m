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

#ifdef COCOAPODS
#import <UIColor-HexString/UIColor+HexString.h>
#else
#import "UIColor+HexString.h"
#endif

#import "OLPhotoSelectionViewController.h"
#import "OLPhotoSelectionButton.h"
#import "OLPrintPhoto.h"
#import "OLOrderReviewViewController.h"
#ifdef OL_KITE_OFFER_CUSTOM_IMAGE_PROVIDERS
#import "OLCustomPhotoProvider.h"
#import <KITAssetsPickerController.h>
#endif

#ifdef OL_KITE_AT_LEAST_IOS8
#import "CTAssetsPickerController.h"
#endif

#ifdef OL_KITE_OFFER_INSTAGRAM
#import <InstagramImagePicker/OLInstagramImagePickerController.h>
#import <InstagramImagePicker/OLInstagramImage.h>
#endif

#ifdef OL_KITE_OFFER_FACEBOOK
#import <FacebookImagePicker/OLFacebookImagePickerController.h>
#import <FacebookImagePicker/OLFacebookImage.h>
#endif

#import "LXReorderableCollectionViewFlowLayout.h"
#import "NSArray+QueryingExtras.h"
#import "NSObject+Utils.h"
#import "OLAddress.h"
#import "OLAnalytics.h"
#import "OLAsset.h"
#import "OLProductPrintJob.h"
#import "OLAssetsPickerController.h"
#import "OLConstants.h"
#import "OLImageCachingManager.h"
#import "OLKiteABTesting.h"
#import "OLKitePrintSDK.h"
#import "OLKiteUtils.h"
#import "OLOrderReviewViewController.h"
#import "OLPhotoSelectionButton.h"
#import "OLPhotoSelectionViewController.h"
#import "OLPrintJob.h"
#import "OLPrintPhoto.h"
#import "OLProductPrintJob.h"
#import "OLRemoteImageView.h"
#import "UIImage+ImageNamedInKiteBundle.h"
#import "UIViewController+OLMethods.h"
#import "OLPaymentViewController.h"
#import "OLImagePreviewViewController.h"
#import "UIView+RoundRect.h"
#import "UIViewController+TraitCollectionCompatibility.h"

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
#ifdef OL_KITE_OFFER_CUSTOM_IMAGE_PROVIDERS
                                            KITAssetsPickerControllerDelegate,
#endif
                                            LXReorderableCollectionViewDataSource,
                                            UICollectionViewDelegateFlowLayout,
UIViewControllerPreviewingDelegate, OLScrollCropViewControllerDelegate>

@property (assign, nonatomic) CGSize rotationSize;
@property (nonatomic, strong) OLAssetsPickerController *picker;
@property (nonatomic, weak) IBOutlet UIButton *buttonNext;
@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) IBOutlet UICollectionView *providersCollectionView;
@property (strong, nonatomic) NSMutableArray *userDisabledPhotos;
@property (strong, nonatomic) NSMutableDictionary *indexPathsToRemoveDict;
@property (strong, nonatomic) UIVisualEffectView *visualEffectView;
@property (weak, nonatomic) IBOutlet UIView *clearButtonContainerView;

@property (weak, nonatomic) OLPrintPhoto *editingPrintPhoto;
@end

@interface OLKiteViewController ()
@property (strong, nonatomic) NSMutableArray <OLCustomPhotoProvider *> *customImageProviders;
@property (strong, nonatomic) OLPrintOrder *printOrder;
- (void)dismiss;

@end

@implementation OLPhotoSelectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackPhotoSelectionScreenViewed:self.product.productTemplate.name];
#endif
    
    if ([UITraitCollection class] && [self.traitCollection respondsToSelector:@selector(forceTouchCapability)] && self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable){
        [self registerForPreviewingWithDelegate:self sourceView:self.collectionView];
    }
    
    self.providersCollectionView.delegate = self;
    self.providersCollectionView.dataSource = self;
    
    self.navigationItem.titleView = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 44)];
    [(UILabel *)self.navigationItem.titleView setTextAlignment:NSTextAlignmentCenter];
    [(UILabel *)self.navigationItem.titleView setFont:[UIFont preferredFontForTextStyle:UIFontTextStyleHeadline]];
    self.userDisabledPhotos = [[NSMutableArray alloc] init];
    
    self.rotationSize = CGSizeZero;
    
    LXReorderableCollectionViewFlowLayout *layout = (LXReorderableCollectionViewFlowLayout *)[self.collectionView collectionViewLayout];
    layout.headerReferenceSize = CGSizeMake(0, 50);
    
    if ((self.product.productTemplate.templateUI == kOLTemplateUICase || self.product.productTemplate.templateUI == kOLTemplateUIPoster || self.product.productTemplate.templateUI == kOLTemplateUIPostcard || self.product.productTemplate.templateUI == kOLTemplateUIPhotobook) && self.userSelectedPhotos.count > self.product.quantityToFulfillOrder){
        self.userSelectedPhotos = [[self.userSelectedPhotos subarrayWithRange:NSMakeRange(0, self.product.quantityToFulfillOrder)] mutableCopy];
    }
    
    [self.collectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"headerView"];
    
    [self onUserSelectedPhotoCountChange];
}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    
    self.collectionView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
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
    
    [self updateTitleBasedOnSelectedPhotoQuanitity];
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
        [(UILabel *)self.navigationItem.titleView sizeToFit];
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
        if ([object.asset isKindOfClass:[OLAsset class]] && [object.asset dataSource]){
            [array addObject:[object.asset dataSource]];
        }
        else if (![object.asset isKindOfClass:[OLAsset class]]){
            [array addObject:object.asset];
        }
    }
    return array;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    self.rotationSize = size;
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinator> context){
        [self.collectionView reloadData];
        [self.collectionView.collectionViewLayout invalidateLayout];
        [self.providersCollectionView.collectionViewLayout invalidateLayout];
    }completion:^(id<UIViewControllerTransitionCoordinator> context){
        
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    for (OLPrintPhoto *photo in self.userSelectedPhotos) {
        [photo unloadImage];
    }
}

- (UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location{
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:location];
    UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
    
    OLRemoteImageView *imageView = (OLRemoteImageView *)[cell viewWithTag:40];
    if (!imageView.image){
        return nil;
    }
    
    NSUInteger imageIndex = indexPath.row + indexPath.section * self.product.quantityToFulfillOrder;
    if (imageIndex > self.userSelectedPhotos.count){
        return nil;
    }
    
    [previewingContext setSourceRect:[cell convertRect:imageView.frame toView:self.collectionView]];
    
    self.editingPrintPhoto = self.userSelectedPhotos[indexPath.item];
    
    OLImagePreviewViewController *previewVc = [self.storyboard instantiateViewControllerWithIdentifier:@"OLImagePreviewViewController"];
    [self.editingPrintPhoto getImageWithProgress:NULL completion:^(UIImage *image){
        previewVc.image = image;
    }];
    previewVc.providesPresentationContextTransitionStyle = true;
    previewVc.definesPresentationContext = true;
    previewVc.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    return previewVc;
}

- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit{
    OLScrollCropViewController *cropVc = [self.storyboard instantiateViewControllerWithIdentifier:@"OLScrollCropViewController"];
    cropVc.enableCircleMask = self.product.productTemplate.templateUI == kOLTemplateUICircle;
    cropVc.delegate = self;
    cropVc.aspectRatio = [self productAspectRatio];
    [self.editingPrintPhoto getImageWithProgress:^(float progress){
        [cropVc.cropView setProgress:progress];
    }completion:^(UIImage *image){
        [cropVc setFullImage:image];
        cropVc.edits = self.editingPrintPhoto.edits;
        cropVc.modalPresentationStyle = [OLKiteUtils kiteVcForViewController:self].modalPresentationStyle;
        [self presentViewController:cropVc animated:YES completion:NULL];
        
#ifndef OL_NO_ANALYTICS
        [OLAnalytics trackReviewScreenEnteredCropScreenForProductName:self.product.productTemplate.name];
#endif
    }];
}

- (CGFloat) productAspectRatio{
    UIEdgeInsets b = self.product.productTemplate.imageBorder;
    if (b.top < b.bottom){ //This is for polaroids, since we don't know its pixel dims
        return 1;
    }
    else{
        return self.product.productTemplate.sizeCm.height / self.product.productTemplate.sizeCm.width;
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

#ifdef OL_KITE_OFFER_CUSTOM_IMAGE_PROVIDERS
- (void)customProviderSelected:(OLPhotoSelectionButton *)sender{
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.providersCollectionView];
    NSIndexPath *indexPath = [self.providersCollectionView indexPathForItemAtPoint:buttonPosition];
    
    KITAssetsPickerController *vc = [[KITAssetsPickerController alloc] init];
    vc.delegate = self;
    vc.collectionDataSources = [[OLKiteUtils kiteVcForViewController:self].customImageProviders[indexPath.item - [OLKiteUtils customProvidersStartIndex:self]] collections];
    vc.selectedAssets = [[self createAssetArray] mutableCopy];
    vc.modalPresentationStyle = [OLKiteUtils kiteVcForViewController:self].modalPresentationStyle;
    [self presentViewController:vc animated:YES completion:NULL];
}
#endif

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

- (BOOL)assetsPickerController:(id)picker shouldSelectAsset:(id)asset
{
    if (self.product.productTemplate.templateUI != kOLTemplateUICase && self.product.productTemplate.templateUI != kOLTemplateUIPoster && self.product.productTemplate.templateUI != kOLTemplateUIPostcard && self.product.productTemplate.templateUI != kOLTemplateUIPhotobook){
        return YES;
    }
    NSInteger max = self.product.quantityToFulfillOrder;
    
    NSMutableArray *tempUserSelected = [[NSMutableArray alloc] init];
    [tempUserSelected addObjectsFromArray:self.userSelectedPhotos];
    
    NSArray *assets;
    if ([picker respondsToSelector:@selector(selectedAssets)]){
        assets = [picker selectedAssets];
    }
    else if ([picker respondsToSelector:@selector(selected)]){
        assets = [picker selected];
    }
    else{ // ¯\_(ツ)_/¯
        return YES;
    }
    
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
    
    // show alert
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
    if (collectionView.tag == 10){
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
    else{
        NSInteger providers = 0;
        if ([OLKiteUtils cameraRollEnabled:self]){
            providers++;
        }
        if ([OLKiteUtils facebookEnabled]){
            providers++;
        }
        if ([OLKiteUtils instagramEnabled]){
            providers++;
        }
#ifdef OL_KITE_OFFER_CUSTOM_IMAGE_PROVIDERS
        providers += [OLKiteUtils kiteVcForViewController:self].customImageProviders.count;
#endif
        return providers;
    }
}

- (NSInteger) numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    if (collectionView.tag == 10){
        if ([self shouldGroupPhotosInOneSection]){
            return 1;
        }
        
        NSInteger removedImagesCount = 0;
        for (NSNumber *section in self.indexPathsToRemoveDict.allKeys){
            NSNumber *n = [NSNumber numberWithLong:[section longValue]];
            removedImagesCount += [self.indexPathsToRemoveDict[n] count];
        }
        NSInteger finalNumberOfPhotos = self.userSelectedPhotos.count;
        return MAX(ceil(finalNumberOfPhotos / (double)self.product.quantityToFulfillOrder), 1);
    }
    else{
        return 1;
    }
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath{
    if (collectionView.tag == 10){
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
    else{
        return nil;
    }
}

- (void)fixCellFrameOnIOS7:(UICollectionViewCell *)cell {
    // Ugly hack to fix cell frame on iOS 7 iPad. For whatever reason the frame size is not as per collectionView:layout:sizeForItemAtIndexPath:, others also experiencing this issue http://stackoverflow.com/questions/25804588/auto-layout-in-uicollectionviewcell-not-working
    if (SYSTEM_VERSION_LESS_THAN(@"8")) {
        [[cell contentView] setFrame:[cell bounds]];
        [[cell contentView] setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionView.tag == 10){
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
    else{
        UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"sourceCell" forIndexPath:indexPath];
        
        OLPhotoSelectionButton *button = [cell viewWithTag:11];
        [button makeRoundRectWithRadius:22];
        if (indexPath.item == [OLKiteUtils cameraRollProviderIndex:self]){
            button.image = [UIImage imageNamedInKiteBundle:@"import_gallery"];
            button.mainColor = [UIColor colorWithRed:0.227 green:0.706 blue:0.600 alpha:1.000];
            [button addTarget:self action:@selector(cameraRollSelected:) forControlEvents:UIControlEventTouchUpInside];
        }
        else if (indexPath.item == [OLKiteUtils facebookProviderIndex:self]){
            button.image = [UIImage imageNamedInKiteBundle:@"import_facebook"];
            button.mainColor = [UIColor colorWithRed:0.290 green:0.537 blue:0.863 alpha:1.000];
            [button addTarget:self action:@selector(facebookSelected:) forControlEvents:UIControlEventTouchUpInside];
        }
        else if (indexPath.item == [OLKiteUtils instagramProviderIndex:self]){
            button.image = [UIImage imageNamedInKiteBundle:@"import_instagram"];
            button.mainColor = [UIColor colorWithRed:0.965 green:0.733 blue:0.259 alpha:1.000];
            [button addTarget:self action:@selector(instagramSelected:) forControlEvents:UIControlEventTouchUpInside];
        }
#ifdef OL_KITE_OFFER_CUSTOM_IMAGE_PROVIDERS
        else{
            button.image = [[OLKiteUtils kiteVcForViewController:self].customImageProviders[indexPath.item - [OLKiteUtils customProvidersStartIndex:self]] icon];
            button.mainColor = [UIColor grayColor];
            [button addTarget:self action:@selector(customProviderSelected:) forControlEvents:UIControlEventTouchUpInside];
        }
#endif
        
        return cell;
    }
}

#pragma mark - UICollectionViewDelegate Methods

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionView.tag == 10){
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
    else{
        
    }
}

#pragma mark LXReorderableCollectionViewFlowLayoutDelegate

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

#pragma mark UICollectionViewLayoutDelegate

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section{
    if (collectionView.tag == 10){
        return OLPhotoSelectionMargin;
    }
    else{
        return 0;
    }
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section{
    if (collectionView.tag == 10){
        return OLPhotoSelectionMargin;
    }
    else{
        return 0;
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionView.tag == 10){
        CGSize size = self.view.bounds.size;
        
        if (self.rotationSize.width != 0){
            size = self.rotationSize;
        }
        
        float numberOfCellsPerRow = [self numberOfCellsPerRow];
        CGFloat width = ceilf(size.width/numberOfCellsPerRow);
        CGFloat height = width;
        
        
        return CGSizeMake(width, height);
    }
    else{
        return CGSizeMake(60, collectionView.frame.size.height);
    }
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section{
    CGSize size = self.rotationSize.width != 0 ? self.rotationSize : self.view.frame.size;
    
    if (collectionView.tag == 10){
    CGSize cellSize = [self collectionView:collectionView layout:collectionView.collectionViewLayout sizeForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
    CGFloat diff = size.width - (cellSize.width * [self numberOfCellsPerRow]);
    return UIEdgeInsetsMake(0, diff/2.0, 0, diff/2.0);
    }
    else{
        CGFloat margin = MAX((size.width - [self collectionView:collectionView numberOfItemsInSection:0] * [self collectionView:collectionView layout:collectionView.collectionViewLayout sizeForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]].width)/2.0, 0);
        return UIEdgeInsetsMake(0, margin, 0, margin);
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section{
    if (collectionView.tag == 10){
        if ([self shouldGroupPhotosInOneSection]){
            return CGSizeZero;
        }
        else{
            return CGSizeMake(self.view.frame.size.width, 50);
        }
    }
    else{
        return CGSizeZero;
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

#pragma mark - OLImageEditorViewControllerDelegate methods

- (void)scrollCropViewControllerDidCancel:(OLScrollCropViewController *)cropper{
    [cropper dismissViewControllerAnimated:YES completion:NULL];
}

-(void)scrollCropViewController:(OLScrollCropViewController *)cropper didFinishCroppingImage:(UIImage *)croppedImage{
    [self.editingPrintPhoto unloadImage];
    
    self.editingPrintPhoto.edits = cropper.edits;
    
    [self.collectionView reloadData];
    [cropper dismissViewControllerAnimated:YES completion:NULL];
    
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

@end
