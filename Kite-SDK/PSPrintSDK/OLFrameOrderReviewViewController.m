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

#ifdef COCOAPODS
#import <SDWebImage/SDWebImageManager.h>
#else
#import "SDWebImageManager.h"
#endif

#ifdef COCOAPODS
#import <SDWebImage/SDWebImageManager.h>
#else
#import "SDWebImageManager.h"
#endif

#import "OLFrameOrderReviewViewController.h"
#import "OLPrintPhoto.h"
#import "OLProduct.h"
#import "OLAsset+Private.h"
#import "UIViewController+TraitCollectionCompatibility.h"
#import "OLRemoteImageView.h"
#import "OLKiteUtils.h"
#import "OLKiteViewController.h"
#import "OLImagePreviewViewController.h"
#import "OLAnalytics.h"
#import "OLKitePrintSDK.h"

#ifdef OL_KITE_OFFER_ADOBE
#import <AdobeCreativeSDKImage/AdobeCreativeSDKImage.h>
#import <AdobeCreativeSDKCore/AdobeCreativeSDKCore.h>
#endif

@interface OLKitePrintSDK (Private)

+ (NSString *)adobeCreativeSDKClientSecret;
+ (NSString *)adobeCreativeSDKClientID;

@end

@interface OLOrderReviewViewController (Private)

- (void)updateTitleBasedOnSelectedPhotoQuanitity;
- (BOOL) shouldGoToCheckout;
- (void) doCheckout;
- (void)preparePhotosForCheckout;
-(NSUInteger) totalNumberOfExtras;

@end

@interface OLFrameOrderReviewViewController () <OLScrollCropViewControllerDelegate,
#ifdef OL_KITE_OFFER_ADOBE
AdobeUXImageEditorViewControllerDelegate,
#endif
UIViewControllerPreviewingDelegate>

@property (strong, nonatomic) NSMutableArray* framePhotos;
@property (weak, nonatomic) OLPrintPhoto *editingPrintPhoto;

@end

@implementation OLFrameOrderReviewViewController

CGFloat margin = 2;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // ensure order is maxed out by adding duplicates as necessary
    self.framePhotos = [[NSMutableArray alloc] init];
    [self.framePhotos addObjectsFromArray:self.userSelectedPhotos];
    NSUInteger userSelectedAssetCount = [self.framePhotos count];
    NSUInteger numOrders = (NSUInteger) floor(userSelectedAssetCount + self.product.quantityToFulfillOrder - 1) / self.product.quantityToFulfillOrder;
    NSUInteger duplicatesToFillOrder = numOrders * self.product.quantityToFulfillOrder - userSelectedAssetCount;
    for (NSUInteger i = 0; i < duplicatesToFillOrder; ++i) {
        [self.framePhotos addObject:self.userSelectedPhotos[i % userSelectedAssetCount]];
    }
#ifdef OL_VERBOSE
    NSLog(@"Adding %lu duplicates to frame", (unsigned long)duplicatesToFillOrder);
#endif
    
    self.title = NSLocalizedString(@"Review", @"");
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
    
#ifdef OL_KITE_OFFER_ADOBE
    [[AdobeUXAuthManager sharedManager] setAuthenticationParametersWithClientID:[OLKitePrintSDK adobeCreativeSDKClientID] clientSecret:[OLKitePrintSDK adobeCreativeSDKClientSecret] enableSignUp:true];
    [AdobeImageEditorCustomization setCropToolPresets:@[@{kAdobeImageEditorCropPresetName:@"", kAdobeImageEditorCropPresetWidth:@1, kAdobeImageEditorCropPresetHeight:@1}]];
    [AdobeImageEditorCustomization setCropToolCustomEnabled:NO];
    [AdobeImageEditorCustomization setCropToolInvertEnabled:NO];
    [AdobeImageEditorCustomization setCropToolOriginalEnabled:NO];
    
    [self.editingPrintPhoto getImageWithProgress:NULL completion:^(UIImage *image){
        AdobeUXImageEditorViewController *editorController = [[AdobeUXImageEditorViewController alloc] initWithImage:image];
        [editorController setDelegate:self];
        [self presentViewController:editorController animated:YES completion:nil];
    }];
#else
    
    OLScrollCropViewController *cropVc = [self.storyboard instantiateViewControllerWithIdentifier:@"OLScrollCropViewController"];
    cropVc.delegate = self;
    cropVc.aspectRatio = 1;
    
    cropVc.previewView = [imageView snapshotViewAfterScreenUpdates:YES];
    cropVc.previewView.frame = [cell convertRect:imageView.frame toView:nil];
    cropVc.previewSourceView = imageView;
    cropVc.providesPresentationContextTransitionStyle = true;
    cropVc.definesPresentationContext = true;
    cropVc.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    
    [self.editingPrintPhoto getImageWithProgress:NULL completion:^(UIImage *image){
        [cropVc setFullImage:image];
        cropVc.edits = self.editingPrintPhoto.edits;
//        cropVc.modalPresentationStyle = [OLKiteUtils kiteVcForViewController:self].modalPresentationStyle;
        [self presentViewController:cropVc animated:NO completion:NULL];
    }];
