//
//  FrameOrderReviewViewController.m
//  Kite Print SDK
//
//  Created by Kostas Karayannis on 23/07/2014.
//  Copyright (c) 2014 Ocean Labs. All rights reserved.
//

#import "OLFrameOrderReviewViewController.h"
#import "OLPrintPhoto.h"
#import "OLProduct.h"
#import "OLAsset+Private.h"
#import <SDWebImageManager.h>
#import "UITableViewController+ScreenWidthFactor.h"

@interface OLFrameOrderReviewViewController () <OLScrollCropViewControllerDelegate>

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
    NSLog(@"Adding %lu duplicates to frame", (unsigned long)duplicatesToFillOrder);
    [super viewDidLoad];
    self.extraCopiesOfAssets = [[NSMutableArray alloc] initWithCapacity:[self.framePhotos count]];
    for (int i = 0; i < [self.framePhotos count]; i++){
        [self.extraCopiesOfAssets addObject:@0];
    }
    
    self.title = NSLocalizedString(@"Review", @"");
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Confirm", @"") style:UIBarButtonItemStylePlain target:self action:@selector(onButtonNextClicked:)];
}

- (void)onTapGestureThumbnailTapped:(UITapGestureRecognizer*)gestureRecognizer {
    NSIndexPath *tableIndexPath = [self.collectionView indexPathForItemAtPoint:[gestureRecognizer locationInView:self.collectionView]];
    UICollectionViewCell *tableCell = [self.collectionView cellForItemAtIndexPath:tableIndexPath];
    
    UICollectionView* collectionView = (UICollectionView*)[tableCell.contentView viewWithTag:20];
    
    NSIndexPath* indexPath = [collectionView indexPathForItemAtPoint:[gestureRecognizer locationInView:collectionView]];
    
    self.editingPrintPhoto = self.framePhotos[(tableIndexPath.item) * self.product.quantityToFulfillOrder + indexPath.row];
    self.editingPrintPhoto.asset = self.assets[((tableIndexPath.item) * self.product.quantityToFulfillOrder + indexPath.row) % [self.assets count]];
    
    UINavigationController *nav = [self.storyboard instantiateViewControllerWithIdentifier:@"CropViewNavigationController"];
    OLScrollCropViewController *cropVc = (id)nav.topViewController;
    cropVc.delegate = self;
    cropVc.aspectRatio = 1;
    
    [self.editingPrintPhoto getImageWithProgress:NULL completion:^(UIImage *image){
        [cropVc setFullImage:image];
        [self presentViewController:nav animated:YES completion:NULL];
    }];
}

