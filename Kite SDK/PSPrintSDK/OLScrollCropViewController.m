//
//  OLScrollCropViewController.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 1/21/15.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import "OLScrollCropViewController.h"

@interface OLScrollCropViewController ()

@end

@implementation OLScrollCropViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.cropView setClipsToBounds:NO];
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8){
        UIButton *doneButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 40, 20)];
        [doneButton addTarget:self action:@selector(onBarButtonDoneTapped:) forControlEvents:UIControlEventTouchUpInside];
        [doneButton setTitle: NSLocalizedString(@"Done", @"") forState:UIControlStateNormal];
        [doneButton setTitleColor:self.view.tintColor forState:UIControlStateNormal];
        [doneButton.titleLabel setFont:[UIFont boldSystemFontOfSize:18]];
        [doneButton sizeToFit];
        
        UIBarButtonItem *item =[[UIBarButtonItem alloc] initWithCustomView:doneButton];
        self.navigationItem.rightBarButtonItem = item;
    }
    
    UIButton *cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 40, 20)];
    [cancelButton addTarget:self action:@selector(onBarButtonCancelTapped:) forControlEvents:UIControlEventTouchUpInside];
    [cancelButton setTitle: NSLocalizedString(@"Cancel", @"") forState:UIControlStateNormal];
    [cancelButton setTitleColor:self.view.tintColor forState:UIControlStateNormal];
    [cancelButton.titleLabel setFont:[UIFont boldSystemFontOfSize:18]];
    [cancelButton sizeToFit];
    
    UIBarButtonItem *cancelItem =[[UIBarButtonItem alloc] initWithCustomView:cancelButton];
    self.navigationItem.leftBarButtonItem = cancelItem;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.cropView removeConstraint:self.aspectRatioConstraint];
    NSLayoutConstraint *con = [NSLayoutConstraint constraintWithItem:self.cropView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.cropView attribute:NSLayoutAttributeWidth multiplier:self.aspectRatio constant:0];
    [self.cropView addConstraints:@[con]];
    
    [self.cropView setImage:self.fullImage];
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
}

-(void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    if (self.enableCircleMask){
        CAShapeLayer *aCircle=[CAShapeLayer layer];
        aCircle.path=[UIBezierPath bezierPathWithRoundedRect:self.cropView.bounds cornerRadius:self.cropView.frame.size.height/2].CGPath;
        
        aCircle.fillColor=[UIColor blackColor].CGColor;
        self.cropView.layer.mask=aCircle;
    }
}

- (IBAction)onBarButtonDoneTapped:(UIBarButtonItem *)sender {
    if ([self.delegate respondsToSelector:@selector(scrollCropViewController:didFinishCroppingImage:)]){
        [self.delegate scrollCropViewController:self didFinishCroppingImage:[self.cropView editedImage]];
    }
}

- (IBAction)onBarButtonCancelTapped:(UIBarButtonItem *)sender {
    if ([self.delegate respondsToSelector:@selector(scrollCropViewControllerDidCancel:)]){
        [self.delegate scrollCropViewControllerDidCancel:self];
    }
}

#pragma mark - Autorotate and Orientation Methods
// Currently here to disable landscape orientations and rotation on iOS 7. When support is dropped, these can be deleted.

- (BOOL)shouldAutorotate {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8) {
        return YES;
    }
    else{
        return NO;
    }
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8) {
        return UIInterfaceOrientationMaskAll;
    }
    else{
        return UIInterfaceOrientationMaskPortrait;
    }
}

@end
