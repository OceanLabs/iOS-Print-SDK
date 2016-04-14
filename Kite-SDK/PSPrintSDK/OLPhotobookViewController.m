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

#ifdef COCOAPODS
#import <MPFlipViewController/MPFlipTransition.h>
#else
#import "MPFlipTransition.h"
#endif

#import "NSArray+QueryingExtras.h"
#import "NSObject+Utils.h"
#import "OLAnalytics.h"
#import "OLAssetsPickerController.h"
#import "OLImageCachingManager.h"
#import "OLKiteABTesting.h"
#import "OLKitePrintSDK.h"
#import "OLKiteUtils.h"
#import "OLPaymentViewController.h"
#import "OLPhotobookPageContentViewController.h"
#import "OLPhotobookPrintJob.h"
#import "OLPhotobookViewController.h"
#import "OLPopupOptionsImageView.h"
#import "OLPrintPhoto.h"
#import "OLProduct.h"
#import "OLProductTemplate.h"
#import "OLScrollCropViewController.h"
#import "UIImage+ImageNamedInKiteBundle.h"
#import "UIView+RoundRect.h"
#import "OLUpsellViewController.h"

#ifdef OL_KITE_AT_LEAST_IOS8
#import "CTAssetsPickerController.h"
#endif

#ifdef OL_KITE_OFFER_FACEBOOK
#import <FacebookImagePicker/OLFacebookImagePickerController.h>
#import <FacebookImagePicker/OLFacebookImage.h>
#endif

#ifdef OL_KITE_OFFER_INSTAGRAM
#import <InstagramImagePicker/OLInstagramImagePickerController.h>
#import <InstagramImagePicker/OLInstagramImage.h>
#endif

#import "UIImage+ImageNamedInKiteBundle.h"
#import "OLKiteABTesting.h"
#import "OLPaymentViewController.h"
#import "UIViewController+OLMethods.h"
#ifdef OL_KITE_OFFER_CUSTOM_IMAGE_PROVIDERS
#import "OLCustomPhotoProvider.h"
#ifdef COCOAPODS
#import <KITAssetsPickerController/KITAssetsPickerController.h>
#else
#import "KITAssetsPickerController.h"
#endif
#endif

#ifdef OL_KITE_OFFER_ADOBE
#import <AdobeCreativeSDKImage/AdobeCreativeSDKImage.h>
#import <AdobeCreativeSDKCore/AdobeCreativeSDKCore.h>
#endif

static const NSUInteger kTagAlertViewSelectMorePhotos = 99;
static const NSUInteger kTagLeft = 10;
static const NSUInteger kTagRight = 20;
static const CGFloat kBookAnimationTime = 0.8;
static const CGFloat kBookEdgePadding = 38;

@interface OLPaymentViewController (Private)

-(void)saveAndDismissReviewController;

@end

@interface OLKitePrintSDK (InternalUtils)
#ifdef OL_KITE_OFFER_ADOBE
+ (NSString *)adobeCreativeSDKClientSecret;
+ (NSString *)adobeCreativeSDKClientID;
#endif
#ifdef OL_KITE_OFFER_INSTAGRAM
+ (NSString *) instagramRedirectURI;
+ (NSString *) instagramSecret;
+ (NSString *) instagramClientID;
#endif
@end

@interface OLKiteViewController ()

@property (strong, nonatomic) OLPrintOrder *printOrder;
#ifdef OL_KITE_OFFER_CUSTOM_IMAGE_PROVIDERS
@property (strong, nonatomic) NSMutableArray <OLCustomPhotoProvider *> *customImageProviders;
#endif
- (void)dismiss;

@end

@interface OLPrintOrder (Private)
- (BOOL)hasOfferIdBeenUsed:(NSUInteger)identifier;
- (void)saveOrder;
@end

@interface MPFlipTransition (Private)

- (void)animateFlip1:(BOOL)isFallingBack fromProgress:(CGFloat)fromProgress toProgress:(CGFloat)toProgress withCompletion:(void (^)(BOOL finished))completion;
- (void)animateFlip2:(BOOL)isFallingBack fromProgress:(CGFloat)fromProgress withCompletion:(void (^)(BOOL finished))completion;
- (void)transitionDidComplete:(BOOL)completed;
- (void)cleanupLayers;

@end

@interface OLProduct ()
@property (strong, nonatomic) NSMutableSet <OLUpsellOffer *>*declinedOffers;
@property (strong, nonatomic) NSMutableSet <OLUpsellOffer *>*acceptedOffers;
@property (strong, nonatomic) OLUpsellOffer *redeemedOffer;
- (BOOL)hasOfferIdBeenUsed:(NSUInteger)identifier;
@end

@interface OLPhotobookPrintJob ()
@property (strong, nonatomic) NSMutableSet <OLUpsellOffer *>*declinedOffers;
@property (strong, nonatomic) NSMutableSet <OLUpsellOffer *>*acceptedOffers;
@property (strong, nonatomic) OLUpsellOffer *redeemedOffer;
@end

@interface OLPhotobookViewController () <UIPageViewControllerDataSource, UIPageViewControllerDelegate, UIGestureRecognizerDelegate,
OLAssetsPickerControllerDelegate,
#ifdef OL_KITE_AT_LEAST_IOS8
CTAssetsPickerControllerDelegate,
#endif
UIActionSheetDelegate, UIAlertViewDelegate, OLImageViewDelegate, OLScrollCropViewControllerDelegate,
#ifdef OL_KITE_OFFER_INSTAGRAM
OLInstagramImagePickerControllerDelegate,
#endif
#ifdef OL_KITE_OFFER_FACEBOOK
OLFacebookImagePickerControllerDelegate,
#endif
#ifdef OL_KITE_OFFER_CUSTOM_IMAGE_PROVIDERS
KITAssetsPickerControllerDelegate,
#endif
#ifdef OL_KITE_OFFER_ADOBE
AdobeUXImageEditorViewControllerDelegate,
#endif
UINavigationControllerDelegate, OLUpsellViewControllerDelegate
>

@property (assign, nonatomic) BOOL animating;
@property (assign, nonatomic) BOOL bookClosed;
@property (assign, nonatomic) BOOL haveSeenViewDidAppear;
@property (assign, nonatomic) BOOL stranded;
@property (assign, nonatomic) BOOL userHasOpenedBook;
@property (assign, nonatomic) NSInteger addNewPhotosAtIndex;
@property (assign, nonatomic) NSInteger croppingImageIndex;
@property (strong, nonatomic) IBOutlet UIView *bookCover;
@property (strong, nonatomic) NSArray *userSelectedPhotosCopy;
@property (strong, nonatomic) NSLayoutConstraint *centerXCon;
@property (strong, nonatomic) NSLayoutConstraint *centerYCon;
@property (strong, nonatomic) NSLayoutConstraint *widthCon2;
@property (strong, nonatomic) NSLayoutConstraint *widthCon;
@property (strong, nonatomic) OLPrintPhoto *croppingPrintPhoto;
@property (strong, nonatomic) UIDynamicAnimator* dynamicAnimator;
@property (strong, nonatomic) UIDynamicItemBehavior* inertiaBehavior;
@property (strong, nonatomic) UIVisualEffectView *visualEffectView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomMarginCon;
@property (weak, nonatomic) IBOutlet UIImageView *bookImageView;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UIView *fakeShadowView;
@property (weak, nonatomic) IBOutlet UIView *openbookView;
@property (weak, nonatomic) IBOutlet UIView *pagesLabelContainer;
@property (weak, nonatomic) NSLayoutConstraint *topMarginCon;
@property (weak, nonatomic) OLPopupOptionsImageView *coverImageView;
@property (weak, nonatomic) IBOutlet UIButton *ctaButton;
@property (weak, nonatomic) UIPanGestureRecognizer *pageControllerPanGesture;
@property (strong, nonatomic) UILabel *coverHelpLabel;

@end

@implementation OLPhotobookViewController

-(id<OLPrintJob>)editingPrintJob{
    if (_editingPrintJob){
        return _editingPrintJob;
    }
    else if([OLKiteABTesting sharedInstance].launchedWithPrintOrder){
        OLKiteViewController *kiteVc = [OLKiteUtils kiteVcForViewController:self];
        self.product.uuid = [kiteVc.printOrder.jobs.firstObject uuid];
        return [kiteVc.printOrder.jobs firstObject];
    }
    
    return nil;
}

-(UIDynamicAnimator*) dynamicAnimator{
    if (!_dynamicAnimator) _dynamicAnimator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    return _dynamicAnimator;
}

-(UIDynamicItemBehavior*) inertiaBehavior{
    if (!_inertiaBehavior){
        _inertiaBehavior = [[UIDynamicItemBehavior alloc] init];
    }
    return _inertiaBehavior;
}

- (void)setUserSelectedPhotos:(NSMutableArray *)userSelectedPhotos{
    _userSelectedPhotos = userSelectedPhotos;
    
    self.photobookPhotos = [[NSMutableArray alloc] initWithCapacity:self.product.quantityToFulfillOrder];
    [self.photobookPhotos addObjectsFromArray:userSelectedPhotos];
    for (NSInteger i = userSelectedPhotos.count; i < self.product.quantityToFulfillOrder; i++){
        [self.photobookPhotos addObject:[userSelectedPhotos objectAtIndex:i % userSelectedPhotos.count]];
    }
    
    for (OLPhotobookPageContentViewController *page in [self.pageController viewControllers]){
        page.userSelectedPhotos = self.photobookPhotos;
    }
    
    self.userSelectedPhotosCopy = [[NSArray alloc] initWithArray:userSelectedPhotos copyItems:NO];
}

- (void)setEditingPageNumber:(NSNumber *)editingPageNumber{
    _editingPageNumber = editingPageNumber;
    [self updatePagesLabel];
    [self setPages];
}

