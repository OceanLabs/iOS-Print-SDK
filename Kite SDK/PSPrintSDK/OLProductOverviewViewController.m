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
#import "OLFrameSelectionViewController.h"
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

@interface OLKitePrintSDK (Kite)

+ (OLKiteViewController *)kiteViewControllerInNavStack:(NSArray *)viewControllers;

@end

@interface OLProductOverviewViewController () <UIPageViewControllerDataSource, OLProductOverviewPageContentViewControllerDelegate>
@property (strong, nonatomic) UIPageViewController *pageController;
@property (strong, nonatomic) IBOutlet UIPageControl *pageControl;
@property (weak, nonatomic) IBOutlet UILabel *costLabel;
@property (weak, nonatomic) IBOutlet UILabel *sizeLabel;
@property (weak, nonatomic) IBOutlet UILabel *freePostageLabel;
@property (weak, nonatomic) IBOutlet OLWhiteSquare *whiteBox;
@end

@implementation OLProductOverviewViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackProductDescriptionScreenViewed:self.product.productTemplate.name];
#endif
    
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
    
    OLTemplateUI templateClass = self.product.productTemplate.templateUI;
    self.costLabel.text = self.product.unitCost;
    
    self.sizeLabel.text = [NSString stringWithFormat:@"%@%@", self.product.packInfo, self.product.dimensions];
    
    if (templateClass == kOLTemplateUICase){
        [self.sizeLabel removeFromSuperview];
    }
}

-(void)viewWillAppear:(BOOL)animated{
//    [self.splitViewController setPreferredDisplayMode:UISplitViewControllerDisplayModePrimaryOverlay];
}

-(void)viewDidAppear:(BOOL)animated{
//    [self.splitViewController setPreferredDisplayMode:UISplitViewControllerDisplayModeAllVisible];
    if (self.navigationController){
        NSMutableArray *navigationStack = self.navigationController.viewControllers.mutableCopy;
        if (navigationStack.count > 1 && [navigationStack[navigationStack.count - 2] isKindOfClass:[OLKiteViewController class]]) {
            OLKiteViewController *kiteVc = navigationStack[navigationStack.count - 2];
            if (!kiteVc.presentingViewController){
                [navigationStack removeObject:kiteVc];
                self.navigationController.viewControllers = navigationStack;
            }
        }
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

- (IBAction)onButtonStartClicked:(UIBarButtonItem *)sender {
    if (self.product.productTemplate.templateUI == kOLTemplateUIFrame){
        OLFrameSelectionViewController *frameVc = [self.storyboard instantiateViewControllerWithIdentifier:@"FrameSelectionViewController"];
        frameVc.assets = self.assets;
        frameVc.userSelectedPhotos = self.userSelectedPhotos;
        frameVc.delegate = self.delegate;
        [(UINavigationController *)[self.splitViewController.viewControllers firstObject] pushViewController:frameVc animated:YES];
        
        NSArray *products = [OLProduct products];
        OLFrameOrderReviewViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"FrameOrderReviewViewController"];
        vc.assets = self.assets;
        for (OLProduct *product in products){
            if (product.productTemplate.templateUI == kOLTemplateUIFrame){
                vc.product = product;
            }
        }
        [self.splitViewController showDetailViewController:vc sender:self];
    }
    else if (self.product.productTemplate.templateUI == kOLTemplateUICase){
        OLSingleImageProductReviewViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"OLCaseViewController"];
        vc.assets = self.assets;
        vc.userSelectedPhotos = self.userSelectedPhotos;
        vc.delegate = self.delegate;
        vc.product = self.product;
//        [self.splitViewController setPreferredDisplayMode:UISplitViewControllerDisplayModePrimaryHidden];
        [self.navigationController pushViewController:vc animated:YES];
    }
    else if (self.product.productTemplate.templateUI == kOLTemplateUIPostcard){
        OLPostcardViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"OLPostcardViewController"];
        vc.assets = self.assets;
        vc.userSelectedPhotos = self.userSelectedPhotos;
        vc.delegate = self.delegate;
        vc.product = self.product;
        [self.navigationController pushViewController:vc animated:YES];
    }
    else if (self.product.productTemplate.templateUI == kOLTemplateUIPoster){
        OLPosterViewController *dest = [self.storyboard instantiateViewControllerWithIdentifier:@"OLSingleImageProductReviewViewController"];
        dest.product = self.product;
        dest.assets = self.assets;
        dest.userSelectedPhotos = self.userSelectedPhotos;
        [self.navigationController pushViewController:dest animated:YES];
    }
    else{
        if (![self.delegate respondsToSelector:@selector(kiteControllerShouldAllowUserToAddMorePhotos:)] || [self.delegate kiteControllerShouldAllowUserToAddMorePhotos:[OLKitePrintSDK kiteViewControllerInNavStack:self.navigationController.viewControllers]]){
            OLPhotoSelectionViewController *vc;
            vc = [self.storyboard instantiateViewControllerWithIdentifier:@"PhotoSelectionViewController"];
            vc.assets = self.assets;
            vc.userSelectedPhotos = self.userSelectedPhotos;
            vc.product = self.product;
            vc.delegate = self.delegate;
            [self.navigationController pushViewController:vc animated:YES];
        }
        else{
            OLOrderReviewViewController *vc;
            vc = [self.storyboard instantiateViewControllerWithIdentifier:@"OrderReviewViewController"];
            vc.assets = self.assets;
            vc.userSelectedPhotos = self.userSelectedPhotos;
            vc.product = self.product;
            vc.delegate = self.delegate;
            [self.navigationController pushViewController:vc animated:YES];
        }
    }
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
    return 0;
}

#pragma mark - Autorotate and Orientation Methods

- (BOOL)shouldAutorotate {
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}


@end
