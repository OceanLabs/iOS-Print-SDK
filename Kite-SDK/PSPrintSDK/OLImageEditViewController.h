//
//  Modified MIT License
//
//  Copyright (c) 2010-2017 Kite Tech Ltd. https://www.kite.ly
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The software MAY ONLY be used with the Kite Tech Ltd platform and MAY NOT be modified
//  to be used with any competitor platforms. This means the software MAY NOT be modified
//  to place orders with any competitors to Kite Tech Ltd, all orders MUST go through the
//  Kite Tech Ltd platform servers.
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import <UIKit/UIKit.h>
#import "OLRemoteImageCropper.h"
#import "OLViewController.h"
#import "OLEditingToolsView.h"
#import "OLProduct.h"

@class OLImageEditViewController;
@class OLPhotoEdits;
@class OLAsset;

@protocol OLImageEditViewControllerDelegate <NSObject>

- (void)scrollCropViewController:(OLImageEditViewController *)cropper didFinishCroppingImage:(UIImage *)croppedImage;
- (void)scrollCropViewController:(OLImageEditViewController *)cropper didReplaceAssetWithAsset:(OLAsset *)asset;

@optional
- (void)scrollCropViewControllerDidDropChanges:(OLImageEditViewController *)cropper;
- (void)scrollCropViewControllerDidCancel:(OLImageEditViewController *)cropper;
@end

@interface OLImageEditViewController : OLViewController

@property (strong, nonatomic) UIImage *fullImage;
@property (copy, nonatomic) OLPhotoEdits *edits;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *aspectRatioConstraint;
@property (weak, nonatomic) IBOutlet OLRemoteImageCropper *cropView;
@property (assign, nonatomic) CGFloat aspectRatio;
@property (strong, nonatomic) NSNumber *centerYConConstant;
@property (weak, nonatomic) id<OLImageEditViewControllerDelegate> delegate;
@property (assign, nonatomic) BOOL enableCircleMask;
@property (strong, nonatomic) UIView *previewView;
@property (strong, nonatomic) UIView *previewSourceView;
@property (assign, nonatomic) BOOL forceSourceViewDimensions;
@property (assign, nonatomic) BOOL skipPresentAnimation;
@property (assign, nonatomic) UIEdgeInsets borderInsets;
@property (strong, nonatomic) OLAsset *asset;
@property (weak, nonatomic) UIButton *ctaButton;
@property (strong, nonatomic) OLEditingToolsView *editingTools;
@property (strong, nonatomic) OLProduct *product;
@property (weak, nonatomic) IBOutlet UINavigationItem *customNavigationItem;



@end