- (void)setPages{
    NSInteger pageIndex = self.editingPageNumber ? [self.editingPageNumber integerValue] : 0;
    if (self.pageController.viewControllers.count < 2){
        [self.pageController setViewControllers:@[[self viewControllerAtIndex:pageIndex], [self viewControllerAtIndex:pageIndex + 1]] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    }
    else{
        [self.pageController.viewControllers[0] setPageIndex:pageIndex];
        [self.pageController.viewControllers[0] loadImageWithCompletionHandler:NULL];
        [self.pageController.viewControllers[1] setPageIndex:pageIndex + 1];
        [self.pageController.viewControllers[1] loadImageWithCompletionHandler:NULL];
    }
}

- (void)viewDidLoad{
    [super viewDidLoad];
    
    if ([OLKiteABTesting sharedInstance].launchedWithPrintOrder){
        if ([[OLKiteABTesting sharedInstance].launchWithPrintOrderVariant isEqualToString:@"Review-Overview-Checkout"]){
            [self.ctaButton setTitle:NSLocalizedString(@"Next", @"") forState:UIControlStateNormal];
        }
        
        if(!self.editingPrintJob){
            OLKiteViewController *kiteVc = [OLKiteUtils kiteVcForViewController:self];
            self.editingPrintJob = [kiteVc.printOrder.jobs firstObject];
            self.product.uuid = self.editingPrintJob.uuid;
        }
    }
    
    if ([self.presentingViewController respondsToSelector:@selector(viewControllers)]) {
        UIViewController *paymentVc = [(UINavigationController *)self.presentingViewController viewControllers].lastObject;
        if ([paymentVc respondsToSelector:@selector(saveAndDismissReviewController)]){
            [self.ctaButton setTitle:NSLocalizedString(@"Save", @"") forState:UIControlStateNormal];
            [self.ctaButton removeTarget:self action:@selector(onButtonNextClicked:) forControlEvents:UIControlEventTouchUpInside];
            [self.ctaButton addTarget:paymentVc action:@selector(saveAndDismissReviewController) forControlEvents:UIControlEventTouchUpInside];
        }
    }
    
    
    
#ifndef OL_NO_ANALYTICS
    if (!self.editMode){
        [OLAnalytics trackReviewScreenViewed:self.product.productTemplate.name];
    }
#endif
    
    self.pageController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStylePageCurl navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:@{UIPageViewControllerOptionSpineLocationKey : [NSNumber numberWithInt:UIPageViewControllerSpineLocationMid]}];
    self.pageController.dataSource = self;
    self.pageController.delegate = self;
    
    [self setPages];
    
    [self addChildViewController:self.pageController];
    [self.openbookView addSubview:self.pageController.view];
    
    self.pageController.view.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.openbookView.superview addConstraint:[NSLayoutConstraint constraintWithItem:self.pageController.view attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.openbookView attribute:NSLayoutAttributeHeight multiplier:1 - (2 * .021573604) constant:0]];
    [self.openbookView.superview addConstraint:[NSLayoutConstraint constraintWithItem:self.pageController.view attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.openbookView attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
    
    [self.openbookView.superview addConstraint:[NSLayoutConstraint constraintWithItem:self.pageController.view attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.openbookView attribute:NSLayoutAttributeWidth multiplier:1 - (2 * .031951641) constant:0]];
    [self.openbookView.superview addConstraint:[NSLayoutConstraint constraintWithItem:self.pageController.view attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.openbookView attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    
    [self.openbookView.superview setNeedsLayout];
    [self.openbookView.superview layoutIfNeeded];
    
    CGFloat bookAspectRatio = [self productAspectRatio];
    
    NSLayoutConstraint *bookAspectRatioCon = [NSLayoutConstraint constraintWithItem:self.containerView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.containerView attribute:NSLayoutAttributeHeight multiplier:bookAspectRatio constant:0];
    [self.containerView addConstraint:bookAspectRatioCon];
    
    self.topMarginCon = [NSLayoutConstraint constraintWithItem:self.containerView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:self.containerView.superview attribute:NSLayoutAttributeTop multiplier:1 constant:20];
    [self.containerView.superview addConstraint:self.topMarginCon];
    
    self.centerXCon = [NSLayoutConstraint constraintWithItem:self.containerView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.containerView.superview attribute:NSLayoutAttributeCenterX multiplier:1 constant:0];
    if ([self isLandscape]){
        [self.containerView.superview addConstraint:self.centerXCon];
        self.widthCon = [NSLayoutConstraint constraintWithItem:self.containerView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationLessThanOrEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:self.view.frame.size.width - 20 - kBookEdgePadding * 2];
    }
    else{
        self.widthCon = [NSLayoutConstraint constraintWithItem:self.containerView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationLessThanOrEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:(self.view.frame.size.width - kBookEdgePadding * 2) * 1.9];
    }
    
    [self.view addConstraint:self.widthCon];
    self.widthCon2 = [NSLayoutConstraint constraintWithItem:self.containerView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:(self.view.frame.size.width - kBookEdgePadding * 2) * 1.9];
    self.widthCon2.priority = UILayoutPriorityDefaultLow;
    [self.view addConstraint:self.widthCon2];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapGestureRecognized:)];
    tapGesture.delegate = self;
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPanGestureRecognized:)];
    panGesture.delegate = self;
    
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onLongPressGestureRecognized:)];
    longPressGesture.delegate = self;
    
    [self.pageController.view addGestureRecognizer:tapGesture];
    [self.pageController.view addGestureRecognizer:panGesture];
    [self.pageController.view addGestureRecognizer:longPressGesture];
    
    self.title = NSLocalizedString(@"Review", @"");
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", @"")
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:nil
                                                                            action:nil];
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0){
        UIVisualEffect *blurEffect;
        blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        
        self.visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        UIView *view = self.visualEffectView;
        [self.pagesLabelContainer insertSubview:view belowSubview:self.pagesLabel];
        
        view.translatesAutoresizingMaskIntoConstraints = NO;
        NSDictionary *views = NSDictionaryOfVariableBindings(view);
        NSMutableArray *con = [[NSMutableArray alloc] init];
        
        NSArray *visuals = @[@"H:|-0-[view]-0-|",
                             @"V:|-0-[view]-0-|"];
        
        
        for (NSString *visual in visuals) {
            [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
        }
        
        [view.superview addConstraints:con];
    }
    else{
        self.pagesLabelContainer.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.8];
        self.pagesLabel.font = [UIFont systemFontOfSize:13];
        
        [self.containerView.superview addConstraint:[NSLayoutConstraint constraintWithItem:self.containerView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationLessThanOrEqual toItem:self.containerView.superview attribute:NSLayoutAttributeRight multiplier:1 constant:0]];
        [self.containerView.superview addConstraint:[NSLayoutConstraint constraintWithItem:self.containerView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:self.containerView.superview attribute:NSLayoutAttributeLeft multiplier:1 constant:0]];
        if ([self productAspectRatio] > 1){ //Landscape book REALLY doesn't like the following, only do it for portrait.
            [self.containerView.superview addConstraint:[NSLayoutConstraint constraintWithItem:self.containerView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.containerView.superview attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
        }
        
        if (!self.editMode){
            UINavigationBar *navigationBar = [[UINavigationBar alloc] init];
            [self.view addSubview:navigationBar];
            UIView *view = navigationBar;
            
            view.translatesAutoresizingMaskIntoConstraints = NO;
            NSDictionary *views = NSDictionaryOfVariableBindings(view);
            NSMutableArray *con = [[NSMutableArray alloc] init];
            
            NSArray *visuals = @[@"H:|-0-[view]-0-|", @"V:|-0-[view(44)]"];
            
            for (NSString *visual in visuals) {
                [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
            }
            
            [view.superview addConstraints:con];
            
            UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectMake(5, 0, 50, 44)];
            [backButton setTitle:NSLocalizedString(@"Back", @"") forState:UIControlStateNormal];
            [backButton setTitleColor:self.view.tintColor forState:UIControlStateNormal];
            [backButton addTarget:self action:@selector(ios7Back) forControlEvents:UIControlEventTouchUpInside];
            [navigationBar addSubview:backButton];
            
            UIButton *nextButton = [[UIButton alloc] initWithFrame:CGRectMake(MAX(self.view.frame.size.width, self.view.frame.size.height) - 55, 0, 50, 44)];
            [nextButton setTitle:NSLocalizedString(@"Next", @"") forState:UIControlStateNormal];
            [nextButton setTitleColor:self.view.tintColor forState:UIControlStateNormal];
            [nextButton addTarget:self action:@selector(onButtonNextClicked:) forControlEvents:UIControlEventTouchUpInside];
            [navigationBar addSubview:nextButton];
        }
    }
    
    [self.pagesLabelContainer makeRoundRectWithRadius:3];
    
    [self updatePagesLabel];
    
    if (self.editMode){
        [self.ctaButton removeFromSuperview];
    }
    
    CGFloat yOffset = !self.editMode ? ([[UIApplication sharedApplication] statusBarFrame].size.height + self.navigationController.navigationBar.frame.size.height-self.ctaButton.frame.size.height)/2.0 : -15;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8){
        yOffset = 22;
    }
    self.centerYCon = [NSLayoutConstraint constraintWithItem:self.containerView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.containerView.superview attribute:NSLayoutAttributeCenterY multiplier:1 constant:yOffset];
    [self.containerView.superview addConstraint:self.centerYCon];
    
    self.containerView.layer.shadowOffset = CGSizeMake(-10, 10);
    self.containerView.layer.shadowRadius = 5;
    self.containerView.layer.shadowOpacity = 0.25;
    self.containerView.layer.shouldRasterize = YES;
    self.containerView.layer.rasterizationScale = [UIScreen mainScreen].scale;
    
    [self.bookImageView makeRoundRectWithRadius:3];
    
    for (UIGestureRecognizer *gesture in self.pageController.gestureRecognizers){
        gesture.delegate = self;
        if ([gesture isKindOfClass:[UIPanGestureRecognizer class]]){
            self.pageControllerPanGesture = (UIPanGestureRecognizer *)gesture;
        }
    }
    
    if (!self.editMode || !self.startOpen){ //Start with book closed
        [self setUpBookCoverViewForGesture:nil];
        self.bookCover.hidden = NO;
        self.containerView.layer.shadowOpacity = 0;
        
        UIView *closedPage = [self.bookCover viewWithTag:kTagRight];
        closedPage.layer.shadowOffset = CGSizeMake(-10, 10);
        closedPage.layer.shadowRadius = 5;
        closedPage.layer.shadowOpacity = 0.25;
        closedPage.layer.shouldRasterize = YES;
        closedPage.layer.rasterizationScale = [UIScreen mainScreen].scale;
        
        self.containerView.layer.shadowOpacity = 0.0;
        self.pagesLabelContainer.alpha = 0;
        self.bookClosed = YES;
        
        self.openbookView.hidden = YES;
        
        [self.fakeShadowView makeRoundRectWithRadius:3];
    }
    
    if (self.editMode && !self.startOpen){
        self.topMarginCon.constant = 10;
        self.bottomMarginCon.constant = 0;
    }
    else if (self.editMode){
        self.topMarginCon.constant = 10;
        self.bottomMarginCon.constant = 0;
    }
}

- (void)viewDidDisappear:(BOOL)animated{
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    [super viewDidDisappear:animated];
    
#ifndef OL_NO_ANALYTICS
    if (!self.navigationController && !self.editMode){
        [OLAnalytics trackReviewScreenHitBack:self.product.productTemplate.name numberOfPhotos:self.userSelectedPhotos.count];
    }
#endif
}

- (void)updatePagesLabel{
    int page = self.editingPageNumber ? [self.editingPageNumber intValue] : 0;
    self.pagesLabel.text = [NSString stringWithFormat:@"%d-%d of %ld", page + 1, page + 2, (long)self.product.quantityToFulfillOrder];
}

- (void)ios7Back{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (BOOL)prefersStatusBarHidden{
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8){
        return YES;
    }
    else{
        return [super prefersStatusBarHidden];
    }
}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    
    if (!self.haveSeenViewDidAppear && [[[UIDevice currentDevice] systemVersion] floatValue] >= 8){
        if (![self isLandscape]){
            if ((self.containerView.frame.size.width > self.view.frame.size.width - kBookEdgePadding * 2)){
                self.containerView.transform = CGAffineTransformMakeTranslation([self xTrasformForBookAtRightEdge], 0);
            }
            else{
                [self.containerView.superview addConstraint:self.centerXCon];
            }
        }
    }
    if (self.editMode && self.bookClosed){
        self.containerView.transform = CGAffineTransformMakeTranslation(-self.containerView.frame.size.width / 4.0, 0);
    }
}

- (BOOL)isLandscape{
    return self.view.frame.size.width > self.view.frame.size.height || self.editMode;
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    self.haveSeenViewDidAppear = YES;
    
    if (!self.editMode){
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    }
    
    if (self.bookClosed && !self.editMode){
        [self tease];
    }
}

