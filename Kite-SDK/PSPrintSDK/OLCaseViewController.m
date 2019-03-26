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

#import "OLImageDownloader.h"
#import "OLCaseViewController.h"
#import "OLImageCropper.h"
#import "UIImage+ImageNamedInKiteBundle.h"
#import "UIImage+OLUtils.h"
#import "OLUserSession.h"
#import "OLAsset+Private.h"
#import "UIImageView+FadeIn.h"
#import "OLPhotoTextField.h"
#import "OLKiteUtils.h"
#import "OLImagePickerViewController.h"
#import "NSDecimalNumber+CostFormatter.h"
#import "NSObject+Utils.h"
#import "OLKiteABTesting.h"
#import "UIView+AutoLayoutHelper.h"
#import "UIColor+OLHexString.h"
#import "UIViewController+OLMethods.h"

@interface OLProduct ()
- (NSString *)currencyCode;
@end

@interface OLSingleProductReviewViewController (Private) <UITextFieldDelegate>

- (UIEdgeInsets)imageInsetsOnContainer;
- (void)disableOverlay;
- (void)doCheckout;
- (void)loadImageFromAsset;
- (void)onButtonCropClicked:(UIButton *)sender;
- (void)onButtonDoneTapped:(id)sender;
- (void)onTapGestureRecognized:(id)sender;
- (void)saveEditsToAsset:(OLAsset *)asset;
- (void)showDrawerWithCompletionHandler:(void(^)(BOOL finished))handler;
@property (strong, nonatomic) UIView *safeAreaView;
@property (assign, nonatomic) BOOL showingBack;
@property (assign, nonatomic) CGAffineTransform backupTransform;
@property (strong, nonatomic) NSMutableArray *cropFrameGuideViews;
@property (strong, nonatomic) NSMutableArray<OLPhotoTextField *> *textFields;
@property (strong, nonatomic) OLImagePickerViewController *vcDelegateForCustomVc;
@property (strong, nonatomic) OLPhotoTextField *activeTextField;
@property (strong, nonatomic) UITextField *borderTextField;
@property (strong, nonatomic) UIView *textFieldsView;
@property (strong, nonatomic) UIViewController *presentedVc;
@property (weak, nonatomic) UIView *gestureView;
- (OLProductTemplateOptionChoice *)selectedChoice;
@property (weak, nonatomic) OLProductTemplateOption *selectedOption;
@property (strong, nonatomic) UIImage *fullImage;

@end

@interface OLCaseViewController ()
@property (assign, nonatomic) BOOL downloadedMask;
@property (strong, nonatomic) NSBlockOperation *viewDidAppearOperation;
@property (strong, nonatomic) NSOperation *downloadImagesOperation;
@property (strong, nonatomic) OLAsset *backAsset;
@property (strong, nonatomic) UIActivityIndicatorView *maskActivityIndicator;
@property (strong, nonatomic) UIButton *productFlipButton;
@property (strong, nonatomic) UIImage *maskImage;
@property (strong, nonatomic) UIImageView *renderedImageView;
@property (strong, nonatomic) UIVisualEffectView *caseVisualEffectView;
@end

@implementation OLCaseViewController

- (void)setActiveTextField:(OLPhotoTextField *)activeTextField{
    if ([self isUsingMultiplyBlend]){
        if (self.activeTextField && !activeTextField){
            [self renderImageWithCompletionHandler:NULL];
        }
        else if (activeTextField){
            [self disableOverlay];
        }
    }
    
    [super setActiveTextField:activeTextField];
}

- (void)viewDidLoad{
    if ([self isUsingMultiplyBlend]){
        self.viewDidAppearOperation = [NSBlockOperation blockOperationWithBlock:^{}];
    }
    
    [super viewDidLoad];
    
    self.printContainerView.backgroundColor = [self containerBackgroundColor];

    if (self.product.productTemplate.fulfilmentItems.count > 1){
        self.artboard.backgroundColor = [UIColor clearColor];
        
        self.productFlipButton = [[UIButton alloc] init];
        [self.view addSubview:self.productFlipButton];
        [self.productFlipButton setImage:[UIImage imageNamedInKiteBundle:@"flip-black"] forState:UIControlStateNormal];
        [self.productFlipButton addTarget:self action:@selector(onButtonProductFlipClicked:) forControlEvents:UIControlEventTouchUpInside];
        
        [self.productFlipButton.superview addConstraint:[NSLayoutConstraint constraintWithItem:self.productFlipButton attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.topLayoutGuide attribute:NSLayoutAttributeBottom multiplier:1 constant:15]];
        [self.productFlipButton leadingFromSuperview:15 relation:NSLayoutRelationEqual];
    }
}

