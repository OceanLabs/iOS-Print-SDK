//
//  OrderReviewViewController.m
//  Kite Print SDK
//
//  Created by Kostas Karayannis on 17/07/2014.
//  Copyright (c) 2014 Ocean Labs. All rights reserved.
//

#import "OLOrderReviewViewController.h"
#import "OLPrintPhoto.h"
#import "OLAsset.h"
#import "OLCheckoutViewController.h"
#import "OLProductPrintJob.h"
#import "OLConstants.h"
#import "OLCheckoutDelegate.h"
#import "OLProductTemplate.h"
#import "OLProduct.h"
#import "OLCircleMaskCollectionViewCell.h"
#import "OLAsset+Private.h"
#import "OLAnalytics.h"
#import "OLKitePrintSDK.h"
#import <CTAssetsPickerController.h>

static const NSUInteger kTagAlertViewSelectMorePhotos = 99;
static const NSUInteger kTagAlertViewDeletePhoto = 98;

@interface OLKitePrintSDK (InternalUtils)
+ (NSString *)userEmail:(UIViewController *)topVC;
+ (NSString *)userPhone:(UIViewController *)topVC;
+ (id<OLKiteDelegate>)kiteDelegate:(UIViewController *)topVC;
@end

@interface OLOrderReviewViewController () <OLCheckoutDelegate, UIAlertViewDelegate, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *confirmBarButton;
@property (weak, nonatomic) OLPrintPhoto *editingPrintPhoto;
@property (strong, nonatomic) UIView *addMorePhotosView;
@property (strong, nonatomic) UIButton *addMorePhotosButton;
@property (assign, nonatomic) NSUInteger indexOfPhotoToDelete;

@end

@implementation OLOrderReviewViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackReviewScreenViewed:self.product.productTemplate.name];
#endif
    
    self.extraCopiesOfAssets = [[NSMutableArray alloc] initWithCapacity:[self.userSelectedPhotos count]];
    for (int i = 0; i < [self.userSelectedPhotos count]; i++){
        [self.extraCopiesOfAssets addObject:@0];
    }
    [self updateTitleBasedOnSelectedPhotoQuanitity];
    
    self.confirmBarButton.title = NSLocalizedString(@"Confirm", "");
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", @"")
                                                                             style:UIBarButtonItemStyleBordered
                                                                            target:nil
                                                                            action:nil];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [self.collectionView.collectionViewLayout invalidateLayout];
}

-(NSUInteger) totalNumberOfExtras{
    NSUInteger res = 0;
    for (NSNumber* num in self.extraCopiesOfAssets){
        res += [num integerValue];
    }
    return res;
}

- (void)updateTitleBasedOnSelectedPhotoQuanitity {
    NSUInteger numOrders = 1 + (MAX(0, self.userSelectedPhotos.count - 1 + [self totalNumberOfExtras]) / self.product.quantityToFulfillOrder);
    NSUInteger quanityToFulfilOrder = numOrders * self.product.quantityToFulfillOrder;
    self.title = [NSString stringWithFormat:@"%lu / %lu", (unsigned long) (self.userSelectedPhotos.count + [self totalNumberOfExtras]), (unsigned long)quanityToFulfilOrder];
}

-(BOOL) shouldGoToCheckout{
    NSUInteger selectedCount = self.userSelectedPhotos.count + [self totalNumberOfExtras];
    NSUInteger numOrders = 1 + (MAX(0, selectedCount - 1) / self.product.quantityToFulfillOrder);
    NSUInteger quantityToFulfilOrder = numOrders * self.product.quantityToFulfillOrder;
    if (selectedCount < quantityToFulfilOrder) {
        NSUInteger canSelectExtraCount = quantityToFulfilOrder - selectedCount;
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"You've selected %d photos.", @""),selectedCount] message:[NSString stringWithFormat:NSLocalizedString(@"You can add %d more for the same price.", @""), canSelectExtraCount] delegate:nil cancelButtonTitle:NSLocalizedString(@"Add more", @"") otherButtonTitles:NSLocalizedString(@"Print these", @""), nil];
        av.tag = kTagAlertViewSelectMorePhotos;
        av.delegate = self;
        [av show];
        return NO;
    }
    return YES;
}

