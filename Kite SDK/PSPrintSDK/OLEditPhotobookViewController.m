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

#ifdef OL_KITE_OFFER_INSTAGRAM
#import <OLInstagramImagePickerController.h>
#import <OLInstagramImage.h>
#endif

#ifdef OL_KITE_OFFER_FACEBOOK
#import <OLFacebookImagePickerController.h>
#import <OLFacebookImage.h>
#endif

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

@interface OLEditPhotobookViewController () <UICollectionViewDelegateFlowLayout, OLPhotobookViewControllerDelegate, CTAssetsPickerControllerDelegate, UIActionSheetDelegate, UIAlertViewDelegate, OLImageViewDelegate,
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

@end

@implementation OLEditPhotobookViewController

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

- (void)onButtonNextClicked{
    if (self.userSelectedPhotos.count == 0){
        
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
    
    if (self.userSelectedPhotos.count < self.product.quantityToFulfillOrder){
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
    photobook.assets = self.assets;
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

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"bookPreviewCell" forIndexPath:indexPath];
    
    UIView *view = [cell viewWithTag:10];
    if (!view){
        OLPhotobookViewController *photobook = [self.storyboard instantiateViewControllerWithIdentifier:@"PhotobookViewController"];
        photobook.assets = self.assets;
        
        photobook.userSelectedPhotos = self.photobookPhotos;
        photobook.editingPageNumber = [NSNumber numberWithInteger:indexPath.item * 2];
        
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
                photobook.userSelectedPhotos = self.photobookPhotos;
                if (self.selectedIndexNumber){
                    [[self findPageForImageIndex:[self.selectedIndexNumber integerValue]] highlightImageAtIndex:[self.selectedIndexNumber integerValue]];
                }
            }
        }
    }
    
    return cell;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.product.quantityToFulfillOrder / 2.0;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    return CGSizeMake(self.view.frame.size.width, [self cellHeightForSize:self.view.frame.size]);
}

- (CGFloat) cellHeightForSize:(CGSize)size{
    return (size.width) / (self.product.productTemplate.sizeCm.width*2 / self.product.productTemplate.sizeCm.height) + 40;
}

- (void)swapImageAtIndex:(NSInteger)index1 withImageAtIndex:(NSInteger)index2{
    [self.photobookPhotos exchangeObjectAtIndex:index1 withObjectAtIndex:index2];
}

- (OLPhotobookPageContentViewController *)findPageForImageIndex:(NSInteger)index{
    for (OLPhotobookViewController *photobook in self.childViewControllers){
        for (OLPhotobookPageContentViewController *page in photobook.pageController.viewControllers){
            if (page.pageIndex == index){
                return page;
            }
        }
    }
    return nil;
}

- (void)photobook:(OLPhotobookViewController *)photobook userDidTapOnImageWithIndex:(NSInteger)index{
    OLPhotobookPageContentViewController *page = [self findPageForImageIndex:index];
    if (self.selectedIndexNumber && [self.selectedIndexNumber integerValue] == index){ //deselect
        [[self findPageForImageIndex:[self.selectedIndexNumber integerValue]] unhighlightImageAtIndex:index];
        self.selectedIndexNumber = nil;
    }
    else if (self.selectedIndexNumber){ //swap
        [page unhighlightImageAtIndex:index];
        [self swapImageAtIndex:[self.selectedIndexNumber integerValue] withImageAtIndex:page.pageIndex];
        
        photobook.userSelectedPhotos = self.photobookPhotos;
        
        OLPhotobookPageContentViewController *selectedPage = [self findPageForImageIndex:[self.selectedIndexNumber integerValue]];
        [(OLPhotobookViewController *)selectedPage.parentViewController.parentViewController setUserSelectedPhotos:self.photobookPhotos];
        
        [selectedPage unhighlightImageAtIndex:[self.selectedIndexNumber integerValue]];
        self.selectedIndexNumber = nil;
    }
    else if ([self.photobookPhotos objectAtIndex:index] == (id)[NSNull null]){ //pick new images
        self.addNewPhotosAtIndex = index;
        [self addMorePhotosFromPage:page];
    }
    else{ //select
        self.selectedIndexNumber = [NSNumber numberWithInteger:index];
        [page highlightImageAtIndex:index];
    }

}

- (void)deletePage{
    self.photobookPhotos[self.interactionImageIndex] = [NSNull null];
    self.interactionPhotobook.userSelectedPhotos = self.photobookPhotos;
}

- (void)addPage{
    
}

- (void)cropImage{
    
}

