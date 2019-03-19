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

#import "NSDecimalNumber+CostFormatter.h"
#import "NSObject+Utils.h"
#import "OLAnalytics.h"
#import "OLFrameOrderReviewViewController.h"
#import "OLKiteABTesting.h"
#import "OLKiteUtils.h"
#import "OLKiteViewController.h"
#import "OLPackProductViewController.h"
#import "OLProduct.h"
#import "OLProductDetailsViewController.h"
#import "OLProductOverviewPageContentViewController.h"
#import "OLProductOverviewViewController.h"
#import "OLProductTypeSelectionViewController.h"
#import "OLSingleProductReviewViewController.h"
#import "OLUserSession.h"
#import "UIViewController+OLMethods.h"
#import "OLKiteViewController+Private.h"
#import "OLAsset+Private.h"
#import "UIColor+OLHexString.h"
#import "UIView+RoundRect.h"
#import "UIView+AutoLayoutHelper.h"

@interface OLProductOverviewPageContentViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@end

@interface OLProduct (Private)
- (void)setProductPhotography:(NSUInteger)i toImageView:(UIImageView *)imageView;
@end

@interface OLProductOverviewViewController () <UIPageViewControllerDataSource, OLProductOverviewPageContentViewControllerDelegate, OLProductDetailsDelegate, UIPageViewControllerDelegate>
@property (strong, nonatomic) UIPageViewController *pageController;
@property (strong, nonatomic) IBOutlet UIPageControl *pageControl;
@property (weak, nonatomic) UILabel *costLabel;
@property (weak, nonatomic) IBOutlet UIButton *ctaButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *detailsBoxTopCon;
@property (weak, nonatomic) UIImageView *arrowImageView;
@property (weak, nonatomic) IBOutlet UIView *detailsView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *detailsViewHeightCon;
@property (weak, nonatomic) IBOutlet UIView *detailsSeparator;
@property (assign, nonatomic) CGFloat originalBoxConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *separatorHeightCon;
@property (weak, nonatomic) IBOutlet UIImageView *whiteGradient;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *whiteGradientTopCon;

@property (strong, nonatomic) OLProductDetailsViewController *productDetails;

@end

@implementation OLProductOverviewViewController

