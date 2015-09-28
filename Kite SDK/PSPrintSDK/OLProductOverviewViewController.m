//
//  ProductOverviewViewController.m
//  Kite Print SDK
//
//  Created by Deon Botha on 03/01/2014.
//  Copyright (c) 2014 Ocean Labs. All rights reserved.
//

#import "OLProductOverviewViewController.h"
#import "OLProductOverviewPageContentViewController.h"
#import "OLProduct.h"
#import "OLOrderReviewViewController.h"
#import "OLPosterSizeSelectionViewController.h"
#import "OLWhiteSquare.h"
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
#import <TSMarkdownParser.h>

@interface OLKitePrintSDK (Kite)

+ (OLKiteViewController *)kiteViewControllerInNavStack:(NSArray *)viewControllers;
+ (NSString *)detailsBoxStringForProduct:(OLProduct *)product;
+ (void)checkoutViewControllerForPrintOrder:(OLPrintOrder *)printOrder handler:(void(^)(id vc))handler;
+ (NSString *)reviewViewControllerIdentifierForProduct:(OLProduct *)product photoSelectionScreen:(BOOL)photoSelectionScreen;

@end

@interface OLKiteViewController ()

@property (strong, nonatomic) OLPrintOrder *printOrder;
- (void)dismiss;

@end

@interface OLProductOverviewViewController () <UIPageViewControllerDataSource, OLProductOverviewPageContentViewControllerDelegate>
@property (strong, nonatomic) UIPageViewController *pageController;
@property (strong, nonatomic) IBOutlet UIPageControl *pageControl;
@property (weak, nonatomic) IBOutlet UILabel *costLabel;
@property (weak, nonatomic) IBOutlet UIButton *callToActionButton;
@property (weak, nonatomic) IBOutlet UILabel *callToActionLabel;
@property (weak, nonatomic) IBOutlet UIImageView *callToActionChevron;
@property (weak, nonatomic) IBOutlet UILabel *detailsTextLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *detailsBoxTopCon;
@property (weak, nonatomic) IBOutlet UIImageView *arrowImageView;
@property (weak, nonatomic) IBOutlet UIView *detailsView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *detailsViewHeightCon;
@property (strong, nonatomic) UIVisualEffectView *visualEffectView;

@end

@implementation OLProductOverviewViewController

- (CGFloat)detailsBoxHeight{
    if ([self respondsToSelector:@selector(traitCollection)]){
        return self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact ? 340 : 450;
    }
    else{
        return 340;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGSize size = self.view.frame.size;
    self.detailsViewHeightCon.constant = size.height > size.width ? 450 : [self detailsBoxHeight];
    
    if (self.product.productTemplate.templateUI == kOLTemplateUIPoster){
        self.title = NSLocalizedString(@"Posters", @"");
    }
    else if (self.product.productTemplate.templateUI == kOLTemplateUIFrame){
        self.title = NSLocalizedString(@"Frames", @"");
    }
    else{
        self.title = self.product.productTemplate.name;
    }
    
    self.pageController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    self.pageController.dataSource = self;
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
    if ([(OLKiteViewController *)vc printOrder]){
        if (![[OLKiteABTesting sharedInstance].launchWithPrintOrderVariant isEqualToString:@"Overview-Review-Checkout"]){
            self.callToActionLabel.text = NSLocalizedString(@"Checkout", @"");
        }
        else{
            self.callToActionLabel.text = NSLocalizedString(@"Review", @"");
        }
    }
    
    NSMutableAttributedString *attributedString = [[[TSMarkdownParser standardParser] attributedStringFromMarkdown:[self.product detailsString]] mutableCopy];
    
    [attributedString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed: 0.341 green: 0.341 blue: 0.341 alpha: 1] range:NSMakeRange(0, attributedString.length)];
    self.detailsTextLabel.attributedText = attributedString;
    
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackProductDescriptionScreenViewed:self.product.productTemplate.name hidePrice:[OLKiteABTesting sharedInstance].hidePrice];
#endif
    
    if ([[OLKiteABTesting sharedInstance].productTileStyle isEqualToString:@"B"]){
        [self.callToActionChevron removeFromSuperview];
        self.callToActionLabel.textAlignment = NSTextAlignmentCenter;
    }
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0 && self.detailsView){
        UIVisualEffect *blurEffect;
        blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight];
        
        self.visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        UIView *view = self.visualEffectView;
        [self.detailsView addSubview:view];
        [self.detailsView sendSubviewToBack:view];
        
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
        self.detailsView.backgroundColor = [UIColor whiteColor];
    }
    
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id context){
        self.detailsViewHeightCon.constant = size.height > size.width ? 450 : [self detailsBoxHeight];
        self.detailsBoxTopCon.constant = self.detailsBoxTopCon.constant != 0 ? self.detailsViewHeightCon.constant-100 : 0;
    }completion:NULL];
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