- (void)tease{
    if (self.animating || self.userHasOpenedBook){
        return;
    }
    
    self.animating = YES;
    MPFlipStyle style = MPFlipStyleDefault;
    MPFlipTransition *flipTransition = [[MPFlipTransition alloc] initWithSourceView:self.bookCover destinationView:self.openbookView duration:0.5 timingCurve:UIViewAnimationCurveEaseOut completionAction:MPTransitionActionNone];
    flipTransition.style = style;
    
    [flipTransition buildLayers];
    CGFloat maxProgress = 0.5;
    [flipTransition setRubberbandMaximumProgress:maxProgress/2.0];
    [flipTransition setDuration:[flipTransition duration] * 1 / maxProgress]; // necessary to arrive at the dersired total duration
    [flipTransition animateFlip1:NO fromProgress:0 toProgress:maxProgress withCompletion:^(BOOL finished) {
        flipTransition.timingCurve = UIViewAnimationCurveEaseIn;
        [flipTransition animateFlip2:YES fromProgress:maxProgress withCompletion:^(BOOL finished) {
            [flipTransition cleanupLayers];
            [flipTransition transitionDidComplete:NO];
            self.animating = NO;
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [self tease];
            });
        }];
    }];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if (!self.editMode){
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
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    self.stranded = NO;
    self.containerView.transform = CGAffineTransformIdentity;
    [self.containerView.superview removeConstraint:self.centerYCon];
    [self.view removeConstraint:self.widthCon];
    if (size.width > size.height){
        [self.view addConstraint:self.centerXCon];
        self.widthCon = [NSLayoutConstraint constraintWithItem:self.containerView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationLessThanOrEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:size.width - 20 - kBookEdgePadding * 2];
    }
    else{
        [self.view removeConstraint:self.centerXCon];
        self.widthCon = [NSLayoutConstraint constraintWithItem:self.containerView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationLessThanOrEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:(size.width - kBookEdgePadding * 2)* 1.9];
    }
    [self.view addConstraint:self.widthCon];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinator> context){
        [self setUpBookCoverViewForGesture:nil];
        if (size.width > size.height){
            self.containerView.transform = CGAffineTransformIdentity;
        }
        else{
            if (self.bookClosed && [self isBookAtStart]){
                self.containerView.transform = CGAffineTransformMakeTranslation([self xTrasformForBookAtRightEdge], 0);
            }
        }
        
        CGFloat yOffset = !self.editMode ? ([[UIApplication sharedApplication] statusBarFrame].size.height + self.navigationController.navigationBar.frame.size.height-self.ctaButton.frame.size.height)/2.0 : -15;
        
        self.centerYCon = [NSLayoutConstraint constraintWithItem:self.containerView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.containerView.superview attribute:NSLayoutAttributeCenterY multiplier:1 constant:yOffset];
        [self.containerView.superview addConstraint:self.centerYCon];
    }completion:^(id<UIViewControllerTransitionCoordinator> context){
        if (!self.editMode){
            self.containerView.layer.shadowOpacity = 0;
        }
    }];
}

- (CGFloat) productAspectRatio{
    return self.product.productTemplate.sizeCm.width*2 / self.product.productTemplate.sizeCm.height;
}

- (void)loadCoverPhoto{
    if (!self.coverPhoto){
        self.coverImageView.image = nil;
    }
    __weak OLPhotobookViewController *welf = self;
    if (self.coverImageView){
        [self.coverPhoto setImageSize:self.coverImageView.frame.size cropped:YES progress:^(float progress){
            [welf.coverImageView setProgress:progress];
        }completionHandler:^(UIImage *image){
            dispatch_async(dispatch_get_main_queue(), ^{
                welf.coverImageView.image = image;
            });
        }];
    }
}

- (UIViewController *)viewControllerAtIndex:(NSUInteger)index {
    if (index == NSNotFound) {
        return nil;
    }
    
    OLPhotobookPageContentViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"OLPhotobookPageViewController"];
    vc.pageIndex = index;
    vc.userSelectedPhotos = self.photobookPhotos;
    vc.product = self.product;
    vc.view.autoresizingMask = UIViewAutoresizingNone;
    return vc;
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
        [assets addObject:[OLAsset assetWithDataSource:[self.userSelectedPhotos.firstObject copy]]];
    }
    else{
        for (OLPrintPhoto *photo in self.userSelectedPhotos){
            [assets addObject:[OLAsset assetWithDataSource:[photo copy]]];
        }
    }
    
    id<OLPrintJob> job;
    if ([OLProductTemplate templateWithId:templateId].templateUI == kOLTemplateUIPhotobook){
        job = [OLPrintJob photobookWithTemplateId:templateId OLAssets:assets frontCoverOLAsset:nil backCoverOLAsset:nil];
    }
    else{
        job = [OLPrintJob printJobWithTemplateId:templateId OLAssets:assets];
    }
    
    [[OLKiteUtils kiteVcForViewController:self].printOrder addPrintJob:job];
    return job;
}

- (void)userDidAcceptUpsell:(OLUpsellViewController *)vc{
    [self.product.acceptedOffers addObject:vc.offer];
    [vc dismissViewControllerAnimated:NO completion:^{
        if (vc.offer.prepopulatePhotos){
            id<OLPrintJob> job = [self addItemToBasketWithTemplateId:vc.offer.offerTemplate];
            [(OLPhotobookPrintJob *)job setRedeemedOffer:vc.offer];
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

#pragma mark - OLScrollCropView delegate

- (void)scrollCropViewControllerDidCancel:(OLScrollCropViewController *)cropper{
    [cropper dismissViewControllerAnimated:YES completion:NULL];
}

-(void)scrollCropViewController:(OLScrollCropViewController *)cropper didFinishCroppingImage:(UIImage *)croppedImage{
    [self.croppingPrintPhoto unloadImage];
    self.croppingPrintPhoto.asset = [OLAsset assetWithImageAsJPEG:croppedImage];
    if (self.croppingPrintPhoto == self.coverPhoto){
        [self loadCoverPhoto];
    }
    
    [(OLPhotobookPageContentViewController *)[self.pageController.viewControllers objectAtIndex:self.croppingImageIndex] loadImageWithCompletionHandler:NULL];
    
    [cropper dismissViewControllerAnimated:YES completion:NULL];
}

#ifdef OL_KITE_OFFER_ADOBE
- (void)photoEditor:(AdobeUXImageEditorViewController *)editor finishedWithImage:(UIImage *)image{
    [self.croppingPrintPhoto unloadImage];
    
    OLPrintPhoto *printPhoto = self.croppingPrintPhoto;
    OLPrintPhoto *copy = [printPhoto copy];
    printPhoto.asset = [OLAsset assetWithImageAsJPEG:image];
    
    if (self.croppingPrintPhoto == self.coverPhoto){
        [self loadCoverPhoto];
    }
    
    [(OLPhotobookPageContentViewController *)[self.pageController.viewControllers objectAtIndex:self.croppingImageIndex] loadImageWithCompletionHandler:NULL];
    
    [editor dismissViewControllerAnimated:YES completion:NULL];
    
    [copy getImageWithProgress:NULL completion:^(UIImage *image){
        [editor enqueueHighResolutionRenderWithImage:image completion:^(UIImage *result, NSError *error) {
            NSArray * urls = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
            NSString *documentDirPath = [[(NSURL *)[urls objectAtIndex:0] path] stringByAppendingPathComponent:@"ol-kite-images"];
            
            
            NSFileManager *fileManager= [NSFileManager defaultManager];
            BOOL isDir;
            if(![fileManager fileExistsAtPath:documentDirPath isDirectory:&isDir]){
                [fileManager createDirectoryAtPath:documentDirPath withIntermediateDirectories:YES attributes:nil error:NULL];
            }
            
            NSData * binaryImageData = UIImageJPEGRepresentation(result, 0.7);
            
            NSString *filePath = [documentDirPath stringByAppendingPathComponent:[[[NSUUID UUID] UUIDString] stringByAppendingString:@".jpg"]];
            [binaryImageData writeToFile:filePath atomically:YES];
            
            printPhoto.asset = [OLAsset assetWithFilePath:filePath];
        }];
    }];
    
}

- (void)photoEditorCanceled:(AdobeUXImageEditorViewController *)editor{
    [editor dismissViewControllerAnimated:YES completion:NULL];
}
#endif

#pragma mark - UIPageViewControllerDataSource and delegate

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    OLPhotobookPageContentViewController *vc = (OLPhotobookPageContentViewController *) viewController;
    NSUInteger index = vc.pageIndex - 1;
    if (vc.pageIndex == 0) {
        return nil;
    }
    return [self viewControllerAtIndex:index];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    OLPhotobookPageContentViewController *vc = (OLPhotobookPageContentViewController *) viewController;
    NSUInteger index = (vc.pageIndex + 1);
    if (index >= self.photobookPhotos.count){
        return nil;
    }
    return [self viewControllerAtIndex:index];
}

- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController {
    return self.photobookPhotos.count;
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController {
    return 2;
}

- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray *)pendingViewControllers{
    self.animating = YES;
}

#pragma mark - Checkout

- (IBAction)onButtonNextClicked:(UIButton *)sender {
    if ([self shouldGoToCheckout]){
        [self doCheckout];
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
            if ([[OLKiteUtils kiteVcForViewController:self].printOrder hasOfferIdBeenUsed:offer.identifier]){
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

-(BOOL) shouldGoToCheckout{
    OLUpsellOffer *offer = [self upsellOfferToShow];
    BOOL shouldShowOffer = offer != nil;
    if (offer){
        shouldShowOffer &= offer.minUnits <= self.userSelectedPhotos.count;
        shouldShowOffer &= offer.maxUnits == 0 || offer.maxUnits >= self.userSelectedPhotos.count;
        shouldShowOffer &= [OLProduct productWithTemplateId:offer.offerTemplate] != nil;
    }
    if (shouldShowOffer){
        OLUpsellViewController *c = [self.storyboard instantiateViewControllerWithIdentifier:@"OLUpsellViewController"];
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8){
            c.providesPresentationContextTransitionStyle = true;
            c.definesPresentationContext = true;
        }
        c.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        c.delegate = self;
        c.offer = offer;
        c.triggeredProduct = self.product;
        [self presentViewController:c animated:NO completion:NULL];
        return NO;
    }
    
    NSUInteger selectedCount = 0;
    for (id object in self.photobookPhotos){
        if (object != [NSNull null]){
            selectedCount++;
        }
    }
    
    if (selectedCount == 0){
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Oops", @"") message:NSLocalizedString(@"Please add some photos to your photo book", @"") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
        [av show];
        return NO;
    }
    
    NSUInteger numOrders = 1 + (MAX(0, selectedCount - 1) / self.product.quantityToFulfillOrder);
    NSUInteger quantityToFulfilOrder = numOrders * self.product.quantityToFulfillOrder;
    if (selectedCount < quantityToFulfilOrder) {
        NSUInteger canSelectExtraCount = quantityToFulfilOrder - selectedCount;
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"You've selected %d photos.", @""),selectedCount] message:[NSString stringWithFormat:NSLocalizedString(@"You can add %d more for the same price.", @""), canSelectExtraCount] delegate:nil cancelButtonTitle:NSLocalizedString(@"Add more", @"") otherButtonTitles:NSLocalizedString(@"Print these", @""), nil];
        av.tag = kTagAlertViewSelectMorePhotos;
        av.delegate = self;
        [av show];
        return NO;
    }
    return YES;
}

- (void)saveJobWithCompletionHandler:(void(^)())handler{
    NSInteger i = 0;
    NSMutableArray *bookPhotos = [[NSMutableArray alloc] init];
    NSMutableArray *photobookPhotosClean = [[NSMutableArray alloc] init];
    [photobookPhotosClean addObjectsFromArray:self.photobookPhotos];
    [photobookPhotosClean removeObjectIdenticalTo:[NSNull null]];
    
    for (NSInteger object = 0; object < self.photobookPhotos.count; object++){
        if (self.photobookPhotos[object] == [NSNull null]){
            [bookPhotos addObject:photobookPhotosClean[i % photobookPhotosClean.count]];
            i++;
        }
        else{
            [bookPhotos addObject:self.photobookPhotos[object]];
        }
    }
    
    // Avoid uploading assets if possible. We can avoid uploading where the image already exists at a remote
    // URL and the user did not manipulate it in any way.
    NSMutableArray *photoAssets = [[NSMutableArray alloc] init];
    for (OLPrintPhoto *photo in bookPhotos) {
        [photoAssets addObject:[OLAsset assetWithDataSource:[photo copy]]];
    }
    
    // ensure order is maxed out by adding duplicates as necessary
    NSUInteger userSelectedAssetCount = photoAssets.count;
    NSUInteger numOrders = (NSUInteger) floor(userSelectedAssetCount + self.product.quantityToFulfillOrder - 1) / self.product.quantityToFulfillOrder;
    NSUInteger duplicatesToFillOrder = numOrders * self.product.quantityToFulfillOrder - userSelectedAssetCount;
    for (NSUInteger i = 0; i < duplicatesToFillOrder; ++i) {
        [photoAssets addObject:photoAssets[i % userSelectedAssetCount]];
    }
    
#ifdef OL_VERBOSE
    NSLog(@"Adding %lu duplicates", (unsigned long)duplicatesToFillOrder);
#endif
    
    OLPrintOrder *printOrder = [OLKiteUtils kiteVcForViewController:self].printOrder;
    OLPhotobookPrintJob *job = [[OLPhotobookPrintJob alloc] initWithTemplateId:self.product.templateId OLAssets:photoAssets];
    job.frontCover = self.coverPhoto ? [OLAsset assetWithDataSource:self.coverPhoto] : nil;
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
}

- (void)doCheckout {
    [self saveJobWithCompletionHandler:NULL];
    
    OLPrintOrder *printOrder = [OLKiteUtils kiteVcForViewController:self].printOrder;
    [OLKiteUtils checkoutViewControllerForPrintOrder:printOrder handler:^(id vc){
        [vc safePerformSelector:@selector(setUserEmail:) withObject:[OLKiteUtils userEmail:self]];
        [vc safePerformSelector:@selector(setUserPhone:) withObject:[OLKiteUtils userPhone:self]];
        [vc safePerformSelector:@selector(setKiteDelegate:) withObject:[OLKiteUtils kiteDelegate:self]];
        
        
        if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8){
            UIViewController *presenting = self.presentingViewController;
            [self dismissViewControllerAnimated:YES completion:^{
                [(UINavigationController *)[presenting.childViewControllers firstObject] pushViewController:vc animated:YES];
            }];
        }
        else{
            [self.navigationController pushViewController:vc animated:YES];
        }
    }];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == kTagAlertViewSelectMorePhotos) {
        if (buttonIndex == 1) {
            [self doCheckout];
        }
    }
}

