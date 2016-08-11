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

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

@interface OLPaymentViewController (Private)
-(void)saveAndDismissReviewController;
@end

@interface OLPrintOrder (Private)
- (BOOL)hasOfferIdBeenUsed:(NSUInteger)identifier;
- (void)saveOrder;
@end

@interface OLKiteViewController ()
- (void)dismiss;
@end

@interface OLKitePrintSDK (InternalUtils)
#ifdef OL_KITE_OFFER_INSTAGRAM
+ (NSString *) instagramRedirectURI;
+ (NSString *) instagramSecret;
+ (NSString *) instagramClientID;
#endif
@end

@interface OLSingleImageProductReviewViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UINavigationControllerDelegate, UIGestureRecognizerDelegate, OLUpsellViewControllerDelegate,RMImageCropperDelegate, UIViewControllerPreviewingDelegate, OLImagePickerViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *imagesCollectionView;

@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet OLRemoteImageCropper *imageCropView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *maskAspectRatio;
@property (strong, nonatomic) OLAsset *imagePicked;
@property (strong, nonatomic) OLAsset *imageDisplayed;
@property (strong, nonatomic) NSIndexPath *previewingIndexPath;
@property (nonatomic, copy) void (^saveJobCompletionHandler)();
@property (nonatomic, strong) UITapGestureRecognizer *tapBehindQRUploadModalGestureRecognizer;

@end

static BOOL hasMoved;

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

-(void)viewDidLoad{
    [super viewDidLoad];
    
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackReviewScreenViewed:self.product.productTemplate.name];
#endif
    
    if ([UITraitCollection class] && [self.traitCollection respondsToSelector:@selector(forceTouchCapability)] && self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable){
        [self registerForPreviewingWithDelegate:self sourceView:self.imagesCollectionView];
        [self registerForPreviewingWithDelegate:self sourceView:self.imageCropView];
    }
    
    if ([OLKiteABTesting sharedInstance].launchedWithPrintOrder){
        if ([[OLKiteABTesting sharedInstance].launchWithPrintOrderVariant isEqualToString:@"Review-Overview-Checkout"]){
            [self.ctaButton setTitle:NSLocalizedStringFromTableInBundle(@"Next", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"") forState:UIControlStateNormal];
        }
        
        if(!self.editingPrintJob){
            self.editingPrintJob = [[OLUserSession currentSession].printOrder.jobs firstObject];
            self.product.uuid = self.editingPrintJob.uuid;
        }
    }
    
    if ([self.presentingViewController respondsToSelector:@selector(viewControllers)] || !self.presentingViewController) {
        UIViewController *paymentVc = [(UINavigationController *)self.presentingViewController viewControllers].lastObject;
        if ([paymentVc respondsToSelector:@selector(saveAndDismissReviewController)]){
            [self.ctaButton setTitle:NSLocalizedStringFromTableInBundle(@"Save", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"") forState:UIControlStateNormal];
            [self.ctaButton removeTarget:self action:@selector(onButtonNextClicked) forControlEvents:UIControlEventTouchUpInside];
            [self.ctaButton addTarget:paymentVc action:@selector(saveAndDismissReviewController) forControlEvents:UIControlEventTouchUpInside];
        }
    }
    
    self.ctaButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.ctaButton.titleLabel.minimumScaleFactor = 0.5;
    
    self.title = NSLocalizedStringFromTableInBundle(@"Reposition the Photo", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"");
    
    if (self.imageCropView){
        self.imageCropView.delegate = self;
        OLAsset *photo = [[OLUserSession currentSession].userSelectedPhotos firstObject];
        self.imageDisplayed = photo;
        [photo imageWithSize:[UIScreen mainScreen].bounds.size applyEdits:NO progress:NULL completion:^(UIImage *image){
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.imageCropView setImage:image];
                self.imageCropView.imageView.transform = self.imageDisplayed.edits.cropTransform;
            });
        }];
    }
    
    for (OLAsset *printPhoto in [OLUserSession currentSession].userSelectedPhotos){
        [printPhoto unloadImage];
    }
    
    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapGestureRecognized)];
    gesture.delegate = self;
    [self.imageCropView addGestureRecognizer:gesture];
    
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Back", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"")
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:nil
                                                                            action:nil];
    
    self.imagesCollectionView.dataSource = self;
    self.imagesCollectionView.delegate = self;
    
    if (![OLKiteUtils imageProvidersAvailable:self] && [OLUserSession currentSession].userSelectedPhotos.count == 1){
        self.imagesCollectionView.hidden = YES;
    }
    
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