- (void)doCheckout {
    int originalCount = (int)[self.userSelectedPhotos count];
    NSMutableArray* userSelectedPhotosAndExtras = [[NSMutableArray alloc] initWithCapacity:originalCount + [self totalNumberOfExtras]];
    [userSelectedPhotosAndExtras addObjectsFromArray:self.userSelectedPhotos];
    for (int i = 0; i < originalCount; i++) {
        int numberOfCopies = [((NSNumber*)self.extraCopiesOfAssets[i]) intValue];
        for (int j = 0; j < numberOfCopies; j++){
            [userSelectedPhotosAndExtras addObject:self.userSelectedPhotos[i]];
        }
    }
    
    NSUInteger iphonePhotoCount = 0;
    for (OLPrintPhoto *photo in userSelectedPhotosAndExtras) {
        if (photo.type == kPrintPhotoAssetTypeALAsset) ++iphonePhotoCount;
    }
    
    // Avoid uploading assets if possible. We can avoid uploading where the image already exists at a remote
    // URL and the user did not manipulate it in any way.
    NSMutableArray *photoAssets = [[NSMutableArray alloc] init];
    for (OLPrintPhoto *photo in userSelectedPhotosAndExtras) {
        if(photo.type == kPrintPhotoAssetTypeOLAsset){
            [photoAssets addObject:photo.asset];
        } else {
            [photoAssets addObject:[OLAsset assetWithDataSource:photo]];
        }
    }
    
    // ensure order is maxed out by adding duplicates as necessary
    NSUInteger userSelectedAssetCount = photoAssets.count;
    NSUInteger numOrders = (NSUInteger) floor(userSelectedAssetCount + self.product.quantityToFulfillOrder - 1) / self.product.quantityToFulfillOrder;
    NSUInteger duplicatesToFillOrder = numOrders * self.product.quantityToFulfillOrder - userSelectedAssetCount;
    for (NSUInteger i = 0; i < duplicatesToFillOrder; ++i) {
        [photoAssets addObject:photoAssets[i % userSelectedAssetCount]];
    }
    NSLog(@"Adding %lu duplicates", (unsigned long)duplicatesToFillOrder);
        
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString *appVersion = [infoDict objectForKey:@"CFBundleShortVersionString"];
    NSNumber *buildNumber = [infoDict objectForKey:@"CFBundleVersion"];
    
    OLPrintOrder *printOrder = [[OLPrintOrder alloc] init];
    printOrder.userData = @{@"photo_count_iphone": [NSNumber numberWithUnsignedInteger:iphonePhotoCount],
                            @"sdk_version": kOLKiteSDKVersion,
                            @"platform": @"iOS",
                            @"uid": [[[UIDevice currentDevice] identifierForVendor] UUIDString],
                            @"app_version": [NSString stringWithFormat:@"Version: %@ (%@)", appVersion, buildNumber]
                            };
    OLProductPrintJob* printJob = [[OLProductPrintJob alloc] initWithTemplateId:self.product.templateId OLAssets:photoAssets];
    for (id<OLPrintJob> job in printOrder.jobs){
        [printOrder removePrintJob:job];
    }
    [printOrder addPrintJob:printJob];

    
    OLCheckoutViewController *vc = [[OLCheckoutViewController alloc] initWithPrintOrder:printOrder];
    vc.userEmail = [OLKitePrintSDK userEmail:self];
    vc.userPhone = [OLKitePrintSDK userPhone:self];
    vc.kiteDelegate = [OLKitePrintSDK kiteDelegate:self];
    
    
    [self.navigationController pushViewController:vc animated:YES];
}

