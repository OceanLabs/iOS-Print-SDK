//
//  OLScrollCropViewController.h
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 1/21/15.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <RMImageCropper.h>

@protocol OLScrollCropViewControllerDelegate <NSObject>

-(void)userDidCropImage:(UIImage *)croppedImage;

@end

@interface OLScrollCropViewController : UIViewController

@property (strong, nonatomic) UIImage *fullImage;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *aspectRatioConstraint;
@property (weak, nonatomic) IBOutlet RMImageCropper *cropView;
@property (assign, nonatomic) CGFloat aspectRatio;
@property (weak, nonatomic) id<OLScrollCropViewControllerDelegate> delegate;

@end