- (void)setupContainerView{
    [super setupContainerView];
    
    if (self.product.productTemplate.maskImageURL){
        UIVisualEffect *blurEffect;
        blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        
        self.caseVisualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        [self.printContainerView insertSubview:self.caseVisualEffectView aboveSubview:self.artboard];
        
        [self.caseVisualEffectView fillSuperView];
        
        self.maskActivityIndicator = [[UIActivityIndicatorView alloc] init];
        self.maskActivityIndicator.color = [UIColor blackColor];
        [self.maskActivityIndicator startAnimating];
        self.maskActivityIndicator.hidesWhenStopped = YES;
        [self.printContainerView insertSubview:self.maskActivityIndicator aboveSubview:self.caseVisualEffectView];
        [self.maskActivityIndicator centerInSuperview];
    }
}

- (void)onTapGestureRecognized:(id)sender{
    if (!self.activeTextField){
        [self renderImageWithCompletionHandler:NULL];
    }
    [super onTapGestureRecognized:sender];
}

- (BOOL)isUsingMultiplyBlend{
    return self.product.productTemplate.blendMode == OLImageBlendModeMultiply;
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

- (NSURL *)maskURL{
    if (!self.showingBack){
        NSURL *url;
        for (OLFulfilmentItem *item in self.product.productTemplate.fulfilmentItems){
            if ([item.identifier isEqualToString:@"center_chest"] || [item.identifier isEqualToString:@"front_image"]){
                url = item.maskUrl;
            }
        }
        return url ? url : self.product.productTemplate.maskImageURL;
    }
    else{
        for (OLFulfilmentItem *item in self.product.productTemplate.fulfilmentItems){
            if ([item.identifier isEqualToString:@"center_back"] || [item.identifier isEqualToString:@"back_image"]){
                return item.maskUrl;
            }
        }
    }
    
    return nil;
}

- (NSURL *)productBackgroundURL{
    if (!self.showingBack){
        NSURL *url;
        for (OLFulfilmentItem *item in self.product.productTemplate.fulfilmentItems){
            if ([item.identifier isEqualToString:@"center_chest"] || [item.identifier isEqualToString:@"front_image"]){
                url = item.productBackGroundImageURL;
            }
        }
        return url ? url : self.product.productTemplate.productBackgroundImageURL;
    }
    else{
        for (OLFulfilmentItem *item in self.product.productTemplate.fulfilmentItems){
            if ([item.identifier isEqualToString:@"center_back"] || [item.identifier isEqualToString:@"back_image"]){
                return item.productBackGroundImageURL;
            }
        }
    }
    
    return nil;
}

- (NSURL *)productHighlightsURL{
    if (!self.showingBack){
        NSURL *url;
        for (OLFulfilmentItem *item in self.product.productTemplate.fulfilmentItems){
            if ([item.identifier isEqualToString:@"center_chest"] || [item.identifier isEqualToString:@"front_image"]){
                url = item.productHighlightsUrl;
            }
        }
        return url ? url : self.product.productTemplate.productHighlightsImageURL;
    }
    else{
        for (OLFulfilmentItem *item in self.product.productTemplate.fulfilmentItems){
            if ([item.identifier isEqualToString:@"center_back"] || [item.identifier isEqualToString:@"back_image"]){
                return item.productHighlightsUrl;
            }
        }
    }
    
    return nil;
}

- (void)setupProductRepresentation{
    self.downloadedMask = NO;
    
    self.downloadImagesOperation = [NSBlockOperation blockOperationWithBlock:^{}];
    
    if ([self maskURL]){
        NSOperation *op1 = [NSBlockOperation blockOperationWithBlock:^{}];
        [self.downloadImagesOperation addDependency:op1];
        
        [[OLImageDownloader sharedInstance] downloadImageAtURL:[self maskURL] withCompletionHandler:^(UIImage *image, NSError *error){
            [[NSOperationQueue mainQueue] addOperation:op1];
        }];
    }
    if ([self productHighlightsURL]){
        NSOperation *op2 = [NSBlockOperation blockOperationWithBlock:^{}];
        [self.downloadImagesOperation addDependency:op2];
        
        [[OLImageDownloader sharedInstance] downloadImageAtURL:[self productHighlightsURL] withCompletionHandler:^(UIImage *image, NSError *error){
            [[NSOperationQueue mainQueue] addOperation:op2];
        }];
    }
    
    if ([self productBackgroundURL]){
        NSOperation *op3 = [NSBlockOperation blockOperationWithBlock:^{}];
        [self.downloadImagesOperation addDependency:op3];
        
        [[OLImageDownloader sharedInstance] downloadImageAtURL:[self productBackgroundURL] withCompletionHandler:^(UIImage *image, NSError *error){
            [[NSOperationQueue mainQueue] addOperation:op3];
        }];
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

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
     [self addBasketIconToTopRight];
    
    if (!self.downloadedMask && self.product.productTemplate.maskImageURL){
        UIImage *tempMask = [UIImage imageNamedInKiteBundle:@"dummy mask"];
        [self.artboard removeConstraint:self.aspectRatioConstraint];
        NSLayoutConstraint *con = [NSLayoutConstraint constraintWithItem:self.artboard attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.artboard attribute:NSLayoutAttributeWidth multiplier:tempMask.size.height / tempMask.size.width constant:0];
        [self.artboard addConstraints:@[con]];
        self.aspectRatioConstraint = con;
        
        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];
        
        [self maskWithImage:tempMask targetView:self.artboard];
        
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    }
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    if (self.viewDidAppearOperation && !self.viewDidAppearOperation.finished){
        [[NSOperationQueue mainQueue] addOperation:self.viewDidAppearOperation];
    }
}

- (void)showHintViewIfNeeded{
    if ([OLAsset userSelectedAssets].nonPlaceholderAssets.count == 0  && !self.backAsset && self.hintView.alpha <= 0.1f) {
        [self showHintViewForView:self.editingTools.button1 header:NSLocalizedStringFromTableInBundle(@"Let's pick\nan image!", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Let's pick an image! The \n means there is a line break there. Please put it in the middle of the phrase, as best as you can. If one needs to be longer, it should be the first half.") body:NSLocalizedStringFromTableInBundle(@"Start by tapping this button", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"")delay:YES];
    }
}

- (void)onButtonDoneTapped:(UIButton *)sender{
    sender.enabled = NO;
    if ([OLAsset userSelectedAssets].nonPlaceholderAssets.count == 0 && !self.backAsset) {
        [self showHintViewForView:self.editingTools.button1 header:NSLocalizedStringFromTableInBundle(@"Let's pick\nan image!", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Let's pick an image! The \n means there is a line break there. Please put it in the middle of the phrase, as best as you can. If one needs to be longer, it should be the first half.") body:NSLocalizedStringFromTableInBundle(@"Start by tapping this button", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"")delay:NO];
        sender.enabled = YES;
        return;
    }
    
    [self doCheckout];
}

- (void)saveJobWithCompletionHandler:(void(^)(void))handler{
    [self saveEditsToAsset:self.asset];
    
    OLAsset *asset = [[OLAsset userSelectedAssets].nonPlaceholderAssets.firstObject copy];
    OLAsset *backAsset = [self.backAsset copy];
    if (!asset){
        asset = backAsset;
        backAsset = nil;
    }
    [asset dataLengthWithCompletionHandler:^(long long dataLength, NSError *error){
        if (dataLength < 40000){
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTableInBundle(@"Image Is Too Small", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") message:NSLocalizedStringFromTableInBundle(@"Please zoom out or pick a higher quality image", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"OK", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") style:UIAlertActionStyleDefault handler:NULL]];
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"Print It Anyway", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                [self saveEditsToAsset:self.asset];
                [self saveJobNowWithCompletionHandler:handler];
            }]];
            [self presentViewController:alert animated:YES completion:NULL];
            return;
            
        }
        
        [self.backAsset dataLengthWithCompletionHandler:^(long long dataLength, NSError *error){
            if (dataLength < 40000){
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTableInBundle(@"Back Image Is Too Small", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") message:NSLocalizedStringFromTableInBundle(@"Please zoom out or pick a higher quality image", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"OK", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") style:UIAlertActionStyleDefault handler:NULL]];
                [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"Print It Anyway", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                    [self saveEditsToAsset:self.asset];
                    [self saveJobNowWithCompletionHandler:handler];
                }]];
                [self presentViewController:alert animated:YES completion:NULL];
                return;
                
            }
        }];
        
        [self saveJobNowWithCompletionHandler:handler];
    }];
}

