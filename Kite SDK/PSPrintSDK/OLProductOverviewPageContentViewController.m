//
//  ProductOverviewViewController.m
//  Kite Print SDK
//
//  Created by Deon Botha on 03/01/2014.
//  Copyright (c) 2014 Ocean Labs. All rights reserved.
//

#import "OLProductOverviewPageContentViewController.h"
#import "OLFrameSelectionViewController.h"
#import "OLProductTemplate.h"
#import "OLProduct.h"
#import "OLProductOverviewViewController.h"

@interface OLProduct (Private)

-(void)setCoverImageToImageView:(UIImageView *)imageView;
-(void)setProductPhotography:(NSUInteger)i toImageView:(UIImageView *)imageView;

@end

@interface OLProductOverviewViewController (Private)

- (IBAction)onButtonStartClicked:(UIBarButtonItem *)sender;

@end

@interface OLProductOverviewPageContentViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@end

@implementation OLProductOverviewPageContentViewController


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
