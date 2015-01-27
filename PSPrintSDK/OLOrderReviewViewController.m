//
//  OrderReviewViewController.m
//  Kite Print SDK
//
//  Created by Kostas Karayannis on 17/07/2014.
//  Copyright (c) 2014 Ocean Labs. All rights reserved.
//

#import "OLOrderReviewViewController.h"
#import "OLPrintPhoto.h"
#import "OLAsset.h"
#import "OLCheckoutViewController.h"
#import "OLProductPrintJob.h"
#import "OLConstants.h"
#import "OLCheckoutDelegate.h"
#import "UITableViewController+ScreenWidthFactor.h"
#import "OLProductTemplate.h"
#import "OLProduct.h"
#import "OLCircleMaskTableViewCell.h"
#import "OLAsset+Private.h"
#import <SDWebImageManager.h>
#import "OLAnalytics.h"

static const NSUInteger kTagAlertViewSelectMorePhotos = 99;

@interface OLOrderReviewViewController () <OLCheckoutDelegate>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *confirmBarButton;
@property (weak, nonatomic) OLPrintPhoto *editingPrintPhoto;

@end

@implementation OLOrderReviewViewController

-(NSArray *) userSelectedPhotos{
    if (!_userSelectedPhotos){
        NSMutableArray *mutableUserSelectedPhotos = [[NSMutableArray alloc] init];
        for (id asset in self.assets){
            OLPrintPhoto *printPhoto = [[OLPrintPhoto alloc] init];
            printPhoto.serverImageSize = [self.product serverImageSize];
            printPhoto.asset = asset;
            [mutableUserSelectedPhotos addObject:printPhoto];
        }
        _userSelectedPhotos = mutableUserSelectedPhotos;
    }
    return _userSelectedPhotos;
}

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
    
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackReviewScreenViewed:self.product.productTemplate.name];
#endif
    
    self.extraCopiesOfAssets = [[NSMutableArray alloc] initWithCapacity:[self.userSelectedPhotos count]];
    for (int i = 0; i < [self.userSelectedPhotos count]; i++){
        [self.extraCopiesOfAssets addObject:@0];
    }
    [self updateTitleBasedOnSelectedPhotoQuanitity];
    
    self.confirmBarButton.title = NSLocalizedString(@"Confirm", "");
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", @"")
                                                                             style:UIBarButtonItemStyleBordered
                                                                            target:nil
                                                                            action:nil];
}

-(NSUInteger) totalNumberOfExtras{
    NSUInteger res = 0;
    for (NSNumber* num in self.extraCopiesOfAssets){
        res += [num integerValue];
    }
    return res;
}

- (void)updateTitleBasedOnSelectedPhotoQuanitity {
    NSUInteger numOrders = 1 + (MAX(0, self.userSelectedPhotos.count - 1 + [self totalNumberOfExtras]) / self.product.quantityToFulfillOrder);
    NSUInteger quanityToFulfilOrder = numOrders * self.product.quantityToFulfillOrder;
    self.title = [NSString stringWithFormat:@"%lu / %lu", (unsigned long) (self.userSelectedPhotos.count + [self totalNumberOfExtras]), (unsigned long)quanityToFulfilOrder];
}

-(BOOL) shouldGoToCheckout{
    NSUInteger selectedCount = self.userSelectedPhotos.count + [self totalNumberOfExtras];
    NSUInteger numOrders = 1 + (MAX(0, selectedCount - 1) / self.product.quantityToFulfillOrder);
    NSUInteger quantityToFulfilOrder = numOrders * self.product.quantityToFulfillOrder;
    if (selectedCount < quantityToFulfilOrder) {
        NSUInteger canSelectExtraCount = quantityToFulfilOrder - selectedCount;
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"You've selected %d photos.", @""),selectedCount] message:[NSString stringWithFormat:NSLocalizedString(@"You can add %d more for the same price.", @""), canSelectExtraCount] delegate:nil cancelButtonTitle:NSLocalizedString(@"Add more", @"") otherButtonTitles:NSLocalizedString(@"Print these", @""), nil];
        av.tag = kTagAlertViewSelectMorePhotos;
        av.delegate = self;
        [av show];
        return NO;
    }
    return YES;
}

