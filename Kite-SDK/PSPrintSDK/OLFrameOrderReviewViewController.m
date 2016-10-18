//
//  Modified MIT License
//
//  Copyright (c) 2010-2016 Kite Tech Ltd. https://www.kite.ly
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

@interface OLPackProductViewController (Private) <OLInfoBannerDelegate>

- (void)updateTitleBasedOnSelectedPhotoQuanitity;
- (BOOL) shouldGoToCheckout;
- (void) doCheckout;
- (void)preparePhotosForCheckout;
-(NSUInteger) totalNumberOfExtras;
- (void)replacePhoto:(id)sender;
@property (strong, nonatomic) OLInfoBanner *infoBanner;

@end

@interface OLFrameOrderReviewViewController () <OLScrollCropViewControllerDelegate,UIViewControllerPreviewingDelegate>

@property (strong, nonatomic) NSMutableArray* framePhotos;
@property (weak, nonatomic) OLAsset *editingPrintPhoto;

@end

@implementation OLFrameOrderReviewViewController

CGFloat margin = 10;
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
        [self.framePhotos addObject:[NSNull null]];
    }
#ifdef OL_VERBOSE
    NSLog(@"Adding %lu duplicates to frame", (unsigned long)duplicatesToFillOrder);
#endif
    
    self.title = NSLocalizedStringFromTableInBundle(@"Review", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"");
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
    
    self.editingPrintPhoto = self.framePhotos[(outerCollectionViewIndexPath.item) * self.product.quantityToFulfillOrder + indexPath.row];
    
    if ([OLUserSession currentSession].kiteVc.disableEditingTools || [self.editingPrintPhoto isEqual:[NSNull null]]){
        [self replacePhoto:nil];
        return;
    }
    
    OLImageEditViewController *cropVc = [[UIStoryboard storyboardWithName:@"OLKiteStoryboard" bundle:[OLKiteUtils kiteBundle]] instantiateViewControllerWithIdentifier:@"OLScrollCropViewController"];
    cropVc.delegate = self;
    cropVc.aspectRatio = 1;
    cropVc.product = self.product;
    
    cropVc.previewView = [imageView snapshotViewAfterScreenUpdates:YES];
    cropVc.previewView.frame = [cell convertRect:imageView.frame toView:nil];
    cropVc.previewSourceView = imageView;
    cropVc.providesPresentationContextTransitionStyle = true;
    cropVc.definesPresentationContext = true;
    cropVc.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    
    [self.editingPrintPhoto imageWithSize:OLAssetMaximumSize applyEdits:NO progress:NULL completion:^(UIImage *image, NSError *error){
        [cropVc setFullImage:image];
        cropVc.edits = self.editingPrintPhoto.edits;
        cropVc.modalPresentationStyle = [OLUserSession currentSession].kiteVc.modalPresentationStyle;
        [self presentViewController:cropVc animated:NO completion:NULL];
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
        if ([asset isEqual:[NSNull null]]){
            nullCount++;
        }
    }
    
    if (nullCount > 0){
        NSInteger selected = self.framePhotos.count - nullCount;
        NSString *title = selected == 1 ? [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"You've only selected %d photo.", @"KitePrintSDK", [OLKiteUtils kiteBundle], @""), selected] : [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"You've only selected %d photos.", @"KitePrintSDK", [OLKiteUtils kiteBundle], @""), selected];
        UIAlertController *ac = [UIAlertController alertControllerWithTitle:title message:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Please add %d more.", @"KitePrintSDK", [OLKiteUtils kiteBundle], @""), nullCount] preferredStyle:UIAlertControllerStyleAlert];
        [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"OK", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"") style:UIAlertActionStyleCancel handler:NULL]];
        [self presentViewController:ac animated:YES completion:NULL];
        return NO;

    }
    
    return [super shouldGoToCheckout];
}