#pragma mark - Gesture recognizers

- (void)onCoverTapRecognized:(UITapGestureRecognizer *)sender{
    if (self.editMode){
        [self.photobookDelegate photobook:self userDidTapOnImageWithIndex:-1];
    }
    else if (self.coverPhoto){
        self.croppingPrintPhoto = self.coverPhoto;
        UIImageView *imageView = self.coverImageView;
#ifdef OL_KITE_OFFER_ADOBE
        [[AdobeUXAuthManager sharedManager] setAuthenticationParametersWithClientID:[OLKitePrintSDK adobeCreativeSDKClientID] clientSecret:[OLKitePrintSDK adobeCreativeSDKClientSecret] enableSignUp:true];
        [AdobeImageEditorCustomization setCropToolPresets:@[@{kAdobeImageEditorCropPresetName:@"", kAdobeImageEditorCropPresetWidth:@1, kAdobeImageEditorCropPresetHeight:[NSNumber numberWithDouble:imageView.frame.size.height / imageView.frame.size.width]}]];
        [AdobeImageEditorCustomization setCropToolCustomEnabled:NO];
        [AdobeImageEditorCustomization setCropToolInvertEnabled:NO];
        [AdobeImageEditorCustomization setCropToolOriginalEnabled:NO];
        
        [self.croppingPrintPhoto getImageWithProgress:NULL completion:^(UIImage *image){
            AdobeUXImageEditorViewController *editorController = [[AdobeUXImageEditorViewController alloc] initWithImage:image];
            [editorController setDelegate:self];
            [self presentViewController:editorController animated:YES completion:nil];
        }];
#else
        OLScrollCropViewController *cropVc = [self.storyboard instantiateViewControllerWithIdentifier:@"OLScrollCropViewController"];
        cropVc.delegate = self;
        cropVc.aspectRatio = imageView.frame.size.height / imageView.frame.size.width;
        cropVc.previewView = [imageView snapshotViewAfterScreenUpdates:YES];
        cropVc.previewView.frame = [imageView.superview convertRect:imageView.frame toView:nil];
        cropVc.previewSourceView = imageView;
        cropVc.providesPresentationContextTransitionStyle = true;
        cropVc.definesPresentationContext = true;
        cropVc.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        
        [self.croppingPrintPhoto getImageWithProgress:NULL completion:^(UIImage *image){
            [cropVc setFullImage:image];
            cropVc.edits = self.croppingPrintPhoto.edits;
//            cropVc.modalPresentationStyle = [OLKiteUtils kiteVcForViewController:self].modalPresentationStyle;
            [self presentViewController:cropVc animated:NO completion:NULL];
        }];
#endif
    }
    else{
        [self openBook:sender];
    }
}

- (void)onCoverLongPressRecognized:(UILongPressGestureRecognizer *)sender{
    if (self.editMode && self.coverPhoto){
        [self.photobookDelegate photobook:self userDidLongPressOnImageWithIndex:-1 sender:sender];
    }
}

- (void)updateUserSelectedPhotos{
    [self.userSelectedPhotos removeAllObjects];
    for (OLPrintPhoto *item in self.photobookPhotos){
        if (![item isKindOfClass:[NSNull class]]){
            [self.userSelectedPhotos addObject:item];
        }
    }
}

- (void)onTapGestureRecognized:(UITapGestureRecognizer *)sender{
    if ([sender locationInView:self.pageController.view].x < self.pageController.view.frame.size.width / 2.0){
        self.croppingImageIndex = 0;
    }
    else{
        self.croppingImageIndex = 1;
    }
    NSInteger index = [[self.pageController.viewControllers objectAtIndex:self.croppingImageIndex] pageIndex];
    
    if (self.editMode){
        OLPhotobookPageContentViewController *page = [self.pageController.viewControllers objectAtIndex:self.croppingImageIndex];
        NSInteger index = [page imageIndexForPoint:[sender locationInView:page.view]];
        [self.photobookDelegate photobook:self userDidTapOnImageWithIndex:index];
        
        return;
    }
    else if ([self.photobookPhotos objectAtIndex:index] == (id)[NSNull null]){
        self.addNewPhotosAtIndex = index;
        [self addMorePhotosFromView:sender.view];
    }
    else{
        OLPhotobookPageContentViewController *page = [self.pageController.viewControllers objectAtIndex:self.croppingImageIndex];
        UIImageView *imageView = [page imageView];

        self.croppingPrintPhoto = self.photobookPhotos[index];
        
        [self.croppingPrintPhoto getImageWithProgress:NULL completion:^(UIImage *image){
            
#ifdef OL_KITE_OFFER_ADOBE
            [[AdobeUXAuthManager sharedManager] setAuthenticationParametersWithClientID:[OLKitePrintSDK adobeCreativeSDKClientID] clientSecret:[OLKitePrintSDK adobeCreativeSDKClientSecret] enableSignUp:true];
            [AdobeImageEditorCustomization setCropToolPresets:@[@{kAdobeImageEditorCropPresetName:@"", kAdobeImageEditorCropPresetWidth:@1, kAdobeImageEditorCropPresetHeight:[NSNumber numberWithDouble:imageView.frame.size.height / imageView.frame.size.width]}]];
            [AdobeImageEditorCustomization setCropToolCustomEnabled:NO];
            [AdobeImageEditorCustomization setCropToolInvertEnabled:NO];
            [AdobeImageEditorCustomization setCropToolOriginalEnabled:NO];
            
            
            AdobeUXImageEditorViewController *editorController = [[AdobeUXImageEditorViewController alloc] initWithImage:image];
            [editorController setDelegate:self];
            [self presentViewController:editorController animated:YES completion:nil];
#else
            OLScrollCropViewController *cropVc = [self.storyboard instantiateViewControllerWithIdentifier:@"OLScrollCropViewController"];
            cropVc.delegate = self;
            cropVc.aspectRatio = imageView.frame.size.height / imageView.frame.size.width;
            
            cropVc.previewView = [imageView snapshotViewAfterScreenUpdates:YES];
            cropVc.previewView.frame = [imageView.superview convertRect:imageView.frame toView:nil];
            cropVc.previewSourceView = imageView;
            cropVc.providesPresentationContextTransitionStyle = true;
            cropVc.definesPresentationContext = true;
            cropVc.modalPresentationStyle = UIModalPresentationOverCurrentContext;
            [cropVc setFullImage:image];
            cropVc.edits = self.croppingPrintPhoto.edits;
            [self presentViewController:cropVc animated:NO completion:NULL];
#endif
            
#ifndef OL_NO_ANALYTICS
            [OLAnalytics trackReviewScreenEnteredCropScreenForProductName:self.product.productTemplate.name];
#endif
        }];
    }
}

- (void)onPanGestureRecognized:(UIPanGestureRecognizer *)recognizer{
    if (self.animating){
        return;
    }
    CGPoint translation = [recognizer translationInView:self.containerView];
    BOOL draggingLeft = translation.x < 0;
    BOOL draggingRight = translation.x > 0;
    
    if (([self isContainerViewAtRightEdge:NO] && draggingLeft) || ([self isContainerViewAtLeftEdge:NO] && draggingRight)){
        if (draggingLeft && [self isBookAtEnd]) {
            recognizer.enabled = NO;
            recognizer.enabled = YES;
            [self closeBookBackForGesture:recognizer];
        }
        else if (draggingRight && [self isBookAtStart]) {
            recognizer.enabled = NO;
            recognizer.enabled = YES;
            [self closeBookFrontForGesture:recognizer];
        }
        return;
    }
    
    if ([self isContainerViewAtLeftEdge:NO] && [self isContainerViewAtRightEdge:NO]){
        return;
    }
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8){
        return;
    }
    
    if (!(([self isContainerViewAtLeftEdge:NO] && draggingRight) || ([self isContainerViewAtRightEdge:NO] && draggingLeft))){
        
        self.containerView.transform = CGAffineTransformTranslate(self.containerView.transform, translation.x, 0);
        [recognizer setTranslation:CGPointMake(0, 0) inView:self.containerView];
        
        if ([self isContainerViewAtRightEdge:NO]){
            if ([[[UIDevice currentDevice] systemVersion] floatValue] < 9){
                recognizer.enabled = NO;
                recognizer.enabled = YES;
            }
            [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionBeginFromCurrentState  animations:^{
                self.containerView.transform = CGAffineTransformMakeTranslation(-self.containerView.frame.size.width + self.view.frame.size.width - kBookEdgePadding * 2, 0);
            } completion:NULL];
        }
        else if ([self isContainerViewAtLeftEdge:NO]){
            [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionBeginFromCurrentState  animations:^{
                self.containerView.transform = CGAffineTransformMakeTranslation(0, 0);
            } completion:NULL];
        }
    }
    
    if (recognizer.state == UIGestureRecognizerStateEnded){
        self.containerView.frame = CGRectMake(self.containerView.frame.origin.x + self.containerView.transform.tx, self.containerView.frame.origin.y, self.containerView.frame.size.width, self.containerView.frame.size.height);
        self.containerView.transform = CGAffineTransformIdentity;
        [self.dynamicAnimator addBehavior:self.inertiaBehavior];
        [self.inertiaBehavior addItem:self.containerView];
        [self.inertiaBehavior addLinearVelocity:CGPointMake([recognizer velocityInView:self.containerView].x, 0) forItem:self.containerView];
        self.inertiaBehavior.resistance = 3;
        __weak OLPhotobookViewController *welf = self;
        self.animating = YES;
        self.stranded = NO;
        [self.inertiaBehavior setAction:^{
            if ([welf isContainerViewAtRightEdge:YES] ){
                welf.animating = NO;
                [welf.inertiaBehavior removeItem:welf.containerView];
                [welf.dynamicAnimator removeBehavior:welf.inertiaBehavior];
                
                welf.containerView.transform = CGAffineTransformMakeTranslation(-welf.containerView.frame.size.width + welf.view.frame.size.width - kBookEdgePadding * 2, 0);
                
                [welf.view setNeedsLayout];
                [welf.view layoutIfNeeded];
                welf.stranded = NO;
            }
            else if ([welf isContainerViewAtLeftEdge:YES] && [self.inertiaBehavior linearVelocityForItem:welf.containerView].x > 0){
                welf.animating = NO;
                [welf.inertiaBehavior removeItem:welf.containerView];
                [welf.dynamicAnimator removeBehavior:welf.inertiaBehavior];
                
                welf.containerView.transform = CGAffineTransformIdentity;
                
                [welf.view setNeedsLayout];
                [welf.view layoutIfNeeded];
                welf.stranded = NO;
            }
            
            else if ([welf.inertiaBehavior linearVelocityForItem:welf.containerView].x < 15 && [welf.inertiaBehavior linearVelocityForItem:welf.containerView].x > -15 && !welf.stranded){
                welf.animating = NO;
                [welf.inertiaBehavior removeItem:welf.containerView];
                welf.stranded = YES;
            }
        }];
    }
}