#endif
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
    NSMutableArray *reversePhotos = [self.framePhotos mutableCopy];
    [OLFrameOrderReviewViewController reverseRowsOfPhotosInArray:reversePhotos forProduct:self.product];
    self.checkoutPhotos = reversePhotos;
}

- (BOOL)shouldShowAddMorePhotos{
    return NO;
}

-(NSUInteger) totalNumberOfExtras{
    return 0;
}

- (UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location{
    NSIndexPath *outerCollectionViewIndexPath = [self.collectionView indexPathForItemAtPoint:location];
    UICollectionViewCell *outerCollectionViewCell = [self.collectionView cellForItemAtIndexPath:outerCollectionViewIndexPath];
    
    UICollectionView* collectionView = (UICollectionView*)[outerCollectionViewCell.contentView viewWithTag:20];
    
    NSIndexPath* indexPath = [collectionView indexPathForItemAtPoint:[collectionView convertPoint:location fromView:self.collectionView]];
    
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    OLRemoteImageView *imageView = (OLRemoteImageView *)[cell viewWithTag:110];
    
    OLPrintPhoto *printPhoto =(OLPrintPhoto*)[self.framePhotos objectAtIndex:indexPath.row + (outerCollectionViewIndexPath.item) * self.product.quantityToFulfillOrder];
    if (!imageView.image){
        return nil;
    }
    
    [previewingContext setSourceRect:[cell convertRect:imageView.frame toView:self.collectionView]];
    
    self.editingPrintPhoto = printPhoto;
    
    OLImagePreviewViewController *previewVc = [self.storyboard instantiateViewControllerWithIdentifier:@"OLImagePreviewViewController"];
    [self.editingPrintPhoto getImageWithProgress:NULL completion:^(UIImage *image){
        previewVc.image = image;
    }];
    previewVc.providesPresentationContextTransitionStyle = true;
    previewVc.definesPresentationContext = true;
    previewVc.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    return previewVc;
}

- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit{
#ifdef OL_KITE_OFFER_ADOBE
    [[AdobeUXAuthManager sharedManager] setAuthenticationParametersWithClientID:[OLKitePrintSDK adobeCreativeSDKClientID] clientSecret:[OLKitePrintSDK adobeCreativeSDKClientSecret] enableSignUp:true];
    [AdobeImageEditorCustomization setCropToolPresets:@[@{kAdobeImageEditorCropPresetName:@"", kAdobeImageEditorCropPresetWidth:@1, kAdobeImageEditorCropPresetHeight:@1}]];
    [AdobeImageEditorCustomization setCropToolCustomEnabled:NO];
    [AdobeImageEditorCustomization setCropToolInvertEnabled:NO];
    [AdobeImageEditorCustomization setCropToolOriginalEnabled:NO];
    
    [self.editingPrintPhoto getImageWithProgress:NULL completion:^(UIImage *image){
        AdobeUXImageEditorViewController *editorController = [[AdobeUXImageEditorViewController alloc] initWithImage:image];
        [editorController setDelegate:self];
        [self presentViewController:editorController animated:YES completion:nil];
    }];
#else
    OLScrollCropViewController *cropVc = [self.storyboard instantiateViewControllerWithIdentifier:@"OLScrollCropViewController"];
    cropVc.enableCircleMask = self.product.productTemplate.templateUI == kOLTemplateUICircle;
    cropVc.delegate = self;
    cropVc.aspectRatio = 1;
    [self.editingPrintPhoto getImageWithProgress:^(float progress){
        [cropVc.cropView setProgress:progress];
    }completion:^(UIImage *image){
        [cropVc setFullImage:image];
        cropVc.edits = self.editingPrintPhoto.edits;
        cropVc.modalPresentationStyle = [OLKiteUtils kiteVcForViewController:self].modalPresentationStyle;
        [self presentViewController:cropVc animated:YES completion:NULL];
    }];
#endif
    
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

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath{
    UICollectionReusableView * cell = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"reviewHeaderCell" forIndexPath:indexPath];
    return cell;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    if (collectionView.tag == 10){
        int incompleteFrame = ([self.framePhotos count] % self.product.quantityToFulfillOrder) != 0 ? 1 : 0;
        return [self.framePhotos count]/self.product.quantityToFulfillOrder + incompleteFrame;
    }
    else{
        return self.product.quantityToFulfillOrder;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    if (collectionView.tag == 10){
        UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"reviewCell" forIndexPath:indexPath];
        
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
        
        view = innerCollectionView;
        
        CGSize size = [self collectionView:collectionView layout:collectionView.collectionViewLayout sizeForItemAtIndexPath:indexPath];
        float scaleFactorH = size.width / 320.0;
        
        view.translatesAutoresizingMaskIntoConstraints = NO;
        views = NSDictionaryOfVariableBindings(view);
        con = [[NSMutableArray alloc] init];
        
        visuals = @[[NSString stringWithFormat:@"H:|-%f-[view]-%f-|", 25 * scaleFactorH, 25 * scaleFactorH],
                             [NSString stringWithFormat:@"V:|-%f-[view]", 53 * scaleFactorH]];
        
        
        for (NSString *visual in visuals) {
            [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
        }
        
        [view.superview addConstraints:con];

        
        return cell;
    }
    else{
        UICollectionViewCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"imageCell" forIndexPath:indexPath];
        
        //Workaround for iOS 7
        if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8){
            cell.contentView.frame = cell.bounds;
            cell.contentView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin |UIViewAutoresizingFlexibleTopMargin |UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
        }
        
        UIView* view = collectionView.superview;
        while (![view isKindOfClass:[UICollectionViewCell class]]){
            view = view.superview;
        }
        
        NSIndexPath* outerCollectionViewIndexPath = [self.collectionView indexPathForCell:(UICollectionViewCell *)view];
        
        OLRemoteImageView* cellImage = (OLRemoteImageView*)[cell.contentView viewWithTag:110];
        cellImage.userInteractionEnabled = YES;
        cellImage.image = nil;
        
        OLPrintPhoto *printPhoto =(OLPrintPhoto*)[self.framePhotos objectAtIndex:indexPath.row + (outerCollectionViewIndexPath.item) * self.product.quantityToFulfillOrder];
        [printPhoto setImageSize:[self collectionView:collectionView layout:collectionView.collectionViewLayout sizeForItemAtIndexPath:indexPath] cropped:YES progress:^(float progress){
            [cellImage setProgress:progress];
        }completionHandler:^(UIImage *image){
            dispatch_async(dispatch_get_main_queue(), ^{
                cellImage.image = image;
            });
        }];
        
        UITapGestureRecognizer* doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapGestureThumbnailTapped:)];
        [cellImage addGestureRecognizer:doubleTap];
        
        return cell;
    }
}

