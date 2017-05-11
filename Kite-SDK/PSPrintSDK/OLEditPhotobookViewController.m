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
#import "OLArtboardView.h"
#import "OLAsset+Private.h"
#import "OLCustomPickerController.h"
#import "OLCustomViewControllerPhotoProvider.h"
#import "OLEditPhotobookViewController.h"
#import "OLImageCachingManager.h"
#import "OLImageEditViewController.h"
#import "OLImagePickerViewController.h"
#import "OLInfoBanner.h"
#import "OLKiteABTesting.h"
#import "OLKiteUtils.h"
#import "OLKiteViewController+Private.h"
#import "OLNavigationController.h"
#import "OLPaymentViewController.h"
#import "OLPhotobookPageContentViewController.h"
#import "OLPhotobookViewController.h"
#import "OLImageView.h"
#import "OLUserSession.h"
#import "UIView+RoundRect.h"
#import "UIViewController+OLMethods.h"

static const NSInteger kSectionCover = 0;
static const NSInteger kSectionPages = 1;

@interface OLKitePrintSDK (InternalUtils)
+ (NSString *) instagramRedirectURI;
+ (NSString *) instagramSecret;
+ (NSString *) instagramClientID;
@end

@interface OLEditPhotobookViewController () <UICollectionViewDelegateFlowLayout, OLPhotobookViewControllerDelegate, OLImageViewDelegate, UINavigationControllerDelegate, OLImagePickerViewControllerDelegate, UIPopoverPresentationControllerDelegate, OLInfoBannerDelegate, OLArtboardDelegate>

@property (assign, nonatomic) BOOL animating;
@property (assign, nonatomic) BOOL haveCachedCells;
@property (assign, nonatomic) BOOL rotating;
@property (assign, nonatomic) NSInteger addNewPhotosAtIndex;
@property (assign, nonatomic) NSInteger longPressImageIndex;
@property (strong, nonatomic) NSNumber *selectedIndexNumber;
@property (strong, nonatomic) NSArray *userSelectedPhotosCopy;
@property (weak, nonatomic) OLPhotobookViewController *interactionPhotobook;
@property (strong, nonatomic) UIButton *ctaButton;
@property (strong, nonatomic) OLImagePickerViewController *vcDelegateForCustomVc;
@property (strong, nonatomic) UIViewController *presentedVc;
@property (strong, nonatomic) OLInfoBanner *infoBanner;

@end

@implementation OLEditPhotobookViewController

- (void)setAnimating:(BOOL)animating{
    _animating = animating;
    self.collectionView.scrollEnabled = !animating;
}

- (void)viewDidLoad{
    [super viewDidLoad];
    
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackPhotobookEditScreenViewed:self.product.productTemplate.name];
#endif
    
    self.title = NSLocalizedStringFromTableInBundle(@"Move Pages", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Title of a screen that allows the user to move the pages of a book around");
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[OLKiteABTesting sharedInstance].backButtonText
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:nil
                                                                            action:nil];
    
    UIView *view = self.collectionView;
    view.translatesAutoresizingMaskIntoConstraints = NO;
    NSDictionary *views = NSDictionaryOfVariableBindings(view);
    NSMutableArray *con = [[NSMutableArray alloc] init];
    
    NSArray *visuals = @[@"H:|-0-[view]-0-|",
                         @"V:|-0-[view]-0-|"];
    
    
    for (NSString *visual in visuals) {
        [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
    }
    
    [view.superview addConstraints:con];
    
    [[OLAsset userSelectedAssets] adjustNumberOfSelectedAssetsWithTotalNumberOfAssets:self.product.quantityToFulfillOrder + 1 trim:YES];
    
    [self setupCtaButton];
    
    self.collectionView.contentInset = UIEdgeInsetsMake(self.collectionView.contentInset.top, self.collectionView.contentInset.left, self.ctaButton.frame.size.height, self.collectionView.contentInset.right);
    
    [self addInfoBanner];
}

