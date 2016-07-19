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
#import "OLAnalytics.h"
#import "OLEditPhotobookViewController.h"
#import "OLImageCachingManager.h"
#import "OLKiteUtils.h"
#import "OLPhotobookPageContentViewController.h"
#import "OLPhotobookViewController.h"
#import "OLPopupOptionsImageView.h"
#import "OLPrintPhoto.h"
#import "OLScrollCropViewController.h"
#import "OLUserSession.h"

#import "CTAssetsPickerController.h"

#ifdef OL_KITE_OFFER_INSTAGRAM
#import <InstagramImagePicker/OLInstagramImagePickerController.h>
#import <InstagramImagePicker/OLInstagramImage.h>
#endif

#ifdef OL_KITE_OFFER_FACEBOOK
#import <FacebookImagePicker/OLFacebookImagePickerController.h>
#import <FacebookImagePicker/OLFacebookImage.h>
#endif

#import "OLCustomPhotoProvider.h"
#ifdef COCOAPODS
#import <KITAssetsPickerController/KITAssetsPickerController.h>
#else
#import "KITAssetsPickerController.h"
#endif

#ifdef OL_KITE_OFFER_ADOBE
#import <AdobeCreativeSDKImage/AdobeCreativeSDKImage.h>
#import <AdobeCreativeSDKCore/AdobeCreativeSDKCore.h>
#endif

#import "UIViewController+OLMethods.h"

#import "OLPaymentViewController.h"

static const NSInteger kSectionCover = 0;
static const NSInteger kSectionHelp = 1;
static const NSInteger kSectionPages = 2;

@interface OLPhotobookViewController ()
@property (weak, nonatomic) UIImageView *coverImageView;
@end

@interface OLKiteViewController (Private)
@property (strong, nonatomic) NSMutableArray <OLCustomPhotoProvider *> *customImageProviders;

@end

@interface OLKitePrintSDK (InternalUtils)
#ifdef OL_KITE_OFFER_ADOBE
+ (NSString *)adobeCreativeSDKClientSecret;
+ (NSString *)adobeCreativeSDKClientID;
#endif

#ifdef OL_KITE_OFFER_INSTAGRAM
+ (NSString *) instagramRedirectURI;
+ (NSString *) instagramSecret;
+ (NSString *) instagramClientID;
#endif
@end

@interface OLEditPhotobookViewController () <UICollectionViewDelegateFlowLayout, OLPhotobookViewControllerDelegate, CTAssetsPickerControllerDelegate,
OLImageViewDelegate, OLScrollCropViewControllerDelegate,
#ifdef OL_KITE_OFFER_INSTAGRAM
OLInstagramImagePickerControllerDelegate,
#endif
#ifdef OL_KITE_OFFER_FACEBOOK
OLFacebookImagePickerControllerDelegate,
#endif
KITAssetsPickerControllerDelegate,
#ifdef OL_KITE_OFFER_ADOBE
AdobeUXImageEditorViewControllerDelegate,
#endif
UINavigationControllerDelegate>

@property (assign, nonatomic) BOOL animating;
@property (assign, nonatomic) BOOL haveCachedCells;
@property (assign, nonatomic) BOOL rotating;
@property (assign, nonatomic) NSInteger addNewPhotosAtIndex;
@property (assign, nonatomic) NSInteger longPressImageIndex;
@property (strong, nonatomic) NSNumber *replacingImageNumber;
@property (strong, nonatomic) NSNumber *selectedIndexNumber;
@property (strong, nonatomic) NSArray *userSelectedPhotosCopy;
@property (strong, nonatomic) NSMutableArray *photobookPhotos;
@property (strong, nonatomic) OLPrintPhoto *coverPhoto;
@property (weak, nonatomic) OLPhotobookViewController *interactionPhotobook;
@property (strong, nonatomic) UIButton *nextButton;
@property (assign, nonatomic) BOOL autoAddedCover;

@end

@implementation OLEditPhotobookViewController

- (void)setAnimating:(BOOL)animating{
    _animating = animating;
    self.collectionView.scrollEnabled = !animating;
}

- (void)viewDidLoad{
    [super viewDidLoad];
    
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackPhotoSelectionScreenViewed:self.product.productTemplate.name];
#endif
    
    self.title = NSLocalizedString(@"Move Pages", @"");
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", @"")
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
    
    
    [self updatePhotobookPhotos];
    
    [self setupCtaButton];
    
    self.collectionView.contentInset = UIEdgeInsetsMake(self.collectionView.contentInset.top, self.collectionView.contentInset.left, self.nextButton.frame.size.height, self.collectionView.contentInset.right);
}

- (void)setupCtaButton{
    self.nextButton = [[UIButton alloc] init];
    [self.nextButton.titleLabel setFont:[UIFont systemFontOfSize:17]];
    [self.nextButton setTitle:NSLocalizedString(@"Next", @"") forState:UIControlStateNormal];
    [self.nextButton addTarget:self action:@selector(onButtonNextClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.nextButton setBackgroundColor:[UIColor colorWithRed:0.125 green:0.498 blue:0.655 alpha:1.000]];
    [self.nextButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.nextButton.frame = CGRectMake(0, self.view.frame.size.height - 40 - ([[UIApplication sharedApplication] statusBarFrame].size.height + self.navigationController.navigationBar.frame.size.height), self.view.frame.size.width, 40);
    [self.collectionView addSubview:self.nextButton];
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
    
    if ([OLUserSession currentSession].userSelectedPhotos.count == 0 && self.childViewControllers.count > 1 && !self.coverPhoto){
        [self photobook:self.childViewControllers[1] userDidTapOnImageWithIndex:0];
    }
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    
    self.navigationItem.rightBarButtonItem.enabled = YES;
    
#ifndef OL_NO_ANALYTICS
    if (!self.navigationController){
        [OLAnalytics trackPhotoSelectionScreenHitBack:self.product.productTemplate.name];
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
            photobook.photobookPhotos = self.photobookPhotos;
            for (OLPhotobookPageContentViewController *page in photobook.pageController.viewControllers){
                [page loadImageWithCompletionHandler:NULL];
            }
        }
    }
}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    self.nextButton.frame = CGRectMake(self.nextButton.frame.origin.x, -self.nextButton.frame.origin.x + self.view.frame.size.height - self.nextButton.frame.size.height + self.collectionView.contentOffset.y, self.view.frame.size.width - 2 * self.nextButton.frame.origin.x, self.nextButton.frame.size.height);
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
    [self.collectionView deleteSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 3)]];
    for (OLPhotobookViewController *photobook in self.childViewControllers){
        [photobook.view removeFromSuperview];
        [photobook removeFromParentViewController];
    }
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinator> context){
        self.nextButton.frame = CGRectMake(self.nextButton.frame.origin.x, -self.nextButton.frame.origin.x + self.view.frame.size.height - self.nextButton.frame.size.height + self.collectionView.contentOffset.y, self.view.frame.size.width - 2 * self.nextButton.frame.origin.x, self.nextButton.frame.size.height);
    }completion:^(id<UIViewControllerTransitionCoordinator> context){
        self.rotating = NO;
        [self.collectionView insertSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 3)]];
        [self.collectionView scrollToItemAtIndexPath:visibleCells.firstObject atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
    }];
}