- (void)saveJobNowWithCompletionHandler:(void(^)(void))handler {
    if (self.product.productTemplate.collectionName && self.product.productTemplate.collectionId){
        NSString *templateId = self.product.selectedOptions[self.product.productTemplate.collectionId];
        if (templateId){
            OLProduct *product = [OLProduct productWithTemplateId:templateId];
            product.selectedOptions = self.product.selectedOptions;
            product.uuid = self.product.uuid;
            self.product = product;
        }
    }
    
    OLAsset *asset = [[OLAsset userSelectedAssets].nonPlaceholderAssets.firstObject copy];
    if (!asset){
        return;
    }
    
    
    OLProductPrintJob *job = [[OLProductPrintJob alloc] initWithTemplateId:self.product.templateId OLAssets:@[asset]];
    for (NSString *option in self.product.selectedOptions.allKeys){
        [job setValue:self.product.selectedOptions[option] forOption:option];
    }
    
    [[PhotobookSDK shared] addProductToBasket:job];
        
    if (handler){
        handler();
    }
}

- (UIColor *)containerBackgroundColor{
    return self.product.productTemplate.maskImageURL ? [UIColor clearColor] : [UIColor whiteColor];
}

- (void)orderViews{
    [self.view bringSubviewToFront:self.deviceView];
    [self.view bringSubviewToFront:self.printContainerView];
    [self.view bringSubviewToFront:self.artboard];
    [self.view bringSubviewToFront:self.textFieldsView];
    
    if (![self isUsingMultiplyBlend]){
        [self.view bringSubviewToFront:self.highlightsView];
    }
    else{
        [self.highlightsView.superview sendSubviewToBack:self.highlightsView];
        self.highlightsView.hidden = YES;
    }
    
    [self.view bringSubviewToFront:self.editingTools.drawerView];
    if (self.safeAreaView){
        [self.view bringSubviewToFront:self.safeAreaView];
    }
    [self.view bringSubviewToFront:self.editingTools];
    [self.view bringSubviewToFront:self.renderedImageView];
    [self.view bringSubviewToFront:self.hintView];
    [self.view bringSubviewToFront:self.gestureView];
    [self.view bringSubviewToFront:self.productFlipButton];
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
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context){
        [self.view layoutIfNeeded];
        [self maskWithImage:self.maskImage targetView:self.artboard];
    }completion:^(id <UIViewControllerTransitionCoordinatorContext> context){}];
}

