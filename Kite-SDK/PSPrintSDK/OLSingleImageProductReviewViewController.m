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

#import "NSArray+QueryingExtras.h"
#import "NSObject+Utils.h"
#import "OLSingleImageProductReviewViewController.h"
#import "OLAnalytics.h"
#import "OLAsset+Private.h"
#import "OLProductPrintJob.h"
#import "OLAsset+Private.h"
#import "OLCustomPhotoProvider.h"
#import "OLImageCachingManager.h"
#import "OLKiteABTesting.h"
#import "OLKitePrintSDK.h"
#import "OLKiteUtils.h"
#import "OLUserSession.h"
#import "OLNavigationController.h"
#import "NSArray+QueryingExtras.h"
#import "OLKiteViewController.h"
#import "OLPaymentViewController.h"
#import "OLProductPrintJob.h"
#import "OLProductTemplateOption.h"
#import "OLRemoteImageView.h"
#import "OLRemoteImageCropper.h"
#import "OLAsset+Private.h"
#import "OLProductTemplateOption.h"
#import "OLPaymentViewController.h"
#import "UIViewController+OLMethods.h"
#import "OLSingleImageProductReviewViewController.h"
#import "OLUpsellViewController.h"
#import "OLImagePreviewViewController.h"
#import "OLImagePickerViewController.h"

@interface OLPaymentViewController (Private)
-(void)saveAndDismissReviewController;
@end

@interface OLPrintOrder (Private)
- (BOOL)hasOfferIdBeenUsed:(NSUInteger)identifier;
- (void)saveOrder;
@end

@interface OLImageEditViewController ()
- (void)orderViews;
- (void)onButtonClicked:(UIButton *)sender;
- (void)saveEditsToAsset:(OLAsset *)asset;
@end

@interface OLSingleImageProductReviewViewController () <OLUpsellViewControllerDelegate, OLScrollCropViewControllerDelegate>
@property (nonatomic, copy) void (^saveJobCompletionHandler)();
@end

@interface OLProduct ()
@property (strong, nonatomic) NSMutableSet <OLUpsellOffer *>*declinedOffers;
@property (strong, nonatomic) NSMutableSet <OLUpsellOffer *>*acceptedOffers;
@property (strong, nonatomic) OLUpsellOffer *redeemedOffer;
- (BOOL)hasOfferIdBeenUsed:(NSUInteger)identifier;
@end

@interface OLProductPrintJob ()
@property (strong, nonatomic) NSMutableSet <OLUpsellOffer *>*declinedOffers;
@property (strong, nonatomic) NSMutableSet <OLUpsellOffer *>*acceptedOffers;
@property (strong, nonatomic) OLUpsellOffer *redeemedOffer;
@end

@implementation OLSingleImageProductReviewViewController

- (OLAsset *)asset{
    if (!super.asset){
        super.asset = [OLUserSession currentSession].userSelectedPhotos.lastObject;
    }
    
    return super.asset;
}

- (CGFloat)aspectRatio{
    return 1.435714286;
}

