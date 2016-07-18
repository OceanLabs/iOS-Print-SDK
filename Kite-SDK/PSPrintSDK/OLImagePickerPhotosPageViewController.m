//
//  OLImagePickerPhotosPageViewController.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 15/07/16.
//  Copyright © 2016 Kite.ly. All rights reserved.
//

#import "OLImagePickerPhotosPageViewController.h"
#import "UIImageView+FadeIn.h"
#import "OLRemoteImageView.h"
#import "UIViewController+TraitCollectionCompatibility.h"

@interface OLImagePickerPhotosPageViewController () <UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UICollectionViewDelegate>
@property (weak, nonatomic) IBOutlet UILabel *albumLabel;
@property (weak, nonatomic) IBOutlet UIImageView *albumLabelChevron;
@property (weak, nonatomic) IBOutlet UIView *albumLabelContainer;
@property (assign, nonatomic) CGSize rotationSize;

@end

NSInteger OLImagePickerMargin = 0;

@implementation OLImagePickerPhotosPageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    
    self.automaticallyAdjustsScrollViewInsets = NO;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    self.rotationSize = size;
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinator> context){
        [self.collectionView reloadData];
        [self.collectionView.collectionViewLayout invalidateLayout];
    }completion:^(id<UIViewControllerTransitionCoordinator> context){
        
    }];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return [self.assets count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"photoCell" forIndexPath:indexPath];
    OLRemoteImageView *imageView = [cell viewWithTag:10];
    [self setAssetWithIndexPath:indexPath toImageView:imageView];
    
    return cell;
    
}

- (void)setAssetWithIndexPath:(NSIndexPath *)indexPath toImageView:(OLRemoteImageView *)imageView{
    id asset = self.assets[indexPath.item];
    
    if ([asset isKindOfClass:[PHAsset class]]){
        PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
        options.synchronous = NO;
        options.networkAccessAllowed = YES;
        options.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
        options.resizeMode = PHImageRequestOptionsResizeModeFast;
        
        //TODO progress
        
        CGSize cellSize = [self collectionView:self.collectionView layout:self.collectionView.collectionViewLayout sizeForItemAtIndexPath:indexPath];
        [imageView setAndFadeInImageWithPHAsset:asset size:CGSizeMake(cellSize.width * [UIScreen mainScreen].scale, cellSize.height * [UIScreen mainScreen].scale) options:options];
    }
}

- (NSUInteger)numberOfCellsPerRow{
    CGSize size = self.rotationSize.width != 0 ? self.rotationSize : self.view.frame.size;
    if (self.quantityPerItem == 3){
        return 3;
    }
    
    if (![self isHorizontalSizeClassCompact]){
        if (size.height > size.width){
            return [self findFactorOf:self.quantityPerItem maximum:6 minimum:6];
        }
        else{
            return [self findFactorOf:self.quantityPerItem maximum:6 minimum:6];
        }
    }
    else{
        if (size.height > size.width){
            return [self findFactorOf:self.quantityPerItem maximum:3 minimum:3];
        }
        else{
            return [self findFactorOf:self.quantityPerItem maximum:6 minimum:6];
        }
    }
}

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

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section{
    return OLImagePickerMargin;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section{
    return OLImagePickerMargin;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGSize size = self.view.bounds.size;
    
    if (self.rotationSize.width != 0){
        size = self.rotationSize;
    }
    
    float numberOfCellsPerRow = [self numberOfCellsPerRow];
    CGFloat width = ceilf(size.width/numberOfCellsPerRow);
    CGFloat height = width;
    
    
    return CGSizeMake(width, height);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section{
    CGSize size = self.rotationSize.width != 0 ? self.rotationSize : self.view.frame.size;
    
    CGSize cellSize = [self collectionView:collectionView layout:collectionView.collectionViewLayout sizeForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
    CGFloat diff = size.width - (cellSize.width * [self numberOfCellsPerRow]);
    return UIEdgeInsetsMake(0, diff/2.0, 0, diff/2.0);
}



@end
