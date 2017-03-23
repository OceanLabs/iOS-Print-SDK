//
//  Modified MIT License
//
//  Copyright (c) 2010-2017 Kite Tech Ltd. https://www.kite.ly
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The software MAY ONLY be used with the Kite Tech Ltd platform and MAY NOT be modified
//  to be used with any competitor platforms. This means the software MAY NOT be modified
//  to place orders with any competitors to Kite Tech Ltd, all orders MUST go through the
//  Kite Tech Ltd platform servers.
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "OLFrameOrderReviewViewController.h"
#import "OLAsset.h"
#import "OLProduct.h"
#import "OLAsset+Private.h"
#import "OLRemoteImageView.h"
#import "OLKiteUtils.h"
#import "OLKiteViewController.h"
#import "OLImagePreviewViewController.h"
#import "OLAnalytics.h"
#import "OLKitePrintSDK.h"
#import "OLUserSession.h"
#import "UIImageView+FadeIn.h"
#import "OLImagePickerViewController.h"
#import "OLInfoBanner.h"
#import "OLCustomViewControllerPhotoProvider.h"
#import "NSObject+Utils.h"
#import "OLCustomPickerController.h"
#import "OLKiteViewController+Private.h"

@interface OLPackProductViewController (Private) <OLInfoBannerDelegate, OLImagePickerViewControllerDelegate>

- (void)updateTitleBasedOnSelectedPhotoQuanitity;
- (BOOL) shouldGoToCheckout;
- (void) doCheckout;
- (void)preparePhotosForCheckout;
-(NSUInteger) totalNumberOfExtras;
- (void)replacePhoto:(id)sender;
@property (strong, nonatomic) UIButton *nextButton;
@property (strong, nonatomic) OLInfoBanner *infoBanner;

@end

@interface OLFrameOrderReviewViewController () <OLImageEditViewControllerDelegate,UIViewControllerPreviewingDelegate>

@property (strong, nonatomic) NSMutableArray* framePhotos;
@property (weak, nonatomic) OLAsset *editingAsset;
@property (strong, nonatomic) OLImagePickerViewController *vcDelegateForCustomVc;
@property (strong, nonatomic) UIViewController *presentedVc;

@end

@implementation OLFrameOrderReviewViewController

CGFloat margin = 25;
CGFloat innerMargin = 3;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.product.productTemplate.templateUI == OLTemplateUIFrame){
        margin = 2;
        innerMargin = 2;
    }
    
    // add placeholder photos
    self.framePhotos = [[NSMutableArray alloc] init];
    [self.framePhotos addObjectsFromArray:[OLUserSession currentSession].userSelectedPhotos];
    NSUInteger userSelectedAssetCount = [self.framePhotos count];
    NSUInteger numOrders = (NSUInteger) floor(userSelectedAssetCount + self.product.quantityToFulfillOrder - 1) / self.product.quantityToFulfillOrder;
    NSUInteger duplicatesToFillOrder = numOrders * self.product.quantityToFulfillOrder - userSelectedAssetCount;
    for (NSUInteger i = 0; i < duplicatesToFillOrder; ++i) {
        [self.framePhotos addObject:[OLPlaceholderAsset asset]];
    }
#ifdef OL_VERBOSE
    NSLog(@"Adding %lu duplicates to frame", (unsigned long)duplicatesToFillOrder);
#endif
    
    self.title = NSLocalizedStringFromTableInBundle(@"Review", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Title of a screen where the user can review the product before ordering");
}