-(void)viewDidLoad{
    [super viewDidLoad];
    
    self.delegate = self;
    
    self.title = NSLocalizedStringFromTableInBundle(@"Create Image", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"");
    
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackReviewScreenViewed:self.product.productTemplate.name];
#endif
    
    if ([OLKiteABTesting sharedInstance].launchedWithPrintOrder){
        if ([[OLKiteABTesting sharedInstance].launchWithPrintOrderVariant isEqualToString:@"Review-Overview-Checkout"]){
            [self.ctaButton setTitle:NSLocalizedStringFromTableInBundle(@"Next", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"") forState:UIControlStateNormal];
        }
        
        if(!self.editingPrintJob){
            self.editingPrintJob = [[OLUserSession currentSession].printOrder.jobs firstObject];
            self.product.uuid = self.editingPrintJob.uuid;
        }
    }
    
    [self.ctaButton setTitle:NSLocalizedStringFromTableInBundle(@"Next", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"") forState:UIControlStateNormal];
    if ([self.presentingViewController respondsToSelector:@selector(viewControllers)] || !self.presentingViewController) {
        UIViewController *paymentVc = [(UINavigationController *)self.presentingViewController viewControllers].lastObject;
        if ([paymentVc respondsToSelector:@selector(saveAndDismissReviewController)]){
            [self.ctaButton setTitle:NSLocalizedStringFromTableInBundle(@"Save", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"") forState:UIControlStateNormal];
            [self.ctaButton removeTarget:self action:@selector(onButtonDoneTapped:) forControlEvents:UIControlEventTouchUpInside];
            [self.ctaButton addTarget:paymentVc action:@selector(saveAndDismissReviewController) forControlEvents:UIControlEventTouchUpInside];
        }
    }
    
    self.ctaButton.enabled = YES;
    
    if ([OLKiteABTesting sharedInstance].lightThemeColor1){
        [self.ctaButton setBackgroundColor:[OLKiteABTesting sharedInstance].lightThemeColor1];
    }
    UIFont *font = [[OLKiteABTesting sharedInstance] lightThemeFont1WithSize:17];
    if (font){
        [self.ctaButton.titleLabel setFont:font];
    }
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Back", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"")
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:nil
                                                                            action:nil];
    
    [self.hintView viewWithTag:10].transform = CGAffineTransformMakeRotation(M_PI_4);
    
    self.hintView.layer.masksToBounds = NO;
    self.hintView.layer.shadowOffset = CGSizeMake(-5, -5);
    self.hintView.layer.shadowRadius = 5;
    self.hintView.layer.shadowOpacity = 0.3;
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    NSTimeInterval delay = 1;
    NSTimeInterval duration = 0.3;
    if ([OLUserSession currentSession].userSelectedPhotos.count == 0 && self.hintView.alpha <= 0.1f) {
        [UIView animateWithDuration:duration delay:delay options:UIViewAnimationOptionCurveEaseIn animations:^{
            self.hintView.alpha = 1;
        } completion:NULL];
    }
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    if ([self.presentingViewController respondsToSelector:@selector(viewControllers)]) {
        UIViewController *presentingVc = [(UINavigationController *)self.presentingViewController viewControllers].lastObject;
        if (![presentingVc isKindOfClass:[OLPaymentViewController class]]){
            [self addBasketIconToTopRight];
        }
    }
    else{
        [self addBasketIconToTopRight];
    }
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    
#ifndef OL_NO_ANALYTICS
    if (!self.navigationController){
        [OLAnalytics trackReviewScreenHitBack:self.product.productTemplate.name numberOfPhotos:[OLUserSession currentSession].userSelectedPhotos.count];
    }
#endif
}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    
    self.hintView.transform = CGAffineTransformMakeTranslation(self.editingTools.button1.frame.size.width / 2.0, 0);
}

- (void)orderViews{
    [super orderViews];
    [self.view bringSubviewToFront:self.hintView];
}

- (void)onButtonDoneTapped:(id)sender{
    if ([self shouldDoCheckout]){
        [self doCheckout];
    }
}

- (void)saveJobWithCompletionHandler:(void(^)())handler{
    [self saveEditsToAsset:self.asset];
    
    OLAsset *asset = [self.asset copy];
    [asset dataLengthWithCompletionHandler:^(long long dataLength, NSError *error){
        if (dataLength < 40000){
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Image Is Too Small", @"") message:NSLocalizedString(@"Please zoom out or pick a higher quality image", @"") preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"") style:UIAlertActionStyleDefault handler:NULL]];
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Print It Anyway", @"") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                [self saveJobNowWithCompletionHandler:handler];
            }]];
            [self presentViewController:alert animated:YES completion:NULL];
            return;
            
        }
        
        [self saveJobNowWithCompletionHandler:handler];
    }];
}

