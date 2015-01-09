//
//  FrameSelectionViewController.m
//  Print Studio
//
//  Created by Deon Botha on 13/02/2014.
//  Copyright (c) 2014 Ocean Labs. All rights reserved.
//

#import "FrameSelectionViewController.h"
#import "UITableViewController+ScreenWidthFactor.h"
#import "FrameOrderReviewViewController.h"
#import "OLProduct.h"

@interface FrameSelectionViewController ()

@end

@implementation FrameSelectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Choose Frame Style", @"");
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSArray *products = [OLProduct products];
    
    FrameOrderReviewViewController *vc = segue.destinationViewController;
    vc.printOrder = self.printOrder;
    if ([segue.identifier isEqualToString:@"Selected2x2FrameStyleSegue"]) {
        for (OLProduct *product in products){
            if (product.type == kOLTemplateTypeFrame2x2){
                vc.product = product;
            }
        }
    } else if ([segue.identifier isEqualToString:@"Selected3x3FrameStyleSegue"]) {
        for (OLProduct *product in products){
            if (product.type == kOLTemplateTypeFrame3x3){
                vc.product = product;
            }
        }
    } else if ([segue.identifier isEqualToString:@"Selected4x4FrameStyleSegue"]) {
        for (OLProduct *product in products){
            if (product.type == kOLTemplateTypeFrame4x4){
                vc.product = product;
            }
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 233 * [self screenWidthFactor];
}



@end