- (void)setupCtaButton{
    self.ctaButton = [[UIButton alloc] init];
    [self.ctaButton.titleLabel setFont:[UIFont systemFontOfSize:17]];
    [self.ctaButton setTitle:NSLocalizedStringFromTableInBundle(@"Next", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") forState:UIControlStateNormal];
    [self.ctaButton addTarget:self action:@selector(onButtonNextClicked) forControlEvents:UIControlEventTouchUpInside];
    if ([OLKiteABTesting sharedInstance].lightThemeColor1){
        [self.ctaButton setBackgroundColor:[OLKiteABTesting sharedInstance].lightThemeColor1];
    }
    else{
        [self.ctaButton setBackgroundColor:[UIColor colorWithRed:0.125 green:0.498 blue:0.655 alpha:1.000]];
    }
    UIFont *font = [[OLKiteABTesting sharedInstance] lightThemeFont1WithSize:17];
    if (font){
        [self.ctaButton.titleLabel setFont:font];
    }
    NSNumber *cornerRadius = [OLKiteABTesting sharedInstance].lightThemeButtonRoundCorners;
    if (cornerRadius){
        [self.ctaButton makeRoundRectWithRadius:[cornerRadius floatValue]];
    }

    
    [self.ctaButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.ctaButton.frame = CGRectMake(5, self.view.frame.size.height - 55 - ([[UIApplication sharedApplication] statusBarFrame].size.height + self.navigationController.navigationBar.frame.size.height), self.view.frame.size.width-10, 50);
    [self.collectionView addSubview:self.ctaButton];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    
    NSInteger maxItem = -1;
    for (UICollectionViewCell *cell in [self.collectionView visibleCells]){
        NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
        if (indexPath.item > maxItem){
            maxItem = indexPath.item;
        }
    }
    if (!self.haveCachedCells && self.product.productTemplate.productRepresentation.numberOfPages > (maxItem+1) * 2){
        [self collectionView:self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:maxItem+1 inSection:kSectionPages]];
        [self collectionView:self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:maxItem+2 inSection:kSectionPages]];
        self.haveCachedCells = YES;
    }
    
    UIFont *font = [[OLKiteABTesting sharedInstance] lightThemeHeavyFont1WithSize:17];
    if (!font){
        font = [[OLKiteABTesting sharedInstance] lightThemeFont1WithSize:17];
    }
    if (font){
        [self.ctaButton.titleLabel setFont:font];
    }
    else{
        [self.ctaButton.titleLabel setFont:[UIFont systemFontOfSize:17]];
    }
    
    NSNumber *cornerRadius = [OLKiteABTesting sharedInstance].lightThemeButtonRoundCorners;
    if (cornerRadius){
        [self.ctaButton makeRoundRectWithRadius:[cornerRadius floatValue]];
    }
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    
    self.navigationItem.rightBarButtonItem.enabled = YES;
    
#ifndef OL_NO_ANALYTICS
    if (!self.navigationController){
        [OLAnalytics trackPhotobookEditScreenHitBack:self.product.productTemplate.name];
    }
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
    
    for (OLPhotobookViewController *photobook in self.childViewControllers){
        if (!photobook.bookClosed){
            for (OLPhotobookPageContentViewController *page in photobook.pageController.viewControllers){
                [page loadImageWithCompletionHandler:NULL];
            }
        }
        else{
            [photobook loadCoverPhoto];
        }
    }
}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    self.ctaButton.frame = CGRectMake(self.ctaButton.frame.origin.x, -self.ctaButton.frame.origin.x + self.view.frame.size.height - self.ctaButton.frame.size.height + self.collectionView.contentOffset.y, self.view.frame.size.width - 2 * self.ctaButton.frame.origin.x, self.ctaButton.frame.size.height);
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator{
    
    NSArray *visibleCells = [self.collectionView indexPathsForVisibleItems];
    
    if ([self.navigationController topViewController] == self && !self.presentedViewController){
        for (NSIndexPath *indexPath in visibleCells){
            UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
            UIView *clone = [cell snapshotViewAfterScreenUpdates:YES];
            clone.tag = 999;
            [cell addSubview:clone];
        }
    }
    
    self.rotating = YES;
    [self.collectionView deleteSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)]];
    for (OLPhotobookViewController *photobook in self.childViewControllers){
        [photobook.view removeFromSuperview];
        [photobook removeFromParentViewController];
    }
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinator> context){
        self.ctaButton.frame = CGRectMake(self.ctaButton.frame.origin.x, -self.ctaButton.frame.origin.x + self.view.frame.size.height - self.ctaButton.frame.size.height + self.collectionView.contentOffset.y, self.view.frame.size.width - 2 * self.ctaButton.frame.origin.x, self.ctaButton.frame.size.height);
    }completion:^(id<UIViewControllerTransitionCoordinator> context){
        self.rotating = NO;
        [self.collectionView insertSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)]];
        [self.collectionView scrollToItemAtIndexPath:visibleCells.firstObject atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
    }];
}

