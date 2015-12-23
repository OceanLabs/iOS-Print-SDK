//
//  OLPosterViewController.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 31/7/15.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#ifdef COCOAPODS
#import <SDWebImage/SDWebImageManager.h>
#else
#import "SDWebImageManager.h"
#endif

#import "OLPosterViewController.h"
#import "OLProduct.h"
#import "OLAnalytics.h"
#import "OLPrintPhoto.h"
#import "LXReorderableCollectionViewFlowLayout.h"
#import "OLScrollCropViewController.h"
#import "OLKiteViewController.h"
#import "NSObject+Utils.h"
#import "OLAsset+Private.h"
#import "OLAnalytics.h"
#import "OLKitePrintSDK.h"
#import "OLKiteABTesting.h"
#import "OLRemoteImageView.h"
#import "OLKiteUtils.h"

@interface OLPrintOrder (Private)

- (void)saveOrder;

@end

@interface OLPosterViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UICollectionViewDelegate, LXReorderableCollectionViewDataSource, OLScrollCropViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) NSMutableArray *posterPhotos;
@property (assign, nonatomic) CGFloat numberOfRows;
@property (assign, nonatomic) CGFloat numberOfColumns;
@property (weak, nonatomic) OLPrintPhoto *editingPrintPhoto;

@end

@interface OLSingleImageProductReviewViewController (Private) <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UICollectionViewDelegate>

@end

@interface OLKiteViewController ()

@property (strong, nonatomic) OLPrintOrder *printOrder;
- (void)dismiss;

@end

@implementation OLPosterViewController

-(void)viewDidLoad{
    [super viewDidLoad];
    
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackReviewScreenViewed:self.product.productTemplate.name];
#endif
    
    self.posterPhotos = [[NSMutableArray alloc] initWithCapacity:self.product.quantityToFulfillOrder];
    [self.posterPhotos addObjectsFromArray:self.userSelectedPhotos];
    
    for (NSUInteger i = 0; i < self.product.quantityToFulfillOrder; i++){
        if (self.posterPhotos.count < self.product.quantityToFulfillOrder){
            [self.posterPhotos addObject:self.userSelectedPhotos[i % self.userSelectedPhotos.count]];
        }
    }
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", @"")
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:nil
                                                                            action:nil];
    [self setTitle:NSLocalizedString(@"Edit Poster", @"")];
    
    self.numberOfColumns = self.product.productTemplate.gridCountX;
    self.numberOfRows = self.product.productTemplate.gridCountY;
    
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", @"")
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:nil
                                                                            action:nil];
}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    [self.collectionView.collectionViewLayout invalidateLayout];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinator> context){
        [self.collectionView.collectionViewLayout invalidateLayout];
        if (size.height > size.width){
            [self.collectionView reloadData];
        }
    }completion:^(id<UIViewControllerTransitionCoordinator> context){
    }];
}

- (NSInteger) numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    if (collectionView.tag != 800){
        return [super numberOfSectionsInCollectionView:collectionView];
    }
    
    return 1;
}

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    if (collectionView.tag != 800){
        return [super collectionView:collectionView numberOfItemsInSection:section];
    }
    
    return self.product.quantityToFulfillOrder;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    if (collectionView.tag != 800){
        return [super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    }
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"photoCell" forIndexPath:indexPath];
    UIActivityIndicatorView *activity = (UIActivityIndicatorView *)[cell viewWithTag:796];
    [activity startAnimating];
    
    OLRemoteImageView *imageView = (OLRemoteImageView *)[cell viewWithTag:795];
    imageView.image = nil;
    imageView.userInteractionEnabled = YES;
    [imageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onButtonEnhanceClicked:)]];
    
    OLPrintPhoto *printPhoto = self.posterPhotos[indexPath.item];
    
    [printPhoto setImageSize:[self collectionView:collectionView layout:collectionView.collectionViewLayout sizeForItemAtIndexPath:indexPath] cropped:YES progress:^(float progress){
        [imageView setProgress:progress];
    } completionHandler:^(UIImage *image){
        dispatch_async(dispatch_get_main_queue(), ^{
            imageView.image = image;
            [activity stopAnimating];
        });
    }];
    
    return cell;
}

