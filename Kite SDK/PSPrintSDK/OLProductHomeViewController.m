//
//  ProductHomeViewController.m
//  Kite Print SDK
//
//  Created by Elliott Minns on 12/12/2013.
//  Copyright (c) 2013 Ocean Labs. All rights reserved.
//

#import "OLProductHomeViewController.h"
#import "OLProductOverviewViewController.h"
#import "OLProductTypeSelectionViewController.h"
#import "OLProductTemplate.h"
#import "OLProduct.h"
#import "OLKiteViewController.h"
#import "OLKitePrintSDK.h"
#import "OLPosterSizeSelectionViewController.h"
#import "OLAnalytics.h"
#import "OLProductGroup.h"
#import "NSObject+Utils.h"
#import "OLCustomNavigationController.h"
#import "UIViewController+TraitCollectionCompatibility.h"
#import "UIImageView+FadeIn.h"
#import "OLKiteABTesting.h"
#import "UIImage+ColorAtPixel.h"
#import "OLInfoPageViewController.h"

#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)

@interface OLProduct (Private)

-(void)setCoverImageToImageView:(UIImageView *)imageView;
-(void)setClassImageToImageView:(UIImageView *)imageView;
-(void)setProductPhotography:(NSUInteger)i toImageView:(UIImageView *)imageView;

@end

@interface OLKiteViewController (Private)

+ (NSString *)storyboardIdentifierForGroupSelected:(OLProductGroup *)group;

@end

@interface OLProductHomeViewController () <UICollectionViewDelegateFlowLayout>
@property (nonatomic, strong) NSArray *productGroups;
@property (nonatomic, strong) UIImageView *topSurpriseImageView;
@property (assign, nonatomic) BOOL fromRotation;
@end

@implementation OLProductHomeViewController

- (NSArray *)productGroups {
    if (!_productGroups){
        _productGroups = [OLProductGroup groupsWithFilters:self.filterProducts];
    }
    
    return _productGroups;
}

- (void)viewDidLoad {
    [super viewDidLoad];

#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackProductSelectionScreenViewed];
#endif

    self.title = NSLocalizedString(@"Print Shop", @"");
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", @"")
                                                                             style:UIBarButtonItemStyleBordered
                                                                            target:nil
                                                                            action:nil];
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.collectionView.contentInset = UIEdgeInsetsMake([[UIApplication sharedApplication] statusBarFrame].size.height + self.navigationController.navigationBar.frame.size.height, 0, 0, 0);
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
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
        self.collectionView.contentInset = UIEdgeInsetsMake([[UIApplication sharedApplication] statusBarFrame].size.height + self.navigationController.navigationBar.frame.size.height, 0, 0, 0);
    }completion:^(id<UIViewControllerTransitionCoordinator> context){
        [self.collectionView reloadData];
    }];
}

#pragma mark - UICollectionViewDelegate Methods

