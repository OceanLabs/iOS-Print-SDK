//
//  OLTShirtReviewViewController.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 17/06/16.
//  Copyright © 2016 Kite.ly. All rights reserved.
//

#import "OLTShirtReviewViewController.h"
#import "OLColorSelectionCollectionViewCell.h"
#import "UIImage+ImageNamedInKiteBundle.h"
#import "OLUserSession.h"
#import "OLAsset+Private.h"

const NSInteger kOLDrawerTagImages = 10;
const NSInteger kOLDrawerTagColors = 20;
const NSInteger kOLDrawerTagTools = 30;
const NSInteger kOLDrawerTagSizes = 40;

@interface OLSingleImageProductReviewViewController () <UICollectionViewDelegate, UICollectionViewDataSource>
- (NSInteger) sectionForImageCells;
@property (weak, nonatomic) IBOutlet UICollectionView *imagesCollectionView;
@property (weak, nonatomic) IBOutlet OLRemoteImageCropper *imageCropView;
@property (strong, nonatomic) OLAsset *imageDisplayed;
@property(nullable, nonatomic, readonly, strong) UIView *containerView;
@end

@interface OLTShirtReviewViewController () <UICollectionViewDelegateFlowLayout>
@property (weak, nonatomic) IBOutlet UIButton *sizeIconButton;
@property (weak, nonatomic) IBOutlet UIButton *toolIconButton;
@property (weak, nonatomic) IBOutlet UIButton *bucketIconButton;
@property (weak, nonatomic) IBOutlet UIButton *addPhotosIconButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *drawerBottomCom;
@property (weak, nonatomic) IBOutlet UILabel *drawerLabel;
@property (weak, nonatomic) IBOutlet UIView *drawer;
@property (strong, nonatomic) NSArray<UIColor *> *availableColors;
@property (strong, nonatomic) NSArray<NSString *> *availableSizes;
@property (assign, nonatomic) BOOL showingBack;

@end

@implementation OLTShirtReviewViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.addPhotosIconButton.tag = kOLDrawerTagImages;
    self.bucketIconButton.tag = kOLDrawerTagColors;
    self.sizeIconButton.tag = kOLDrawerTagSizes;
    self.toolIconButton.tag = kOLDrawerTagTools;
    
    self.availableColors = @[[UIColor blackColor], [UIColor whiteColor], [UIColor grayColor], [UIColor greenColor], [UIColor redColor]];
    self.availableSizes = @[@"XS", @"S", @"M", @"L", @"XL", @"XXL"];
}

