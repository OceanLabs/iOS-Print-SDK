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

#import "NSObject+Utils.h"
#import "OLAnalytics.h"
#import "OLAsset+Private.h"
#import "OLImageCachingManager.h"
#import "OLImagePickerViewController.h"
#import "OLKiteABTesting.h"
#import "OLKitePrintSDK.h"
#import "OLKiteUtils.h"
#import "OLKiteViewController.h"
#import "OLNavigationController.h"
#import "OLPaymentViewController.h"
#import "OLProductPrintJob.h"
#import "OLProductTemplateOption.h"
#import "OLImageCropper.h"
#import "OLImageView.h"
#import "OLSingleProductReviewViewController.h"
#import "OLUpsellViewController.h"
#import "OLUserSession.h"
#import "UIViewController+OLMethods.h"
#import "UIView+AutoLayoutHelper.h"
#import "UIColor+OLHexString.h"
#import "OLKiteViewController+Private.h"

@interface OLPaymentViewController (Private)
- (void)saveAndDismissReviewController:(UIButton *)button;
@end

@interface OLPrintOrder (Private)
- (BOOL)hasOfferIdBeenUsed:(NSUInteger)identifier;
- (void)saveOrder;
@end

@interface OLImageEditViewController ()
- (void)orderViews;
- (void)onButtonClicked:(UIButton *)sender;
- (void)saveEditsToAsset:(OLAsset *)asset;
- (void)loadImageFromAsset;
- (void)updateProductRepresentationForChoice:(OLProductTemplateOptionChoice *)choice;
@property (strong, nonatomic) UIViewController *presentedVc;
@end

@interface OLSingleProductReviewViewController () <OLUpsellViewControllerDelegate, OLImageEditViewControllerDelegate>
@property (assign, nonatomic) BOOL showingBack;
@property (strong, nonatomic) OLAsset *backAsset;
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

@implementation OLSingleProductReviewViewController

- (OLAsset *)asset{
    if (!super.asset && !self.showingBack){
        super.asset = [[OLAsset userSelectedAssets] nonPlaceholderAssets].firstObject;
    }
    
    return super.asset;
}

- (CGFloat)aspectRatio{
    return 1.435714286;
}