- (CGSize) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    if (collectionView.tag != 800){
        return [super collectionView:collectionView layout:collectionViewLayout sizeForItemAtIndexPath:indexPath];
    }
    
    CGFloat margin = [self collectionView:collectionView layout:collectionView.collectionViewLayout minimumInteritemSpacingForSectionAtIndex:indexPath.section];
    CGSize size = collectionView.frame.size;
    CGFloat width = (size.width - (self.numberOfColumns - 1) * margin)/ self.numberOfColumns;
    CGFloat height = (size.height - (self.numberOfRows - 1) * margin) / self.numberOfRows;
    return CGSizeMake(width, height);
}

- (CGFloat) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section{
    if (collectionView.tag != 800){
        return [super collectionView:collectionView layout:collectionViewLayout minimumInteritemSpacingForSectionAtIndex:section];
    }
    return 2;
}

- (CGFloat) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section{
    if (collectionView.tag != 800){
        return [super collectionView:collectionView layout:collectionViewLayout minimumLineSpacingForSectionAtIndex:section];
    }
    return 2;
}

- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath didMoveToIndexPath:(NSIndexPath *)toIndexPath {
    
    id object = [self.posterPhotos objectAtIndex:fromIndexPath.item];
    [self.posterPhotos removeObjectAtIndex:fromIndexPath.item];
    [self.posterPhotos insertObject:object atIndex:toIndexPath.item];
}