- (void)onLongPressGestureRecognized:(UILongPressGestureRecognizer *)sender{
    if ([sender locationInView:self.pageController.view].x < self.pageController.view.frame.size.width / 2.0){
        self.croppingImageIndex = 0;
    }
    else{
        self.croppingImageIndex = 1;
    }
    OLPhotobookPageContentViewController *page = [self.pageController.viewControllers objectAtIndex:self.croppingImageIndex];
    NSInteger index = [page imageIndexForPoint:[sender locationInView:page.view]];
    [self.photobookDelegate photobook:self userDidLongPressOnImageWithIndex:index sender:sender];
}

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]] || [otherGestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]){
        return NO;
    }
    else if (([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]] && [otherGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) && ![otherGestureRecognizer.view isKindOfClass:[UICollectionView class]]){
        CGPoint translation = [(UIPanGestureRecognizer *)gestureRecognizer translationInView:self.containerView];
        BOOL draggingLeft = translation.x < 0;
        BOOL draggingRight = translation.x > 0;
        
        if (([self isContainerViewAtRightEdge:NO] && draggingLeft) || ([self isContainerViewAtLeftEdge:NO] && draggingRight)){
            return YES;
        }
        return NO;
    }
    return YES;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer{
    if (gestureRecognizer == self.pageControllerPanGesture){
        CGPoint translation = [(UIPanGestureRecognizer *)gestureRecognizer translationInView:self.containerView];
        BOOL draggingLeft = translation.x < 0;
        BOOL draggingRight = translation.x > 0;
        if (draggingLeft && [self isBookAtEnd]){
            return NO;
        }
        if (draggingRight && [self isBookAtStart]){
            return NO;
        }
    }
    return !self.animating;
}

#pragma mark - Book related methods

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed{
    self.animating = NO;
    if (completed){
        OLPhotobookPageContentViewController *vc1 = [pageViewController.viewControllers firstObject];
        OLPhotobookPageContentViewController *vc2 = [pageViewController.viewControllers lastObject];
        self.pagesLabel.text = [NSString stringWithFormat:@"%ld-%ld of %ld", (long)vc1.pageIndex+1, (long)vc2.pageIndex+1, (long)self.product.quantityToFulfillOrder];
        
        [UIView animateWithDuration:kBookAnimationTime/2.0 animations:^{
            if ([(OLPhotobookPageContentViewController *)[previousViewControllers firstObject] pageIndex] < vc1.pageIndex){
                self.containerView.transform = CGAffineTransformIdentity;
            }
            else if (![self isContainerViewAtRightEdge:NO]){
                self.containerView.transform = CGAffineTransformMakeTranslation([self xTrasformForBookAtRightEdge], 0);
            }
        }];
    }
}

- (void)setupCoverContentInView:(UIView *)halfBookCoverImageContainer{
    OLPopupOptionsImageView *coverImageView = [[OLPopupOptionsImageView alloc] initWithFrame:CGRectMake(0, 0, self.bookCover.frame.size.width / 2.0, self.bookCover.frame.size.height)];
    self.coverImageView = coverImageView;
    [self loadCoverPhoto];
    coverImageView.tag = 18;
    coverImageView.contentMode = UIViewContentModeScaleAspectFill;
    coverImageView.clipsToBounds = YES;
    [halfBookCoverImageContainer addSubview:coverImageView];
    coverImageView.translatesAutoresizingMaskIntoConstraints = NO;
}

