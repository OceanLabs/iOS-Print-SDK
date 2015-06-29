//
//  OLEditPhotobookViewController.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 16/6/15.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import "OLEditPhotobookViewController.h"
#import "OLPhotobookViewController.h"
#import "OLPhotobookPageContentViewController.h"
#import <CTAssetsPickerController.h>
#import "OLPrintPhoto.h"
#import "NSArray+QueryingExtras.h"
#import "OLImageView.h"
#import "OLScrollCropViewController.h"

#ifdef OL_KITE_OFFER_INSTAGRAM
#import <OLInstagramImagePickerController.h>
#import <OLInstagramImage.h>
#endif

#ifdef OL_KITE_OFFER_FACEBOOK
#import <OLFacebookImagePickerController.h>
#import <OLFacebookImage.h>
#endif

static const NSInteger kSectionCover = 0;
static const NSInteger kSectionHelp = 1;
static const NSInteger kSectionPages = 2;

@interface OLPhotobookViewController ()

@property (weak, nonatomic) UIImageView *coverImageView;

@end

@interface OLKitePrintSDK (InternalUtils)
+ (NSString *)userEmail:(UIViewController *)topVC;
+ (NSString *)userPhone:(UIViewController *)topVC;
+ (id<OLKiteDelegate>)kiteDelegate:(UIViewController *)topVC;
+ (void)checkoutViewControllerForPrintOrder:(OLPrintOrder *)printOrder handler:(void(^)(OLCheckoutViewController *vc))handler;

#ifdef OL_KITE_OFFER_INSTAGRAM
+ (NSString *) instagramRedirectURI;
+ (NSString *) instagramSecret;
+ (NSString *) instagramClientID;
#endif
@end

@interface OLEditPhotobookViewController () <UICollectionViewDelegateFlowLayout, OLPhotobookViewControllerDelegate, CTAssetsPickerControllerDelegate, UIActionSheetDelegate, UIAlertViewDelegate, OLImageViewDelegate, OLScrollCropViewControllerDelegate,
#ifdef OL_KITE_OFFER_INSTAGRAM
OLInstagramImagePickerControllerDelegate,
#endif
#ifdef OL_KITE_OFFER_FACEBOOK
OLFacebookImagePickerControllerDelegate,
#endif
UINavigationControllerDelegate>

@property (strong, nonatomic) NSMutableArray *photobookPhotos;
@property (strong, nonatomic) NSArray *userSelectedPhotosCopy;
@property (assign, nonatomic) NSNumber *selectedIndexNumber;
@property (assign, nonatomic) NSInteger addNewPhotosAtIndex;
@property (assign, nonatomic) NSInteger interactionImageIndex;
@property (weak, nonatomic) OLPhotobookViewController *interactionPhotobook;
@property (strong, nonatomic) OLPrintPhoto *coverPhoto;
@property (assign, nonatomic) BOOL animating;

@end

@implementation OLEditPhotobookViewController

- (void)setAnimating:(BOOL)animating{
    _animating = animating;
    self.collectionView.scrollEnabled = !animating;
}

- (void)viewDidLoad{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Move Pages", @"");
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", @"")
                                                                             style:UIBarButtonItemStyleBordered
                                                                            target:nil
                                                                            action:nil];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                              initWithTitle:NSLocalizedString(@"Next", @"")
                                              style:UIBarButtonItemStylePlain
                                              target:self
                                              action:@selector(onButtonNextClicked)];
    
    [self updatePhotobookPhotos];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator{
    for (OLPhotobookViewController *photobook in self.childViewControllers){
        [photobook viewWillTransitionToSize:CGSizeMake(size.width, [self cellHeightForSize:size]) withTransitionCoordinator:coordinator];
    }
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinator> context){
        [self.collectionView.collectionViewLayout invalidateLayout];
        for (OLPhotobookViewController * photobook in self.childViewControllers){
            photobook.view.frame = CGRectMake(0, 0, size.width, [self cellHeightForSize:size]);
        }
    }completion:^(id<UIViewControllerTransitionCoordinator> context){
    }];
}