- (void)selectButton:(UIButton *)sender{
    switch (sender.tag) {
        case kOLDrawerTagImages:
            self.drawerLabel.text = NSLocalizedString(@"PHOTOS", @"");
            break;
        case kOLDrawerTagTools:
            self.drawerLabel.text = NSLocalizedString(@"TOOLS", @"");
            break;
        case kOLDrawerTagSizes:
            self.drawerLabel.text = NSLocalizedString(@"SIZES", @"");
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
        if ([OLUserSession currentSession].userSelectedPhotos.count == 0 && sender.tag == kOLDrawerTagImages){
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
    else if (collectionView.tag == kOLDrawerTagSizes && section == 1){
        return self.availableSizes.count;
    }
    else if (collectionView.tag == kOLDrawerTagSizes && section == 0){
        return 1;
    }
    else if (collectionView.tag == kOLDrawerTagTools){
        return 2;
    }
    return 0;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    if (collectionView.tag == kOLDrawerTagImages){
        return [super numberOfSectionsInCollectionView:collectionView];
    }
    else if (collectionView.tag == kOLDrawerTagSizes){
        return 2;
    }
    return 1;
}

- (UIEdgeInsets) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section{
    if (section == 0){
        return UIEdgeInsetsMake(0, 10, 0, 30);
    }
    else{
        return UIEdgeInsetsMake(0, 0, 0, 30);
    }
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    if (collectionView.tag == kOLDrawerTagSizes && indexPath.section == 0){
        return NO;
    }
    return YES;
}

- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    if (collectionView.tag == kOLDrawerTagImages){
        [super collectionView:collectionView didSelectItemAtIndexPath:indexPath];
    }
    else if (collectionView.tag == kOLDrawerTagColors){
        self.product.selectedOptions[@"colour"] = self.availableColors[indexPath.item];
        [collectionView reloadData];
    }
    else if (collectionView.tag == kOLDrawerTagSizes){
        self.product.selectedOptions[@"size"] = self.availableSizes[indexPath.item];
        [collectionView reloadData];
    }
    else if (collectionView.tag == kOLDrawerTagTools){
        if (indexPath.item == 0){
            [self onButtonRotateClicked:nil];
        }
        else if (indexPath.item == 1){
            [self onButtonHorizontalFlipClicked:nil];
        }
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewCell *cell;
    if (collectionView.tag == kOLDrawerTagImages){
        cell = [super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    }
    if (collectionView.tag == kOLDrawerTagColors){
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"colorSelectionCell" forIndexPath:indexPath];
        
        [cell setSelected:[self.product.selectedOptions[@"colour"] isEqual:self.availableColors[indexPath.item]]];
        
        [(OLColorSelectionCollectionViewCell *)cell setColor:self.availableColors[indexPath.item]];
        [cell setNeedsDisplay];
    }
    if (collectionView.tag == kOLDrawerTagSizes){
        if (indexPath.section == 0){
            cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"iconCell" forIndexPath:indexPath];
            [(UIImageView *)[cell viewWithTag:10] setImage:[UIImage imageNamedInKiteBundle:@"shirt-size-icon"]];
        }
        else{
            cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"circleSelectedCell" forIndexPath:indexPath];
            
            [cell setSelected:[self.product.selectedOptions[@"size"] isEqual:self.availableSizes[indexPath.item]]];
            
            [(UILabel *)[cell viewWithTag:10] setText:self.availableSizes[indexPath.item]];
            [cell setNeedsDisplay];
        }
    }
    if  (collectionView.tag == kOLDrawerTagTools){
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"toolCell" forIndexPath:indexPath];
        if (indexPath.item == 0){
            [(UIImageView *)[cell viewWithTag:10] setImage:[UIImage imageNamedInKiteBundle:@"rotate"]];
            [(UILabel *)[cell viewWithTag:20] setText:NSLocalizedString(@"Rotate", @"")];
        }
        else if (indexPath.item == 1){
            [(UIImageView *)[cell viewWithTag:10] setImage:[UIImage imageNamedInKiteBundle:@"flip"]];
            [(UILabel *)[cell viewWithTag:20] setText:NSLocalizedString(@"Flip", @"")];
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

- (IBAction)onButtonHorizontalFlipClicked:(id)sender {
    if (self.imageCropView.isCorrecting){
        return;
    }
    
    [self.imageDisplayed.edits performHorizontalFlipEditFromOrientation:self.imageCropView.imageView.image.imageOrientation];
    
    [UIView transitionWithView:self.imageCropView.imageView duration:0.5 options:UIViewAnimationOptionTransitionFlipFromRight animations:^{
        
        [self.imageCropView setImage:[UIImage imageWithCGImage:self.imageCropView.image.CGImage scale:self.imageCropView.imageView.image.scale orientation:[OLPhotoEdits orientationForNumberOfCounterClockwiseRotations:self.imageDisplayed.edits.counterClockwiseRotations andInitialOrientation:UIImageOrientationUp horizontalFlip:self.imageDisplayed.edits.flipHorizontal verticalFlip:self.imageDisplayed.edits.flipVertical]]];
        
    }completion:NULL];
}

- (IBAction)onButtonRotateClicked:(id)sender {
    if (self.imageCropView.isCorrecting){
        return;
    }
    
    [(UIBarButtonItem *)sender setEnabled:NO];
    self.imageDisplayed.edits.counterClockwiseRotations = (self.imageDisplayed.edits.counterClockwiseRotations + 1) % 4;
    CGAffineTransform transform = self.imageCropView.imageView.transform;
    transform.tx = self.imageCropView.imageView.transform.ty;
    transform.ty = -self.imageCropView.imageView.transform.tx;
    
    CGRect cropboxRect = self.imageCropView.frame;
    
    UIImage *newImage = [UIImage imageWithCGImage:self.self.imageCropView.image.CGImage scale:self.imageCropView.imageView.image.scale orientation:[OLPhotoEdits orientationForNumberOfCounterClockwiseRotations:self.imageDisplayed.edits.counterClockwiseRotations andInitialOrientation:UIImageOrientationUp horizontalFlip:self.imageDisplayed.edits.flipHorizontal verticalFlip:self.imageDisplayed.edits.flipVertical]];
    CGFloat imageAspectRatio = newImage.size.height/newImage.size.width;
    
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        self.imageCropView.transform = CGAffineTransformMakeRotation(-M_PI_2);
        
        CGFloat boxWidth = self.imageCropView.frame.size.width;
        CGFloat boxHeight = self.imageCropView.frame.size.height;
        
        CGFloat imageWidth;
        CGFloat imageHeight;
        
        if (imageAspectRatio > 1.0){
            imageHeight = boxHeight;
            imageWidth = boxHeight * imageAspectRatio;
        }
        else{
            imageWidth = boxWidth;
            imageHeight = boxWidth / imageAspectRatio;
        }
        
        self.imageCropView.imageView.frame = CGRectMake((boxHeight - imageWidth)/ 2.0, (boxWidth - imageHeight) / 2.0, imageWidth, imageHeight);
        
    } completion:^(BOOL finished){
        self.imageCropView.transform = CGAffineTransformIdentity;
        self.imageCropView.frame = cropboxRect;
        [self.imageCropView setImage:newImage];
        
        [(UIBarButtonItem *)sender setEnabled:YES];
    }];
}

- (IBAction)onButtonProductFlip:(UIButton *)sender {
    [UIView transitionWithView:self.containerView duration:0.5 options:UIViewAnimationOptionTransitionFlipFromRight animations:^{
        if (self.showingBack){
            self.showingBack = NO;
            //Change view here
        }
        else{
            self.showingBack = YES;
            //Change view here
        }
    }completion:NULL];
}

@end
