//
//  OLImagePreviewViewController.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 23/12/15.
//  Copyright © 2015 Kite.ly. All rights reserved.
//

#import "OLImagePreviewViewController.h"

@interface OLImagePreviewViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation OLImagePreviewViewController

- (void)viewDidLoad{
    [super viewDidLoad];
    self.imageView.image = self.image;
}

- (void)setImage:(UIImage *)image{
    _image = image;
    self.imageView.image = image;
}

@end