- (void)replacePhoto:(id)sender{
    OLImagePickerViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"OLImagePickerViewController"];
    vc.delegate = self;
    vc.selectedAssets = [[NSMutableArray alloc] init];
    vc.maximumPhotos = 1;
    vc.product = self.product;
    
    if ([OLKiteUtils numberOfProvidersAvailable] <= 2 && [[OLUserSession currentSession].kiteVc.customImageProviders.firstObject isKindOfClass:[OLCustomViewControllerPhotoProvider class]]){
        //Skip the image picker and only show the custom vc
        
        self.vcDelegateForCustomVc = vc; //Keep strong reference
        vc.providerForPresentedVc = [OLUserSession currentSession].kiteVc.customImageProviders.firstObject;
        UIViewController<OLCustomPickerController> *customVc = [(OLCustomViewControllerPhotoProvider *)[OLUserSession currentSession].kiteVc.customImageProviders.firstObject vc];
        [customVc safePerformSelector:@selector(setDelegate:) withObject:vc];
        [customVc safePerformSelector:@selector(setProductId:) withObject:self.product.templateId];
        [customVc safePerformSelector:@selector(setSelectedAssets:) withObject:[[NSMutableArray alloc] init]];
        if ([vc respondsToSelector:@selector(setMaximumPhotos:)]){
            vc.maximumPhotos = 1;
        }
        
        [self presentViewController:customVc animated:YES completion:NULL];
        self.presentedVc = customVc;
        return;
    }
    
    [self presentViewController:[[OLNavigationController alloc] initWithRootViewController:vc] animated:YES completion:NULL];
}

- (void)onTapGestureThumbnailTapped:(UITapGestureRecognizer*)gestureRecognizer {
    NSIndexPath *outerCollectionViewIndexPath = [self.collectionView indexPathForItemAtPoint:[gestureRecognizer locationInView:self.collectionView]];
    UICollectionViewCell *outerCollectionViewCell = [self.collectionView cellForItemAtIndexPath:outerCollectionViewIndexPath];
    
    UICollectionView* collectionView = (UICollectionView*)[outerCollectionViewCell.contentView viewWithTag:20];
    
    NSIndexPath* indexPath = [collectionView indexPathForItemAtPoint:[gestureRecognizer locationInView:collectionView]];
    
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    OLRemoteImageView *imageView = (OLRemoteImageView *)[cell viewWithTag:110];
    
    if (!imageView.image){
        return;
    }
    
    self.editingAsset = self.framePhotos[(outerCollectionViewIndexPath.item) * [self collectionView:collectionView numberOfItemsInSection:indexPath.section] + indexPath.row];
    
    if ([OLUserSession currentSession].kiteVc.disableEditingTools || [self.editingAsset isKindOfClass:[OLPlaceholderAsset class]]){
        [self replacePhoto:nil];
        return;
    }
    
    [self.editingAsset imageWithSize:[UIScreen mainScreen].bounds.size applyEdits:NO progress:NULL completion:^(UIImage *image, NSError *error){
        
        OLImageEditViewController *cropVc = [[OLImageEditViewController alloc] init];
        cropVc.borderInsets = self.product.productTemplate.imageBorder;
        cropVc.enableCircleMask = self.product.productTemplate.templateUI == OLTemplateUICircle;
        cropVc.delegate = self;
        cropVc.aspectRatio = 1.0;
        cropVc.product = self.product;
        
        cropVc.previewView = [imageView snapshotViewAfterScreenUpdates:YES];
        cropVc.previewView.frame = [imageView.superview convertRect:imageView.frame toView:nil];
        cropVc.previewSourceView = imageView;
        cropVc.providesPresentationContextTransitionStyle = true;
        cropVc.definesPresentationContext = true;
        cropVc.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        [cropVc setFullImage:image];
        cropVc.edits = self.editingAsset.edits;
        [self presentViewController:cropVc animated:NO completion:NULL];
        
        [UIView animateWithDuration:0.25 delay:0.25 options:0 animations:^{
            self.nextButton.alpha = 0;
            self.infoBanner.transform = CGAffineTransformMakeTranslation(0, -self.infoBanner.frame.origin.y);
            self.collectionView.contentInset = UIEdgeInsetsMake(self.collectionView.contentInset.top - self.infoBanner.frame.size.height, self.collectionView.contentInset.left, self.collectionView.contentInset.bottom, self.collectionView.contentInset.right);
        } completion:^(BOOL finished){
            [self.infoBanner removeFromSuperview];
            self.infoBanner = nil;
        }];
        
#ifndef OL_NO_ANALYTICS
        [OLAnalytics trackEditPhotoTappedForProductName:self.product.productTemplate.name];
#endif
    }];
}