- (void)saveJobNowWithCompletionHandler:(void(^)())handler {
    OLAsset *asset = [self.asset copy];
    NSArray *assetArray = @[asset];
    
    OLPrintOrder *printOrder = [OLUserSession currentSession].printOrder;
    OLProductPrintJob *job = [[OLProductPrintJob alloc] initWithTemplateId:self.product.templateId OLAssets:assetArray];
    for (NSString *option in self.product.selectedOptions.allKeys){
        [job setValue:self.product.selectedOptions[option] forOption:option];
    }
    NSArray *jobs = [NSArray arrayWithArray:printOrder.jobs];
    for (id<OLPrintJob> existingJob in jobs){
        if ([existingJob.uuid isEqualToString:self.product.uuid]){
            job.dateAddedToBasket = [existingJob dateAddedToBasket];
            if ([existingJob extraCopies] > 0){
                [existingJob setExtraCopies:[existingJob extraCopies]-1];
            }
            else{
                [printOrder removePrintJob:existingJob];
            }
            job.uuid = self.product.uuid;
        }
    }
    [job.acceptedOffers addObjectsFromArray:self.product.acceptedOffers.allObjects];
    [job.declinedOffers addObjectsFromArray:self.product.declinedOffers.allObjects];
    job.redeemedOffer = self.product.redeemedOffer;
    self.product.uuid = job.uuid;
    self.editingPrintJob = job;
    if ([printOrder.jobs containsObject:self.editingPrintJob]){
        id<OLPrintJob> existingJob = printOrder.jobs[[printOrder.jobs indexOfObject:self.editingPrintJob]];
        [existingJob setExtraCopies:[existingJob extraCopies]+1];
    }
    else{
        [printOrder addPrintJob:self.editingPrintJob];
    }
    
    [printOrder saveOrder];
    
    if (handler){
        handler();
    }
    
    self.saveJobCompletionHandler = nil;
}

- (BOOL)shouldDoCheckout{
    OLUpsellOffer *offer = [self upsellOfferToShow];
    BOOL shouldShowOffer = offer != nil;
    if (offer){
        shouldShowOffer &= offer.minUnits <= [OLUserSession currentSession].userSelectedPhotos.count;
        shouldShowOffer &= [OLProduct productWithTemplateId:offer.offerTemplate] != nil;
    }
    if (shouldShowOffer){
        OLUpsellViewController *c = [self.storyboard instantiateViewControllerWithIdentifier:@"OLUpsellViewController"];
        c.providesPresentationContextTransitionStyle = true;
        c.definesPresentationContext = true;
        c.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        c.delegate = self;
        c.offer = offer;
        c.triggeredProduct = self.product;
        [self presentViewController:c animated:NO completion:NULL];
        return NO;
    }
    else{
        return YES;
    }
}

- (OLUpsellOffer *)upsellOfferToShow{
    NSArray *upsells = self.product.productTemplate.upsellOffers;
    if (upsells.count == 0){
        return nil;
    }
    
    OLUpsellOffer *offerToShow;
    for (OLUpsellOffer *offer in upsells){
        //Check if offer is valid for this point
        if (offer.active && offer.type == OLUpsellOfferTypeItemAdd){
            
            if ([self.product hasOfferIdBeenUsed:offer.identifier]){
                continue;
            }
            if ([[OLUserSession currentSession].printOrder hasOfferIdBeenUsed:offer.identifier]){
                continue;
            }
            
            //Find the max priority offer
            if (!offerToShow || offerToShow.priority < offer.priority){
                offerToShow = offer;
            }
        }
    }
    
    return offerToShow;
}

-(void) doCheckout{
    if (!self.cropView.image) {
        NSTimeInterval duration = 0.3;
        [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            self.hintView.alpha = 1;
        } completion:NULL];
        return;
    }
    
    [self saveJobWithCompletionHandler:^{
        if ([OLKiteABTesting sharedInstance].launchedWithPrintOrder && [[OLKiteABTesting sharedInstance].launchWithPrintOrderVariant isEqualToString:@"Review-Overview-Checkout"]){
            UIViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"OLProductOverviewViewController"];
            [vc safePerformSelector:@selector(setUserEmail:) withObject:[(OLKiteViewController *)vc userEmail]];
            [vc safePerformSelector:@selector(setUserPhone:) withObject:[(OLKiteViewController *)vc userPhone]];
            [vc safePerformSelector:@selector(setKiteDelegate:) withObject:self.delegate];
            [vc safePerformSelector:@selector(setProduct:) withObject:self.product];
            [self.navigationController pushViewController:vc animated:YES];
        }
        else{
            OLPrintOrder *printOrder = [OLUserSession currentSession].printOrder;
            [OLKiteUtils checkoutViewControllerForPrintOrder:printOrder handler:^(id vc){
                [vc safePerformSelector:@selector(setUserEmail:) withObject:[OLKiteUtils userEmail:self]];
                [vc safePerformSelector:@selector(setUserPhone:) withObject:[OLKiteUtils userPhone:self]];
                [vc safePerformSelector:@selector(setKiteDelegate:) withObject:[OLKiteUtils kiteDelegate:self]];
                
                [self.navigationController pushViewController:vc animated:YES];
            }];
        }
    }];
}

