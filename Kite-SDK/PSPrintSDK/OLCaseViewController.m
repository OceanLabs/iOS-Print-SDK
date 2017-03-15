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
#import "OLRemoteImageCropper.h"
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

@interface OLProduct ()
@property (strong, nonatomic) NSMutableSet <OLUpsellOffer *>*declinedOffers;
@property (strong, nonatomic) NSMutableSet <OLUpsellOffer *>*acceptedOffers;
@property (strong, nonatomic) OLUpsellOffer *redeemedOffer;
- (BOOL)hasOfferIdBeenUsed:(NSUInteger)identifier;
- (NSString *)currencyCode;
@end

@interface OLProductPrintJob ()
@property (strong, nonatomic) NSMutableSet <OLUpsellOffer *>*declinedOffers;
@property (strong, nonatomic) NSMutableSet <OLUpsellOffer *>*acceptedOffers;
@property (strong, nonatomic) OLUpsellOffer *redeemedOffer;
@end

@interface OLPrintOrder ()
- (void)saveOrder;
@end

@interface OLSingleImageProductReviewViewController (Private) <UITextFieldDelegate>

- (BOOL)shouldDoCheckout;
- (UIEdgeInsets)imageInsetsOnContainer;
- (void)disableOverlay;
- (void)doCheckout;
- (void)loadImageFromAsset;
- (void)onButtonCropClicked:(UIButton *)sender;
- (void)onButtonDoneTapped:(id)sender;
- (void)onTapGestureRecognized:(id)sender;
- (void)saveEditsToAsset:(OLAsset *)asset;
- (void)showDrawerWithCompletionHandler:(void(^)(BOOL finished))handler;
@property (assign, nonatomic) BOOL showingBack;
@property (assign, nonatomic) CGAffineTransform backupTransform;
@property (nonatomic, copy) void (^saveJobCompletionHandler)();
@property (strong, nonatomic) NSMutableArray *cropFrameGuideViews;
@property (strong, nonatomic) NSMutableArray<OLPhotoTextField *> *textFields;
@property (strong, nonatomic) OLImagePickerViewController *vcDelegateForCustomVc;
@property (strong, nonatomic) OLPhotoTextField *activeTextField;
@property (strong, nonatomic) UITextField *borderTextField;
@property (strong, nonatomic) UIView *textFieldsView;
@property (strong, nonatomic) UIViewController *presentedVc;
@property (weak, nonatomic) IBOutlet UIView *printContainerView;
@property (weak, nonatomic) UIView *gestureView;

@end

@interface OLCaseViewController ()
@property (assign, nonatomic) BOOL downloadedMask;
@property (strong, nonatomic) IBOutlet UIVisualEffectView *caseVisualEffectView;
@property (strong, nonatomic) NSBlockOperation *viewDidAppearOperation;
@property (strong, nonatomic) NSOperation *downloadImagesOperation;
@property (strong, nonatomic) OLAsset *backAsset;
@property (strong, nonatomic) UIImage *maskImage;
@property (strong, nonatomic) UIImageView *renderedImageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *centerYCon;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *maskActivityIndicator;
@property (weak, nonatomic) IBOutlet UIButton *productFlipButton;
@property (weak, nonatomic) IBOutlet UIImageView *deviceView;
@property (weak, nonatomic) IBOutlet UIImageView *highlightsView;
@property (strong, nonatomic) UIView *backgroundColorView;
@end

@implementation OLCaseViewController