+(void)reverseRowsOfPhotosInArray:(NSMutableArray*)array forProduct:(OLProduct *)product{
    NSUInteger photosPerRow = sqrt(product.quantityToFulfillOrder);
    NSUInteger numberOfRows = [array count] / photosPerRow;
    
    NSMutableArray* rows = [[NSMutableArray alloc] initWithCapacity:numberOfRows];
    for (NSUInteger rowNumber = 0; rowNumber < numberOfRows; rowNumber++){
        NSMutableArray* row = [[NSMutableArray alloc] initWithCapacity:photosPerRow];
        for (NSUInteger photoInRow = 0; photoInRow < photosPerRow; photoInRow++){
            [row addObject:array[rowNumber * photosPerRow + photoInRow]];
        }
        [rows addObject:row];
    }
    
    [array removeAllObjects];
    for (NSInteger rowNumber = numberOfRows - 1; rowNumber >= 0; rowNumber--){
        [array addObjectsFromArray:rows[rowNumber]];
    }
}

- (void)preparePhotosForCheckout{
    if (self.product.productTemplate.templateUI != OLTemplateUIFrame){
        self.checkoutPhotos = self.framePhotos;
        return;
    }
    NSMutableArray *reversePhotos = [self.framePhotos mutableCopy];
    [OLFrameOrderReviewViewController reverseRowsOfPhotosInArray:reversePhotos forProduct:self.product];
    self.checkoutPhotos = reversePhotos;
}

-(NSUInteger) totalNumberOfExtras{
    return 0;
}

-(BOOL) shouldGoToCheckout{
    NSInteger nullCount = 0;
    for (OLAsset *asset in self.framePhotos){
        if ([asset isKindOfClass:[OLPlaceholderAsset class]]){
            nullCount++;
        }
    }
    
    if (nullCount > 0){
        NSInteger selected = self.framePhotos.count - nullCount;
        NSString *title = selected == 1 ? [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"You've only selected %d photo.", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @""), selected] : [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"You've only selected %d photos.", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @""), selected];
        UIAlertController *ac = [UIAlertController alertControllerWithTitle:title message:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Please add %d more.", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Please add [a number] more [photos]"), nullCount] preferredStyle:UIAlertControllerStyleAlert];
        [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"OK", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Acknowledgent to an alert dialog.") style:UIAlertActionStyleCancel handler:NULL]];
        [self presentViewController:ac animated:YES completion:NULL];
        return NO;

    }
    
    return [super shouldGoToCheckout];
}