- (OLKiteViewController *)kiteViewController {
    for (UIViewController *vc in self.navigationController.viewControllers) {
        if ([vc isMemberOfClass:[OLKiteViewController class]]) {
            return (OLKiteViewController *) vc;
        }
    }
    
    return nil;
}

- (void)onUserSelectedPhotoCountChange {
    [self updateTitleBasedOnSelectedPhotoQuanitity];
}

- (BOOL) shouldShowContinueShoppingButton{
    return NO;
}

- (void) deletePhotoAtIndex:(NSUInteger)index{
    [self.assets removeObjectAtIndex:index];
    [self.userSelectedPhotos removeObjectAtIndex:index];
    [self.extraCopiesOfAssets removeObjectAtIndex:index];
    
    [self updateTitleBasedOnSelectedPhotoQuanitity];
    
    [self.collectionView deleteItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]]];
}

- (CGFloat) productAspectRatio{
    UIEdgeInsets b = self.product.productTemplate.imageBorder;
    if (b.top < b.bottom){
        return 1;
    }
    else{
        return self.product.productTemplate.sizeCm.height / self.product.productTemplate.sizeCm.width;
    }
}

#pragma mark Button Actions

- (IBAction)onButtonUpArrowClicked:(UIButton *)sender {
    UIView* cellContentView = sender.superview;
    UIView* cell = cellContentView.superview;
    while (![cell isKindOfClass:[UICollectionViewCell class]]){
        cell = cell.superview;
    }
    NSIndexPath* indexPath = [self.collectionView indexPathForCell:(UICollectionViewCell *)cell];
    
    NSUInteger extraCopies = [self.extraCopiesOfAssets[indexPath.row] integerValue] + 1;
    self.extraCopiesOfAssets[indexPath.row] = [NSNumber numberWithInteger:extraCopies];
    UILabel* countLabel = (UILabel *)[cellContentView viewWithTag:30];
    [countLabel setText: [NSString stringWithFormat:@"%lu", (unsigned long)extraCopies + 1]];
    
    [self updateTitleBasedOnSelectedPhotoQuanitity];
}

- (IBAction)onButtonDownArrowClicked:(UIButton *)sender {
    UIView* cellContentView = sender.superview;
    UIView* cell = cellContentView.superview;
    while (![cell isKindOfClass:[UICollectionViewCell class]]){
        cell = cell.superview;
    }
    NSIndexPath* indexPath = [self.collectionView indexPathForCell:(UICollectionViewCell *)cell];
    
    NSUInteger extraCopies = [self.extraCopiesOfAssets[indexPath.row] integerValue];
    if (extraCopies == 0){
        if ([UIAlertController class]){
            UIAlertController *ac = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Delete?", @"") message:NSLocalizedString(@"Do you want to delete this photo?", @"") preferredStyle:UIAlertControllerStyleAlert];
            [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Yes, delete it", @"") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action){
                [self deletePhotoAtIndex:indexPath.row];
            }]];
            [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"No, keep it", @"") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action){}]];
            [self presentViewController:ac animated:YES completion:NULL];
        }
        else{
            UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Delete?", @"") message:NSLocalizedString(@"Do you want to delete this photo?", @"") delegate:self cancelButtonTitle:NSLocalizedString(@"Yes, delete it", @"") otherButtonTitles:NSLocalizedString(@"No, keep it", @""), nil];
            self.indexOfPhotoToDelete = indexPath.row;
            av.tag = kTagAlertViewDeletePhoto;
            [av show];
        };
        return;
    }
    extraCopies--;
    
    self.extraCopiesOfAssets[indexPath.row] = [NSNumber numberWithInteger:extraCopies];
    UILabel* countLabel = (UILabel *)[cellContentView viewWithTag:30];
    [countLabel setText: [NSString stringWithFormat:@"%lu", (unsigned long)extraCopies + 1]];
    
    [self updateTitleBasedOnSelectedPhotoQuanitity];
}

