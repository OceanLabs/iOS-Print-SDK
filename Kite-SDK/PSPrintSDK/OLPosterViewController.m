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

#import "OLPosterViewController.h"
#import "OLProduct.h"
#import "OLAnalytics.h"
#import "OLAsset.h"
#import "LXReorderableCollectionViewFlowLayout.h"
#import "OLImageEditViewController.h"
#import "OLKiteViewController.h"
#import "NSObject+Utils.h"
#import "OLAnalytics.h"
#import "OLKitePrintSDK.h"
#import "OLKiteABTesting.h"
#import "OLRemoteImageView.h"
#import "OLKiteUtils.h"
#import "OLImagePreviewViewController.h"
#import "OLUserSession.h"
#import "OLAsset+Private.h"

CGFloat posterMargin = 2;

@interface OLPrintOrder (Private)

- (void)saveOrder;

@end

@interface OLPosterViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UICollectionViewDelegate, LXReorderableCollectionViewDataSource, OLScrollCropViewControllerDelegate>

@property (strong, nonatomic) NSMutableArray *posterPhotos;
@property (assign, nonatomic) CGFloat numberOfRows;
@property (assign, nonatomic) CGFloat numberOfColumns;
@property (weak, nonatomic) OLAsset *editingPrintPhoto;
@property (assign, nonatomic) CGSize rotationSize;

@end

@interface OLKiteViewController ()
- (void)dismiss;
@end

@interface OLOrderReviewViewController (Private) <UICollectionViewDelegateFlowLayout>

- (BOOL) shouldGoToCheckout;
- (void) doCheckout;

@end

@implementation OLPosterViewController

-(void)viewDidLoad{
    [super viewDidLoad];
    
    // ensure order is maxed out by adding duplicates as necessary
    self.posterPhotos = [[NSMutableArray alloc] init];
    [self.posterPhotos addObjectsFromArray:[OLUserSession currentSession].userSelectedPhotos];
    NSUInteger userSelectedAssetCount = [self.posterPhotos count];
    NSUInteger numOrders = (NSUInteger) floor(userSelectedAssetCount + self.product.quantityToFulfillOrder - 1) / self.product.quantityToFulfillOrder;
    NSUInteger duplicatesToFillOrder = numOrders * self.product.quantityToFulfillOrder - userSelectedAssetCount;
    for (NSUInteger i = 0; i < duplicatesToFillOrder; ++i) {
        [self.posterPhotos addObject:[OLUserSession currentSession].userSelectedPhotos[i % userSelectedAssetCount]];
    }
#ifdef OL_VERBOSE
    NSLog(@"Adding %lu duplicates to frame", (unsigned long)duplicatesToFillOrder);
#endif
    
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

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    self.rotationSize = size;
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    CGSize oldSize = self.view.frame.size;
    BOOL iPadMutitasking = oldSize.width != size.height || oldSize.height != size.width;
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinator> context){
        if (iPadMutitasking){
            [self.collectionView reloadData];
        }
    }completion:^(id<UIViewControllerTransitionCoordinator> context){
        
    }];
}