- (CGSize) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    CGSize size = self.view.bounds.size;
    if (indexPath.section == 0 && ![[OLKiteABTesting sharedInstance].qualityBannerType isEqualToString:@"None"]){
        CGFloat height = 110;
        if ([self isHorizontalSizeClassCompact] && size.height > size.width){
            height = (self.view.frame.size.width * height) / 375.0;
        }
        return CGSizeMake(self.view.frame.size.width, height);
    }
    
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

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 0 && ![[OLKiteABTesting sharedInstance].qualityBannerType isEqualToString:@"None"]){
        OLInfoPageViewController *vc = (OLInfoPageViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"InfoPageViewController"];
        vc.imageName = @"quality";
        [self.navigationController pushViewController:vc animated:YES];
        return;
    }
    if (indexPath.item >= self.productGroups.count){
        return;
    }
    
    OLProductGroup *group = self.productGroups[indexPath.row];
    OLProduct *product = [group.products firstObject];
    NSString *identifier = [OLKiteViewController storyboardIdentifierForGroupSelected:group];
    
    id vc = [self.storyboard instantiateViewControllerWithIdentifier:identifier];
    [vc safePerformSelector:@selector(setAssets:) withObject:self.assets];
    [vc safePerformSelector:@selector(setUserSelectedPhotos:) withObject:self.userSelectedPhotos];
    [vc safePerformSelector:@selector(setDelegate:) withObject:self.delegate];
    [vc safePerformSelector:@selector(setFilterProducts:) withObject:self.filterProducts];
    [vc safePerformSelector:@selector(setTemplateClass:) withObject:product.productTemplate.templateClass];
    [vc safePerformSelector:@selector(setProduct:) withObject:product];
    
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - UICollectionViewDataSource Methods

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return [[OLKiteABTesting sharedInstance].qualityBannerType isEqualToString:@"None"] ? 1 : 2;
}

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    if (section == 0 && ![[OLKiteABTesting sharedInstance].qualityBannerType isEqualToString:@"None"]){
        return 1;
    }
    NSInteger extras = 0;
    NSInteger numberOfProducts = [self.productGroups count];
    
    CGSize size = self.view.frame.size;
    if (!(numberOfProducts % 2 == 0) && (!([self isHorizontalSizeClassCompact]) || size.height < size.width)){
        extras = 1;
    }
    
    return numberOfProducts + extras;
}

- (void)fixCellFrameOnIOS7:(UICollectionViewCell *)cell {
    // Ugly hack to fix cell frame on iOS 7 iPad. For whatever reason the frame size is not as per collectionView:layout:sizeForItemAtIndexPath:, others also experiencing this issue http://stackoverflow.com/questions/25804588/auto-layout-in-uicollectionviewcell-not-working
    if (SYSTEM_VERSION_LESS_THAN(@"8")) {
        [[cell contentView] setFrame:[cell bounds]];
        [[cell contentView] setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 0 && ![[OLKiteABTesting sharedInstance].qualityBannerType isEqualToString:@"None"] ){
        UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"qualityBanner" forIndexPath:indexPath];
        UIImageView *imageView = (UIImageView *)[cell viewWithTag:10];
        imageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"quality-banner%@", [OLKiteABTesting sharedInstance].qualityBannerType]];
        imageView.backgroundColor = [imageView.image colorAtPixel:CGPointMake(3, 3)];
        return cell;
    }
    
    if (indexPath.item >= self.productGroups.count){
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
    
    NSString *identifier = [NSString stringWithFormat:@"ProductCell%@", [OLKiteABTesting sharedInstance].productTileStyle];
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    [self fixCellFrameOnIOS7:cell];
    
    UIImageView *cellImageView = (UIImageView *)[cell.contentView viewWithTag:40];
    
    OLProductGroup *group = self.productGroups[indexPath.item];
    OLProduct *product = [group.products firstObject];
    [product setClassImageToImageView:cellImageView];
    
    UILabel *productTypeLabel = (UILabel *)[cell.contentView viewWithTag:300];
    
    productTypeLabel.text = product.productTemplate.templateClass;
    
    UIActivityIndicatorView *activityIndicator = (id)[cell.contentView viewWithTag:41];
    [activityIndicator startAnimating];
    
    if ([[OLKiteABTesting sharedInstance].productTileStyle isEqualToString:@"Classic"]){
        productTypeLabel.backgroundColor = [product labelColor];
    }
    else{
        UIButton *button = (UIButton *)[cell.contentView viewWithTag:390];
        button.layer.shadowColor = [[UIColor blackColor] CGColor];
        button.layer.shadowOpacity = .3;
        button.layer.shadowOffset = CGSizeMake(0,2);
        button.layer.shadowRadius = 2;
        
        button.backgroundColor = [product labelColor];
        
        [button addTarget:self action:@selector(onButtonCallToActionTapped:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return cell;
}

- (void)onButtonCallToActionTapped:(UIButton *)sender{
    UIView *view = sender.superview;
    while (![view isKindOfClass:[UICollectionViewCell class]]){
        view = view.superview;
    }
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:(UICollectionViewCell *)view];
    [self collectionView:self.collectionView didSelectItemAtIndexPath:indexPath];
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
