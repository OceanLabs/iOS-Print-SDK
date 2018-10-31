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

#import "NSObject+Utils.h"
#import "OLAnalytics.h"
#import "OLImageDownloader.h"
#import "OLKiteABTesting.h"
#import "OLKitePrintSDK.h"
#import "OLKiteUtils.h"
#import "OLProduct.h"
#import "OLProductOverviewViewController.h"
#import "OLProductTypeSelectionViewController.h"
#import "OLSingleProductReviewViewController.h"
#import "OLUserSession.h"
#import "UIImage+OLUtils.h"
#import "UIImageView+FadeIn.h"
#import "UIViewController+OLMethods.h"
#import "OLKiteViewController+Private.h"
#import "UIView+RoundRect.h"
#import "UIImage+ImageNamedInKiteBundle.h"
#import "UIView+AutoLayoutHelper.h"
#import "OLKiteViewController+Private.h"

@interface OLProductTypeSelectionViewController () <UICollectionViewDelegateFlowLayout>

@property (strong, nonatomic) NSMutableArray *products;
@property (strong, nonatomic) NSMutableArray *allPosterProducts;
@property (strong, nonatomic) NSMutableDictionary *collections;
@property (assign, nonatomic) BOOL fromRotation;
@property (strong, nonatomic) UIView *bannerView;

@end

@implementation OLProductTypeSelectionViewController

-(NSMutableArray *) products{
    if (!_products){
        _products = [[NSMutableArray alloc] init];
        self.allPosterProducts = [[NSMutableArray alloc] init];
        self.collections = [[NSMutableDictionary alloc] init];
        NSArray *allProducts = [OLProduct productsWithFilters:self.filterProducts];
        for (OLProduct *product in allProducts){
            if (!product.labelColor || product.productTemplate.templateUI == OLTemplateUINA){
                continue;
            }
            if (product.productTemplate.templateUI == OLTemplateUIPoster && !self.subtypeSelection){
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
                if (!product.productTemplate.collectionId || !product.productTemplate.collectionName || ![self.collections.allKeys containsObject:[product.productTemplate.collectionId stringByAppendingString:product.productTemplate.collectionName]]){
                    [_products addObject:product];
                    [self.allPosterProducts addObject:product];
                }
                if (product.productTemplate.collectionId && product.productTemplate.collectionName){
                    if (!self.collections[[product.productTemplate.collectionId stringByAppendingString:product.productTemplate.collectionName]]){
                        self.collections[[product.productTemplate.collectionId stringByAppendingString:product.productTemplate.collectionName]] = [[NSMutableArray alloc] init];
                    }
                    [self.collections[[product.productTemplate.collectionId stringByAppendingString:product.productTemplate.collectionName]] addObject:product.productTemplate.identifier];
                }
            }
        }
    }
    if (_products.count == 1 && !self.subtypeSelection && [_products.firstObject productTemplate].templateUI == OLTemplateUIPoster && self.allPosterProducts.count > 1){
        _products = nil;
        self.subtypeSelection = YES;
        return [self products];
    }
    return _products;
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    if (self.bannerView){
        [UIView animateWithDuration:0.25 animations:^{
            self.bannerView.transform = CGAffineTransformMakeTranslation(0, 0);
            [self.collectionView setContentInset:UIEdgeInsetsMake(self.collectionView.contentInset.top, 0, 0, 0)];
        }completion:^(BOOL finished){
            self.bannerView.hidden = YES;
            self.bannerView.transform = CGAffineTransformIdentity;
        }];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.bannerView){
        self.bannerView.hidden = NO;
        [UIView animateWithDuration:0.25 animations:^{
            self.bannerView.transform = CGAffineTransformMakeTranslation(0, -70);
            [self.collectionView setContentInset:UIEdgeInsetsMake(self.collectionView.contentInset.top, 0, 40, 0)];
        }completion:NULL];
    }
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    
    if ([self isPushed]){
        self.automaticallyAdjustsScrollViewInsets = NO;
        self.collectionView.contentInset = UIEdgeInsetsMake([[UIApplication sharedApplication] statusBarFrame].size.height + self.navigationController.navigationBar.frame.size.height, self.collectionView.contentInset.left, self.collectionView.contentInset.bottom, self.collectionView.contentInset.right);
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[OLKiteABTesting sharedInstance].backButtonText
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:nil
                                                                            action:nil];
    }
    
    [self addBasketIconToTopRight];
    [(PhotobookNavigationBar *)self.navigationController.navigationBar setBarType:PhotobookNavigationBarTypeWhite];
    
    [self.collectionView.collectionViewLayout invalidateLayout];
}

