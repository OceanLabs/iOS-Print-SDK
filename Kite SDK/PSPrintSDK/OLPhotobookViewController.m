//
//  OLPhotobookViewController.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 4/17/15.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import "OLPhotobookViewController.h"
#import "OLProduct.h"
#import "OLProductTemplate.h"
#import "OLPhotobookPageContentViewController.h"
#import "OLPrintPhoto.h"
#import "OLScrollCropViewController.h"
#import "OLProductPrintJob.h"
#import "UIView+RoundRect.h"

#import <MPFlipTransition.h>

static const NSUInteger kTagAlertViewSelectMorePhotos = 99;
static const NSUInteger kTagLeft = 10;
static const NSUInteger kTagRight = 20;
static const CGFloat kBookAnimationTime = 0.8;
static const CGFloat kBookEdgePadding = 38;

@interface OLKitePrintSDK (InternalUtils)
+ (NSString *)userEmail:(UIViewController *)topVC;
+ (NSString *)userPhone:(UIViewController *)topVC;
+ (id<OLKiteDelegate>)kiteDelegate:(UIViewController *)topVC;
+ (void)checkoutViewControllerForPrintOrder:(OLPrintOrder *)printOrder handler:(void(^)(OLCheckoutViewController *vc))handler;
@end

@interface MPFlipTransition (Private)

- (void)animateFlip1:(BOOL)isFallingBack fromProgress:(CGFloat)fromProgress toProgress:(CGFloat)toProgress withCompletion:(void (^)(BOOL finished))completion;
- (void)animateFlip2:(BOOL)isFallingBack fromProgress:(CGFloat)fromProgress withCompletion:(void (^)(BOOL finished))completion;
- (void)transitionDidComplete:(BOOL)completed;
- (void)cleanupLayers;

@end

@interface OLPhotobookViewController () <UIPageViewControllerDataSource, UIPageViewControllerDelegate, UIGestureRecognizerDelegate, OLScrollCropViewControllerDelegate>

@property (strong, nonatomic) UIPageViewController *pageController;
@property (weak, nonatomic) UIPanGestureRecognizer *pageControllerPanGesture;
@property (weak, nonatomic) IBOutlet UIView *fakeShadowView;
@property (weak, nonatomic) IBOutlet UIView *openbookView;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (strong, nonatomic) NSMutableArray *photobookPhotos;
@property (strong, nonatomic) OLPrintPhoto *editingPrintPhoto;
@property (weak, nonatomic) IBOutlet UIImageView *bookImageView;
@property (assign, nonatomic) NSInteger editingPageIndex;
@property (strong, nonatomic) NSLayoutConstraint *centerXCon;
@property (strong, nonatomic) NSLayoutConstraint *widthCon;
@property (strong, nonatomic) NSLayoutConstraint *widthCon2;
@property (strong, nonatomic) NSLayoutConstraint *centerYCon;

@property (strong, nonatomic) UIDynamicAnimator* dynamicAnimator;
@property (strong, nonatomic) UIDynamicItemBehavior* inertiaBehavior;
@property (weak, nonatomic) IBOutlet UILabel *leftPageLabel;
@property (weak, nonatomic) IBOutlet UILabel *rightPageLabel;

@property (strong, nonatomic) IBOutlet UIView *bookCover;
@property (assign, nonatomic) BOOL bookClosed;
@property (weak, nonatomic) IBOutlet UIView *pagesLabelContainer;
@property (weak, nonatomic) IBOutlet UILabel *pagesLabel;
@property (strong, nonatomic) UIVisualEffectView *visualEffectView;
@property (assign, nonatomic) BOOL animating;
@property (assign, nonatomic) BOOL stranded;
@property (assign, nonatomic) BOOL hasDoneFirstTimeLayout;
@property (assign, nonatomic) BOOL userHasOpenedBook;

@end

@implementation OLPhotobookViewController

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

