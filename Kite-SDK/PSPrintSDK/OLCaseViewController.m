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

#import "OLImageDownloader.h"
#import "OLCaseViewController.h"
#import "OLRemoteImageCropper.h"
#import "UIImage+ImageNamedInKiteBundle.h"
#import "UIImage+OLUtils.h"
#import "OLUserSession.h"
#import "OLAsset+Private.h"
#import "UIImageView+FadeIn.h"
#import "OLPhotoTextField.h"

@interface OLSingleImageProductReviewViewController (Private) <UITextFieldDelegate>

-(void) doCheckout;
@property (weak, nonatomic) IBOutlet UIView *printContainerView;
@property (strong, nonatomic) NSMutableArray *cropFrameGuideViews;
- (UIEdgeInsets)imageInsetsOnContainer;
@property (strong, nonatomic) UITextField *borderTextField;
- (void)onButtonCropClicked:(UIButton *)sender;
- (void)onTapGestureRecognized:(id)sender;
@property (strong, nonatomic) OLPhotoTextField *activeTextField;
@property (strong, nonatomic) NSMutableArray<OLPhotoTextField *> *textFields;
- (void)disableOverlay;
- (void)showDrawerWithCompletionHandler:(void(^)(BOOL finished))handler;
@end

@interface OLCaseViewController ()

@property (assign, nonatomic) BOOL downloadedMask;
@property (strong, nonatomic) IBOutlet UIVisualEffectView *caseVisualEffectView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *maskActivityIndicator;
@property (strong, nonatomic) UIImage *maskImage;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *centerYCon;
@property (weak, nonatomic) IBOutlet UIImageView *deviceView;
@property (weak, nonatomic) IBOutlet UIImageView *highlightsView;
@property (strong, nonatomic) NSOperation *downloadImagesOperation;
@property (strong, nonatomic) UIImageView *renderedImageView;
@property (strong, nonatomic) NSBlockOperation *viewDidAppearOperation;

@end

@implementation OLCaseViewController

- (void)setActiveTextField:(OLPhotoTextField *)activeTextField{
    if ([self isUsingMultiplyBlend]){
        if (self.activeTextField && !activeTextField ){
            [self renderImage];
        }
        else{
            [self disableOverlay];
        }
    }
    
    [super setActiveTextField:activeTextField];
}

- (void)viewDidLoad{
    if ([self isUsingMultiplyBlend]){
        [self.cropView setGesturesEnabled:NO];
        self.viewDidAppearOperation = [NSBlockOperation blockOperationWithBlock:^{}];
    }
    
    [super viewDidLoad];
}

- (void)onTapGestureRecognized:(id)sender{
    if (!self.activeTextField){
        [self renderImage];
    }
    [super onTapGestureRecognized:sender];
}

- (BOOL)isUsingMultiplyBlend{
    return self.product.productTemplate.templateUI == OLTemplateUIApparel || self.product.productTemplate.blendMode == OLImageBlendModeMultiply;
}

- (BOOL)shouldEnableGestures{
    return self.product.productTemplate.templateUI != OLTemplateUIApparel;
}

- (void)disableOverlay{
    self.renderedImageView.hidden = YES;
}

- (CGFloat)aspectRatio{
    if (CGSizeEqualToSize(self.product.productTemplate.sizePx, CGSizeZero)){
        return self.product.productTemplate.sizeCm.height / self.product.productTemplate.sizeCm.width;
    }
    
    return self.product.productTemplate.sizePx.height / self.product.productTemplate.sizePx.width;
}

