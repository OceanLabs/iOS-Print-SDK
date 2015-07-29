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
#import "OLPosterViewController.h"
#import "OLFrameOrderReviewViewController.h"
#import "OLPostcardViewController.h"
#import "NSObject+Utils.h"
#import "NSDecimalNumber+CostFormatter.h"
#import "OLKiteABTesting.h"

@interface OLKitePrintSDK (Kite)

+ (OLKiteViewController *)kiteViewControllerInNavStack:(NSArray *)viewControllers;

@end

@interface OLKiteViewController ()

@property (strong, nonatomic) OLPrintOrder *printOrder;
- (void)dismiss;

@end

@interface OLProductOverviewViewController () <UIPageViewControllerDataSource, OLProductOverviewPageContentViewControllerDelegate>
@property (strong, nonatomic) UIPageViewController *pageController;
@property (strong, nonatomic) IBOutlet UIPageControl *pageControl;
@property (weak, nonatomic) IBOutlet UILabel *costLabel;
@property (weak, nonatomic) IBOutlet UILabel *sizeLabel;
@property (weak, nonatomic) IBOutlet UILabel *freePostageLabel;
@property (weak, nonatomic) IBOutlet OLWhiteSquare *whiteBox;
@property (weak, nonatomic) IBOutlet UIButton *callToActionButton;
@property (weak, nonatomic) IBOutlet UILabel *callToActionLabel;
@property (weak, nonatomic) IBOutlet UIImageView *callToActionChevron;

@end

@implementation OLProductOverviewViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
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
    
    self.costLabel.text = self.product.unitCost;
    
    self.sizeLabel.text = [NSString stringWithFormat:@"%@%@", self.product.packInfo, self.product.dimensions];
    
    OLTemplateUI templateClass = self.product.productTemplate.templateUI;
    if (templateClass == kOLTemplateUICase){
        [self.sizeLabel removeFromSuperview];
    }
    
    NSDecimalNumber *shippingCost = [self.product.productTemplate shippingCostForCountry:[OLCountry countryForCurrentLocale]];
    if (shippingCost && [shippingCost doubleValue] != 0){
        self.freePostageLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Shipping: %@", @""), [shippingCost formatCostForCurrencyCode:[self.product.productTemplate currencyForCurrentLocale]]];
    }
    else if (!shippingCost){ // ¯\_(ツ)_/¯ don't assume 0, remove shipping information altogether
        [self.freePostageLabel removeFromSuperview];
        [self.whiteBox removeFromSuperview];
    }
    //else do nothing, free shipping label will be shown
    
    UIViewController *vc = self.parentViewController;
    while (vc) {
        if ([vc isKindOfClass:[OLKiteViewController class]]){
            break;
        }
        else{
            vc = vc.parentViewController;
        }
    }
    if ([OLKiteABTesting sharedInstance].hidePrice){
        [self.costLabel removeFromSuperview];
        [self.freePostageLabel removeFromSuperview];
        [self.whiteBox removeFromSuperview];
    }
    
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackProductDescriptionScreenViewed:self.product.productTemplate.name hidePrice:[OLKiteABTesting sharedInstance].hidePrice];
#endif
    
    if ([[OLKiteABTesting sharedInstance].productTileStyle isEqualToString:@"Classic"]){
        [self.callToActionButton removeFromSuperview];
        [self.callToActionChevron removeFromSuperview];
        [self.callToActionLabel removeFromSuperview];
    }
    else if ([[OLKiteABTesting sharedInstance].productTileStyle isEqualToString:@"B"]){
        [self.callToActionChevron removeFromSuperview];
        self.callToActionLabel.textAlignment = NSTextAlignmentCenter;
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

- (IBAction)onTapGestureRecognized:(UITapGestureRecognizer *)sender {
    [self onButtonStartClicked:nil];
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
        OLCheckoutViewController *vc = [[OLCheckoutViewController alloc] initWithPrintOrder:printOrder];
        [[vc navigationItem] setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:(OLKiteViewController *)vc action:@selector(dismiss)]];
        vc.userEmail = self.userEmail;
        vc.userPhone = self.userPhone;
        vc.kiteDelegate = self.delegate;
        [self.navigationController pushViewController:vc animated:YES];
        return;
    }
    
    if (self.product.productTemplate.templateUI == kOLTemplateUICase){
        vc = [self.storyboard instantiateViewControllerWithIdentifier:@"OLCaseViewController"];
    }
    else if (self.product.productTemplate.templateUI == kOLTemplateUIPostcard){
        vc = [self.storyboard instantiateViewControllerWithIdentifier:@"OLPostcardViewController"];
    }
    else if (self.product.productTemplate.templateUI == kOLTemplateUIPoster){
        vc = [self.storyboard instantiateViewControllerWithIdentifier:@"OLSingleImageProductReviewViewController"];
    }
    else if (self.product.productTemplate.templateUI == kOLTemplateUIPhotobook){
        vc = [self.storyboard instantiateViewControllerWithIdentifier:@"OLEditPhotobookViewController"];
    }
    else{
        if (![self.delegate respondsToSelector:@selector(kiteControllerShouldAllowUserToAddMorePhotos:)] || [self.delegate kiteControllerShouldAllowUserToAddMorePhotos:[OLKitePrintSDK kiteViewControllerInNavStack:self.navigationController.viewControllers]]){
            vc = [self.storyboard instantiateViewControllerWithIdentifier:@"PhotoSelectionViewController"];
        }
        else if (!(![self.delegate respondsToSelector:@selector(kiteControllerShouldAllowUserToAddMorePhotos:)] || [self.delegate kiteControllerShouldAllowUserToAddMorePhotos:[OLKitePrintSDK kiteViewControllerInNavStack:self.navigationController.viewControllers]]) && self.product.productTemplate.templateUI == kOLTemplateUIPhotobook){
            vc = [self.storyboard instantiateViewControllerWithIdentifier:@"PhotobookViewController"];
            if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8){
                [vc safePerformSelector:@selector(setUserSelectedPhotos:) withObject:self.userSelectedPhotos];
                [vc safePerformSelector:@selector(setDelegate:) withObject:self.delegate];
                [vc safePerformSelector:@selector(setProduct:) withObject:self.product];
                
                [self.navigationController presentViewController:vc animated:YES completion:NULL];
                return;
            }
        }
        else{
            vc = [self.storyboard instantiateViewControllerWithIdentifier:@"OrderReviewViewController"];
        }
    }
    [vc safePerformSelector:@selector(setUserSelectedPhotos:) withObject:self.userSelectedPhotos];
    [vc safePerformSelector:@selector(setDelegate:) withObject:self.delegate];
    [vc safePerformSelector:@selector(setProduct:) withObject:self.product];
    
    [self.navigationController pushViewController:vc animated:YES];
}

-(void)userDidTapOnImage{
    [self onButtonStartClicked:nil];
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

- (NSUInteger)supportedInterfaceOrientations {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8) {
        return UIInterfaceOrientationMaskAll;
    }
    else{
        return UIInterfaceOrientationMaskPortrait;
    }
}


@end
