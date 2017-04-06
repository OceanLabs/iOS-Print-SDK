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

#import "OLFlipTransition.h"
#import "NSObject+Utils.h"
#import "OLAnalytics.h"
#import "OLImageCachingManager.h"
#import "OLKiteABTesting.h"
#import "OLKitePrintSDK.h"
#import "OLKiteUtils.h"
#import "OLPaymentViewController.h"
#import "OLPhotobookPageContentViewController.h"
#import "OLPhotobookPrintJob.h"
#import "OLPhotobookViewController.h"
#import "OLPopupOptionsImageView.h"
#import "OLProduct.h"
#import "OLProductTemplate.h"
#import "OLImageEditViewController.h"
#import "UIImage+ImageNamedInKiteBundle.h"
#import "UIView+RoundRect.h"
#import "OLUpsellViewController.h"
#import "OLProductRepresentation.h"
#import "OLPageLayout.h"
#import "OLPhotobookPageBlankContentViewController.h"
#import "OLUserSession.h"
#import "OLAsset+Private.h"
#import "UIImage+ImageNamedInKiteBundle.h"
#import "OLKiteABTesting.h"
#import "OLPaymentViewController.h"
#import "UIViewController+OLMethods.h"
#import "OLImagePickerViewController.h"
#import "OLNavigationController.h"
#import "OLCustomPickerController.h"
#import "OLCustomViewControllerPhotoProvider.h"
#import "NSObject+Utils.h"
#import "OLKiteViewController+Private.h"

static const NSUInteger kTagLeft = 10;
static const NSUInteger kTagRight = 20;
static const CGFloat kBookAnimationTime = 0.8;
static const CGFloat kBookEdgePadding = 38;

@interface OLPaymentViewController (Private)

-(void)saveAndDismissReviewController;

@end

@interface OLPrintOrder (Private)
- (BOOL)hasOfferIdBeenUsed:(NSUInteger)identifier;
- (void)saveOrder;
@end

@interface OLFlipTransition (Private)

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

@interface OLPhotobookViewController () <UIPageViewControllerDataSource, UIPageViewControllerDelegate,UIGestureRecognizerDelegate, OLImageViewDelegate, OLImageEditViewControllerDelegate, UINavigationControllerDelegate, OLUpsellViewControllerDelegate, OLImagePickerViewControllerDelegate>

@property (assign, nonatomic) BOOL animating;
@property (assign, nonatomic) BOOL bookClosed;
@property (assign, nonatomic) BOOL haveSeenViewDidAppear;
@property (assign, nonatomic) BOOL stranded;
@property (assign, nonatomic) BOOL userHasOpenedBook;
@property (assign, nonatomic) NSInteger addNewPhotosAtIndex;
@property (assign, nonatomic) NSInteger croppingImageIndex;
@property (strong, nonatomic) IBOutlet UIView *bookCover;
@property (strong, nonatomic) NSArray<OLAsset *> *userSelectedPhotosCopy;
@property (strong, nonatomic) NSLayoutConstraint *centerXCon;
@property (strong, nonatomic) NSLayoutConstraint *centerYCon;
@property (strong, nonatomic) NSLayoutConstraint *widthCon2;
@property (strong, nonatomic) NSLayoutConstraint *widthCon;
@property (strong, nonatomic) OLAsset *editingAsset;
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
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *ctaButtonTrailingCon;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *ctaButtonLeadingCon;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *ctaButtonHeightCon;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *ctaButtonBottomCon;
@property (weak, nonatomic) OLPopupOptionsImageView *coverImageView;
@property (weak, nonatomic) IBOutlet UIButton *ctaButton;
@property (weak, nonatomic) UIPanGestureRecognizer *pageControllerPanGesture;
@property (strong, nonatomic) UILabel *coverHelpLabel;
@property (strong, nonatomic) OLImagePickerViewController *vcDelegateForCustomVc;
@property (strong, nonatomic) UIViewController *presentedVc;

@end

@implementation OLPhotobookViewController