- (void)proceedToBookReview{
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    OLPhotobookViewController *photobook = [self.storyboard instantiateViewControllerWithIdentifier:@"PhotobookViewController"];
    [photobook loadCoverPhoto];
    photobook.product = self.product;
    
    [self.navigationController pushViewController:photobook animated:YES];
}

- (void)swapImageAtIndex:(NSInteger)index1 withImageAtIndex:(NSInteger)index2{
    [[OLAsset userSelectedAssets] exchangeObjectAtIndex:index1 withObjectAtIndex:index2];
}

- (OLPhotobookPageContentViewController *)pageControllerForPageIndex:(NSInteger)index{
    index--;
    for (OLPhotobookViewController *photobook in self.childViewControllers){
        if (photobook.bookClosed){
            continue;
        }
        for (OLPhotobookPageContentViewController *page in photobook.pageController.viewControllers){
            if (page.pageIndex == index){
                return page;
            }
        }
    }
    return nil;
}

- (void)addPageShadowsToView:(UIView *)view{
    if (self.product.productTemplate.imageBorder.top == 0 && self.product.productTemplate.imageBorder.left == 0){
        UIImage *leftImage = [UIImage imageNamed:@"page-shadow-left" inBundle:[OLKiteUtils kiteLocalizationBundle] compatibleWithTraitCollection:self.traitCollection];
        UIImage *rightImage = [UIImage imageNamed:@"page-shadow-right" inBundle:[OLKiteUtils kiteLocalizationBundle] compatibleWithTraitCollection:self.traitCollection];
        
        UIImageView *left1 = [[UIImageView alloc] initWithImage:leftImage];
        left1.contentMode = UIViewContentModeScaleToFill;
        left1.tag = 11;
        [view addSubview:left1];
        
        UIImageView *right1 = [[UIImageView alloc] initWithImage:rightImage];
        right1.contentMode = UIViewContentModeScaleToFill;
        right1.tag = 21;
        [view addSubview:right1];
        
        CGFloat shadowWidth = view.frame.size.width * 0.3;
        
        left1.frame = CGRectMake(view.frame.size.width - shadowWidth, 0, shadowWidth, view.frame.size.height);
        right1.frame = CGRectMake(0, 0, shadowWidth, view.frame.size.height);
    }
}