- (void)proceedToBookReview{
    NSInteger i = 0;
    NSMutableArray *bookPhotos = [[NSMutableArray alloc] init];
    for (NSInteger object = 0; object < self.photobookPhotos.count; object++){
        if (self.photobookPhotos[object] == [NSNull null]){
            [bookPhotos addObject:self.userSelectedPhotos[i % self.userSelectedPhotos.count]];
            i++;
        }
        else{
            [bookPhotos addObject:self.photobookPhotos[object]];
        }
    }
    
    OLPhotobookViewController *photobook = [self.storyboard instantiateViewControllerWithIdentifier:@"PhotobookViewController"];
    photobook.coverPhoto = self.coverPhoto;
    [photobook loadCoverPhoto];
    photobook.userSelectedPhotos = bookPhotos;
    photobook.product = self.product;
    photobook.delegate = self.delegate;
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8){
        [self.navigationController presentViewController:photobook animated:YES completion:NULL];
        return;
    }
    
    [self.navigationController pushViewController:photobook animated:YES];
}

- (void)updatePhotobookPhotos{
    if (!self.photobookPhotos){
        self.userSelectedPhotosCopy = [[NSArray alloc] initWithArray:self.userSelectedPhotos copyItems:NO];
        self.photobookPhotos = [[NSMutableArray alloc] initWithCapacity:self.product.quantityToFulfillOrder];
        [self.photobookPhotos addObjectsFromArray:self.userSelectedPhotos];
        for (NSInteger i = self.userSelectedPhotos.count; i < self.product.quantityToFulfillOrder; i++){
            [self.photobookPhotos addObject:[NSNull null]];
        }
    }
    else{
        NSMutableArray *newPhotos = [NSMutableArray arrayWithArray:self.userSelectedPhotos];
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
        self.userSelectedPhotosCopy = [[NSArray alloc] initWithArray:self.userSelectedPhotos copyItems:NO];
    }
    
}

- (void)swapImageAtIndex:(NSInteger)index1 withImageAtIndex:(NSInteger)index2{
    [self.photobookPhotos exchangeObjectAtIndex:index1 withObjectAtIndex:index2];
}

- (OLPhotobookPageContentViewController *)findPageForImageIndex:(NSInteger)index{
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
    UIImage *leftImage = [UIImage imageNamed:@"page-shadow-left"];
    UIImage *rightImage = [UIImage imageNamed:@"page-shadow-right"];
    
    UIImageView *left1 = [[UIImageView alloc] initWithImage:leftImage];
    left1.contentMode = UIViewContentModeScaleToFill;
    left1.tag = 11;
    left1.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:left1];
    
    UIImageView *left2 = [[UIImageView alloc] initWithImage:leftImage];
    left2.contentMode = UIViewContentModeScaleToFill;
    left2.tag = 12;
    left2.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:left2];
    
    UIImageView *right1 = [[UIImageView alloc] initWithImage:rightImage];
    right1.contentMode = UIViewContentModeScaleToFill;
    right1.tag = 21;
    right1.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:right1];
    
    UIImageView *right2 = [[UIImageView alloc] initWithImage:rightImage];
    right2.contentMode = UIViewContentModeScaleToFill;
    right2.tag = 22;
    right2.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:right2];
    
    CGFloat shadowWidth = view.frame.size.width * 0.3;
    
    left1.frame = CGRectMake(view.frame.size.width - shadowWidth, 0, shadowWidth, view.frame.size.height);
    left2.frame = CGRectMake(view.frame.size.width - shadowWidth, 0, shadowWidth, view.frame.size.height);
    right1.frame = CGRectMake(0, 0, shadowWidth, view.frame.size.height);
    right2.frame = CGRectMake(0, 0, shadowWidth, view.frame.size.height);
}