- (UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location{
    if ([OLUserSession currentSession].kiteVc.disableEditingTools){
        return nil;
    }
    
    NSIndexPath *outerCollectionViewIndexPath = [self.collectionView indexPathForItemAtPoint:location];
    UICollectionViewCell *outerCollectionViewCell = [self.collectionView cellForItemAtIndexPath:outerCollectionViewIndexPath];
    
    UICollectionView* collectionView = (UICollectionView*)[outerCollectionViewCell.contentView viewWithTag:20];
    
    NSIndexPath* indexPath = [collectionView indexPathForItemAtPoint:[collectionView convertPoint:location fromView:self.collectionView]];
    
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    OLRemoteImageView *imageView = (OLRemoteImageView *)[cell viewWithTag:110];
    
    OLAsset *printPhoto =(OLAsset*)[self.framePhotos objectAtIndex:indexPath.row + (outerCollectionViewIndexPath.item) * self.product.quantityToFulfillOrder];
    if (!imageView.image){
        return nil;
    }
    
    [previewingContext setSourceRect:[cell convertRect:imageView.frame toView:self.collectionView]];
    
    self.editingPrintPhoto = printPhoto;
    
    OLImagePreviewViewController *previewVc = [[OLImagePreviewViewController alloc] init];
    __weak OLImagePreviewViewController *weakVc = previewVc;
    [previewVc.imageView setAndFadeInImageWithOLAsset:self.editingPrintPhoto size:self.view.frame.size applyEdits:YES placeholder:nil progress:^(float progress){
        [weakVc.imageView setProgress:progress];
    }completionHandler:NULL];
    previewVc.providesPresentationContextTransitionStyle = true;
    previewVc.definesPresentationContext = true;
    previewVc.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    return previewVc;
}

- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit{
    OLImageEditViewController *cropVc = [[UIStoryboard storyboardWithName:@"OLKiteStoryboard" bundle:[OLKiteUtils kiteBundle]] instantiateViewControllerWithIdentifier:@"OLScrollCropViewController"];
    cropVc.enableCircleMask = self.product.productTemplate.templateUI == OLTemplateUICircle;
    cropVc.delegate = self;
    cropVc.aspectRatio = 1;
    cropVc.product = self.product;
    
    [self.editingPrintPhoto imageWithSize:OLAssetMaximumSize applyEdits:NO progress:^(float progress){
        [cropVc.cropView setProgress:progress];
    }completion:^(UIImage *image, NSError *error){
        [cropVc setFullImage:image];
        cropVc.edits = self.editingPrintPhoto.edits;
        cropVc.modalPresentationStyle = [OLUserSession currentSession].kiteVc.modalPresentationStyle;
        [self presentViewController:cropVc animated:YES completion:NULL];
    }];
    
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackReviewScreenEnteredCropScreenForProductName:self.product.productTemplate.name];
#endif
}

#pragma mark Button Actions

- (IBAction)onButtonNextClicked:(UIBarButtonItem *)sender {
    if (![self shouldGoToCheckout]){
        return;
    }
    
    [self doCheckout];
}