- (void)applyDownloadedMask {
    if (self.downloadedMask){
        [self maskWithImage:self.maskImage targetView:self.artboard];
        return;
    }
    
    [[OLImageDownloader sharedInstance] downloadImageAtURL:self.product.productTemplate.maskImageURL priority:1 progress:NULL withCompletionHandler:^(UIImage *image, NSError *error){
        dispatch_async(dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            if (error) {
                UIAlertController *ac = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTableInBundle(@"Oops!", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") message:NSLocalizedStringFromTableInBundle(@"Failed to download phone case mask. Please check your internet connectivity and try again", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") preferredStyle:UIAlertControllerStyleAlert];
                [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"Cancel", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action){
                [self.navigationController popViewControllerAnimated:YES];
                }]];
                [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"Retry", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
                    [self applyDownloadedMask];
                }]];
                [self presentViewController:ac animated:YES completion:NULL];
            } else {
                [self.artboard removeConstraint:self.aspectRatioConstraint];
                NSLayoutConstraint *con = [NSLayoutConstraint constraintWithItem:self.artboard attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.artboard attribute:NSLayoutAttributeWidth multiplier:[self aspectRatio] constant:0];
                [self.artboard addConstraints:@[con]];
                
                [self.view setNeedsLayout];
                [self.view layoutIfNeeded];
                
                self.artboard.assetViews.firstObject.imageView.transform = self.edits.cropTransform;
                
                self.maskImage = [image shrinkToSize:[UIScreen mainScreen].bounds.size forScreenScale:[OLUserSession currentSession].screenScale];
                [self maskWithImage:self.maskImage targetView:self.artboard];
                
                [self applyProductImageLayers];
                
                self.caseVisualEffectView.hidden = YES;
                self.downloadedMask = YES;
                [self.maskActivityIndicator stopAnimating];
            }
        });
    }];
}

