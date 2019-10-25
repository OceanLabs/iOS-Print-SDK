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

#import "NSObject+Utils.h"
#import "OLAnalytics.h"
#import "OLAsset+Private.h"
#import "OLCustomPickerController.h"
#import "OLCustomViewControllerPhotoProvider.h"
#import "OLImagePickerLoginPageViewController.h"
#import "OLImagePickerPhotosPageViewController.h"
#import "OLImagePickerProvider.h"
#import "OLImagePickerProviderCollection.h"
#import "OLImagePickerViewController.h"
#import "OLKiteABTesting.h"
#import "OLKitePrintSDK.h"
#import "OLKiteUtils.h"
#import "OLProductPrintJob.h"
#import "OLQRCodeUploadViewController.h"
#import "OLUserSession.h"
#import "UIImage+ImageNamedInKiteBundle.h"
#import "UIViewController+OLMethods.h"
#import <Photos/Photos.h>
#import "OLKiteViewController+Private.h"
#import "UIView+RoundRect.h"
#import "UIColor+OLHexString.h"
#import "NSMutableArray+OLUserSelectedAssetsUtils.h"
#import "OLNavigationController.h"

@interface OLKitePrintSDK ()
+ (NSString *)instagramRedirectURI;
+ (NSString *)instagramSecret;
+ (NSString *)instagramClientID;
@end

@interface OLImagePickerViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIPageViewControllerDelegate, UIPageViewControllerDataSource, OLCustomImagePickerViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UICollectionView *sourcesCollectionView;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *nextButtonLeadingCon;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *nextButtonTrailingCon;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *nextButtonBottomCon;
@property (strong, nonatomic) UIPageViewController *pageController;
@property (strong, nonatomic) UIVisualEffectView *visualEffectView;
@property (assign, nonatomic) CGSize rotationSize;

@property (strong, nonatomic) NSArray<OLAsset *> *originalSelectedAssets;

@property (assign, nonatomic) BOOL viewWillDisappear;
@end

@implementation OLImagePickerViewController

@synthesize selectedAssets=_selectedAssets;

- (void)setSelectedAssets:(NSMutableArray<OLAsset *> *)selectedAssets{
    self.originalSelectedAssets = [[NSArray alloc] initWithArray:selectedAssets];
    
    _selectedAssets = selectedAssets;
}

- (NSMutableArray<OLAsset *> *)selectedAssets{
    if (!_selectedAssets){
        return [OLAsset userSelectedAssets];
    }
    
    return _selectedAssets;
}