- (void)photobook:(OLPhotobookViewController *)photobook userDidLongPressOnImageWithIndex:(NSInteger)index sender:(UILongPressGestureRecognizer *)sender{
    self.interactionImageIndex = index;
    self.interactionPhotobook = photobook;
    OLImageView *view = (OLImageView *)[photobook.pageController.viewControllers[index % 2] imageView];
    view.delegate = self;
    [view becomeFirstResponder];
    UIMenuItem *deleteItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Remove", @"") action:@selector(deletePage)];
//    UIMenuItem *cropImageItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Crop", @"") action:@selector(cropImage)];
//    UIMenuItem *addPageItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Add Page", @"") action:@selector(addPage)];
    
    UIMenuController *mc = [UIMenuController sharedMenuController];
    [mc setMenuItems:@[deleteItem]];
    [mc setTargetRect:view.frame inView:view];
    [mc setMenuVisible:YES animated:YES];
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
//        [self.collectionView reloadData];
    }completion:^(id<UIViewControllerTransitionCoordinator> context){
//        [self.collectionView reloadData];
    }];
}

#pragma mark - Adding new images

- (void)addMorePhotosFromPage:(OLPhotobookPageContentViewController *)page{
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
            ac.popoverPresentationController.sourceView = page.view;
            ac.popoverPresentationController.sourceRect = page.view.frame;
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

- (NSArray *)createAssetArray {
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:self.userSelectedPhotos.count];
    for (OLPrintPhoto *object in self.userSelectedPhotos) {
        [array addObject:object.asset];
    }
    return array;
}

- (void)showCameraRollImagePicker{
    CTAssetsPickerController *picker = [[CTAssetsPickerController alloc] init];
    picker.delegate = self;
    picker.assetsFilter = [ALAssetsFilter allPhotos];
    NSArray *allAssets = [[self createAssetArray] mutableCopy];
    NSMutableArray *alAssets = [[NSMutableArray alloc] init];
    for (id asset in allAssets){
        if ([asset isKindOfClass:[ALAsset class]]){
            [alAssets addObject:asset];
        }
    }
    picker.selectedAssets = alAssets;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)showFacebookImagePicker{
#ifdef OL_KITE_OFFER_FACEBOOK
    OLFacebookImagePickerController *picker = nil;
    picker = [[OLFacebookImagePickerController alloc] init];
    picker.delegate = self;
    picker.selected = [self createAssetArray];
    [self presentViewController:picker animated:YES completion:nil];
#endif
}

- (void)showInstagramImagePicker{
#ifdef OL_KITE_OFFER_INSTAGRAM
    OLInstagramImagePickerController *picker = nil;
    picker = [[OLInstagramImagePickerController alloc] initWithClientId:[OLKitePrintSDK instagramClientID] secret:[OLKitePrintSDK instagramSecret] redirectURI:[OLKitePrintSDK instagramRedirectURI]];
    picker.delegate = self;
    picker.selected = [self createAssetArray];
    [self presentViewController:picker animated:YES completion:nil];
#endif
}

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
    NSMutableArray *removeAssetArray = [NSMutableArray arrayWithArray:self.assets];
    for (OLPrintPhoto *object in self.userSelectedPhotos) {
        if (![object.asset isKindOfClass:class] || [photoArray containsObjectIdenticalTo:object]) {
            [removeAssetArray removeObjectAtIndex:[removeArray indexOfObjectIdenticalTo:object]];
            [removeArray removeObjectIdenticalTo:object];
        }
    }
    
    [self.userSelectedPhotos removeObjectsInArray:removeArray];
    [self.assets removeObjectsInArray:removeAssetArray];
    
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
    [self.assets addObjectsFromArray:addAssetArray];
    
    [self updatePhotobookPhotos];
    for (OLPhotobookViewController *photobook in self.childViewControllers){
        photobook.userSelectedPhotos = self.photobookPhotos;
    }
    
}

- (BOOL)assetsPickerController:(CTAssetsPickerController *)picker isDefaultAssetsGroup:(ALAssetsGroup *)group {
    if ([self.delegate respondsToSelector:@selector(kiteController:isDefaultAssetsGroup:)]) {
        return [self.delegate kiteController:[self kiteViewController] isDefaultAssetsGroup:group];
    }
    
    return NO;
}

- (void)assetsPickerController:(CTAssetsPickerController *)picker didFinishPickingAssets:(NSArray *)assets {
    [self populateArrayWithNewArray:assets dataType:[ALAsset class]];
    [picker dismissViewControllerAnimated:YES completion:^(void){}];
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
    [self populateArrayWithNewArray:images dataType:[OLInstagramImage class]];
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
    [self populateArrayWithNewArray:images dataType:[OLFacebookImage class]];
    [self dismissViewControllerAnimated:YES completion:^(void){}];
}

- (void)facebookImagePickerDidCancelPickingImages:(OLFacebookImagePickerController *)imagePicker {
    [self dismissViewControllerAnimated:YES completion:nil];
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
