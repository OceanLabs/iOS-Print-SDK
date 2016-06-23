//
//  OLTShirtReviewViewController.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 17/06/16.
//  Copyright © 2016 Kite.ly. All rights reserved.
//

#import "OLTShirtReviewViewController.h"

const NSInteger kCollectionViewTagImages = 10;
const NSInteger kCollectionViewTagColors = 20;
const NSInteger kCollectionViewTagTools = 30;
const NSInteger kCollectionViewTagSizes = 40;

@interface OLSingleImageProductReviewViewController () <UICollectionViewDelegate, UICollectionViewDataSource>
- (NSInteger) sectionForImageCells;
@property (weak, nonatomic) IBOutlet UICollectionView *imagesCollectionView;
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView imageCellForIndexPath:(NSIndexPath *)indexPath;
@end

@interface OLTShirtReviewViewController ()
@property (weak, nonatomic) IBOutlet UIButton *sizeIconButton;
@property (weak, nonatomic) IBOutlet UIButton *toolIconButton;
@property (weak, nonatomic) IBOutlet UIButton *bucketIconButton;
@property (weak, nonatomic) IBOutlet UIButton *addPhotosIconButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *drawerBottomCom;
@property (weak, nonatomic) IBOutlet UILabel *drawerLabel;
@property (weak, nonatomic) IBOutlet UIView *drawer;

@end

@implementation OLTShirtReviewViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (IBAction)onButtonAddPhotosIconClicked:(UIButton *)sender {
    self.imagesCollectionView.tag = kCollectionViewTagImages;
    [self.imagesCollectionView reloadData];
    if (self.userSelectedPhotos.count == 0){
        //TODO check if we can add photos
        [self collectionView:self.imagesCollectionView didSelectItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
    }
    else if (self.drawerBottomCom.constant == 0){
        self.drawerLabel.text = NSLocalizedString(@"PHOTOS", @"");
        self.drawerBottomCom.constant = -self.ctaButton.frame.size.height - self.drawer.frame.size.height;
        [UIView animateWithDuration:0.25 animations:^{
            [self.view layoutIfNeeded];
        }];
    }
    else{
        self.drawerBottomCom.constant = 0;
        [UIView animateWithDuration:0.25 animations:^{
            [self.view layoutIfNeeded];
        }];
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    if (collectionView.tag == kCollectionViewTagImages){
        return self.userSelectedPhotos.count + [self sectionForImageCells];
    }
    return 0;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return collectionView.tag == 0 ? 0 : 1;
}

- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    if (collectionView.tag == kCollectionViewTagImages){
        if (indexPath.section == [self sectionForImageCells]){
            indexPath = [NSIndexPath indexPathForItem:indexPath.item inSection:0];
        }
        [super collectionView:collectionView didSelectItemAtIndexPath:indexPath];
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewCell *cell;
    if (collectionView.tag == kCollectionViewTagImages){
        if (indexPath.item == 0){
            cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"moreCell" forIndexPath:indexPath];
        }
        else{
            cell = [self collectionView:collectionView imageCellForIndexPath:[NSIndexPath indexPathForItem:indexPath.item-[self sectionForImageCells] inSection:0]];
        }
    }
    
    return cell;
}

- (CGFloat) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section{
    return 30;
}

- (CGFloat) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section{
    return 30;
}

- (IBAction)onButtonBucketIconClicked:(UIButton *)sender {
    self.imagesCollectionView.tag = kCollectionViewTagColors;
    [self.imagesCollectionView reloadData];
}

- (IBAction)onButtonToolsIconClicked:(UIButton *)sender {
    self.imagesCollectionView.tag = kCollectionViewTagTools;
    [self.imagesCollectionView reloadData];
}

- (IBAction)onButtonSizeClicked:(UIButton *)sender {
    self.imagesCollectionView.tag = kCollectionViewTagSizes;
    [self.imagesCollectionView reloadData];
}

@end
