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

#import "OLProductOverviewViewController.h"
#import "OLProductOverviewPageContentViewController.h"
#import "OLProduct.h"
#import "OLOrderReviewViewController.h"
#import "OLKiteViewController.h"
#import "OLAnalytics.h"
#import "OLProductTypeSelectionViewController.h"
#import "OLSingleImageProductReviewViewController.h"
#import "OLPhotoSelectionViewController.h"
#import "OLFrameOrderReviewViewController.h"
#import "OLPostcardViewController.h"
#import "NSObject+Utils.h"
#import "NSDecimalNumber+CostFormatter.h"
#import "OLKiteABTesting.h"
#import "OLKiteUtils.h"
#import "OLProductDetailsViewController.h"
#import "UIViewController+OLMethods.h"
#import "OLPaymentViewController.h"
#import "OLUpsellViewController.h"

@interface OLKiteViewController ()

@property (strong, nonatomic) OLPrintOrder *printOrder;
- (void)dismiss;

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

@interface OLPrintOrder ()
- (void)saveOrder;
- (BOOL)hasOfferIdBeenUsed:(NSUInteger)identifier;
@end

@interface OLProductOverviewPageContentViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@end

@interface OLProduct (Private)
-(void)setProductPhotography:(NSUInteger)i toImageView:(UIImageView *)imageView;
- (BOOL)hasOfferIdBeenUsed:(NSUInteger)identifier;
@end

@interface OLProductOverviewViewController () <UIPageViewControllerDataSource, OLProductOverviewPageContentViewControllerDelegate, OLProductDetailsDelegate, UIPageViewControllerDelegate, OLUpsellViewControllerDelegate>
@property (strong, nonatomic) UIPageViewController *pageController;
@property (strong, nonatomic) IBOutlet UIPageControl *pageControl;
@property (weak, nonatomic) IBOutlet UILabel *costLabel;
@property (weak, nonatomic) IBOutlet UIButton *callToActionButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *detailsBoxTopCon;
@property (weak, nonatomic) IBOutlet UIImageView *arrowImageView;
@property (weak, nonatomic) IBOutlet UIView *detailsView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *detailsViewHeightCon;
@property (weak, nonatomic) IBOutlet UIView *detailsSeparator;
@property (assign, nonatomic) CGFloat originalBoxConstraint;

@property (strong, nonatomic) OLProductDetailsViewController *productDetails;

@property (strong, nonatomic) id<OLPrintJob> editingPrintJob;


@end

