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

@interface OLFrameSelectionViewController ()

@end

@implementation OLFrameSelectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackProductTemplateSelectionScreenViewed:@"Frames"];
#endif
    
    self.title = NSLocalizedString(@"Choose Frame Style", @"");
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSArray *products = [OLProduct products];
    
    OLFrameOrderReviewViewController *vc = segue.destinationViewController;
    vc.assets = self.assets;
    if ([segue.identifier isEqualToString:@"Selected2x2FrameStyleSegue"]) {
        for (OLProduct *product in products){
            if (product.productTemplate.templateClass == kOLTemplateClassFrame && product.productTemplate.quantityPerSheet == 4){
                vc.product = product;
            }
        }
    } else if ([segue.identifier isEqualToString:@"Selected3x3FrameStyleSegue"]) {
        for (OLProduct *product in products){
            if (product.productTemplate.templateClass == kOLTemplateClassFrame && product.productTemplate.quantityPerSheet == 9){
                vc.product = product;
            }
        }
    } else if ([segue.identifier isEqualToString:@"Selected4x4FrameStyleSegue"]) {
        for (OLProduct *product in products){
            if (product.productTemplate.templateClass == kOLTemplateClassFrame && product.productTemplate.quantityPerSheet == 16){
                vc.product = product;
            }
        }
    }
    else if ([segue.identifier isEqualToString:@"Selected1x1FrameStyleSegue"]){
        for (OLProduct *product in products){
            if (product.productTemplate.templateClass == kOLTemplateClassFrame && product.productTemplate.quantityPerSheet == 1){
                vc.product = product;
            }
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 233 * [self screenWidthFactor];
}



@end