- (void)setPageShadowAlpha:(UIView *)view forIndex:(NSInteger)index{
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

#pragma mark - Menu Actions

- (void)deletePage{
    if (self.interactionImageIndex == -1){
        self.coverPhoto = nil;
        self.interactionPhotobook.coverPhoto = nil;
        [self.interactionPhotobook loadCoverPhoto];
        return;
    }
    
    self.photobookPhotos[self.interactionImageIndex] = [NSNull null];
    self.interactionPhotobook.userSelectedPhotos = self.photobookPhotos;
    [[self findPageForImageIndex:self.interactionImageIndex] loadImageWithCompletionHandler:NULL];
}

- (void)addPage{
    
}

- (void)cropImage{
    OLPrintPhoto *cropPhoto;
    UIImageView *imageView;
    if (self.interactionImageIndex == -1){
        cropPhoto = self.coverPhoto;
        imageView = self.interactionPhotobook.coverImageView;
    }
    else{
        cropPhoto = self.photobookPhotos[self.interactionImageIndex];
        imageView = [self findPageForImageIndex:self.interactionImageIndex].imageView;
    }
    
    UINavigationController *nav = [self.storyboard instantiateViewControllerWithIdentifier:@"CropViewNavigationController"];
    OLScrollCropViewController *cropVc = (id)nav.topViewController;
    cropVc.delegate = self;
    cropVc.aspectRatio = imageView.frame.size.height / imageView.frame.size.width;
    [cropPhoto getImageWithProgress:NULL completion:^(UIImage *image){
        [cropVc setFullImage:image];
        [self presentViewController:nav animated:YES completion:NULL];
    }];
}

#pragma mark - User Actions

- (void)onButtonNextClicked{
    if (self.photobookPhotos.count == 0){
        
        NSString *alertTitle = NSLocalizedString(@"No photos", @"");
        NSString *alertMessage = NSLocalizedString(@"Please add at least one photo", @"");
        NSString *actionTitle = NSLocalizedString(@"OK", @"");
        if ([UIAlertController class]){
            UIAlertController *ac = [UIAlertController alertControllerWithTitle:alertTitle message:alertMessage preferredStyle:UIAlertControllerStyleAlert];
            [ac addAction:[UIAlertAction actionWithTitle:actionTitle style:UIAlertActionStyleDefault handler:NULL]];
            [self presentViewController:ac animated:YES completion:NULL];
        }
        else{
            UIAlertView *av = [[UIAlertView alloc] initWithTitle:alertTitle message:alertMessage delegate:self cancelButtonTitle:actionTitle otherButtonTitles:nil];
            av.delegate = self;
            [av show];
        }
        return;
    }
    
    if (self.photobookPhotos.count < self.product.quantityToFulfillOrder){
        NSString *alertTitle = NSLocalizedString(@"You can add more photos", @"");
        NSString *alertMessage = NSLocalizedString(@"Are you sure you want to proceed? If you do, the blank pages will be filled in with duplicate photos", @"");
        NSString *actionTitle = NSLocalizedString(@"Yes, proceed", @"");
        if ([UIAlertController class]){
            UIAlertController *ac = [UIAlertController alertControllerWithTitle:alertTitle message:alertMessage preferredStyle:UIAlertControllerStyleAlert];
            [ac addAction:[UIAlertAction actionWithTitle:actionTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
                [self proceedToBookReview];
            }]];
            [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"No, not yet", @"") style:UIAlertActionStyleCancel handler:NULL]];
            [self presentViewController:ac animated:YES completion:NULL];
        }
        else{
            UIAlertView *av = [[UIAlertView alloc] initWithTitle:alertTitle message:alertMessage delegate:self cancelButtonTitle:NSLocalizedString(@"No, not yet", @"") otherButtonTitles:actionTitle, nil];
            av.tag = 172;
            [av show];
        }
    }
    else{
        [self proceedToBookReview];
    }
    
}