- (void)setPageShadowAlpha:(UIView *)view forIndex:(NSInteger)index{
    if (self.product.productTemplate.imageBorder.top == 0 && self.product.productTemplate.imageBorder.left == 0){
        if (index % 2 == 0){//LEFT
            [view viewWithTag:21].alpha = 0;
            [view viewWithTag:22].alpha = 0;
            [view viewWithTag:11].alpha = 1;
            [view viewWithTag:12].alpha = 1;
        }
        else{
            [view viewWithTag:11].alpha = 0;
            [view viewWithTag:12].alpha = 0;
            [view viewWithTag:21].alpha = 1;
            [view viewWithTag:22].alpha = 1;
        }
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    CGRect headerFrame = self.ctaButton.frame;
    headerFrame.origin.y = self.view.frame.size.height - self.ctaButton.frame.size.height + scrollView.contentOffset.y ;
    self.ctaButton.frame = headerFrame;
}

- (void)addInfoBanner{
    if ([OLUserSession currentSession].kiteVc.disableEditingTools){
        self.infoBanner = [OLInfoBanner showInfoBannerOnViewController:self withTitle:NSLocalizedStringFromTableInBundle(@"Tap image to change or hold to move", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"")];
    }
    else{
        self.infoBanner = [OLInfoBanner showInfoBannerOnViewController:self withTitle:NSLocalizedStringFromTableInBundle(@"Tap image to edit or hold to move", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"")];
    }
    self.infoBanner.delegate = self;
    self.collectionView.contentInset = UIEdgeInsetsMake(self.collectionView.contentInset.top + 50, self.collectionView.contentInset.left, self.collectionView.contentInset.bottom, self.collectionView.contentInset.right);
}

#pragma mark - User Actions

- (void)onButtonNextClicked{
    [self proceedToBookReview];
}

#pragma mark - CollectionView

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewCell *cell;
    if (indexPath.section == kSectionCover){
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"coverEditCell" forIndexPath:indexPath];
    }
    else{
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"bookPreviewCell" forIndexPath:indexPath];
    }
    
    UIView *view = [cell viewWithTag:10];
    if (!view){
        for (OLPhotobookViewController *photobook in self.childViewControllers){
            if (!photobook.view.superview){
                photobook.editingPageNumber = [NSNumber numberWithInteger:indexPath.item * 2];
                [cell addSubview:photobook.view];
                [[cell viewWithTag:999] removeFromSuperview];
                return cell;
            }
        }
        OLPhotobookViewController *photobook = [self.storyboard instantiateViewControllerWithIdentifier:@"PhotobookViewController"];
        photobook.photobookDelegate = self;
        if (indexPath.section == kSectionPages){
            photobook.startOpen = YES;
        }
        
        if (indexPath.section == kSectionCover){
            photobook.editingPageNumber = nil;
            
            [photobook loadCoverPhoto];
        }
        else{
            photobook.editingPageNumber = [NSNumber numberWithInteger:indexPath.item * 2];
        }
        
        photobook.product = self.product;
        photobook.editMode = YES;
        [self addChildViewController:photobook];
        photobook.view.alpha = 0;
        [cell addSubview:photobook.view];
        [UIView animateWithDuration:0.15 animations:^{
            photobook.view.alpha = 1;
        }];
        CGSize size = [self collectionView:collectionView layout:collectionView.collectionViewLayout sizeForItemAtIndexPath:indexPath];
        photobook.view.frame = CGRectMake(0, 0, size.width, size.height);
        photobook.view.tag = 10;
    }
    else{
        for (OLPhotobookViewController *photobook in self.childViewControllers){
            if (photobook.view == view){
                photobook.editingPageNumber = [NSNumber numberWithInteger:indexPath.item * 2];
                break;
            }
        }
    }
    [[cell viewWithTag:999] removeFromSuperview];
    return cell;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    if (section == kSectionCover){
        return 1;
    }
    else{
        return self.product.productTemplate.productRepresentation.numberOfPages / 2.0;
    }
    
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return self.rotating ? 0 : 2;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == kSectionCover){
        return CGSizeMake(self.view.frame.size.width, [self cellHeightForSize:self.view.frame.size] + 10);
    }
    else {
        return CGSizeMake(self.view.frame.size.width, [self cellHeightForSize:self.view.frame.size]);
    }
}

- (CGFloat) cellHeightForSize:(CGSize)size{
    CGFloat min = size.width; //MIN(size.width, size.height);
    return MIN((min) / (self.product.productTemplate.sizeCm.width*2 / self.product.productTemplate.sizeCm.height), (self.view.frame.size.height - ([[UIApplication sharedApplication] statusBarFrame].size.height + self.navigationController.navigationBar.frame.size.height)) * 0.9);
}

#pragma mark - Adding new images