- (void)viewDidLoad{
    [super viewDidLoad];
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
    
    if ([self isPushed]){
        self.parentViewController.title = self.templateClass;
    }
    else{
        self.title = self.templateClass;
    }
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[OLKiteABTesting sharedInstance].backButtonText
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:nil
                                                                            action:nil];
    
    if ([OLKitePrintSDK isKiosk]){
        for (OLProduct *product in self.products){
            if (product.productTemplate.printInStore){
                [self setupBannerView];
                break;
            }
        }
    }
    
    [OLAnalytics trackProductListScreenViewedWithTemplateClass:self.templateClass];
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

        [self addBasketIconToTopRight];
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

- (UIViewController *)viewControllerForItemAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.item >= self.products.count){
        return nil;
    }
    
    OLProduct *product = self.products[indexPath.row];
    product.uuid = nil;
    
    UIViewController *vc;
    NSMutableArray *posters = [[NSMutableArray alloc] init];
    if (product.productTemplate.templateUI == OLTemplateUIPoster && !self.subtypeSelection){
        for (OLProduct *poster in self.allPosterProducts){
            if (poster.productTemplate.gridCountX == product.productTemplate.gridCountX && poster.productTemplate.gridCountY == product.productTemplate.gridCountY){
                [posters addObject:poster];
            }
        }
        if (posters.count > 1){
            vc = [self.storyboard instantiateViewControllerWithIdentifier:@"OLTypeSelectionViewController"];
        }
    }
    else if ([OLKiteABTesting sharedInstance].skipProductOverview && product.productTemplate.templateUI != OLTemplateUINonCustomizable){
        vc = [[OLUserSession currentSession].kiteVc reviewViewControllerForProduct:product photoSelectionScreen:[OLKiteUtils imageProvidersAvailable]];
    }
    
    if (!vc){
        vc = [[OLUserSession currentSession].kiteVc productDescriptionViewController];
    }
    ((OLProductOverviewViewController *)vc).delegate = self.delegate;
    
    if (product.productTemplate.collectionName && product.productTemplate.collectionId){
        NSMutableArray *options = [[NSMutableArray alloc] init];
        for (NSString *templateId in self.collections[[product.productTemplate.collectionId stringByAppendingString:product.productTemplate.collectionName]]){
            OLProductTemplate *template = [OLProductTemplate templateWithId:templateId];
            if (!template){
                continue;
            }
            OLProduct *otherProduct = [[OLProduct alloc] initWithTemplate:template];
            [options addObject:@{
                                 @"code" : otherProduct.productTemplate.identifier,
                                 @"name" : [NSString stringWithFormat:@"%@\n%@", [otherProduct dimensions], [otherProduct unitCost]],
                                 }];
        }
        
        OLProductTemplateOption *collectionOption =
        [[OLProductTemplateOption alloc] initWithDictionary:@{
                                                              @"code" : product.productTemplate.collectionId,
                                                              @"name" : product.productTemplate.collectionName,
                                                              @"options" : options
                                                              }];
        collectionOption.iconImageName = @"tool-size";
        for (OLProductTemplateOption *option in product.productTemplate.options){
            if ([option.code isEqualToString:collectionOption.code]){
                [(NSMutableArray *)product.productTemplate.options removeObjectIdenticalTo:option];
            }
        }
        [(NSMutableArray *)product.productTemplate.options addObject:collectionOption];
    }
    
    [vc safePerformSelector:@selector(setProduct:) withObject:product];
    
    if ([vc isKindOfClass:[OLProductTypeSelectionViewController class]]){
        [(OLProductTypeSelectionViewController *)vc setTemplateClass:self.templateClass];
        [(OLProductTypeSelectionViewController *)vc setSubtypeSelection:YES];
        [vc safePerformSelector:@selector(setProducts:) withObject:posters];
    }
    
    return vc;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.item >= self.products.count){
        UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"extraCell" forIndexPath:indexPath];
        UILabel *label = [cell.contentView viewWithTag:50];
        label.text = NSLocalizedStringFromTableInBundle(@"MORE ITEMS\nCOMING SOON!", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"");
        return cell;
    }
    
    NSString *identifier = [NSString stringWithFormat:@"ProductCell%@", [OLKiteABTesting sharedInstance].productTileStyle];
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    
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
    imageView.image = nil;
    [imageView setAndFadeInImageWithOLAsset:[product coverPhotoAsset] size:[self collectionView:collectionView layout:collectionView.collectionViewLayout sizeForItemAtIndexPath:indexPath] applyEdits:NO placeholder:nil progress:NULL completionHandler:NULL];
    
    UILabel *textView = (UILabel *)[cell.contentView viewWithTag:300];
    UIFont *font = [[OLKiteABTesting sharedInstance] lightThemeFont1WithSize:17];
    if (font){
        textView.font = font;
    }
    
    BOOL inSizeCollectionFlag = NO;
    for (NSString *s in self.collections){
        if ([s isEqualToString:[product.productTemplate.collectionId stringByAppendingString:product.productTemplate.collectionName]]){
            inSizeCollectionFlag = YES;
        }
    }
    
    if (product.productTemplate.templateUI == OLTemplateUIPoster && !self.subtypeSelection){
        if (product.productTemplate.gridCountX == 1 && product.productTemplate.gridCountY == 1){
            textView.text = NSLocalizedStringFromTableInBundle(@"Single Photo Poster", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"");
        }
        else{
            textView.text = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%ldx%ld Collage", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"example: 5x7 Collage"), (long)product.productTemplate.gridCountX, (long)product.productTemplate.gridCountY];
        }
    }
    else if (inSizeCollectionFlag){
        textView.text = [[[[product.productTemplate.templateType stringByReplacingOccurrencesOfString:NSLocalizedStringFromTableInBundle(@"Small", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") withString:@"Small product size"] stringByReplacingOccurrencesOfString:NSLocalizedStringFromTableInBundle(@"Medium", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") withString:@"Medium Product size"] stringByReplacingOccurrencesOfString:NSLocalizedStringFromTableInBundle(@"Large", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") withString:@"Large Product Size"] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]];
    }
    else{
        textView.text = product.productTemplate.templateType;
    }
    
    if ([[OLKiteABTesting sharedInstance].productTileStyle isEqualToString:@"Classic"]){
        textView.backgroundColor = [product labelColor];
    }
    else if([[OLKiteABTesting sharedInstance].productTileStyle isEqualToString:@"MinimalWhite"]){
        UILabel *priceLabel = [cell.contentView viewWithTag:301];
        UILabel *detailsLabel = [cell.contentView viewWithTag:302];
        
        priceLabel.text = [product unitCost];
        detailsLabel.text = [product.productTemplate shortDescription];
        
        UIFont *font = [[OLKiteABTesting sharedInstance] lightThemeFont1WithSize:17];
        if (font){
            priceLabel.font = font;
            detailsLabel.font = [[OLKiteABTesting sharedInstance] lightThemeFont1WithSize:15];
        }
    }
    else if([[OLKiteABTesting sharedInstance].productTileStyle isEqualToString:@"ThemeColor"]){
        if ([OLKiteABTesting sharedInstance].lightThemeColor1){
            UILabel *detailsLabel = [cell.contentView viewWithTag:302];
            detailsLabel.backgroundColor = [OLKiteABTesting sharedInstance].lightThemeColor1;
        }
    }
    else{
        UIButton *button = (UIButton *)[cell.contentView viewWithTag:390];
        button.layer.shadowColor = [[UIColor blackColor] CGColor];
        button.layer.shadowOpacity = .3;
        button.layer.shadowOffset = CGSizeMake(0,2);
        button.layer.shadowRadius = 2;
        
        button.backgroundColor = [product labelColor];
        [button addTarget:self action:@selector(onButtonCallToActionTapped:) forControlEvents:UIControlEventTouchUpInside];
        
        UIFont *font = [[OLKiteABTesting sharedInstance] lightThemeFont1WithSize:17];
        if (font){
            [button.titleLabel setFont:font];
        }
    }
    
    UIImageView *printInStoreIndicator = [cell.contentView viewWithTag:777];
    if ([OLKitePrintSDK isKiosk] && product.productTemplate.printInStore){
        if (!printInStoreIndicator){
            printInStoreIndicator = [[UIImageView alloc] initWithImage:[UIImage imageNamedInKiteBundle:@"availableintstore"]];
            printInStoreIndicator.frame = CGRectMake(0, 0, 40, 40);
            printInStoreIndicator.contentMode = UIViewContentModeCenter;
            printInStoreIndicator.tag = 777;
            printInStoreIndicator.backgroundColor = [product labelColor];
            [cell.contentView addSubview:printInStoreIndicator];
            
            [printInStoreIndicator trailingToSuperview:20 relation:NSLayoutRelationEqual];
            [printInStoreIndicator topFromSuperview:20 relation:NSLayoutRelationEqual];
            [printInStoreIndicator widthConstraint:40];
            [printInStoreIndicator heightConstraint:40];
        }
        
        CGRect frame = printInStoreIndicator.frame;
        [printInStoreIndicator makeRoundRectWithRadius:frame.size.height/2.0];
        printInStoreIndicator.hidden = NO;
    }
    else{
        [cell.contentView viewWithTag:777].hidden = YES;
    }
    
    return cell;
}

- (void)setupBannerView{
    self.bannerView = [[UIView alloc] init];
    UIView *bannerView = self.bannerView;
    bannerView.backgroundColor = [UIColor colorWithRed:0.310 green:0.698 blue:0.886 alpha:1.000];
    
    bannerView.layer.shadowColor = [[UIColor blackColor] CGColor];
    bannerView.layer.shadowOpacity = .3;
    bannerView.layer.shadowOffset = CGSizeMake(0,-2);
    bannerView.layer.shadowRadius = 2;
    
    UILabel *label = [[UILabel alloc] init];
    [bannerView addSubview:label];
    
    [self.navigationController.view addSubview:bannerView];
    
    bannerView.translatesAutoresizingMaskIntoConstraints = NO;
    NSDictionary *views = NSDictionaryOfVariableBindings(bannerView);
    NSMutableArray *con = [[NSMutableArray alloc] init];
    
    NSArray *visuals = @[@"H:|-0-[bannerView]-0-|",
                         @"V:[bannerView(40)]"];
    
    
    for (NSString *visual in visuals) {
        [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
    }
    
    [bannerView.superview addConstraints:con];
    
    [self.navigationController.view addConstraint:[NSLayoutConstraint constraintWithItem:bannerView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.navigationController.view attribute:NSLayoutAttributeBottom multiplier:1 constant:70]];
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamedInKiteBundle:@"availableintstore"]];
    imageView.contentMode = UIViewContentModeCenter;
    [imageView makeRoundRectWithRadius:2];
    imageView.backgroundColor = [UIColor colorWithRed:0.310 green:0.698 blue:0.886 alpha:1.000];
    
    [bannerView addSubview:imageView];
    [bannerView addConstraint:[NSLayoutConstraint constraintWithItem:bannerView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:label attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
    [bannerView addConstraint:[NSLayoutConstraint constraintWithItem:bannerView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:imageView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
    
    [bannerView addConstraint:[NSLayoutConstraint constraintWithItem:bannerView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationLessThanOrEqual toItem:imageView attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0]];
    [bannerView addConstraint:[NSLayoutConstraint constraintWithItem:bannerView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:label attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0]];
    
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    label.translatesAutoresizingMaskIntoConstraints = NO;
    views = NSDictionaryOfVariableBindings(label, imageView);
    con = [[NSMutableArray alloc] init];
    
    visuals = @[@"H:[imageView(30)]-0-[label]",
                @"V:|-0-[label]-0-|", @"V:[imageView(30)]"];
    
    
    for (NSString *visual in visuals) {
        [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
    }
    
    [label.superview addConstraints:con];
    
    label.tag = 10;
    label.minimumScaleFactor = 0.5;
    label.adjustsFontSizeToFitWidth = YES;
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 3;
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont systemFontOfSize:15.5];
    label.text = NSLocalizedString(@"*Printed in store in less than 20 minutes!", @"");
    label.minimumScaleFactor = 0.5;
    if ([label respondsToSelector:@selector(setAllowsDefaultTighteningForTruncation:)]){
        label.allowsDefaultTighteningForTruncation = YES;
    }
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
    if (!(numberOfProducts % 2 == 0) && (self.traitCollection.horizontalSizeClass != UIUserInterfaceSizeClassCompact || size.height < size.width)){
        extras = 1;
    }
    if (numberOfProducts == 2 && self.traitCollection.horizontalSizeClass != UIUserInterfaceSizeClassCompact){
        extras = 1;
    }
    
    return numberOfProducts + extras;
}

- (CGSize) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    CGSize size = self.view.bounds.size;
    
    if (@available(iOS 11.0, *)) {
        size = CGSizeMake(size.width, size.height - self.view.safeAreaInsets.bottom);
    }
    
    NSInteger numberOfCells = [self collectionView:collectionView numberOfItemsInSection:indexPath.section];
    CGFloat halfScreenHeight = (size.height - [[UIApplication sharedApplication] statusBarFrame].size.height - self.navigationController.navigationBar.frame.size.height)/2;
    
    CGFloat height = 233;
    
    if([[OLKiteABTesting sharedInstance].productTileStyle isEqualToString:@"ThemeColor"]){
        height = 200;
    }
    
    if (indexPath.item >= self.products.count && self.products.count % 2 == 0){
        return CGSizeMake(size.width, halfScreenHeight);
    }
    
    if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact && size.height > size.width) {
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
            return CGSizeMake(size.width/2 - 1, halfScreenHeight);
        }
    }
    else{
        return CGSizeMake(size.width/2 - 1, height);
    }
}

@end