- (void)photobook:(OLPhotobookViewController *)photobook userDidTapOnImageWithIndex:(NSInteger)index{
    if (self.animating == YES){
        return;
    }
    self.animating = YES;
    if (index == -1){ //Replace Cover
        self.addNewPhotosAtIndex = index;
        [self addMorePhotosFromView:photobook.view];
        self.animating = NO;
        return;
    }
    
    OLPhotobookPageContentViewController *page = [self findPageForImageIndex:index];
    if (self.selectedIndexNumber && [self.selectedIndexNumber integerValue] == index){ //deselect
        [[self findPageForImageIndex:[self.selectedIndexNumber integerValue]] unhighlightImageAtIndex:index];
        self.selectedIndexNumber = nil;
        self.animating = NO;
    }
    else if (self.selectedIndexNumber){ //swap
        OLPhotobookPageContentViewController *selectedPage = [self findPageForImageIndex:[self.selectedIndexNumber integerValue]];
        OLPrintPhoto *printPhoto = [self.photobookPhotos objectAtIndex:page.pageIndex];
        
        [page unhighlightImageAtIndex:index];
        [selectedPage unhighlightImageAtIndex:[self.selectedIndexNumber integerValue]];
        
        UIView *pageCopy = [page.imageView snapshotViewAfterScreenUpdates:YES];
        pageCopy.frame = [self.view convertRect:page.imageView.frame fromView:page.view];
        [page clearImage];
        
    
        if (selectedPage){ //Previously selected page is in view
            [self addPageShadowsToView:pageCopy];
            [self setPageShadowAlpha:pageCopy forIndex:index];
            [self.view addSubview:pageCopy];
            OLPhotobookViewController *selectedPhotobook = (OLPhotobookViewController *)selectedPage.parentViewController.parentViewController;
            UIView *selectedPageCopy = [selectedPage.imageView snapshotViewAfterScreenUpdates:YES];
            [selectedPage clearImage];
            selectedPageCopy.frame = [self.view convertRect:selectedPage.imageView.frame fromView:selectedPage.view];
            [self addPageShadowsToView:selectedPageCopy];
            [self setPageShadowAlpha:selectedPageCopy forIndex:[self.selectedIndexNumber integerValue]];
            
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
                [self setPageShadowAlpha:selectedPageCopy forIndex:index];
                
                if (printPhoto != (id)[NSNull null]){
                    [self setPageShadowAlpha:pageCopy forIndex:[self.selectedIndexNumber integerValue]];
                    pageCopy.frame = selectedPageCopy.frame;
                }
                selectedPageCopy.frame = tempFrame;
            } completion:^(BOOL finished){
                [self swapImageAtIndex:[self.selectedIndexNumber integerValue] withImageAtIndex:page.pageIndex];
                self.selectedIndexNumber = nil;
                photobook.userSelectedPhotos = self.photobookPhotos;
                
                [(OLPhotobookViewController *)selectedPage.parentViewController.parentViewController setUserSelectedPhotos:self.photobookPhotos];
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
            if (self.photobookPhotos[index] == (id)[NSNull null]){
                [pageCopy viewWithTag:12].alpha = 0;
                [pageCopy viewWithTag:22].alpha = 0;
            }

            [self swapImageAtIndex:[self.selectedIndexNumber integerValue] withImageAtIndex:page.pageIndex];
            photobook.userSelectedPhotos = self.photobookPhotos;
            for (OLPhotobookViewController *otherPhotobook in self.childViewControllers){
                otherPhotobook.userSelectedPhotos = self.photobookPhotos;
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
                [self setPageShadowAlpha:selectedPageCopy forIndex:[self.selectedIndexNumber integerValue]];
                [self.view addSubview:selectedPageCopy];
                
                [UIView animateWithDuration:0.5 animations:^{
                    [self setPageShadowAlpha:selectedPageCopy forIndex:index];
                    
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
                    
                    if (self.photobookPhotos[index] != (id)[NSNull null]){
                        if (index % 2 == 0){
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
    else if ([self.photobookPhotos objectAtIndex:index] == (id)[NSNull null]){ //pick new images
        self.addNewPhotosAtIndex = index;
        [self addMorePhotosFromView:page.view];
        self.animating = NO;
    }
    else{ //select
        self.selectedIndexNumber = [NSNumber numberWithInteger:index];
        [page highlightImageAtIndex:index];
        self.animating = NO;
    }
    
}

- (void)photobook:(OLPhotobookViewController *)photobook userDidLongPressOnImageWithIndex:(NSInteger)index sender:(UILongPressGestureRecognizer *)sender{
    OLImageView *view;
    if (index == -1){
        view = (OLImageView *)sender.view;
    }
    else{
        if (self.photobookPhotos[index] == (id)[NSNull null]){
            return;
        }
        view = (OLImageView *)[photobook.pageController.viewControllers[index % 2] imageView];
    }
    
    self.interactionImageIndex = index;
    self.interactionPhotobook = photobook;
    
    view.delegate = self;
    [view becomeFirstResponder];
    UIMenuItem *deleteItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Remove", @"") action:@selector(deletePage)];
    UIMenuItem *cropImageItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Crop", @"") action:@selector(cropImage)];
//    UIMenuItem *addPageItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Add Page", @"") action:@selector(addPage)];
    
    UIMenuController *mc = [UIMenuController sharedMenuController];
    [mc setMenuItems:@[deleteItem, cropImageItem]];
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
        return cell;
    }
    else{
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"bookPreviewCell" forIndexPath:indexPath];
    }
    
    UIView *view = [cell viewWithTag:10];
    if (!view){
        OLPhotobookViewController *photobook = [self.storyboard instantiateViewControllerWithIdentifier:@"PhotobookViewController"];
        if (indexPath.section == kSectionPages){
            photobook.startOpen = YES;
        }
                
        photobook.userSelectedPhotos = self.photobookPhotos;
        if (indexPath.section == kSectionCover){
            photobook.editingPageNumber = nil;
        }
        else{
            photobook.editingPageNumber = [NSNumber numberWithInteger:indexPath.item * 2];
        }
        
        photobook.product = self.product;
        photobook.delegate = self.delegate;
        photobook.editMode = YES;
        [self addChildViewController:photobook];
        [cell addSubview:photobook.view];
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
    
    return cell;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    if (section == kSectionCover || section == kSectionHelp){
        return 1;
    }
    else{
        return self.product.quantityToFulfillOrder / 2.0;
    }
    
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 3;
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
    CGFloat min = MIN(size.width, size.height);
    return (min) / (self.product.productTemplate.sizeCm.width*2 / self.product.productTemplate.sizeCm.height);
}

#pragma mark - OLScrollCropView delegate

- (void)scrollCropViewControllerDidCancel:(OLScrollCropViewController *)cropper{
    [cropper dismissViewControllerAnimated:YES completion:NULL];
}

-(void)scrollCropViewController:(OLScrollCropViewController *)cropper didFinishCroppingImage:(UIImage *)croppedImage{
    if (self.interactionImageIndex == -1){
        [self.coverPhoto unloadImage];
        [self.coverPhoto setAsset:[OLAsset assetWithImageAsJPEG:croppedImage]];
        self.interactionPhotobook.coverPhoto = self.coverPhoto;
        [self.interactionPhotobook loadCoverPhoto];
        
    }
    else{
        [self.photobookPhotos[self.interactionImageIndex] unloadImage];
        [self.photobookPhotos[self.interactionImageIndex] setAsset:[OLAsset assetWithImageAsJPEG:croppedImage]];
        
        [[self findPageForImageIndex:self.interactionImageIndex] loadImageWithCompletionHandler:NULL];
    }
    
    [cropper dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - Adding new images

- (void)addMorePhotosFromView:(UIView *)view{
    if ([self instagramEnabled] || [self facebookEnabled]){
        if ([UIAlertController class]){
            UIAlertController *ac = [UIAlertController alertControllerWithTitle:nil message:NSLocalizedString(@"Add photos from:", @"") preferredStyle:UIAlertControllerStyleActionSheet];
            [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Camera Roll", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
                [self showCameraRollImagePicker];
            }]];
            if ([self instagramEnabled]){
                [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Instagram", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
                    [self showInstagramImagePicker];
                }]];
            }
            if ([self facebookEnabled]){
                [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Facebook", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
                    [self showFacebookImagePicker];
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
            UIActionSheet *as;
            if ([self instagramEnabled] && [self facebookEnabled]){
                as = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Add photos from:", @"") delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"") destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Camera Roll", @""),
                      NSLocalizedString(@"Instagram", @""),
                      NSLocalizedString(@"Facebook", @""),
                      nil];
            }
            else if ([self instagramEnabled]){
                as = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Add photos from:", @"") delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"") destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Camera Roll", @""),
                      NSLocalizedString(@"Instagram", @""),
                      nil];
            }
            else if ([self facebookEnabled]){
                as = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Add photos from:", @"") delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"") destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Camera Roll", @""),
                      NSLocalizedString(@"Facebook", @""),
                      nil];
            }
            else{
                as = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Add photos from:", @"") delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"") destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Camera Roll", @""),
                      nil];
            }
            [as showInView:self.view];
        }
    }
    else{
        [self showCameraRollImagePicker];
    }
}