- (void)showImagePicker{
    NSInteger max = self.product.quantityToFulfillOrder + 1; //Plus cover photo
    
    OLImagePickerViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"OLImagePickerViewController"];
    vc.selectedAssets = [[[OLAsset userSelectedAssets] nonPlaceholderAssets] mutableCopy];
    vc.delegate = self;
    vc.maximumPhotos = max;
    vc.product = self.product;
    
    if ([OLKiteUtils numberOfProvidersAvailable] <= 2 && [[OLUserSession currentSession].kiteVc.customImageProviders.firstObject isKindOfClass:[OLCustomViewControllerPhotoProvider class]]){
        //Skip the image picker and only show the custom vc
        
        self.vcDelegateForCustomVc = vc; //Keep strong reference
        vc.providerForPresentedVc = [OLUserSession currentSession].kiteVc.customImageProviders.firstObject;
        UIViewController<OLCustomPickerController> *customVc = [(OLCustomViewControllerPhotoProvider *)[OLUserSession currentSession].kiteVc.customImageProviders.firstObject vc];
        if (!customVc){
            customVc = [[OLUserSession currentSession].kiteVc.delegate imagePickerViewControllerForName:vc.providerForPresentedVc.name];
        }
        [customVc safePerformSelector:@selector(setDelegate:) withObject:vc];
        [customVc safePerformSelector:@selector(setProductId:) withObject:self.product.templateId];
        [customVc safePerformSelector:@selector(setSelectedAssets:) withObject:[[OLAsset userSelectedAssets].nonPlaceholderAssets mutableCopy]];
        if ([vc respondsToSelector:@selector(setMaximumPhotos:)]){
            vc.maximumPhotos = self.product.quantityToFulfillOrder;
        }
        
        [self presentViewController:customVc animated:YES completion:NULL];
        self.presentedVc = customVc;
        return;
    }
    
    [self presentViewController:[[OLNavigationController alloc] initWithRootViewController:vc] animated:YES completion:NULL];
}

- (void)imagePickerDidCancel:(OLImagePickerViewController *)vc{
    [vc dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imagePicker:(OLImagePickerViewController *)vc didFinishPickingAssets:(NSMutableArray *)assets added:(NSArray<OLAsset *> *)addedAssets removed:(NSArray *)removedAssets{
    [[OLAsset userSelectedAssets] updateUserSelectedAssetsAtIndex:MAX(0, self.addNewPhotosAtIndex) withAddedAssets:addedAssets removedAssets:removedAssets];
    
    if (self.addNewPhotosAtIndex == -1){
        for (OLPhotobookViewController *photobook in self.childViewControllers){
            if ([photobook bookClosed]){
                [photobook loadCoverPhoto];
                break;
            }
        }
    }

    for (OLPhotobookViewController *photobook in self.childViewControllers){
        if (!photobook.bookClosed){
            for (OLPhotobookPageContentViewController *page in photobook.pageController.viewControllers){
                [page loadImageWithCompletionHandler:NULL];
            }
        }
    }
    
    if (self.presentedVc){
        [self.presentedVc dismissViewControllerAnimated:YES completion:NULL];
    }
    else{
        [vc dismissViewControllerAnimated:YES completion:NULL];
    }
    
    self.vcDelegateForCustomVc = nil;
    self.presentedVc = nil;
    
}

#pragma mark Artboard Delegate

- (UIView *)viewToAddDraggingAsset{
    return self.view;
}

- (OLArtboardAssetView *)assetViewAtPoint:(CGPoint)point{
    CGPoint collectionViewPoint = [self.collectionView convertPoint:point fromView:[self viewToAddDraggingAsset]];
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:collectionViewPoint];
    UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
    UIView *view = [cell viewWithTag:10];
    
    for (OLPhotobookViewController *photobook in self.childViewControllers){
        if (photobook.view == view){
            return [photobook findAssetViewAtPoint:point];
        }
    }

    return nil;
}

- (UIScrollView *)scrollViewForVerticalScolling{
    return self.collectionView;
}

- (void)refreshAssetViewsWithIndexSet:(NSIndexSet *)indexSet{
    for (OLPhotobookViewController *photobook in self.childViewControllers){
        [photobook photobookRefreshAssetViewsWithIndexSet:indexSet];
    }
}

- (UIViewController *)viewControllerForPresenting{
    return self;
}

@end
