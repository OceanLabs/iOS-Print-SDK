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
#import "ProductOverviewViewController.h"

@interface ProductOverviewViewController (Private)

- (IBAction)onButtonStartClicked:(UIBarButtonItem *)sender;

@end

@interface ProductOverviewPageContentViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@end

@implementation ProductOverviewPageContentViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    [self.product setProductPhotography:self.pageIndex toImageView:self.imageView];
}

- (IBAction)userDidTapOnImage:(UITapGestureRecognizer *)sender {
    if ([self.delegate respondsToSelector:@selector(userDidTapOnImage)]){
        [self.delegate userDidTapOnImage];
    }
}


@end