- (void)viewDidLoad{
    [super viewDidLoad];
    
    self.photobookPhotos = [[NSMutableArray alloc] initWithCapacity:self.product.quantityToFulfillOrder];
    [self.photobookPhotos addObjectsFromArray:self.userSelectedPhotos];
    for (NSInteger i = self.userSelectedPhotos.count; i < self.product.quantityToFulfillOrder; i++){
        [self.photobookPhotos addObject:[self.userSelectedPhotos objectAtIndex:i % self.userSelectedPhotos.count]];
    }
    
    if (self.editMode){
        self.photobookPhotos = [[self.photobookPhotos subarrayWithRange:NSMakeRange(0, 2)] mutableCopy];
    }
    
    self.pageController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStylePageCurl navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:@{UIPageViewControllerOptionSpineLocationKey : [NSNumber numberWithInt:UIPageViewControllerSpineLocationMid]}];
    self.pageController.dataSource = self;
    self.pageController.delegate = self;
    
    [self.pageController setViewControllers:@[[self viewControllerAtIndex:0], [self viewControllerAtIndex:1]] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    
    [self addChildViewController:self.pageController];
    [self.openbookView addSubview:self.pageController.view];
    
    self.pageController.view.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.openbookView addConstraint:[NSLayoutConstraint constraintWithItem:self.pageController.view attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.openbookView attribute:NSLayoutAttributeHeight multiplier:1 - (2 * .021573604) constant:0]];
    [self.openbookView addConstraint:[NSLayoutConstraint constraintWithItem:self.pageController.view attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.openbookView attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
    
    [self.openbookView addConstraint:[NSLayoutConstraint constraintWithItem:self.pageController.view attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.openbookView attribute:NSLayoutAttributeWidth multiplier:1 - (2 * .031951641) constant:0]];
    [self.openbookView addConstraint:[NSLayoutConstraint constraintWithItem:self.pageController.view attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.openbookView attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    
    CGFloat bookAspectRatio = [self productAspectRatio];
    
    NSLayoutConstraint *bookAspectRatioCon = [NSLayoutConstraint constraintWithItem:self.containerView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.containerView attribute:NSLayoutAttributeHeight multiplier:bookAspectRatio constant:0];
    [self.containerView addConstraint:bookAspectRatioCon];
    
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
    self.widthCon2.priority = UILayoutPriorityDefaultHigh;
    [self.view addConstraint:self.widthCon2];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapGestureRecognized:)];
    tapGesture.delegate = self;
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPanGestureRecognized:)];
    panGesture.delegate = self;
    
    [self.pageController.view addGestureRecognizer:tapGesture];
    [self.pageController.view addGestureRecognizer:panGesture];
    
    self.title = [NSString stringWithFormat: NSLocalizedString(@"%d / %d", @""), self.userSelectedPhotos.count, self.product.quantityToFulfillOrder];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", @"") style:UIBarButtonItemStylePlain target:self action:@selector(onBackButtonTapped)];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Confirm", @"") style:UIBarButtonItemStylePlain target:self action:@selector(onButtonNextClicked:)];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", @"")
                                                                             style:UIBarButtonItemStyleBordered
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
        self.pagesLabelContainer.backgroundColor = [UIColor darkGrayColor];
        
        [self.containerView.superview addConstraint:[NSLayoutConstraint constraintWithItem:self.containerView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationLessThanOrEqual toItem:self.containerView.superview attribute:NSLayoutAttributeRight multiplier:1 constant:0]];
        [self.containerView.superview addConstraint:[NSLayoutConstraint constraintWithItem:self.containerView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:self.containerView.superview attribute:NSLayoutAttributeLeft multiplier:1 constant:0]];
        if ([self productAspectRatio] > 1){ //Landscape book REALLY doesn't like the following, only do it for portrait.
            [self.containerView.superview addConstraint:[NSLayoutConstraint constraintWithItem:self.containerView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.containerView.superview attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
        }
        
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
    
    [self.pagesLabelContainer makeRoundRect];
    
    self.pagesLabel.text = [NSString stringWithFormat:@"%d-%d of %ld", 1, 2, (long)self.product.quantityToFulfillOrder];
    
    CGFloat yOffset = !self.editMode ? ([[UIApplication sharedApplication] statusBarFrame].size.height + self.navigationController.navigationBar.frame.size.height)/2.0 : -15;
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
    
    if (!self.editMode){ //Start with book closed
        [self setUpBookCoverView];
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
    
    if (!self.hasDoneFirstTimeLayout && !self.editMode){
        self.hasDoneFirstTimeLayout = YES;
        if (![self isLandscape]){
            self.containerView.transform = CGAffineTransformMakeTranslation([self xTrasformForBookAtRightEdge], 0);
        }
    }
}

- (BOOL)isLandscape{
    return self.view.frame.size.width > self.view.frame.size.height || self.editMode;
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
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

- (void)onBackButtonTapped{
    [self.navigationController popViewControllerAnimated:YES];
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
        [self setUpBookCoverView];
        if (size.width > size.height){
            self.containerView.transform = CGAffineTransformIdentity;
        }
        else{
            if (self.bookClosed && [self isBookAtStart]){
                self.containerView.transform = CGAffineTransformMakeTranslation([self xTrasformForBookAtRightEdge], 0);
            }
        }
        
        CGFloat yOffset = !self.editMode ? ([[UIApplication sharedApplication] statusBarFrame].size.height + self.navigationController.navigationBar.frame.size.height)/2.0 : -15;
        
        self.centerYCon = [NSLayoutConstraint constraintWithItem:self.containerView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.containerView.superview attribute:NSLayoutAttributeCenterY multiplier:1 constant:yOffset];
        [self.containerView.superview addConstraint:self.centerYCon];
    }completion:^(id<UIViewControllerTransitionCoordinator> context){
        self.containerView.layer.shadowOpacity = 0;
    }];
}

- (CGFloat) productAspectRatio{
    return self.product.productTemplate.sizeCm.width*2 / self.product.productTemplate.sizeCm.height;
}

- (UIViewController *)viewControllerAtIndex:(NSUInteger)index {
    if (index == NSNotFound || index >= self.photobookPhotos.count) {
        return nil;
    }
    
    OLPhotobookPageContentViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"OLPhotobookPageViewController"];
    vc.pageIndex = index;
    vc.userSelectedPhotos = self.photobookPhotos;
    vc.assets = self.assets;
    return vc;
}