@implementation OLProductOverviewViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupDetailsView];
    
    if ([self isPushed]){
        self.parentViewController.title = self.product.productTemplate.name;
    }
    else{
        self.title = self.product.productTemplate.name;
    }
    
    self.pageController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    self.pageController.dataSource = self;
    self.pageController.delegate = self;
    self.pageController.view.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height + 37);
    
    self.pageControl.numberOfPages = self.product.productPhotos.count;
    [self.pageController setViewControllers:@[[self viewControllerAtIndex:0]] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    [self addChildViewController:self.pageController];
    [self.view insertSubview:self.pageController.view belowSubview:self.pageControl];
    [self.pageController didMoveToParentViewController:self];
    
    UIPageControl *pageControl = [UIPageControl appearance];
    pageControl.pageIndicatorTintColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.5];
    pageControl.currentPageIndicatorTintColor = [UIColor whiteColor];
    pageControl.backgroundColor = [UIColor clearColor];
    pageControl.frame = CGRectMake(0, -200, 100, 100);
    
    if ([OLKiteABTesting sharedInstance].hidePrice){
        [self.costLabel removeFromSuperview];
    }
    else{
        self.costLabel.text = self.product.unitCost;
    }
    
    UIViewController *vc = self.parentViewController;
    while (vc) {
        if ([vc isKindOfClass:[OLKiteViewController class]]){
            break;
        }
        else{
            vc = vc.parentViewController;
        }
    }
    if ([OLKiteABTesting sharedInstance].launchedWithPrintOrder && self.product.productTemplate.templateUI != kOLTemplateUINonCustomizable){
        if (![[OLKiteABTesting sharedInstance].launchWithPrintOrderVariant isEqualToString:@"Overview-Review-Checkout"]){
            [self.callToActionButton setTitle: NSLocalizedString(@"Checkout", @"") forState:UIControlStateNormal];
        }
        else{
            [self.callToActionButton setTitle: NSLocalizedString(@"Review", @"")forState:UIControlStateNormal];
        }
    }
    else if (self.product.productTemplate.templateUI == kOLTemplateUINonCustomizable){
        [self.callToActionButton setTitle: NSLocalizedString(@"Add to Basket", @"")forState:UIControlStateNormal];
    }
    
    if ([OLKiteABTesting sharedInstance].darkTheme && [OLKiteABTesting sharedInstance].darkThemeColor1){
        self.callToActionButton.backgroundColor = [OLKiteABTesting sharedInstance].darkThemeColor1;
        [self.callToActionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        
        self.detailsSeparator.backgroundColor = [OLKiteABTesting sharedInstance].darkThemeColor1;
    }
    
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackProductDescriptionScreenViewed:self.product.productTemplate.name hidePrice:[OLKiteABTesting sharedInstance].hidePrice];
#endif
    
    self.originalBoxConstraint = self.detailsBoxTopCon.constant;
    
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    
#ifndef OL_NO_ANALYTICS
    if (!self.navigationController){
        [OLAnalytics trackProductDescriptionScreenHitBack:self.product.productTemplate.name hidePrice:[OLKiteABTesting sharedInstance].hidePrice];
    }
#endif
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
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

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id context){
        self.detailsViewHeightCon.constant = size.height > size.width ? 450 : [self.productDetails recommendedDetailsBoxHeight];
        self.detailsBoxTopCon.constant = ![self boxIsHidden] ? self.detailsViewHeightCon.constant-100 : self.originalBoxConstraint;
    }completion:NULL];
}

- (BOOL)boxIsHidden{
    return self.detailsBoxTopCon.constant == self.originalBoxConstraint;
}

- (void)optionsButtonClicked{
    if ([self boxIsHidden]){
        [self onLabelDetailsTapped:nil useSpringAnimation:NO];
    }
}

- (UIViewController *)viewControllerAtIndex:(NSUInteger)index {
    if (index == NSNotFound || index >= self.product.productPhotos.count) {
        return nil;
    }
    
    OLProductOverviewPageContentViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"ProductOverviewPageContentViewController"];
    vc.pageIndex = index;
    vc.product = self.product;
    vc.delegate = self;
    return vc;
}

- (void)setupDetailsView{
    self.productDetails = [self.storyboard instantiateViewControllerWithIdentifier:@"OLProductDetailsViewController"];
    self.productDetails.product = self.product;
    self.productDetails.delegate = self;
    
    [self.productDetails view]; //Access the view to force the ViewController to load
    
    self.arrowImageView = self.productDetails.arrowImageView;
    self.costLabel = self.productDetails.priceLabel;
    
    UINavigationController *nvc = [[UINavigationController alloc] initWithRootViewController:self.productDetails];
    nvc.navigationBarHidden = YES;
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0){
        UIVisualEffect *blurEffect;
        if (![OLKiteABTesting sharedInstance].darkTheme){
        blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight];
        }
        else{
            blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        }
        
        UIVisualEffectView *visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        UIView *view = visualEffectView;
        [nvc.view addSubview:view];
        [nvc.view sendSubviewToBack:view];
        nvc.view.backgroundColor = [UIColor clearColor];
        
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
        nvc.view.backgroundColor = [UIColor whiteColor];
    }
    
    [self addChildViewController:nvc];
    [self.detailsView addSubview:nvc.view];
    UIView *detailsVcView = nvc.view;
    
    detailsVcView.translatesAutoresizingMaskIntoConstraints = NO;
    NSDictionary *views = NSDictionaryOfVariableBindings(detailsVcView);
    NSMutableArray *con = [[NSMutableArray alloc] init];
    
    NSArray *visuals = @[@"H:|-0-[detailsVcView]-0-|",
                         @"V:|-0-[detailsVcView]-0-|"];
    
    
    for (NSString *visual in visuals) {
        [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
    }
    
    [detailsVcView.superview addConstraints:con];
    
    CGSize size = self.view.frame.size;
    self.detailsViewHeightCon.constant = size.height > size.width ? 450 : [self.productDetails recommendedDetailsBoxHeight];
}

