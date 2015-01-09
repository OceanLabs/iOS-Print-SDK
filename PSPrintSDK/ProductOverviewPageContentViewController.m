//
//  ProductOverviewViewController.m
//  Print Studio
//
//  Created by Deon Botha on 03/01/2014.
//  Copyright (c) 2014 Ocean Labs. All rights reserved.
//

#import "ProductOverviewPageContentViewController.h"
#import "FrameSelectionViewController.h"
#import "OLProductTemplate.h"
#import "OLProduct.h"

@interface ProductOverviewPageContentViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@end

@implementation ProductOverviewPageContentViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    [self.product setProductPhotography:self.pageIndex toImageView:self.imageView];
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    if ([identifier isEqualToString:@"ToPhotoSelectionSegue"]) {
        
        if (self.product.type == kOLTemplateTypeFrame2x2
            || self.product.type == kOLTemplateTypeFrame3x3
            || self.product.type == kOLTemplateTypeFrame4x4) {
            FrameSelectionViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"FrameSelectionViewController"];
            [self.navigationController pushViewController:vc animated:YES];
            return NO;
        }
    }
    
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
//    if ([segue.identifier isEqualToString:@"ToPhotoSelectionSegue"]) {
//        PhotoSelectionViewController *photoSelectionVC = segue.destinationViewController;
//        photoSelectionVC.product = self.product;
//    }
}

@end
