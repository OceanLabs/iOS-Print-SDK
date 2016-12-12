//
//  CustomImagePickerViewController.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 14/10/2016.
//  Copyright © 2016 Kite.ly. All rights reserved.
//

#import "CustomImagePickerViewController.h"
#import "OLAsset.h"

@interface CustomImagePickerViewController ()

@end

@implementation CustomImagePickerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIButton *button = [[UIButton alloc] init];
    [button setTitle:@"Add pets photos" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(buttonAction) forControlEvents:UIControlEventTouchUpInside];
    [button setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    
    [self.view addSubview:button];
    
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [button.superview addConstraint:[NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:button.superview attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    [button.superview addConstraint:[NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:button.superview attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    NSLog(@"%@", self.productId);
}

- (void)buttonAction{
    NSArray *assets = @[[OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/1.jpg"]],
                       [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/2.jpg"]],
                       [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/3.jpg"]],
                       [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/4.jpg"]],
                       [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/5.jpg"]],
                       [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/6.jpg"]]];
    [self.delegate assetsPickerController:self didFinishPickingAssets:assets];
}



@end