- (void)setupProductRepresentation{
    self.downloadedMask = NO;
    
    self.downloadImagesOperation = [NSBlockOperation blockOperationWithBlock:^{}];
    
    if (self.product.productTemplate.maskImageURL){
        NSOperation *op1 = [NSBlockOperation blockOperationWithBlock:^{}];
        [self.downloadImagesOperation addDependency:op1];
        
        [[OLImageDownloader sharedInstance] downloadImageAtURL:self.product.productTemplate.maskImageURL withCompletionHandler:^(UIImage *image, NSError *error){
            [[NSOperationQueue mainQueue] addOperation:op1];
        }];
    }
    else{
        [self.caseVisualEffectView removeFromSuperview];
        [self.maskActivityIndicator stopAnimating];
    }
    if (self.product.productTemplate.productHighlightsImageURL){
        NSOperation *op2 = [NSBlockOperation blockOperationWithBlock:^{}];
        [self.downloadImagesOperation addDependency:op2];
        
        [[OLImageDownloader sharedInstance] downloadImageAtURL:self.product.productTemplate.productHighlightsImageURL withCompletionHandler:^(UIImage *image, NSError *error){
            [[NSOperationQueue mainQueue] addOperation:op2];
        }];
    }
    else{
        [self.highlightsView removeFromSuperview];
    }
    
    if (self.product.productTemplate.productBackgroundImageURL){
        NSOperation *op3 = [NSBlockOperation blockOperationWithBlock:^{}];
        [self.downloadImagesOperation addDependency:op3];
        
        [[OLImageDownloader sharedInstance] downloadImageAtURL:self.product.productTemplate.productBackgroundImageURL withCompletionHandler:^(UIImage *image, NSError *error){
            [[NSOperationQueue mainQueue] addOperation:op3];
        }];
    }
    else{
        [self.deviceView removeFromSuperview];
    }
    
    [[NSOperationQueue mainQueue] addOperation:self.downloadImagesOperation];
    
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
    
    if ([self isUsingMultiplyBlend]){
        UIImageView *imageView = [[UIImageView alloc] init];
        self.renderedImageView = imageView;
        [self.printContainerView addSubview:imageView];
        imageView.translatesAutoresizingMaskIntoConstraints = NO;
        NSDictionary *views = NSDictionaryOfVariableBindings(imageView);
        NSMutableArray *con = [[NSMutableArray alloc] init];
        
        NSArray *visuals = @[@"H:|-0-[imageView]-0-|",
                             @"V:|-0-[imageView]-0-|"];
        
        
        for (NSString *visual in visuals) {
            [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
        }
        
        [imageView.superview addConstraints:con];
    }
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    self.centerYCon.constant = (88.0 - ([[UIApplication sharedApplication] statusBarFrame].size.height + self.navigationController.navigationBar.frame.size.height + 20.0))/2.0;
    
    if (!self.downloadedMask && self.product.productTemplate.maskImageURL){
        UIImage *tempMask = [UIImage imageNamedInKiteBundle:@"dummy mask"];
        [self.cropView removeConstraint:self.aspectRatioConstraint];
        NSLayoutConstraint *con = [NSLayoutConstraint constraintWithItem:self.cropView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.cropView attribute:NSLayoutAttributeWidth multiplier:tempMask.size.height / tempMask.size.width constant:0];
        [self.cropView addConstraints:@[con]];
        self.aspectRatioConstraint = con;
        
        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];
        
        [self maskWithImage:tempMask targetView:self.cropView];
        
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    }
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    if (self.viewDidAppearOperation && !self.viewDidAppearOperation.finished){
        [[NSOperationQueue mainQueue] addOperation:self.viewDidAppearOperation];
    }
}

- (UIColor *)containerBackgroundColor{
    return self.product.productTemplate.maskImageURL ? [UIColor clearColor] : [UIColor whiteColor];
}

- (void)orderViews{
    [self.view bringSubviewToFront:self.deviceView];
    [self.view bringSubviewToFront:self.printContainerView];
    [self.view bringSubviewToFront:self.cropView];
    
    if (![self isUsingMultiplyBlend]){
        [self.view bringSubviewToFront:self.highlightsView];
    }
    else{
        [self.highlightsView.superview sendSubviewToBack:self.highlightsView];
        self.highlightsView.hidden = YES;
    }
    
    [self.view bringSubviewToFront:self.editingTools.drawerView];
    [self.view bringSubviewToFront:self.editingTools];
    [self.view bringSubviewToFront:self.hintView];
    [self.view bringSubviewToFront:self.renderedImageView];
}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    
    if (self.product.productTemplate.maskImageURL){
        NSBlockOperation *block = [NSBlockOperation blockOperationWithBlock:^{
            [self applyDownloadedMask];
        }];
        [block addDependency:self.downloadImagesOperation];
        if ([self isUsingMultiplyBlend] && !self.viewDidAppearOperation.finished){
            [block addDependency:self.viewDidAppearOperation];
        }
        [[NSOperationQueue mainQueue] addOperation:block];
    }
    else{
        [self applyProductImageLayers];
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context){
        self.centerYCon.constant = (88.0 - ([[UIApplication sharedApplication] statusBarFrame].size.height + self.navigationController.navigationBar.frame.size.height + 20.0))/2.0;
        [self.view layoutIfNeeded];
        [self maskWithImage:self.maskImage targetView:self.cropView];
    }completion:^(id <UIViewControllerTransitionCoordinatorContext> context){}];
}

