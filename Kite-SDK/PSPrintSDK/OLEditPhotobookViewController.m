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

#import "OLAnalytics.h"
#import "OLEditPhotobookViewController.h"
#import "OLImageCachingManager.h"
#import "OLKiteUtils.h"
#import "OLPhotobookPageContentViewController.h"
#import "OLPhotobookViewController.h"
#import "OLPopupOptionsImageView.h"
#import "OLImageEditViewController.h"
#import "OLUserSession.h"
#import "OLAsset+Private.h"
#import "UIViewController+OLMethods.h"
#import "OLPaymentViewController.h"
#import "OLImagePickerViewController.h"
#import "OLNavigationController.h"
#import "OLKiteABTesting.h"
#import "OLCustomPickerController.h"
#import "OLCustomViewControllerPhotoProvider.h"
#import "NSObject+Utils.h"
#import "OLKiteViewController+Private.h"
#import "UIView+RoundRect.h"

static const NSInteger kSectionCover = 0;
static const NSInteger kSectionHelp = 1;
static const NSInteger kSectionPages = 2;

@interface OLPhotobookViewController ()
@property (weak, nonatomic) UIImageView *coverImageView;
@end

@interface OLKitePrintSDK (InternalUtils)
+ (NSString *) instagramRedirectURI;
+ (NSString *) instagramSecret;
+ (NSString *) instagramClientID;
@end

@interface OLEditPhotobookViewController () <UICollectionViewDelegateFlowLayout, OLPhotobookViewControllerDelegate, OLImageViewDelegate, OLImageEditViewControllerDelegate,UINavigationControllerDelegate, OLImagePickerViewControllerDelegate, UIPopoverPresentationControllerDelegate>

@property (assign, nonatomic) BOOL animating;
@property (assign, nonatomic) BOOL haveCachedCells;
@property (assign, nonatomic) BOOL rotating;
@property (assign, nonatomic) NSInteger addNewPhotosAtIndex;
@property (assign, nonatomic) NSInteger longPressImageIndex;
@property (strong, nonatomic) NSNumber *replacingImageNumber;
@property (strong, nonatomic) NSNumber *selectedIndexNumber;
@property (strong, nonatomic) NSArray *userSelectedPhotosCopy;
@property (strong, nonatomic) NSMutableArray *photobookPhotos;
@property (strong, nonatomic) OLAsset *coverPhoto;
@property (weak, nonatomic) OLPhotobookViewController *interactionPhotobook;
@property (strong, nonatomic) UIButton *nextButton;
@property (assign, nonatomic) BOOL autoAddedCover;
@property (assign, nonatomic) BOOL shownImagePicker;
@property (strong, nonatomic) OLImagePickerViewController *vcDelegateForCustomVc;
@property (strong, nonatomic) UIViewController *presentedVc;

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
    
    
    [self updatePhotobookPhotos];
    
    [self setupCtaButton];
    
    self.collectionView.contentInset = UIEdgeInsetsMake(self.collectionView.contentInset.top, self.collectionView.contentInset.left, self.nextButton.frame.size.height, self.collectionView.contentInset.right);
}

