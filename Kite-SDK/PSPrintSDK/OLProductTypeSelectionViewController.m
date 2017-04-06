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
#import "OLSingleImageProductReviewViewController.h"
#import "OLUserSession.h"
#import "UIImage+OLUtils.h"
#import "UIImageView+FadeIn.h"
#import "UIViewController+OLMethods.h"
#import "OLKiteViewController+Private.h"

@interface OLProductTypeSelectionViewController () <UICollectionViewDelegateFlowLayout, UIViewControllerPreviewingDelegate>

@property (strong, nonatomic) NSMutableArray *products;
@property (strong, nonatomic) NSMutableArray *allPosterProducts;
@property (strong, nonatomic) NSMutableDictionary *collections;
@property (assign, nonatomic) BOOL fromRotation;

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
    
    [self.collectionView.collectionViewLayout invalidateLayout];
}

- (void)viewDidLoad{
    [super viewDidLoad];
    
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
    
    if ([self.traitCollection respondsToSelector:@selector(forceTouchCapability)] && self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable){
        [self registerForPreviewingWithDelegate:self sourceView:self.collectionView];
    }
    
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackProductListScreenViewedWithTemplateClass:self.templateClass];
#endif
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];

#ifndef OL_NO_ANALYTICS
    if (!self.navigationController){
        [OLAnalytics trackProductListScreenHitBackTemplateClass:self.templateClass];
    }
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
    else if ([OLKiteABTesting sharedInstance].skipProductOverview && ![OLKiteABTesting sharedInstance].launchedWithPrintOrder && product.productTemplate.templateUI != OLTemplateUINonCustomizable){
        vc = [[OLUserSession currentSession].kiteVc reviewViewControllerForProduct:product photoSelectionScreen:[OLKiteUtils imageProvidersAvailable:self]];
    }
    
    if (!vc){
        vc = [self.storyboard instantiateViewControllerWithIdentifier:@"OLProductOverviewViewController"];
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
        UIImageView *cellImageView = (UIImageView *)[cell.contentView viewWithTag:40];
        UILabel *label = [cell.contentView viewWithTag:50];
        label.text = NSLocalizedStringFromTableInBundle(@"MORE ITEMS\nCOMING SOON!", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"");
        [[OLImageDownloader sharedInstance] downloadImageAtURL:[NSURL URLWithString:@"https://s3.amazonaws.com/sdk-static/product_photography/placeholder-loc.png"] withCompletionHandler:^(UIImage *image, NSError *error){
            dispatch_async(dispatch_get_main_queue(), ^{
                cellImageView.image = image;
                cell.backgroundColor = [image colorAtPixel:CGPointMake(3, 3)];
            });
        }];
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
