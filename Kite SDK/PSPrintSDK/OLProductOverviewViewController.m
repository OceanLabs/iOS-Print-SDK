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
#import "OLCaseSelectionViewController.h"

@interface OLProductOverviewViewController () <UIPageViewControllerDataSource, OLProductOverviewPageContentViewControllerDelegate>
@property (strong, nonatomic) UIPageViewController *pageController;
@property (strong, nonatomic) IBOutlet UIPageControl *pageControl;
@property (weak, nonatomic) IBOutlet UILabel *costLabel;
@property (weak, nonatomic) IBOutlet UILabel *sizeLabel;
@property (weak, nonatomic) IBOutlet UILabel *freePostageLabel;
@property (weak, nonatomic) IBOutlet UILabel *fromLabel;
@property (weak, nonatomic) IBOutlet OLWhiteSquare *whiteBox;
@end

@implementation OLProductOverviewViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackProductDescriptionScreenViewed:self.product.productTemplate.name];
#endif
    
    if (self.product.productTemplate.templateClass == kOLTemplateClassPoster){
        self.title = NSLocalizedString(@"Posters", @"");
    }
    else if (self.product.productTemplate.templateClass == kOLTemplateClassFrame){
        self.title = NSLocalizedString(@"Frames", @"");
    }
    else if (self.product.productTemplate.templateClass == kOLTemplateClassCase){
        self.title = NSLocalizedString(@"Phone Cases", @"");
        self.fromLabel.hidden = NO;
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
    
    if (self.product.productTemplate.templateClass == kOLTemplateClassFrame){
        self.sizeLabel.text = [NSString stringWithFormat:@"%@", self.product.dimensions];
    }
    else{
        self.sizeLabel.text = [NSString stringWithFormat:@"%@\n%@", self.product.packInfo, self.product.dimensions];
    }
    
    if (self.product.productTemplate.templateClass == kOLTemplateClassPoster){
        self.costLabel.hidden = YES;
        self.sizeLabel.hidden = YES;
        self.freePostageLabel.hidden = YES;
        self.whiteBox.hidden = YES;
    }
    
    if (self.product.productTemplate.templateClass == kOLTemplateClassCase){
        [self.sizeLabel removeFromSuperview];
    }
}

-(void)viewDidAppear:(BOOL)animated{
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

- (BOOL)shouldAutorotate {
    return NO;
}

- (UIViewController *)viewControllerAtIndex:(NSUInteger)index {
    if (index == NSNotFound || index >= self.self.product.productPhotos.count) {
        return nil;
    }
    
    OLProductOverviewPageContentViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"ProductOverviewPageContentViewController"];
    vc.pageIndex = index;
    vc.product = self.product;
    vc.delegate = self;
    return vc;
}

- (IBAction)onButtonStartClicked:(UIBarButtonItem *)sender {
    if (self.product.productTemplate.templateClass == kOLTemplateClassFrame){
        OLFrameSelectionViewController *frameVc = [self.storyboard instantiateViewControllerWithIdentifier:@"FrameSelectionViewController"];
        frameVc.assets = self.assets;
        frameVc.delegate = self.delegate;
        [self.navigationController pushViewController:frameVc animated:YES];
    }
    else if (self.product.productTemplate.templateClass == kOLTemplateClassCase){
        OLCaseSelectionViewController *caseVc = [self.storyboard instantiateViewControllerWithIdentifier:@"OLCaseSelectionViewController"];
        caseVc.assets = self.assets;
        caseVc.delegate = self.delegate;
        [self.navigationController pushViewController:caseVc animated:YES];
    }
    else{
        OLOrderReviewViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"OrderReviewViewController"];
        vc.assets = self.assets;
        vc.product = self.product;
        vc.delegate = self.delegate;
        [self.navigationController pushViewController:vc animated:YES];
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


@end