#pragma mark - OLScrollCropView delegate

- (void)scrollCropViewControllerDidCancel:(OLScrollCropViewController *)cropper{
    [cropper dismissViewControllerAnimated:YES completion:NULL];
}

-(void)scrollCropViewController:(OLScrollCropViewController *)cropper didFinishCroppingImage:(UIImage *)croppedImage{
    [self.editingPrintPhoto unloadImage];
    self.editingPrintPhoto.asset = [OLAsset assetWithImageAsJPEG:croppedImage];
    
    [(OLPhotobookPageContentViewController *)[self.pageController.viewControllers objectAtIndex:self.editingPageIndex] loadImage];
    
    [cropper dismissViewControllerAnimated:YES completion:NULL];
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

- (IBAction)onButtonNextClicked:(UIBarButtonItem *)sender {
    if (![self shouldGoToCheckout]){
        return;
    }
    
    [self doCheckout];
}

-(BOOL) shouldGoToCheckout{
    NSUInteger selectedCount = self.userSelectedPhotos.count;
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

- (void)doCheckout {
    NSUInteger iphonePhotoCount = 0;
    for (OLPrintPhoto *photo in self.userSelectedPhotos) {
        if (photo.type == kPrintPhotoAssetTypeALAsset) ++iphonePhotoCount;
    }
    
    // Avoid uploading assets if possible. We can avoid uploading where the image already exists at a remote
    // URL and the user did not manipulate it in any way.
    NSMutableArray *photoAssets = [[NSMutableArray alloc] init];
    for (OLPrintPhoto *photo in self.userSelectedPhotos) {
        if(photo.type == kPrintPhotoAssetTypeOLAsset){
            [photoAssets addObject:photo.asset];
        } else {
            [photoAssets addObject:[OLAsset assetWithDataSource:photo]];
        }
    }
    
    // ensure order is maxed out by adding duplicates as necessary
    NSUInteger userSelectedAssetCount = photoAssets.count;
    NSUInteger numOrders = (NSUInteger) floor(userSelectedAssetCount + self.product.quantityToFulfillOrder - 1) / self.product.quantityToFulfillOrder;
    NSUInteger duplicatesToFillOrder = numOrders * self.product.quantityToFulfillOrder - userSelectedAssetCount;
    for (NSUInteger i = 0; i < duplicatesToFillOrder; ++i) {
        [photoAssets addObject:photoAssets[i % userSelectedAssetCount]];
    }
    NSLog(@"Adding %lu duplicates", (unsigned long)duplicatesToFillOrder);
    
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString *appVersion = [infoDict objectForKey:@"CFBundleShortVersionString"];
    NSNumber *buildNumber = [infoDict objectForKey:@"CFBundleVersion"];
    
    OLPrintOrder *printOrder = [[OLPrintOrder alloc] init];
    printOrder.userData = @{@"photo_count_iphone": [NSNumber numberWithUnsignedInteger:iphonePhotoCount],
                            @"sdk_version": kOLKiteSDKVersion,
                            @"platform": @"iOS",
                            @"uid": [[[UIDevice currentDevice] identifierForVendor] UUIDString],
                            @"app_version": [NSString stringWithFormat:@"Version: %@ (%@)", appVersion, buildNumber]
                            };
    OLProductPrintJob* printJob = [[OLProductPrintJob alloc] initWithTemplateId:self.product.templateId OLAssets:photoAssets];
    for (id<OLPrintJob> job in printOrder.jobs){
        [printOrder removePrintJob:job];
    }
    [printOrder addPrintJob:printJob];
    
    
    [OLKitePrintSDK checkoutViewControllerForPrintOrder:printOrder handler:^(OLCheckoutViewController *vc){
        vc.userEmail = [OLKitePrintSDK userEmail:self];
        vc.userPhone = [OLKitePrintSDK userPhone:self];
        vc.kiteDelegate = [OLKitePrintSDK kiteDelegate:self];
        
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

- (void)onTapGestureRecognized:(UITapGestureRecognizer *)sender{
    OLPrintPhoto *tempPrintPhoto = [[OLPrintPhoto alloc] init];
    NSInteger index = 0;
    if ([sender locationInView:self.pageController.view].x < self.pageController.view.frame.size.width / 2.0){
        self.editingPageIndex = 0;
    }
    else{
        self.editingPageIndex = 1;
    }
    
    if (self.editMode){
        OLPhotobookPageContentViewController *page = [self.pageController.viewControllers objectAtIndex:self.editingPageIndex];
        [page selectedViewForPoint:[sender locationInView:page.view]];
        
        return;
    }
    
    index = [[self.pageController.viewControllers objectAtIndex:self.editingPageIndex] pageIndex];
    tempPrintPhoto.asset = self.assets[index % [self.assets count]];
    self.editingPrintPhoto = self.photobookPhotos[index];
    
    UINavigationController *nav = [self.storyboard instantiateViewControllerWithIdentifier:@"CropViewNavigationController"];
    OLScrollCropViewController *cropVc = (id)nav.topViewController;
    cropVc.delegate = self;
    UIImageView *imageView = [(OLPhotobookPageContentViewController *)[[self.pageController viewControllers] firstObject] imageView];
    cropVc.aspectRatio = imageView.frame.size.height / imageView.frame.size.width;
    [tempPrintPhoto getImageWithProgress:NULL completion:^(UIImage *image){
        [cropVc setFullImage:image];
        [self presentViewController:nav animated:YES completion:NULL];
    }];
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
            [self closeBookBack];
        }
        else if (draggingRight && [self isBookAtStart]) {
            recognizer.enabled = NO;
            recognizer.enabled = YES;
            [self closeBookFront];
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
            [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionBeginFromCurrentState  animations:^{
                self.containerView.transform = CGAffineTransformMakeTranslation(-self.containerView.frame.size.width + self.view.frame.size.width, 0);
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

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]] || [otherGestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]){
        return NO;
    }
    else if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]] && [otherGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]){
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

-(void) setUpBookCoverView{
    UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(openBook:)];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openBook:)];
    
    UIView *halfBookCoverImageContainer;
    
    if ([self isBookAtStart]){
        halfBookCoverImageContainer = [self.bookCover viewWithTag:kTagRight];
        [self.bookCover viewWithTag:kTagLeft].hidden = YES;
        if (!halfBookCoverImageContainer){
            halfBookCoverImageContainer = [[UIView alloc] init];
            halfBookCoverImageContainer.tag = kTagRight;
            swipe.direction = UISwipeGestureRecognizerDirectionLeft;
            
            UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"book-cover-right"]];
            imageView.contentMode = UIViewContentModeScaleAspectFill;
            [imageView makeRoundRectWithRadius:3];
            [halfBookCoverImageContainer addSubview:imageView];
            
            [self.bookCover addSubview:halfBookCoverImageContainer];
            halfBookCoverImageContainer.userInteractionEnabled = YES;
            [halfBookCoverImageContainer addGestureRecognizer:tap];
            [halfBookCoverImageContainer addGestureRecognizer:swipe];
            
            halfBookCoverImageContainer.layer.shadowOffset = CGSizeMake(-10, 10);
            halfBookCoverImageContainer.layer.shadowRadius = 5;
            halfBookCoverImageContainer.layer.shadowOpacity = 0.0;
            halfBookCoverImageContainer.layer.shouldRasterize = YES;
            halfBookCoverImageContainer.layer.rasterizationScale = [UIScreen mainScreen].scale;
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
        
        view = [[halfBookCoverImageContainer subviews] firstObject];
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
            
            UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"book-cover-left"]];
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
    OLPhotobookPageContentViewController *vc1 = [self.pageController.viewControllers firstObject];
    return vc1.pageIndex == 0;
}

