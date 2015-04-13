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

@property (weak, nonatomic) IBOutlet UIBarButtonItem *confirmBarButton;
@property (strong, nonatomic) NSMutableArray* framePhotos;
@property (weak, nonatomic) OLPrintPhoto *editingPrintPhoto;

@end

@implementation OLFrameOrderReviewViewController

NSInteger margin = 2;

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
}

- (void)onTapGestureThumbnailTapped:(UITapGestureRecognizer*)gestureRecognizer {
    NSIndexPath *tableIndexPath = [self.tableView indexPathForRowAtPoint:[gestureRecognizer locationInView:self.tableView]];
    UITableViewCell* tableCell = [self.tableView cellForRowAtIndexPath:tableIndexPath];
    
    UICollectionView* collectionView = (UICollectionView*)[tableCell.contentView viewWithTag:100];
    
    NSIndexPath* indexPath = [collectionView indexPathForItemAtPoint:[gestureRecognizer locationInView:collectionView]];
    
    self.editingPrintPhoto = self.framePhotos[(tableIndexPath.row - 1) * self.product.quantityToFulfillOrder + indexPath.row];
    self.editingPrintPhoto.asset = self.assets[((tableIndexPath.row - 1) * self.product.quantityToFulfillOrder + indexPath.row) % [self.assets count]];
    
    UINavigationController *nav = [self.storyboard instantiateViewControllerWithIdentifier:@"CropViewNavigationController"];
    OLScrollCropViewController *cropVc = (id)nav.topViewController;
    cropVc.delegate = self;
    cropVc.aspectRatio = 1;
    if (((OLAsset *)(self.editingPrintPhoto.asset)).assetType == kOLAssetTypeRemoteImageURL){
        [[SDWebImageManager sharedManager] downloadImageWithURL:[((OLAsset *)(self.editingPrintPhoto.asset)) imageURL] options:0 progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *url) {
            if (finished) {
                [cropVc setFullImage:image];
                [self presentViewController:nav animated:YES completion:NULL];
            }
        }];
    }
    else{
        [[self.userSelectedPhotos objectAtIndex:0] dataWithCompletionHandler:^(NSData *data, NSError *error){
            [cropVc setFullImage:[UIImage imageWithData:data]];
            [self presentViewController:nav animated:YES completion:NULL];
        }];
    }
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

- (IBAction)onButtonUpArrowClicked:(UIButton *)sender {
    UIView* cellContentView = sender.superview;
    UIView* cell = cellContentView.superview;
    while (![cell isKindOfClass:[UITableViewCell class]]){
        cell = cell.superview;
    }
    NSIndexPath* indexPath = [self.tableView indexPathForCell:(UITableViewCell*)cell];
    
    for (int i = 0; i < self.product.quantityToFulfillOrder; i++){
        NSUInteger extraCopies = [self.extraCopiesOfAssets[(indexPath.row - 1) * self.product.quantityToFulfillOrder + i] integerValue] + 1;
        self.extraCopiesOfAssets[(indexPath.row - 1) * self.product.quantityToFulfillOrder + i] = [NSNumber numberWithInteger:extraCopies];
    }
    UILabel* countLabel = (UILabel *)[cellContentView viewWithTag:30];
    [countLabel setText: [NSString stringWithFormat:@"%lu", (unsigned long)[countLabel.text integerValue] + 1]];
    
//    [self updateTitleBasedOnSelectedPhotoQuanitity];
}

- (IBAction)onButtonDownArrowClicked:(UIButton *)sender {
    UIView* cellContentView = sender.superview;
    UIView* cell = cellContentView.superview;
    while (![cell isKindOfClass:[UITableViewCell class]]){
        cell = cell.superview;
    }
    NSIndexPath* indexPath = [self.tableView indexPathForCell:(UITableViewCell*)cell];
    
    for (int i = 0; i < self.product.quantityToFulfillOrder; i++){
        NSUInteger extraCopies = [self.extraCopiesOfAssets[(indexPath.row - 1) * self.product.quantityToFulfillOrder + i] integerValue];
        if (extraCopies == 0){
            return;
        }
        extraCopies--;
        
        self.extraCopiesOfAssets[(indexPath.row - 1) * self.product.quantityToFulfillOrder + i] = [NSNumber numberWithInteger:extraCopies];
    }
    UILabel* countLabel = (UILabel *)[cellContentView viewWithTag:30];
    [countLabel setText: [NSString stringWithFormat:@"%lu", (unsigned long)[countLabel.text integerValue] - 1]];
    
//    [self updateTitleBasedOnSelectedPhotoQuanitity];
}