- (NSUInteger)assetCount{
    NSUInteger count = 0;
    for (OLAsset *asset in self.selectedAssets){
        if (![asset isKindOfClass:[OLPlaceholderAsset class]]){
            count++;
        }
    }
    
    return count;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
    
    if (self.product){
        [OLAnalytics trackImagePickerScreenViewed:self.product.productTemplate.name];
    }
    
    if (!self.navigationController){
        [self.ctaButton removeFromSuperview];
    }
    else if (self.navigationController.viewControllers.firstObject == self && !self.overrideImagePickerMode){
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Cancel", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") style:UIBarButtonItemStylePlain target:self action:@selector(onBarButtonItemCancelTapped:)];
        [self.ctaButton removeTarget:self action:@selector(onButtonNextClicked:) forControlEvents:UIControlEventTouchUpInside];
        [self.ctaButton addTarget:self action:@selector(onButtonDoneTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.ctaButton setTitle:NSLocalizedStringFromTableInBundle(@"Done", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") forState:UIControlStateNormal];
    }
    else{
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[OLKiteABTesting sharedInstance].backButtonText
                                                                                 style:UIBarButtonItemStylePlain
                                                                                target:nil
                                                                                action:nil];
        [self.ctaButton setTitle:NSLocalizedStringFromTableInBundle(@"Next", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") forState:UIControlStateNormal];
    }
    
    if ([OLKiteABTesting sharedInstance].lightThemeColor1){
        self.ctaButton.backgroundColor = [OLKiteABTesting sharedInstance].lightThemeColor1;
    }
    UIFont *font = [[OLKiteABTesting sharedInstance] lightThemeHeavyFont1WithSize:17];
    if (!font){
        font = [[OLKiteABTesting sharedInstance] lightThemeFont1WithSize:17];
    }
    if (font){
        [self.ctaButton.titleLabel setFont:font];
    }
    
    NSNumber *cornerRadius = [OLKiteABTesting sharedInstance].lightThemeButtonRoundCorners;
    if (cornerRadius){
        [self.ctaButton makeRoundRectWithRadius:[cornerRadius floatValue]];
    } else {
        [self.ctaButton makeRoundRectWithRadius:10];
    }
    
    if ([OLUserSession currentSession].capitalizeCtaTitles){
        [self.ctaButton setTitle:[[self.ctaButton titleForState:UIControlStateNormal] uppercaseString] forState:UIControlStateNormal];
    }
    
    NSMutableArray<OLImagePickerProvider *> *providers = [[NSMutableArray<OLImagePickerProvider *> alloc] init];
    self.providers = providers;
    [self setupProviders];
    [self updateRecentsWith:[OLUserSession currentSession].recentPhotos];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
        
    self.sourcesCollectionView.delegate = self;
    self.sourcesCollectionView.dataSource = self;
    
    self.pageController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    self.pageController.delegate = self;
    self.pageController.dataSource = self;
    [self.pageController setViewControllers:@[[self viewControllerAtIndex:0]] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:NULL];
    [self addChildViewController:self.pageController];
    [self.containerView addSubview:self.pageController.view];
    
    for (UIView *view in self.pageController.view.subviews) {
        if ([view isKindOfClass:[UIScrollView class]]) {
            [(UIScrollView *)view setDelegate:self];
        }
    }
    
    UIView *view = self.pageController.view;
    view.translatesAutoresizingMaskIntoConstraints = NO;
    NSDictionary *views = NSDictionaryOfVariableBindings(view);
    NSMutableArray *con = [[NSMutableArray alloc] init];
    
    NSArray *visuals = @[@"H:|-0-[view]-0-|",
                         @"V:|-0-[view]-0-|"];
    
    
    for (NSString *visual in visuals) {
        [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
    }
    
    [view.superview addConstraints:con];
    
    self.sourcesCollectionView.backgroundColor = [UIColor whiteColor];
    
    if (self.maximumPhotos == 0 && self.minimumPhotos == 0){
        if (self.product.productTemplate.templateUI == OLTemplateUIDoubleSided){
            self.maximumPhotos = 2;
            self.minimumPhotos = 2;
        } else if (self.product.productTemplate.templateUI == OLTemplateUIPhotobook) {
            self.maximumPhotos = 70;
            self.minimumPhotos = 20;
        }
    }
    else if (self.maximumPhotos == 1){
        self.title = NSLocalizedStringFromTableInBundle(@"Choose Photo", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"");
    }
    
    if ([self assetCount] > self.maximumPhotos && self.maximumPhotos != 0){
        NSArray *maxSelected = [self.selectedAssets subarrayWithRange:NSMakeRange(0, self.maximumPhotos)];
        [self.selectedAssets removeAllObjects];
        [self.selectedAssets addObjectsFromArray:maxSelected];
    }
    
    [self updateTitleBasedOnSelectedPhotoQuanitity];
    
    if ((self.product.productTemplate.templateUI == OLTemplateUICalendar || self.product.productTemplate.templateUI == OLTemplateUIDoubleSided || self.product.productTemplate.templateUI == OLTemplateUIPoster) && self.maximumPhotos == 0){
        self.maximumPhotos = self.product.quantityToFulfillOrder;
    }
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    self.viewWillDisappear = NO;
    
    if (self.navigationController.viewControllers.firstObject != self){
        [self addBasketIconToTopRight];
    }
    
    [self updateTitleBasedOnSelectedPhotoQuanitity];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    self.viewWillDisappear = YES;
}

- (void)setupLibraryProviderAtIndex:(NSInteger)index{
    if (![OLKiteUtils cameraRollEnabled]){
        return;
    }
    
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    options.wantsIncrementalChangeDetails = NO;
    options.includeHiddenAssets = NO;
    options.includeAllBurstAssets = NO;
    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
    if ([options respondsToSelector:@selector(setIncludeAssetSourceTypes:)]){
        options.includeAssetSourceTypes = PHAssetSourceTypeCloudShared | PHAssetSourceTypeUserLibrary | PHAssetSourceTypeiTunesSynced;
    }
    options.predicate = [NSPredicate predicateWithFormat:@"mediaType = %d",PHAssetMediaTypeImage];
    
    PHAssetCollection *userLibraryCollection = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil].firstObject;
    PHFetchResult *fetchedPhotos = [PHAsset fetchAssetsInAssetCollection:userLibraryCollection options:options];
    OLImagePickerProviderCollection *userLibraryProviderCollection = [[OLImagePickerProviderCollection alloc] initWithPHFetchResult:fetchedPhotos name:userLibraryCollection.localizedTitle];
    
    OLImagePickerProvider *provider = [[OLImagePickerProvider alloc] initWithCollections:@[userLibraryProviderCollection] name:NSLocalizedStringFromTableInBundle(@"Photo Library", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") icon:[UIImage imageNamedInKiteBundle:@"import_gallery"]];
    provider.providerType = OLImagePickerProviderTypePhotoLibrary;
    [(NSMutableArray *)self.providers insertObject:provider atIndex:index];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray *assetCollections = [[NSMutableArray alloc] init];
        PHFetchResult *result = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumFavorites options:nil];
        for (PHAssetCollection *collection in result){
            [assetCollections addObject:collection];
        }
        result = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumSelfPortraits options:nil];
        for (PHAssetCollection *collection in result){
            [assetCollections addObject:collection];
        }
        result = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumRecentlyAdded options:nil];
        for (PHAssetCollection *collection in result){
            [assetCollections addObject:collection];
        }
        result = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumPanoramas options:nil];
        for (PHAssetCollection *collection in result){
            [assetCollections addObject:collection];
        }
        result = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumScreenshots options:nil];
        for (PHAssetCollection *collection in result){
            [assetCollections addObject:collection];
        }
        result = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAny options:nil];
        for (PHAssetCollection *collection in result){
            [assetCollections addObject:collection];
        }
        
        NSMutableArray<OLImagePickerProviderCollection *> *collections = [[NSMutableArray alloc] init];
        for (PHAssetCollection *fetchedCollection in assetCollections){
            PHFetchResult *fetchedPhotos = [PHAsset fetchAssetsInAssetCollection:fetchedCollection options:options];
            if (fetchedPhotos.count == 0){
                continue;
            }
            OLImagePickerProviderCollection *collection = [[OLImagePickerProviderCollection alloc] initWithPHFetchResult:fetchedPhotos name:fetchedCollection.localizedTitle];
            [collections addObject:collection];
        }
        
        [provider.collections addObjectsFromArray:collections];
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.pageController.viewControllers.firstObject isKindOfClass:[OLImagePickerPhotosPageViewController class]]){
                [[self.pageController.viewControllers.firstObject albumsCollectionView] reloadData];
            }
        });
    });
    
    if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusNotDetermined){
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status){
            if (status == PHAuthorizationStatusAuthorized){
                for (OLImagePickerProvider *provider in self.providers){
                    if (provider.providerType == OLImagePickerProviderTypePhotoLibrary){
                        NSInteger providerIndex = [self.providers indexOfObjectIdenticalTo:provider];
                        [self.providers removeObjectAtIndex:providerIndex];
                        [self setupLibraryProviderAtIndex:providerIndex];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self reloadPageController];
                        });
                        break;
                    }
                }
            }
        }];
    }
}