- (NSInteger) numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath{
    UICollectionReusableView * cell = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"reviewHeaderCell" forIndexPath:indexPath];
    return cell;
}

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    if (collectionView.tag == 10){
        int incompleteFrame = ([self.posterPhotos count] % self.product.quantityToFulfillOrder) != 0 ? 1 : 0;
        return [self.posterPhotos count]/self.product.quantityToFulfillOrder + incompleteFrame;
    }
    else{
        return self.product.quantityToFulfillOrder;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    if (collectionView.tag == 10){
        UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"posterCell" forIndexPath:indexPath];
        
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
        
        return cell;
    }
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"photoCell" forIndexPath:indexPath];
    
    UIView* view = collectionView.superview;
    while (![view isKindOfClass:[UICollectionViewCell class]]){
        view = view.superview;
    }
    
    NSIndexPath* outerCollectionViewIndexPath = [self.collectionView indexPathForCell:(UICollectionViewCell *)view];
    
    UIActivityIndicatorView *activity = (UIActivityIndicatorView *)[cell viewWithTag:796];
    [activity startAnimating];
    
    OLRemoteImageView *imageView = (OLRemoteImageView *)[cell viewWithTag:795];
    imageView.image = nil;
    imageView.userInteractionEnabled = YES;
    [imageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onButtonEnhanceClicked:)]];
    
    OLAsset *printPhoto =(OLAsset*)[self.posterPhotos objectAtIndex:indexPath.row + (outerCollectionViewIndexPath.item) * self.product.quantityToFulfillOrder];
    
    [printPhoto imageWithSize:[self collectionView:collectionView layout:collectionView.collectionViewLayout sizeForItemAtIndexPath:indexPath] applyEdits:YES progress:^(float progress){
        [imageView setProgress:progress];
    } completion:^(UIImage *image){
        dispatch_async(dispatch_get_main_queue(), ^{
            imageView.image = image;
            [activity stopAnimating];
        });
    }];
    
    return cell;
}

- (void) collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionView *innerCollectionView = (id)[cell.contentView viewWithTag:20];
    [innerCollectionView.collectionViewLayout invalidateLayout];
    [innerCollectionView reloadData];
}

- (CGSize) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    if (collectionView.tag == 10){
        CGSize size = self.rotationSize.width != 0 ? self.rotationSize : self.view.frame.size;
        size = CGSizeMake(MIN(size.width, size.height), MAX(size.width, size.height));
        return CGSizeMake(size.width - 30, (size.width-30) * (1.392857143));
    }
    
    CGFloat margin = [self collectionView:collectionView layout:collectionView.collectionViewLayout minimumInteritemSpacingForSectionAtIndex:indexPath.section];
    CGSize size = CGSizeMake(MIN(collectionView.frame.size.width, collectionView.frame.size.height), MAX(collectionView.frame.size.width, collectionView.frame.size.height));
    CGFloat width = (size.width - (self.numberOfColumns - 1) * margin)/ self.numberOfColumns;
    CGFloat height = (size.height - (self.numberOfRows - 1) * margin) / self.numberOfRows;
    return CGSizeMake(width, height);
}