#pragma mark UICollectionView data source and delegate methods

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    if (collectionView.tag == 10){
        NSInteger numberOfPhotosPerFrame = self.product.productTemplate.templateUI == OLTemplateUIFrame ? self.product.quantityToFulfillOrder : (self.product.productTemplate.gridCountX * self.product.productTemplate.gridCountY != 0 ? self.product.productTemplate.gridCountX * self.product.productTemplate.gridCountY : 4);
        int incompleteFrame = ([self.framePhotos count] % numberOfPhotosPerFrame) != 0 ? 1 : 0;
        return [self.framePhotos count]/self.product.quantityToFulfillOrder + incompleteFrame;
    }
    else{
        return self.product.quantityToFulfillOrder;
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
        float scaleFactorH = size.width / 320.0;
        
        view.translatesAutoresizingMaskIntoConstraints = NO;
        views = NSDictionaryOfVariableBindings(view);
        con = [[NSMutableArray alloc] init];
        
        visuals = @[[NSString stringWithFormat:@"H:|-%f-[view]-%f-|", innerCollectionViewHorizontalMargin * scaleFactorH, innerCollectionViewHorizontalMargin * scaleFactorH],
                    [NSString stringWithFormat:@"V:|-%f-[view]", innerCollectionViewTopMargin * scaleFactorH]];
        
        
        for (NSString *visual in visuals) {
            [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
        }
        
        [view.superview addConstraints:con];
        
        if (self.product.productTemplate.templateUI != OLTemplateUIFrame){
            cell.contentView.backgroundColor = [UIColor whiteColor];
            
            UIImageView *imageView = [cell.contentView viewWithTag:1010];
            [imageView setAndFadeInImageWithURL:[NSURL URLWithString:@"https://dl.dropboxusercontent.com/u/3007013/calendar_test.png"]];
            
            for (NSLayoutConstraint *con in imageView.constraints){
                if ([con.identifier isEqualToString:@"calendarHeightCon"]){
                    con.constant = 125 * scaleFactorH;
                }
                if ([con.identifier isEqualToString:@"imageTopCon"]){
                    con.constant = 10 * scaleFactorH;
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
        
        OLAsset *printPhoto =(OLAsset*)[self.framePhotos objectAtIndex:indexPath.row + (outerCollectionViewIndexPath.item) * numberOfPhotosPerFrame];
        [cellImage setAndFadeInImageWithOLAsset:printPhoto size:[self collectionView:collectionView layout:collectionView.collectionViewLayout sizeForItemAtIndexPath:indexPath] applyEdits:YES placeholder:nil progress:^(float progress){
                        [cellImage setProgress:progress];
        } completionHandler:NULL];
        
        UITapGestureRecognizer* doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapGestureThumbnailTapped:)];
        [cellImage addGestureRecognizer:doubleTap];
        
        return cell;
    }
}

- (void)addInfoBanner{
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        if ([OLUserSession currentSession].kiteVc.disableEditingTools){
            self.infoBanner = [OLInfoBanner showInfoBannerOnViewController:self withTitle:NSLocalizedStringFromTableInBundle(@"Tap Image to Change ", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"")];
        }
        else{
            self.infoBanner = [OLInfoBanner showInfoBannerOnViewController:self withTitle:NSLocalizedStringFromTableInBundle(@"Tap Image to Edit or Hold to Rearrange", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"")];
        }
        self.infoBanner.delegate = self;
        self.collectionView.contentInset = UIEdgeInsetsMake(self.collectionView.contentInset.top + 50, self.collectionView.contentInset.left, self.collectionView.contentInset.bottom, self.collectionView.contentInset.right);
    });
}

- (CGSize) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    if (collectionView.tag == 10){
        CGSize size = self.view.frame.size;
        CGFloat height = self.product.productTemplate.templateUI == OLTemplateUIFrame ? 351 : 427;
        if (MIN(size.height, size.width) == 320){
            float scaleFactorH = (MIN(self.view.frame.size.width, self.view.frame.size.height)-20) / 320.0;
            return CGSizeMake(320 * scaleFactorH, height * scaleFactorH);
        }
        return CGSizeMake(320, height);
    }
    else{
        CGFloat photosPerRow = sqrt(self.product.quantityToFulfillOrder);

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
        return UIEdgeInsetsMake(margin,margin,margin,margin);
    }
}

- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath willMoveToIndexPath:(NSIndexPath *)toIndexPath {
    UIView* outerCollectionViewCell = collectionView.superview;
    while (![outerCollectionViewCell isKindOfClass:[UICollectionViewCell class]]){
        outerCollectionViewCell = outerCollectionViewCell.superview;
    }
    NSIndexPath* outerCollectionViewIndexPath = [self.collectionView indexPathForCell:(UICollectionViewCell *)outerCollectionViewCell];
    
    NSInteger trueFromIndex = fromIndexPath.item + (outerCollectionViewIndexPath.item) * self.product.quantityToFulfillOrder;
    NSInteger trueToIndex = toIndexPath.item + (outerCollectionViewIndexPath.item) * self.product.quantityToFulfillOrder;
    
    id object = [self.framePhotos objectAtIndex:trueFromIndex];
    [self.framePhotos removeObjectAtIndex:trueFromIndex];
    [self.framePhotos insertObject:object atIndex:trueToIndex];
}