- (IBAction)onTapGestureRecognized:(UITapGestureRecognizer *)sender {
    [self onButtonStartClicked:nil];
}

- (void)onLabelDetailsTapped:(UITapGestureRecognizer *)sender useSpringAnimation:(BOOL)spring{
    if (self.detailsBoxTopCon.constant != self.originalBoxConstraint){
        [(UINavigationController *)self.productDetails.parentViewController popToRootViewControllerAnimated:YES];
    }
    self.detailsBoxTopCon.constant = self.detailsBoxTopCon.constant == self.originalBoxConstraint ? self.detailsViewHeightCon.constant-100 : self.originalBoxConstraint;
    [UIView animateWithDuration:spring ? 0.8 : 0.4 delay:0 usingSpringWithDamping:spring ? 0.5 : 1 initialSpringVelocity:0 options:0 animations:^{
        self.arrowImageView.transform = self.detailsBoxTopCon.constant == self.originalBoxConstraint ? CGAffineTransformIdentity : CGAffineTransformMakeRotation(M_PI);
        [self.view layoutIfNeeded];
    }completion:^(BOOL finished){
#ifndef OL_NO_ANALYTICS
        self.detailsBoxTopCon.constant == self.originalBoxConstraint ? [OLAnalytics trackProductDetailsViewClosed:self.product.productTemplate.name hidePrice:[OLKiteABTesting sharedInstance].hidePrice] : [OLAnalytics trackProductDetailsViewOpened:self.product.productTemplate.name hidePrice:[OLKiteABTesting sharedInstance].hidePrice];
#endif
    }];
    
}

- (IBAction)onLabelDetailsTapped:(UITapGestureRecognizer *)sender{
    [self onLabelDetailsTapped:sender useSpringAnimation:YES];
}

- (IBAction)onButtonCallToActionClicked:(id)sender {
    [self onButtonStartClicked:sender];
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
    
    return YES;
}