- (void)applyDownloadedMask {
    if (self.downloadedMask){
        return;
    }
    
    [[OLImageDownloader sharedInstance] downloadImageAtURL:self.product.productTemplate.maskImageURL priority:1 progress:NULL withCompletionHandler:^(UIImage *image, NSError *error){
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        if (error) {
            UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Oops", @"")  message:NSLocalizedString(@"Failed to download phone case mask. Please check your internet connectivity and try again", @"")  delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"") otherButtonTitles:@"Retry", nil];
            av.tag = 99;
            [av show];
        } else {
            [self.cropView removeConstraint:self.aspectRatioConstraint];
            NSLayoutConstraint *con = [NSLayoutConstraint constraintWithItem:self.cropView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.cropView attribute:NSLayoutAttributeWidth multiplier:[self aspectRatio] constant:0];
            [self.cropView addConstraints:@[con]];
            
            [self.view setNeedsLayout];
            [self.view layoutIfNeeded];
            
            self.maskImage = [image shrinkToSize:[UIScreen mainScreen].bounds.size forScreenScale:[OLUserSession currentSession].screenScale];
            [self maskWithImage:self.maskImage targetView:self.cropView];
            
            [self applyProductImageLayers];
            
            self.caseVisualEffectView.hidden = YES;
            self.downloadedMask = YES;
            [self.maskActivityIndicator stopAnimating];
        }
    }];
}

- (void)applyProductImageLayers{
    if (!self.deviceView.image){
        self.deviceView.alpha = 0;
        [[OLImageDownloader sharedInstance] downloadImageAtURL:self.product.productTemplate.productBackgroundImageURL priority:1.0 progress:NULL withCompletionHandler:^(UIImage *image, NSError *error){
            self.deviceView.image = [image shrinkToSize:[UIScreen mainScreen].bounds.size forScreenScale:[OLUserSession currentSession].screenScale];
            [UIView animateWithDuration:0.1 animations:^{
                self.deviceView.alpha = 1;
            } completion:^(BOOL finished){
                [self renderImage];
            }];
        }];
    }
    if (!self.highlightsView.image){
        self.highlightsView.alpha = 0;
        [[OLImageDownloader sharedInstance] downloadImageAtURL:self.product.productTemplate.productHighlightsImageURL priority:0.9 progress:NULL withCompletionHandler:^(UIImage *image, NSError *error){
            self.highlightsView.image = [image shrinkToSize:[UIScreen mainScreen].bounds.size forScreenScale:[OLUserSession currentSession].screenScale];
            [UIView animateWithDuration:0.1 animations:^{
                self.highlightsView.alpha = 1;
            }];
        }];
    }
}

- (void)updateProductRepresentationForChoice:(OLProductTemplateOptionChoice *)choice{
    
    self.renderedImageView.image = nil;
    if (choice.productBackground){
        self.cropView.hidden = YES;
        [self.maskActivityIndicator.superview bringSubviewToFront:self.maskActivityIndicator];
        [self.maskActivityIndicator startAnimating];
        [self.deviceView setAndFadeInImageWithURL:choice.productBackground size:[UIScreen mainScreen].bounds.size placeholder:nil progress:NULL completionHandler:^{
            self.cropView.hidden = NO;
            [self.maskActivityIndicator stopAnimating];
            [self renderImage];
        }];
    }
    else{
        [self renderImage];
    }
}

-(void) maskWithImage:(UIImage*) maskImage targetView:(UIView*) targetView{
    if (!maskImage){
        [targetView.layer.mask removeFromSuperlayer];
        targetView.layer.mask = nil;
        return;
    }
    
    CALayer *_maskingLayer = [CALayer layer];
    CGRect f = targetView.bounds;
    UIEdgeInsets imageBleed = self.product.productTemplate.imageBleed;
    CGSize size = self.product.productTemplate.sizePx;
    
    if (CGSizeEqualToSize(size, CGSizeZero)){
        size = self.product.productTemplate.sizeCm;
    }
    
    UIEdgeInsets adjustedBleed = UIEdgeInsetsMake(f.size.height * imageBleed.top / size.height,
                                                  f.size.width * imageBleed.left / size.width,
                                                  f.size.height * imageBleed.bottom / size.height,
                                                  f.size.width * imageBleed.right / size.width);
    
    _maskingLayer.frame = CGRectMake(f.origin.x + adjustedBleed.left,
                                     f.origin.y + adjustedBleed.top,
                                     f.size.width - (adjustedBleed.left + adjustedBleed.right),
                                     f.size.height - (adjustedBleed.top + adjustedBleed.bottom));
    [_maskingLayer setContents:(id)[maskImage CGImage]];
    [targetView.layer setMask:_maskingLayer];
}