-(void)changeOrderOfPhotosInArray:(NSMutableArray*)array{
    NSUInteger photosPerRow = sqrt(self.product.quantityToFulfillOrder);
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

-(void) doCheckout{
    [self changeOrderOfPhotosInArray:self.framePhotos];
    [self changeOrderOfPhotosInArray:self.extraCopiesOfAssets];
    
    [super doCheckout];
}

- (BOOL)shouldShowAddMorePhotos{
    return NO;
}

#pragma mark Button Actions

//- (IBAction)onButtonUpArrowClicked:(UIButton *)sender {
//    UIView* cellContentView = sender.superview;
//    UIView* cell = cellContentView.superview;
//    while (![cell isKindOfClass:[UITableViewCell class]]){
//        cell = cell.superview;
//    }
//    NSIndexPath* indexPath = [self.tableView indexPathForCell:(UITableViewCell*)cell];
//    
//    for (int i = 0; i < self.product.quantityToFulfillOrder; i++){
//        NSUInteger extraCopies = [self.extraCopiesOfAssets[(indexPath.item) * self.product.quantityToFulfillOrder + i] integerValue] + 1;
//        self.extraCopiesOfAssets[(indexPath.item) * self.product.quantityToFulfillOrder + i] = [NSNumber numberWithInteger:extraCopies];
//    }
//    UILabel* countLabel = (UILabel *)[cellContentView viewWithTag:30];
//    [countLabel setText: [NSString stringWithFormat:@"%lu", (unsigned long)[countLabel.text integerValue] + 1]];
//    
////    [self updateTitleBasedOnSelectedPhotoQuanitity];
//}

//- (IBAction)onButtonDownArrowClicked:(UIButton *)sender {
//    UIView* cellContentView = sender.superview;
//    UIView* cell = cellContentView.superview;
//    while (![cell isKindOfClass:[UITableViewCell class]]){
//        cell = cell.superview;
//    }
//    NSIndexPath* indexPath = [self.tableView indexPathForCell:(UITableViewCell*)cell];
//    
//    for (int i = 0; i < self.product.quantityToFulfillOrder; i++){
//        NSUInteger extraCopies = [self.extraCopiesOfAssets[(indexPath.item) * self.product.quantityToFulfillOrder + i] integerValue];
//        if (extraCopies == 0){
//            return;
//        }
//        extraCopies--;
//        
//        self.extraCopiesOfAssets[(indexPath.item) * self.product.quantityToFulfillOrder + i] = [NSNumber numberWithInteger:extraCopies];
//    }
//    UILabel* countLabel = (UILabel *)[cellContentView viewWithTag:30];
//    [countLabel setText: [NSString stringWithFormat:@"%lu", (unsigned long)[countLabel.text integerValue] - 1]];
//    
////    [self updateTitleBasedOnSelectedPhotoQuanitity];
//}

- (IBAction)onButtonNextClicked:(UIBarButtonItem *)sender {
    self.userSelectedPhotos = self.framePhotos;
    if (![self shouldGoToCheckout]){
        return;
    }
    
    [self doCheckout];
}


#pragma mark UICollectionView data source and delegate methods

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
        
        UILabel *countLabel = (UILabel *)[cell.contentView viewWithTag:30];
        [countLabel setText: [NSString stringWithFormat:@"%lu", (unsigned long) (1+[((NSNumber*)[self.extraCopiesOfAssets objectAtIndex:indexPath.item]) integerValue])]];
        
        UICollectionView* innerCollectionView = (UICollectionView*)[cell.contentView viewWithTag:20];
        
        innerCollectionView.dataSource = self;
        innerCollectionView.delegate = self;
        
        UITapGestureRecognizer* doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapGestureThumbnailTapped:)];
        [collectionView addGestureRecognizer:doubleTap];
        
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
        
        NSIndexPath* tableIndexindexPath = [self.collectionView indexPathForCell:(UICollectionViewCell *)view];
        
        UIImageView* cellImage = (UIImageView*)[cell.contentView viewWithTag:110];
        
        cellImage.image = nil;
        
        [((OLPrintPhoto*)[self.framePhotos objectAtIndex:indexPath.row + (tableIndexindexPath.item) * self.product.quantityToFulfillOrder]) setImageIdealSizeForImageView:cellImage highQuality:YES];
        
        
        return cell;
    }
}

- (CGSize) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    if (collectionView.tag == 10){
        return CGSizeMake(320, 351);
    }
    else{
        CGFloat photosPerRow = sqrt(self.product.quantityToFulfillOrder);

        return CGSizeMake(
                          (collectionView.frame.size.width / photosPerRow - margin/2 * (photosPerRow-1))-11/MAX(1,(photosPerRow-1)),
                          (collectionView.frame.size.height / photosPerRow - margin/2 * (photosPerRow-1))
                          );
    }
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section{
    return 0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section{
    return margin;
}

- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath willMoveToIndexPath:(NSIndexPath *)toIndexPath {
    UIView* tableViewCell = collectionView.superview;
    while (![tableViewCell isKindOfClass:[UICollectionViewCell class]]){
        tableViewCell = tableViewCell.superview;
    }
    NSIndexPath* tableIndexPath = [self.collectionView indexPathForCell:(UICollectionViewCell *)tableViewCell];
    
    NSInteger trueFromIndex = fromIndexPath.item + (tableIndexPath.item) * self.product.quantityToFulfillOrder;
    NSInteger trueToIndex = toIndexPath.item + (tableIndexPath.item) * self.product.quantityToFulfillOrder;
    
    id object = [self.framePhotos objectAtIndex:trueFromIndex];
    [self.framePhotos removeObjectAtIndex:trueFromIndex];
    [self.framePhotos insertObject:object atIndex:trueToIndex];
    object = [self.extraCopiesOfAssets objectAtIndex:trueFromIndex];
    [self.extraCopiesOfAssets removeObjectAtIndex:trueFromIndex];
    [self.extraCopiesOfAssets insertObject:object atIndex:trueToIndex];
    object = [self.assets objectAtIndex:trueFromIndex];
    [self.assets removeObjectAtIndex:trueFromIndex];
    [self.assets insertObject:object atIndex:trueToIndex];
}

- (void) collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionView *innerCollectionView = (id)[cell.contentView viewWithTag:20];
    [innerCollectionView.collectionViewLayout invalidateLayout];
    [innerCollectionView reloadData];
}

-(void)userDidCropImage:(UIImage *)croppedImage{
    [self.editingPrintPhoto unloadImage];
    self.editingPrintPhoto.asset = [OLAsset assetWithImageAsJPEG:croppedImage];
    
    [self.collectionView reloadData];
}

@end