- (void)showCameraRollImagePicker{
    CTAssetsPickerController *picker = [[CTAssetsPickerController alloc] init];
    picker.delegate = self;
    picker.assetsFilter = [ALAssetsFilter allPhotos];
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)showFacebookImagePicker{
#ifdef OL_KITE_OFFER_FACEBOOK
    OLFacebookImagePickerController *picker = nil;
    picker = [[OLFacebookImagePickerController alloc] init];
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
#endif
}

- (void)showInstagramImagePicker{
#ifdef OL_KITE_OFFER_INSTAGRAM
    OLInstagramImagePickerController *picker = nil;
    picker = [[OLInstagramImagePickerController alloc] initWithClientId:[OLKitePrintSDK instagramClientID] secret:[OLKitePrintSDK instagramSecret] redirectURI:[OLKitePrintSDK instagramRedirectURI]];
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
#endif
}

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
        if (![object.asset isKindOfClass:class] || [photoArray containsObjectIdenticalTo:object]) {
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
    
    [self.userSelectedPhotos addObjectsFromArray:addArray];
    
    [self updatePhotobookPhotos];
    for (OLPhotobookViewController *photobook in self.childViewControllers){
        if (!photobook.bookClosed){
            photobook.userSelectedPhotos = self.photobookPhotos;
            for (OLPhotobookPageContentViewController *page in photobook.pageController.viewControllers){
                [page loadImageWithCompletionHandler:NULL];
            }
        }
    }
    
}