- (IBAction)onTapGestureRecognized:(UITapGestureRecognizer *)sender {
    [self onButtonStartClicked:nil];
}

- (IBAction)onLabelDetailsTapped:(UITapGestureRecognizer *)sender {
    self.detailsBoxTopCon.constant = self.detailsBoxTopCon.constant == 0 ? self.detailsViewHeightCon.constant-100 : 0;
    [UIView animateWithDuration:0.8 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0 options:0 animations:^{
        self.arrowImageView.transform = self.detailsBoxTopCon.constant == 0 ? CGAffineTransformIdentity : CGAffineTransformMakeRotation(M_PI);
        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];
    }completion:^(BOOL finished){
        
    }];
    
}

- (IBAction)onButtonCallToActionClicked:(id)sender {
    [self onButtonStartClicked:sender];
}

- (IBAction)onButtonStartClicked:(id)sender {
    UIViewController *vc = self.parentViewController;
    OLPrintOrder *printOrder = nil;
    while (vc) {
        if ([vc isKindOfClass:[OLKiteViewController class]]){
            printOrder = [(OLKiteViewController *)vc printOrder];
            break;
        }
        else{
            vc = vc.parentViewController;
        }
    }
    if (printOrder){
        UIViewController *vc;
        if ([[OLKiteABTesting sharedInstance].launchWithPrintOrderVariant isEqualToString:@"Overview-Review-Checkout"]){
            vc = [self.storyboard instantiateViewControllerWithIdentifier:[OLKitePrintSDK reviewViewControllerIdentifierForProduct:self.product photoSelectionScreen:NO]];
        }
        else{
            [OLKitePrintSDK checkoutViewControllerForPrintOrder:printOrder handler:^(id vc){
                [[vc navigationItem] setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:(OLKiteViewController *)vc action:@selector(dismiss)]];
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
    
    vc = [self.storyboard instantiateViewControllerWithIdentifier:[OLKitePrintSDK reviewViewControllerIdentifierForProduct:self.product photoSelectionScreen:![self.delegate respondsToSelector:@selector(kiteControllerShouldAllowUserToAddMorePhotos:)] || [self.delegate kiteControllerShouldAllowUserToAddMorePhotos:[OLKitePrintSDK kiteViewControllerInNavStack:self.navigationController.viewControllers]]]];
    
    [vc safePerformSelector:@selector(setUserSelectedPhotos:) withObject:self.userSelectedPhotos];
    [vc safePerformSelector:@selector(setDelegate:) withObject:self.delegate];
    [vc safePerformSelector:@selector(setProduct:) withObject:self.product];
    
    [self.navigationController pushViewController:vc animated:YES];
}

-(void)userDidTapOnImage{
    if (self.detailsBoxTopCon.constant != 0){
        [self onLabelDetailsTapped:nil];
    }
    else{
        [self onButtonStartClicked:nil];
    }
}

#pragma mark - UIPageViewControllerDataSource

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    OLProductOverviewPageContentViewController *vc = (OLProductOverviewPageContentViewController *) viewController;
    vc.delegate = self;
    self.pageControl.currentPage = vc.pageIndex;
    NSUInteger index = vc.pageIndex - 1;
    if (vc.pageIndex == 0) {
        index = self.product.productPhotos.count - 1;
    }
    return [self viewControllerAtIndex:index];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    OLProductOverviewPageContentViewController *vc = (OLProductOverviewPageContentViewController *) viewController;
    vc.delegate = self;
    self.pageControl.currentPage = vc.pageIndex;
    NSUInteger index = (vc.pageIndex + 1) % self.product.productPhotos.count;
    return [self viewControllerAtIndex:index];
}

- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController {
    return self.product.productPhotos.count;
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController {
    return 1;
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
