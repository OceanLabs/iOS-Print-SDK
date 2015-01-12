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

@interface OLFrameSelectionViewController ()

@end

@implementation OLFrameSelectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Choose Frame Style", @"");
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSArray *products = [OLProduct products];
    
    OLFrameOrderReviewViewController *vc = segue.destinationViewController;
    vc.printOrder = self.printOrder;
    if ([segue.identifier isEqualToString:@"Selected2x2FrameStyleSegue"]) {
        for (OLProduct *product in products){
            if (product.templateType == kOLTemplateTypeFrame2x2){
                vc.product = product;
            }
        }
    } else if ([segue.identifier isEqualToString:@"Selected3x3FrameStyleSegue"]) {
        for (OLProduct *product in products){
            if (product.templateType == kOLTemplateTypeFrame3x3){
                vc.product = product;
            }
        }
    } else if ([segue.identifier isEqualToString:@"Selected4x4FrameStyleSegue"]) {
        for (OLProduct *product in products){
            if (product.templateType == kOLTemplateTypeFrame4x4){
                vc.product = product;
            }
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 233 * [self screenWidthFactor];
}



@end
