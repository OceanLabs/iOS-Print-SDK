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

#import "OL3DCaseViewController.h"
#import "OLKiteUtils.h"
#import "OLUserSession.h"
#import "OLAsset+Private.h"

@import SceneKit;

@interface OLSingleImageProductReviewViewController (Private) <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UIView *printContainerView;
@end

@interface OL3DCaseViewController ()
@property (weak, nonatomic) IBOutlet SCNView *scene;
@property (strong, nonatomic) SCNNode *cameraNode;
@end

@implementation OL3DCaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Create a new scene
    SCNScene *scene = [SCNScene sceneWithURL:[[NSBundle bundleForClass:[OLKiteViewController class]] URLForResource:@"cup" withExtension:@"dae"]
 options:NULL error:nil];
    
    SCNTube *tube = [SCNTube tubeWithInnerRadius:1.521 outerRadius:1.521 height:2.81385]; //height = 2*radius * 0.925
    [scene.rootNode addChildNode:[SCNNode nodeWithGeometry:tube]];
    
    [[OLUserSession currentSession].userSelectedPhotos.lastObject imageWithSize:OLAssetMaximumSize applyEdits:YES progress:NULL completion:^(UIImage *image, NSError *error){
        SCNMaterial *material = [[SCNMaterial alloc] init];
        material.litPerPixel = NO;
        material.diffuse.wrapS = SCNWrapModeRepeat;
        material.diffuse.wrapT = SCNWrapModeRepeat;
        material.diffuse.contents = image;
        tube.materials = @[material];
    }];
    
    // create and add a light to the scene
    SCNNode *lightNode = [SCNNode node];
    lightNode.light = [SCNLight light];
    lightNode.light.type = SCNLightTypeOmni;
    lightNode.position = SCNVector3Make(0, -10, 10);
    [scene.rootNode addChildNode:lightNode];
    
    // create and add an ambient light to the scene
    SCNNode *ambientLightNode = [SCNNode node];
    ambientLightNode.light = [SCNLight light];
    ambientLightNode.light.type = SCNLightTypeAmbient;
    ambientLightNode.light.color = [UIColor darkGrayColor];
    [scene.rootNode addChildNode:ambientLightNode];
    
    SCNView *scnView = self.scene;
    
    // set the scene to the view
    scnView.scene = scene;
    
    // allows the user to manipulate the camera
    scnView.allowsCameraControl = YES;
    
    // configure the view
    scnView.backgroundColor = [UIColor clearColor];
}

- (void)orderViews{
    [self.view bringSubviewToFront:self.printContainerView];
    [self.view bringSubviewToFront:self.cropView];
    [self.view bringSubviewToFront:self.editingTools.drawerView];
    [self.view bringSubviewToFront:self.editingTools];
    [self.view bringSubviewToFront:self.hintView];
    [self.view bringSubviewToFront:self.scene];
}

- (void)setupProductRepresentation{
    self.printContainerView.hidden = YES;
}

@end
