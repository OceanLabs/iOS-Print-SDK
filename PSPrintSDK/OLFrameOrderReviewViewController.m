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
#import "OLImageView.h"
#import "OLKiteUtils.h"
#import "OLKiteViewController.h"
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
- (NSUInteger) totalNumberOfExtras;
- (UIViewController *)viewControllerForPresenting;
- (UIView *)viewToAddDraggingAsset;
@property (strong, nonatomic) UIButton *ctaButton;
@property (strong, nonatomic) OLInfoBanner *infoBanner;
@end

@interface OLFrameOrderReviewViewController () <OLArtboardDelegate>
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
    
    NSUInteger numOrders = 1 + (MAX(0, [OLAsset userSelectedAssets].count - 1) / self.product.quantityToFulfillOrder);
    [[OLAsset userSelectedAssets] adjustNumberOfSelectedAssetsWithTotalNumberOfAssets:self.product.quantityToFulfillOrder * numOrders trim:self.product.productTemplate.templateUI == OLTemplateUICalendar];
    
    self.title = NSLocalizedStringFromTableInBundle(@"Review", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Title of a screen where the user can review the product before ordering");
}

+ (void)reverseRowsOfPhotosInArray:(NSMutableArray*)array forProduct:(OLProduct *)product{
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
        [OLUserSession currentSession].userSelectedAssets = [[OLAsset userSelectedAssets].nonPlaceholderAssets mutableCopy];
    }
    else{
        [OLUserSession currentSession].userSelectedAssets = [[OLAsset userSelectedAssets].nonPlaceholderAssets mutableCopy];
        [OLFrameOrderReviewViewController reverseRowsOfPhotosInArray:[OLUserSession currentSession].userSelectedAssets forProduct:self.product];
    }
}

-(NSUInteger) totalNumberOfExtras{
    return 0;
}

-(BOOL) shouldGoToCheckout{
    NSInteger nullCount = 0;
    for (OLAsset *asset in [OLAsset userSelectedAssets]){
        if ([asset isKindOfClass:[OLPlaceholderAsset class]]){
            nullCount++;
        }
    }
    
    if (nullCount > 0){
        NSInteger selected = [OLAsset userSelectedAssets].nonPlaceholderAssets.count;
        NSString *title = selected == 1 ? [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"You've only selected %d photo.", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @""), selected] : [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"You've only selected %d photos.", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @""), selected];
        UIAlertController *ac = [UIAlertController alertControllerWithTitle:title message:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Please add %d more.", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Please add [a number] more [photos]"), nullCount] preferredStyle:UIAlertControllerStyleAlert];
        [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"OK", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Acknowledgent to an alert dialog.") style:UIAlertActionStyleCancel handler:NULL]];
        [self presentViewController:ac animated:YES completion:NULL];
        return NO;
    }
    
    return [super shouldGoToCheckout];
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
        return [OLAsset userSelectedAssets].count / self.product.quantityToFulfillOrder;
    }
    else{
        NSInteger numberOfPhotosPerFrame = self.product.productTemplate.gridCountX * self.product.productTemplate.gridCountY;
        return self.product.quantityToFulfillOrder / numberOfPhotosPerFrame;
        
    }
}