- (UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location{
    return nil;
}

#pragma mark Button Actions

- (IBAction)onButtonNextClicked:(UIBarButtonItem *)sender {
    if (![self shouldGoToCheckout]){
        return;
    }
    
    [self doCheckout];
}


#pragma mark UICollectionView data source and delegate methods

- (NSInteger)numberOfFrames{
    if (self.product.productTemplate.templateUI == OLTemplateUIFrame){
        NSInteger numberOfPhotosPerFrame =  self.product.quantityToFulfillOrder;
        int incompleteFrame = ([self.framePhotos count] % numberOfPhotosPerFrame) != 0 ? 1 : 0;
        return [self.framePhotos count]/self.product.quantityToFulfillOrder + incompleteFrame;
    }
    else{
        NSInteger numberOfPhotosPerFrame = self.product.productTemplate.gridCountX * self.product.productTemplate.gridCountY;
        return self.product.quantityToFulfillOrder / numberOfPhotosPerFrame;
        
    }
}

- (NSInteger)numberOfPhotosPerFrame{
    if (self.product.productTemplate.templateUI == OLTemplateUIFrame){
        return self.product.quantityToFulfillOrder;
    }
    else{
        return self.product.productTemplate.gridCountX * self.product.productTemplate.gridCountY;
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    if (collectionView.tag == 10){
        return [self numberOfFrames];
    }
    else{
        return [self numberOfPhotosPerFrame];
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    if (collectionView.tag == 10){
        NSString *cellId = self.product.productTemplate.templateUI == OLTemplateUIFrame ? @"reviewCell" : @"calendarCell";
        UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellId forIndexPath:indexPath];
        
        UIView *view = cell.contentView;
        view.translatesAutoresizingMaskIntoConstraints = NO;
        NSDictionary *views = NSDictionaryOfVariableBindings(view);
        NSMutableArray *con = [[NSMutableArray alloc] init];
        
        NSArray *visuals = @[@"H:|-0-[view]-0-|",
                             @"V:|-0-[view]-0-|"];
        
        
        for (NSString *visual in visuals) {
            [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
        }
        
        [view.superview addConstraints:con];
        
        UICollectionView* innerCollectionView = (UICollectionView*)[cell.contentView viewWithTag:20];
        
        innerCollectionView.dataSource = self;
        innerCollectionView.delegate = self;
        
        CGFloat innerCollectionViewHorizontalMargin = 20;
        CGFloat innerCollectionViewTopMargin = 20;
        if (self.product.productTemplate.templateUI == OLTemplateUIFrame){
            innerCollectionViewHorizontalMargin = 25;
            innerCollectionViewTopMargin = 53;
        }
        
        view = innerCollectionView;
        
        CGSize size = [self collectionView:collectionView layout:collectionView.collectionViewLayout sizeForItemAtIndexPath:indexPath];
        float scaleFactor = size.width / 320.0;
        
        view.translatesAutoresizingMaskIntoConstraints = NO;
        views = NSDictionaryOfVariableBindings(view);
        con = [[NSMutableArray alloc] init];
        
        visuals = @[[NSString stringWithFormat:@"H:|-%f-[view]-%f-|", innerCollectionViewHorizontalMargin * scaleFactor, innerCollectionViewHorizontalMargin * scaleFactor],
                    [NSString stringWithFormat:@"V:|-%f-[view]", innerCollectionViewTopMargin * scaleFactor]];
        
        
        for (NSString *visual in visuals) {
            [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
        }
        
        [view.superview addConstraints:con];
        
        if (self.product.productTemplate.templateUI != OLTemplateUIFrame){
            cell.contentView.backgroundColor = [UIColor whiteColor];
            
            CGSize imageSize = [self collectionView:innerCollectionView layout:innerCollectionView.collectionViewLayout sizeForItemAtIndexPath:indexPath];
            UIImageView *imageView = [cell.contentView viewWithTag:1010];
            if (indexPath.item < self.product.productTemplate.representationAssets.count){
                [imageView setAndFadeInImageWithURL:self.product.productTemplate.representationAssets[indexPath.item] size:CGSizeMake(imageSize.width, imageSize.height)];
            }
            if (self.product.productTemplate.logo){
                __weak UIImageView *imageView = [cell.contentView viewWithTag:1011];
                [imageView setAndFadeInImageWithURL:self.product.productTemplate.logo size:CGSizeMake(122 * scaleFactor, 56 * scaleFactor)];
                [imageView addConstraint:[NSLayoutConstraint constraintWithItem:imageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:37.5 * scaleFactor]];
                [imageView addConstraint:[NSLayoutConstraint constraintWithItem:imageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:75 * scaleFactor]];
            }
            
            for (NSLayoutConstraint *con in imageView.constraints){
                if ([con.identifier isEqualToString:@"calendarHeightCon"]){
                    con.constant = 125 * scaleFactor;
                }
                if ([con.identifier isEqualToString:@"imageTopCon"]){
                    con.constant = 10 * scaleFactor;
                }
            }
        }
        
        return cell;
    }
    else{
        UICollectionViewCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"imageCell" forIndexPath:indexPath];
        
        UIView* view = collectionView.superview;
        while (![view isKindOfClass:[UICollectionViewCell class]]){
            view = view.superview;
        }
        
        NSIndexPath* outerCollectionViewIndexPath = [self.collectionView indexPathForCell:(UICollectionViewCell *)view];
        
        __weak OLRemoteImageView* cellImage = (OLRemoteImageView*)[cell.contentView viewWithTag:110];
        cellImage.userInteractionEnabled = YES;
        cellImage.image = nil;
        
        NSInteger numberOfPhotosPerFrame = self.product.productTemplate.templateUI == OLTemplateUIFrame ? self.product.quantityToFulfillOrder : (self.product.productTemplate.gridCountX * self.product.productTemplate.gridCountY != 0 ? self.product.productTemplate.gridCountX * self.product.productTemplate.gridCountY : 4);
        
        OLAsset *asset =(OLAsset*)[self.framePhotos objectAtIndex:indexPath.row + (outerCollectionViewIndexPath.item) * numberOfPhotosPerFrame];
        [cellImage setAndFadeInImageWithOLAsset:asset size:[self collectionView:collectionView layout:collectionView.collectionViewLayout sizeForItemAtIndexPath:indexPath] applyEdits:YES placeholder:nil progress:^(float progress){
                        [cellImage setProgress:progress];
        } completionHandler:NULL];
        
        UITapGestureRecognizer* doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapGestureThumbnailTapped:)];
        [cellImage addGestureRecognizer:doubleTap];
        
        return cell;
    }
}

- (void)addInfoBanner{
    if ([OLUserSession currentSession].kiteVc.disableEditingTools){
        self.infoBanner = [OLInfoBanner showInfoBannerOnViewController:self withTitle:NSLocalizedStringFromTableInBundle(@"Tap Image to Change", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"")];
    }
    else{
        self.infoBanner = [OLInfoBanner showInfoBannerOnViewController:self withTitle:NSLocalizedStringFromTableInBundle(@"Tap Image to Edit or Hold to Rearrange", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"")];
    }
    self.infoBanner.delegate = self;
    self.collectionView.contentInset = UIEdgeInsetsMake(self.collectionView.contentInset.top + 50, self.collectionView.contentInset.left, self.collectionView.contentInset.bottom, self.collectionView.contentInset.right);
}

- (CGSize) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    if (collectionView.tag == 10){
        CGSize size = self.view.frame.size;
        CGFloat height = self.product.productTemplate.templateUI == OLTemplateUIFrame ? 351 : 435;
        if (MIN(size.height, size.width) == 320){
            float scaleFactorH = (MIN(self.view.frame.size.width, self.view.frame.size.height)-20) / 320.0;
            return CGSizeMake(320 * scaleFactorH, height * scaleFactorH);
        }
        return CGSizeMake(320, height);
    }
    else{
        CGFloat photosPerRow = self.product.productTemplate.templateUI == OLTemplateUIFrame ? sqrt(self.product.quantityToFulfillOrder) : self.product.productTemplate.gridCountX;

        return CGSizeMake(
                          (collectionView.frame.size.width - innerMargin * (photosPerRow-1.0)) / photosPerRow,
                          (collectionView.frame.size.width - innerMargin * (photosPerRow-1.0)) / photosPerRow
                          );
    }
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section{
    if (collectionView.tag == 20){
        return innerMargin;
    }
    else{
        return margin;
    }
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section{
    if (collectionView.tag == 20){
        return innerMargin;
    }
    else{
        return margin;
    }
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section{
    if (collectionView.tag == 20){
        return UIEdgeInsetsZero;
    }
    else{
        CGSize cellSize = [self collectionView:collectionView layout:collectionView.collectionViewLayout sizeForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:section]];
        
        NSInteger numberOfCellsPerRow = collectionView.frame.size.width / cellSize.width;
        CGFloat sideMargin = (collectionView.frame.size.width - (cellSize.width * numberOfCellsPerRow) - margin * (numberOfCellsPerRow - 1))/(numberOfCellsPerRow+1);
        return UIEdgeInsetsMake(margin, sideMargin, margin, sideMargin);
    }
}

- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath willMoveToIndexPath:(NSIndexPath *)toIndexPath {
    UIView* outerCollectionViewCell = collectionView.superview;
    while (![outerCollectionViewCell isKindOfClass:[UICollectionViewCell class]]){
        outerCollectionViewCell = outerCollectionViewCell.superview;
    }
    NSIndexPath* outerCollectionViewIndexPath = [self.collectionView indexPathForCell:(UICollectionViewCell *)outerCollectionViewCell];
    
    NSInteger trueFromIndex = fromIndexPath.item + (outerCollectionViewIndexPath.item) * [self collectionView:collectionView numberOfItemsInSection:fromIndexPath.section];
    NSInteger trueToIndex = toIndexPath.item + (outerCollectionViewIndexPath.item) * [self collectionView:collectionView numberOfItemsInSection:toIndexPath.section];
    
    id object = [self.framePhotos objectAtIndex:trueFromIndex];
    [self.framePhotos removeObjectAtIndex:trueFromIndex];
    [self.framePhotos insertObject:object atIndex:trueToIndex];
}

- (void) collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionView *innerCollectionView = (id)[cell.contentView viewWithTag:20];
    [innerCollectionView.collectionViewLayout invalidateLayout];
    [innerCollectionView reloadData];
}

-(void)imageEditViewController:(OLImageEditViewController *)cropper didFinishCroppingImage:(UIImage *)croppedImage{
    [self.editingAsset unloadImage];
    
    self.editingAsset.edits = cropper.edits;
    
    NSInteger frameQty = [self numberOfPhotosPerFrame];
    //Need to do some work to only reload the proper cells, otherwise the cropped image might zoom to the wrong cell.
    for (NSInteger i = 0; i < self.framePhotos.count; i++){
        if (self.framePhotos[i] == self.editingAsset){
            NSInteger outerIndex = i / frameQty;
            
            if (![self.collectionView.indexPathsForVisibleItems containsObject:[NSIndexPath indexPathForItem:outerIndex inSection:0]]){
                continue;
            }
            
            NSInteger innerIndex = i - outerIndex * frameQty;
            
            UICollectionViewCell *outerCell = [self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:outerIndex inSection:0]];
            UICollectionView *innerCollectionView = [outerCell viewWithTag:20];
            
            NSIndexPath *innerIndexPath = [NSIndexPath indexPathForItem:innerIndex inSection:0];
            
            if (innerIndexPath){
                [innerCollectionView reloadItemsAtIndexPaths:@[innerIndexPath]];
            }
        }
    }
    
    
    [cropper dismissViewControllerAnimated:YES completion:^{
        [UIView animateWithDuration:0.25 animations:^{
            self.nextButton.alpha = 1;
            self.navigationController.navigationBar.alpha = 1;
        }];
    }];
    
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackEditScreenFinishedEditingPhotoForProductName:self.product.productTemplate.name];
#endif
}

