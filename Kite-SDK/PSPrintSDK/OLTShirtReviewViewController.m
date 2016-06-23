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
@end

@interface OLTShirtReviewViewController () <UICollectionViewDelegateFlowLayout>
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
    if (self.userSelectedPhotos.count == 0){
        //TODO check if we can add photos
        [self collectionView:self.imagesCollectionView didSelectItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
    }
    else if (self.drawerBottomCom.constant == 0){
        self.imagesCollectionView.tag = kCollectionViewTagImages;
        [self.imagesCollectionView reloadData];
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

- (IBAction)onButtonBucketIconClicked:(UIButton *)sender {
    if (self.drawerBottomCom.constant == 0){
        self.imagesCollectionView.tag = kCollectionViewTagColors;
        [self.imagesCollectionView reloadData];
        self.drawerLabel.text = NSLocalizedString(@"COLOURS", @"");
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

- (IBAction)onButtonToolsIconClicked:(UIButton *)sender {
    if (self.drawerBottomCom.constant == 0){
        self.imagesCollectionView.tag = kCollectionViewTagTools;
        [self.imagesCollectionView reloadData];
        self.drawerLabel.text = NSLocalizedString(@"TOOLS", @"");
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

- (IBAction)onButtonSizeClicked:(UIButton *)sender {
    if (self.drawerBottomCom.constant == 0){
        self.imagesCollectionView.tag = kCollectionViewTagSizes;
        [self.imagesCollectionView reloadData];
        self.drawerLabel.text = NSLocalizedString(@"SIZE", @"");
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
        return [super collectionView:collectionView numberOfItemsInSection:section];
    }
    return 0;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    if (collectionView.tag == kCollectionViewTagImages){
        return [super numberOfSectionsInCollectionView:collectionView];
    }
    return 0;
}

- (UIEdgeInsets) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section{
    if (section == 0){
        return UIEdgeInsetsMake(0, 30, 0, 30);
    }
    else{
        return UIEdgeInsetsMake(0, 0, 0, 30);
    }
}

- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    if (collectionView.tag == kCollectionViewTagImages){
        [super collectionView:collectionView didSelectItemAtIndexPath:indexPath];
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewCell *cell;
    if (collectionView.tag == kCollectionViewTagImages){
        cell = [super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    }
    
    return cell;
}

- (CGFloat) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section{
    return 30;
}

- (CGFloat) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section{
    return 30;
}

@end