- (BOOL)isBookAtEnd{
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
    }completion:^(BOOL completed){
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
    }];
    
    
}

- (void)closeBookFront{
    if (self.animating || self.editMode){
        return;
    }
    self.animating = YES;
    [self setUpBookCoverView];
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
        
        if (![self isContainerViewAtRightEdge:NO]){
            [UIView animateWithDuration:kBookAnimationTime/2.0 animations:^{
                self.containerView.transform = CGAffineTransformMakeTranslation([self xTrasformForBookAtRightEdge], 0);
            }];
        }
        self.bookClosed = YES;
    }];
}
- (void)closeBookBack{
    if (self.animating || self.editMode){
        return;
    }
    self.animating = YES;
    [self setUpBookCoverView];
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
                     } completion:^(BOOL finished){
                         MPFlipTransition *flipTransition = [[MPFlipTransition alloc] initWithSourceView:self.openbookView destinationView:self.bookCover duration:kBookAnimationTime timingCurve:UIViewAnimationCurveEaseInOut completionAction:MPTransitionActionShowHide];
                         flipTransition.flippingPageShadowOpacity = 0;
                         flipTransition.style = MPFlipStyleDefault;
                         [flipTransition perform:^(BOOL finished){
                             self.animating = NO;
                             [self.fakeShadowView makeRoundRectWithRadius:3];
                         }];
                         self.bookClosed = YES;
                     }];
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

- (NSUInteger)supportedInterfaceOrientations {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8) {
        return UIInterfaceOrientationMaskAll;
    }
    else{
        return UIInterfaceOrientationMaskLandscape;
    }
}

@end