-(id<OLPrintJob>)editingPrintJob{
    if (_editingPrintJob){
        return _editingPrintJob;
    }
    else if([OLKiteABTesting sharedInstance].launchedWithPrintOrder){
        self.product.uuid = [[OLUserSession currentSession].printOrder.jobs.firstObject uuid];
        return [[OLUserSession currentSession].printOrder.jobs firstObject];
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

- (void)setUserSelectedPhotos:(NSMutableArray<OLAsset *> *)userSelectedPhotos{
    [OLUserSession currentSession].userSelectedPhotos = userSelectedPhotos;
    
    self.photobookPhotos = [[NSMutableArray<OLAsset *> alloc] initWithCapacity:self.product.quantityToFulfillOrder];
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
        for (OLPhotobookPageContentViewController *vc in self.pageController.viewControllers){
            NSInteger index = [self.pageController.viewControllers indexOfObjectIdenticalTo:vc];
            NSInteger numberOfImages = self.product.productTemplate.productRepresentation.pages[pageIndex+index].numberOfPhotos;
            if (([vc isKindOfClass:[OLPhotobookPageContentViewController class]] && numberOfImages == 0) || ([vc isKindOfClass:[OLPhotobookPageBlankContentViewController class]] && numberOfImages == 1)){
                OLPhotobookPageContentViewController *newVc;
                if (self.product.productTemplate.productRepresentation.pages[pageIndex+index].numberOfPhotos == 0){
                    newVc = [self.storyboard instantiateViewControllerWithIdentifier:@"OLPhotobookPageBlankContentViewController"];        newVc.view.backgroundColor = [UIColor colorWithRed:0.918 green:0.910 blue:0.894 alpha:1.000];
                }
                else{
                    newVc = [self.storyboard instantiateViewControllerWithIdentifier:@"OLPhotobookPageViewController"];
                }
                newVc.pageIndex = pageIndex+index;
                newVc.userSelectedPhotos = self.photobookPhotos;
                newVc.product = self.product;
                newVc.view.autoresizingMask = UIViewAutoresizingNone;
                NSMutableArray *newArray = [NSMutableArray arrayWithArray:self.pageController.viewControllers];
                newArray[index] = newVc;
                [self.pageController setViewControllers:newArray direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:NULL];
            }
            else{
                [vc setPageIndex:pageIndex+index];
                [vc loadImageWithCompletionHandler:NULL];
            }
        }
    }
}

- (void)viewDidLoad{
    [super viewDidLoad];
    
    [self.ctaButton setTitle:NSLocalizedStringFromTableInBundle(@"Add to Basket", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") forState:UIControlStateNormal];
    
    if ([OLKiteABTesting sharedInstance].launchedWithPrintOrder){
        if ([[OLKiteABTesting sharedInstance].launchWithPrintOrderVariant isEqualToString:@"Review-Overview-Checkout"]){
            [self.ctaButton setTitle:NSLocalizedStringFromTableInBundle(@"Next", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") forState:UIControlStateNormal];
        }
        
        if(!self.editingPrintJob){
            self.editingPrintJob = [[OLUserSession currentSession].printOrder.jobs firstObject];
            self.product.uuid = self.editingPrintJob.uuid;
        }
    }
    
    if ([self.presentingViewController respondsToSelector:@selector(viewControllers)]) {
        UIViewController *paymentVc = [(UINavigationController *)self.presentingViewController viewControllers].lastObject;
        if ([paymentVc respondsToSelector:@selector(saveAndDismissReviewController)]){
            [self.ctaButton setTitle:NSLocalizedStringFromTableInBundle(@"Save", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") forState:UIControlStateNormal];
            [self.ctaButton removeTarget:self action:@selector(onButtonNextClicked:) forControlEvents:UIControlEventTouchUpInside];
            [self.ctaButton addTarget:paymentVc action:@selector(saveAndDismissReviewController) forControlEvents:UIControlEventTouchUpInside];
        }
    }
    
    if ([OLKiteABTesting sharedInstance].lightThemeColor1){
        [self.ctaButton setBackgroundColor:[OLKiteABTesting sharedInstance].lightThemeColor1];
    }
    UIFont *font = [[OLKiteABTesting sharedInstance] lightThemeHeavyFont1WithSize:18];
    if (!font){
        font = [[OLKiteABTesting sharedInstance] lightThemeFont1WithSize:18];
    }
    if (font){
        [self.ctaButton.titleLabel setFont:font];
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
    
    self.title = NSLocalizedStringFromTableInBundle(@"Review", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Title of a screen where the user can review the product before ordering");
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[OLKiteABTesting sharedInstance].backButtonText
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:nil
                                                                            action:nil];
    
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
    
    [self.pagesLabelContainer makeRoundRectWithRadius:3];
    
    [self updatePagesLabel];
    
    if (self.editMode){
        [self.ctaButton removeFromSuperview];
    }
    
    CGFloat yOffset = !self.editMode ? ([[UIApplication sharedApplication] statusBarFrame].size.height + self.navigationController.navigationBar.frame.size.height-self.ctaButton.frame.size.height)/2.0 : -15;
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
        [self setUpBookCoverViewForFrontCover:YES];
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
    
    [self setupCtaButtonConstraints];
}

- (void)setupCtaButtonConstraints{
    if (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact){
        self.ctaButtonTrailingCon.constant = 0;
        self.ctaButtonLeadingCon.constant = 0;
        self.ctaButtonBottomCon.constant = 0;
        self.ctaButtonHeightCon.constant = 40;
        
        [self.ctaButton makeRoundRectWithRadius:0];
    }
    else{
        self.ctaButtonTrailingCon.constant = 5;
        self.ctaButtonLeadingCon.constant = 5;
        self.ctaButtonBottomCon.constant = 5;
        self.ctaButtonHeightCon.constant = 50;
        
        NSNumber *cornerRadius = [OLKiteABTesting sharedInstance].lightThemeButtonRoundCorners;
        if (cornerRadius){
            [self.ctaButton makeRoundRectWithRadius:[cornerRadius floatValue]];
        }

    }
}

- (void)viewDidDisappear:(BOOL)animated{
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    [super viewDidDisappear:animated];
    
#ifndef OL_NO_ANALYTICS
    if (!self.navigationController && !self.editMode){
        [OLAnalytics trackReviewScreenHitBack:self.product.productTemplate.name numberOfPhotos:[OLUserSession currentSession].userSelectedPhotos.count];
    }
#endif
}

- (void)updatePagesLabel{
    int page = 0;
    if (self.editingPageNumber){
        page = [self.editingPageNumber intValue];
    }
    else if (!self.editMode){
        page = (int)[(OLPhotobookPageContentViewController *)self.pageController.viewControllers.firstObject pageIndex];
    }
    int displayPage = page+1;
    
    if ([(OLPageLayout *)self.product.productTemplate.productRepresentation.pages.firstObject numberOfPhotos] == 0&& page > 0){
        displayPage--;
    }
    
    if (self.product.productTemplate.productRepresentation.pages[page].numberOfPhotos == 0){
        self.pagesLabel.text = [NSString stringWithFormat:@"%d of %ld", displayPage, (long)self.product.quantityToFulfillOrder];
    }
    else if(self.product.productTemplate.productRepresentation.pages[page+1].numberOfPhotos == 0){
        self.pagesLabel.text = [NSString stringWithFormat:@"%d of %ld", displayPage, (long)self.product.quantityToFulfillOrder];
    }
    else{
        self.pagesLabel.text = [NSString stringWithFormat:@"%d-%d of %ld", displayPage, displayPage + 1, (long)self.product.quantityToFulfillOrder];
    }
}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    
    if (!self.haveSeenViewDidAppear){
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
    OLFlipStyle style = OLFlipStyleDefault;
    OLFlipTransition *flipTransition = [[OLFlipTransition alloc] initWithSourceView:self.bookCover destinationView:self.openbookView duration:0.5 timingCurve:UIViewAnimationCurveEaseOut completionAction:OLTransitionActionNone];
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
        [self setupCtaButtonConstraints];
        
        [self setUpBookCoverViewForFrontCover:YES];
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
    if (!self.coverPhoto || (id)self.coverPhoto == [NSNull null]){
        self.coverImageView.image = nil;
        return;
    }
    __weak OLPhotobookViewController *welf = self;
    if (self.coverImageView){
        [self.coverPhoto imageWithSize:self.coverImageView.frame.size applyEdits:YES progress:^(float progress){
            [welf.coverImageView setProgress:progress];
        }completion:^(UIImage *image, NSError *error){
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
    
    OLPhotobookPageContentViewController *vc;
    
    if (self.product.productTemplate.productRepresentation.pages[index].numberOfPhotos == 0){
        vc = [self.storyboard instantiateViewControllerWithIdentifier:@"OLPhotobookPageBlankContentViewController"];        vc.view.backgroundColor = [UIColor colorWithRed:0.918 green:0.910 blue:0.894 alpha:1.000];
    }
    else{
        vc = [self.storyboard instantiateViewControllerWithIdentifier:@"OLPhotobookPageViewController"];
    }
    vc.pageIndex = index;
    vc.userSelectedPhotos = self.photobookPhotos;
    vc.product = self.product;
    vc.view.autoresizingMask = UIViewAutoresizingNone;
    return vc;
}

- (NSInteger)photobookPhotosCount{
    NSInteger count = 0;
    for (id object in self.photobookPhotos){
        if (![object isKindOfClass:[OLPlaceholderAsset class]]){
            count++;
        }
    }
    
    return count;
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
        [assets addObject:[[OLUserSession currentSession].userSelectedPhotos.firstObject copy]];
    }
    else{
        for (OLAsset *photo in [OLUserSession currentSession].userSelectedPhotos){
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
            [(OLPhotobookPrintJob *)job setRedeemedOffer:vc.offer];
            [self doCheckout];
        }
        else{
            [self saveJobWithCompletionHandler:^{
                OLProduct *offerProduct = [OLProduct productWithTemplateId:vc.offer.offerTemplate];
                UIViewController *nextVc = [[OLUserSession currentSession].kiteVc reviewViewControllerForProduct:offerProduct photoSelectionScreen:[OLKiteUtils imageProvidersAvailable:self]];
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

#pragma mark - OLImageEditViewController delegate

- (void)imageEditViewControllerDidCancel:(OLImageEditViewController *)cropper{
    [cropper dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imageEditViewControllerDidDropChanges:(OLImageEditViewController *)cropper{
    [cropper dismissViewControllerAnimated:NO completion:NULL];
}

-(void)imageEditViewController:(OLImageEditViewController *)cropper didFinishCroppingImage:(UIImage *)croppedImage{
    [self.editingAsset unloadImage];
    self.editingAsset.edits = cropper.edits;
    if (self.editingAsset == self.coverPhoto){
        [self loadCoverPhoto];
    }
    
    [(OLPhotobookPageContentViewController *)[self.pageController.viewControllers objectAtIndex:self.croppingImageIndex] loadImageWithCompletionHandler:NULL];
    
    [cropper dismissViewControllerAnimated:YES completion:NULL];
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackEditScreenFinishedEditingPhotoForProductName:self.product.productTemplate.name];
#endif
}

- (void)imageEditViewController:(OLImageEditViewController *)cropper didReplaceAssetWithAsset:(OLAsset *)asset{
    if (self.editingAsset == self.coverPhoto){
        self.coverPhoto = asset;
        [self loadCoverPhoto];
    }
    else{
        NSUInteger index = [[OLUserSession currentSession].userSelectedPhotos indexOfObjectIdenticalTo:self.editingAsset];
        [[OLUserSession currentSession].userSelectedPhotos replaceObjectAtIndex:index withObject:asset];
        index = [self.photobookPhotos indexOfObjectIdenticalTo:self.editingAsset];
        [self.photobookPhotos replaceObjectAtIndex:index withObject:asset];
        
         [(OLPhotobookPageContentViewController *)[self.pageController.viewControllers objectAtIndex:self.croppingImageIndex] loadImageWithCompletionHandler:NULL];
    }
    self.editingAsset = asset;
}

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
    if (index >= self.product.productTemplate.productRepresentation.numberOfPages){
        return nil;
    }
    return [self viewControllerAtIndex:index];
}

- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController {
    return self.product.productTemplate.productRepresentation.numberOfPages;
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

-(BOOL) shouldGoToCheckout{
    OLUpsellOffer *offer = [self upsellOfferToShow];
    BOOL shouldShowOffer = offer != nil;
    if (offer){
        shouldShowOffer &= offer.minUnits <= [OLUserSession currentSession].userSelectedPhotos.count;
        shouldShowOffer &= offer.maxUnits == 0 || offer.maxUnits >= [OLUserSession currentSession].userSelectedPhotos.count;
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
    
    NSUInteger selectedCount = 0;
    for (id object in self.photobookPhotos){
        if (![object isKindOfClass:[OLPlaceholderAsset class]]){
            selectedCount++;
        }
    }
    
    if (selectedCount == 0){
        UIAlertController *ac = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTableInBundle(@"Oops!", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") message:NSLocalizedStringFromTableInBundle(@"Please add some photos to your photo book", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") preferredStyle:UIAlertControllerStyleAlert];
        [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"OK", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Acknowledgent to an alert dialog.") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){}]];
        [self presentViewController:ac animated:YES completion:NULL];
        return NO;
    }
    
    NSUInteger numOrders = 1 + (MAX(0, selectedCount - 1) / self.product.quantityToFulfillOrder);
    NSUInteger quantityToFulfilOrder = numOrders * self.product.quantityToFulfillOrder;
    if (selectedCount < quantityToFulfilOrder) {
        NSUInteger canSelectExtraCount = quantityToFulfilOrder - selectedCount;
        UIAlertController *ac = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"You've selected %d photos.", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @""),selectedCount] message:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"You can add %d more for the same price.", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @""), canSelectExtraCount] preferredStyle:UIAlertControllerStyleAlert];
        [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"Add more", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Add more [photos]") style:UIAlertActionStyleCancel handler:NULL]];
        [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"Print these", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Print these [photos]") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
            [self doCheckout];
        }]];
        [self presentViewController:ac animated:YES completion:NULL];
        return NO;
    }
    return YES;
}

- (void)saveJobWithCompletionHandler:(void(^)())handler{
    NSInteger i = 0;
    NSMutableArray *bookPhotos = [[NSMutableArray alloc] init];
    NSMutableArray *photobookPhotosClean = [[NSMutableArray alloc] init];
    for (id asset in self.photobookPhotos){
        if (![asset isKindOfClass:[OLPlaceholderAsset class]]){
            [photobookPhotosClean addObject:asset];
        }
    }
    
    for (NSInteger object = 0; object < self.photobookPhotos.count; object++){
        if ([self.photobookPhotos[object] isKindOfClass:[OLPlaceholderAsset class]]){
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
    for (OLAsset *photo in bookPhotos) {
        [photoAssets addObject:[photo copy]];
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
    
    OLPrintOrder *printOrder = [OLUserSession currentSession].printOrder;
    OLPhotobookPrintJob *job = [[OLPhotobookPrintJob alloc] initWithTemplateId:self.product.templateId OLAssets:photoAssets];
    job.frontCover = self.coverPhoto;
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
}

- (void)doCheckout {
    [self saveJobWithCompletionHandler:NULL];
    
    OLPrintOrder *printOrder = [OLUserSession currentSession].printOrder;
    [OLKiteUtils checkoutViewControllerForPrintOrder:printOrder handler:^(id vc){
        [vc safePerformSelector:@selector(setUserEmail:) withObject:[OLKiteUtils userEmail:self]];
        [vc safePerformSelector:@selector(setUserPhone:) withObject:[OLKiteUtils userPhone:self]];
        [self.navigationController pushViewController:vc animated:YES];
    }];
}

#pragma mark - Gesture recognizers

- (void)onCoverTapRecognized:(UITapGestureRecognizer *)sender{
    if (self.editMode){
        [self.photobookDelegate photobook:self userDidTapOnImageWithIndex:-1];
    }
    else if (self.coverPhoto){
        if ([OLUserSession currentSession].kiteVc.disableEditingTools){
            return;
        }
        self.editingAsset = self.coverPhoto;
        UIImageView *imageView = self.coverImageView;
        OLImageEditViewController *cropVc = [[OLImageEditViewController alloc] init];
        cropVc.delegate = self;
        cropVc.aspectRatio = imageView.frame.size.height / imageView.frame.size.width;
        cropVc.previewView = [imageView snapshotViewAfterScreenUpdates:YES];
        cropVc.previewView.frame = [imageView.superview convertRect:imageView.frame toView:nil];
        cropVc.previewSourceView = imageView;
        cropVc.providesPresentationContextTransitionStyle = true;
        cropVc.definesPresentationContext = true;
        cropVc.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        cropVc.product = self.product;
        
        [self.editingAsset imageWithSize:[UIScreen mainScreen].bounds.size applyEdits:NO progress:NULL completion:^(UIImage *image, NSError *error){
            [cropVc setFullImage:image];
            cropVc.edits = self.editingAsset.edits;
            [self presentViewController:cropVc animated:NO completion:NULL];
        }];
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
    [[OLUserSession currentSession].userSelectedPhotos removeAllObjects];
    for (OLAsset *item in self.photobookPhotos){
        if (![item isKindOfClass:[OLPlaceholderAsset class]]){
            [[OLUserSession currentSession].userSelectedPhotos addObject:item];
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
    
    OLPhotobookPageContentViewController *page = [self.pageController.viewControllers objectAtIndex:self.croppingImageIndex];
    NSInteger index = [page imageIndexForPoint:[sender locationInView:page.view]];
    
    if (index == NSNotFound){
        return;
    }
    
    if (self.editMode){
        [self.photobookDelegate photobook:self userDidTapOnImageWithIndex:index];
        
        return;
    }
    else if ([[self.photobookPhotos objectAtIndex:index] isKindOfClass:[OLPlaceholderAsset class]]){
        self.addNewPhotosAtIndex = index;
        [self addMorePhotosFromView:sender.view];
    }
    else{
        if ([OLUserSession currentSession].kiteVc.disableEditingTools){
            return;
        }
        UIImageView *imageView = [page imageView];
        self.editingAsset = self.photobookPhotos[index];
        [self.editingAsset imageWithSize:[UIScreen mainScreen].bounds.size applyEdits:NO progress:NULL completion:^(UIImage *image, NSError *error){
            OLImageEditViewController *cropVc = [[OLImageEditViewController alloc] init];
            cropVc.delegate = self;
            cropVc.aspectRatio = imageView.frame.size.height / imageView.frame.size.width;
            
            cropVc.previewView = [imageView snapshotViewAfterScreenUpdates:YES];
            cropVc.previewView.frame = [imageView.superview convertRect:imageView.frame toView:nil];
            cropVc.previewSourceView = imageView;
            cropVc.providesPresentationContextTransitionStyle = true;
            cropVc.definesPresentationContext = true;
            cropVc.modalPresentationStyle = UIModalPresentationOverCurrentContext;
            [cropVc setFullImage:image];
            cropVc.edits = self.editingAsset.edits;
            cropVc.product = self.product;
            
            [self presentViewController:cropVc animated:NO completion:NULL];
            
#ifndef OL_NO_ANALYTICS
            [OLAnalytics trackEditPhotoTappedForProductName:self.product.productTemplate.name];
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
        [self updatePagesLabel];
        
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

-(void) setUpBookCoverViewForFrontCover:(BOOL)front{
    UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(openBook:)];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onCoverTapRecognized:)];
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onCoverLongPressRecognized:)];
    
    UIView *halfBookCoverImageContainer;
    
    if (front){
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
            helpLabel.text = NSLocalizedStringFromTableInBundle(@"Tap to edit", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Tap to edit [photo]");
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
    return vc2.pageIndex == self.product.productTemplate.productRepresentation.numberOfPages - 1;
}

- (void)openBook:(UIGestureRecognizer *)sender{
    if (self.animating){
        return;
    }
    self.animating = YES;
    self.userHasOpenedBook = YES;
    
    [UIView animateWithDuration:kBookAnimationTime animations:^{
        if (self.product.productTemplate.productRepresentation.pages.firstObject.numberOfPhotos != 0){
            self.containerView.transform = CGAffineTransformIdentity;
        }
    }completion:^(BOOL completed){}];
    OLFlipStyle style = sender.view.tag == kTagRight ? OLFlipStyleDefault : OLFlipStyleDirectionBackward;
    OLFlipTransition *flipTransition = [[OLFlipTransition alloc] initWithSourceView:self.bookCover destinationView:self.openbookView duration:kBookAnimationTime timingCurve:UIViewAnimationCurveEaseInOut completionAction:OLTransitionActionNone];
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
    
    CGPoint translation = [sender translationInView:self.containerView];
    BOOL draggingRight = translation.x >= 0;
    
    [self setUpBookCoverViewForFrontCover:draggingRight];
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
    
    OLFlipTransition *flipTransition = [[OLFlipTransition alloc] initWithSourceView:self.openbookView destinationView:self.bookCover duration:kBookAnimationTime timingCurve:UIViewAnimationCurveEaseInOut completionAction:OLTransitionActionShowHide];
    flipTransition.flippingPageShadowOpacity = 0;
    flipTransition.style = OLFlipStyleDirectionBackward;
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
    
    CGPoint translation = [sender translationInView:self.containerView];
    BOOL draggingRight = translation.x >= 0;
    
    [self setUpBookCoverViewForFrontCover:draggingRight];
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
    OLFlipTransition *flipTransition = [[OLFlipTransition alloc] initWithSourceView:self.openbookView destinationView:self.bookCover duration:kBookAnimationTime timingCurve:UIViewAnimationCurveEaseInOut completionAction:OLTransitionActionShowHide];
    flipTransition.flippingPageShadowOpacity = 0;
    flipTransition.style = OLFlipStyleDefault;
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
    if (!useFrame){
        return self.containerView.transform.tx <= [self xTrasformForBookAtRightEdge] && !self.stranded;
    }
    else{
        return self.containerView.frame.origin.x - kBookEdgePadding <= [self xTrasformForBookAtRightEdge];
    }
}

- (BOOL)isContainerViewAtLeftEdge:(BOOL)useFrame{
    if (!useFrame){
        return self.containerView.transform.tx >= 0 && !self.stranded;
    }
    else{
        return self.containerView.center.x - self.containerView.frame.size.width / 2  - kBookEdgePadding >= 0;
    }
}

#pragma mark - Adding new images

- (void)addMorePhotosFromView:(UIView *)view{
    OLImagePickerViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"OLImagePickerViewController"];
    if ([self.photobookPhotos indexOfObject:self.coverPhoto] == NSNotFound){
        [[OLUserSession currentSession].userSelectedPhotos removeObject:self.coverPhoto];
    }
    vc.selectedAssets = [OLUserSession currentSession].userSelectedPhotos;
    vc.delegate = self;
    vc.maximumPhotos = self.product.quantityToFulfillOrder;
    
    if ([OLKiteUtils numberOfProvidersAvailable] <= 2 && [[OLUserSession currentSession].kiteVc.customImageProviders.firstObject isKindOfClass:[OLCustomViewControllerPhotoProvider class]]){
        //Skip the image picker and only show the custom vc
        
        self.vcDelegateForCustomVc = vc; //Keep strong reference
        vc.providerForPresentedVc = [OLUserSession currentSession].kiteVc.customImageProviders.firstObject;
        UIViewController<OLCustomPickerController> *customVc = [(OLCustomViewControllerPhotoProvider *)[OLUserSession currentSession].kiteVc.customImageProviders.firstObject vc];
        [customVc safePerformSelector:@selector(setDelegate:) withObject:vc];
        [customVc safePerformSelector:@selector(setProductId:) withObject:self.product.templateId];
        [customVc safePerformSelector:@selector(setSelectedAssets:) withObject:[[OLUserSession currentSession].userSelectedPhotos mutableCopy]];
        if ([vc respondsToSelector:@selector(setMaximumPhotos:)]){
            vc.maximumPhotos = self.product.quantityToFulfillOrder;
        }
        
        [self presentViewController:customVc animated:YES completion:NULL];
        self.presentedVc = customVc;
        return;
    }
    
    [self presentViewController:[[OLNavigationController alloc] initWithRootViewController:vc] animated:YES completion:NULL];
}

- (void)imagePickerDidCancel:(OLImagePickerViewController *)vc{
    [vc dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imagePicker:(OLImagePickerViewController *)vc didFinishPickingAssets:(NSMutableArray *)assets added:(NSArray<OLAsset *> *)addedAssets removed:(NSArray *)removedAssets{
    
    if (self.addNewPhotosAtIndex == -1){
        self.coverPhoto = [addedAssets firstObject];
        addedAssets = [[addedAssets subarrayWithRange:NSMakeRange(1, assets.count - 1)] mutableCopy];
        self.addNewPhotosAtIndex = 0;
        
        for (OLPhotobookViewController *photobook in self.childViewControllers){
            if ([photobook bookClosed]){
                photobook.coverPhoto = self.coverPhoto;
                [photobook loadCoverPhoto];
                break;
            }
        }
    }
    [self.photobookPhotos removeObjectsInArray:removedAssets];
    [self updatePhotobookPhotos];
    for (OLPhotobookPageContentViewController *page in self.pageController.viewControllers){
        [page loadImageWithCompletionHandler:NULL];
    }
    [self updateUserSelectedPhotos];
    
    if (self.presentedVc){
        [self.presentedVc dismissViewControllerAnimated:YES completion:NULL];
    }
    else{
        [vc dismissViewControllerAnimated:YES completion:NULL];
    }
    
    self.vcDelegateForCustomVc = nil;
    self.presentedVc = nil;
    
}

- (void)updatePhotobookPhotos{
    if (!self.photobookPhotos){
        self.userSelectedPhotosCopy = [[NSArray alloc] initWithArray:[OLUserSession currentSession].userSelectedPhotos copyItems:NO];
        self.photobookPhotos = [[NSMutableArray alloc] initWithCapacity:self.product.quantityToFulfillOrder];
        NSInteger start = 0;
        if (!self.coverPhoto){
            self.coverPhoto = [OLUserSession currentSession].userSelectedPhotos.firstObject;
            start++;
        }
        else if ([self.coverPhoto isKindOfClass:[OLPlaceholderAsset class]]){
            self.coverPhoto = nil;
        }
        for (NSInteger i = start; i < self.product.quantityToFulfillOrder + start; i++){
            [self.photobookPhotos addObject:i < [OLUserSession currentSession].userSelectedPhotos.count ? [OLUserSession currentSession].userSelectedPhotos[i] : [OLPlaceholderAsset asset]];
        }
    }
    else{
        NSMutableArray *newPhotos = [NSMutableArray arrayWithArray:[[OLUserSession currentSession].userSelectedPhotos subarrayWithRange:NSMakeRange(0, MIN([OLUserSession currentSession].userSelectedPhotos.count, self.product.quantityToFulfillOrder+1))]];
        [newPhotos removeObjectsInArray:self.userSelectedPhotosCopy];
        for (NSInteger newPhoto = 0; newPhoto < newPhotos.count; newPhoto++){
            BOOL foundSpot = NO;
            for (NSInteger bookPhoto = self.addNewPhotosAtIndex; bookPhoto < self.photobookPhotos.count && !foundSpot; bookPhoto++){
                if ([self.photobookPhotos[bookPhoto] isKindOfClass:[OLPlaceholderAsset class]]){
                    self.photobookPhotos[bookPhoto] = newPhotos[newPhoto];
                    foundSpot = YES;
                }
            }
            for (NSInteger bookPhoto = 0; bookPhoto < self.addNewPhotosAtIndex && !foundSpot; bookPhoto++){
                if ([self.photobookPhotos[bookPhoto] isKindOfClass:[OLPlaceholderAsset class]]){
                    self.photobookPhotos[bookPhoto] = newPhotos[newPhoto];
                    foundSpot = YES;
                }
            }
        }
        self.userSelectedPhotosCopy = [[NSArray alloc] initWithArray:[OLUserSession currentSession].userSelectedPhotos copyItems:NO];
    }
    
}

@end