- (IBAction)onButtonEnhanceClicked:(id)sender {
    UIView *cellContentView;
    if ([sender isKindOfClass: [UIButton class]]){
        cellContentView = [(UIButton *)sender superview];
    }
    else if ([sender isKindOfClass:[UITapGestureRecognizer class]]){
        cellContentView = [(UITapGestureRecognizer *)sender view];
    }
    UIView *cell = cellContentView.superview;
    while (![cell isKindOfClass:[UICollectionViewCell class]]){
        cell = cell.superview;
    }
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:(UICollectionViewCell *)cell];
    
    OLPrintPhoto *tempPrintPhoto = [[OLPrintPhoto alloc] init];
    tempPrintPhoto.asset = self.assets[indexPath.row];
    self.editingPrintPhoto = self.userSelectedPhotos[indexPath.row];
    
    UINavigationController *nav = [self.storyboard instantiateViewControllerWithIdentifier:@"CropViewNavigationController"];
    OLScrollCropViewController *cropVc = (id)nav.topViewController;
    cropVc.enableCircleMask = self.product.productTemplate.templateUI == kOLTemplateUICircle;
    cropVc.delegate = self;
    cropVc.aspectRatio = [self productAspectRatio];
    [tempPrintPhoto getImageWithProgress:NULL completion:^(UIImage *image){
        [cropVc setFullImage:image];
        [self presentViewController:nav animated:YES completion:NULL];
    }];
}

- (IBAction)onButtonNextClicked:(UIBarButtonItem *)sender {
    if (![self shouldGoToCheckout]){
        return;
    }
    
    [self doCheckout];
}

- (IBAction)onButtonImageClicked:(UIButton *)sender {
    [self onButtonEnhanceClicked:sender];
}