- (void)doCheckout {
    int originalCount = (int)[self.userSelectedPhotos count];
    NSMutableArray* userSelectedPhotosAndExtras = [[NSMutableArray alloc] initWithCapacity:originalCount + [self totalNumberOfExtras]];
    [userSelectedPhotosAndExtras addObjectsFromArray:self.userSelectedPhotos];
    for (int i = 0; i < originalCount; i++) {
        int numberOfCopies = [((NSNumber*)self.extraCopiesOfAssets[i]) intValue];
        for (int j = 0; j < numberOfCopies; j++){
            [userSelectedPhotosAndExtras addObject:self.userSelectedPhotos[i]];
        }
    }
    
    NSUInteger iphonePhotoCount = 0;
    for (OLPrintPhoto *photo in userSelectedPhotosAndExtras) {
        if (photo.type == kPrintPhotoAssetTypeALAsset) ++iphonePhotoCount;
    }
    
    // Avoid uploading assets if possible. We can avoid uploading where the image already exists at a remote
    // URL and the user did not manipulate it in any way.
    NSMutableArray *photoAssets = [[NSMutableArray alloc] init];
    for (OLPrintPhoto *photo in userSelectedPhotosAndExtras) {
        if(photo.type == kPrintPhotoAssetTypeOLAsset){
            [photoAssets addObject:photo.asset];
        } else {
            [photoAssets addObject:[OLAsset assetWithDataSource:photo]];
        }
    }
    
    // ensure order is maxed out by adding duplicates as necessary
    NSUInteger userSelectedAssetCount = photoAssets.count;
    NSUInteger numOrders = (NSUInteger) floor(userSelectedAssetCount + self.product.quantityToFulfillOrder - 1) / self.product.quantityToFulfillOrder;
    NSUInteger duplicatesToFillOrder = numOrders * self.product.quantityToFulfillOrder - userSelectedAssetCount;
    for (NSUInteger i = 0; i < duplicatesToFillOrder; ++i) {
        [photoAssets addObject:photoAssets[i % userSelectedAssetCount]];
    }
    NSLog(@"Adding %lu duplicates", (unsigned long)duplicatesToFillOrder);
        
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString *appVersion = [infoDict objectForKey:@"CFBundleShortVersionString"];
    NSNumber *buildNumber = [infoDict objectForKey:@"CFBundleVersion"];
    
    OLPrintOrder *printOrder = [[OLPrintOrder alloc] init];
    printOrder.userData = @{@"photo_count_iphone": [NSNumber numberWithUnsignedInteger:iphonePhotoCount],
                            @"sdk_version": kOLKiteSDKVersion,
                            @"platform": @"iOS",
                            @"uid": [[[UIDevice currentDevice] identifierForVendor] UUIDString],
                            @"app_version": [NSString stringWithFormat:@"Version: %@ (%@)", appVersion, buildNumber]
                            };
    OLProductPrintJob* printJob = [[OLProductPrintJob alloc] initWithTemplateId:self.product.templateId OLAssets:photoAssets];
    for (id<OLPrintJob> job in printOrder.jobs){
        [printOrder removePrintJob:job];
    }
    [printOrder addPrintJob:printJob];

    
    OLCheckoutViewController *vc = [[OLCheckoutViewController alloc] initWithPrintOrder:printOrder];
    
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onUserSelectedPhotoCountChange {
    [self updateTitleBasedOnSelectedPhotoQuanitity];
}

- (BOOL) shouldShowContinueShoppingButton{
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
    
    NSUInteger extraCopies = [self.extraCopiesOfAssets[indexPath.row - 1] integerValue] + 1;
    self.extraCopiesOfAssets[indexPath.row-1] = [NSNumber numberWithInteger:extraCopies];
    UILabel* countLabel = (UILabel *)[cellContentView viewWithTag:30];
    [countLabel setText: [NSString stringWithFormat:@"%lu", (unsigned long)extraCopies + 1]];
    
    [self updateTitleBasedOnSelectedPhotoQuanitity];
}

- (IBAction)onButtonDownArrowClicked:(UIButton *)sender {
    UIView* cellContentView = sender.superview;
    UIView* cell = cellContentView.superview;
    while (![cell isKindOfClass:[UITableViewCell class]]){
        cell = cell.superview;
    }
    NSIndexPath* indexPath = [self.tableView indexPathForCell:(UITableViewCell*)cell];
    
    NSUInteger extraCopies = [self.extraCopiesOfAssets[indexPath.row - 1] integerValue];
    if (extraCopies == 0){
        return;
    }
    extraCopies--;
    
    self.extraCopiesOfAssets[indexPath.row-1] = [NSNumber numberWithInteger:extraCopies];
    UILabel* countLabel = (UILabel *)[cellContentView viewWithTag:30];
    [countLabel setText: [NSString stringWithFormat:@"%lu", (unsigned long)extraCopies + 1]];
    
    [self updateTitleBasedOnSelectedPhotoQuanitity];
}

- (IBAction)onButtonEnhanceClicked:(UIButton *)sender {
    UIView* cellContentView = sender.superview;
    UIView* cell = cellContentView.superview;
    while (![cell isKindOfClass:[UITableViewCell class]]){
        cell = cell.superview;
    }
    NSIndexPath* indexPath = [self.tableView indexPathForCell:(UITableViewCell*)cell];
    
    self.editingPrintPhoto = self.userSelectedPhotos[indexPath.row - 1];
    self.editingPrintPhoto.asset = self.assets[indexPath.row - 1];
    
    UINavigationController *nav = [self.storyboard instantiateViewControllerWithIdentifier:@"CropViewNavigationController"];
    OLScrollCropViewController *cropVc = (id)nav.topViewController;
    cropVc.enableCircleMask = self.product.templateType == kOLTemplateTypeStickersCircle;
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

- (IBAction)onButtonNextClicked:(UIBarButtonItem *)sender {
    if (![self shouldGoToCheckout]){
        return;
    }
    
    [self doCheckout];
}

- (IBAction)onButtonImageClicked:(UIButton *)sender {
    [self onButtonEnhanceClicked:sender];
}


#pragma mark UITableView data source and delegate methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [self.userSelectedPhotos count] + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row == 0){
        UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"reviewTitle"];
        UILabel* titleLabel = (UILabel *)[cell.contentView viewWithTag:60];
        titleLabel.font = [UIFont fontWithName:@"MissionGothic-Regular" size:19];
        return cell;
    }
    
    OLCircleMaskTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"reviewPhotoCell"];
    if (!cell) {
        cell = [[OLCircleMaskTableViewCell alloc] init];
    }
    
    UIImageView *cellImage = (UIImageView *)[cell.contentView viewWithTag:10];
    
    if (cellImage){
        [((OLPrintPhoto*)[self.userSelectedPhotos objectAtIndex:indexPath.row-1]) setThumbImageIdealSizeForImageView:cellImage];
    }
    
    UILabel *countLabel = (UILabel *)[cell.contentView viewWithTag:30];
    [countLabel setText: [NSString stringWithFormat:@"%lu", (unsigned long)(1+[((NSNumber*)[self.extraCopiesOfAssets objectAtIndex:indexPath.row-1]) integerValue])]];
    countLabel.font = [UIFont fontWithName:@"MissionGothic-Black" size:18];
    
    UIButton* enhanceButton = (UIButton *)[cell.contentView viewWithTag:50];
    if (enhanceButton){
        enhanceButton.titleLabel.font = [UIFont fontWithName:@"MissionGothic-Bold" size:12];
    }
    
    if (self.product.templateType == kOLTemplateTypeStickersCircle){
        UIView *circleMaskView = [cell.contentView viewWithTag:89];
        circleMaskView.hidden = NO;
        
        cell.enableMask = YES;
    }

    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row == 0){
        NSNumber *labelHeight;
        if (!labelHeight) {
            UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"reviewTitle"];
            labelHeight = @(cell.bounds.size.height);
        }
        return [labelHeight floatValue];
    }
    else{
        NSNumber *reviewPhotoCellHeight;
        if (!reviewPhotoCellHeight) {
            UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"reviewPhotoCell"];
            
            if (self.product.templateType == kOLTemplateTypePolaroids || self.product.templateType == kOLTemplateTypeMiniPolaroids){
                NSUInteger extraBottomBezel = 50 / [self screenWidthFactor];
                reviewPhotoCellHeight = @(cell.bounds.size.height + extraBottomBezel);
            }
            else{
                reviewPhotoCellHeight = @(cell.bounds.size.height);
            }
        }
        return [reviewPhotoCellHeight floatValue] * [self screenWidthFactor];
    }
}

#pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == kTagAlertViewSelectMorePhotos) {
        if (buttonIndex == 1) {
            [self doCheckout];
        }
    }
}

#pragma mark - OLImageEditorViewControllerDelegate methods

-(void)userDidCropImage:(UIImage *)croppedImage{
    self.editingPrintPhoto.asset = [OLAsset assetWithImageAsJPEG:croppedImage];
    
    [self.tableView reloadData];
}

@end