- (IBAction)onButtonNextClicked:(UIBarButtonItem *)sender {
    self.userSelectedPhotos = self.framePhotos;
    if (![self shouldGoToCheckout]){
        return;
    }
    
    [self doCheckout];
}


#pragma mark UITableView data source and delegate methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (section == 0){
        int incompleteFrame = ([self.framePhotos count] % self.product.quantityToFulfillOrder) != 0 ? 1 : 0;
        return [self.framePhotos count]/self.product.quantityToFulfillOrder + incompleteFrame + 1;
    }
    else{
        return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 0){
        if (indexPath.row == 0){
            UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"reviewTitle"];
            
            return cell;
        }
        
        UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"reviewPhotoCell"];
        if (!cell) {
            cell = [[UITableViewCell alloc] init];
        }
        
        UILabel *countLabel = (UILabel *)[cell.contentView viewWithTag:30];
        [countLabel setText: [NSString stringWithFormat:@"%lu", (unsigned long) (1+[((NSNumber*)[self.extraCopiesOfAssets objectAtIndex:indexPath.row-1]) integerValue])]];
        
        UICollectionView* collectionView = (UICollectionView*)[cell.contentView viewWithTag:100];
        collectionView.dataSource = self;
        collectionView.delegate = self;
        
        UITapGestureRecognizer* doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapGestureThumbnailTapped:)];
        [collectionView addGestureRecognizer:doubleTap];
        
        return cell;
    }
    else{
        return [tableView dequeueReusableCellWithIdentifier:@"dummyCell"];
    }
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row > 0){
        return 400 * self.view.bounds.size.width / 320;
    }
    else{
        NSNumber *labelHeight;
        if (!labelHeight) {
            UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"reviewTitle"];
            labelHeight = @(cell.bounds.size.height);
        }
        return [labelHeight floatValue];
    }
}

#pragma mark UICollectionView data source

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.product.quantityToFulfillOrder;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"imageInFrame" forIndexPath:indexPath];
    
    //Workaround for iOS 7
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8){
        cell.contentView.frame = cell.bounds;
        cell.contentView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin |UIViewAutoresizingFlexibleTopMargin |UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    }

    UIView* tableViewCell = collectionView.superview;
    while (![tableViewCell isKindOfClass:[UITableViewCell class]]){
        tableViewCell = tableViewCell.superview;
    }

    NSIndexPath* tableIndexindexPath = [self.tableView indexPathForRowAtPoint:tableViewCell.frame.origin];//[self.tableView indexPathForCell:(UITableViewCell*)tableViewCell];
    
    UIImageView* cellImage = (UIImageView*)[cell.contentView viewWithTag:110];
    
    if (cellImage && !cellImage.image && tableIndexindexPath){
        [((OLPrintPhoto*)[self.framePhotos objectAtIndex:indexPath.row + (tableIndexindexPath.row-1) * self.product.quantityToFulfillOrder]) setImageIdealSizeForImageView:cellImage highQuality:YES];
    }
    
    
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    int photosPerRow = sqrt(self.product.quantityToFulfillOrder);
    
    return CGSizeMake(collectionView.frame.size.width / photosPerRow - margin/2 * (photosPerRow-1), collectionView.frame.size.height / photosPerRow - margin/2 * (photosPerRow-1));
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section{
    return margin;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section{
    return margin;
}

- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath willMoveToIndexPath:(NSIndexPath *)toIndexPath {
    UIView* tableViewCell = collectionView.superview;
    while (![tableViewCell isKindOfClass:[UITableViewCell class]]){
        tableViewCell = tableViewCell.superview;
    }
    NSIndexPath* tableIndexPath = [self.tableView indexPathForCell:(UITableViewCell*)tableViewCell];
    
    NSInteger trueFromIndex = fromIndexPath.item + (tableIndexPath.row-1) * self.product.quantityToFulfillOrder;
    NSInteger trueToIndex = toIndexPath.item + (tableIndexPath.row-1) * self.product.quantityToFulfillOrder;
    
    id object = [self.framePhotos objectAtIndex:trueFromIndex];
    [self.framePhotos removeObjectAtIndex:trueFromIndex];
    [self.framePhotos insertObject:object atIndex:trueToIndex];
    object = [self.extraCopiesOfAssets objectAtIndex:trueFromIndex];
    [self.extraCopiesOfAssets removeObjectAtIndex:trueFromIndex];
    [self.extraCopiesOfAssets insertObject:object atIndex:trueToIndex];
}

-(void)userDidCropImage:(UIImage *)croppedImage{
    self.editingPrintPhoto.asset = [OLAsset assetWithImageAsJPEG:croppedImage];
    
    [self.tableView reloadData];
}

#pragma mark - Autorotate and Orientation Methods

- (BOOL)shouldAutorotate {
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

@end
