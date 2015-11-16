//
//  OLScrollCropViewController.h
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 1/21/15.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OLRemoteImageCropper.h"

@class OLScrollCropViewController;
@class OLPhotoEdits;

@protocol OLScrollCropViewControllerDelegate <NSObject>

- (void)scrollCropViewController:(OLScrollCropViewController *)cropper didFinishCroppingImage:(UIImage *)croppedImage;
- (void)scrollCropViewControllerDidCancel:(OLScrollCropViewController *)cropper;

@end

@interface OLScrollCropViewController : UIViewController

@property (strong, nonatomic) UIImage *fullImage;
@property (copy, nonatomic) OLPhotoEdits *edits;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *aspectRatioConstraint;
@property (weak, nonatomic) IBOutlet OLRemoteImageCropper *cropView;
@property (assign, nonatomic) CGFloat aspectRatio;
@property (weak, nonatomic) id<OLScrollCropViewControllerDelegate> delegate;
@property (assign, nonatomic) BOOL enableCircleMask;

@end