#pragma mark - CTAssetsPickerControllerDelegate Methods

- (BOOL)assetsPickerController:(CTAssetsPickerController *)picker isDefaultAssetsGroup:(ALAssetsGroup *)group {
    if ([self.delegate respondsToSelector:@selector(kiteController:isDefaultAssetsGroup:)]) {
        return [self.delegate kiteController:[self kiteViewController] isDefaultAssetsGroup:group];
    }
    
    return NO;
}

- (void)assetsPickerController:(CTAssetsPickerController *)picker didFinishPickingAssets:(NSArray *)assets {
    if (self.addNewPhotosAtIndex == -1){
        self.coverPhoto = [[OLPrintPhoto alloc] init];
        self.coverPhoto.asset = [assets firstObject];
        
        for (OLPhotobookViewController *photobook in self.childViewControllers){
            if ([photobook bookClosed]){
                photobook.coverPhoto = self.coverPhoto;
                [photobook loadCoverPhoto];
                break;
            }
        }
        
        [picker dismissViewControllerAnimated:YES completion:NULL];
        return;
    }
    
    [self populateArrayWithNewArray:assets dataType:[ALAsset class]];
    [picker dismissViewControllerAnimated:YES completion:^(void){}];
}

- (BOOL)assetsPickerController:(CTAssetsPickerController *)picker shouldSelectAsset:(ALAsset *)asset{
    if (self.addNewPhotosAtIndex == -1){
        return picker.selectedAssets.count == 0;
    }
    else{
        return YES;
    }
}