- (IBAction)onButtonStartClicked:(id)sender {
    if ([OLKiteABTesting sharedInstance].launchedWithPrintOrder && self.product.productTemplate.templateUI != kOLTemplateUINonCustomizable){
        UIViewController *vc;
        if ([[OLKiteABTesting sharedInstance].launchWithPrintOrderVariant isEqualToString:@"Overview-Review-Checkout"]){
            vc = [self.storyboard instantiateViewControllerWithIdentifier:[OLKiteUtils reviewViewControllerIdentifierForProduct:self.product photoSelectionScreen:[OLKiteUtils imageProvidersAvailable:self]]];
        }
        else{
            [OLKiteUtils checkoutViewControllerForPrintOrder:[OLKiteUtils kiteVcForViewController:self].printOrder handler:^(id vc){
                if ([[OLKiteABTesting sharedInstance].launchWithPrintOrderVariant isEqualToString:@"Checkout"]){
                    [[vc navigationItem] setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:(OLKiteViewController *)vc action:@selector(dismiss)]];
                }
                [vc safePerformSelector:@selector(setUserEmail:) withObject:self.userEmail];
                [vc safePerformSelector:@selector(setUserPhone:) withObject:self.userPhone];
                [vc safePerformSelector:@selector(setKiteDelegate:) withObject:self.delegate];
                [vc safePerformSelector:@selector(setProduct:) withObject:self.product];
                [self.navigationController pushViewController:vc animated:YES];
            }];
            return;
        }
        [vc safePerformSelector:@selector(setUserEmail:) withObject:self.userEmail];
        [vc safePerformSelector:@selector(setUserPhone:) withObject:self.userPhone];
        [vc safePerformSelector:@selector(setKiteDelegate:) withObject:self.delegate];
        [vc safePerformSelector:@selector(setProduct:) withObject:self.product];
        [self.navigationController pushViewController:vc animated:YES];
        return;
    }
    else if (self.product.productTemplate.templateUI == kOLTemplateUINonCustomizable){
        if ([self shouldGoToCheckout]){
            [self doCheckout];
        }
        return;
    }
    
    UIViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:[OLKiteUtils reviewViewControllerIdentifierForProduct:self.product photoSelectionScreen:[OLKiteUtils imageProvidersAvailable:self]]];
    
    [vc safePerformSelector:@selector(setUserSelectedPhotos:) withObject:self.userSelectedPhotos];
    [vc safePerformSelector:@selector(setDelegate:) withObject:self.delegate];
    [vc safePerformSelector:@selector(setProduct:) withObject:self.product];
    
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)saveJobWithCompletionHandler:(void(^)())handler{
    OLPrintOrder *printOrder = [OLKiteUtils kiteVcForViewController:self].printOrder;
    
    OLProductPrintJob *job = [[OLProductPrintJob alloc] initWithTemplateId:self.product.templateId OLAssets:@[[OLAsset assetWithURL:[NSURL URLWithString:@"https://kite.ly/no-asset.jpg"]]]];
    NSArray *jobs = [NSArray arrayWithArray:printOrder.jobs];
    for (id<OLPrintJob> existingJob in jobs){
        if ([existingJob.uuid isEqualToString:self.product.uuid]){
            if ([existingJob extraCopies] > 0){
                [existingJob setExtraCopies:[existingJob extraCopies]-1];
            }
            else{
                [printOrder removePrintJob:existingJob];
            }
            job.uuid = self.product.uuid;
        }
    }
    self.product.uuid = job.uuid;
    self.editingPrintJob = job;
    if ([printOrder.jobs containsObject:self.editingPrintJob]){
        id<OLPrintJob> existingJob = printOrder.jobs[[printOrder.jobs indexOfObject:self.editingPrintJob]];
        [existingJob setExtraCopies:[existingJob extraCopies]+1];
        for (NSString *option in self.product.selectedOptions.allKeys){
            [job setValue:self.product.selectedOptions[option] forOption:option];
        }
    }
    else{
        [printOrder addPrintJob:self.editingPrintJob];
    }
    
    [printOrder saveOrder];
    
    if (handler){
        handler();
    }
}

/**
 *  Will only do checkout on this screen for non-customizable products.
 */
- (void)doCheckout {
    [self saveJobWithCompletionHandler:NULL];
    
    OLPrintOrder *printOrder = [OLKiteUtils kiteVcForViewController:self].printOrder;
        [OLKiteUtils checkoutViewControllerForPrintOrder:printOrder handler:^(id vc){
            [vc safePerformSelector:@selector(setUserEmail:) withObject:[OLKiteUtils userEmail:self]];
            [vc safePerformSelector:@selector(setUserPhone:) withObject:[OLKiteUtils userPhone:self]];
            [vc safePerformSelector:@selector(setKiteDelegate:) withObject:[OLKiteUtils kiteDelegate:self]];
            
            [self.navigationController pushViewController:vc animated:YES];
        }];
}