- (NSInteger)numberOfPhotosPerFrame{
    NSUInteger gridX = self.product.productTemplate.gridCountX;
    NSUInteger gridY = self.product.productTemplate.gridCountY;
    if (gridX == 0 || gridY == 0){
        gridX = sqrt(self.product.quantityToFulfillOrder);
        gridY = gridX;
    }
    
    return gridX * gridY;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return [self numberOfFrames];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    NSString *cellId = self.product.productTemplate.templateUI == OLTemplateUIFrame ? @"reviewCell" : @"calendarCell";
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellId forIndexPath:indexPath];
    
    CGFloat artboardHorizontalMargin = 20;
    CGFloat artboardTopMargin = 20;
    if (self.product.productTemplate.templateUI == OLTemplateUIFrame){
        artboardHorizontalMargin = 25;
        artboardTopMargin = 53;
    }
    
    CGSize size = [self collectionView:collectionView layout:collectionView.collectionViewLayout sizeForItemAtIndexPath:indexPath];
    float scaleFactor = size.width / 320.0;
    
    OLArtboardView *artboard = (OLArtboardView *)[cell.contentView viewWithTag:20];
    artboard.delegate = self;
    CGFloat side = size.width - artboardHorizontalMargin * scaleFactor - artboardHorizontalMargin * scaleFactor;
    [self configureAssetViewsForArtboard:artboard forSize:CGSizeMake(side, side)];
    
    for (NSUInteger i = 0; i < artboard.assetViews.count; i++){
        artboard.assetViews[i].index = i + (indexPath.item * [self numberOfPhotosPerFrame]);
    }
    
    [artboard loadImageOnAllAssetViews];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(artboard);
    NSMutableArray *con = [[NSMutableArray alloc] init];
    
    NSArray *visuals = @[[NSString stringWithFormat:@"H:|-%f-[artboard]-%f-|", artboardHorizontalMargin * scaleFactor, artboardHorizontalMargin * scaleFactor], [NSString stringWithFormat:@"V:|-%f-[artboard]", artboardTopMargin * scaleFactor]];
    
    
    for (NSString *visual in visuals) {
        [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
    }
    
    [artboard.superview addConstraints:con];
    
    if (self.product.productTemplate.templateUI != OLTemplateUIFrame){
        cell.contentView.backgroundColor = [UIColor whiteColor];
        
        UIImageView *imageView = [cell.contentView viewWithTag:1010];
        if (indexPath.item < self.product.productTemplate.representationAssets.count){
            [imageView setAndFadeInImageWithURL:self.product.productTemplate.representationAssets[indexPath.item] size:CGSizeMake(side, side)];
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

- (void)configureAssetViewsForArtboard:(OLArtboardView *)artboard forSize:(CGSize)size{
    NSUInteger gridX = self.product.productTemplate.gridCountX;
    NSUInteger gridY = self.product.productTemplate.gridCountY;
    if (gridX == 0 || gridY == 0){
        gridX = sqrt(self.product.quantityToFulfillOrder);
        gridY = gridX;
    }
    
    CGFloat relativeMargin = innerMargin / size.width;
    
    CGSize assetViewRelativeSize = CGSizeMake((1 - relativeMargin * (gridX-1.0)) / gridX, (1 - relativeMargin * (gridY-1.0)) / gridY);
    
    while(artboard.assetViews.count < gridX * gridY){
        [artboard addAssetView];
    }
    
    for (NSUInteger i = 0; i < artboard.assetViews.count; i++){
        NSUInteger x = i % gridX;
        NSUInteger y = i / gridX;
        artboard.assetViews[i].relativeFrame = CGRectMake((assetViewRelativeSize.width + relativeMargin) * x, (assetViewRelativeSize.height + relativeMargin) * y, assetViewRelativeSize.width, assetViewRelativeSize.height);
    }
}

- (void)addInfoBanner{
    if ([OLUserSession currentSession].kiteVc.disableEditingTools){
        self.infoBanner = [OLInfoBanner showInfoBannerOnViewController:self withTitle:NSLocalizedStringFromTableInBundle(@"Tap image to change or hold to move", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"")];
    }
    else{
        self.infoBanner = [OLInfoBanner showInfoBannerOnViewController:self withTitle:NSLocalizedStringFromTableInBundle(@"Tap image to edit or hold to move", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"")];
    }
    self.infoBanner.delegate = self;
    self.collectionView.contentInset = UIEdgeInsetsMake(self.collectionView.contentInset.top + 50, self.collectionView.contentInset.left, self.collectionView.contentInset.bottom, self.collectionView.contentInset.right);
}

- (CGSize) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    CGSize size = self.view.frame.size;
    CGFloat height = self.product.productTemplate.templateUI == OLTemplateUIFrame ? 351 : 435;
    if (MIN(size.height, size.width) == 320){
        float scaleFactorH = (MIN(self.view.frame.size.width, self.view.frame.size.height)-20) / 320.0;
        return CGSizeMake(320 * scaleFactorH, height * scaleFactorH);
    }
    return CGSizeMake(320, height);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section{
    return margin;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section{
    return margin;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section{
    CGSize cellSize = [self collectionView:collectionView layout:collectionView.collectionViewLayout sizeForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:section]];
    
    NSInteger numberOfCellsPerRow = collectionView.frame.size.width / cellSize.width;
    CGFloat sideMargin = (collectionView.frame.size.width - (cellSize.width * numberOfCellsPerRow) - margin * (numberOfCellsPerRow - 1))/(numberOfCellsPerRow+1);
    return UIEdgeInsetsMake(margin, sideMargin, margin, sideMargin);
}

#pragma mark OLArtboardDelegate

- (OLArtboardAssetView *)assetViewAtPoint:(CGPoint)point{
    for (UICollectionViewCell *cell in self.collectionView.visibleCells){
        OLArtboardView *artboard = [cell viewWithTag:20];
        if ([artboard isKindOfClass:[OLArtboardView class]]){
            OLArtboardAssetView *found = [artboard findAssetViewAtPoint:point];
            if (found){
                return found;
            }
        }
    }
    
    return nil;
}

@end