- (void)proceedToBookReview{
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    OLPhotobookViewController *photobook = [self.storyboard instantiateViewControllerWithIdentifier:@"PhotobookViewController"];
    photobook.coverPhoto = self.coverPhoto;
    [photobook loadCoverPhoto];
    photobook.userSelectedPhotos = [OLUserSession currentSession].userSelectedPhotos;
    photobook.photobookPhotos = self.photobookPhotos;
    photobook.product = self.product;
    photobook.delegate = self.delegate;
    
    [self.navigationController pushViewController:photobook animated:YES];
}

- (void)updatePhotobookPhotos{
    if (!self.photobookPhotos){
        self.userSelectedPhotosCopy = [[NSArray alloc] initWithArray:[OLUserSession currentSession].userSelectedPhotos copyItems:NO];
        self.photobookPhotos = [[NSMutableArray alloc] initWithCapacity:self.product.quantityToFulfillOrder];
        NSInteger start = 0;
        if (!self.coverPhoto){
            self.coverPhoto = [OLUserSession currentSession].userSelectedPhotos.firstObject;
            start++;
        }
        else if (self.coverPhoto == (id)[NSNull null]){
            self.coverPhoto = nil;
        }
        for (NSInteger i = start; i < self.product.quantityToFulfillOrder + start; i++){
            [self.photobookPhotos addObject:i < [OLUserSession currentSession].userSelectedPhotos.count ? [OLUserSession currentSession].userSelectedPhotos[i] : [NSNull null]];
        }
    }
    else{
        NSMutableArray *newPhotos = [NSMutableArray arrayWithArray:[[OLUserSession currentSession].userSelectedPhotos subarrayWithRange:NSMakeRange(0, MIN([OLUserSession currentSession].userSelectedPhotos.count, self.product.quantityToFulfillOrder+1))]];
        [newPhotos removeObjectsInArray:self.userSelectedPhotosCopy];
        for (NSInteger newPhoto = 0; newPhoto < newPhotos.count; newPhoto++){
            BOOL foundSpot = NO;
            for (NSInteger bookPhoto = self.addNewPhotosAtIndex; bookPhoto < self.photobookPhotos.count && !foundSpot; bookPhoto++){
                if (self.photobookPhotos[bookPhoto] == [NSNull null]){
                    self.photobookPhotos[bookPhoto] = newPhotos[newPhoto];
                    foundSpot = YES;
                }
            }
            for (NSInteger bookPhoto = 0; bookPhoto < self.addNewPhotosAtIndex && !foundSpot; bookPhoto++){
                if (self.photobookPhotos[bookPhoto] == [NSNull null]){
                    self.photobookPhotos[bookPhoto] = newPhotos[newPhoto];
                    foundSpot = YES;
                }
            }
        }
        self.userSelectedPhotosCopy = [[NSArray alloc] initWithArray:[OLUserSession currentSession].userSelectedPhotos copyItems:NO];
    }
    
}

- (void)swapImageAtIndex:(NSInteger)index1 withImageAtIndex:(NSInteger)index2{
    [self.photobookPhotos exchangeObjectAtIndex:index1 withObjectAtIndex:index2];
}