- (void)imageEditViewController:(OLImageEditViewController *)cropper didReplaceAssetWithAsset:(OLAsset *)asset{
    NSUInteger index = [[OLUserSession currentSession].userSelectedPhotos indexOfObjectIdenticalTo:self.editingAsset];
    if (index != NSNotFound){
        [[OLUserSession currentSession].userSelectedPhotos replaceObjectAtIndex:index withObject:asset];
    }
    else if ([self.editingAsset isKindOfClass:[OLPlaceholderAsset class]]){
        [[OLUserSession currentSession].userSelectedPhotos addObject:asset];
    }
    index = [self.framePhotos indexOfObjectIdenticalTo:self.editingAsset];
    [self.framePhotos replaceObjectAtIndex:index withObject:asset];
    self.editingAsset = asset;
}

- (void)imagePicker:(OLImagePickerViewController *)vc didFinishPickingAssets:(NSMutableArray *)assets added:(NSArray<OLAsset *> *)addedAssets removed:(NSArray *)removedAssets{
    OLAsset *asset = addedAssets.lastObject;
    if (asset){
        [self imageEditViewController:nil didReplaceAssetWithAsset:asset];
        
        NSInteger frameQty = [self numberOfPhotosPerFrame];
        //Need to do some work to only reload the proper cells, otherwise the cropped image might zoom to the wrong cell.
        for (NSInteger i = 0; i < self.framePhotos.count; i++){
            if (self.framePhotos[i] == self.editingAsset){
                NSInteger outerIndex = i / frameQty;
                
                if (![self.collectionView.indexPathsForVisibleItems containsObject:[NSIndexPath indexPathForItem:outerIndex inSection:0]]){
                    continue;
                }
                
                UICollectionViewCell *outerCell = [self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:outerIndex inSection:0]];
                UICollectionView *innerCollectionView = [outerCell viewWithTag:20];
                
                NSInteger innerIndex = i - outerIndex * frameQty;
                NSIndexPath *innerIndexPath = [NSIndexPath indexPathForItem:innerIndex inSection:0];
                if (innerIndexPath){
                    [innerCollectionView reloadItemsAtIndexPaths:@[innerIndexPath]];
                }
            }
        }
        
        if (self.presentedVc){
            [self.presentedVc dismissViewControllerAnimated:YES completion:NULL];
        }
        else{
            [vc dismissViewControllerAnimated:YES completion:NULL];
        }
        
        self.vcDelegateForCustomVc = nil;
        self.presentedVc = nil;
    }
}

@end
