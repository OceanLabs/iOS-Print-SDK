//
//  OLTShirtReviewViewController.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 17/06/16.
//  Copyright © 2016 Kite.ly. All rights reserved.
//

#import "OLTShirtReviewViewController.h"
#import "OLColorSelectionCollectionViewCell.h"

const NSInteger kOLDrawerTagImages = 10;
const NSInteger kOLDrawerTagColors = 20;
const NSInteger kOLDrawerTagTools = 30;
const NSInteger kOLDrawerTagSizes = 40;

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
@property (strong, nonatomic) UIColor *selectedColor;
@property (strong, nonatomic) NSArray<UIColor *> *availableColors;

@end

@implementation OLTShirtReviewViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.addPhotosIconButton.tag = kOLDrawerTagImages;
    self.bucketIconButton.tag = kOLDrawerTagColors;
    self.sizeIconButton.tag = kOLDrawerTagSizes;
    self.toolIconButton.tag = kOLDrawerTagTools;
    
    self.availableColors = @[[UIColor blackColor], [UIColor whiteColor], [UIColor grayColor], [UIColor greenColor], [UIColor redColor]];
}

- (void)selectButton:(UIButton *)sender{
    switch (sender.tag) {
        case kOLDrawerTagImages:
            self.drawerLabel.text = NSLocalizedString(@"PHOTOS", @"");
            break;
        case kOLDrawerTagTools:
            self.drawerLabel.text = NSLocalizedString(@"TOOL", @"");
            break;
        case kOLDrawerTagSizes:
            self.drawerLabel.text = NSLocalizedString(@"SIZE", @"");
            break;
        case kOLDrawerTagColors:
            self.drawerLabel.text = NSLocalizedString(@"COLOURS", @"");
            break;
            
        default:
            break;
    }
    
    sender.selected = YES;
    self.imagesCollectionView.tag = sender.tag;
    [self.imagesCollectionView reloadData];
    
    [UIView animateWithDuration:0.25 animations:^{
        self.drawer.transform = CGAffineTransformMakeTranslation(0, -self.ctaButton.frame.size.height - self.drawer.frame.size.height);
    }];
}

- (void)deselectButton:(UIButton *)sender withCompletionHandler:(void (^)())handler{
    sender.selected = NO;
    [UIView animateWithDuration:0.25 animations:^{
        self.drawer.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished){
        if (handler){
            handler();
        }
    }];
}

- (void)deselectSelectedButtonWithCompletionHandler:(void (^)())handler{
    for (UIButton *button in @[self.addPhotosIconButton, self.toolIconButton, self.sizeIconButton, self.bucketIconButton]){
        if (button.selected){
            [self deselectButton:button withCompletionHandler:handler];
            break; //We should never have more than one selected button
        }
    }
}

- (IBAction)onIconButtonClicked:(UIButton *)sender {
    void (^buttonAction)() = ^void(){
        if (self.userSelectedPhotos.count == 0 && sender.tag == kOLDrawerTagImages){
            //TODO check if we can add photos
            [self collectionView:self.imagesCollectionView didSelectItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
        }
        [self selectButton:sender];
    };
    
    // Nothing is selected: just action
    if (!self.addPhotosIconButton.selected && !self.toolIconButton.selected && !self.bucketIconButton.selected && !self.sizeIconButton.selected){
        buttonAction();
    }
    // Sender is selected: just deselect
    else if (sender.selected){
        [self deselectSelectedButtonWithCompletionHandler:NULL];
    }
    // Other is selected: Deselect and action
    else{
        [self deselectSelectedButtonWithCompletionHandler:^{
            buttonAction();
        }];
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    if (collectionView.tag == kOLDrawerTagImages){
        return [super collectionView:collectionView numberOfItemsInSection:section];
    }
    else if (collectionView.tag == kOLDrawerTagColors){
        return self.availableColors.count;
    }
    return 0;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    if (collectionView.tag == kOLDrawerTagImages){
        return [super numberOfSectionsInCollectionView:collectionView];
    }
    return 1;
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
    if (collectionView.tag == kOLDrawerTagImages){
        [super collectionView:collectionView didSelectItemAtIndexPath:indexPath];
    }
    else if (collectionView.tag == kOLDrawerTagColors){
        self.selectedColor = [(OLColorSelectionCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath] color];
        [collectionView reloadData];
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewCell *cell;
    if (collectionView.tag == kOLDrawerTagImages){
        cell = [super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    }
    if (collectionView.tag == kOLDrawerTagColors){
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"colorSelectionCell" forIndexPath:indexPath];
        
        [cell setSelected:[self.selectedColor isEqual:self.availableColors[indexPath.item]]];
        
        [(OLColorSelectionCollectionViewCell *)cell setColor:self.availableColors[indexPath.item]];
        [cell setNeedsDisplay];
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
