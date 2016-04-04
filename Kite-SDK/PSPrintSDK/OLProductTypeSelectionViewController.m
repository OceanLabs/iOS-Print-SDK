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

#import "OLProductTypeSelectionViewController.h"
#import "OLKitePrintSDK.h"
#import "OLProduct.h"
#import "OLSingleImageProductReviewViewController.h"
#import "UITableViewController+ScreenWidthFactor.h"
#import "OLProductOverviewViewController.h"
#import "OLAnalytics.h"
#import "UIViewController+TraitCollectionCompatibility.h"
#import "UIImageView+FadeIn.h"
#import "OLKiteABTesting.h"
#import "OLKiteUtils.h"
#import "UIViewController+OLMethods.h"
#import "NSObject+Utils.h"

#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)

@interface OLProduct (Private)

-(void)setCoverImageToImageView:(UIImageView *)imageView;
-(void)setProductPhotography:(NSUInteger)i toImageView:(UIImageView *)imageView;

@end

@interface OLKiteViewController (Private)

@property (strong, nonatomic) NSMutableArray *userSelectedPhotos;

@end

@interface OLProductTypeSelectionViewController () <UICollectionViewDelegateFlowLayout, UIViewControllerPreviewingDelegate>

@property (strong, nonatomic) NSMutableArray *products;
@property (strong, nonatomic) NSMutableArray *allPosterProducts;
@property (assign, nonatomic) BOOL fromRotation;

@end

@implementation OLProductTypeSelectionViewController

-(NSMutableArray *) products{
    if (!_products){
        _products = [[NSMutableArray alloc] init];
        self.allPosterProducts = [[NSMutableArray alloc] init];
        NSArray *allProducts = [OLProduct productsWithFilters:self.filterProducts];
        for (OLProduct *product in allProducts){
            if (!product.labelColor || product.productTemplate.templateUI == kOLTemplateUINA){
                continue;
            }
            if (product.productTemplate.templateUI == kOLTemplateUIPoster && !self.subtypeSelection){
                BOOL sameGridTemplate = NO;
                for (OLProduct *otherProduct in _products){
                    if (otherProduct.productTemplate.gridCountX == product.productTemplate.gridCountX && otherProduct.productTemplate.gridCountY == product.productTemplate.gridCountY){
                        sameGridTemplate = YES;
                        break;
                    }
                }
                if (sameGridTemplate){
                    [self.allPosterProducts addObject:product];
                    continue;
                }
            }
            if ([product.productTemplate.templateClass isEqualToString:self.templateClass]){
                [_products addObject:product];
                [self.allPosterProducts addObject:product];
            }
        }
    }
    if (_products.count == 1 && !self.subtypeSelection && [_products.firstObject productTemplate].templateUI == kOLTemplateUIPoster && self.allPosterProducts.count > 1){
        _products = nil;
        self.subtypeSelection = YES;
        return [self products];
    }
    return _products;
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    
    if ([self isPushed]){
        self.automaticallyAdjustsScrollViewInsets = NO;
        self.collectionView.contentInset = UIEdgeInsetsMake([[UIApplication sharedApplication] statusBarFrame].size.height + self.navigationController.navigationBar.frame.size.height, self.collectionView.contentInset.left, self.collectionView.contentInset.bottom, self.collectionView.contentInset.right);
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", @"")
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:nil
                                                                            action:nil];
    }
    
    [self addBasketIconToTopRight];
    
    [self.collectionView.collectionViewLayout invalidateLayout];
}

- (void)viewDidLoad{
    [super viewDidLoad];
    
    if ([self isPushed]){
        self.parentViewController.title = NSLocalizedString(self.templateClass, @"");
    }
    else{
        self.title = NSLocalizedString(self.templateClass, @"");
    }
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", @"")
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:nil
                                                                            action:nil];
    
    if ([UITraitCollection class] && [self.traitCollection respondsToSelector:@selector(forceTouchCapability)] && self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable){
        [self registerForPreviewingWithDelegate:self sourceView:self.collectionView];
    }
    
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackProductTypeSelectionScreenViewedWithTemplateClass:self.templateClass];
#endif
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];

#ifndef OL_NO_ANALYTICS
    if (!self.navigationController){
        [OLAnalytics trackProductTypeSelectionScreenHitBackTemplateClass:self.templateClass];
    }
#endif
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    if ([OLKiteABTesting sharedInstance].allowsMultipleRecipients && self.filterProducts){
        [self addBasketIconToTopRight];
    }
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
        
        if ([self isPushed]){
            self.automaticallyAdjustsScrollViewInsets = NO;
            self.collectionView.contentInset = UIEdgeInsetsMake([[UIApplication sharedApplication] statusBarFrame].size.height + self.navigationController.navigationBar.frame.size.height, self.collectionView.contentInset.left, self.collectionView.contentInset.bottom, self.collectionView.contentInset.right);
        }

    } completion:^(id<UIViewControllerTransitionCoordinator> context){
        [self.collectionView reloadData];
    }];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    UIViewController *vc = [self viewControllerForItemAtIndexPath:indexPath];
    if (vc){
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location{
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:location];
    UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
    [previewingContext setSourceRect:cell.frame];
    return [self viewControllerForItemAtIndexPath:indexPath];
}

- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit{
    [self.navigationController pushViewController:viewControllerToCommit animated:YES];
}

- (UIViewController *)viewControllerForItemAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.item >= self.products.count){
        return nil;
    }
    
    OLProduct *product = self.products[indexPath.row];
    product.uuid = nil;
    [OLKiteUtils kiteVcForViewController:self].userSelectedPhotos = nil;
    self.userSelectedPhotos = [OLKiteUtils kiteVcForViewController:self].userSelectedPhotos;
    
    NSString *identifier;
    NSMutableArray *posters = [[NSMutableArray alloc] init];
    if (product.productTemplate.templateUI == kOLTemplateUIPoster && !self.subtypeSelection){
        for (OLProduct *poster in self.allPosterProducts){
            if (poster.productTemplate.gridCountX == product.productTemplate.gridCountX && poster.productTemplate.gridCountY == product.productTemplate.gridCountY){
                [posters addObject:poster];
            }
        }
        if (posters.count > 1){
            identifier = @"OLTypeSelectionViewController";
        }
    }
    if (!identifier){
        identifier = @"OLProductOverviewViewController";
    }
    OLProductOverviewViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:identifier];
    vc.delegate = self.delegate;
    vc.userSelectedPhotos = self.userSelectedPhotos;
    [vc safePerformSelector:@selector(setProduct:) withObject:product];
    
    if ([vc isKindOfClass:[OLProductTypeSelectionViewController class]]){
        [(OLProductTypeSelectionViewController *)vc setTemplateClass:self.templateClass];
        [(OLProductTypeSelectionViewController *)vc setSubtypeSelection:YES];
        [vc safePerformSelector:@selector(setProducts:) withObject:posters];
    }
    
    return vc;
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
    
    NSString *identifier = [NSString stringWithFormat:@"ProductCell%@", [OLKiteABTesting sharedInstance].productTileStyle];
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    [self fixCellFrameOnIOS7:cell];
    
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
    
    UIActivityIndicatorView *activity = (UIActivityIndicatorView *)[cell.contentView viewWithTag:41];
    [activity startAnimating];
    
    OLProduct *product = (OLProduct *)self.products[indexPath.item];
    
    UIImageView *imageView = (UIImageView *)[cell.contentView viewWithTag:40];
    [product setCoverImageToImageView:imageView];
    
    UILabel *textView = (UILabel *)[cell.contentView viewWithTag:300];
    
    if (product.productTemplate.templateUI == kOLTemplateUIPoster && !self.subtypeSelection){
        if (product.productTemplate.gridCountX == 1 && product.productTemplate.gridCountY == 1){
            textView.text = NSLocalizedString(@"Single Photo Poster", @"");
        }
        else{
            textView.text = [NSString stringWithFormat:@"%ldx%ld Collage", (long)product.productTemplate.gridCountX, (long)product.productTemplate.gridCountY];
        }
    }
    else{
        textView.text = product.productTemplate.templateType;
    }
    
    if ([[OLKiteABTesting sharedInstance].productTileStyle isEqualToString:@"Classic"]){
        textView.backgroundColor = [product labelColor];
    }
    else if([[OLKiteABTesting sharedInstance].productTileStyle isEqualToString:@"Dark"]){
        UIButton *button = (UIButton *)[cell.contentView viewWithTag:390];
        button.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.8];
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
    
    CGFloat height = 233;
    if ([[OLKiteABTesting sharedInstance].productTileStyle isEqualToString:@"Dark"]){
        height = 200;
    }
    
    if ([self isHorizontalSizeClassCompact] && size.height > size.width) {
        if (numberOfCells == 2){
            return CGSizeMake(size.width, halfScreenHeight);
        }
        else{
            return CGSizeMake(size.width, height * (size.width / 320.0));
        }
    }
    else if (numberOfCells == 6){
        return CGSizeMake(size.width/2 - 1, MAX(halfScreenHeight * (2.0 / 3.0), height));
    }
    else if (numberOfCells == 4){
        return CGSizeMake(size.width/2 - 1, MAX(halfScreenHeight, height));
    }
    else if (numberOfCells == 3){
        if (size.width < size.height){
            return CGSizeMake(size.width, halfScreenHeight * 0.8);
        }
        else{
            return CGSizeMake(size.width/2 - 1, MAX(halfScreenHeight, height));
        }
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
        return CGSizeMake(size.width/2 - 1, height);
    }
}

#pragma mark - Tear down and restore

//- (void)tearDownLargeObjectsFromMemory{
//    [super tearDownLargeObjectsFromMemory];
//    [self.collectionView reloadData];
//}
//
//- (void)recreateTornDownLargeObjectsToMemory{
//    [super recreateTornDownLargeObjectsToMemory];
//    [self.collectionView reloadData];
//}

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
