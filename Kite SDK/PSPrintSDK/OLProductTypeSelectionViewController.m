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

@interface OLProduct (Private)

-(void)setCoverImageToImageView:(UIImageView *)imageView;
-(void)setProductPhotography:(NSUInteger)i toImageView:(UIImageView *)imageView;

@end

@interface OLProductTypeSelectionViewController () <UICollectionViewDelegateFlowLayout>

@property (strong, nonatomic) NSMutableArray *products;

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
    [self.collectionView.collectionViewLayout invalidateLayout];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    OLProduct *product = self.products[indexPath.row];
    
    OLProductOverviewViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"OLProductOverviewViewController"];
    vc.delegate = self.delegate;
    vc.assets = self.assets;
    vc.userSelectedPhotos = self.userSelectedPhotos;
    vc.product = product;
    
    [self.navigationController pushViewController:vc animated:YES];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"caseCell" forIndexPath:indexPath];
    
    UIActivityIndicatorView *activity = (UIActivityIndicatorView *)[cell.contentView viewWithTag:41];
    [activity startAnimating];
    
    OLProduct *product = (OLProduct *)self.products[indexPath.row];
    
    UIImageView *imageView = (UIImageView *)[cell.contentView viewWithTag:10];
    [product setCoverImageToImageView:imageView];
    
    UITextView *textView = (UITextView *)[cell.contentView viewWithTag:20];
    textView.text = product.productTemplate.templateType;
    textView.backgroundColor = product.productTemplate.labelColor;
    
    return cell;
}

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.products.count;
}

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

@end
