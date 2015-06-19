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
@property (weak, nonatomic) IBOutlet UIImageView *pageShadowRight2;
@property (weak, nonatomic) IBOutlet UIImageView *pageShadowLeft;
@property (weak, nonatomic) IBOutlet UIImageView *pageShadowLeft2;

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
        self.pageShadowLeft2.hidden = YES;
        self.pageShadowRight2.hidden = YES;

    }
    else{
        self.pageBackground.image = [UIImage imageNamed:@"page-right"];
        self.pageShadowLeft.hidden = YES;
        self.pageShadowRight.hidden = NO;
        self.pageShadowLeft2.hidden = YES;
        self.pageShadowRight2.hidden = YES;
    }
}

- (NSInteger)imageIndexForPoint:(CGPoint)p{
    return self.pageIndex; //only one for now
}

- (void)unhighlightImageAtIndex:(NSInteger)index{
    UIView *selectedView = self.imageView; //only one for now
    
    [UIView animateWithDuration:0.15 animations:^(void){
        selectedView.layer.borderColor = [UIColor clearColor].CGColor;
        selectedView.layer.borderWidth = 0;
    }];
}

- (void)highlightImageAtIndex:(NSInteger)index{
    UIView *selectedView = self.imageView; //only one for now
    
    [UIView animateWithDuration:0.15 animations:^(void){
        selectedView.layer.borderColor = self.view.tintColor.CGColor;
        selectedView.layer.borderWidth = 3.0;
    }];
}

- (void)loadImage{
        OLPrintPhoto *printPhoto = [self.userSelectedPhotos objectAtIndex:self.pageIndex];
    if (printPhoto != (id)[NSNull null]){
        self.imageView.image = nil;
        self.imageView.contentMode = UIViewContentModeScaleAspectFill;
        [printPhoto getImageWithProgress:NULL completion:^(UIImage *image){
            dispatch_async(dispatch_get_main_queue(), ^{
                self.imageView.image = image;
                self.pageShadowLeft2.hidden = NO;
                self.pageShadowRight2.hidden = NO;
            });
        }];
        
    }
    else{
        self.pageShadowLeft2.hidden = YES;
        self.pageShadowRight2.hidden = YES;
        [UIView animateWithDuration:0.5 animations:^{
            self.imageView.alpha = 0;
        }completion:^(BOOL finished){
            self.imageView.contentMode = UIViewContentModeCenter;
            self.imageView.image = [UIImage imageNamed:@"plus"];
            [UIView animateWithDuration:0.15 animations:^{
                self.imageView.alpha = 1;
            }];
        }];
        
    }
}

@end