- (OLPhotobookPageContentViewController *)pageControllerForPageIndex:(NSInteger)index{
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
        UIImage *leftImage = [UIImage imageNamed:@"page-shadow-left" inBundle:[OLKiteUtils kiteBundle] compatibleWithTraitCollection:self.traitCollection];
        UIImage *rightImage = [UIImage imageNamed:@"page-shadow-right" inBundle:[OLKiteUtils kiteBundle] compatibleWithTraitCollection:self.traitCollection];
        
        UIImageView *left1 = [[UIImageView alloc] initWithImage:leftImage];
        left1.contentMode = UIViewContentModeScaleToFill;
        left1.tag = 11;
        //        left1.translatesAutoresizingMaskIntoConstraints = NO;
        [view addSubview:left1];
        
        //        UIImageView *left2 = [[UIImageView alloc] initWithImage:leftImage];
        //        left2.contentMode = UIViewContentModeScaleToFill;
        //        left2.tag = 12;
        //        left2.translatesAutoresizingMaskIntoConstraints = NO;
        //        [view addSubview:left2];
        
        UIImageView *right1 = [[UIImageView alloc] initWithImage:rightImage];
        right1.contentMode = UIViewContentModeScaleToFill;
        right1.tag = 21;
        //        right1.translatesAutoresizingMaskIntoConstraints = NO;
        [view addSubview:right1];
        
        //        UIImageView *right2 = [[UIImageView alloc] initWithImage:rightImage];
        //        right2.contentMode = UIViewContentModeScaleToFill;
        //        right2.tag = 22;
        //        right2.translatesAutoresizingMaskIntoConstraints = NO;
        //        [view addSubview:right2];
        
        CGFloat shadowWidth = view.frame.size.width * 0.3;
        
        left1.frame = CGRectMake(view.frame.size.width - shadowWidth, 0, shadowWidth, view.frame.size.height);
        //        left2.frame = CGRectMake(view.frame.size.width - shadowWidth, 0, shadowWidth, view.frame.size.height);
        right1.frame = CGRectMake(0, 0, shadowWidth, view.frame.size.height);
        //        right2.frame = CGRectMake(0, 0, shadowWidth, view.frame.size.height);
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

- (void)updateUserSelectedPhotos{
    [[OLUserSession currentSession].userSelectedPhotos removeAllObjects];
    for (OLPrintPhoto *item in self.photobookPhotos){
        if (![item isKindOfClass:[NSNull class]]){
            [[OLUserSession currentSession].userSelectedPhotos addObject:item];
        }
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    CGRect headerFrame = self.nextButton.frame;
    headerFrame.origin.y = self.view.frame.size.height - self.nextButton.frame.size.height + scrollView.contentOffset.y ;
    self.nextButton.frame = headerFrame;
}

- (NSInteger)photobookPhotosCount{
    NSInteger count = 0;
    for (id object in self.photobookPhotos){
        if (object != [NSNull null]){
            count++;
        }
    }
    
    return count;
}

#pragma mark - Menu Actions

- (void)deletePage{
    if (self.longPressImageIndex == -1){
        self.coverPhoto = nil;
        self.interactionPhotobook.coverPhoto = nil;
        [self.interactionPhotobook loadCoverPhoto];
        return;
    }
    
    if ([self.selectedIndexNumber integerValue] == self.longPressImageIndex){
        [[self pageControllerForPageIndex:[self.product.productTemplate.productRepresentation pageIndexForImageIndex:[self.selectedIndexNumber integerValue]]] unhighlightImageAtIndex:[self.selectedIndexNumber integerValue]];
        self.selectedIndexNumber = nil;
    }
    self.photobookPhotos[self.longPressImageIndex] = [NSNull null];
    [self updateUserSelectedPhotos];
    self.interactionPhotobook.photobookPhotos = self.photobookPhotos;
    [[self pageControllerForPageIndex:[self.product.productTemplate.productRepresentation pageIndexForImageIndex:self.longPressImageIndex]] loadImageWithCompletionHandler:NULL];
}

- (void)cropImage{
    OLPrintPhoto *cropPhoto;
    UIImageView *imageView;
    if (self.longPressImageIndex == -1){
        cropPhoto = self.coverPhoto;
        imageView = self.interactionPhotobook.coverImageView;
    }
    else{
        cropPhoto = self.photobookPhotos[self.longPressImageIndex];
        imageView = [self pageControllerForPageIndex:[self.product.productTemplate.productRepresentation pageIndexForImageIndex:self.longPressImageIndex]].imageView;
    }
#ifdef OL_KITE_OFFER_ADOBE
    [[AdobeUXAuthManager sharedManager] setAuthenticationParametersWithClientID:[OLKitePrintSDK adobeCreativeSDKClientID] clientSecret:[OLKitePrintSDK adobeCreativeSDKClientSecret] enableSignUp:true];
    [AdobeImageEditorCustomization setCropToolPresets:@[@{kAdobeImageEditorCropPresetName:@"", kAdobeImageEditorCropPresetWidth:@1, kAdobeImageEditorCropPresetHeight:[NSNumber numberWithDouble:imageView.frame.size.height / imageView.frame.size.width]}]];
    [AdobeImageEditorCustomization setCropToolCustomEnabled:NO];
    [AdobeImageEditorCustomization setCropToolInvertEnabled:NO];
    [AdobeImageEditorCustomization setCropToolOriginalEnabled:NO];
    
    [cropPhoto getImageWithProgress:NULL completion:^(UIImage *image){
        AdobeUXImageEditorViewController *editorController = [[AdobeUXImageEditorViewController alloc] initWithImage:image];
        [editorController setDelegate:self];
        [self presentViewController:editorController animated:YES completion:nil];
    }];
#else
    OLScrollCropViewController *cropVc = [self.storyboard instantiateViewControllerWithIdentifier:@"OLScrollCropViewController"];
    cropVc.delegate = self;
    cropVc.aspectRatio = imageView.frame.size.height / imageView.frame.size.width;
    
    cropVc.previewView = [imageView snapshotViewAfterScreenUpdates:YES];
    cropVc.previewView.frame = [imageView.superview convertRect:imageView.frame toView:nil];
    cropVc.previewSourceView = imageView;
    cropVc.providesPresentationContextTransitionStyle = true;
    cropVc.definesPresentationContext = true;
    cropVc.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    [cropPhoto getImageWithProgress:NULL completion:^(UIImage *image){
        [cropVc setFullImage:image];
        cropVc.edits = cropPhoto.edits;
        //        cropVc.modalPresentationStyle = [OLKiteUtils kiteVcForViewController:self].modalPresentationStyle;
        [self presentViewController:cropVc animated:NO completion:NULL];
    }];
#endif
    
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackReviewScreenEnteredCropScreenForProductName:self.product.productTemplate.name];
#endif
}

- (void)replaceImage{
    UIImageView *imageView;
    if (self.longPressImageIndex == -1){
        imageView = self.interactionPhotobook.coverImageView;
    }
    else{
        imageView = [self pageControllerForPageIndex:[self.product.productTemplate.productRepresentation pageIndexForImageIndex:self.longPressImageIndex]].imageView;
    }
    
    self.replacingImageNumber = [NSNumber numberWithInteger:self.longPressImageIndex];
    [self addMorePhotosFromView:imageView];
}

#pragma mark - User Actions

- (void)onButtonNextClicked{
    if (self.photobookPhotos.count == 0){
        
        NSString *alertTitle = NSLocalizedString(@"No photos", @"");
        NSString *alertMessage = NSLocalizedString(@"Please add at least one photo", @"");
        NSString *actionTitle = NSLocalizedString(@"OK", @"");
        UIAlertController *ac = [UIAlertController alertControllerWithTitle:alertTitle message:alertMessage preferredStyle:UIAlertControllerStyleAlert];
        [ac addAction:[UIAlertAction actionWithTitle:actionTitle style:UIAlertActionStyleDefault handler:NULL]];
        [self presentViewController:ac animated:YES completion:NULL];
        return;
    }
    
    if (self.photobookPhotos.count < self.product.quantityToFulfillOrder){
        NSString *alertTitle = NSLocalizedString(@"You can add more photos", @"");
        NSString *alertMessage = NSLocalizedString(@"Are you sure you want to proceed? If you do, the blank pages will be filled in with duplicate photos", @"");
        NSString *actionTitle = NSLocalizedString(@"Yes, proceed", @"");
        UIAlertController *ac = [UIAlertController alertControllerWithTitle:alertTitle message:alertMessage preferredStyle:UIAlertControllerStyleAlert];
        [ac addAction:[UIAlertAction actionWithTitle:actionTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
            [self proceedToBookReview];
        }]];
        [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"No, not yet", @"") style:UIAlertActionStyleCancel handler:NULL]];
        [self presentViewController:ac animated:YES completion:NULL];
    }
    else{
        [self proceedToBookReview];
    }
    
}