- (void)setActiveTextField:(OLPhotoTextField *)activeTextField{
    if ([self isUsingMultiplyBlend]){
        if (self.activeTextField && !activeTextField){
            [self renderImage];
        }
        else if (activeTextField){
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
    
    if (self.product.productTemplate.fulfilmentItems.count < 2){
        [self.productFlipButton removeFromSuperview];
    }
    
    if (self.product.productTemplate.templateUI == OLTemplateUIApparel){
        self.backgroundColorView = [[UIView alloc] init];
        [self.printContainerView insertSubview:self.backgroundColorView aboveSubview:self.deviceView];
        [self.backgroundColorView fillSuperView];
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

- (NSURL *)maskURL{
    if (!self.showingBack){
        return self.product.productTemplate.maskImageURL;
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
        return self.product.productTemplate.productBackgroundImageURL;
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
        return self.product.productTemplate.productHighlightsImageURL;
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
    else{
        [self.caseVisualEffectView removeFromSuperview];
        [self.maskActivityIndicator stopAnimating];
    }
    if ([self productHighlightsURL]){
        NSOperation *op2 = [NSBlockOperation blockOperationWithBlock:^{}];
        [self.downloadImagesOperation addDependency:op2];
        
        [[OLImageDownloader sharedInstance] downloadImageAtURL:[self productHighlightsURL] withCompletionHandler:^(UIImage *image, NSError *error){
            [[NSOperationQueue mainQueue] addOperation:op2];
        }];
    }
    else{
        [self.highlightsView removeFromSuperview];
    }
    
    if ([self productBackgroundURL]){
        NSOperation *op3 = [NSBlockOperation blockOperationWithBlock:^{}];
        [self.downloadImagesOperation addDependency:op3];
        
        [[OLImageDownloader sharedInstance] downloadImageAtURL:[self productBackgroundURL] withCompletionHandler:^(UIImage *image, NSError *error){
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

- (void)showHintViewIfNeeded{
    if ([OLUserSession currentSession].userSelectedPhotos.count == 0  && !self.backAsset && self.hintView.alpha <= 0.1f) {
        [self showHintViewForView:self.editingTools.button1 header:NSLocalizedStringFromTableInBundle(@"Let's pick\nan image!", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Let's pick an image! The \n means there is a line break there. Please put it in the middle of the phrase, as best as you can. If one needs to be longer, it should be the first half.") body:NSLocalizedStringFromTableInBundle(@"Start by tapping this button", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"")delay:YES];
    }
}

- (void)onButtonDoneTapped:(id)sender{
    if ([OLUserSession currentSession].userSelectedPhotos.count != 0 && self.product.productTemplate.templateUI == OLTemplateUIApparel && !self.product.selectedOptions[@"garment_size"]) {
        [self showHintViewForView:self.editingTools.button2 header:NSLocalizedStringFromTableInBundle(@"Select Size", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Example: Shirt size") body:NSLocalizedStringFromTableInBundle(@"Tap on this button", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"")delay:NO];
        return;
    }
    
    if ([OLUserSession currentSession].userSelectedPhotos.count == 0 && !self.backAsset) {
        [self showHintViewForView:self.editingTools.button1 header:NSLocalizedStringFromTableInBundle(@"Let's pick\nan image!", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Let's pick an image! The \n means there is a line break there. Please put it in the middle of the phrase, as best as you can. If one needs to be longer, it should be the first half.") body:NSLocalizedStringFromTableInBundle(@"Start by tapping this button", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"")delay:NO];
        return;
    }
    
    if (![self shouldDoCheckout]){
        return;
    }
    
    [self saveJobWithCompletionHandler:^{
        if ([OLKiteABTesting sharedInstance].launchedWithPrintOrder && [[OLKiteABTesting sharedInstance].launchWithPrintOrderVariant isEqualToString:@"Review-Overview-Checkout"]){
            UIViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"OLProductOverviewViewController"];
            [vc safePerformSelector:@selector(setUserEmail:) withObject:[(OLKiteViewController *)vc userEmail]];
            [vc safePerformSelector:@selector(setUserPhone:) withObject:[(OLKiteViewController *)vc userPhone]];
            [vc safePerformSelector:@selector(setProduct:) withObject:self.product];
            [self.navigationController pushViewController:vc animated:YES];
        }
        else{
            OLPrintOrder *printOrder = [OLUserSession currentSession].printOrder;
            [OLKiteUtils checkoutViewControllerForPrintOrder:printOrder handler:^(id vc){
                [vc safePerformSelector:@selector(setUserEmail:) withObject:[OLKiteUtils userEmail:self]];
                [vc safePerformSelector:@selector(setUserPhone:) withObject:[OLKiteUtils userPhone:self]];
                
                [self.navigationController pushViewController:vc animated:YES];
            }];
        }
    }];
}

- (void)saveJobWithCompletionHandler:(void(^)())handler{
    [self saveEditsToAsset:self.asset];
    
    OLAsset *asset = [[OLUserSession currentSession].userSelectedPhotos.lastObject copy];
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
                    [self saveJobNowWithCompletionHandler:handler];
                }]];
                [self presentViewController:alert animated:YES completion:NULL];
                return;
                
            }
        }];
        
        [self saveJobNowWithCompletionHandler:handler];
    }];
}

- (void)saveJobNowWithCompletionHandler:(void(^)())handler {
    if (self.product.productTemplate.collectionName && self.product.productTemplate.collectionId){
        NSString *templateId = self.product.selectedOptions[self.product.productTemplate.collectionId];
        if (templateId){
            OLProduct *product = [OLProduct productWithTemplateId:templateId];
            product.selectedOptions = self.product.selectedOptions;
            product.uuid = self.product.uuid;
            self.product = product;
        }
    }
    
    OLAsset *asset = [[OLUserSession currentSession].userSelectedPhotos.lastObject copy];
    
    OLPrintOrder *printOrder = [OLUserSession currentSession].printOrder;
    OLProductPrintJob *job;
    if (self.product.productTemplate.templateUI == OLTemplateUIApparel){
        if (self.product.productTemplate.fulfilmentItems.count > 0){
            NSMutableDictionary *assetDict = [[NSMutableDictionary alloc] init];
            for (OLFulfilmentItem *item in self.product.productTemplate.fulfilmentItems){
                if (([item.identifier isEqualToString:@"center_chest"] || [item.identifier isEqualToString:@"front_image"]) && asset){
                    [assetDict setObject:asset forKey:item.identifier];
                }
                else if (([item.identifier isEqualToString:@"center_back"] || [item.identifier isEqualToString:@"back_image"]) && self.backAsset){
                    [assetDict setObject:[self.backAsset copy] forKey:item.identifier];
                }
            }
            job = [OLPrintJob apparelWithTemplateId:self.product.templateId OLAssets:assetDict];
            
        }
        else{
            job = [OLPrintJob apparelWithTemplateId:self.product.templateId OLAssets:@{
                                                                                       @"center_chest": asset,
                                                                                       }];
        }
    }
    else{
        job = [[OLProductPrintJob alloc] initWithTemplateId:self.product.templateId OLAssets:@[asset]];
    }
    for (NSString *option in self.product.selectedOptions.allKeys){
        [job setValue:self.product.selectedOptions[option] forOption:option];
    }
    NSArray *jobs = [NSArray arrayWithArray:printOrder.jobs];
    for (id<OLPrintJob> existingJob in jobs){
        if ([existingJob.uuid isEqualToString:self.product.uuid]){
            job.dateAddedToBasket = [existingJob dateAddedToBasket];
            job.extraCopies = existingJob.extraCopies;
            job.uuid = self.product.uuid;
            [printOrder removePrintJob:existingJob];
        }
    }
    [job.acceptedOffers addObjectsFromArray:self.product.acceptedOffers.allObjects];
    [job.declinedOffers addObjectsFromArray:self.product.declinedOffers.allObjects];
    job.redeemedOffer = self.product.redeemedOffer;
    self.product.uuid = job.uuid;
    self.editingPrintJob = job;
    [printOrder addPrintJob:self.editingPrintJob];
    
    [printOrder saveOrder];
    
    if (handler){
        handler();
    }
    
    self.saveJobCompletionHandler = nil;
}

- (UIColor *)containerBackgroundColor{
    return self.product.productTemplate.maskImageURL ? [UIColor clearColor] : [UIColor whiteColor];
}

- (void)orderViews{
    [self.view bringSubviewToFront:self.deviceView];
    [self.view bringSubviewToFront:self.printContainerView];
    [self.view bringSubviewToFront:self.cropView];
    [self.view bringSubviewToFront:self.textFieldsView];
    
    if (![self isUsingMultiplyBlend]){
        [self.view bringSubviewToFront:self.highlightsView];
    }
    else{
        [self.highlightsView.superview sendSubviewToBack:self.highlightsView];
        self.highlightsView.hidden = YES;
    }
    
    [self.view bringSubviewToFront:self.editingTools.drawerView];
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
        });
    }];
}

- (void)applyProductImageLayers{
    if (!self.deviceView.image){
        self.deviceView.alpha = 0;
        [[OLImageDownloader sharedInstance] downloadImageAtURL:self.product.productTemplate.productBackgroundImageURL priority:1.0 progress:NULL withCompletionHandler:^(UIImage *image, NSError *error){
            dispatch_async(dispatch_get_main_queue(), ^{
                self.deviceView.image = [image shrinkToSize:[UIScreen mainScreen].bounds.size forScreenScale:[OLUserSession currentSession].screenScale];
                [UIView animateWithDuration:0.1 animations:^{
                    self.deviceView.alpha = 1;
                } completion:^(BOOL finished){
                    [self renderImage];
                }];
            });
        }];
    }
    if (!self.highlightsView.image){
        self.highlightsView.alpha = 0;
        [[OLImageDownloader sharedInstance] downloadImageAtURL:self.product.productTemplate.productHighlightsImageURL priority:0.9 progress:NULL withCompletionHandler:^(UIImage *image, NSError *error){
            dispatch_async(dispatch_get_main_queue(), ^{
                self.highlightsView.image = [image shrinkToSize:[UIScreen mainScreen].bounds.size forScreenScale:[OLUserSession currentSession].screenScale];
                [UIView animateWithDuration:0.1 animations:^{
                    self.highlightsView.alpha = 1;
                }];
            });
        }];
    }
}

- (void)updateProductRepresentationForChoice:(OLProductTemplateOptionChoice *)choice{
    self.renderedImageView.image = nil;
    if (choice.color){
        self.cropView.hidden = NO;
        self.backgroundColorView.backgroundColor = choice.color;
        [self renderImage];
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
    self.backupTransform = self.cropView.imageView.transform;
    self.editingTools.drawerDoneButton.hidden = YES;
    self.editingTools.halfWidthDrawerDoneButton.hidden = NO;
    self.editingTools.halfWidthDrawerCancelButton.hidden = NO;
    
    self.productFlipButton.enabled = NO;
    
    if ([self isUsingMultiplyBlend]){
        [self.cropView setGesturesEnabled:YES];
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
        [self renderImage];
        if ([self isUsingMultiplyBlend]){
            [self.cropView setGesturesEnabled:NO];
        }
    }];
}

- (void)showExtraChargeHint{
    if (self.product.productTemplate.fulfilmentItems.count > 1){
        if ((self.showingBack && [OLUserSession currentSession].userSelectedPhotos.lastObject && !self.backAsset) || (!self.showingBack && self.backAsset && ![OLUserSession currentSession].userSelectedPhotos.lastObject)){
            for (OLFulfilmentItem *item in self.product.productTemplate.fulfilmentItems){
                if (((([item.identifier isEqualToString:@"center_back"] || [item.identifier isEqualToString:@"back_image"]) && self.showingBack) || (([item.identifier isEqualToString:@"center_chest"] || [item.identifier isEqualToString:@"front_image"]) && !self.showingBack)) && [item hasCostForCurrency:[self.product currencyCode]]){
                    [self showHintViewForView:self.editingTools.button1 header:NSLocalizedStringFromTableInBundle(@"Add a photo\non this side", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"this side [of the shirt]") body:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"For only %@ extra", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"[Add a photo on this side of the shirt] for only $4.00 extra"), [[item costForCurrency:self.product.currencyCode] formatCostForCurrencyCode:self.product.currencyCode]] delay:NO];
                }
            }
        }
    }
}

