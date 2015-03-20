//
//  FrameSelectionViewController.m
//  Kite Print SDK
//
//  Created by Deon Botha on 13/02/2014.
//  Copyright (c) 2014 Ocean Labs. All rights reserved.
//

#import "OLFrameSelectionViewController.h"
#import "UITableViewController+ScreenWidthFactor.h"
#import "OLFrameOrderReviewViewController.h"
#import "OLProduct.h"
#import "OLAnalytics.h"
#import "OLPhotoSelectionViewController.h"
#import "OLKitePrintSDK.h"

@interface OLKitePrintSDK (Kite)

+ (OLKiteViewController *)kiteViewControllerInNavStack:(NSArray *)viewControllers;

@end

@implementation OLFrameSelectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackProductTemplateSelectionScreenViewed:@"Frames"];
#endif
    
    self.title = NSLocalizedString(@"Choose Frame Style", @"");
}

- (IBAction)onTapGestureRecognized:(UITapGestureRecognizer *)sender {
    NSArray *products = [OLProduct products];
    OLProduct *chosenProduct;
    
    if (sender.view.tag == 22) {
        for (OLProduct *product in products){
            if (product.productTemplate.templateClass == kOLTemplateClassFrame && product.productTemplate.quantityPerSheet == 4){
                chosenProduct = product;
            }
        }
    } else if (sender.view.tag == 33) {
        for (OLProduct *product in products){
            if (product.productTemplate.templateClass == kOLTemplateClassFrame && product.productTemplate.quantityPerSheet == 9){
                chosenProduct = product;
            }
        }
    } else if (sender.view.tag == 44) {
        for (OLProduct *product in products){
            if (product.productTemplate.templateClass == kOLTemplateClassFrame && product.productTemplate.quantityPerSheet == 16){
                chosenProduct = product;
            }
        }
    }
    else if (sender.view.tag == 11){
        for (OLProduct *product in products){
            if (product.productTemplate.templateClass == kOLTemplateClassFrame && product.productTemplate.quantityPerSheet == 1){
                chosenProduct = product;
            }
        }
    }
    
    if (![self.delegate respondsToSelector:@selector(kiteControllerShouldShowAddMorePhotosInReview:)] || [self.delegate kiteControllerShouldShowAddMorePhotosInReview:[OLKitePrintSDK kiteViewControllerInNavStack:self.navigationController.viewControllers]]){
        OLPhotoSelectionViewController *vc;
        vc = [self.storyboard instantiateViewControllerWithIdentifier:@"PhotoSelectionViewController"];
        vc.assets = self.assets;
        vc.userSelectedPhotos = self.userSelectedPhotos;
        vc.product = chosenProduct;
        vc.delegate = self.delegate;
        [self.navigationController pushViewController:vc animated:YES];
    }
    else{
        OLFrameOrderReviewViewController *vc;
        vc = [self.storyboard instantiateViewControllerWithIdentifier:@"FrameOrderReviewViewController"];
        vc.assets = self.assets;
        vc.userSelectedPhotos = self.userSelectedPhotos;
        vc.product = chosenProduct;
        vc.delegate = self.delegate;
        [self.navigationController pushViewController:vc animated:YES];
    }
    
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self tableView:tableView numberOfRowsInSection:indexPath.section] == 2){
        return (self.view.bounds.size.height - 64) / 2;
    }
    else{
        return 233 * [self screenWidthFactor];
    }
}



@end