-(void) setUpBookCoverViewForGesture:(UIPanGestureRecognizer *)sender{
    UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(openBook:)];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onCoverTapRecognized:)];
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onCoverLongPressRecognized:)];
    
    UIView *halfBookCoverImageContainer;
    
    CGPoint translation = [sender translationInView:self.containerView];
    BOOL draggingRight = translation.x >= 0;
    
    if ([self isBookAtStart] && (!sender || draggingRight)){
        halfBookCoverImageContainer = [self.bookCover viewWithTag:kTagRight];
        [self.bookCover viewWithTag:kTagLeft].hidden = YES;
        if (!halfBookCoverImageContainer){
            halfBookCoverImageContainer = [[UIView alloc] init];
            halfBookCoverImageContainer.tag = kTagRight;
            swipe.direction = UISwipeGestureRecognizerDirectionLeft;
            
            UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamedInKiteBundle:[self productAspectRatio]/2.0 < 1 ? @"book-cover-right" : @"book-cover-right-landscape"]];
            imageView.contentMode = UIViewContentModeScaleAspectFill;
            [imageView makeRoundRectWithRadius:3];
            imageView.tag = 17;
            [halfBookCoverImageContainer addSubview:imageView];
            
            [self.bookCover addSubview:halfBookCoverImageContainer];
            
            halfBookCoverImageContainer.userInteractionEnabled = YES;
            [halfBookCoverImageContainer addGestureRecognizer:tap];
            if (!self.editMode){
                [halfBookCoverImageContainer addGestureRecognizer:swipe];
            }
            
            halfBookCoverImageContainer.layer.shadowOffset = CGSizeMake(-10, 10);
            halfBookCoverImageContainer.layer.shadowRadius = 5;
            halfBookCoverImageContainer.layer.shadowOpacity = 0.0;
            halfBookCoverImageContainer.layer.shouldRasterize = YES;
            halfBookCoverImageContainer.layer.rasterizationScale = [UIScreen mainScreen].scale;
            
            [self setupCoverContentInView:halfBookCoverImageContainer];
            
            if (self.editMode){
                OLPopupOptionsImageView *coverImageView = [halfBookCoverImageContainer viewWithTag:18];
                coverImageView.userInteractionEnabled = YES;
                [coverImageView addGestureRecognizer:tap];
                [coverImageView addGestureRecognizer:longPress];
            }
        }
        
        [halfBookCoverImageContainer removeConstraints:halfBookCoverImageContainer.constraints];
        UIView *view = halfBookCoverImageContainer;
        view.translatesAutoresizingMaskIntoConstraints = NO;
        NSDictionary *views = NSDictionaryOfVariableBindings(view);
        NSMutableArray *con = [[NSMutableArray alloc] init];
        
        NSArray *visuals = @[@"H:[view]-0-|",
                             @"V:|-0-[view]-0-|"];
        
        
        for (NSString *visual in visuals) {
            [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
        }
        
        [view.superview addConstraints:con];
        [view.superview addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:view.superview attribute:NSLayoutAttributeWidth multiplier:0.5 constant:1]];
        
        view = [halfBookCoverImageContainer viewWithTag:17];
        [view removeConstraints:view.constraints];
        view.translatesAutoresizingMaskIntoConstraints = NO;
        views = NSDictionaryOfVariableBindings(view);
        con = [[NSMutableArray alloc] init];
        
        visuals = @[@"H:|-0-[view]-0-|",
                    @"V:|-0-[view]-0-|"];
        
        
        for (NSString *visual in visuals) {
            [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
        }
        
        [view.superview addConstraints:con];
        
        UIView *coverImageView = [halfBookCoverImageContainer viewWithTag:18];
        [halfBookCoverImageContainer addConstraint:[NSLayoutConstraint constraintWithItem:coverImageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:halfBookCoverImageContainer attribute:NSLayoutAttributeWidth multiplier:0.8 constant:0]];
        [halfBookCoverImageContainer addConstraint:[NSLayoutConstraint constraintWithItem:coverImageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:halfBookCoverImageContainer attribute:NSLayoutAttributeHeight multiplier:0.9 constant:0]];
        [halfBookCoverImageContainer addConstraint:[NSLayoutConstraint constraintWithItem:halfBookCoverImageContainer attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:coverImageView attribute:NSLayoutAttributeCenterX multiplier:0.97 constant:0]];
        [halfBookCoverImageContainer addConstraint:[NSLayoutConstraint constraintWithItem:coverImageView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:halfBookCoverImageContainer attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
        
        if (self.editMode){
            [[halfBookCoverImageContainer viewWithTag:1234] removeFromSuperview];
            UILabel *helpLabel = [[UILabel alloc] init];
            helpLabel.tag = 1234;
            helpLabel.font = [UIFont systemFontOfSize:11];
            helpLabel.text = NSLocalizedString(@"Tap to edit", @"");
            helpLabel.translatesAutoresizingMaskIntoConstraints = NO;
            self.coverHelpLabel = helpLabel;
            [halfBookCoverImageContainer insertSubview:helpLabel belowSubview:coverImageView];
            [halfBookCoverImageContainer addConstraint:[NSLayoutConstraint constraintWithItem:halfBookCoverImageContainer attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:helpLabel attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
            [halfBookCoverImageContainer addConstraint:[NSLayoutConstraint constraintWithItem:halfBookCoverImageContainer attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:helpLabel attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
        }
        
        [self.bookCover viewWithTag:kTagRight].hidden = NO;
    }
    else{
        [self.bookCover viewWithTag:kTagRight].hidden = YES;
        halfBookCoverImageContainer = [self.bookCover viewWithTag:kTagLeft];
        if (!halfBookCoverImageContainer){
            halfBookCoverImageContainer = [[UIView alloc] init];
            halfBookCoverImageContainer.tag = kTagLeft;
            swipe.direction = UISwipeGestureRecognizerDirectionRight;
            [self.bookCover addSubview:halfBookCoverImageContainer];
            halfBookCoverImageContainer.userInteractionEnabled = YES;
            [halfBookCoverImageContainer addGestureRecognizer:tap];
            [halfBookCoverImageContainer addGestureRecognizer:swipe];
            
            UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamedInKiteBundle:[self productAspectRatio]/2.0 < 1 ? @"book-cover-left" : @"book-cover-left-landscape"]];
            imageView.contentMode = UIViewContentModeScaleAspectFill;
            [imageView makeRoundRectWithRadius:3];
            [halfBookCoverImageContainer addSubview:imageView];
            
            halfBookCoverImageContainer.layer.shadowOffset = CGSizeMake(-10, 10);
            halfBookCoverImageContainer.layer.shadowRadius = 5;
            halfBookCoverImageContainer.layer.shadowOpacity = 0.0;
            halfBookCoverImageContainer.layer.shouldRasterize = YES;
            halfBookCoverImageContainer.layer.rasterizationScale = [UIScreen mainScreen].scale;
        }
        
        
        halfBookCoverImageContainer.frame = CGRectMake(0, 0, self.bookCover.frame.size.width / 2.0, self.bookCover.frame.size.height);
        [[[halfBookCoverImageContainer subviews] firstObject] setFrame:halfBookCoverImageContainer.frame];
        [self.bookCover viewWithTag:kTagLeft].hidden = NO;
    }
}

- (BOOL)isBookAtStart{
    if (self.editMode){
        return YES;
    }
    OLPhotobookPageContentViewController *vc1 = [self.pageController.viewControllers firstObject];
    return vc1.pageIndex == 0;
}

- (BOOL)isBookAtEnd{
    if (self.editMode){
        return YES;
    }
    OLPhotobookPageContentViewController *vc2 = [self.pageController.viewControllers lastObject];
    return vc2.pageIndex == self.photobookPhotos.count - 1;
}

- (void)openBook:(UIGestureRecognizer *)sender{
    if (self.animating){
        return;
    }
    self.animating = YES;
    self.userHasOpenedBook = YES;
    
    [UIView animateWithDuration:kBookAnimationTime animations:^{
        self.containerView.transform = CGAffineTransformIdentity;
    }completion:^(BOOL completed){}];
    MPFlipStyle style = sender.view.tag == kTagRight ? MPFlipStyleDefault : MPFlipStyleDirectionBackward;
    MPFlipTransition *flipTransition = [[MPFlipTransition alloc] initWithSourceView:self.bookCover destinationView:self.openbookView duration:kBookAnimationTime timingCurve:UIViewAnimationCurveEaseInOut completionAction:MPTransitionActionNone];
    flipTransition.style = style;
    [flipTransition perform:^(BOOL finished){
        self.bookClosed = NO;
        [UIView animateWithDuration:kBookAnimationTime/2.0 animations:^{
            self.pagesLabelContainer.alpha = 1;
        }];
        
        self.openbookView.hidden = NO;
        
        //Fade out shadow of the half-book.
        UIView *closedPage = [self.bookCover viewWithTag:sender.view.tag];
        CABasicAnimation *showAnim = [CABasicAnimation animationWithKeyPath:@"shadowOpacity"];
        showAnim.fromValue = [NSNumber numberWithFloat:0.25];
        showAnim.toValue = [NSNumber numberWithFloat:0.0];
        showAnim.duration = kBookAnimationTime/4.0;
        showAnim.removedOnCompletion = NO;
        showAnim.fillMode = kCAFillModeForwards;
        [closedPage.layer addAnimation:showAnim forKey:@"shadowOpacity"];
        
        //Fade in shadow of the book cover
        CABasicAnimation *hideAnim = [CABasicAnimation animationWithKeyPath:@"shadowOpacity"];
        hideAnim.fromValue = [NSNumber numberWithFloat:0.0];
        hideAnim.toValue = [NSNumber numberWithFloat:0.25];
        hideAnim.duration = kBookAnimationTime/4.0;
        hideAnim.removedOnCompletion = NO;
        hideAnim.fillMode = kCAFillModeForwards;
        [self.containerView.layer addAnimation:hideAnim forKey:@"shadowOpacity"];
        
        CABasicAnimation *cornerAnim = [CABasicAnimation animationWithKeyPath:@"cornerRadius"];
        cornerAnim.fromValue = @3;
        cornerAnim.toValue = @0;
        cornerAnim.duration = kBookAnimationTime/4.0;
        cornerAnim.removedOnCompletion = NO;
        cornerAnim.fillMode = kCAFillModeForwards;
        [self.fakeShadowView.layer addAnimation:cornerAnim forKey:@"cornerRadius"];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, kBookAnimationTime/4.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            self.animating = NO;
            self.containerView.layer.shadowOpacity = 0.25;
            self.bookCover.hidden = YES;
        });
    }];
    
    
}

- (void)closeBookFrontForGesture:(UIPanGestureRecognizer *)sender{
    if (self.animating || self.editMode){
        return;
    }
    self.animating = YES;
    [self setUpBookCoverViewForGesture:sender];
    self.bookCover.hidden = NO;
    
    //Fade in shadow of the half-book.
    UIView *closedPage = [self.bookCover viewWithTag:kTagRight];
    CABasicAnimation *showAnim = [CABasicAnimation animationWithKeyPath:@"shadowOpacity"];
    showAnim.fromValue = [NSNumber numberWithFloat:0.0];
    showAnim.toValue = [NSNumber numberWithFloat:0.25];
    showAnim.duration = kBookAnimationTime/4.0;
    [closedPage.layer addAnimation:showAnim forKey:@"shadowOpacity"];
    closedPage.layer.shadowOpacity = 0.25;
    
    //Fade out shadow of the book cover
    CABasicAnimation *hideAnim = [CABasicAnimation animationWithKeyPath:@"shadowOpacity"];
    hideAnim.fromValue = [NSNumber numberWithFloat:0.25];
    hideAnim.toValue = [NSNumber numberWithFloat:0.0];
    hideAnim.duration = kBookAnimationTime/4.0;
    [self.containerView.layer addAnimation:hideAnim forKey:@"shadowOpacity"];
    self.containerView.layer.shadowOpacity = 0.0;
    
    [UIView animateWithDuration:kBookAnimationTime/8.0 animations:^{
        self.pagesLabelContainer.alpha = 0;
    }];
    
    if (![self isContainerViewAtRightEdge:NO]){
        [UIView animateWithDuration:kBookAnimationTime animations:^{
            self.containerView.transform = CGAffineTransformMakeTranslation([self xTrasformForBookAtRightEdge], 0);
        }];
    }
    
    MPFlipTransition *flipTransition = [[MPFlipTransition alloc] initWithSourceView:self.openbookView destinationView:self.bookCover duration:kBookAnimationTime timingCurve:UIViewAnimationCurveEaseInOut completionAction:MPTransitionActionShowHide];
    flipTransition.flippingPageShadowOpacity = 0;
    flipTransition.style = MPFlipStyleDirectionBackward;
    [flipTransition perform:^(BOOL finished){
        self.animating = NO;
        
        CABasicAnimation *cornerAnim = [CABasicAnimation animationWithKeyPath:@"cornerRadius"];
        cornerAnim.fromValue = @0;
        cornerAnim.toValue = @3;
        cornerAnim.duration = kBookAnimationTime/4.0;
        cornerAnim.removedOnCompletion = NO;
        cornerAnim.fillMode = kCAFillModeForwards;
        [self.fakeShadowView.layer addAnimation:cornerAnim forKey:@"cornerRadius"];
        
        self.bookClosed = YES;
    }];
}
- (void)closeBookBackForGesture:(UIPanGestureRecognizer *)sender{
    if (self.animating || self.editMode){
        return;
    }
    self.animating = YES;
    [self setUpBookCoverViewForGesture:sender];
    self.bookCover.hidden = NO;
    
    // Turn off containerView shadow because we will be animating that. Will use bookCover view shadow for the duration of the animation.
    self.containerView.layer.shadowOpacity = 0;
    
    //Fade in shadow of the half-book.
    UIView *closedPage = [self.bookCover viewWithTag:kTagLeft];
    CABasicAnimation *showAnim = [CABasicAnimation animationWithKeyPath:@"shadowOpacity"];
    showAnim.fromValue = [NSNumber numberWithFloat:0.0];
    showAnim.toValue = [NSNumber numberWithFloat:0.25];
    showAnim.duration = kBookAnimationTime/4.0;
    [closedPage.layer addAnimation:showAnim forKey:@"shadowOpacity"];
    closedPage.layer.shadowOpacity = 0.25;
    
    //Fade out shadow of the book cover
    CABasicAnimation *hideAnim = [CABasicAnimation animationWithKeyPath:@"shadowOpacity"];
    hideAnim.fromValue = [NSNumber numberWithFloat:0.25];
    hideAnim.toValue = [NSNumber numberWithFloat:0.0];
    hideAnim.duration = kBookAnimationTime/4.0;
    [self.containerView.layer addAnimation:hideAnim forKey:@"shadowOpacity"];
    self.containerView.layer.shadowOpacity = 0.0;
    
    [UIView animateWithDuration:kBookAnimationTime/8.0 animations:^{
        self.pagesLabelContainer.alpha = 0;
    }];
    
    [UIView animateWithDuration:kBookAnimationTime/2.0
                          delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.containerView.transform = CGAffineTransformIdentity;
                     } completion:^(BOOL finished){}];
    MPFlipTransition *flipTransition = [[MPFlipTransition alloc] initWithSourceView:self.openbookView destinationView:self.bookCover duration:kBookAnimationTime timingCurve:UIViewAnimationCurveEaseInOut completionAction:MPTransitionActionShowHide];
    flipTransition.flippingPageShadowOpacity = 0;
    flipTransition.style = MPFlipStyleDefault;
    [flipTransition perform:^(BOOL finished){
        self.animating = NO;
        [self.fakeShadowView makeRoundRectWithRadius:3];
    }];
    self.bookClosed = YES;
}

- (CGFloat)xTrasformForBookAtRightEdge{
    return self.view.frame.size.width - self.containerView.frame.size.width - kBookEdgePadding * 2;
}

- (BOOL)isContainerViewAtRightEdge:(BOOL)useFrame{
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8){
        return YES;
    }
    
    if (!useFrame){
        return self.containerView.transform.tx <= [self xTrasformForBookAtRightEdge] && !self.stranded;
    }
    else{
        return self.containerView.frame.origin.x - kBookEdgePadding <= [self xTrasformForBookAtRightEdge];
    }
}

- (BOOL)isContainerViewAtLeftEdge:(BOOL)useFrame{
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8){
        return YES;
    }
    
    if (!useFrame){
        return self.containerView.transform.tx >= 0 && !self.stranded;
    }
    else{
        return self.containerView.center.x - self.containerView.frame.size.width / 2  - kBookEdgePadding >= 0;
    }
}

#pragma mark - Adding new images

- (void)addMorePhotosFromView:(UIView *)view{
    NSInteger numberOfProviders = 0;
#ifdef OL_KITE_OFFER_CUSTOM_IMAGE_PROVIDERS
    NSInteger numberOfCustomProviders = [OLKiteUtils kiteVcForViewController:self].customImageProviders.count;
    numberOfProviders += numberOfCustomProviders;
#endif
    
    if ([OLKiteUtils cameraRollEnabled:self]){
        numberOfProviders++;
    }
    if ([OLKiteUtils facebookEnabled]){
        numberOfProviders++;
    }
    if ([OLKiteUtils instagramEnabled]){
        numberOfProviders++;
    }
    
    if (numberOfProviders > 1){
        if ([UIAlertController class]){
            UIAlertController *ac = [UIAlertController alertControllerWithTitle:nil message:NSLocalizedString(@"Add photos from:", @"") preferredStyle:UIAlertControllerStyleActionSheet];
            if ([OLKiteUtils cameraRollEnabled:self]){
                [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Camera Roll", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
                    [self showCameraRollImagePicker];
                }]];
            }
            if ([OLKiteUtils instagramEnabled]){
                [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Instagram", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
                    [self showInstagramImagePicker];
                }]];
            }
            if ([OLKiteUtils facebookEnabled]){
                [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Facebook", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
                    [self showFacebookImagePicker];
                }]];
            }