- (void)photobook:(OLPhotobookViewController *)photobook userDidTapOnImageWithIndex:(NSInteger)tappedImageIndex{
    if (self.animating == YES){
        return;
    }
    self.animating = YES;
    if (tappedImageIndex == -1){ //Replace Cover
        if (!self.coverPhoto){
            self.addNewPhotosAtIndex = tappedImageIndex;
            [self addMorePhotosFromView:photobook.view];
            self.animating = NO;
            return;
        }
        else{
            self.animating = NO;
            [self photobook:photobook userDidLongPressOnImageWithIndex:tappedImageIndex sender:photobook.coverImageView.gestureRecognizers.firstObject];
            return;
        }
    }
    
    OLPhotobookPageContentViewController *page = [self pageControllerForPageIndex:[self.product.productTemplate.productRepresentation pageIndexForImageIndex:tappedImageIndex]];
    if (self.selectedIndexNumber && [self.selectedIndexNumber integerValue] == tappedImageIndex){ //deselect
        [[self pageControllerForPageIndex:[self.product.productTemplate.productRepresentation pageIndexForImageIndex:[self.selectedIndexNumber integerValue]]] unhighlightImageAtIndex:tappedImageIndex];
        self.selectedIndexNumber = nil;
        self.animating = NO;
        [self photobook:photobook userDidLongPressOnImageWithIndex:tappedImageIndex sender:nil];
    }
    else if (self.selectedIndexNumber){ //swap
        OLPhotobookPageContentViewController *selectedPage = [self pageControllerForPageIndex:[self.product.productTemplate.productRepresentation pageIndexForImageIndex:[self.selectedIndexNumber integerValue]]];
        OLPrintPhoto *printPhoto = [self.photobookPhotos objectAtIndex:tappedImageIndex];
        
        [page unhighlightImageAtIndex:tappedImageIndex];
        [selectedPage unhighlightImageAtIndex:[self.selectedIndexNumber integerValue]];
        
        UIView *pageCopy = [page.imageView snapshotViewAfterScreenUpdates:YES];
        pageCopy.frame = [self.view convertRect:page.imageView.frame fromView:page.view];
        [page clearImage];
        
        
        if (selectedPage){ //Previously selected page is in view
            [self addPageShadowsToView:pageCopy];
            [self setPageShadowAlpha:pageCopy forIndex:page.pageIndex];
            [self.view addSubview:pageCopy];
            OLPhotobookViewController *selectedPhotobook = (OLPhotobookViewController *)selectedPage.parentViewController.parentViewController;
            UIView *selectedPageCopy = [selectedPage.imageView snapshotViewAfterScreenUpdates:YES];
            [selectedPage clearImage];
            selectedPageCopy.frame = [self.view convertRect:selectedPage.imageView.frame fromView:selectedPage.view];
            [self addPageShadowsToView:selectedPageCopy];
            [self setPageShadowAlpha:selectedPageCopy forIndex:selectedPage.pageIndex];
            
            [self.view addSubview:selectedPageCopy];
            
            CGRect tempFrame = pageCopy.frame;
            if (printPhoto == (id)[NSNull null]){
                [pageCopy removeFromSuperview];
            }
            [UIView animateWithDuration:0.05 animations:^{
                photobook.pagesLabel.superview.alpha = 0;
                selectedPhotobook.pagesLabel.superview.alpha = 0;
            }];
            [UIView animateWithDuration:0.5 animations:^{
                [self setPageShadowAlpha:selectedPageCopy forIndex:page.pageIndex];
                
                if (printPhoto != (id)[NSNull null]){
                    [self setPageShadowAlpha:pageCopy forIndex:selectedPage.pageIndex];
                    pageCopy.frame = selectedPageCopy.frame;
                }
                selectedPageCopy.frame = tempFrame;
            } completion:^(BOOL finished){
                [self swapImageAtIndex:[self.selectedIndexNumber integerValue] withImageAtIndex:tappedImageIndex];
                self.selectedIndexNumber = nil;
                photobook.photobookPhotos = self.photobookPhotos;
                
                [(OLPhotobookViewController *)selectedPage.parentViewController.parentViewController setPhotobookPhotos:self.photobookPhotos];
                [page loadImageWithCompletionHandler:^{
                    [selectedPage loadImageWithCompletionHandler:^{
                        [pageCopy removeFromSuperview];
                        [selectedPageCopy removeFromSuperview];
                        self.animating = NO;
                        [UIView animateWithDuration:0.5 animations:^{
                            photobook.pagesLabel.superview.alpha = 1;
                            selectedPhotobook.pagesLabel.superview.alpha = 1;
                        }];
                    }];
                }];
            }];
        }
        else{ //Previously selected image is not in view. Only pretend to swap.
            [self.view addSubview:pageCopy];
            if (self.photobookPhotos[tappedImageIndex] == (id)[NSNull null]){
                [pageCopy viewWithTag:12].alpha = 0;
                [pageCopy viewWithTag:22].alpha = 0;
            }
            
            [self swapImageAtIndex:[self.selectedIndexNumber integerValue] withImageAtIndex:tappedImageIndex];
            photobook.photobookPhotos = self.photobookPhotos;
            for (OLPhotobookViewController *otherPhotobook in self.childViewControllers){
                otherPhotobook.photobookPhotos = self.photobookPhotos;
            }
            
            CGFloat x = 0;
            if (page.pageIndex % 2 == 0 && [self.selectedIndexNumber integerValue] % 2 == 1){
                x += self.view.frame.size.width / 2.0;
            }
            if (page.pageIndex % 2 == 1 && [self.selectedIndexNumber integerValue] % 2 == 0){
                x -= self.view.frame.size.width / 2.0;
            }
            
            [UIView animateWithDuration:0.05 animations:^{
                photobook.pagesLabel.superview.alpha = 0;
            }];
            
            page.imageView.transform = CGAffineTransformMakeTranslation(-1000000, 0);
            page.pageShadowLeft2.alpha = 0;
            page.pageShadowRight2.alpha = 0;
            [page loadImageWithCompletionHandler:^{
                UIView *selectedPageCopy = [page.imageView snapshotViewAfterScreenUpdates:YES];
                page.imageView.hidden = YES;
                page.pageShadowLeft2.hidden = YES;
                page.pageShadowRight2.hidden = YES;
                page.imageView.transform = CGAffineTransformIdentity;
                selectedPageCopy.frame = [self.view convertRect:page.imageView.frame fromView:page.view];
                selectedPageCopy.transform = CGAffineTransformMakeTranslation(x, [self.selectedIndexNumber integerValue] < page.pageIndex ? -1000 : 1000);
                
                [self addPageShadowsToView:selectedPageCopy];
                [self setPageShadowAlpha:selectedPageCopy forIndex:selectedPage.pageIndex];
                [self.view addSubview:selectedPageCopy];
                
                [UIView animateWithDuration:0.5 animations:^{
                    [self setPageShadowAlpha:selectedPageCopy forIndex:page.pageIndex];
                    
                    if (printPhoto != (id)[NSNull null]){
                        pageCopy.transform = selectedPageCopy.transform;
                    }
                    selectedPageCopy.transform = CGAffineTransformIdentity;
                }completion:^(BOOL finished){
                    self.animating = NO;
                    page.imageView.hidden = NO;
                    [selectedPageCopy removeFromSuperview];
                    [pageCopy removeFromSuperview];
                    self.selectedIndexNumber = nil;
                    
                    if (self.photobookPhotos[tappedImageIndex] != (id)[NSNull null]){
                        if (tappedImageIndex % 2 == 0){
                            page.pageShadowLeft2.hidden = NO;
                            page.pageShadowLeft2.alpha = 1;
                        }
                        else{
                            page.pageShadowRight2.hidden = NO;
                            page.pageShadowRight2.alpha = 1;
                        }
                    }
                    [UIView animateWithDuration:0.5 animations:^{
                        photobook.pagesLabel.superview.alpha = 1;
                    }];
                }];
            }];
        }
        
        
    }
    else if ([self.photobookPhotos objectAtIndex:tappedImageIndex] == (id)[NSNull null]){ //pick new images
        self.addNewPhotosAtIndex = tappedImageIndex;
        [self addMorePhotosFromView:page.view];
        self.animating = NO;
    }
    else{ //select
        self.selectedIndexNumber = [NSNumber numberWithInteger:tappedImageIndex];
        [page highlightImageAtIndex:tappedImageIndex];
        self.animating = NO;
    }
    
}

