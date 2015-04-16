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
@property (nonatomic, strong) UIView *huggleBotSpeechBubble;
@property (nonatomic, weak) IBOutlet UILabel *huggleBotFriendNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *letsStartLabel;
@property (nonatomic, assign) BOOL startHuggleBotOnViewWillAppear;
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
    //self.splitViewController.preferredDisplayMode = UISplitViewControllerDisplayModePrimaryHidden;
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

-(void)viewDidAppear:(BOOL)animated{
    if (self.navigationController){
        NSMutableArray *navigationStack = self.navigationController.viewControllers.mutableCopy;
        if (navigationStack.count > 1 && [navigationStack[navigationStack.count - 2] isKindOfClass:[OLKiteViewController class]]) {
            OLKiteViewController *kiteVc = navigationStack[navigationStack.count - 2];
            if (!kiteVc.presentingViewController){
                [navigationStack removeObject:kiteVc];
                self.navigationController.viewControllers = navigationStack;
            }
        }
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [self.collectionView.collectionViewLayout invalidateLayout];
}

#pragma mark - UICollectionViewDelegate Methods

- (CGSize) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    CGSize size = self.view.bounds.size;
    NSInteger numberOfCells = [self collectionView:collectionView numberOfItemsInSection:indexPath.section];
    CGFloat halfScreenHeight = (size.height - [[UIApplication sharedApplication] statusBarFrame].size.height - self.navigationController.navigationBar.frame.size.height)/2;
    
    if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact && size.height > size.width) {
        if (numberOfCells == 2){
            return CGSizeMake(size.width, halfScreenHeight);
        }
        else{
            return CGSizeMake(size.width, 233 * (size.width / 320.0));
        }
    }
    else if (numberOfCells == 4){
        return CGSizeMake(size.width/2 - 0.5, MAX(halfScreenHeight, 233));
    }
    else if (numberOfCells == 2){
        if (size.width < size.height){
            return CGSizeMake(size.width, halfScreenHeight);
        }
        else{
            return CGSizeMake(size.width/2 - 0.5, halfScreenHeight * 2);
        }
    }
    else{
        return CGSizeMake(size.width/2 - 0.5, 233);
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
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
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return [self.productGroups count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *identifier = @"ProductCell";
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    
    UIImageView *cellImageView = (UIImageView *)[cell.contentView viewWithTag:40];

    OLProductGroup *group = self.productGroups[indexPath.row];
    OLProduct *product = [group.products firstObject];
    [product setClassImageToImageView:cellImageView];

    UILabel *productTypeLabel = (UILabel *)[cell.contentView viewWithTag:300];

    productTypeLabel.text = product.productTemplate.templateClass;

    productTypeLabel.backgroundColor = [product labelColor];

    UIActivityIndicatorView *activityIndicator = (id)[cell.contentView viewWithTag:41];
    [activityIndicator startAnimating];
    
    return cell;
}

#pragma mark - Autorotate and Orientation Methods

//- (BOOL)shouldAutorotate {
//    return NO;
//}
//
//- (NSUInteger)supportedInterfaceOrientations {
//    return UIInterfaceOrientationMaskPortrait;
//}

@end