#pragma mark UICollectionView data source and delegate methods

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return [self.userSelectedPhotos count];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    OLCircleMaskCollectionViewCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"reviewPhotoCell" forIndexPath:indexPath];
    
    UIView *borderView = [cell.contentView viewWithTag:399];
    
    UIActivityIndicatorView *activityIndicator = (UIActivityIndicatorView *)[cell.contentView viewWithTag:278];
    [activityIndicator startAnimating];
    
    UIImageView *cellImage = (UIImageView *)[cell.contentView viewWithTag:10];
    [cellImage removeFromSuperview];
    
    cellImage = [[UIImageView alloc] initWithFrame:borderView.frame];
    cellImage.tag = 10;
    cellImage.translatesAutoresizingMaskIntoConstraints = NO;
    cellImage.contentMode = UIViewContentModeScaleAspectFill;
    cellImage.clipsToBounds = YES;
    [cell.contentView insertSubview:cellImage aboveSubview:activityIndicator];
    
    cellImage.userInteractionEnabled = YES;
    [cellImage addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onButtonEnhanceClicked:)]];
    
    UIButton *enhanceButton = (UIButton *)[cell.contentView viewWithTag:11];
    [enhanceButton addTarget:self action:@selector(onButtonEnhanceClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *upButton = (UIButton *)[cell.contentView viewWithTag:12];
    [upButton addTarget:self action:@selector(onButtonUpArrowClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *downButton = (UIButton *)[cell.contentView viewWithTag:13];
    [downButton addTarget:self action:@selector(onButtonDownArrowClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    UILabel *countLabel = (UILabel *)[cell.contentView viewWithTag:30];
    [countLabel setText: [NSString stringWithFormat:@"%lu", (unsigned long)(1+[((NSNumber*)[self.extraCopiesOfAssets objectAtIndex:indexPath.row]) integerValue])]];
    
    [((OLPrintPhoto*)[self.userSelectedPhotos objectAtIndex:indexPath.row]) setImageIdealSizeForImageView:cellImage highQuality:YES];
    
    if (self.product.productTemplate.templateUI == kOLTemplateUICircle){
        cell.enableMask = YES;
    }
    
    UIEdgeInsets b = self.product.productTemplate.imageBorder;
    
    NSLayoutConstraint *topCon = [NSLayoutConstraint constraintWithItem:cellImage attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:borderView attribute:NSLayoutAttributeTop multiplier:1 constant:b.top];
    NSLayoutConstraint *leftCon = [NSLayoutConstraint constraintWithItem:cellImage attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:borderView attribute:NSLayoutAttributeLeft multiplier:1 constant:b.left];
    NSLayoutConstraint *rightCon = [NSLayoutConstraint constraintWithItem:cellImage attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:borderView attribute:NSLayoutAttributeRight multiplier:1 constant:-b.right];
    NSLayoutConstraint *bottomCon = [NSLayoutConstraint constraintWithItem:cellImage attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationLessThanOrEqual toItem:borderView attribute:NSLayoutAttributeBottom multiplier:1 constant:-b.bottom];
    
    NSLayoutConstraint *aspectRatioCon = [NSLayoutConstraint constraintWithItem:cellImage attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:cellImage attribute:NSLayoutAttributeHeight multiplier:1 constant:0];
    aspectRatioCon.priority = 750;
    NSLayoutConstraint *activityCenterXCon = [NSLayoutConstraint constraintWithItem:cellImage attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:activityIndicator attribute:NSLayoutAttributeCenterX multiplier:1 constant:0];
    NSLayoutConstraint *activityCenterYCon = [NSLayoutConstraint constraintWithItem:cellImage attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:activityIndicator attribute:NSLayoutAttributeCenterY multiplier:1 constant:0];
    
    [borderView.superview addConstraints:@[topCon, leftCon, rightCon, bottomCon, activityCenterYCon, activityCenterXCon]];
    [cellImage addConstraints:@[aspectRatioCon]];
    
    
    
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UIEdgeInsets b = self.product.productTemplate.imageBorder;
    
    CGFloat width = 320;
    CGFloat heightForButtons = 69;
    CGFloat imageHeight = (width - b.right - b.left) * [self productAspectRatio] * 1;
    CGFloat height = imageHeight + (b.top + b.bottom) * 1 + heightForButtons;
    
    return CGSizeMake(width, height);

}

-(CGFloat)marginBetweenCellsForCollectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout{
    CGFloat width = self.view.bounds.size.width;
    CGFloat cellWidth = [self collectionView:collectionView layout:collectionViewLayout sizeForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]].width;
    int cellsPerRow = width / cellWidth;
    CGFloat spaceLeft = width - (cellsPerRow * cellWidth);
    CGFloat margin = spaceLeft / (cellsPerRow + 1);
    return margin;
}

// 3
- (UIEdgeInsets)collectionView:
(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    CGFloat margin = [self marginBetweenCellsForCollectionView:collectionView layout:collectionViewLayout];
    return UIEdgeInsetsMake(0, margin, 0, margin);
}
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 0;//[self marginBetweenCellsForCollectionView:collectionView layout:collectionViewLayout];
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 20.0;
}

#pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == kTagAlertViewSelectMorePhotos) {
        if (buttonIndex == 1) {
            [self doCheckout];
        }
    }
    else if (alertView.tag == kTagAlertViewDeletePhoto) {
        if (buttonIndex == 0){
            [self deletePhotoAtIndex:self.indexOfPhotoToDelete];
        }
    }
}

#pragma mark - OLImageEditorViewControllerDelegate methods

-(void)userDidCropImage:(UIImage *)croppedImage{
    [self.editingPrintPhoto unloadImage];
    self.editingPrintPhoto.asset = [OLAsset assetWithImageAsJPEG:croppedImage];
    
    [self.collectionView reloadData];
}

@end
