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

#import "OL3DProductViewController.h"
#import "OLKiteUtils.h"
#import "OLUserSession.h"
#import "OLAsset+Private.h"
#import "OLInfoBanner.h"
#import "UIView+AutoLayoutHelper.h"
#import "UIColor+OLHexString.h"
#import "OLImagePickerViewController.h"

@import SceneKit;

@interface OLSingleProductReviewViewController (Private) <UITextFieldDelegate>
- (void)loadImages;
- (void)onButtonCropClicked:(UIButton *)sender;
- (void)exitCropMode;
@property (strong, nonatomic) UIView *safeAreaView;
- (void)imagePicker:(OLImagePickerViewController *)vc didFinishPickingAssets:(NSMutableArray *)assets added:(NSArray<OLAsset *> *)addedAssets removed:(NSArray *)removedAssets;
@end

@interface OL3DProductViewController ()
@property (strong, nonatomic) OLInfoBanner *infoBanner;
@property (strong, nonatomic) SCNView *scene;
@property (strong, nonatomic) SCNGeometry *tube;
@property (strong, nonatomic) SCNNode *tubeNode;
@property (strong, nonatomic) SCNNode *mug;
@property (strong, nonatomic) SCNNode *camera;
@property (strong, nonatomic) UIActivityIndicatorView *activity;
@end

@implementation OL3DProductViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.scene = [[SCNView alloc] init];
    self.scene.antialiasingMode = SCNAntialiasingModeMultisampling4X;
    self.scene.backgroundColor = self.view.backgroundColor;
    [self.view addSubview:self.scene];
    [self.scene leadingFromSuperview:0 relation:NSLayoutRelationEqual];
    [self.scene trailingToSuperview:0 relation:NSLayoutRelationEqual];
    [self.scene verticalSpacingToView:self.editingTools constant:0 relation:NSLayoutRelationEqual];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.scene attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.topLayoutGuide attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPanGestureRecognized:)];
    [self.scene addGestureRecognizer:panGesture];
    
    SCNScene *scene = [SCNScene sceneWithURL:[[OLKiteUtils kiteResourcesBundle] URLForResource:@"mug" withExtension:@"scn"]
 options:NULL error:nil];
    
    self.tube = [SCNTube tubeWithInnerRadius:1 outerRadius:1 height:1.95];
    self.tubeNode = [SCNNode nodeWithGeometry:self.tube];
    self.tubeNode.eulerAngles = SCNVector3Make(M_PI_2, 0, -M_PI_2);
    [scene.rootNode addChildNode:self.tubeNode];
    
    self.scene.scene = scene;
    
    self.infoBanner = [OLInfoBanner showInfoBannerOnViewController:self withTitle:NSLocalizedStringFromTableInBundle(@"Swipe to rotate your mug", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"")];
    
    [[scene rootNode] enumerateChildNodesUsingBlock:^(SCNNode *node, BOOL *stop){
        if ([node.name isEqualToString:@"mug"]){
            self.mug = node;
            self.mug.pivot = SCNMatrix4MakeTranslation(-0.038, 0, -0.05);
        }
        if ([node.name isEqualToString:@"Camera"]){
            self.camera = node;
        }
    }];
    
    if (self.view.frame.size.width > self.view.frame.size.height){
        self.camera.position = SCNVector3Make(0, 6.5, 0);
    }
    else{
        self.camera.position = SCNVector3Make(0, 4.2, 0);
    }
    
    self.activity = [[UIActivityIndicatorView alloc] init];
    [self.scene addSubview:self.activity];
    [self.activity centerXInSuperview];
    [self.activity centerYInSuperview];
    self.activity.hidesWhenStopped = YES;
    self.activity.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    
    [self orderViews];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id cotext){
        if (size.width > size.height){
            self.camera.position = SCNVector3Make(0, 6.5, 0);
        }
        else{
            self.camera.position = SCNVector3Make(0, 4.2, 0);
        }
    }completion:NULL];
}

- (CGFloat)aspectRatio{
    return 1.110/2.685;
}

- (void)orderViews{
    [self.view bringSubviewToFront:self.printContainerView];
    [self.view bringSubviewToFront:self.artboard];
    [self.view bringSubviewToFront:self.scene];
    [self.view bringSubviewToFront:self.editingTools.drawerView];
    if (self.safeAreaView){
        [self.view bringSubviewToFront:self.safeAreaView];
    }
    [self.view bringSubviewToFront:self.editingTools];
    [self.view bringSubviewToFront:self.hintView];
    [self.view bringSubviewToFront:self.activity];
}

- (void)setCropViewImageToMaterial{
    if (self.activity.isAnimating){
        return;
    }
    self.tube.materials = @[];
    
    if (self.artboard.assetViews.firstObject.imageView.image == nil){
        return;
    }
    
    [self.activity startAnimating];
    
    UIImage *image = [self.artboard.assetViews.firstObject editedImage];
    
    if (!image){
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        OLAsset *tempAsset = [OLAsset assetWithImageAsPNG:image];
        tempAsset.edits.filterName = self.edits.filterName;
        
        [tempAsset imageWithSize:OLAssetMaximumSize applyEdits:YES progress:NULL completion:^(UIImage *image, NSError *error){
            dispatch_async(dispatch_get_main_queue(), ^{
                SCNMaterial *material = [[SCNMaterial alloc] init];
                material.diffuse.wrapS = SCNWrapModeRepeat;
                material.diffuse.wrapT = SCNWrapModeRepeat;
                material.diffuse.contents = [self addBorderToImage:image];
                self.tube.materials = @[material];
                
                [self.activity stopAnimating];
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
    [[UIColor whiteColor] set];
    UIRectFill(CGRectMake(0.0, 0.0, contextSize.width, contextSize.height));
    [image drawInRect:drawRect blendMode:kCGBlendModeNormal alpha:1.0];
    UIImage *paddedImage =  UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return paddedImage;
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

- (IBAction)onPanGestureRecognized:(UIPanGestureRecognizer *)sender {
    static CGFloat startingEulerAngle = 0;
    if (sender.state == UIGestureRecognizerStateBegan){
        startingEulerAngle = self.mug.eulerAngles.z;
    }
    if (sender.state == UIGestureRecognizerStateChanged){
        CGPoint translate = [sender translationInView:sender.view.superview];
        CGFloat angleDelta = startingEulerAngle + (translate.x * M_PI)/180.0;
        
        self.mug.eulerAngles = SCNVector3Make(self.mug.eulerAngles.x, self.mug.eulerAngles.y, angleDelta);
        self.tubeNode.eulerAngles = SCNVector3Make(self.tubeNode.eulerAngles.x, self.tubeNode.eulerAngles.y, -M_PI_2 + angleDelta);
        
    }
}

- (void)imagePicker:(OLImagePickerViewController *)vc didFinishPickingAssets:(NSMutableArray *)assets added:(NSArray<OLAsset *> *)addedAssets removed:(NSArray *)removedAssets{
    if (addedAssets.firstObject){
        self.edits = nil;
    }
    [super imagePicker:vc didFinishPickingAssets:assets added:addedAssets removed:removedAssets];
}

- (void)updateProductRepresentationForChoice:(OLProductTemplateOptionChoice *)choice{
    [self setCropViewImageToMaterial];
}


@end