- (IBAction)onButtonProductFlipClicked:(UIButton *)sender {
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.hintView.alpha = 0;
    } completion:NULL];
    
    [self disableOverlay];
    
    [self saveEditsToAsset:self.asset];
    
    self.showingBack = !self.showingBack;
    
    if (self.showingBack){
        self.asset = self.backAsset;
    }
    else{
        self.asset = [OLUserSession currentSession].userSelectedPhotos.lastObject;
    }
    
    self.cropView.imageView.image = nil;
    self.edits = nil;
    self.fullImage = nil;
    
    [UIView transitionWithView:self.printContainerView duration:0.5 options:UIViewAnimationOptionTransitionFlipFromRight animations:^{
        [self setupProductRepresentation];
        [self loadImageFromAsset];
    }completion:^(BOOL finished){
        [self renderImage];
        [self showExtraChargeHint];
    }];
    
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackEditScreenButtonTapped:@"Product Flip"];
#endif
}


-(void) doCheckout{
    if (!self.downloadedMask && self.product.productTemplate.maskImageURL) {
        return;
    }
    [super doCheckout];
}

- (void)renderImage{
    if (![self isUsingMultiplyBlend]  || self.maskActivityIndicator.isAnimating || [[[UIDevice currentDevice] systemVersion] floatValue] < 10){
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

- (void)imagePicker:(OLImagePickerViewController *)vc didFinishPickingAssets:(NSMutableArray *)assets added:(NSArray<OLAsset *> *)addedAssets removed:(NSArray *)removedAssets{
    OLAsset *asset = addedAssets.lastObject;
    if (self.showingBack){
        self.backAsset = asset;
    }
    self.asset = asset;
    self.edits = [asset.edits copy];
    if (asset){
        if ([self.delegate respondsToSelector:@selector(scrollCropViewController:didReplaceAssetWithAsset:)]){
            [self.delegate scrollCropViewController:self didReplaceAssetWithAsset:asset];
        }
        
        self.ctaButton.enabled = YES;
        id view = [self.view viewWithTag:1010];
        if ([view isKindOfClass:[UIActivityIndicatorView class]]){
            [(UIActivityIndicatorView *)view startAnimating];
        }
        
        [self loadImageFromAsset];
    }
    
    if (self.presentedVc){
        [self.presentedVc dismissViewControllerAnimated:YES completion:^{
            [self updateProductRepresentationForChoice:nil];
        }];
    }
    else{
        [vc dismissViewControllerAnimated:YES completion:^{
            [self updateProductRepresentationForChoice:nil];
        }];
    }
    
    self.vcDelegateForCustomVc = nil;
    self.presentedVc = nil;
}

- (void)scrollCropViewController:(OLImageEditViewController *)cropper didReplaceAssetWithAsset:(OLAsset *)asset{
    if (!self.showingBack){
        [[OLUserSession currentSession].userSelectedPhotos addObject:asset];
    }
}

#pragma mark - RMImageCropperDelegate methods

- (void)imageCropperDidTransformImage:(RMImageCropper *)imageCropper {
    self.ctaButton.enabled = YES;
    
    [self disableOverlay];
}

@end