- (void)photobook:(OLPhotobookViewController *)photobook userDidLongPressOnImageWithIndex:(NSInteger)index sender:(UILongPressGestureRecognizer *)sender{
    OLPopupOptionsImageView *view;
    if (index == -1){
        view = (OLPopupOptionsImageView *)sender.view;
    }
    else{
        if (self.photobookPhotos[index] == (id)[NSNull null]){
            return;
        }
        view = (OLPopupOptionsImageView *)[[self pageControllerForPageIndex:[self.product.productTemplate.productRepresentation pageIndexForImageIndex:index]] imageView];
    }
    
    self.longPressImageIndex = index;
    self.interactionPhotobook = photobook;
    
    if ([view respondsToSelector:@selector(setDelegate:)]){
        view.delegate = self;
    }
    if (view.isFirstResponder && [UIMenuController sharedMenuController].isMenuVisible){
        return;
    }
    [view becomeFirstResponder];
    UIMenuItem *deleteItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Remove", @"") action:@selector(deletePage)];
    UIMenuItem *cropImageItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Edit", @"") action:@selector(cropImage)];
    UIMenuItem *replaceImageItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Replace Photo", @"") action:@selector(replaceImage)];
    //    UIMenuItem *addPageItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Add Page", @"") action:@selector(addPage)];
    
    UIMenuController *mc = [UIMenuController sharedMenuController];
    [mc setMenuItems:@[cropImageItem, replaceImageItem, deleteItem]];
    [mc setTargetRect:view.frame inView:view];
    [mc setMenuVisible:YES animated:YES];
}

