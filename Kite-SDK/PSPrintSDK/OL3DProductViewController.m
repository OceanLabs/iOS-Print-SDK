//
//  Modified MIT License
//
//  Copyright (c) 2010-2016 Kite Tech Ltd. https://www.kite.ly
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

#import "OL3DProductViewController.h"
#import "OLKiteUtils.h"
#import "OLUserSession.h"
#import "OLAsset+Private.h"
#import "OLInfoBanner.h"

@import SceneKit;

@interface OLSingleImageProductReviewViewController (Private) <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UIView *printContainerView;
- (void)setupImage;
- (void)onButtonCropClicked:(UIButton *)sender;
- (void)exitCropMode;
@end

@interface OL3DProductViewController ()
@property (strong, nonatomic) OLInfoBanner *infoBanner;
@property (weak, nonatomic) IBOutlet SCNView *scene;
@property (strong, nonatomic) SCNGeometry *tube;
@end

@implementation OL3DProductViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    SCNScene *scene = [SCNScene sceneWithURL:[[NSBundle bundleForClass:[OLKiteViewController class]] URLForResource:@"mug" withExtension:@"dae"]
 options:NULL error:nil];
    
    self.tube = [SCNTube tubeWithInnerRadius:1 outerRadius:1 height:1.75];
    [scene.rootNode addChildNode:[SCNNode nodeWithGeometry:self.tube]];
    
    self.scene.scene = scene;
    
    self.infoBanner = [OLInfoBanner showInfoBannerOnViewController:self withTitle:NSLocalizedStringFromTableInBundle(@"Swipe to rotate your mug. Double tap to reset.", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"")];
}

- (CGFloat)aspectRatio{
    return 1.0/2.415;
}

- (void)orderViews{
    [self.view bringSubviewToFront:self.printContainerView];
    [self.view bringSubviewToFront:self.cropView];
    [self.view bringSubviewToFront:self.scene];
    [self.view bringSubviewToFront:self.editingTools.drawerView];
    [self.view bringSubviewToFront:self.editingTools];
    [self.view bringSubviewToFront:self.hintView];
    [self.view bringSubviewToFront:[self.view viewWithTag:1010]];
}

- (void)setCropViewImageToMaterial{
    id view = [self.view viewWithTag:1010];
    if ([view isKindOfClass:[UIActivityIndicatorView class]]){
        [(UIActivityIndicatorView *)view startAnimating];
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *image = [self addBorderToImage:[self.cropView editedImage]];
        
        OLAsset *tempAsset = [OLAsset assetWithImageAsPNG:image];
        tempAsset.edits.filterName = self.edits.filterName;
        
        [tempAsset imageWithSize:OLAssetMaximumSize applyEdits:YES progress:NULL completion:^(UIImage *image, NSError *error){
            dispatch_async(dispatch_get_main_queue(), ^{
                
                
                SCNMaterial *material = [[SCNMaterial alloc] init];
                material.diffuse.wrapS = SCNWrapModeRepeat;
                material.diffuse.wrapT = SCNWrapModeRepeat;
                material.diffuse.contents = image;
                self.tube.materials = @[material];
                
                if ([view isKindOfClass:[UIActivityIndicatorView class]]){
                    [(UIActivityIndicatorView *)view stopAnimating];
                }
            });
        }];
    });
}

- (UIImage *)addBorderToImage:(UIImage *)image {
    CGFloat borderPercent = 0.1;
    
    CGSize size = [image size];
    CGSize contextSize = CGSizeMake(size.width * (1.0 + borderPercent), size.height);
    CGRect drawRect = CGRectMake(size.width * borderPercent/2.0, 0, size.width, size.height);
    
    UIGraphicsBeginImageContext(contextSize);
    [image drawInRect:drawRect blendMode:kCGBlendModeNormal alpha:1.0];
    UIImage *paddedImage =  UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return paddedImage;
}

- (void)setupImage{
    [super setupImage];
    
    [self setCropViewImageToMaterial];
}

- (void)updateProductRepresentationForChoice:(OLProductTemplateOptionChoice *)choice{
    [self setCropViewImageToMaterial];
}

- (void)onButtonCropClicked:(UIButton *)sender{
    self.scene.hidden = YES;
    
    [super onButtonCropClicked:sender];
}

- (void)exitCropMode{
    [super exitCropMode];
    
    [self setCropViewImageToMaterial];
    self.scene.hidden = NO;
}

@end