- (void)updateProductRepresentationForChoice:(OLProductTemplateOptionChoice *)choice{
    self.renderedImageView.image = nil;
    if (choice.color){
        self.deviceView.tintColor = choice.color;
        self.deviceView.image = [self.deviceView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [self renderImageWithCompletionHandler:NULL];
    }
    else{
        [self renderImageWithCompletionHandler:NULL];
    }
}

- (void) maskWithImage:(UIImage*) maskImage targetView:(UIView*) targetView{
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
    self.backupTransform = self.artboard.assetViews.firstObject.imageView.transform;
    self.editingTools.drawerDoneButton.hidden = YES;
    self.editingTools.halfWidthDrawerDoneButton.hidden = NO;
    self.editingTools.halfWidthDrawerCancelButton.hidden = NO;
    
    self.productFlipButton.enabled = NO;
    
    if ([self isUsingMultiplyBlend]){
        [self.artboard.assetViews.firstObject setGesturesEnabled:YES];
    }
    self.gestureView.userInteractionEnabled = YES;
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
        [self.view bringSubviewToFront:self.safeAreaView];
        [self.view bringSubviewToFront:self.editingTools.drawerView];
        self.editingTools.collectionView.tag = 40; // kOLEditTagCrop;
        
        self.editingTools.drawerHeightCon.constant = 80;
        [self.view layoutIfNeeded];
        [(UICollectionViewFlowLayout *)self.editingTools.collectionView.collectionViewLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
        
        [self.editingTools.collectionView reloadData];
        [self showDrawerWithCompletionHandler:NULL];
    } completion:^(BOOL finished){
        self.artboard.clipsToBounds = NO;
        [self maskWithImage:nil targetView:self.artboard];
        [self.view sendSubviewToBack:self.artboard];
    }];
}

- (void)exitCropMode{
    self.artboard.clipsToBounds = YES;
    [self maskWithImage:self.maskImage targetView:self.artboard];
    [self orderViews];
    for (UIView *view in self.cropFrameGuideViews){
        [self.printContainerView bringSubviewToFront:view];
    }
    self.gestureView.userInteractionEnabled = NO;
    self.productFlipButton.enabled = YES;
    [UIView animateWithDuration:0.2 animations:^{
        for (UIView *textField in self.textFields){
            textField.alpha = 1;
        }
        for (UIView *view in self.cropFrameGuideViews){
            view.alpha = 0;
            self.highlightsView.alpha = 1;
        }
    } completion:^(BOOL finished){
        [self renderImageWithCompletionHandler:NULL];
    }];
}

- (void)showExtraChargeHint{
    if (self.product.productTemplate.fulfilmentItems.count > 1){
        if ((self.showingBack && [OLAsset userSelectedAssets].nonPlaceholderAssets.firstObject && !self.backAsset) || (!self.showingBack && self.backAsset && ![OLAsset userSelectedAssets].nonPlaceholderAssets.firstObject)){
            for (OLFulfilmentItem *item in self.product.productTemplate.fulfilmentItems){
                if (((([item.identifier isEqualToString:@"center_back"] || [item.identifier isEqualToString:@"back_image"]) && self.showingBack) || (([item.identifier isEqualToString:@"center_chest"] || [item.identifier isEqualToString:@"front_image"]) && !self.showingBack)) && [item hasCostForCurrency:[self.product currencyCode]]){
                    [self showHintViewForView:self.editingTools.button1 header:NSLocalizedStringFromTableInBundle(@"Add a photo\non this side", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"this side [of the shirt]") body:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"For only %@ extra", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"[Add a photo on this side of the shirt] for only $4.00 extra"), [[item costForCurrency:self.product.currencyCode] formatCostForCurrencyCode:self.product.currencyCode]] delay:NO];
                }
            }
        }
    }
}