- (void)viewDidLoad{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor colorWithHexString:@"E7EBEF"];
    self.printContainerView.backgroundColor = [UIColor clearColor];
    
    self.delegate = self;
    self.view.clipsToBounds = YES;
    
    if (self.navigationController.viewControllers.firstObject == self){
        self.title = self.product.productTemplate.name;
    }
    else{
        self.title = NSLocalizedStringFromTableInBundle(@"Create Image", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"");
    }
    
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackReviewScreenViewed:self.product.productTemplate.name];
#endif
    
    if ([OLKiteABTesting sharedInstance].launchedWithPrintOrder){
        if ([[OLKiteABTesting sharedInstance].launchWithPrintOrderVariant isEqualToString:@"Review-Overview-Checkout"]){
            [self.ctaButton setTitle:NSLocalizedStringFromTableInBundle(@"Next", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") forState:UIControlStateNormal];
        }
    }
    
    [self.ctaButton setTitle:NSLocalizedStringFromTableInBundle(@"Next", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") forState:UIControlStateNormal];
    if ([self.presentingViewController respondsToSelector:@selector(viewControllers)] || !self.presentingViewController) {
        UIViewController *paymentVc = [(UINavigationController *)self.presentingViewController viewControllers].lastObject;
        if ([paymentVc respondsToSelector:@selector(saveAndDismissReviewController:)]){
            [self.ctaButton setTitle:NSLocalizedStringFromTableInBundle(@"Save", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") forState:UIControlStateNormal];
            [self.ctaButton removeTarget:self action:@selector(onButtonDoneTapped:) forControlEvents:UIControlEventTouchUpInside];
            [self.ctaButton addTarget:paymentVc action:@selector(saveAndDismissReviewController:) forControlEvents:UIControlEventTouchUpInside];
        }
    }
    
    self.ctaButton.enabled = YES;
    
    UIFont *font = [[OLKiteABTesting sharedInstance] lightThemeHeavyFont1WithSize:17];
    if (!font){
        font = [[OLKiteABTesting sharedInstance] lightThemeFont1WithSize:17];
    }
    if (font){
        [self.ctaButton.titleLabel setFont:font];
    }
    
    if ([OLUserSession currentSession].capitalizeCtaTitles){
        [self.ctaButton setTitle:[[self.ctaButton titleForState:UIControlStateNormal] uppercaseString] forState:UIControlStateNormal];
    }
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[OLKiteABTesting sharedInstance].backButtonText
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:nil
                                                                            action:nil];
    
    self.hintView = [[[OLKiteUtils kiteResourcesBundle] loadNibNamed:@"OLHintView" owner:self options:nil] objectAtIndex:0];
    self.hintView.alpha = 0;
    self.hintView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.hintView];
    
    [self.hintView.superview addConstraint:[NSLayoutConstraint constraintWithItem:self.hintView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:self.hintView.superview attribute:NSLayoutAttributeLeading multiplier:1 constant:5]];
    [self.hintView.superview addConstraint:[NSLayoutConstraint constraintWithItem:self.hintView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationLessThanOrEqual toItem:self.hintView.superview attribute:NSLayoutAttributeTrailing multiplier:1 constant:-5]];
    [self.hintView.superview addConstraint:[NSLayoutConstraint constraintWithItem:self.hintView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.editingTools attribute:NSLayoutAttributeTop multiplier:1 constant:-15]];
    [self.hintView setContentHuggingPriority:1000 forAxis:UILayoutConstraintAxisHorizontal];
    [self.hintView setContentCompressionResistancePriority:1000 forAxis:UILayoutConstraintAxisHorizontal];
    
    [self.hintView viewWithTag:10].transform = CGAffineTransformMakeRotation(M_PI_4);
    
    self.hintView.layer.masksToBounds = NO;
    self.hintView.layer.shadowOffset = CGSizeMake(0, 2);
    self.hintView.layer.shadowRadius = 5;
    self.hintView.layer.shadowOpacity = 0.3;
}

- (void)showHintViewForView:(UIView *)view header:(NSString *)header body:(NSString *)body delay:(BOOL)shouldDelay{
    if (!self.hintView){
        return;
    }
    for (NSLayoutConstraint *con in self.view.constraints){
        if ([con.identifier isEqualToString:@"toolBarCon"]){
            [self.view removeConstraint:con];
        }
    }
    NSLayoutConstraint *con = [NSLayoutConstraint constraintWithItem:[self.hintView viewWithTag:10] attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeCenterX multiplier:1 constant:0];
    con.identifier = @"toolBarCon";
    [self.view addConstraint:con];
    
    if (header){
        UILabel *label = (UILabel *)[self.hintView viewWithTag:20];
        [label setText:header];
        
        UIFont *font = [[OLKiteABTesting sharedInstance] lightThemeHeavyFont1WithSize:25];
        if (!font){
            font = [[OLKiteABTesting sharedInstance] lightThemeFont1WithSize:25];
        }
        
        if (font){
            [label setFont:font];
        }
    }
    if (body){
        UILabel *label = (UILabel *)[self.hintView viewWithTag:30];
        [label setText:body];
        
        UIFont *font = [[OLKiteABTesting sharedInstance] lightThemeFont1WithSize:13];
        if (font){
            [label setFont:font];
        }
    }
    
    NSTimeInterval delay = shouldDelay ? 1 : 0;
    NSTimeInterval duration = 0.3;
    [UIView animateWithDuration:duration delay:delay options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.hintView.alpha = 1;
    } completion:NULL];
}

- (void)viewWillAppear:(BOOL)animated{
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

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    [self showHintViewIfNeeded];
}

- (void)showHintViewIfNeeded{
    if ([OLAsset userSelectedAssets].nonPlaceholderAssets.count == 0 && self.hintView.alpha <= 0.1f) {
        [self showHintViewForView:self.editingTools.button1 header:NSLocalizedStringFromTableInBundle(@"Let's pick\nan image!", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Let's pick an image! The \n means there is a line break there. Please put it in the middle of the phrase, as best as you can. If one needs to be longer, it should be the first half.") body:NSLocalizedStringFromTableInBundle(@"Start by tapping this button", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"")delay:YES];
    }
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    
#ifndef OL_NO_ANALYTICS
    if (!self.navigationController){
        [OLAnalytics trackReviewScreenHitBack:self.product.productTemplate.name numberOfPhotos:[OLAsset userSelectedAssets].nonPlaceholderAssets.count];
    }
#endif
}

- (void)orderViews{
    [super orderViews];
    [self.view bringSubviewToFront:self.hintView];
}

- (void)onButtonDoneTapped:(UIButton *)sender{
    if ([self shouldDoCheckout]){
        sender.enabled = NO;
        [self doCheckout];
    }
}

- (void)saveJobWithCompletionHandler:(void(^)(void))handler{
    [self saveEditsToAsset:self.asset];
    OLAsset *asset = [self.asset copy];
    
    [asset dataLengthWithCompletionHandler:^(long long dataLength, NSError *error){
        if (dataLength < 40000){
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTableInBundle(@"Image Is Too Small", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") message:NSLocalizedStringFromTableInBundle(@"Please zoom out or pick a higher quality image", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"OK", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Acknowledgent to an alert dialog.") style:UIAlertActionStyleDefault handler:NULL]];
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"Print It Anyway", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                [self saveEditsToAsset:self.asset];
                [self saveJobNowWithCompletionHandler:handler];
            }]];
            [self presentViewController:alert animated:YES completion:NULL];
            return;
            
        }
        
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
    
    OLAsset *asset = [self.asset copy];
    NSArray *assetArray = @[asset];
    
    BOOL fromEdit = NO;
    
    OLPrintOrder *printOrder = [OLUserSession currentSession].printOrder;
    OLProductPrintJob *job;
    job = [[OLProductPrintJob alloc] initWithTemplateId:self.product.templateId OLAssets:assetArray];
    for (NSString *option in self.product.selectedOptions.allKeys){
        [job setValue:self.product.selectedOptions[option] forOption:option];
    }
    NSArray *jobs = [NSArray arrayWithArray:printOrder.jobs];
    for (id<OLPrintJob> existingJob in jobs){
        if ([existingJob.uuid isEqualToString:self.product.uuid]){
            job.dateAddedToBasket = [existingJob dateAddedToBasket];
            job.extraCopies = existingJob.extraCopies;
            [printOrder removePrintJob:existingJob];
            fromEdit = YES;
        }
    }
    [job.acceptedOffers addObjectsFromArray:self.product.acceptedOffers.allObjects];
    [job.declinedOffers addObjectsFromArray:self.product.declinedOffers.allObjects];
    job.redeemedOffer = self.product.redeemedOffer;
    [printOrder addPrintJob:job];
#ifndef OL_NO_ANALYTICS
    if (!fromEdit){
        [OLAnalytics trackItemAddedToBasket:job];
    }
#endif
    
    [printOrder saveOrder];
    
    if (handler){
        handler();
    }    
}

- (BOOL)shouldDoCheckout{
    OLUpsellOffer *offer = [self upsellOfferToShow];
    BOOL shouldShowOffer = offer != nil;
    if (offer){
        shouldShowOffer &= offer.minUnits <= [OLAsset userSelectedAssets].nonPlaceholderAssets.count;
        shouldShowOffer &= [OLProduct productWithTemplateId:offer.offerTemplate] != nil;
    }
    if (shouldShowOffer){
        OLUpsellViewController *c = [[OLUserSession currentSession].kiteVc.storyboard instantiateViewControllerWithIdentifier:@"OLUpsellViewController"];
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

- (void) doCheckout{
    if ([OLAsset userSelectedAssets].nonPlaceholderAssets.count == 0) {
        if (self.hintView){
            [self showHintViewForView:self.editingTools.button1 header:NSLocalizedStringFromTableInBundle(@"Let's pick\nan image!", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Let's pick an image! The \n means there is a line break there. Please put it in the middle of the phrase, as best as you can. If one needs to be longer, it should be the first half.") body:NSLocalizedStringFromTableInBundle(@"Start by tapping this button", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"")delay:NO];
        }
        else{
            UIAlertController *av = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTableInBundle(@"Oops!", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") message:NSLocalizedStringFromTableInBundle(@"Please add some photos", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") preferredStyle:UIAlertControllerStyleAlert];
            [av addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"OK", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Acknowledgent to an alert dialog.") style:UIAlertActionStyleDefault handler:NULL]];
            [self presentViewController:av animated:YES completion:NULL];
        }
        return;
    }
    [self saveJobWithCompletionHandler:^{
        if ([OLKiteABTesting sharedInstance].launchedWithPrintOrder && [[OLKiteABTesting sharedInstance].launchWithPrintOrderVariant isEqualToString:@"Review-Overview-Checkout"]){
            // The `self.storybard` may be nil if it was not initialized from storyboard.
            // eg. Review page for phonecase (OLCaseViewController). see. OLKiteViewController.m L264
            UIStoryboard *storyboard = self.storyboard ?: [OLUserSession currentSession].kiteVc.storyboard;
            UIViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"OLProductOverviewViewController"];
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

- (void)onButtonClicked:(UIButton *)sender {
    NSTimeInterval duration = 0.3;
    [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.hintView.alpha = 0;
    } completion:NULL];
    
    [super onButtonClicked:sender];
}

- (void)imageEditViewController:(OLImageEditViewController *)cropper didReplaceAssetWithAsset:(OLAsset *)asset{
    [[OLAsset userSelectedAssets] replaceObjectAtIndex:[[OLAsset userSelectedAssets] indexOfObjectIdenticalTo:self.asset] withObject:asset];
}

- (void)imageEditViewController:(OLImageEditViewController *)cropper didFinishCroppingImage:(UIImage *)croppedImage{
    //Do nothing
}

- (void)imagePicker:(OLImagePickerViewController *)vc didFinishPickingAssets:(NSMutableArray *)assets added:(NSArray<OLAsset *> *)addedAssets removed:(NSArray *)removedAssets{
    OLAsset *asset = [addedAssets.firstObject copy];
    self.edits = [asset.edits copy];
    
    NSInteger assetIndex = 0;
    if (self.showingBack){
        self.backAsset = asset;
        assetIndex = 1;
    }
    if (asset) {
        self.asset = asset;
        
        if ([OLAsset userSelectedAssets].count > assetIndex && vc.maximumPhotos == 1){
            [[OLAsset userSelectedAssets] replaceObjectAtIndex:assetIndex withObject:asset];
        }
        else{
            [[OLAsset userSelectedAssets] addObject:asset];
        }
        
        self.ctaButton.enabled = YES;
        id view = [self.view viewWithTag:1010];
        if ([view isKindOfClass:[UIActivityIndicatorView class]]){
            [(UIActivityIndicatorView *)view startAnimating];
        }
        
        [self loadImageFromAsset];
    }
    
    if (self.presentedVc){
        [self.presentedVc dismissViewControllerAnimated:YES completion:NULL];
    }
    else{
        [vc dismissViewControllerAnimated:YES completion:NULL];
    }
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
    if (offerProduct.productTemplate.templateUI == OLTemplateUINonCustomizable){
        //Do nothing, no assets needed
    }
    else if (offerProduct.quantityToFulfillOrder == 1){
        [assets addObject:[[OLAsset userSelectedAssets].nonPlaceholderAssets.firstObject copy]];
    }
    else{
        for (OLAsset *photo in [OLAsset userSelectedAssets]){
            [assets addObject:[photo copy]];
        }
    }
    
    id<OLPrintJob> job;
    if ([OLProductTemplate templateWithId:templateId].templateUI == OLTemplateUIPhotobook){
        job = [OLPrintJob photobookWithTemplateId:templateId OLAssets:assets frontCoverOLAsset:nil backCoverOLAsset:nil];
    }
    else{
        job = [OLPrintJob printJobWithTemplateId:templateId OLAssets:assets];
    }
    
    [[OLUserSession currentSession].printOrder addPrintJob:job];
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackItemAddedToBasket:job];
#endif
    return job;
}

- (void)userDidAcceptUpsell:(OLUpsellViewController *)vc{
    //Drop previous screens from the navigation stack
    NSMutableArray *navigationStack = self.navigationController.viewControllers.mutableCopy;
    if (navigationStack.count > 1) {
        NSMutableArray *viewControllers = [[NSMutableArray alloc] init];
        for (UIViewController *vc in self.navigationController.viewControllers){
            [viewControllers addObject:vc];
            if ([vc isKindOfClass:[OLKiteViewController class]]){
                [viewControllers addObject:self];
                [self.navigationController setViewControllers:viewControllers animated:YES];
                break;
            }
        }
        [self.navigationController setViewControllers:@[navigationStack.firstObject, self] animated:NO];
    }
    
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
                UIViewController *nextVc = [[OLUserSession currentSession].kiteVc reviewViewControllerForProduct:offerProduct photoSelectionScreen:[OLKiteUtils imageProvidersAvailable]];
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