- (void)setupCtaButton{
    self.nextButton = [[UIButton alloc] init];
    [self.nextButton.titleLabel setFont:[UIFont systemFontOfSize:17]];
    [self.nextButton setTitle:NSLocalizedStringFromTableInBundle(@"Next", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") forState:UIControlStateNormal];
    [self.nextButton addTarget:self action:@selector(onButtonNextClicked) forControlEvents:UIControlEventTouchUpInside];
    if ([OLKiteABTesting sharedInstance].lightThemeColor1){
        [self.nextButton setBackgroundColor:[OLKiteABTesting sharedInstance].lightThemeColor1];
    }
    else{
        [self.nextButton setBackgroundColor:[UIColor colorWithRed:0.125 green:0.498 blue:0.655 alpha:1.000]];
    }
    UIFont *font = [[OLKiteABTesting sharedInstance] lightThemeFont1WithSize:17];
    if (font){
        [self.nextButton.titleLabel setFont:font];
    }
    NSNumber *cornerRadius = [OLKiteABTesting sharedInstance].lightThemeButtonRoundCorners;
    if (cornerRadius){
        [self.nextButton makeRoundRectWithRadius:[cornerRadius floatValue]];
    }

    
    [self.nextButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.nextButton.frame = CGRectMake(5, self.view.frame.size.height - 55 - ([[UIApplication sharedApplication] statusBarFrame].size.height + self.navigationController.navigationBar.frame.size.height), self.view.frame.size.width-10, 50);
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
    
    if (!self.shownImagePicker && [OLUserSession currentSession].userSelectedPhotos.count == 0 && self.childViewControllers.count > 1 && !self.coverPhoto){
        self.shownImagePicker = YES;
        [self photobook:self.childViewControllers[1] userDidTapOnImageWithIndex:0];
    }
    
    UIFont *font = [[OLKiteABTesting sharedInstance] lightThemeHeavyFont1WithSize:17];
    if (!font){
        font = [[OLKiteABTesting sharedInstance] lightThemeFont1WithSize:17];
    }
    if (font){
        [self.nextButton.titleLabel setFont:font];
    }
    else{
        [self.nextButton.titleLabel setFont:[UIFont systemFontOfSize:17]];
    }
    
    NSNumber *cornerRadius = [OLKiteABTesting sharedInstance].lightThemeButtonRoundCorners;
    if (cornerRadius){
        [self.nextButton makeRoundRectWithRadius:[cornerRadius floatValue]];
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
        else if ([self.coverPhoto isKindOfClass:[OLPlaceholderAsset class]]){
            self.coverPhoto = nil;
        }
        for (NSInteger i = start; i < self.product.quantityToFulfillOrder + start; i++){
            [self.photobookPhotos addObject:i < [OLUserSession currentSession].userSelectedPhotos.count ? [OLUserSession currentSession].userSelectedPhotos[i] : [OLPlaceholderAsset asset]];
        }
    }
    else{
        NSMutableArray *newPhotos = [NSMutableArray arrayWithArray:[[OLUserSession currentSession].userSelectedPhotos subarrayWithRange:NSMakeRange(0, MIN([OLUserSession currentSession].userSelectedPhotos.count, self.product.quantityToFulfillOrder+1))]];
        [newPhotos removeObjectsInArray:self.userSelectedPhotosCopy];
        for (NSInteger newPhoto = 0; newPhoto < newPhotos.count; newPhoto++){
            BOOL foundSpot = NO;
            for (NSInteger bookPhoto = self.addNewPhotosAtIndex; bookPhoto < self.photobookPhotos.count && !foundSpot; bookPhoto++){
                if ([self.photobookPhotos[bookPhoto] isKindOfClass:[OLPlaceholderAsset class]]){
                    self.photobookPhotos[bookPhoto] = newPhotos[newPhoto];
                    foundSpot = YES;
                }
            }
            for (NSInteger bookPhoto = 0; bookPhoto < self.addNewPhotosAtIndex && !foundSpot; bookPhoto++){
                if ([self.photobookPhotos[bookPhoto] isKindOfClass:[OLPlaceholderAsset class]]){
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
        UIImage *leftImage = [UIImage imageNamed:@"page-shadow-left" inBundle:[OLKiteUtils kiteLocalizationBundle] compatibleWithTraitCollection:self.traitCollection];
        UIImage *rightImage = [UIImage imageNamed:@"page-shadow-right" inBundle:[OLKiteUtils kiteLocalizationBundle] compatibleWithTraitCollection:self.traitCollection];
        
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
    if (self.coverPhoto && ![self.coverPhoto isKindOfClass:[OLPlaceholderAsset class]]){
        [[OLUserSession currentSession].userSelectedPhotos addObject:self.coverPhoto];
    }
    for (OLAsset *item in self.photobookPhotos){
        if (![item isKindOfClass:[OLPlaceholderAsset class]]){
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
        if (![object isKindOfClass:[OLPlaceholderAsset class]]){
            count++;
        }
    }
    
    return count;
}

#pragma mark - Menu Actions

- (void)deletePage{
    if (self.longPressImageIndex == -1){
        [self.photobookPhotos removeObjectIdenticalTo:self.coverPhoto];
        [[OLUserSession currentSession].userSelectedPhotos removeObjectIdenticalTo:self.coverPhoto];
        self.coverPhoto = nil;
        self.interactionPhotobook.coverPhoto = nil;
        [self.interactionPhotobook loadCoverPhoto];
        return;
    }
    
    if ([self.selectedIndexNumber integerValue] == self.longPressImageIndex){
        [[self pageControllerForPageIndex:[self.product.productTemplate.productRepresentation pageIndexForImageIndex:[self.selectedIndexNumber integerValue]]] unhighlightImageAtIndex:[self.selectedIndexNumber integerValue]];
        self.selectedIndexNumber = nil;
    }
    [[OLUserSession currentSession].userSelectedPhotos removeObjectIdenticalTo:self.photobookPhotos[self.longPressImageIndex]];
    self.photobookPhotos[self.longPressImageIndex] = [OLPlaceholderAsset asset];
    [self updateUserSelectedPhotos];
    self.interactionPhotobook.photobookPhotos = self.photobookPhotos;
    [[self pageControllerForPageIndex:[self.product.productTemplate.productRepresentation pageIndexForImageIndex:self.longPressImageIndex]] loadImageWithCompletionHandler:NULL];
}

- (void)editImage{
    OLAsset *cropPhoto;
    UIImageView *imageView;
    if (self.longPressImageIndex == -1){
        cropPhoto = self.coverPhoto;
        imageView = self.interactionPhotobook.coverImageView;
    }
    else{
        cropPhoto = self.photobookPhotos[self.longPressImageIndex];
        imageView = [self pageControllerForPageIndex:[self.product.productTemplate.productRepresentation pageIndexForImageIndex:self.longPressImageIndex]].imageView;
    }
    OLImageEditViewController *cropVc = [[OLImageEditViewController alloc] init];
    cropVc.delegate = self;
    cropVc.aspectRatio = imageView.frame.size.height / imageView.frame.size.width;
    cropVc.product = self.product;
    
    cropVc.previewView = [imageView snapshotViewAfterScreenUpdates:YES];
    cropVc.previewView.frame = [imageView.superview convertRect:imageView.frame toView:nil];
    cropVc.previewSourceView = imageView;
    cropVc.providesPresentationContextTransitionStyle = true;
    cropVc.definesPresentationContext = true;
    cropVc.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    [cropPhoto imageWithSize:[UIScreen mainScreen].bounds.size applyEdits:NO progress:NULL completion:^(UIImage *image, NSError *error){
        [cropVc setFullImage:image];
        cropVc.edits = cropPhoto.edits;
        [self presentViewController:cropVc animated:NO completion:NULL];
    }];
    
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackEditPhotoTappedForProductName:self.product.productTemplate.name];
#endif
}

#pragma mark - User Actions

- (void)onButtonNextClicked{
    if (self.photobookPhotos.count == 0){
        NSString *alertTitle = NSLocalizedStringFromTableInBundle(@"No photos", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Title of an alert letting the user know that they selected no photos");
        NSString *alertMessage = NSLocalizedStringFromTableInBundle(@"Please add at least one photo", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"");
        NSString *actionTitle = NSLocalizedStringFromTableInBundle(@"OK", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Acknowledgent to an alert dialog.");
        UIAlertController *ac = [UIAlertController alertControllerWithTitle:alertTitle message:alertMessage preferredStyle:UIAlertControllerStyleAlert];
        [ac addAction:[UIAlertAction actionWithTitle:actionTitle style:UIAlertActionStyleDefault handler:NULL]];
        [self presentViewController:ac animated:YES completion:NULL];
        return;
    }
    
    if (self.photobookPhotos.count < self.product.quantityToFulfillOrder){
        NSString *alertTitle = NSLocalizedStringFromTableInBundle(@"You can add more photos", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"");
        NSString *alertMessage = NSLocalizedStringFromTableInBundle(@"Are you sure you want to proceed? If you do, the blank pages will be filled in with duplicate photos", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"");
        NSString *actionTitle = NSLocalizedStringFromTableInBundle(@"Yes, proceed", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"");
        UIAlertController *ac = [UIAlertController alertControllerWithTitle:alertTitle message:alertMessage preferredStyle:UIAlertControllerStyleAlert];
        [ac addAction:[UIAlertAction actionWithTitle:actionTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
            [self proceedToBookReview];
        }]];
        [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"No, not yet", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") style:UIAlertActionStyleCancel handler:NULL]];
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
        OLAsset *asset = [self.photobookPhotos objectAtIndex:tappedImageIndex];
        
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
            if ([asset isKindOfClass:[OLPlaceholderAsset class]]){
                [pageCopy removeFromSuperview];
            }
            [UIView animateWithDuration:0.05 animations:^{
                photobook.pagesLabel.superview.alpha = 0;
                selectedPhotobook.pagesLabel.superview.alpha = 0;
            }];
            [UIView animateWithDuration:0.5 animations:^{
                [self setPageShadowAlpha:selectedPageCopy forIndex:page.pageIndex];
                
                if (![asset isKindOfClass:[OLPlaceholderAsset class]]){
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
            if ([self.photobookPhotos[tappedImageIndex] isKindOfClass:[OLPlaceholderAsset class]]){
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
                    
                    if (![asset isKindOfClass:[OLPlaceholderAsset class]]){
                        pageCopy.transform = selectedPageCopy.transform;
                    }
                    selectedPageCopy.transform = CGAffineTransformIdentity;
                }completion:^(BOOL finished){
                    self.animating = NO;
                    page.imageView.hidden = NO;
                    [selectedPageCopy removeFromSuperview];
                    [pageCopy removeFromSuperview];
                    self.selectedIndexNumber = nil;
                    
                    if (![self.photobookPhotos[tappedImageIndex] isKindOfClass:[OLPlaceholderAsset class]]){
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
    else if ([[self.photobookPhotos objectAtIndex:tappedImageIndex] isKindOfClass:[OLPlaceholderAsset class]]){ //pick new images
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
        if ([self.photobookPhotos[index] isKindOfClass:[OLPlaceholderAsset class]]){
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
    NSMutableArray *items = [[NSMutableArray alloc] init];
    UIMenuItem *deleteItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Remove", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Remove/clear an image") action:@selector(deletePage)];
    [items addObject:deleteItem];
    
    if (![OLUserSession currentSession].kiteVc.disableEditingTools){
        UIMenuItem *cropImageItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Edit", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") action:@selector(editImage)];
        [items addObject:cropImageItem];
    }
    
    UIMenuController *mc = [UIMenuController sharedMenuController];
    [mc setMenuItems:items];
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
        label.text = NSLocalizedStringFromTableInBundle(@"Tap to swap pages. Hold for more options.", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"");
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

#pragma mark - OLImageEditViewController delegate

- (void)imageEditViewControllerDidCancel:(OLImageEditViewController *)cropper{
    if (self.longPressImageIndex == -1){
        [self.coverPhoto unloadImage];
    }
    else{
        [self.photobookPhotos[self.longPressImageIndex] unloadImage];
    }
    [cropper dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imageEditViewControllerDidDropChanges:(OLImageEditViewController *)cropper{
    if (self.longPressImageIndex == -1){
        [self.coverPhoto unloadImage];
    }
    else{
        [self.photobookPhotos[self.longPressImageIndex] unloadImage];
    }
    [cropper dismissViewControllerAnimated:NO completion:NULL];
}

-(void)imageEditViewController:(OLImageEditViewController *)cropper didFinishCroppingImage:(UIImage *)croppedImage{
    if (self.longPressImageIndex == -1){
        [self.coverPhoto unloadImage];
        self.coverPhoto.edits = cropper.edits;
        self.interactionPhotobook.coverPhoto = self.coverPhoto;
        [self.interactionPhotobook loadCoverPhoto];
        
    }
    else{
        [self.photobookPhotos[self.longPressImageIndex] unloadImage];
        [self.photobookPhotos[self.longPressImageIndex] setEdits:cropper.edits];
        
        [[self pageControllerForPageIndex:[self.product.productTemplate.productRepresentation pageIndexForImageIndex:self.longPressImageIndex]] loadImageWithCompletionHandler:NULL];
    }
    
    [cropper dismissViewControllerAnimated:YES completion:NULL];
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackEditScreenFinishedEditingPhotoForProductName:self.product.productTemplate.name];
#endif
}

- (void)imageEditViewController:(OLImageEditViewController *)cropper didReplaceAssetWithAsset:(OLAsset *)asset{
    if (self.longPressImageIndex == -1){
        self.coverPhoto = asset;
        self.interactionPhotobook.coverPhoto = self.coverPhoto;
        [self.interactionPhotobook loadCoverPhoto];
    }
    else{
        NSUInteger index = [[OLUserSession currentSession].userSelectedPhotos indexOfObjectIdenticalTo:self.photobookPhotos[self.longPressImageIndex]];
        [[OLUserSession currentSession].userSelectedPhotos replaceObjectAtIndex:index withObject:asset];
        [self.photobookPhotos replaceObjectAtIndex:self.longPressImageIndex withObject:asset];
        
        self.interactionPhotobook.photobookPhotos = self.photobookPhotos;
        [[self pageControllerForPageIndex:[self.product.productTemplate.productRepresentation pageIndexForImageIndex:self.longPressImageIndex]] loadImageWithCompletionHandler:NULL];
    }
    
}


#pragma mark - Adding new images

- (void)addMorePhotosFromView:(UIView *)view{
    NSInteger max = self.product.quantityToFulfillOrder + 1; //Plus cover photo
    NSInteger current = [self photobookPhotosCount];
    if (self.replacingImageNumber){
        current--;
    }
    
    OLImagePickerViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"OLImagePickerViewController"];
    vc.selectedAssets = [OLUserSession currentSession].userSelectedPhotos;
    vc.delegate = self;
    vc.maximumPhotos = max;
    vc.product = self.product;
    
    if ([OLKiteUtils numberOfProvidersAvailable] <= 2 && [[OLUserSession currentSession].kiteVc.customImageProviders.firstObject isKindOfClass:[OLCustomViewControllerPhotoProvider class]]){
        //Skip the image picker and only show the custom vc
        
        self.vcDelegateForCustomVc = vc; //Keep strong reference
        vc.providerForPresentedVc = [OLUserSession currentSession].kiteVc.customImageProviders.firstObject;
        UIViewController<OLCustomPickerController> *customVc = [(OLCustomViewControllerPhotoProvider *)[OLUserSession currentSession].kiteVc.customImageProviders.firstObject vc];
        [customVc safePerformSelector:@selector(setDelegate:) withObject:vc];
        [customVc safePerformSelector:@selector(setProductId:) withObject:self.product.templateId];
        [customVc safePerformSelector:@selector(setSelectedAssets:) withObject:[[OLUserSession currentSession].userSelectedPhotos mutableCopy]];
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
    
    if (self.replacingImageNumber){
        if ([self.replacingImageNumber integerValue] == -1){
            self.coverPhoto = nil;
            self.addNewPhotosAtIndex = -1;
        }
        else{
            self.photobookPhotos[[self.replacingImageNumber integerValue]] = [OLPlaceholderAsset asset];
        }
        self.replacingImageNumber = nil;
    }
    
    if (self.addNewPhotosAtIndex == -1){
            self.coverPhoto = [addedAssets firstObject];
        if (addedAssets.count > 0){
            addedAssets = [addedAssets mutableCopy];
            [(NSMutableArray *)addedAssets removeObjectAtIndex:0];
            [assets removeObjectIdenticalTo:self.coverPhoto];
        }
        self.addNewPhotosAtIndex = 0;
        
        for (OLPhotobookViewController *photobook in self.childViewControllers){
            if ([photobook bookClosed]){
                photobook.coverPhoto = self.coverPhoto;
                [photobook loadCoverPhoto];
                break;
            }
        }
    }
    
    [self.photobookPhotos removeObjectsInArray:removedAssets];
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
    
    if (!self.autoAddedCover && assets.count > 0){
        self.autoAddedCover = YES;
        if (!self.coverPhoto){
            self.coverPhoto = addedAssets.firstObject;
            [assets removeObject:self.coverPhoto];
            [assets insertObject:self.coverPhoto atIndex:0];
            for (OLPhotobookViewController *photobook in self.childViewControllers){
                if ([photobook bookClosed]){
                    photobook.coverPhoto = self.coverPhoto;
                    [photobook loadCoverPhoto];
                    break;
                }
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

@end