- (CGSize) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    if (collectionView.tag == 10){
        CGSize size = self.view.frame.size;
        if (MIN(size.height, size.width) == 320){
            float scaleFactorH = (MIN(self.view.frame.size.width, self.view.frame.size.height)-20) / 320.0;
            return CGSizeMake(320 * scaleFactorH, 351 * scaleFactorH);
        }
        return CGSizeMake(320, 351);
    }
    else{
        CGFloat photosPerRow = sqrt(self.product.quantityToFulfillOrder);

        return CGSizeMake(
                          (collectionView.frame.size.width - margin * (photosPerRow-1.0)) / photosPerRow,
                          (collectionView.frame.size.width - margin * (photosPerRow-1.0)) / photosPerRow
                          );
    }
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section{
    return margin;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section{
    return margin;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section{
    if (collectionView.tag == 20){
        return UIEdgeInsetsZero;
    }
    else{
        return UIEdgeInsetsMake(0, 10, 0, 10);
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

- (void)scrollCropViewControllerDidCancel:(OLScrollCropViewController *)cropper{
    [cropper dismissViewControllerAnimated:YES completion:NULL];
}

-(void)scrollCropViewController:(OLScrollCropViewController *)cropper didFinishCroppingImage:(UIImage *)croppedImage{
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

#ifdef OL_KITE_OFFER_ADOBE
- (void)photoEditor:(AdobeUXImageEditorViewController *)editor finishedWithImage:(UIImage *)image{
    [self.editingPrintPhoto unloadImage];
    
    OLPrintPhoto *printPhoto = self.editingPrintPhoto;
    OLPrintPhoto *copy = [printPhoto copy];
    printPhoto.asset = [OLAsset assetWithImageAsJPEG:image];
    
    [self.collectionView reloadData];
    
    [editor dismissViewControllerAnimated:YES completion:NULL];
    
    [copy getImageWithProgress:NULL completion:^(UIImage *image){
        [editor enqueueHighResolutionRenderWithImage:image completion:^(UIImage *result, NSError *error) {
            NSArray * urls = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
            NSString *documentDirPath = [[(NSURL *)[urls objectAtIndex:0] path] stringByAppendingPathComponent:@"ol-kite-images"];
            
            
            NSFileManager *fileManager= [NSFileManager defaultManager];
            BOOL isDir;
            if(![fileManager fileExistsAtPath:documentDirPath isDirectory:&isDir]){
                [fileManager createDirectoryAtPath:documentDirPath withIntermediateDirectories:YES attributes:nil error:NULL];
            }
            
            NSData * binaryImageData = UIImageJPEGRepresentation(result, 0.7);
            
            NSString *filePath = [documentDirPath stringByAppendingPathComponent:[[[NSUUID UUID] UUIDString] stringByAppendingString:@".jpg"]];
            [binaryImageData writeToFile:filePath atomically:YES];
            
            printPhoto.asset = [OLAsset assetWithFilePath:filePath];
        }];
    }];
    
}

- (void)photoEditorCanceled:(AdobeUXImageEditorViewController *)editor{
    [editor dismissViewControllerAnimated:YES completion:NULL];
}
#endif

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