- (BOOL)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath canMoveToIndexPath:(NSIndexPath *)toIndexPath{
    return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath{
    return YES;
}

-(void)changeOrderOfPhotosInArray:(NSMutableArray*)array{
    NSMutableArray* rows = [[NSMutableArray alloc] initWithCapacity:self.numberOfRows];
    for (NSUInteger rowNumber = 0; rowNumber < self.numberOfRows; rowNumber++){
        NSMutableArray* row = [[NSMutableArray alloc] initWithCapacity:self.numberOfColumns];
        for (NSUInteger photoInRow = 0; photoInRow < self.numberOfColumns; photoInRow++){
            [row addObject:array[rowNumber * (NSInteger)self.numberOfColumns + photoInRow]];
        }
        [rows addObject:row];
    }
    
    [array removeAllObjects];
    for (NSInteger rowNumber = self.numberOfRows - 1; rowNumber >= 0; rowNumber--){
        [array addObjectsFromArray:rows[rowNumber]];
    }
}

- (void)saveJobWithCompletionHandler:(void (^)())handler{
    NSUInteger iphonePhotoCount = 0;
    for (OLPrintPhoto *photo in self.posterPhotos) {
        if (photo.type == kPrintPhotoAssetTypeALAsset || photo.type == kPrintPhotoAssetTypePHAsset) ++iphonePhotoCount;
    }
    
    // Avoid uploading assets if possible. We can avoid uploading where the image already exists at a remote
    // URL and the user did not manipulate it in any way.
    NSMutableArray *photoAssets = [[NSMutableArray alloc] init];
    for (OLPrintPhoto *photo in self.posterPhotos) {
        [photoAssets addObject:[OLAsset assetWithDataSource:photo]];
    }
    [self changeOrderOfPhotosInArray:photoAssets];
    
    
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString *appVersion = [infoDict objectForKey:@"CFBundleShortVersionString"];
    NSNumber *buildNumber = [infoDict objectForKey:@"CFBundleVersion"];
    
    OLPrintOrder *printOrder = [OLKiteUtils kiteVcForViewController:self].printOrder;
    printOrder.userData = @{@"photo_count_iphone": [NSNumber numberWithUnsignedInteger:iphonePhotoCount],
                            @"sdk_version": kOLKiteSDKVersion,
                            @"platform": @"iOS",
                            @"uid": [OLAnalytics userDistinctId],
                            @"app_version": [NSString stringWithFormat:@"Version: %@ (%@)", appVersion, buildNumber]
                            };
    
    OLProductPrintJob *job = [[OLProductPrintJob alloc] initWithTemplateId:self.product.templateId OLAssets:photoAssets];
    for (id<OLPrintJob> existingJob in printOrder.jobs){
        if ([existingJob.uuid isEqualToString:self.product.uuid]){
            if ([existingJob extraCopies] > 0){
                [existingJob setExtraCopies:[existingJob extraCopies]-1];
            }
            else{
                [printOrder removePrintJob:existingJob];
            }
            job.uuid = self.product.uuid;
        }
    }
    self.editingPrintJob = job;
    
    for (NSString *option in self.product.selectedOptions.allKeys){
        [job setValue:self.product.selectedOptions[option] forOption:option];
    }
    
    if ([printOrder.jobs containsObject:self.editingPrintJob]){
        id<OLPrintJob> existingJob = printOrder.jobs[[printOrder.jobs indexOfObject:self.editingPrintJob]];
        [existingJob setExtraCopies:[existingJob extraCopies]+1];
    }
    else{
        [printOrder addPrintJob:self.editingPrintJob];
    }
    
    [printOrder saveOrder];
    
    if (handler){
        handler();
    }
}

- (void)doCheckout{
    [self saveJobWithCompletionHandler:NULL];
    
    OLPrintOrder *printOrder = [OLKiteUtils kiteVcForViewController:self].printOrder;
    if ([OLKiteABTesting sharedInstance].launchedWithPrintOrder && [[OLKiteABTesting sharedInstance].launchWithPrintOrderVariant isEqualToString:@"Review-Overview-Checkout"]){
        UIViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"OLProductOverviewViewController"];
        [vc safePerformSelector:@selector(setUserEmail:) withObject:[(OLKiteViewController *)vc userEmail]];
        [vc safePerformSelector:@selector(setUserPhone:) withObject:[(OLKiteViewController *)vc userPhone]];
        [vc safePerformSelector:@selector(setKiteDelegate:) withObject:self.delegate];
        [vc safePerformSelector:@selector(setProduct:) withObject:self.product];
        [self.navigationController pushViewController:vc animated:YES];
    }
    else{
        [OLKiteUtils checkoutViewControllerForPrintOrder:printOrder handler:^(id vc){
            [vc safePerformSelector:@selector(setUserEmail:) withObject:[OLKiteUtils userEmail:self]];
            [vc safePerformSelector:@selector(setUserPhone:) withObject:[OLKiteUtils userPhone:self]];
            [vc safePerformSelector:@selector(setKiteDelegate:) withObject:[OLKiteUtils kiteDelegate:self]];
            
            [self.navigationController pushViewController:vc animated:YES];
        }];
    }
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
    
    self.editingPrintPhoto = self.posterPhotos[indexPath.item];
    
    OLScrollCropViewController *cropVc = [self.storyboard instantiateViewControllerWithIdentifier:@"OLScrollCropViewController"];
    cropVc.enableCircleMask = self.product.productTemplate.templateUI == kOLTemplateUICircle;
    cropVc.delegate = self;
    
    CGSize cellSize = [self collectionView:self.collectionView layout:self.collectionView.collectionViewLayout sizeForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
    cropVc.aspectRatio = cellSize.height / cellSize.width;
    [self.editingPrintPhoto getImageWithProgress:NULL completion:^(UIImage *image){
        [cropVc setFullImage:image];
        cropVc.edits = self.editingPrintPhoto.edits;
        cropVc.modalPresentationStyle = [OLKiteUtils kiteVcForViewController:self].modalPresentationStyle;
        [self presentViewController:cropVc animated:YES completion:NULL];
    }];
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
