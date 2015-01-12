//
//  FrameOrderReviewViewController.m
//  HuggleUp
//
//  Created by Kostas Karayannis on 23/07/2014.
//  Copyright (c) 2014 Ocean Labs. All rights reserved.
//

#import "OLFrameOrderReviewViewController.h"
#import "OLPrintPhoto.h"
#import "OLProduct.h"

@interface OLFrameOrderReviewViewController ()

@property (weak, nonatomic) IBOutlet UIBarButtonItem *confirmBarButton;
@property (strong, nonatomic) NSMutableArray* framePhotos;

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
        [self.framePhotos addObject:self.framePhotos[i % userSelectedAssetCount]];
    }
    NSLog(@"Adding %lu duplicates to frame", duplicatesToFillOrder);
    [super viewDidLoad];
    self.extraCopiesOfAssets = [[NSMutableArray alloc] initWithCapacity:[self.framePhotos count]];
    for (int i = 0; i < [self.framePhotos count]; i++){
        [self.extraCopiesOfAssets addObject:@0];
    }
}

- (void)onTapGestureThumbnailTapped:(UITapGestureRecognizer*)gestureRecognizer {
    NSIndexPath *tableIndexPath = [self.tableView indexPathForRowAtPoint:[gestureRecognizer locationInView:self.tableView]];
    UITableViewCell* tableCell = [self.tableView cellForRowAtIndexPath:tableIndexPath];
    
    UICollectionView* collectionView = (UICollectionView*)[tableCell.contentView viewWithTag:100];
    
    NSIndexPath* indexPath = [collectionView indexPathForItemAtPoint:[gestureRecognizer locationInView:collectionView]];
    
    OLPrintPhoto *printPhoto = self.framePhotos[(tableIndexPath.row - 1) * self.product.quantityToFulfillOrder + indexPath.row];
    OLImageEditorViewController *imageEditor = [[OLImageEditorViewController alloc] init];
    imageEditor.image = printPhoto;
    imageEditor.delegate = self;
    [self presentViewController:imageEditor animated:YES completion:nil];
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

- (void)imageEditor:(OLImageEditorViewController *)imageEditorVC userDidDeleteImage:(id<OLImageEditorImage>)image{
    [self dismissViewControllerAnimated:YES completion:^(void){
    [self.navigationController popViewControllerAnimated:YES];
//        [self.userSelectedPhotos removeObject:image];
    }];
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
    [countLabel setText: [NSString stringWithFormat:@"%lu", [countLabel.text integerValue] + 1]];
    
    [self updateTitleBasedOnSelectedPhotoQuanitity];
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
    [countLabel setText: [NSString stringWithFormat:@"%lu", [countLabel.text integerValue] - 1]];
    
    [self updateTitleBasedOnSelectedPhotoQuanitity];
}

- (IBAction)onButtonNextClicked:(UIBarButtonItem *)sender {
//    self.userSelectedPhotos = self.framePhotos;
    if (![self shouldGoToCheckout]){
        return;
    }
    
    [self doCheckout];
}


#pragma mark UITableView data source and delegate methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    int incompleteFrame = ([self.framePhotos count] % self.product.quantityToFulfillOrder) != 0 ? 1 : 0;
    return [self.framePhotos count]/self.product.quantityToFulfillOrder + incompleteFrame + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row == 0){
        UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"reviewTitle"];
        UILabel* titleLabel = (UILabel *)[cell.contentView viewWithTag:60];
        titleLabel.font = [UIFont fontWithName:@"MissionGothic-Regular" size:19];
        
        UILabel* instructionsLabel = (UILabel*)[cell.contentView viewWithTag:70];
        instructionsLabel.font = [UIFont fontWithName:@"MissionGothic-Light" size:15];
        return cell;
    }
    
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"reviewPhotoCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] init];
    }
    
    UILabel *countLabel = (UILabel *)[cell.contentView viewWithTag:30];
    [countLabel setText: [NSString stringWithFormat:@"%lu", 1+[((NSNumber*)[self.extraCopiesOfAssets objectAtIndex:indexPath.row-1]) integerValue]]];
    countLabel.font = [UIFont fontWithName:@"MissionGothic-Black" size:18];
    
    UICollectionView* collectionView = (UICollectionView*)[cell.contentView viewWithTag:100];
    collectionView.dataSource = self;
    collectionView.delegate = self;
    
    UITapGestureRecognizer* doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapGestureThumbnailTapped:)];
    [collectionView addGestureRecognizer:doubleTap];
    
    return cell;
}

#pragma mark UICollectionView data source

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.product.quantityToFulfillOrder;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"imageInFrame" forIndexPath:indexPath];
    
    //Workaround for Xcode 6-compiled code running on iOS 7
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
        [((OLPrintPhoto*)[self.framePhotos objectAtIndex:indexPath.row + (tableIndexindexPath.row-1) * self.product.quantityToFulfillOrder]) setThumbImageIdealSizeForImageView:cellImage];
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

@end
