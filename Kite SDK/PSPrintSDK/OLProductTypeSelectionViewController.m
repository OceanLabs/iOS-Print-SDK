//
//  OLCaseSelectionViewController.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 2/24/15.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import "OLProductTypeSelectionViewController.h"
#import "OLKitePrintSDK.h"
#import "OLProduct.h"
#import "OLSingleImageProductReviewViewController.h"
#import "UITableViewController+ScreenWidthFactor.h"
#import "OLProductOverviewViewController.h"
#import "OLAnalytics.h"
#import "UIViewController+TraitCollectionCompatibility.h"
#import "UIImageView+FadeIn.h"

#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)

@interface OLProduct (Private)

-(void)setCoverImageToImageView:(UIImageView *)imageView;
-(void)setProductPhotography:(NSUInteger)i toImageView:(UIImageView *)imageView;

@end

@interface OLProductTypeSelectionViewController () <UICollectionViewDelegateFlowLayout>

@property (strong, nonatomic) NSMutableArray *products;
@property (assign, nonatomic) BOOL fromRotation;

@end

@implementation OLProductTypeSelectionViewController

-(NSMutableArray *) products{
    if (!_products){
        _products = [[NSMutableArray alloc] init];
        NSArray *allProducts = [OLProduct productsWithFilters:self.filterProducts];
        for (OLProduct *product in allProducts){
            if (!product.labelColor || product.productTemplate.templateUI == kOLTemplateUINA){
                continue;
            }
            if ([product.productTemplate.templateClass isEqualToString:self.templateClass]){
                [_products addObject:product];
            }
        }
    }
    return _products;
}

- (void)viewDidLoad{
    if ([[self.products firstObject] productTemplate].templateUI == kOLTemplateUICase){
        self.title = NSLocalizedString(@"Choose Device", @"");
    }
    else{
        self.title = NSLocalizedString(@"Choose Size", @"");
    }
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", @"")
                                                                             style:UIBarButtonItemStyleBordered
                                                                            target:nil
                                                                            action:nil];
    
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackProductTypeSelectionScreenViewedWithTemplateClass:self.templateClass];
#endif
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    self.fromRotation = YES;
    
    NSArray *visibleCells = [self.collectionView indexPathsForVisibleItems];
    NSIndexPath *maxIndexPath = [visibleCells firstObject];
    for (NSIndexPath *indexPath in visibleCells){
        if (maxIndexPath.item < indexPath.item){
            maxIndexPath = indexPath;
        }
    }
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinator> context){
        [self.collectionView.collectionViewLayout invalidateLayout];
    } completion:^(id<UIViewControllerTransitionCoordinator> context){
        [self.collectionView reloadData];
    }];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.item >= self.products.count){
        return;
    }
    
    OLProduct *product = self.products[indexPath.row];
    
    OLProductOverviewViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"OLProductOverviewViewController"];
    vc.delegate = self.delegate;
    vc.assets = self.assets;
    vc.userSelectedPhotos = self.userSelectedPhotos;
    vc.product = product;
    
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)fixCellFrameOnIOS7:(UICollectionViewCell *)cell {
    // Ugly hack to fix cell frame on iOS 7 iPad. For whatever reason the frame size is not as per collectionView:layout:sizeForItemAtIndexPath:, others also experiencing this issue http://stackoverflow.com/questions/25804588/auto-layout-in-uicollectionviewcell-not-working
    if (SYSTEM_VERSION_LESS_THAN(@"8")) {
        [[cell contentView] setFrame:[cell bounds]];
        [[cell contentView] setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.item >= self.products.count){
        UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"extraCell" forIndexPath:indexPath];
        [self fixCellFrameOnIOS7:cell];
        UIImageView *cellImageView = (UIImageView *)[cell.contentView viewWithTag:40];
        [cellImageView setAndFadeInImageWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/sdk-static/product_photography/placeholder.png"]];
        if (self.fromRotation){
            self.fromRotation = NO;
            cell.alpha = 0;
            [UIView animateWithDuration:0.3 animations:^{
                cell.alpha = 1;
            }];
        }
        return cell;
    }
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"caseCell" forIndexPath:indexPath];
    [self fixCellFrameOnIOS7:cell];
    
    UIActivityIndicatorView *activity = (UIActivityIndicatorView *)[cell.contentView viewWithTag:41];
    [activity startAnimating];
    
    OLProduct *product = (OLProduct *)self.products[indexPath.item];
    
    UIImageView *imageView = (UIImageView *)[cell.contentView viewWithTag:10];
    [product setCoverImageToImageView:imageView];
    
    UITextView *textView = (UITextView *)[cell.contentView viewWithTag:20];
    textView.text = product.productTemplate.templateType;
    textView.backgroundColor = product.productTemplate.labelColor;
    
    return cell;
}

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    NSInteger extras = 0;
    NSInteger numberOfProducts = [self.products count];
    
    CGSize size = self.view.frame.size;
    if (!(numberOfProducts % 2 == 0) && (!([self isHorizontalSizeClassCompact]) || size.height < size.width)){
        extras = 1;
    }
    
    return numberOfProducts + extras;
}

- (CGSize) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    CGSize size = self.view.bounds.size;
    NSInteger numberOfCells = [self collectionView:collectionView numberOfItemsInSection:indexPath.section];
    CGFloat halfScreenHeight = (size.height - [[UIApplication sharedApplication] statusBarFrame].size.height - self.navigationController.navigationBar.frame.size.height)/2;
    
    if ([self isHorizontalSizeClassCompact] && size.height > size.width) {
        if (numberOfCells == 2){
            return CGSizeMake(size.width, halfScreenHeight);
        }
        else{
            return CGSizeMake(size.width, 233 * (size.width / 320.0));
        }
    }
    else if (numberOfCells == 6){
        return CGSizeMake(size.width/2 - 1, MAX(halfScreenHeight * (2.0 / 3.0), 233));
    }
    else if (numberOfCells == 4){
        return CGSizeMake(size.width/2 - 1, MAX(halfScreenHeight, 233));
    }
    else if (numberOfCells == 2){
        if (size.width < size.height){
            return CGSizeMake(size.width, halfScreenHeight);
        }
        else{
            return CGSizeMake(size.width/2 - 1, halfScreenHeight * 2);
        }
    }
    else{
        return CGSizeMake(size.width/2 - 1, 233);
    }
}

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

- (NSUInteger)supportedInterfaceOrientations {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8) {
        return UIInterfaceOrientationMaskAll;
    }
    else{
        return UIInterfaceOrientationMaskPortrait;
    }
}

@end
