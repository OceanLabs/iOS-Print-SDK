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
#import "OLUserSession.h"
#import "OLAsset+Private.h"
#import "UIImageView+FadeIn.h"
#import "OLImagePickerViewController.h"
#import "OLKiteViewController+Private.h"

CGFloat posterMargin = 2;

@interface OLPrintOrder (Private)

- (void)saveOrder;

@end

@interface OLPosterViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UICollectionViewDelegate, LXReorderableCollectionViewDataSource, OLImageEditViewControllerDelegate>

@property (assign, nonatomic) CGFloat numberOfRows;
@property (assign, nonatomic) CGFloat numberOfColumns;
@property (weak, nonatomic) OLAsset *editingAsset;
@property (assign, nonatomic) CGSize rotationSize;

@end

@interface OLFrameOrderReviewViewController () <UICollectionViewDelegateFlowLayout>

- (BOOL) shouldGoToCheckout;
- (void) doCheckout;
- (void)replacePhoto:(id)sender;
- (void)onTapGestureThumbnailTapped:(UITapGestureRecognizer*)gestureRecognizer;

@end

@implementation OLPosterViewController

-(void)viewDidLoad{
    [super viewDidLoad];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[OLKiteABTesting sharedInstance].backButtonText
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:nil
                                                                            action:nil];
    [self setTitle:NSLocalizedStringFromTableInBundle(@"Edit Poster", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"")];
    
    self.numberOfColumns = self.product.productTemplate.gridCountX;
    self.numberOfRows = self.product.productTemplate.gridCountY;
    
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
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

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    if (collectionView.tag == 10){
        NSUInteger numOrders = 1 + (MAX(0, [OLAsset userSelectedAssets].count - 1) / self.product.quantityToFulfillOrder);
        return numOrders;
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
    
    __weak OLRemoteImageView *imageView = (OLRemoteImageView *)[cell viewWithTag:110];
    imageView.image = nil;
    imageView.userInteractionEnabled = YES;
    [imageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapGestureThumbnailTapped:)]];
    
    OLAsset *asset = [[OLAsset userSelectedAssets] objectAtIndex:indexPath.row + (outerCollectionViewIndexPath.item) * self.product.quantityToFulfillOrder];
    
    [imageView setAndFadeInImageWithOLAsset:asset size:[self collectionView:collectionView layout:collectionView.collectionViewLayout sizeForItemAtIndexPath:indexPath] applyEdits:YES placeholder:nil progress:^(float progress){
                [imageView setProgress:progress];
    } completionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [activity stopAnimating];
        });
    }];
    
    return cell;
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
    NSMutableArray *reversePhotos = [[OLAsset userSelectedAssets].nonPlaceholderAssets mutableCopy];
    [OLPosterViewController changeOrderOfPhotosInArray:reversePhotos forProduct:self.product];
    self.checkoutPhotos = reversePhotos;
}

@end