#ifdef OL_KITE_OFFER_CUSTOM_IMAGE_PROVIDERS
            for (OLCustomPhotoProvider *provider in [OLKiteUtils kiteVcForViewController:self].customImageProviders){
                [ac addAction:[UIAlertAction actionWithTitle:provider.name style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
                    [self showPickerForProvider:provider];
                }]];
            }
#endif
            
            [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action){
                [ac dismissViewControllerAnimated:YES completion:NULL];
            }]];
            ac.popoverPresentationController.sourceView = view;
            ac.popoverPresentationController.sourceRect = view.frame;
            [self presentViewController:ac animated:YES completion:NULL];
        }
        else{
            UIActionSheet *as = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Add photos from:", @"")
                                                            delegate:self
                                                   cancelButtonTitle:nil
                                              destructiveButtonTitle:nil
                                                   otherButtonTitles:nil];
            
            if ([OLKiteUtils cameraRollEnabled:self]){
                [as addButtonWithTitle:NSLocalizedString(@"Camera Roll", @"")];
            }
            if ([OLKiteUtils facebookEnabled]){
                [as addButtonWithTitle:@"Facebook"];
            }
            if ([OLKiteUtils instagramEnabled]){
                [as addButtonWithTitle:@"Instagram"];
            }
#ifdef OL_KITE_OFFER_CUSTOM_IMAGE_PROVIDERS
            for (OLCustomPhotoProvider *provider in [OLKiteUtils kiteVcForViewController:self].customImageProviders){
                [as addButtonWithTitle:provider.name];
            }
#endif
            as.cancelButtonIndex = [as addButtonWithTitle:@"Cancel"];
            
            [as showInView:self.view];
        }
    }
    else{
        if ([OLKiteUtils cameraRollEnabled:self]){
            [self showCameraRollImagePicker];
        }
        else if ([OLKiteUtils facebookEnabled]){
            [self showFacebookImagePicker];
        }
        else if ([OLKiteUtils instagramEnabled]){
            [self showInstagramImagePicker];
        }
#ifdef OL_KITE_OFFER_CUSTOM_IMAGE_PROVIDERS
        else{
            [self showPickerForProvider:[OLKiteUtils kiteVcForViewController:self].customImageProviders.firstObject];
        }
#endif
        
    }
}

- (void)showCameraRollImagePicker{
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackPhotoProviderPicked:@"Camera Roll" forProductName:self.product.productTemplate.name];
#endif
    __block UIViewController *picker;
    __block Class assetClass;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8 || !definesAtLeastiOS8){
        picker = [[OLAssetsPickerController alloc] init];
        [(OLAssetsPickerController *)picker setAssetsFilter:[ALAssetsFilter allPhotos]];
        assetClass = [ALAsset class];
        ((OLAssetsPickerController *)picker).delegate = self;
    }
#ifdef OL_KITE_AT_LEAST_IOS8
    else{
        if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusNotDetermined){
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status){
                if (status == PHAuthorizationStatusAuthorized){
                    picker = [[CTAssetsPickerController alloc] init];
                    ((CTAssetsPickerController *)picker).showsEmptyAlbums = NO;
                    PHFetchOptions *options = [[PHFetchOptions alloc] init];
                    options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %d", PHAssetMediaTypeImage];
                    ((CTAssetsPickerController *)picker).assetsFetchOptions = options;
                    assetClass = [PHAsset class];
                    ((CTAssetsPickerController *)picker).delegate = self;
                    picker.modalPresentationStyle = [OLKiteUtils kiteVcForViewController:self].modalPresentationStyle;
                    [self presentViewController:picker animated:YES completion:nil];
                }
            }];
        }
        else{
            picker = [[CTAssetsPickerController alloc] init];
            ((CTAssetsPickerController *)picker).showsEmptyAlbums = NO;
            PHFetchOptions *options = [[PHFetchOptions alloc] init];
            options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %d", PHAssetMediaTypeImage];
            ((CTAssetsPickerController *)picker).assetsFetchOptions = options;
            assetClass = [PHAsset class];
            ((CTAssetsPickerController *)picker).delegate = self;
        }
    }
#endif
    
    if (picker){
        picker.modalPresentationStyle = [OLKiteUtils kiteVcForViewController:self].modalPresentationStyle;
        [self presentViewController:picker animated:YES completion:nil];
    }
}

- (void)showFacebookImagePicker{
#ifdef OL_KITE_OFFER_FACEBOOK
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackPhotoProviderPicked:@"Facebook" forProductName:self.product.productTemplate.name];
#endif
    OLFacebookImagePickerController *picker = nil;
    picker = [[OLFacebookImagePickerController alloc] init];
    picker.delegate = self;
    picker.modalPresentationStyle = [OLKiteUtils kiteVcForViewController:self].modalPresentationStyle;
    [self presentViewController:picker animated:YES completion:nil];
#endif
}

- (void)showInstagramImagePicker{
#ifdef OL_KITE_OFFER_INSTAGRAM
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackPhotoProviderPicked:@"Instagram" forProductName:self.product.productTemplate.name];
#endif
    OLInstagramImagePickerController *picker = nil;
    picker = [[OLInstagramImagePickerController alloc] initWithClientId:[OLKitePrintSDK instagramClientID] secret:[OLKitePrintSDK instagramSecret] redirectURI:[OLKitePrintSDK instagramRedirectURI]];
    picker.delegate = self;
    picker.selected = @[];
    picker.modalPresentationStyle = [OLKiteUtils kiteVcForViewController:self].modalPresentationStyle;
    [self presentViewController:picker animated:YES completion:nil];
#endif
}

#ifdef OL_KITE_OFFER_CUSTOM_IMAGE_PROVIDERS
- (void)showPickerForProvider:(OLCustomPhotoProvider *)provider{
    UIViewController<KITCustomAssetPickerController> *vc;
    if (provider.vc){
        vc = provider.vc;
    }
    else{
        KITAssetsPickerController *kvc = [[KITAssetsPickerController alloc] init];
        kvc.collectionDataSources = provider.collections;
        vc = kvc;
    }
    
    vc.delegate = self;
    vc.modalPresentationStyle = [OLKiteUtils kiteVcForViewController:self].modalPresentationStyle;
    [self presentViewController:vc animated:YES completion:NULL];
}
#endif

- (void)populateArrayWithNewArray:(NSArray *)array dataType:(Class)class {
    NSMutableArray *photoArray = [[NSMutableArray alloc] initWithCapacity:array.count];
    
    for (id object in array) {
        OLPrintPhoto *printPhoto = [[OLPrintPhoto alloc] init];
        printPhoto.asset = object;
        [photoArray addObject:printPhoto];
    }
    
    //    // First remove any that are not returned.
    //    NSMutableArray *removeArray = [NSMutableArray arrayWithArray:self.userSelectedPhotos];
    //    for (OLPrintPhoto *object in self.userSelectedPhotos) {
    //        if ([object.asset isKindOfClass:[OLAsset class]] && [[object.asset dataSource] isKindOfClass:class]){
    //            if ([photoArray containsObject:object]){
    //                [removeArray removeObjectIdenticalTo:object];
    //                [photoArray removeObject:object];
    //            }
    //        }
    //        else if (![object.asset isKindOfClass:class]) {
    //            [removeArray removeObjectIdenticalTo:object];
    //        }
    //
    //        else if([photoArray containsObject:object]){
    //            [removeArray removeObjectIdenticalTo:object];
    //        }
    //    }
    //
    //    [self.userSelectedPhotos removeObjectsInArray:removeArray];
    
    // Second, add the remaining objects to the end of the array without replacing any.
    NSMutableArray *addArray = [NSMutableArray arrayWithArray:photoArray];
    //    for (id object in self.userSelectedPhotos) {
    //        if ([addArray containsObject:object]){
    //            [addArray removeObject:object];
    //        }
    //    }
    
    [self.userSelectedPhotos addObjectsFromArray:addArray];
    
    [self updatePhotobookPhotos];
    for (OLPhotobookPageContentViewController *page in self.pageController.viewControllers){
        [page loadImageWithCompletionHandler:NULL];
    }
    [self updateUserSelectedPhotos];
}

- (void)updatePhotobookPhotos{
    if (!self.photobookPhotos){
        self.userSelectedPhotosCopy = [[NSArray alloc] initWithArray:self.userSelectedPhotos copyItems:NO];
        self.photobookPhotos = [[NSMutableArray alloc] initWithCapacity:self.product.quantityToFulfillOrder];
        NSInteger start = 0;
        if (!self.coverPhoto){
            self.coverPhoto = self.userSelectedPhotos.firstObject;
            start++;
        }
        else if (self.coverPhoto == (id)[NSNull null]){
            self.coverPhoto = nil;
        }
        for (NSInteger i = start; i < self.product.quantityToFulfillOrder + start; i++){
            [self.photobookPhotos addObject:i < self.userSelectedPhotos.count ? self.userSelectedPhotos[i] : [NSNull null]];
        }
    }
    else{
        NSMutableArray *newPhotos = [NSMutableArray arrayWithArray:[self.userSelectedPhotos subarrayWithRange:NSMakeRange(0, MIN(self.userSelectedPhotos.count, self.product.quantityToFulfillOrder+1))]];
        [newPhotos removeObjectsInArray:self.userSelectedPhotosCopy];
        for (NSInteger newPhoto = 0; newPhoto < newPhotos.count; newPhoto++){
            BOOL foundSpot = NO;
            for (NSInteger bookPhoto = self.addNewPhotosAtIndex; bookPhoto < self.photobookPhotos.count && !foundSpot; bookPhoto++){
                if (self.photobookPhotos[bookPhoto] == [NSNull null]){
                    self.photobookPhotos[bookPhoto] = newPhotos[newPhoto];
                    foundSpot = YES;
                }
            }
            for (NSInteger bookPhoto = 0; bookPhoto < self.addNewPhotosAtIndex && !foundSpot; bookPhoto++){
                if (self.photobookPhotos[bookPhoto] == [NSNull null]){
                    self.photobookPhotos[bookPhoto] = newPhotos[newPhoto];
                    foundSpot = YES;
                }
            }
        }
        self.userSelectedPhotosCopy = [[NSArray alloc] initWithArray:self.userSelectedPhotos copyItems:NO];
    }
    
}

#pragma mark - CTAssetsPickerControllerDelegate Methods
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 80000
- (BOOL)assetsPickerController:(OLAssetsPickerController *)picker isDefaultAssetsGroup:(ALAssetsGroup *)group {
    if ([self.delegate respondsToSelector:@selector(kiteController:isDefaultAssetsGroup:)]) {
        return [self.delegate kiteController:[OLKiteUtils kiteVcForViewController:self] isDefaultAssetsGroup:group];
    }
    
    return NO;
}
#endif

