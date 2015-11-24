//
//  OLScrollCropViewController.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 1/21/15.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import "OLScrollCropViewController.h"
#import "OLPrintPhoto.h"

@interface OLScrollCropViewController () <RMImageCropperDelegate>
@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneButton;
@property (assign, nonatomic) NSInteger initialOrientation;

@end

@implementation OLScrollCropViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.cropView setClipsToBounds:NO];
    self.cropView.backgroundColor = [UIColor clearColor];
    
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
    self.initialOrientation = self.fullImage.imageOrientation;
    self.cropView.delegate = self;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.cropView removeConstraint:self.aspectRatioConstraint];
    self.aspectRatioConstraint = [NSLayoutConstraint constraintWithItem:self.cropView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.cropView attribute:NSLayoutAttributeWidth multiplier:self.aspectRatio constant:0];
    [self.cropView addConstraints:@[self.aspectRatioConstraint]];
    
    if (self.edits.counterClockwiseRotations > 0 || self.edits.flipHorizontal || self.edits.flipVertical){
        self.cropView.image = [UIImage imageWithCGImage:self.fullImage.CGImage scale:self.fullImage.scale orientation:[OLPhotoEdits orientationForNumberOfCounterClockwiseRotations:self.edits.counterClockwiseRotations andInitialOrientation:self.fullImage.imageOrientation horizontalFlip:self.edits.flipHorizontal verticalFlip:self.edits.flipVertical]];
    }
    else{
        [self.cropView setImage:self.fullImage];
    }
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
    self.cropView.imageView.transform = self.edits.cropTransform;
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

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (IBAction)onBarButtonDoneTapped:(UIBarButtonItem *)sender {
    self.edits.cropImageRect = [self.cropView getImageRect];
    self.edits.cropImageFrame = [self.cropView getFrameRect];
    self.edits.cropImageSize = [self.cropView croppedImageSize];
    self.edits.cropTransform = [self.cropView.imageView transform];
    
    if ([self.delegate respondsToSelector:@selector(scrollCropViewController:didFinishCroppingImage:)]){
        [self.delegate scrollCropViewController:self didFinishCroppingImage:[self.cropView editedImage]];
    }
}

- (IBAction)onBarButtonCancelTapped:(UIBarButtonItem *)sender {
    if ([self.delegate respondsToSelector:@selector(scrollCropViewControllerDidCancel:)]){
        [self.delegate scrollCropViewControllerDidCancel:self];
    }
}

- (IBAction)onButtonHorizontalFlipClicked:(id)sender {
    if (self.cropView.isCorrecting){
        return;
    }
    
    [self.edits performHorizontalFlipEditFromOrientation:self.cropView.imageView.image.imageOrientation];
    
    [UIView transitionWithView:self.cropView.imageView duration:0.5 options:UIViewAnimationOptionTransitionFlipFromRight animations:^{
        
        [self.cropView setImage:[UIImage imageWithCGImage:self.fullImage.CGImage scale:self.cropView.imageView.image.scale orientation:[OLPhotoEdits orientationForNumberOfCounterClockwiseRotations:self.edits.counterClockwiseRotations andInitialOrientation:self.initialOrientation horizontalFlip:self.edits.flipHorizontal verticalFlip:self.edits.flipVertical]]];
        
    }completion:NULL];
    
    self.doneButton.enabled = YES;
}

- (IBAction)onButtonRotateClicked:(id)sender {
    if (self.cropView.isCorrecting){
        return;
    }
    
    [(UIBarButtonItem *)sender setEnabled:NO];
    self.edits.counterClockwiseRotations = (self.edits.counterClockwiseRotations + 1) % 4;
    CGAffineTransform transform = self.cropView.imageView.transform;
    transform.tx = self.cropView.imageView.transform.ty;
    transform.ty = -self.cropView.imageView.transform.tx;
    
    CGRect cropboxRect = self.cropView.frame;
    
    UIImage *newImage = [UIImage imageWithCGImage:self.fullImage.CGImage scale:self.cropView.imageView.image.scale orientation:[OLPhotoEdits orientationForNumberOfCounterClockwiseRotations:self.edits.counterClockwiseRotations andInitialOrientation:self.initialOrientation horizontalFlip:self.edits.flipHorizontal verticalFlip:self.edits.flipVertical]];
    CGFloat imageAspectRatio = newImage.size.height/newImage.size.width;
    
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        self.cropView.transform = CGAffineTransformMakeRotation(-M_PI_2);
        
        CGFloat boxWidth = self.cropView.frame.size.width;
        CGFloat boxHeight = self.cropView.frame.size.height;
        
        CGFloat imageWidth;
        CGFloat imageHeight;
        
        if (imageAspectRatio > 1.0){
            imageHeight = boxHeight;
            imageWidth = boxHeight * imageAspectRatio;
        }
        else{
            imageWidth = boxWidth;
            imageHeight = boxWidth / imageAspectRatio;
        }
        
        self.cropView.imageView.frame = CGRectMake((boxHeight - imageWidth)/ 2.0, (boxWidth - imageHeight) / 2.0, imageWidth, imageHeight);
        
    } completion:^(BOOL finished){
        self.cropView.transform = CGAffineTransformIdentity;
        self.cropView.frame = cropboxRect;
        [self.cropView setImage:newImage];
        
        [(UIBarButtonItem *)sender setEnabled:YES];
        self.doneButton.enabled = YES;
    }];
}

#pragma mark - RMImageCropperDelegate methods

- (void)imageCropperDidTransformImage:(RMImageCropper *)imageCropper {
    self.doneButton.enabled = YES;
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