-(void)userDidTapOnImage{
    if (self.detailsBoxTopCon.constant != self.originalBoxConstraint){
        [self onLabelDetailsTapped:nil useSpringAnimation:YES];
    }
    else{
        [self onButtonStartClicked:nil];
    }
}
- (IBAction)onPanGestureRecognized:(UIPanGestureRecognizer *)gesture {
    
    static CGFloat originalY;
    
    if (gesture.state == UIGestureRecognizerStateBegan){
        originalY = self.detailsBoxTopCon.constant;
        [self.view layoutIfNeeded];
    }
    else if (gesture.state == UIGestureRecognizerStateChanged){
        CGPoint translate = [gesture translationInView:gesture.view.superview];
        self.detailsBoxTopCon.constant = MIN(originalY - translate.y, self.detailsViewHeightCon.constant);
        
        CGFloat percentComplete = MAX(self.detailsBoxTopCon.constant - self.originalBoxConstraint, 0) / (self.detailsViewHeightCon.constant-100.0-self.originalBoxConstraint);
        self.arrowImageView.transform = CGAffineTransformMakeRotation(M_PI * MIN(percentComplete, 1));
        
        if (translate.y != 0){
            [(UINavigationController *)self.productDetails.parentViewController popToRootViewControllerAnimated:YES];
        }
    }
    else if (gesture.state == UIGestureRecognizerStateEnded ||
             gesture.state == UIGestureRecognizerStateFailed ||
             gesture.state == UIGestureRecognizerStateCancelled){
        
        CGFloat start = self.detailsBoxTopCon.constant;
        self.detailsBoxTopCon.constant = [gesture velocityInView:gesture.view].y < 0 ? self.detailsViewHeightCon.constant-100.0 : self.originalBoxConstraint;
        
        CGFloat distance = ABS(start - self.detailsBoxTopCon.constant);
        CGFloat total = self.detailsViewHeightCon.constant-100.0-self.originalBoxConstraint;
        CGFloat percentComplete = 1 - distance / total;
        
        CGFloat damping = ABS(0.5 + (0.5 * percentComplete)*(0.5 * percentComplete));
        CGFloat time = ABS(0.8 - (0.8 * percentComplete));
        
        BOOL opening = [gesture velocityInView:gesture.view].y > 0;
        
        [UIView animateWithDuration:time delay:0 usingSpringWithDamping:damping initialSpringVelocity:0 options:0 animations:^{
            self.arrowImageView.transform = opening ? CGAffineTransformIdentity : CGAffineTransformMakeRotation(M_PI);
            [self.view layoutIfNeeded];
        }completion:^(BOOL finished){
#ifndef OL_NO_ANALYTICS
            opening ? [OLAnalytics trackProductDetailsViewClosed:self.product.productTemplate.name hidePrice:[OLKiteABTesting sharedInstance].hidePrice] : [OLAnalytics trackProductDetailsViewOpened:self.product.productTemplate.name hidePrice:[OLKiteABTesting sharedInstance].hidePrice];
#endif
        }];
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
    }];
}

#pragma mark - UIPageViewControllerDataSource

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    OLProductOverviewPageContentViewController *vc = (OLProductOverviewPageContentViewController *) viewController;
    vc.delegate = self;
    NSUInteger index = vc.pageIndex - 1;
    if (vc.pageIndex == 0) {
        index = self.product.productPhotos.count - 1;
    }
    return [self viewControllerAtIndex:index];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    OLProductOverviewPageContentViewController *vc = (OLProductOverviewPageContentViewController *) viewController;
    vc.delegate = self;

    NSUInteger index = (vc.pageIndex + 1) % self.product.productPhotos.count;
    return [self viewControllerAtIndex:index];
}

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray<UIViewController *> *)previousViewControllers transitionCompleted:(BOOL)completed{
    self.pageControl.currentPage = [pageViewController.viewControllers.firstObject pageIndex];
}

- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController {
    return self.product.productPhotos.count;
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController {
    return 1;
}

#pragma mark - Tear down and restore

- (void)tearDownLargeObjectsFromMemory{
    [super tearDownLargeObjectsFromMemory];
    [(OLProductOverviewPageContentViewController *)self.pageController.viewControllers.firstObject imageView].image = nil;
}

- (void)recreateTornDownLargeObjectsToMemory{
    [super recreateTornDownLargeObjectsToMemory];
    [self.product setProductPhotography:[(OLProductOverviewPageContentViewController *)self.pageController.viewControllers.firstObject pageIndex] toImageView:[(OLProductOverviewPageContentViewController *)self.pageController.viewControllers.firstObject imageView]];
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
        return UIInterfaceOrientationMaskPortrait;
    }
}


@end
