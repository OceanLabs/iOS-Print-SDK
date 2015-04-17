//
//  OLPhotobookPageViewController.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 4/17/15.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import "OLPhotobookPageViewController.h"
#import "OLPrintPhoto.h"

@interface OLPhotobookPageViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;


@end

@implementation OLPhotobookPageViewController

- (void)viewDidLoad{
    [super viewDidLoad];
    
    OLPrintPhoto *printPhoto = [self.userSelectedPhotos objectAtIndex:self.pageIndex];
    [printPhoto getImageWithProgress:NULL completion:^(UIImage *image){
        self.imageView.image = image;
    }];
}

@end