- (void)setupRecentsProvider{
    if (([OLUserSession currentSession].appAssets.count == 0 && [OLUserSession currentSession].recentPhotos.count == 0) || [OLUserSession currentSession].kiteVc.disableRecents){
        return;
    }
    
    OLImagePickerProviderCollection *collection = [[OLImagePickerProviderCollection alloc] initWithArray:[OLUserSession currentSession].appAssets name:NSLocalizedStringFromTableInBundle(@"All Photos", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"")];
    
    OLImagePickerProvider *provider = [[OLImagePickerProvider alloc] initWithCollections:@[collection] name:NSLocalizedStringFromTableInBundle(@"Recents", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Recent photos used") icon:[UIImage imageNamedInKiteBundle:@"bookmark"]];
    provider.providerType = OLImagePickerProviderTypeRecents;
    [self.providers addObject:provider];
}

- (void)setupCustomProviders{
    for (OLImagePickerProvider *customProvider in [OLUserSession currentSession].kiteVc.customImageProviders){
        if ([customProvider isKindOfClass:[OLCustomViewControllerPhotoProvider class]]){
            customProvider.providerType = OLImagePickerProviderTypeViewController;
            [self.providers addObject:customProvider];
            
            //When editing a job from basket, add the assets
            if ([self isExclusiveCustomViewControllerProvider] && [self overrideImagePickerMode]){
                [customProvider.collections.firstObject addAssets:[OLAsset userSelectedAssets].nonPlaceholderAssets unique:YES];
            }
        }
        else{
            NSMutableArray *collections = [[NSMutableArray alloc] init];
            for (OLImagePickerProviderCollection *collection in customProvider.collections){
                NSMutableArray *assets = [[NSMutableArray alloc] init];
                for (OLAsset *asset in collection){
                    [assets addObject:asset];
                }
                
                [collections addObject:[[OLImagePickerProviderCollection alloc] initWithArray:assets name:collection.name]];
            }
            OLImagePickerProvider *provider = [[OLImagePickerProvider alloc] initWithCollections:collections name:customProvider.name icon:customProvider.icon];
            provider.providerType = OLImagePickerProviderTypeCustom;
            [self.providers addObject:provider];
        }
    }
}

- (void)setupQRCodeProvider{
    if ([OLKiteUtils qrCodeUploadEnabled]){
        OLImagePickerProviderCollection *emptyCollection = [[OLImagePickerProviderCollection alloc] initWithArray:@[] name:@"QR Code Upload"];
        OLImagePickerProvider *provider = [[OLImagePickerProvider alloc] initWithCollections:@[emptyCollection] name:NSLocalizedStringFromTableInBundle(@"Your Phone", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Device, not number") icon:[UIImage imageNamedInKiteBundle:@"case-options"]];
        provider.providerType = OLImagePickerProviderTypeQRCode;
        [self.providers addObject:provider];
    }
}

- (void)setupProviders{
    [self setupRecentsProvider];
    [self setupLibraryProviderAtIndex:self.providers.count];
    [self setupCustomProviders];
    [self setupQRCodeProvider];
    
    if ([self isExclusiveCustomViewControllerProvider]){
        CGFloat height = 50;
        [self.sourcesCollectionView.superview removeFromSuperview];
        self.sourcesCollectionView = nil;
        self.nextButtonLeadingCon.constant = height + 10;
        self.nextButtonTrailingCon.constant = 5;
        self.nextButtonBottomCon.constant = 5;
        
        UIColor *color;
        if ([OLKiteABTesting sharedInstance].lightThemeColor2){
            color = [OLKiteABTesting sharedInstance].lightThemeColor2;
        }
        else{
            color = [UIColor colorWithRed:0.302 green:0.643 blue:0.682 alpha:1.000];
        }
        
        UIButton *addButton = [[UIButton alloc] init];
        [addButton addTarget:self action:@selector(onButtonAddClicked) forControlEvents:UIControlEventTouchUpInside];
        [addButton setBackgroundColor:color];
        [self.ctaButton.superview addSubview:addButton];
        addButton.translatesAutoresizingMaskIntoConstraints = NO;
        NSDictionary *views = NSDictionaryOfVariableBindings(addButton);
        NSMutableArray *con = [[NSMutableArray alloc] init];
        
        NSArray *visuals = @[[NSString stringWithFormat:@"H:|-5-[addButton(%f)]", height],
                             [NSString stringWithFormat:@"V:[addButton(%f)]", height]];
        
        for (NSString *visual in visuals) {
            [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
        }
        
        [addButton.superview addConstraints:con];
        [addButton.superview addConstraint:[NSLayoutConstraint constraintWithItem:addButton attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.ctaButton attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
        
        UILabel *label = [[UILabel alloc] init];
        label.text = @"+";
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:36];
        [addButton addSubview:label];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        [label.superview addConstraint:[NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:label.superview attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
        [label.superview addConstraint:[NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:label.superview attribute:NSLayoutAttributeCenterY multiplier:1 constant:-2]];
    }
}

- (void)onButtonAddClicked{
    [self presentExternalViewControllerForProvider:self.providers.firstObject];
}

- (BOOL)isExclusiveCustomViewControllerProvider{
    return self.providers.count == 1 && self.providers.firstObject.providerType == OLImagePickerProviderTypeViewController;
}

- (void)updateTopConForVc:(UIViewController *)vc{
    if ([vc isKindOfClass:[OLImagePickerPhotosPageViewController class]]){
        if (self.viewWillDisappear && !self.navigationController){
            return;
        }
        ((OLImagePickerPhotosPageViewController *)vc).albumLabelContainerTopCon.constant = self.sourcesCollectionView.frame.size.height;
        
        CGFloat offset = self.sourcesCollectionView.frame.size.height + ((OLImagePickerPhotosPageViewController *)vc).albumLabelContainer.frame.size.height;
        
        if ([[[UIDevice currentDevice] systemVersion] floatValue] < 11.0){
            offset += [[UIApplication sharedApplication] statusBarFrame].size.height + self.navigationController.navigationBar.frame.size.height;
            ((OLImagePickerPhotosPageViewController *)vc).albumLabelContainerTopCon.constant += [[UIApplication sharedApplication] statusBarFrame].size.height + self.navigationController.navigationBar.frame.size.height;
        }
        
        ((OLImagePickerPhotosPageViewController *)vc).collectionView.contentInset = UIEdgeInsetsMake(offset, 0, 70, 0);
        ((OLImagePickerPhotosPageViewController *)vc).collectionView.contentOffset = CGPointMake(0, -offset);
        ((OLImagePickerPhotosPageViewController *)vc).albumsContainerHeight.constant = self.view.frame.size.height;
    }
    else if ([vc isKindOfClass:[OLImagePickerLoginPageViewController class]]){
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 11.0){
            [(OLImagePickerLoginPageViewController *)vc labelTopConstraint].constant = self.sourcesCollectionView.frame.size.height + 20;
        }
    }
    else{
        ((OLImagePickerPhotosPageViewController *)vc).albumLabelContainerTopCon.constant = [[UIApplication sharedApplication] statusBarFrame].size.height + self.navigationController.navigationBar.frame.size.height + 10;
    }
}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    
    [self updateTopConForVc:self.pageController.viewControllers.firstObject];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    self.rotationSize = size;
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinator> context){
        [self.sourcesCollectionView.collectionViewLayout invalidateLayout];
        [self addBasketIconToTopRight];
    }completion:^(id<UIViewControllerTransitionCoordinator> context){
        [self.sourcesCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:[self.pageController.viewControllers.firstObject pageIndex] inSection:0] atScrollPosition:UICollectionViewScrollPositionNone animated:YES];
    }];
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView{
    OLImagePickerPhotosPageViewController *vc = self.pageController.viewControllers.firstObject;
    if ([vc isKindOfClass:[OLImagePickerPhotosPageViewController class]]){
        [[vc collectionView] scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionTop animated:YES];
    }
    
    return YES;
}

#pragma mark Asset Management

- (void)updateTitleBasedOnSelectedPhotoQuanitity {
    if ([self assetCount] == 0) {
        self.title = NSLocalizedStringFromTableInBundle(@"Choose Photos", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"");
    } else {
        if (self.maximumPhotos > 0){
            self.title = [NSString stringWithFormat:@"%lu / %lu", (unsigned long)[self assetCount] + [self totalNumberOfExtras], (unsigned long)self.maximumPhotos];
        }
        else if (self.product.quantityToFulfillOrder > 1){
            NSUInteger numOrders = 1 + (MAX(0, [self assetCount] - 1 + [self totalNumberOfExtras]) / self.product.quantityToFulfillOrder);
            if (![self.product isMultipack]){
                numOrders = 1;
            }
            NSUInteger quantityToFulfilOrder = numOrders * self.product.quantityToFulfillOrder;
            self.title = [NSString stringWithFormat:@"%lu / %lu", (unsigned long)[self assetCount] + [self totalNumberOfExtras], (unsigned long)quantityToFulfilOrder];
        }
        else{
            self.title = [NSString stringWithFormat:@"%lu", (unsigned long)[self assetCount]];
        }
    }
}

-(NSUInteger) totalNumberOfExtras{
    if (self.product.productTemplate.templateUI == OLTemplateUIFrame || self.product.productTemplate.templateUI == OLTemplateUICalendar || self.product.productTemplate.templateUI == OLTemplateUIPoster || self.product.productTemplate.templateUI == OLTemplateUIPhotobook){
        return 0;
    }
    
    NSUInteger res = 0;
    for (OLAsset *photo in self.selectedAssets){
        res += photo.extraCopies;
    }
    return res;
}

#pragma mark PageViewController

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController{
    return [self viewControllerAtIndex:[(OLImagePickerPhotosPageViewController *)viewController pageIndex] + 1];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController{
    return [self viewControllerAtIndex:[(OLImagePickerPhotosPageViewController *)viewController pageIndex] - 1];
}

- (void)reloadPageController{
    if (!self.pageController){
        return;
    }
    [self.pageController setViewControllers:@[[self viewControllerAtIndex:[self.pageController.viewControllers.firstObject pageIndex]]] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:NULL];
}

- (UIViewController *)viewControllerAtIndex:(NSInteger)index{
    if(index < 0 || index >= self.providers.count){
        return nil;
    }
        
    OLImagePickerPageViewController *vc;
    
    if (self.providers[index].providerType == OLImagePickerProviderTypePhotoLibrary && [PHPhotoLibrary authorizationStatus] != PHAuthorizationStatusAuthorized){
        vc = [self.storyboard instantiateViewControllerWithIdentifier:@"OLImagePickerLoginPageViewController"];
        vc.pageIndex = index;
    }
    else{
        vc = [self.storyboard instantiateViewControllerWithIdentifier:@"OLImagePickerPhotosPageViewController"];
        vc.pageIndex = index;
        ((OLImagePickerPhotosPageViewController *)vc).quantityPerItem = self.product.quantityToFulfillOrder;
    }
    vc.imagePicker = self;
    vc.provider = self.providers[index];
    [vc.view class]; //force view did load
    [self updateTopConForVc:vc];
    
    return vc;
}

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray<UIViewController *> *)previousViewControllers transitionCompleted:(BOOL)completed{
    [self.sourcesCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:[pageViewController.viewControllers.firstObject pageIndex] inSection:0] atScrollPosition:UICollectionViewScrollPositionNone animated:YES];
    self.ctaButton.hidden = NO;
    ((OLImagePickerPageViewController *)(self.pageController.viewControllers.firstObject)).ctaButton.hidden = YES;
    [self updateSelectedProviderColor];
}

#pragma mark Custom VC

- (void)presentExternalViewControllerForProvider:(OLImagePickerProvider *)provider{
    if (provider.providerType == OLImagePickerProviderTypeQRCode){
        OLQRCodeUploadViewController *vc = (OLQRCodeUploadViewController *) [[UIStoryboard storyboardWithName:@"OLKiteStoryboard" bundle:[OLKiteUtils kiteResourcesBundle]] instantiateViewControllerWithIdentifier:@"OLQRCodeUploadViewController"];
        vc.modalPresentationStyle = UIModalPresentationFormSheet;
        vc.delegate = self;
        vc.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Cancel", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") style:UIBarButtonItemStylePlain target:vc action:@selector(onBarButtonItemCancelTapped:)];
        OLNavigationController *nvc = [[OLNavigationController alloc] initWithRootViewController:vc];
        [self presentViewController:nvc animated:YES completion:nil];
        
        self.providerForPresentedVc = provider;
    }
    else if (provider.providerType == OLImagePickerProviderTypeViewController && [provider isKindOfClass:[OLCustomViewControllerPhotoProvider class]]){
        UIViewController<OLCustomPickerController> *vc = [(OLCustomViewControllerPhotoProvider *)provider vc];
        if (!vc){
            vc = [[OLUserSession currentSession].kiteVc.delegate imagePickerViewControllerForName:provider.name];
        }
        vc.delegate = self;
        [vc safePerformSelector:@selector(setSelectedAssets:) withObject:[self.selectedAssets mutableCopy]];
        [vc safePerformSelector:@selector(setProductId:) withObject:self.product.templateId];
        if ([vc respondsToSelector:@selector(setMinimumPhotos:)]){
            vc.minimumPhotos = self.product.quantityToFulfillOrder;
        }
        if ([vc respondsToSelector:@selector(setMaximumPhotos:)]){
            NSInteger maximumPhotos = 0;
            if (self.product.productTemplate.templateUI == OLTemplateUICase || self.product.productTemplate.templateUI == OLTemplateUICalendar || self.product.productTemplate.templateUI == OLTemplateUIPoster || self.product.productTemplate.templateUI == OLTemplateUIPhotobook || self.product.productTemplate.templateUI == OLTemplateUIApparel || self.product.productTemplate.templateUI == OLTemplateUIDoubleSided){
                maximumPhotos = self.product.quantityToFulfillOrder;
            }
            vc.maximumPhotos = maximumPhotos;
        }
        
        [self presentViewController:vc animated:YES completion:nil];
        self.providerForPresentedVc = provider;
    }
}

- (void)assetsPickerControllerDidCancel:(UIViewController *)picker{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)assetsPickerController:(UIViewController *)picker didFinishPickingAssets:(NSArray<OLAsset *> *)assets{
    //Check that the objects are OLAssets
    NSMutableArray *validAssets = [[NSMutableArray alloc] initWithArray:assets];
    for (id obj in assets){
        if (![obj isKindOfClass:[OLAsset class]]){
            [validAssets removeObjectIdenticalTo:obj];
        }
    }
    for (OLAsset *asset in [self.providerForPresentedVc.collections.firstObject copy]){
        if (![validAssets containsObject:asset]){
            [self.providerForPresentedVc.collections.firstObject removeAsset:asset];
            [self.selectedAssets removeObject:asset];
        }
    }
    [self.providerForPresentedVc.collections.firstObject addAssets:validAssets unique:YES];
    for (OLAsset *asset in validAssets){
        if(self.maximumPhotos == 0 || [self assetCount] < self.maximumPhotos){
            if (![self.selectedAssets containsObject:asset]){
                [self.selectedAssets addObject:asset];
            }
        }
    }
    [self reloadPageController];
    [self updateTitleBasedOnSelectedPhotoQuanitity];
    if ([[self.ctaButton actionsForTarget:self forControlEvent:UIControlEventTouchUpInside].firstObject isEqualToString:@"onButtonNextClicked:"]){
        [picker dismissViewControllerAnimated:YES completion:NULL];
    }
    else{
        [self onButtonDoneTapped:nil];
    }
}

#pragma mark CollectionView

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"sourceCell" forIndexPath:indexPath];
    
    UIImageView *imageView = [cell viewWithTag:10];
    UILabel *label = [cell viewWithTag:20];
    imageView.image = self.providers[indexPath.item].icon;
    label.text = self.providers[indexPath.item].name;
    
    UIFont *font = [[OLKiteABTesting sharedInstance] lightThemeFont1WithSize:12];
    if (font){
        label.font = font;
    }
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.item == [self.pageController.viewControllers.firstObject pageIndex]){
        [(UIImageView *)[cell viewWithTag:10] setTintColor:[UIColor blackColor]];
        [(UILabel *)[cell viewWithTag:20] setTextColor:[UIColor blackColor]];
    }
    else{
        [(UIImageView *)[cell viewWithTag:10] setTintColor:[UIColor colorWithHexString:@"7E7E7E"]];
        [(UILabel *)[cell viewWithTag:20] setTextColor:[UIColor colorWithHexString:@"7E7E7E"]];
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.providers.count;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(110, collectionView.frame.size.height);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section{
    
    CGFloat margin = MAX((collectionView.frame.size.width - ([self collectionView:collectionView layout:collectionView.collectionViewLayout sizeForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:section]].width * [self collectionView:collectionView numberOfItemsInSection:section] + [self collectionView:collectionView layout:collectionViewLayout minimumLineSpacingForSectionAtIndex:section] * ([self collectionView:collectionView numberOfItemsInSection:section]-1)))/2.0, 0);
    return UIEdgeInsetsMake(0, margin, 0, margin);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section{
    return 0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section{
    return 0;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    NSInteger currentPageIndex = [self.pageController.viewControllers.firstObject pageIndex];
    UIViewController *showingVc = self.pageController.viewControllers.firstObject;
    if (currentPageIndex == indexPath.item){
        if ([showingVc isKindOfClass:[OLImagePickerPhotosPageViewController class]]){
            [(OLImagePickerPhotosPageViewController *)showingVc closeAlbumsDrawer];
        }
        return;
    }
    
    
    UIViewController *vc = [self viewControllerAtIndex:indexPath.item];
    
    __weak OLImagePickerViewController *welf = self;
    [self.pageController setViewControllers:@[vc] direction:currentPageIndex < indexPath.item ? UIPageViewControllerNavigationDirectionForward : UIPageViewControllerNavigationDirectionReverse animated:YES completion:^(BOOL finished){
        [welf updateSelectedProviderColor];        
    }];
}

- (void)updateSelectedProviderColor{
    UICollectionViewCell *cell = [self.sourcesCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:[self.pageController.viewControllers.firstObject pageIndex] inSection:0]];
    
    if (cell){
        NSMutableArray *grayCells = [[NSMutableArray alloc] init];
        for (UICollectionViewCell *grayCell in self.sourcesCollectionView.visibleCells){
            if (grayCell != cell){
                [grayCells addObject:grayCell];
            }
        }
        
        [UIView animateWithDuration:0.15 animations:^{
            [(UIImageView *)[cell viewWithTag:10] setTintColor:[UIColor blackColor]];
            [(UILabel *)[cell viewWithTag:20] setTextColor:[UIColor blackColor]];
            
            for (UICollectionViewCell *cell in grayCells){
                [(UIImageView *)[cell viewWithTag:10] setTintColor:[UIColor colorWithHexString:@"7E7E7E"]];
                [(UILabel *)[cell viewWithTag:20] setTextColor:[UIColor colorWithHexString:@"7E7E7E"]];
            }
        }];
    }
}

#pragma mark Navigation

- (BOOL)shouldGoToOrderPreview {
    NSString *errorMessage;
    if ([self assetCount] == 0){
        errorMessage = NSLocalizedStringFromTableInBundle(@"Please select some images.", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"");
    }
    else if ([self assetCount] < self.minimumPhotos && self.minimumPhotos == self.maximumPhotos){
        errorMessage = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Please select %d images.", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Please select [number] images"), self.minimumPhotos];
    }
    else if ([self assetCount] < self.minimumPhotos){
        errorMessage = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Please select at least %d images.", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Please select at least [number] images"), self.minimumPhotos];
    }
    else if (![self.product isMultipack] && [self assetCount] > self.maximumPhotos && self.maximumPhotos != 0){
        errorMessage = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Please select no more than %d images.", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Please select no more than [number] images"), self.maximumPhotos];
    }
    if (errorMessage) {
        UIAlertController *av = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTableInBundle(@"Oops!", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") message:errorMessage preferredStyle:UIAlertControllerStyleAlert];
        [av addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"OK", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Acknowledgent to an alert dialog.") style:UIAlertActionStyleDefault handler:NULL]];
        [self presentViewController:av animated:YES completion:NULL];
        return NO;
    }
    
    return YES;
}

- (void)updateRecentsWith:(NSArray *)assets{
    for (OLAsset *asset in assets){
        if (![[OLUserSession currentSession].recentPhotos containsAssetIgnoringEdits:asset]){
            [[OLUserSession currentSession].recentPhotos addObject:asset];
        }
    }
    
    for (OLImagePickerProvider *provider in self.providers){
        if (provider.providerType == OLImagePickerProviderTypeRecents){
            [provider.collections.firstObject addAssets:[OLUserSession currentSession].recentPhotos unique:YES];
        }
    }
}

- (IBAction)onButtonNextClicked:(UIButton *)sender {
    if ([self shouldGoToOrderPreview]) {
        [self updateRecentsWith:[OLAsset userSelectedAssets].nonPlaceholderAssets];
        
        for (OLAsset *asset in [OLAsset userSelectedAssets]){
            if ([asset isEdited]){
                [asset unloadImage];
            }
        }
        [self showOrderPreview];
    }
}

- (void)showOrderPreview{
    UIViewController* orvc = [[OLUserSession currentSession].kiteVc reviewViewControllerForProduct:self.product photoSelectionScreen:NO];
    
    [orvc safePerformSelector:@selector(setProduct:) withObject:self.product];
    [self.navigationController pushViewController:orvc animated:YES];
}

- (void)onBarButtonItemCancelTapped:(UIBarButtonItem *)sender{
    [self.selectedAssets removeAllObjects];
    [self.selectedAssets addObjectsFromArray:self.originalSelectedAssets];
    
    if ([self.delegate respondsToSelector:@selector(imagePickerDidCancel:)]){
        [self.delegate imagePickerDidCancel:self];
    }
    else{
        [self dismissViewControllerAnimated:YES completion:NULL];
    }
}

- (void)onButtonDoneTapped:(UIButton *)sender{
    NSMutableArray *removedAssets = [[NSMutableArray alloc] initWithArray:self.originalSelectedAssets];
    [removedAssets removeObjectsInArray:self.selectedAssets];
    
    NSMutableArray *addedAssets = [[NSMutableArray alloc] initWithArray:self.selectedAssets];
    [addedAssets removeObjectsInArray:self.originalSelectedAssets];
    
    [self updateRecentsWith:addedAssets];
    
    if (self.addingDelegate){
        [self.addingDelegate didFinishAdding:[OLAsset photobookAssetsFromAssets:self.selectedAssets]];
    }
    else if ([self.delegate respondsToSelector:@selector(imagePicker:didFinishPickingAssets:added:removed:)]){
        [self.delegate imagePicker:self didFinishPickingAssets:self.selectedAssets added:addedAssets removed:removedAssets];
    }
    else{
        [self dismissViewControllerAnimated:YES completion:NULL];
    }
}

@synthesize addingDelegate;

@end