- (void)onButtonCropClicked:(UIButton *)sender{
    sender.selected = YES;
    [self.cropView setGesturesEnabled:YES];
}

- (void)exitCropMode{
    [self.cropView setGesturesEnabled:NO];
}

- (void)onButtonClicked:(UIButton *)sender {
    NSTimeInterval duration = 0.3;
    [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.hintView.alpha = 0;
    } completion:NULL];
    
    [super onButtonClicked:sender];
}

- (void)scrollCropViewController:(OLImageEditViewController *)cropper didReplaceAssetWithAsset:(OLAsset *)asset{
    [[OLUserSession currentSession].userSelectedPhotos addObject:asset];
}

- (void)scrollCropViewController:(OLImageEditViewController *)cropper didFinishCroppingImage:(UIImage *)croppedImage{
    //Do nothing
}

#pragma mark OLUpsellViewControllerDelegate

- (void)userDidDeclineUpsell:(OLUpsellViewController *)vc{
    [self.product.declinedOffers addObject:vc.offer];
    [vc dismissViewControllerAnimated:NO completion:^{
        [self doCheckout];
    }];
}

- (id<OLPrintJob>)addItemToBasketWithTemplateId:(NSString *)templateId{
    OLProduct *offerProduct = [OLProduct productWithTemplateId:templateId];
    NSMutableArray *assets = [[NSMutableArray alloc] init];
    if (offerProduct.productTemplate.templateUI == kOLTemplateUINonCustomizable){
        //Do nothing, no assets needed
    }
    else if (offerProduct.quantityToFulfillOrder == 1){
        [assets addObject:[[OLUserSession currentSession].userSelectedPhotos.firstObject copy]];
    }
    else{
        for (OLAsset *photo in [OLUserSession currentSession].userSelectedPhotos){
            [assets addObject:[photo copy]];
        }
    }
    
    id<OLPrintJob> job;
    if ([OLProductTemplate templateWithId:templateId].templateUI == kOLTemplateUIPhotobook){
        job = [OLPrintJob photobookWithTemplateId:templateId OLAssets:assets frontCoverOLAsset:nil backCoverOLAsset:nil];
    }
    else{
        job = [OLPrintJob printJobWithTemplateId:templateId OLAssets:assets];
    }
    
    [[OLUserSession currentSession].printOrder addPrintJob:job];
    return job;
}

- (void)userDidAcceptUpsell:(OLUpsellViewController *)vc{
    [self.product.acceptedOffers addObject:vc.offer];
    [vc dismissViewControllerAnimated:NO completion:^{
        if (vc.offer.prepopulatePhotos){
            id<OLPrintJob> job = [self addItemToBasketWithTemplateId:vc.offer.offerTemplate];
            [(OLProductPrintJob *)job setRedeemedOffer:vc.offer];
            [self doCheckout];
        }
        else{
            [self saveJobWithCompletionHandler:^{
                OLProduct *offerProduct = [OLProduct productWithTemplateId:vc.offer.offerTemplate];
                UIViewController *nextVc = [self.storyboard instantiateViewControllerWithIdentifier:[OLKiteUtils reviewViewControllerIdentifierForProduct:offerProduct photoSelectionScreen:[OLKiteUtils imageProvidersAvailable:self]]];
                [nextVc safePerformSelector:@selector(setKiteDelegate:) withObject:self.delegate];
                [nextVc safePerformSelector:@selector(setProduct:) withObject:offerProduct];
                NSMutableArray *stack = [self.navigationController.viewControllers mutableCopy];
                [stack removeObject:self];
                [stack addObject:nextVc];
                [self.navigationController setViewControllers:stack animated:YES];
            }];
        }
    }];
}


@end