#pragma mark - CollectionView

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewCell *cell;
    if (indexPath.section == kSectionCover){
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"coverEditCell" forIndexPath:indexPath];
    }
    else if (indexPath.section == kSectionHelp){
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"helpCell" forIndexPath:indexPath];
        UILabel *label = (UILabel *)[cell viewWithTag:10];
        label.text = NSLocalizedString(@"Tap to swap pages. Hold for more options.", @"");
        [[cell viewWithTag:999] removeFromSuperview];
        return cell;
    }
    else{
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"bookPreviewCell" forIndexPath:indexPath];
    }
    
    UIView *view = [cell viewWithTag:10];
    if (!view){
        for (OLPhotobookViewController *photobook in self.childViewControllers){
            if (!photobook.view.superview){
                photobook.editingPageNumber = [NSNumber numberWithInteger:indexPath.item * 2];
                for (OLPhotobookPageContentViewController *page in photobook.pageController.viewControllers){
                    if (self.selectedIndexNumber && page.pageIndex == [self.selectedIndexNumber integerValue]){
                        [page highlightImageAtIndex:[self.selectedIndexNumber integerValue]];
                    }
                    else{
                        [page unhighlightImageAtIndex:page.pageIndex];
                    }
                }
                [cell addSubview:photobook.view];
                [[cell viewWithTag:999] removeFromSuperview];
                return cell;
            }
        }
        OLPhotobookViewController *photobook = [self.storyboard instantiateViewControllerWithIdentifier:@"PhotobookViewController"];
        if (indexPath.section == kSectionPages){
            photobook.startOpen = YES;
        }
        
        photobook.photobookPhotos = self.photobookPhotos;
        if (indexPath.section == kSectionCover){
            photobook.editingPageNumber = nil;
            
            photobook.coverPhoto = self.coverPhoto;
            [photobook loadCoverPhoto];
        }
        else{
            photobook.editingPageNumber = [NSNumber numberWithInteger:indexPath.item * 2];
        }
        
        photobook.product = self.product;
        photobook.delegate = self.delegate;
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
        
        photobook.photobookDelegate = self;
    }
    else{
        for (OLPhotobookViewController *photobook in self.childViewControllers){
            if (photobook.view == view){
                photobook.editingPageNumber = [NSNumber numberWithInteger:indexPath.item * 2];
                for (OLPhotobookPageContentViewController *page in photobook.pageController.viewControllers){
                    if (self.selectedIndexNumber && page.pageIndex == [self.selectedIndexNumber integerValue]){
                        [page highlightImageAtIndex:[self.selectedIndexNumber integerValue]];
                    }
                    else{
                        [page unhighlightImageAtIndex:page.pageIndex];
                    }
                }
                break;
            }
        }
    }
    [[cell viewWithTag:999] removeFromSuperview];
    return cell;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    if (section == kSectionCover || section == kSectionHelp){
        return 1;
    }
    else{
        return self.product.productTemplate.productRepresentation.numberOfPages / 2.0;
    }
    
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return self.rotating ? 0 : 3;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == kSectionHelp){
        return CGSizeMake(self.view.frame.size.width, 20);
    }
    else if (indexPath.section == kSectionCover){
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

#pragma mark - OLScrollCropView delegate

- (void)scrollCropViewControllerDidCancel:(OLScrollCropViewController *)cropper{
    [cropper dismissViewControllerAnimated:YES completion:NULL];
}

- (void)scrollCropViewControllerDidDropChanges:(OLScrollCropViewController *)cropper{
    [cropper dismissViewControllerAnimated:NO completion:NULL];
}

-(void)scrollCropViewController:(OLScrollCropViewController *)cropper didFinishCroppingImage:(UIImage *)croppedImage{
    if (self.longPressImageIndex == -1){
        [self.coverPhoto unloadImage];
        [self.coverPhoto setAsset:[OLAsset assetWithImageAsJPEG:croppedImage]];
        self.interactionPhotobook.coverPhoto = self.coverPhoto;
        [self.interactionPhotobook loadCoverPhoto];
        
    }
    else{
        [self.photobookPhotos[self.longPressImageIndex] unloadImage];
        [self.photobookPhotos[self.longPressImageIndex] setAsset:[OLAsset assetWithImageAsJPEG:croppedImage]];
        
        [[self pageControllerForPageIndex:[self.product.productTemplate.productRepresentation pageIndexForImageIndex:self.longPressImageIndex]] loadImageWithCompletionHandler:NULL];
    }
    
    [cropper dismissViewControllerAnimated:YES completion:NULL];
}

#ifdef OL_KITE_OFFER_ADOBE
- (void)photoEditor:(AdobeUXImageEditorViewController *)editor finishedWithImage:(UIImage *)image{
    OLPrintPhoto *printPhoto;
    OLPrintPhoto *copy;
    if (self.longPressImageIndex == -1){
        printPhoto = self.coverPhoto;
        [printPhoto unloadImage];
        copy = [printPhoto copy];
        printPhoto.asset = [OLAsset assetWithImageAsJPEG:image];
        self.interactionPhotobook.coverPhoto = self.coverPhoto;
        [self.interactionPhotobook loadCoverPhoto];
        
    }
    else{
        printPhoto = self.photobookPhotos[self.longPressImageIndex];
        [printPhoto unloadImage];
        copy = [printPhoto copy];
        printPhoto.asset = [OLAsset assetWithImageAsJPEG:image];
        
        [[self findPageForImageIndex:self.longPressImageIndex] loadImageWithCompletionHandler:NULL];
    }
    
    
    [editor dismissViewControllerAnimated:YES completion:NULL];
    
    [copy getImageWithProgress:NULL completion:^(UIImage *image){
        [editor enqueueHighResolutionRenderWithImage:image completion:^(UIImage *result, NSError *error) {
            NSArray * urls = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
            NSString *documentDirPath = [[(NSURL *)[urls objectAtIndex:0] path] stringByAppendingPathComponent:@"ol-kite-images"];
            
            
            NSFileManager *fileManager= [NSFileManager defaultManager];
            BOOL isDir;
            if(![fileManager fileExistsAtPath:documentDirPath isDirectory:&isDir]){
                [fileManager createDirectoryAtPath:documentDirPath withIntermediateDirectories:YES attributes:nil error:NULL];
            }
            
            NSData * binaryImageData = UIImageJPEGRepresentation(result, 0.7);
            
            NSString *filePath = [documentDirPath stringByAppendingPathComponent:[[[NSUUID UUID] UUIDString] stringByAppendingString:@".jpg"]];
            [binaryImageData writeToFile:filePath atomically:YES];
            
            printPhoto.asset = [OLAsset assetWithFilePath:filePath];
        }];
    }];
    
}

- (void)photoEditorCanceled:(AdobeUXImageEditorViewController *)editor{
    [editor dismissViewControllerAnimated:YES completion:NULL];
}
#endif

#pragma mark - Adding new images

- (void)addMorePhotosFromView:(UIView *)view{
    NSInteger numberOfProviders = 0;
    NSInteger numberOfCustomProviders = [OLKiteUtils kiteVcForViewController:self].customImageProviders.count;
    numberOfProviders += numberOfCustomProviders;
    
    if ([OLKiteUtils cameraRollEnabled:self]){
        numberOfProviders++;
    }
    if ([OLKiteUtils facebookEnabled]){
        numberOfProviders++;
    }
    if ([OLKiteUtils instagramEnabled]){
        numberOfProviders++;
    }
    
    if (numberOfProviders > 1){
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
        for (OLCustomPhotoProvider *provider in [OLKiteUtils kiteVcForViewController:self].customImageProviders){
            [ac addAction:[UIAlertAction actionWithTitle:provider.name style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
                [self showPickerForProvider:provider];
            }]];
        }
        
        [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action){
            [ac dismissViewControllerAnimated:YES completion:NULL];
        }]];
        ac.popoverPresentationController.sourceView = view;
        ac.popoverPresentationController.sourceRect = view.frame;
        [self presentViewController:ac animated:YES completion:NULL];
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
        else{
            [self showPickerForProvider:[OLKiteUtils kiteVcForViewController:self].customImageProviders.firstObject];
        }
    }
}

- (void)showCameraRollImagePicker{
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackPhotoProviderPicked:@"Camera Roll" forProductName:self.product.productTemplate.name];
#endif
    __block UIViewController *picker;
    __block Class assetClass;
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
    if (picker){
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
    picker.selected = @[];
    picker.modalPresentationStyle = [OLKiteUtils kiteVcForViewController:self].modalPresentationStyle;
    [self presentViewController:picker animated:YES completion:nil];
#endif
}

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
    
    vc.delegate = self;
    vc.modalPresentationStyle = [OLKiteUtils kiteVcForViewController:self].modalPresentationStyle;
    [self presentViewController:vc animated:YES completion:NULL];
}