- (void)onButtonCropClicked:(UIButton *)sender{
    if ([self isUsingMultiplyBlend]){
        [self.cropView setGesturesEnabled:YES];
    }
    [self disableOverlay];
    for (UIView *view in self.cropFrameGuideViews){
        [self.printContainerView bringSubviewToFront:view];
    }
    sender.selected = YES;
    [UIView animateWithDuration:0.2 animations:^{
        for (UIView *textField in self.textFields){
            textField.alpha = 0;
        }
        for (UIView *view in self.cropFrameGuideViews){
            view.alpha = 1;
            [view.superview bringSubviewToFront:view];
            self.highlightsView.alpha = 0;
        }
        [self.view bringSubviewToFront:self.editingTools];
        [self.view bringSubviewToFront:self.editingTools.drawerView];
        self.editingTools.collectionView.tag = 40; // kOLEditTagCrop;
        
        self.editingTools.drawerHeightCon.constant = 80;
        [self.view layoutIfNeeded];
        [(UICollectionViewFlowLayout *)self.editingTools.collectionView.collectionViewLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
        
        [self.editingTools.collectionView reloadData];
        [self showDrawerWithCompletionHandler:NULL];
    } completion:^(BOOL finished){
        self.cropView.clipsToBounds = NO;
        [self maskWithImage:nil targetView:self.cropView];
        [self.view sendSubviewToBack:self.cropView];
    }];
}

- (void)exitCropMode{
    self.cropView.clipsToBounds = YES;
    [self maskWithImage:self.maskImage targetView:self.cropView];
    [self orderViews];
    for (UIView *view in self.cropFrameGuideViews){
        [self.printContainerView bringSubviewToFront:view];
    }
    [UIView animateWithDuration:0.2 animations:^{
        for (UIView *textField in self.textFields){
            textField.alpha = 1;
        }
        for (UIView *view in self.cropFrameGuideViews){
            view.alpha = 0;
            self.highlightsView.alpha = 1;
        }
    } completion:^(BOOL finished){
        [self renderImage];
        if ([self isUsingMultiplyBlend]){
            [self.cropView setGesturesEnabled:NO];
        }
    }];
}

-(void) doCheckout{
    if (!self.downloadedMask && self.product.productTemplate.maskImageURL) {
        return;
    }
    [super doCheckout];
}

- (void)renderImage{
    if (![self isUsingMultiplyBlend]){
        return;
    }
    
    self.highlightsView.hidden = NO;
    self.renderedImageView.image = nil;
    UIGraphicsBeginImageContextWithOptions(self.highlightsView.bounds.size, NO, [UIScreen mainScreen].scale);
    [self.highlightsView drawViewHierarchyInRect:self.highlightsView.bounds afterScreenUpdates:YES];
    UIImage *highlightsSnapshot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    UIGraphicsBeginImageContextWithOptions(self.printContainerView.bounds.size, NO, [UIScreen mainScreen].scale);
    [self.printContainerView drawViewHierarchyInRect:self.printContainerView.bounds afterScreenUpdates:YES];
    UIImage *productSnapshot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CIImage *filterImage = [CIImage imageWithCGImage:productSnapshot.CGImage];
    CIFilter *filter = [CIFilter filterWithName:@"CIMultiplyCompositing"];
    [filter setValue:filterImage forKey:@"inputBackgroundImage"];
    [filter setValue:[CIImage imageWithCGImage:highlightsSnapshot.CGImage] forKey:@"inputImage"];
    
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef cgImage = [context createCGImage:filter.outputImage fromRect:filterImage.extent];
    UIImage *renderedImage = [UIImage imageWithCGImage:cgImage];
    self.renderedImageView.image = renderedImage;
    
    self.renderedImageView.hidden = NO;
    self.highlightsView.hidden = YES;
}

#pragma mark - RMImageCropperDelegate methods

- (void)imageCropperDidTransformImage:(RMImageCropper *)imageCropper {
    self.ctaButton.enabled = YES;
    
    [self disableOverlay];
}

@end
