//
//  OLOrderReviewCollectionViewViewController.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 1/29/15.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import "OLOrderReviewCollectionViewViewController.h"
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
#import <SDWebImageManager.h>
#import "OLAnalytics.h"

static const NSUInteger kTagAlertViewSelectMorePhotos = 99;

@interface OLOrderReviewCollectionViewViewController ()

@property (weak, nonatomic) IBOutlet UIBarButtonItem *confirmBarButton;
@property (weak, nonatomic) OLPrintPhoto *editingPrintPhoto;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@end

@implementation OLOrderReviewCollectionViewViewController

-(NSArray *) userSelectedPhotos{
    if (!_userSelectedPhotos){
        NSMutableArray *mutableUserSelectedPhotos = [[NSMutableArray alloc] init];
        for (id asset in self.assets){
            OLPrintPhoto *printPhoto = [[OLPrintPhoto alloc] init];
            printPhoto.serverImageSize = [self.product serverImageSize];
            printPhoto.asset = asset;
            [mutableUserSelectedPhotos addObject:printPhoto];
        }
        _userSelectedPhotos = mutableUserSelectedPhotos;
    }
    return _userSelectedPhotos;
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
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
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
    
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onUserSelectedPhotoCountChange {
    [self updateTitleBasedOnSelectedPhotoQuanitity];
}

- (BOOL) shouldShowContinueShoppingButton{
    return NO;
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
        return;
    }
    extraCopies--;
    
    self.extraCopiesOfAssets[indexPath.row] = [NSNumber numberWithInteger:extraCopies];
    UILabel* countLabel = (UILabel *)[cellContentView viewWithTag:30];
    [countLabel setText: [NSString stringWithFormat:@"%lu", (unsigned long)extraCopies + 1]];
    
    [self updateTitleBasedOnSelectedPhotoQuanitity];
}

- (IBAction)onButtonEnhanceClicked:(UIButton *)sender {
    UIView* cellContentView = sender.superview;
    UIView* cell = cellContentView.superview;
    while (![cell isKindOfClass:[UICollectionViewCell class]]){
        cell = cell.superview;
    }
    NSIndexPath* indexPath = [self.collectionView indexPathForCell:(UICollectionViewCell *)cell];
    
    self.editingPrintPhoto = self.userSelectedPhotos[indexPath.row];
    self.editingPrintPhoto.asset = self.assets[indexPath.row];
    
    UINavigationController *nav = [self.storyboard instantiateViewControllerWithIdentifier:@"CropViewNavigationController"];
    OLScrollCropViewController *cropVc = (id)nav.topViewController;
    cropVc.enableCircleMask = self.product.productTemplate.templateClass == kOLTemplateClassCircle;
    cropVc.delegate = self;
    cropVc.aspectRatio = 1;
    if (((OLAsset *)(self.editingPrintPhoto.asset)).assetType == kOLAssetTypeRemoteImageURL){
        [[SDWebImageManager sharedManager] downloadImageWithURL:[((OLAsset *)(self.editingPrintPhoto.asset)) imageURL] options:0 progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *url) {
            if (finished) {
                [cropVc setFullImage:image];
                [self presentViewController:nav animated:YES completion:NULL];
            }
        }];
    }
    else{
        [[self.userSelectedPhotos objectAtIndex:0] dataWithCompletionHandler:^(NSData *data, NSError *error){
            [cropVc setFullImage:[UIImage imageWithData:data]];
            [self presentViewController:nav animated:YES completion:NULL];
        }];
    }
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

#pragma mark UICollectionView Data Source and Delegate methods

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return [self.userSelectedPhotos count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    OLCircleMaskCollectionViewCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"reviewPhotoCell" forIndexPath:indexPath];
    if (!cell) {
        cell = [[OLCircleMaskCollectionViewCell alloc] init];
    }
    
    UIImageView *cellImage = (UIImageView *)[cell.contentView viewWithTag:10];
    
    if (cellImage){
        [((OLPrintPhoto*)[self.userSelectedPhotos objectAtIndex:indexPath.row]) setThumbImageIdealSizeForImageView:cellImage];
    }
    
    UIButton *enhanceButton = (UIButton *)[cell.contentView viewWithTag:11];
    [enhanceButton addTarget:self action:@selector(onButtonEnhanceClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *upButton = (UIButton *)[cell.contentView viewWithTag:12];
    [upButton addTarget:self action:@selector(onButtonUpArrowClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *downButton = (UIButton *)[cell.contentView viewWithTag:13];
    [downButton addTarget:self action:@selector(onButtonDownArrowClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    UILabel *countLabel = (UILabel *)[cell.contentView viewWithTag:30];
    [countLabel setText: [NSString stringWithFormat:@"%lu", (unsigned long)(1+[((NSNumber*)[self.extraCopiesOfAssets objectAtIndex:indexPath.row]) integerValue])]];
    
    if (self.product.productTemplate.templateClass == kOLTemplateClassCircle){
        cell.enableMask = YES;
    }
    
    
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat width = 320;
    CGFloat extraHeightForPolaroid = 0;
    CGFloat extraHeightForButtons = 56;
    return CGSizeMake(width, width + extraHeightForButtons + extraHeightForPolaroid);
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
}

#pragma mark - OLImageEditorViewControllerDelegate methods

-(void)userDidCropImage:(UIImage *)croppedImage{
    self.editingPrintPhoto.asset = [OLAsset assetWithImageAsJPEG:croppedImage];
    
    [self.collectionView reloadData];
}


@end