- (void) collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionView *innerCollectionView = (id)[cell.contentView viewWithTag:20];
    [innerCollectionView.collectionViewLayout invalidateLayout];
    [innerCollectionView reloadData];
}

- (void)scrollCropViewControllerDidCancel:(OLImageEditViewController *)cropper{
    [cropper dismissViewControllerAnimated:YES completion:NULL];
}

-(void)scrollCropViewController:(OLImageEditViewController *)cropper didFinishCroppingImage:(UIImage *)croppedImage{
    [self.editingPrintPhoto unloadImage];
    
    self.editingPrintPhoto.edits = cropper.edits;
    
    //Need to do some work to only reload the proper cells, otherwise the cropped image might zoom to the wrong cell.
    for (NSInteger i = 0; i < self.framePhotos.count; i++){
        if (self.framePhotos[i] == self.editingPrintPhoto){
            NSInteger outerIndex = i / self.product.quantityToFulfillOrder;
            
            if (![self.collectionView.indexPathsForVisibleItems containsObject:[NSIndexPath indexPathForItem:outerIndex inSection:0]]){
                continue;
            }
            
            NSInteger innerIndex = i - outerIndex * self.product.quantityToFulfillOrder;
            
            UICollectionViewCell *outerCell = [self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:outerIndex inSection:0]];
            UICollectionView *innerCollectionView = [outerCell viewWithTag:20];
            
            NSIndexPath *innerIndexPath = [NSIndexPath indexPathForItem:innerIndex inSection:0];
            
            if (innerIndexPath){
                [innerCollectionView reloadItemsAtIndexPaths:@[innerIndexPath]];
            }
        }
    }
    
    
    [cropper dismissViewControllerAnimated:YES completion:^{}];
    
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackReviewScreenDidCropPhotoForProductName:self.product.productTemplate.name];
#endif
}

- (void)scrollCropViewController:(OLImageEditViewController *)cropper didReplaceAssetWithAsset:(OLAsset *)asset{
    NSUInteger index = [[OLUserSession currentSession].userSelectedPhotos indexOfObjectIdenticalTo:self.editingPrintPhoto];
    if (index != NSNotFound){
        [[OLUserSession currentSession].userSelectedPhotos replaceObjectAtIndex:index withObject:asset];
    }
    else if ([self.editingPrintPhoto isEqual:[NSNull null]]){
        [[OLUserSession currentSession].userSelectedPhotos addObject:asset];
    }
    index = [self.framePhotos indexOfObjectIdenticalTo:self.editingPrintPhoto];
    [self.framePhotos replaceObjectAtIndex:index withObject:asset];
    self.editingPrintPhoto = asset;
}

- (void)imagePicker:(OLImagePickerViewController *)vc didFinishPickingAssets:(NSMutableArray *)assets added:(NSArray<OLAsset *> *)addedAssets removed:(NSArray *)removedAssets{
    OLAsset *asset = addedAssets.lastObject;
    if (asset){
        [self scrollCropViewController:nil didReplaceAssetWithAsset:asset];
        
        //Need to do some work to only reload the proper cells, otherwise the cropped image might zoom to the wrong cell.
        for (NSInteger i = 0; i < self.framePhotos.count; i++){
            if (self.framePhotos[i] == self.editingPrintPhoto){
                NSInteger outerIndex = i / self.product.quantityToFulfillOrder;
                
                if (![self.collectionView.indexPathsForVisibleItems containsObject:[NSIndexPath indexPathForItem:outerIndex inSection:0]]){
                    continue;
                }
                
                NSInteger innerIndex = i - outerIndex * self.product.quantityToFulfillOrder;
                
                UICollectionViewCell *outerCell = [self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:outerIndex inSection:0]];
                UICollectionView *innerCollectionView = [outerCell viewWithTag:20];
                
                NSIndexPath *innerIndexPath = [NSIndexPath indexPathForItem:innerIndex inSection:0];
                
                if (innerIndexPath){
                    [innerCollectionView reloadItemsAtIndexPaths:@[innerIndexPath]];
                }
            }
        }
        
        [vc dismissViewControllerAnimated:YES completion:NULL];
    }
}

@end