- (void)populateArrayWithNewArray:(NSArray *)array dataType:(Class)class {
    NSMutableArray *photoArray = [[NSMutableArray alloc] initWithCapacity:array.count];
    
    for (id object in array) {
        if ([object isKindOfClass:[OLPrintPhoto class]]){
            [photoArray addObject:object];
        }
        else{
            OLPrintPhoto *printPhoto = [[OLPrintPhoto alloc] init];
            printPhoto.asset = object;
            [photoArray addObject:printPhoto];
        }
    }
    
//    // First remove any that are not returned.
//    NSMutableArray *removeArray = [NSMutableArray arrayWithArray:self.userSelectedPhotos];
//    for (OLPrintPhoto *object in self.userSelectedPhotos) {
//        if ([object.asset isKindOfClass:[OLAsset class]] && [[object.asset dataSource] isKindOfClass:class]){
//            if ([photoArray containsObject:object]){
//                [removeArray removeObjectIdenticalTo:object];
//                [photoArray removeObject:object];
//            }
//        }
//        else if (![object.asset isKindOfClass:class]) {
//            [removeArray removeObjectIdenticalTo:object];
//        }
//        
//        else if([photoArray containsObject:object]){
//            [removeArray removeObjectIdenticalTo:object];
//        }
//    }
//    
//    [self.userSelectedPhotos removeObjectsInArray:removeArray];
    
    // Second, add the remaining objects to the end of the array without replacing any.
    NSMutableArray *addArray = [NSMutableArray arrayWithArray:photoArray];
//    for (id object in self.userSelectedPhotos) {
//        if ([addArray containsObject:object]){
//            [addArray removeObject:object];
//        }
//    }
    
    [[OLUserSession currentSession].userSelectedPhotos addObjectsFromArray:addArray];
    
    [self updatePhotobookPhotos];
    for (OLPhotobookViewController *photobook in self.childViewControllers){
        if (!photobook.bookClosed){
            photobook.photobookPhotos = self.photobookPhotos;
            for (OLPhotobookPageContentViewController *page in photobook.pageController.viewControllers){
                [page loadImageWithCompletionHandler:NULL];
            }
        }
    }
    [self updateUserSelectedPhotos];
    
    if (!self.autoAddedCover && [OLUserSession currentSession].userSelectedPhotos.count > 0){
        self.autoAddedCover = YES;
        if (!self.coverPhoto){
            self.coverPhoto = [OLUserSession currentSession].userSelectedPhotos.firstObject;
            [[OLUserSession currentSession].userSelectedPhotos insertObject:self.coverPhoto atIndex:0];
            for (OLPhotobookViewController *photobook in self.childViewControllers){
                if ([photobook bookClosed]){
                    photobook.coverPhoto = self.coverPhoto;
                    [photobook loadCoverPhoto];
                    break;
                }
            }
        }
    }
}

#pragma mark - CTAssetsPickerControllerDelegate Methods

- (void)assetsPickerController:(id)picker didFinishPickingAssets:(NSArray *)assets {
    NSInteger originalCount = [OLUserSession currentSession].userSelectedPhotos.count;
    Class assetClass;
#ifdef OL_KITE_CI_DEPLOY
    if (NO){}
#else
    if ([picker isKindOfClass:[OLAssetsPickerController class]]){
        assetClass = [ALAsset class];
    }
#endif
    else if ([picker isKindOfClass:[CTAssetsPickerController class]]){
        assetClass = [PHAsset class];
    }
    else if ([picker isKindOfClass:[KITAssetsPickerController class]]){
        NSMutableArray *olAssets = [[NSMutableArray alloc] init];
        for (id<OLAssetDataSource> asset in assets){
            if ([asset isKindOfClass:[OLPrintPhoto class]]){
                [olAssets addObject:asset];
                assetClass = [assets.lastObject class];
            }
            else if ([asset respondsToSelector:@selector(dataWithCompletionHandler:)]){
                [olAssets addObject:[OLAsset assetWithDataSource:asset]];
                assetClass = [[olAssets.lastObject dataSource] class];
            }
        }
        assets = olAssets;
    }
    
    if (self.replacingImageNumber){
        if ([self.replacingImageNumber integerValue] == -1){
            self.coverPhoto = nil;
            self.addNewPhotosAtIndex = -1;
        }
        else{
            self.photobookPhotos[[self.replacingImageNumber integerValue]] = [NSNull null];
        }
        self.replacingImageNumber = nil;
    }
    
    if (self.addNewPhotosAtIndex == -1){
        if ([assets.firstObject isKindOfClass:[OLPrintPhoto class]]){
            self.coverPhoto = assets.firstObject;
        }
        else{
            self.coverPhoto = [[OLPrintPhoto alloc] init];
            self.coverPhoto.asset = [assets firstObject];
        }
        assets = [assets subarrayWithRange:NSMakeRange(1, assets.count - 1)];
        self.addNewPhotosAtIndex = 0;
        
        for (OLPhotobookViewController *photobook in self.childViewControllers){
            if ([photobook bookClosed]){
                photobook.coverPhoto = self.coverPhoto;
                [photobook loadCoverPhoto];
                break;
            }
        }
    }
    
    [self populateArrayWithNewArray:assets dataType:assetClass];
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackPhotoProvider:@"Camera Roll" numberOfPhotosAdded:[OLUserSession currentSession].userSelectedPhotos.count - originalCount forProductName:self.product.productTemplate.name];
#endif
    
    [picker dismissViewControllerAnimated:YES completion:^(void){}];
    
}

- (void)assetsPickerController:(CTAssetsPickerController *)picker didDeSelectAsset:(PHAsset *)asset{
    if (![asset isKindOfClass:[PHAsset class]]){
        return;
    }
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.networkAccessAllowed = YES;
    [[OLImageCachingManager sharedInstance].photosCachingManager stopCachingImagesForAssets:@[asset] targetSize:PHImageManagerMaximumSize contentMode:PHImageContentModeAspectFill options:options];
}

- (void)assetsPickerController:(CTAssetsPickerController *)picker didSelectAsset:(PHAsset *)asset{
    if (![asset isKindOfClass:[PHAsset class]]){
        return;
    }
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.networkAccessAllowed = YES;
    [[OLImageCachingManager sharedInstance].photosCachingManager startCachingImagesForAssets:@[asset] targetSize:PHImageManagerMaximumSize contentMode:PHImageContentModeAspectFill options:options];
}

