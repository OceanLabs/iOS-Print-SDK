//
//  OLPhotobookPageViewController.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 4/17/15.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import "OLPhotobookPageContentViewController.h"
#import "OLPrintPhoto.h"
#import "OLScrollCropViewController.h"

@interface OLPhotobookPageContentViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *pageBackground;
@property (weak, nonatomic) IBOutlet UIImageView *pageShadowRight;
@property (weak, nonatomic) IBOutlet UIImageView *pageShadowLeft;


@end

@implementation OLPhotobookPageContentViewController

- (void)viewDidLoad{
    [super viewDidLoad];
    [self loadImage];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self setPage:(self.pageIndex % 2 == 0)];
}

//- (void)setPageIndex:(NSInteger)pageIndex{
//    _pageIndex = pageIndex;
//    
//    [self setPage:(pageIndex % 2 == 0)];
//}

- (void)setPage:(BOOL)left{
    if (left){
        self.pageBackground.image = [UIImage imageNamed:@"page-left"];
        self.pageShadowLeft.hidden = NO;
        self.pageShadowRight.hidden = YES;
    }
    else{
        self.pageBackground.image = [UIImage imageNamed:@"page-right"];
        self.pageShadowLeft.hidden = YES;
        self.pageShadowRight.hidden = NO;
    }
}

- (void)loadImage{
    OLPrintPhoto *printPhoto = [self.userSelectedPhotos objectAtIndex:self.pageIndex];
    [printPhoto getImageWithProgress:NULL completion:^(UIImage *image){
        dispatch_async(dispatch_get_main_queue(), ^{
            self.imageView.image = image;
        });
    }];
}

@end