- (UIEdgeInsets)collectionView:
(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, 0, 0, 0);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section{
    return posterMargin;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section{
    return posterMargin;
}

- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath willMoveToIndexPath:(NSIndexPath *)toIndexPath {
    UIView* outerCollectionViewCell = collectionView.superview;
    while (![outerCollectionViewCell isKindOfClass:[UICollectionViewCell class]]){
        outerCollectionViewCell = outerCollectionViewCell.superview;
    }
    NSIndexPath* outerCollectionViewIndexPath = [self.collectionView indexPathForCell:(UICollectionViewCell *)outerCollectionViewCell];
    
    NSInteger trueFromIndex = fromIndexPath.item + (outerCollectionViewIndexPath.item) * self.product.quantityToFulfillOrder;
    NSInteger trueToIndex = toIndexPath.item + (outerCollectionViewIndexPath.item) * self.product.quantityToFulfillOrder;
    
    id object = [self.posterPhotos objectAtIndex:trueFromIndex];
    [self.posterPhotos removeObjectAtIndex:trueFromIndex];
    [self.posterPhotos insertObject:object atIndex:trueToIndex];
}

- (BOOL)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath canMoveToIndexPath:(NSIndexPath *)toIndexPath{
    return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath{
    return YES;
}

+(void)changeOrderOfPhotosInArray:(NSMutableArray*)array forProduct:(OLProduct *)product{
    NSMutableArray *subArrays = [[NSMutableArray alloc] init];
    for (NSInteger i = 0; i < array.count / product.quantityToFulfillOrder; i++) {
        [subArrays addObject:[[array subarrayWithRange:NSMakeRange(i*product.quantityToFulfillOrder, product.quantityToFulfillOrder)] mutableCopy]];
    }
    
    for (NSMutableArray *subArray in subArrays){
        NSMutableArray* rows = [[NSMutableArray alloc] initWithCapacity:product.productTemplate.gridCountY];
        for (NSUInteger rowNumber = 0; rowNumber < product.productTemplate.gridCountY; rowNumber++){
            NSMutableArray* row = [[NSMutableArray alloc] initWithCapacity:product.productTemplate.gridCountX];
            for (NSUInteger photoInRow = 0; photoInRow < product.productTemplate.gridCountX; photoInRow++){
                [row addObject:subArray[rowNumber * (NSInteger)product.productTemplate.gridCountX + photoInRow]];
            }
            [rows addObject:row];
        }
        
        [subArray removeAllObjects];
        for (NSInteger rowNumber = product.productTemplate.gridCountY - 1; rowNumber >= 0; rowNumber--){
            [subArray addObjectsFromArray:rows[rowNumber]];
        }
    }
    
    [array removeAllObjects];
    for (NSArray *subArray in subArrays){
        [array addObjectsFromArray:subArray];
    }
}

- (void)preparePhotosForCheckout{
    NSMutableArray *reversePhotos = [self.posterPhotos mutableCopy];
    [OLPosterViewController changeOrderOfPhotosInArray:reversePhotos forProduct:self.product];
    self.checkoutPhotos = reversePhotos;
}

- (IBAction)onButtonNextClicked:(UIBarButtonItem *)sender {
    if (![self shouldGoToCheckout]){
        return;
    }
    
    [self doCheckout];
}

- (IBAction)onButtonEnhanceClicked:(id)sender {
    UITapGestureRecognizer* gestureRecognizer = sender;
    NSIndexPath *outerCollectionViewIndexPath = [self.collectionView indexPathForItemAtPoint:[gestureRecognizer locationInView:self.collectionView]];
    UICollectionViewCell *outerCollectionViewCell = [self.collectionView cellForItemAtIndexPath:outerCollectionViewIndexPath];
    
    UICollectionView* collectionView = (UICollectionView*)[outerCollectionViewCell.contentView viewWithTag:20];
    
    NSIndexPath* indexPath = [collectionView indexPathForItemAtPoint:[gestureRecognizer locationInView:collectionView]];
    
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    OLRemoteImageView *imageView = (OLRemoteImageView *)[cell viewWithTag:795];
    
    if (!imageView.image){
        return;
    }
    
    self.editingPrintPhoto = self.posterPhotos[(outerCollectionViewIndexPath.item) * self.product.quantityToFulfillOrder + indexPath.row];
    
    OLImageEditViewController *cropVc = [self.storyboard instantiateViewControllerWithIdentifier:@"OLScrollCropViewController"];
    cropVc.delegate = self;
    cropVc.aspectRatio = 1;
    
    cropVc.previewView = [imageView snapshotViewAfterScreenUpdates:YES];
    cropVc.previewView.frame = [imageView.superview convertRect:imageView.frame toView:nil];
    cropVc.previewSourceView = imageView;
    cropVc.providesPresentationContextTransitionStyle = true;
    cropVc.definesPresentationContext = true;
    cropVc.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    
    [self.editingPrintPhoto imageWithSize:OLAssetMaximumSize applyEdits:NO progress:NULL completion:^(UIImage *image){
        [cropVc setFullImage:image];
        cropVc.edits = self.editingPrintPhoto.edits;
        //        cropVc.modalPresentationStyle = [OLKiteUtils kiteVcForViewController:self].modalPresentationStyle;
        [self presentViewController:cropVc animated:NO completion:NULL];
    }];
}

- (UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location{
    NSIndexPath *outerCollectionViewIndexPath = [self.collectionView indexPathForItemAtPoint:location];
    UICollectionViewCell *outerCollectionViewCell = [self.collectionView cellForItemAtIndexPath:outerCollectionViewIndexPath];
    
    UICollectionView* collectionView = (UICollectionView*)[outerCollectionViewCell.contentView viewWithTag:20];
    
    NSIndexPath* indexPath = [collectionView indexPathForItemAtPoint:[collectionView convertPoint:location fromView:self.collectionView]];
    
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    OLRemoteImageView *imageView = (OLRemoteImageView *)[cell viewWithTag:795];
    
    OLAsset *printPhoto =(OLAsset*)[self.posterPhotos objectAtIndex:indexPath.row + (outerCollectionViewIndexPath.item) * self.product.quantityToFulfillOrder];
    if (!imageView.image){
        return nil;
    }
    
    [previewingContext setSourceRect:[cell convertRect:imageView.frame toView:self.collectionView]];
    
    self.editingPrintPhoto = printPhoto;
    
    OLImagePreviewViewController *previewVc = [self.storyboard instantiateViewControllerWithIdentifier:@"OLImagePreviewViewController"];
    [self.editingPrintPhoto imageWithSize:OLAssetMaximumSize applyEdits:NO progress:NULL completion:^(UIImage *image){
        previewVc.image = image;
    }];
    previewVc.providesPresentationContextTransitionStyle = true;
    previewVc.definesPresentationContext = true;
    previewVc.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    return previewVc;
}

- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit{
    OLImageEditViewController *cropVc = [self.storyboard instantiateViewControllerWithIdentifier:@"OLScrollCropViewController"];
    cropVc.enableCircleMask = self.product.productTemplate.templateUI == kOLTemplateUICircle;
    cropVc.delegate = self;
    cropVc.aspectRatio = 1;
    [self.editingPrintPhoto imageWithSize:OLAssetMaximumSize applyEdits:NO progress:^(float progress){
        [cropVc.cropView setProgress:progress];
    }completion:^(UIImage *image){
        [cropVc setFullImage:image];
        cropVc.edits = self.editingPrintPhoto.edits;
        cropVc.modalPresentationStyle = [OLKiteUtils kiteVcForViewController:self].modalPresentationStyle;
        [self presentViewController:cropVc animated:YES completion:NULL];        
    }];
    
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackReviewScreenEnteredCropScreenForProductName:self.product.productTemplate.name];
#endif
}

#pragma mark - OLImageEditorViewControllerDelegate methods

- (void)scrollCropViewControllerDidCancel:(OLImageEditViewController *)cropper{
    [cropper dismissViewControllerAnimated:YES completion:NULL];
}

-(void)scrollCropViewController:(OLImageEditViewController *)cropper didFinishCroppingImage:(UIImage *)croppedImage{
    [self.editingPrintPhoto unloadImage];
    
    self.editingPrintPhoto.edits = cropper.edits;
    
    //Need to do some work to only reload the proper cells, otherwise the cropped image might zoom to the wrong cell.
    NSMutableArray *indexPaths = [[NSMutableArray alloc] init];
    for (NSInteger i = 0; i < self.posterPhotos.count; i++){
        if (self.posterPhotos[i] == self.editingPrintPhoto){
            NSInteger outerIndex = i / self.product.quantityToFulfillOrder;

            if (![self.collectionView.indexPathsForVisibleItems containsObject:[NSIndexPath indexPathForItem:outerIndex inSection:0]]){
                continue;
            }
            
            NSInteger innerIndex = i - outerIndex * self.product.quantityToFulfillOrder;
            
            UICollectionViewCell *outerCell = [self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:outerIndex inSection:0]];
            UICollectionView *innerCollectionView = [outerCell viewWithTag:20];
            
            
            
            NSIndexPath *innerIndexPath = [NSIndexPath indexPathForItem:innerIndex inSection:0];
            [indexPaths addObject:innerIndexPath];
            
            if (outerIndex != i+1 / self.product.quantityToFulfillOrder){
                [innerCollectionView reloadItemsAtIndexPaths:indexPaths];
                [indexPaths removeAllObjects];
            }
        }
    }
    
    
    [cropper dismissViewControllerAnimated:YES completion:^{}];
    
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackReviewScreenDidCropPhotoForProductName:self.product.productTemplate.name];
#endif
}

@end