- (void)onTapGestureRecognized{
    [self enterFullCrop:YES];
}

- (void)enterFullCrop:(BOOL)animated{
    if (!self.imageCropView.imageView.image){
        return;
    }
    
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackReviewScreenEnteredCropScreenForProductName:self.product.productTemplate.name];
#endif
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
    
    hasMoved = NO;
    self.imageCropView.imageView.transform = self.imageDisplayed.edits.cropTransform;
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    
#ifndef OL_NO_ANALYTICS
    if (!self.navigationController){
        [OLAnalytics trackReviewScreenHitBack:self.product.productTemplate.name numberOfPhotos:[OLUserSession currentSession].userSelectedPhotos.count];
    }
#endif
}

-(IBAction)onButtonNextClicked{
    if ([self shouldDoCheckout]){
        [self doCheckout];
    }
}

- (void)saveJobWithCompletionHandler:(void(^)())handler{
    
    self.imageDisplayed.edits.cropImageFrame = [self.imageCropView getFrameRect];
    self.imageDisplayed.edits.cropImageRect = [self.imageCropView getImageRect];
    self.imageDisplayed.edits.cropImageSize = [self.imageCropView croppedImageSize];
    self.imageDisplayed.edits.cropTransform = self.imageCropView.imageView.transform;
    
    OLAsset *asset = [self.imageDisplayed copy];
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
    OLAsset *asset = [self.imageDisplayed copy];
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
    if (!self.imageCropView.image) {
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

- (void)imageCropperDidTransformImage:(RMImageCropper *)imageCropper{
#ifndef OL_NO_ANALYTICS
    if (!hasMoved){
        hasMoved = YES;
        [OLAnalytics trackReviewScreenDidCropPhotoForProductName:self.product.productTemplate.name];
    }
#endif
}

- (UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location{
    if (previewingContext.sourceView == self.imagesCollectionView){
        NSIndexPath *indexPath = [self.imagesCollectionView indexPathForItemAtPoint:location];
        UICollectionViewCell *cell = [self.imagesCollectionView cellForItemAtIndexPath:indexPath];
        
        OLRemoteImageView *imageView = (OLRemoteImageView *)[cell viewWithTag:11];
        if (!imageView.image){
            return nil;
        }
        
        self.previewingIndexPath = indexPath;
        
        UIImageView *cellImageView = [cell viewWithTag:1];
        
        [previewingContext setSourceRect:[cell convertRect:cellImageView.frame toView:self.imagesCollectionView]];
        
        OLImagePreviewViewController *previewVc = [self.storyboard instantiateViewControllerWithIdentifier:@"OLImagePreviewViewController"];
        [[OLUserSession currentSession].userSelectedPhotos[indexPath.item] imageWithSize:[UIScreen mainScreen].bounds.size applyEdits:NO progress:NULL completion:^(UIImage *image){
            dispatch_async(dispatch_get_main_queue(), ^{
                previewVc.image = image;
            });
        }];
        previewVc.providesPresentationContextTransitionStyle = true;
        previewVc.definesPresentationContext = true;
        previewVc.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        return previewVc;
    }
    else if (previewingContext.sourceView == self.imageCropView){
        OLImagePreviewViewController *previewVc = [self.storyboard instantiateViewControllerWithIdentifier:@"OLImagePreviewViewController"];
        [self.imageDisplayed imageWithSize:[UIScreen mainScreen].bounds.size applyEdits:NO progress:NULL completion:^(UIImage *image){
            dispatch_async(dispatch_get_main_queue(), ^{
                previewVc.image = image;
            });
        }];
        previewVc.providesPresentationContextTransitionStyle = true;
        previewVc.definesPresentationContext = true;
        previewVc.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        return previewVc;
    }
    else{
        return nil;
    }
}

- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit{
    if (previewingContext.sourceView == self.imagesCollectionView){
        [self collectionView:self.imagesCollectionView didSelectItemAtIndexPath:self.previewingIndexPath];
    }
    else if (previewingContext.sourceView == self.imageCropView){
        [self enterFullCrop:NO];
    }
}

#pragma mark CollectionView delegate and data source

- (NSInteger) sectionForMoreCell{
    return 0;
}

- (NSInteger) sectionForImageCells{
    return [OLKiteUtils imageProvidersAvailable:self] ? 1 : 0;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    if (section == [self sectionForImageCells]){
        return [OLUserSession currentSession].userSelectedPhotos.count;
    }
    else if (section == [self sectionForMoreCell]){
        return 1;
    }
    else{
        return 0;
    }
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    if ([OLKiteUtils imageProvidersAvailable:self]){
        return 2;
    }
    else{
        return 1;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == [self sectionForImageCells]){
        UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"imageCell" forIndexPath:indexPath];
        
        for (UIView *view in cell.subviews){
            if ([view isKindOfClass:[OLRemoteImageView class]]){
                [view removeFromSuperview];
            }
        }
        
        OLRemoteImageView *imageView = [[OLRemoteImageView alloc] initWithFrame:CGRectMake(0, 0, 138, 138)];
        imageView.tag = 11;
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        [cell addSubview:imageView];
        imageView.translatesAutoresizingMaskIntoConstraints = NO;
        NSDictionary *views = NSDictionaryOfVariableBindings(imageView);
        NSMutableArray *con = [[NSMutableArray alloc] init];
        
        NSArray *visuals = @[@"H:|-0-[imageView]-0-|",
                             @"V:|-0-[imageView]-0-|"];
        
        
        for (NSString *visual in visuals) {
            [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
        }
        
        [imageView.superview addConstraints:con];
        
        
        [[OLUserSession currentSession].userSelectedPhotos[indexPath.item] imageWithSize:imageView.frame.size applyEdits:NO progress:^(float progress){
            dispatch_async(dispatch_get_main_queue(), ^{
                [imageView setProgress:progress];
            });
        }completion:^(UIImage *image){
            dispatch_async(dispatch_get_main_queue(), ^{
                imageView.image = image;
            });
        }];
        
        return cell;
    }
    
    else {
        UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"moreCell" forIndexPath:indexPath];
        return cell;
    }
    
    
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    return CGSizeMake(collectionView.frame.size.height, collectionView.frame.size.height);
}

- (CGFloat) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section{
    return 0;
}

- (CGFloat) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section{
    return 0;
}

- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    
    if (indexPath.section == [self sectionForImageCells]){
        OLRemoteImageView *imageView = (OLRemoteImageView *)[cell viewWithTag:11];
        if (!imageView.image){
            return;
        }
        
        self.imageDisplayed = [OLUserSession currentSession].userSelectedPhotos[indexPath.item];
        
        id activityView = [self.view viewWithTag:1010];
        if ([activityView isKindOfClass:[UIActivityIndicatorView class]]){
            [(UIActivityIndicatorView *)activityView startAnimating];
        }
        self.imageCropView.imageView.image = nil;
        __weak OLSingleImageProductReviewViewController *welf = self;
        [self.imageDisplayed imageWithSize:[UIScreen mainScreen].bounds.size applyEdits:NO progress:^(float progress){
            dispatch_async(dispatch_get_main_queue(), ^{
                [welf.imageCropView setProgress:progress];
            });
        }completion:^(UIImage *image){
            dispatch_async(dispatch_get_main_queue(), ^{
                [activityView stopAnimating];
                [welf.imageCropView setImage:image];
                [welf.view setNeedsLayout];
                [welf.view layoutIfNeeded];
                welf.imageCropView.imageView.transform = welf.imageDisplayed.edits.cropTransform;
            });
        }];
    }
    else{
        [self showImagePicker];
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

#pragma mark - Image Picker

- (void)showImagePicker{
    OLImagePickerViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"OLImagePickerViewController"];
    vc.selectedAssets = [OLUserSession currentSession].userSelectedPhotos;
    vc.delegate = self;
    [self presentViewController:[[OLNavigationController alloc] initWithRootViewController:vc] animated:YES completion:NULL];
}

- (void)imagePickerDidCancel:(OLImagePickerViewController *)vc{
    [vc dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imagePicker:(OLImagePickerViewController *)vc didFinishPickingAssets:(NSMutableArray *)assets added:(NSArray<OLAsset *> *)addedAssets removed:(NSArray *)removedAssets{
    [OLUserSession currentSession].userSelectedPhotos = assets;
    
    if (addedAssets.count == 0 && [removedAssets containsObject:self.imageDisplayed]){
        self.imagePicked = assets.lastObject;
    }
    else{
        self.imagePicked = addedAssets.lastObject;
    }
    if (self.imagePicked){
        id view = [self.view viewWithTag:1010];
        if ([view isKindOfClass:[UIActivityIndicatorView class]]){
            [(UIActivityIndicatorView *)view startAnimating];
        }
        self.imageDisplayed = self.imagePicked;
        __weak OLSingleImageProductReviewViewController *welf = self;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self.imagePicked imageWithSize:[UIScreen mainScreen].bounds.size applyEdits:NO progress:^(float progress){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [welf.imageCropView setProgress:progress];
                });
            } completion:^(UIImage *image){
                dispatch_async(dispatch_get_main_queue(), ^{
                    welf.imageCropView.image = image;
                    welf.imagePicked = nil;
                    
                    if (assets.count > 0){
                        id view = [welf.view viewWithTag:1010];
                        if ([view isKindOfClass:[UIActivityIndicatorView class]]){
                            [(UIActivityIndicatorView *)view stopAnimating];
                        }
                    }
                });
            }];
        });
        
    }
    
    [self.imagesCollectionView reloadData];
    [vc dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - OLImageEditorViewControllerDelegate methods

- (void)scrollCropViewControllerDidCancel:(OLImageEditViewController *)cropper{
    [cropper dismissViewControllerAnimated:YES completion:^{}];
}

- (void)scrollCropViewControllerDidDropChanges:(OLImageEditViewController *)cropper{
    [cropper dismissViewControllerAnimated:NO completion:NULL];
}

-(void)scrollCropViewController:(OLImageEditViewController *)cropper didFinishCroppingImage:(UIImage *)croppedImage{
    [self.imageDisplayed unloadImage];
    
    self.imageDisplayed.edits = cropper.edits;
    [self.imageCropView setImage:nil];
    id activityView = [self.view viewWithTag:1010];
    if ([activityView isKindOfClass:[UIActivityIndicatorView class]]){
        [(UIActivityIndicatorView *)activityView startAnimating];
    }
    
    __weak OLSingleImageProductReviewViewController *welf = self;
    [self.imageDisplayed imageWithSize:[UIScreen mainScreen].bounds.size applyEdits:NO progress:NULL completion:^(UIImage *image){
        dispatch_async(dispatch_get_main_queue(), ^{
            [activityView stopAnimating];
            [welf.imageCropView setImage:image];
            [welf.view setNeedsLayout];
            [welf.view layoutIfNeeded];
            welf.imageCropView.imageView.transform = welf.imageDisplayed.edits.cropTransform;
        });
    }];
    
    [cropper dismissViewControllerAnimated:YES completion:^{
        [UIView animateWithDuration:0.25 animations:^{
        }];
    }];
    
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackReviewScreenDidCropPhotoForProductName:self.product.productTemplate.name];
#endif
}

#pragma mark - UIGestureRecognizer Delegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if ((gestureRecognizer.view == self.imageCropView && [otherGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) || (![otherGestureRecognizer isKindOfClass:[UITapGestureRecognizer class]] && otherGestureRecognizer.state == UIGestureRecognizerStateEnded)){
        gestureRecognizer.enabled = NO;
        gestureRecognizer.enabled = YES;
        return NO;
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return YES;
}


@end