- (void)setProduct:(OLProduct *)product{
    _product = product;
    self.productDetails.product = _product;
    
    [self setupProductRepresentation];
    
    [OLAnalytics trackProductDetailsScreenViewed:self.product.productTemplate hidePrice:[OLKiteABTesting sharedInstance].hidePrice];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[OLKiteABTesting sharedInstance].backButtonText
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:nil
                                                                            action:nil];
    [self setupDetailsView];
    
    self.pageController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    self.pageController.dataSource = self;
    self.pageController.delegate = self;
    self.pageController.view.translatesAutoresizingMaskIntoConstraints = false;
    
    UIViewController *vc = [self viewControllerAtIndex:0];
    if (vc){
        [self.pageController setViewControllers:@[vc] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    }
    [self addChildViewController:self.pageController];
    [self.view insertSubview:self.pageController.view belowSubview:self.pageControl];
    [self.pageController didMoveToParentViewController:self];
    
    [self.view addConstraints:@[[NSLayoutConstraint constraintWithItem:self.pageController.view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1 constant:0]]];
    [self.view addConstraints:@[[NSLayoutConstraint constraintWithItem:self.pageController.view attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottomMargin multiplier:1 constant:-115]]];
    [self.pageController.view leadingFromSuperview:0 relation:NSLayoutRelationEqual];
    [self.pageController.view trailingToSuperview:0 relation:NSLayoutRelationEqual];
    
    self.separatorHeightCon.constant = 1.5;
    
    UIPageControl *pageControl = [UIPageControl appearance];
    pageControl.pageIndicatorTintColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.5];
    pageControl.currentPageIndicatorTintColor = [UIColor whiteColor];
    pageControl.backgroundColor = [UIColor clearColor];
    pageControl.numberOfPages = self.product.productPhotos.count;
    
    vc = self.parentViewController;
    while (vc) {
        if ([vc isKindOfClass:[OLKiteViewController class]]){
            break;
        }
        else{
            vc = vc.parentViewController;
        }
    }
    if (self.product.productTemplate.templateUI == OLTemplateUINonCustomizable){
        [self.ctaButton setTitle: NSLocalizedStringFromTableInBundle(@"Add to Basket", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") forState:UIControlStateNormal];
    }
    else{
        [self.ctaButton setTitle:NSLocalizedStringFromTableInBundle(@"Start Creating", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Start Creating [your product]") forState:UIControlStateNormal];
    }
    
    if ([OLKiteABTesting sharedInstance].lightThemeColor1){
        [self.ctaButton setBackgroundColor:[OLKiteABTesting sharedInstance].lightThemeColor1];
        [self.detailsSeparator setBackgroundColor:[OLKiteABTesting sharedInstance].lightThemeColor1];
    }
    UIFont *font = [[OLKiteABTesting sharedInstance] lightThemeHeavyFont1WithSize:17];
    if (!font){
        font = [[OLKiteABTesting sharedInstance] lightThemeFont1WithSize:17];
    }
    if (font){
        [self.ctaButton.titleLabel setFont:font];
    }
    
    NSNumber *cornerRadius = [OLKiteABTesting sharedInstance].lightThemeButtonRoundCorners;
    if (cornerRadius){
        [self.ctaButton makeRoundRectWithRadius:[cornerRadius floatValue]];
    } else {
        [self.ctaButton makeRoundRectWithRadius:10];
    }
    
    if ([OLUserSession currentSession].capitalizeCtaTitles){
        [self.ctaButton setTitle:[[self.ctaButton titleForState:UIControlStateNormal] uppercaseString] forState:UIControlStateNormal];
    }
    
    self.originalBoxConstraint = self.detailsBoxTopCon.constant;
    
    if ([OLKiteABTesting sharedInstance].lightThemeColorDescriptionSeparator){
        self.detailsSeparator.backgroundColor = [OLKiteABTesting sharedInstance].lightThemeColorDescriptionSeparator;
    }
}

- (void)setupProductRepresentation{
    if ([self isPushed]){
        self.parentViewController.title = self.product.productTemplate.name;
    }
    else{
        self.title = self.product.productTemplate.name;
    }
    
    self.pageControl.numberOfPages = self.product.productPhotos.count;
    
    if (self.pageController){
        [self.pageController setViewControllers:@[[self viewControllerAtIndex:0]] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:NULL];
    }
    
    if ([OLKiteABTesting sharedInstance].hidePrice){
        [self.costLabel removeFromSuperview];
    }
    else{
        self.costLabel.text = self.product.unitCost;
        
        NSString *original = self.product.originalUnitCost;
        if (original){
            UILabel *originalCostLabel = [[UILabel alloc] init];
            [self.costLabel.superview addSubview:originalCostLabel];
            originalCostLabel.translatesAutoresizingMaskIntoConstraints = NO;
            
            [originalCostLabel.superview addConstraint:[NSLayoutConstraint constraintWithItem:originalCostLabel attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.costLabel attribute:NSLayoutAttributeLeft multiplier:1 constant:-10]];
            [originalCostLabel.superview addConstraint:[NSLayoutConstraint constraintWithItem:originalCostLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.costLabel attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
            
            NSAttributedString *attCost = [[NSAttributedString alloc] initWithString:original attributes:@{NSFontAttributeName : self.costLabel.font, NSStrikethroughStyleAttributeName : [NSNumber numberWithInteger:NSUnderlineStyleSingle], NSForegroundColorAttributeName : [UIColor colorWithWhite:0.40 alpha:1.000]}];
            originalCostLabel.attributedText = attCost;
        }
    }
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    self.product.selectedOptions = nil;
    self.product.uuid = nil;
    
    [self addBasketIconToTopRight];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [self addBasketIconToTopRight];
    [(PhotobookNavigationBar *)self.navigationController.navigationBar setBarType:PhotobookNavigationBarTypeWhite];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id context){
        self.detailsViewHeightCon.constant = size.height > size.width ? 450 : [self.productDetails recommendedDetailsBoxHeight];
        self.detailsBoxTopCon.constant = ![self boxIsHidden] ? self.detailsViewHeightCon.constant-100 : self.originalBoxConstraint;
        [self addBasketIconToTopRight];
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
    
    UIFont *font = [[OLKiteABTesting sharedInstance] lightThemeFont1WithSize:17];
    if (font){
        [self.costLabel setFont:font];
    }
    
    
    [self addChildViewController:self.productDetails];
    [self.detailsView addSubview:self.productDetails.view];
    UIView *detailsVcView = self.productDetails.view;
    
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
    self.detailsBoxTopCon.constant = self.detailsBoxTopCon.constant == self.originalBoxConstraint ? self.detailsViewHeightCon.constant-100 : self.originalBoxConstraint;
    [UIView animateWithDuration:spring ? 0.8 : 0.4 delay:0 usingSpringWithDamping:spring ? 0.5 : 1 initialSpringVelocity:0 options:0 animations:^{
        self.arrowImageView.transform = self.detailsBoxTopCon.constant == self.originalBoxConstraint ? CGAffineTransformIdentity : CGAffineTransformMakeRotation(M_PI);
        [self.view layoutIfNeeded];
    } completion:NULL];
    
}

- (IBAction)onLabelDetailsTapped:(UITapGestureRecognizer *)sender{
    [self onLabelDetailsTapped:sender useSpringAnimation:YES];
}

- (IBAction)onButtonCallToActionClicked:(id)sender {
    [self onButtonStartClicked:sender];
}

- (IBAction)onButtonStartClicked:(id)sender {
    if (self.product.productTemplate.templateUI == OLTemplateUINonCustomizable){
        [self doCheckout];
        return;
    }
    
    UIViewController *vc = [[OLUserSession currentSession].kiteVc reviewViewControllerForProduct:self.product photoSelectionScreen:[OLKiteUtils imageProvidersAvailable]];
    
    [vc safePerformSelector:@selector(setDelegate:) withObject:self.delegate];
    [vc safePerformSelector:@selector(setProduct:) withObject:self.product];
    
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)saveJobWithCompletionHandler:(void(^)(void))handler{
    
    OLProductPrintJob *job = [[OLProductPrintJob alloc] initWithTemplateId:self.product.templateId OLAssets:@[[OLAsset assetWithURL:[NSURL URLWithString:@"https://kite.ly/no-asset.jpg"] size:CGSizeZero]]];
    [[PhotobookSDK shared] addProductToBasket:job];
    
    if (handler){
        handler();
    }
}

/**
 *  Will only do checkout on this screen for non-customizable products.
 */
- (void)doCheckout {
    [self saveJobWithCompletionHandler:NULL];
    
    UIViewController *checkoutVc = [[PhotobookSDK shared] checkoutViewControllerWithEmbedInNavigation:NO dismissClosure:^(UIViewController *viewController, BOOL success){
        if (![OLUserSession currentSession].kiteVc){
            [viewController dismissViewControllerAnimated:YES completion:NULL];
        }
        else if ([viewController isKindOfClass:[NSClassFromString(@"Photobook.PhotobookViewController") class]]){
            [viewController.navigationController popViewControllerAnimated:YES];
        } else {
            [viewController.navigationController popToRootViewControllerAnimated:YES];
        }
    }];
    UIViewController *firstController = self.navigationController.viewControllers.firstObject;
    [self.navigationController setViewControllers:@[firstController, checkoutVc] animated:YES];
    [[OLUserSession currentSession] resetUserSelectedPhotos];
}

- (void)userDidTapOnImage{
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
        } completion: NULL];
    }
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

#pragma mark - Tear down and restore

- (void)tearDownLargeObjectsFromMemory{
    [super tearDownLargeObjectsFromMemory];
    [(OLProductOverviewPageContentViewController *)self.pageController.viewControllers.firstObject imageView].image = nil;
}

- (void)recreateTornDownLargeObjectsToMemory{
    [super recreateTornDownLargeObjectsToMemory];
    [self.product setProductPhotography:[(OLProductOverviewPageContentViewController *)self.pageController.viewControllers.firstObject pageIndex] toImageView:[(OLProductOverviewPageContentViewController *)self.pageController.viewControllers.firstObject imageView]];
}


@end