- (BOOL)assetsPickerController:(id)picker shouldSelectAsset:(id)asset{
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
    
    NSInteger max = self.product.quantityToFulfillOrder;
    NSInteger current = [self photobookPhotosCount] + assets.count;
    if (self.addNewPhotosAtIndex == -1){
        max++;
    }
    if (self.replacingImageNumber){
        current--;
    }
    
    if (current >= max){
        UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Maximum Photos Reached", @"")
                                            message:[NSString stringWithFormat:max == 1 ? NSLocalizedString(@"Please select only %ld photo", @"") : NSLocalizedString(@"Please select not more than %ld photos total", @""), (long)max]
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *action =
        [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"")
                                 style:UIAlertActionStyleDefault
                               handler:nil];
        
        [alert addAction:action];
        
        [picker presentViewController:alert animated:YES completion:nil];
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
    NSInteger originalCount = [OLUserSession currentSession].userSelectedPhotos.count;
    NSMutableArray *assets = [[NSMutableArray alloc] init];
    for (id<OLAssetDataSource> asset in images){
        if ([asset isKindOfClass:[OLInstagramImage class]]){
            [assets addObject:asset];
        }
    }
    images = assets;
    
    if (self.replacingImageNumber){
        if ([self.replacingImageNumber integerValue] == -1){
            self.coverPhoto = nil;
            self.addNewPhotosAtIndex = -1;
        }
        else{
            self.photobookPhotos[[self.replacingImageNumber integerValue]] = [NSNull null];
        }
        self.replacingImageNumber = nil;
    }
    
    if (self.addNewPhotosAtIndex == -1){
        if (images.count > 0){
            self.coverPhoto = [[OLPrintPhoto alloc] init];
            self.coverPhoto.asset = [images firstObject];
            images = [images subarrayWithRange:NSMakeRange(1, images.count - 1)];
            self.addNewPhotosAtIndex = 0;
        }
        
        for (OLPhotobookViewController *photobook in self.childViewControllers){
            if ([photobook bookClosed]){
                photobook.coverPhoto = self.coverPhoto;
                [photobook loadCoverPhoto];
                break;
            }
        }
    }
    
    [self populateArrayWithNewArray:images dataType:[OLInstagramImage class]];
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackPhotoProvider:@"Instagram" numberOfPhotosAdded:[OLUserSession currentSession].userSelectedPhotos.count - originalCount forProductName:self.product.productTemplate.name];
#endif
    [self dismissViewControllerAnimated:YES completion:^(void){}];
}

- (void)instagramImagePickerDidCancelPickingImages:(OLInstagramImagePickerController *)imagePicker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)instagramImagePicker:(OLInstagramImagePickerController *)imagePicker shouldSelectImage:(OLInstagramImage *)image{
    NSInteger max = self.product.quantityToFulfillOrder;
    NSInteger current = [self photobookPhotosCount] + imagePicker.selected.count;
    if (self.addNewPhotosAtIndex == -1){
        max++;
    }
    if (self.replacingImageNumber){
        current--;
    }
    
    if (current >= max){
        UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Maximum Photos Reached", @"")
                                            message:[NSString stringWithFormat:self.product.quantityToFulfillOrder == 1 ? NSLocalizedString(@"Please select only %ld photo", @"") : NSLocalizedString(@"Please select not more than %ld photos total", @""), max]
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *action =
        [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"")
                                 style:UIAlertActionStyleDefault
                               handler:nil];
        
        [alert addAction:action];
        
        [imagePicker presentViewController:alert animated:YES completion:nil];
        return NO;
    }
    return YES;
}
#endif

#ifdef OL_KITE_OFFER_FACEBOOK
#pragma mark - OLFacebookImagePickerControllerDelegate Methods

- (void)facebookImagePicker:(OLFacebookImagePickerController *)imagePicker didFailWithError:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)facebookImagePicker:(OLFacebookImagePickerController *)imagePicker didFinishPickingImages:(NSArray *)images {
    NSInteger originalCount = [OLUserSession currentSession].userSelectedPhotos.count;
    NSMutableArray *assets = [[NSMutableArray alloc] init];
    for (id<OLAssetDataSource> asset in images){
        if ([asset isKindOfClass:[OLFacebookImage class]]){
            [assets addObject:asset];
        }
    }
    images = assets;
    
    if (self.replacingImageNumber){
        if ([self.replacingImageNumber integerValue] == -1){
            self.coverPhoto = nil;
            self.addNewPhotosAtIndex = -1;
        }
        else{
            self.photobookPhotos[[self.replacingImageNumber integerValue]] = [NSNull null];
        }
        self.replacingImageNumber = nil;
    }
    
    if (self.addNewPhotosAtIndex == -1){
        if (images.count > 0){
            self.coverPhoto = [[OLPrintPhoto alloc] init];
            self.coverPhoto.asset = [images firstObject];
            images = [images subarrayWithRange:NSMakeRange(1, images.count - 1)];
            self.addNewPhotosAtIndex = 0;
        }
        
        for (OLPhotobookViewController *photobook in self.childViewControllers){
            if ([photobook bookClosed]){
                photobook.coverPhoto = self.coverPhoto;
                [photobook loadCoverPhoto];
                break;
            }
        }
    }
    [self populateArrayWithNewArray:images dataType:[OLFacebookImage class]];
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackPhotoProvider:@"Facebook" numberOfPhotosAdded:[OLUserSession currentSession].userSelectedPhotos.count - originalCount forProductName:self.product.productTemplate.name];
#endif
    [self dismissViewControllerAnimated:YES completion:^(void){}];
}

- (void)facebookImagePickerDidCancelPickingImages:(OLFacebookImagePickerController *)imagePicker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)facebookImagePicker:(OLFacebookImagePickerController *)imagePicker shouldSelectImage:(OLFacebookImage *)image{
    NSInteger max = self.product.quantityToFulfillOrder;
    NSInteger current = [self photobookPhotosCount] + imagePicker.selected.count;
    if (self.addNewPhotosAtIndex == -1){
        max++;
    }
    if (self.replacingImageNumber){
        current--;
    }
    
    if (current >= max){
        UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Maximum Photos Reached", @"")
                                            message:[NSString stringWithFormat:self.product.quantityToFulfillOrder == 1 ? NSLocalizedString(@"Please select only %ld photo", @"") : NSLocalizedString(@"Please select not more than %ld photos total", @""), max]
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *action =
        [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"")
                                 style:UIAlertActionStyleDefault
                               handler:nil];
        
        [alert addAction:action];
        
        [imagePicker presentViewController:alert animated:YES completion:nil];
        return NO;
    }
    return YES;
}
#endif

@end