- (BOOL)assetsPickerController:(CTAssetsPickerController *)picker shouldShowAssetsGroup:(ALAssetsGroup *)group{
    if (group.numberOfAssets == 0){
        return NO;
    }
    return YES;
}

- (BOOL)assetsPickerController:(CTAssetsPickerController *)picker shouldShowAsset:(ALAsset *)asset{
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
    if (self.addNewPhotosAtIndex == -1){
        if (images.count > 0){
            self.coverPhoto = [[OLPrintPhoto alloc] init];
            self.coverPhoto.asset = [images firstObject];
        }
        
        for (OLPhotobookViewController *photobook in self.childViewControllers){
            if ([photobook bookClosed]){
                photobook.coverPhoto = self.coverPhoto;
                [photobook loadCoverPhoto];
                break;
            }
        }
        
        [imagePicker dismissViewControllerAnimated:YES completion:NULL];
        return;
    }
    
    [self populateArrayWithNewArray:images dataType:[OLInstagramImage class]];
    [self dismissViewControllerAnimated:YES completion:^(void){}];
}

- (void)instagramImagePickerDidCancelPickingImages:(OLInstagramImagePickerController *)imagePicker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)instagramImagePicker:(OLInstagramImagePickerController *)imagePicker shouldSelectImage:(OLInstagramImage *)image{
    if (self.addNewPhotosAtIndex == -1){
        return imagePicker.selected.count == 0;
    }
    else{
        return YES;
    }
}
#endif

#ifdef OL_KITE_OFFER_FACEBOOK
#pragma mark - OLFacebookImagePickerControllerDelegate Methods

- (void)facebookImagePicker:(OLFacebookImagePickerController *)imagePicker didFailWithError:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)facebookImagePicker:(OLFacebookImagePickerController *)imagePicker didFinishPickingImages:(NSArray *)images {
    if (self.addNewPhotosAtIndex == -1){
        if (images.count > 0){
            self.coverPhoto = [[OLPrintPhoto alloc] init];
            self.coverPhoto.asset = [images firstObject];
        }
        
        for (OLPhotobookViewController *photobook in self.childViewControllers){
            if ([photobook bookClosed]){
                photobook.coverPhoto = self.coverPhoto;
                [photobook loadCoverPhoto];
                break;
            }
        }
        
        [imagePicker dismissViewControllerAnimated:YES completion:NULL];
        return;
    }
    [self populateArrayWithNewArray:images dataType:[OLFacebookImage class]];
    [self dismissViewControllerAnimated:YES completion:^(void){}];
}

- (void)facebookImagePickerDidCancelPickingImages:(OLFacebookImagePickerController *)imagePicker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)facebookImagePicker:(OLFacebookImagePickerController *)imagePicker shouldSelectImage:(OLFacebookImage *)image{
    if (self.addNewPhotosAtIndex == -1){
        return imagePicker.selected.count == 0;
    }
    else{
        return YES;
    }
}
#endif

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

- (OLKiteViewController *)kiteViewController {
    for (UIViewController *vc in self.navigationController.viewControllers) {
        if ([vc isMemberOfClass:[OLKiteViewController class]]) {
            return (OLKiteViewController *) vc;
        }
    }
    
    return nil;
}

#pragma mark UIActionSheet Delegate (only used on iOS 7)

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 0){
        [self showCameraRollImagePicker];
    }
    else if (buttonIndex == 1){
        if ([self instagramEnabled]){
            [self showInstagramImagePicker];
        }
        else{
            [self showFacebookImagePicker];
        }
    }
    else if (buttonIndex == 2){
        [self showFacebookImagePicker];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (alertView.tag == 172){
        if (buttonIndex == 1){
            [self proceedToBookReview];
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

- (NSUInteger)supportedInterfaceOrientations {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8) {
        return UIInterfaceOrientationMaskAll;
    }
    else{
        return UIInterfaceOrientationMaskPortrait;
    }
}

@end