- (void)assetsPickerController:(id)picker didFinishPickingAssets:(NSArray *)assets {
    NSInteger originalCount = self.userSelectedPhotos.count;
    Class assetClass;
    if ([picker isKindOfClass:[OLAssetsPickerController class]]){
        assetClass = [ALAsset class];
    }
#ifdef OL_KITE_AT_LEAST_IOS8
    else if ([picker isKindOfClass:[CTAssetsPickerController class]]){
        assetClass = [PHAsset class];
    }
#endif
#ifdef OL_KITE_OFFER_CUSTOM_IMAGE_PROVIDERS
    else if ([picker isKindOfClass:[KITAssetsPickerController class]]){
        NSMutableArray *olAssets = [[NSMutableArray alloc] init];
        for (id<OLAssetDataSource> asset in assets){
            if ([asset respondsToSelector:@selector(dataWithCompletionHandler:)]){
                [olAssets addObject:[OLAsset assetWithDataSource:asset]];
            }
        }
        assets = olAssets;
        assetClass = [[assets.firstObject dataSource] class];
    }
#endif
    
    if (self.addNewPhotosAtIndex == -1){
        self.coverPhoto = [[OLPrintPhoto alloc] init];
        self.coverPhoto.asset = [assets firstObject];
        assets = [assets subarrayWithRange:NSMakeRange(1, assets.count - 1)];
        self.addNewPhotosAtIndex = 0;
        
        for (OLPhotobookViewController *photobook in self.childViewControllers){
            if ([photobook bookClosed]){
                photobook.coverPhoto = self.coverPhoto;
                [photobook loadCoverPhoto];
                break;
            }
        }
    }
    
    [self populateArrayWithNewArray:assets dataType:assetClass];
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackPhotoProvider:@"Camera Roll" numberOfPhotosAdded:self.userSelectedPhotos.count - originalCount forProductName:self.product.productTemplate.name];
#endif
    
    [picker dismissViewControllerAnimated:YES completion:^(void){}];
    
}

- (BOOL)assetsPickerController:(OLAssetsPickerController *)picker shouldShowAssetsGroup:(ALAssetsGroup *)group{
    if (group.numberOfAssets == 0){
        return NO;
    }
    return YES;
}


#ifdef OL_KITE_AT_LEAST_IOS8
- (void)assetsPickerController:(CTAssetsPickerController *)picker didDeSelectAsset:(PHAsset *)asset{
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8){
        return;
    }
    if (![asset isKindOfClass:[PHAsset class]]){
        return;
    }
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.networkAccessAllowed = YES;
    [[OLImageCachingManager sharedInstance].photosCachingManager stopCachingImagesForAssets:@[asset] targetSize:PHImageManagerMaximumSize contentMode:PHImageContentModeAspectFill options:options];
}

- (void)assetsPickerController:(CTAssetsPickerController *)picker didSelectAsset:(PHAsset *)asset{
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8){
        return;
    }
    if (![asset isKindOfClass:[PHAsset class]]){
        return;
    }
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.networkAccessAllowed = YES;
    [[OLImageCachingManager sharedInstance].photosCachingManager startCachingImagesForAssets:@[asset] targetSize:PHImageManagerMaximumSize contentMode:PHImageContentModeAspectFill options:options];
}
#endif

- (BOOL)assetsPickerController:(OLAssetsPickerController *)picker shouldShowAsset:(id)asset{
    NSString *fileName = [[[asset defaultRepresentation] filename] lowercaseString];
    if (!([fileName hasSuffix:@".jpg"] || [fileName hasSuffix:@".jpeg"] || [fileName hasSuffix:@"png"] || [fileName hasSuffix:@"tiff"])) {
        return NO;
    }
    return YES;
}

- (BOOL)assetsPickerController:(id)picker shouldSelectAsset:(id)asset{
    NSArray *assets;
    if ([picker respondsToSelector:@selector(selectedAssets)]){
        assets = [picker selectedAssets];
    }
    else if ([picker respondsToSelector:@selector(selected)]){
        assets = [picker selected];
    }
    else{ // ¯\_(ツ)_/¯
        return YES;
    }
    
    NSInteger max = self.product.quantityToFulfillOrder;
    NSInteger current = self.userSelectedPhotos.count + assets.count;
    if (self.addNewPhotosAtIndex == -1){
        max++;
    }
    
    if (current >= max){
        if ([UIAlertController class]){
            UIAlertController *alert =
            [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Maximum Photos Reached", @"")
                                                message:[NSString stringWithFormat:max == 1 ? NSLocalizedString(@"Please select only %ld photo", @"") : NSLocalizedString(@"Please select not more than %ld photos total", @""), (long)max]
                                         preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *action =
            [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"")
                                     style:UIAlertActionStyleDefault
                                   handler:nil];
            
            [alert addAction:action];
            
            [picker presentViewController:alert animated:YES completion:nil];
        }
        else{
            UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Maximum Photos Reached", @"") message:[NSString stringWithFormat:max == 1 ? NSLocalizedString(@"Please select only %ld photo", @"") : NSLocalizedString(@"Please select not more than %ld photos total", @""), (long)max] delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
            [av show];
        }
        return NO;
    }
    
    return YES;
}


#ifdef OL_KITE_OFFER_INSTAGRAM
#pragma mark - OLInstagramImagePickerControllerDelegate Methods

- (void)instagramImagePicker:(OLInstagramImagePickerController *)imagePicker didFailWithError:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)instagramImagePicker:(OLInstagramImagePickerController *)imagePicker didFinishPickingImages:(NSArray *)images {
    NSInteger originalCount = self.userSelectedPhotos.count;
#ifdef OL_KITE_OFFER_CUSTOM_IMAGE_PROVIDERS
    NSMutableArray *assets = [[NSMutableArray alloc] init];
    for (id<OLAssetDataSource> asset in images){
        if ([asset isKindOfClass:[OLInstagramImage class]]){
            [assets addObject:asset];
        }
    }
    images = assets;
#endif
    
    if (self.addNewPhotosAtIndex == -1){
        if (images.count > 0){
            self.coverPhoto = [[OLPrintPhoto alloc] init];
            self.coverPhoto.asset = [images firstObject];
            images = [images subarrayWithRange:NSMakeRange(1, images.count - 1)];
            self.addNewPhotosAtIndex = 0;
        }
        
        for (OLPhotobookViewController *photobook in self.childViewControllers){
            if ([photobook bookClosed]){
                photobook.coverPhoto = self.coverPhoto;
                [photobook loadCoverPhoto];
                break;
            }
        }
    }
    
    [self populateArrayWithNewArray:images dataType:[OLInstagramImage class]];
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackPhotoProvider:@"Instagram" numberOfPhotosAdded:self.userSelectedPhotos.count - originalCount forProductName:self.product.productTemplate.name];
#endif
    [self dismissViewControllerAnimated:YES completion:^(void){}];
}

- (void)instagramImagePickerDidCancelPickingImages:(OLInstagramImagePickerController *)imagePicker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)instagramImagePicker:(OLInstagramImagePickerController *)imagePicker shouldSelectImage:(OLInstagramImage *)image{
    NSInteger max = self.product.quantityToFulfillOrder;
    NSInteger current = self.userSelectedPhotos.count + imagePicker.selected.count;
    if (self.addNewPhotosAtIndex == -1){
        max++;
    }
    
    if (current >= max){
        if ([UIAlertController class]){
            UIAlertController *alert =
            [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Maximum Photos Reached", @"")
                                                message:[NSString stringWithFormat:self.product.quantityToFulfillOrder == 1 ? NSLocalizedString(@"Please select only %ld photo", @"") : NSLocalizedString(@"Please select not more than %ld photos total", @""), max]
                                         preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *action =
            [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"")
                                     style:UIAlertActionStyleDefault
                                   handler:nil];
            
            [alert addAction:action];
            
            [imagePicker presentViewController:alert animated:YES completion:nil];
        }
        else{
            UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Maximum Photos Reached", @"") message:[NSString stringWithFormat:self.product.quantityToFulfillOrder == 1 ? NSLocalizedString(@"Please select only %ld photo", @"") : NSLocalizedString(@"Please select not more than %ld photos total", @""), max] delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
            [av show];
        }
        return NO;
    }
    return YES;
}
#endif

#ifdef OL_KITE_OFFER_FACEBOOK
#pragma mark - OLFacebookImagePickerControllerDelegate Methods

- (void)facebookImagePicker:(OLFacebookImagePickerController *)imagePicker didFailWithError:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)facebookImagePicker:(OLFacebookImagePickerController *)imagePicker didFinishPickingImages:(NSArray *)images {
    NSInteger originalCount = self.userSelectedPhotos.count;
#ifdef OL_KITE_OFFER_CUSTOM_IMAGE_PROVIDERS
    NSMutableArray *assets = [[NSMutableArray alloc] init];
    for (id<OLAssetDataSource> asset in images){
        if ([asset isKindOfClass:[OLFacebookImage class]]){
            [assets addObject:asset];
        }
    }
    images = assets;
#endif
    
    if (self.addNewPhotosAtIndex == -1){
        if (images.count > 0){
            self.coverPhoto = [[OLPrintPhoto alloc] init];
            self.coverPhoto.asset = [images firstObject];
            images = [images subarrayWithRange:NSMakeRange(1, images.count - 1)];
            self.addNewPhotosAtIndex = 0;
        }
        
        for (OLPhotobookViewController *photobook in self.childViewControllers){
            if ([photobook bookClosed]){
                photobook.coverPhoto = self.coverPhoto;
                [photobook loadCoverPhoto];
                break;
            }
        }
    }
    [self populateArrayWithNewArray:images dataType:[OLFacebookImage class]];
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackPhotoProvider:@"Facebook" numberOfPhotosAdded:self.userSelectedPhotos.count - originalCount forProductName:self.product.productTemplate.name];
#endif
    [self dismissViewControllerAnimated:YES completion:^(void){}];
}

- (void)facebookImagePickerDidCancelPickingImages:(OLFacebookImagePickerController *)imagePicker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)facebookImagePicker:(OLFacebookImagePickerController *)imagePicker shouldSelectImage:(OLFacebookImage *)image{
    NSInteger max = self.product.quantityToFulfillOrder;
    NSInteger current = self.userSelectedPhotos.count + imagePicker.selected.count;
    if (self.addNewPhotosAtIndex == -1){
        max++;
    }
    
    if (current >= max){
        if ([UIAlertController class]){
            UIAlertController *alert =
            [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Maximum Photos Reached", @"")
                                                message:[NSString stringWithFormat:self.product.quantityToFulfillOrder == 1 ? NSLocalizedString(@"Please select only %ld photo", @"") : NSLocalizedString(@"Please select not more than %ld photos total", @""), max]
                                         preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *action =
            [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"")
                                     style:UIAlertActionStyleDefault
                                   handler:nil];
            
            [alert addAction:action];
            
            [imagePicker presentViewController:alert animated:YES completion:nil];
        }
        else{
            UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Maximum Photos Reached", @"") message:[NSString stringWithFormat:self.product.quantityToFulfillOrder == 1 ? NSLocalizedString(@"Please select only %ld photo", @"") : NSLocalizedString(@"Please select not more than %ld photos total", @""), max] delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
            [av show];
        }
        return NO;
    }
    return YES;
}
#endif

#pragma mark UIActionSheet Delegate (only used on iOS 7)

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if (buttonIndex == [OLKiteUtils cameraRollProviderIndex:self]){
            [self showCameraRollImagePicker];
        }
        else if (buttonIndex == [OLKiteUtils instagramProviderIndex:self]){
            [self showInstagramImagePicker];
        }
        else if (buttonIndex == [OLKiteUtils facebookProviderIndex:self]){
            [self showFacebookImagePicker];
        }
#ifdef OL_KITE_OFFER_CUSTOM_IMAGE_PROVIDERS
        else{
            [self showPickerForProvider:[OLKiteUtils kiteVcForViewController:self].customImageProviders[buttonIndex - [OLKiteUtils customProvidersStartIndex:self]]];
        }
#endif
    });
}

#pragma mark - Autorotate and Orientation Methods
// Currently here to disable landscape orientations and rotation on iOS 7. When support is dropped, these can be deleted.

- (BOOL)shouldAutorotate {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8) {
        return YES;
    }
    else{
        return NO;
    }
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8) {
        return UIInterfaceOrientationMaskAll;
    }
    else{
        return UIInterfaceOrientationMaskLandscape;
    }
}

@end