- (void)onButtonProductFlipClicked:(UIButton *)sender {
    self.productFlipButton.enabled = NO;
    UIActivityIndicatorView *aiv = [[UIActivityIndicatorView alloc] init];
    [self.view addSubview:aiv];
    aiv.translatesAutoresizingMaskIntoConstraints = NO;
    [aiv.superview addConstraint:[NSLayoutConstraint constraintWithItem:aiv attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:aiv.superview attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    [aiv.superview addConstraint:[NSLayoutConstraint constraintWithItem:aiv attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:aiv.superview attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
    [aiv startAnimating];
    
    [self saveEditsToAsset:self.asset];
    
    self.showingBack = !self.showingBack;
    
    if (self.showingBack){
        self.asset = self.backAsset;
    }
    else{
        self.asset = [OLAsset userSelectedAssets].nonPlaceholderAssets.firstObject;
    }
    
    
    __block UIImage *backgroundImage;
    __block UIImage *highlightsImage;
    
    NSBlockOperation *backgroundImageDownloadCompleteBlock = [NSBlockOperation blockOperationWithBlock:^{}];
    NSBlockOperation *highlightsImageDownloadCompleteBlock = [NSBlockOperation blockOperationWithBlock:^{}];
    NSBlockOperation *flipBlock = [NSBlockOperation blockOperationWithBlock:^{
        [aiv removeFromSuperview];
        [UIView transitionWithView:self.printContainerView duration:0.5 options:UIViewAnimationOptionTransitionFlipFromRight animations:^{
            for (OLPhotoTextField *tf in self.textFields){
                [tf removeFromSuperview];
                [self.textFields removeObject:tf];
            }
            self.activeTextField = nil;
            
            [self disableOverlay];
            
            self.artboard.assetViews.firstObject.imageView.image = nil;
            [self.asset unloadImage];
            self.edits = nil;
            self.fullImage = nil;
            
            self.renderedImageView.image = nil;
            [self loadImageFromAsset];
            
            self.deviceView.image = backgroundImage;
            self.highlightsView.image = highlightsImage;
            if (self.product.productTemplate.templateUI == OLTemplateUIApparel){
                for (OLProductTemplateOption *option in self.product.productTemplate.options){
                    if ([option.code isEqualToString:@"garment_color"]){
                        for (OLProductTemplateOptionChoice *choice in option.choices){
                            if ([choice.code isEqualToString:self.product.selectedOptions[option.code]]){
                                self.deviceView.tintColor = choice.color;
                                self.deviceView.image = [backgroundImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                            }
                        }
                    }
                }
            }
            
            
        }completion:^(BOOL finished){
            [self renderImageWithCompletionHandler:^{
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    self.productFlipButton.enabled = YES;
                });
            }];
            [self showExtraChargeHint];
        }];
    }];
    [flipBlock addDependency:backgroundImageDownloadCompleteBlock];
    [flipBlock addDependency:highlightsImageDownloadCompleteBlock];
    
    [[OLImageDownloader sharedInstance] downloadImageAtURL:[self productBackgroundURL] priority:1.0 progress:NULL withCompletionHandler:^(UIImage *image, NSError *error){
        backgroundImage = [image shrinkToSize:[UIScreen mainScreen].bounds.size forScreenScale:[OLUserSession currentSession].screenScale];
        [[NSOperationQueue mainQueue] addOperation:backgroundImageDownloadCompleteBlock];
    }];
    
    [[OLImageDownloader sharedInstance] downloadImageAtURL:[self productHighlightsURL] priority:1.0 progress:NULL withCompletionHandler:^(UIImage *image, NSError *error){
            highlightsImage = [image shrinkToSize:[UIScreen mainScreen].bounds.size forScreenScale:[OLUserSession currentSession].screenScale];
        [[NSOperationQueue mainQueue] addOperation:highlightsImageDownloadCompleteBlock];
    }];
    
    [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.hintView.alpha = 0;
    } completion:NULL];
    
    [[NSOperationQueue mainQueue] addOperation:flipBlock];    
}


- (void) doCheckout{
    if (!self.downloadedMask && self.product.productTemplate.maskImageURL) {
        return;
    }
    [super doCheckout];
}

- (void)renderImageWithCompletionHandler:(void (^)(void))handler {
    if (![self isUsingMultiplyBlend]  || self.maskActivityIndicator.isAnimating || [[[UIDevice currentDevice] systemVersion] floatValue] < 10 || self.presentedViewController){
        if (handler) handler();
        return;
    }

    self.highlightsView.layer.compositingFilter = @"multiplyBlendMode";
    [self.printContainerView insertSubview:self.highlightsView aboveSubview:self.artboard];
    [self.highlightsView fillSuperView];
    self.highlightsView.hidden = NO;
    if (handler) handler();
}

#pragma mark - RMImageCropperDelegate methods

- (void)imageCropperDidTransformImage:(RMImageCropper *)imageCropper {
    self.ctaButton.enabled = YES;
    
    [self disableOverlay];
}

@end
