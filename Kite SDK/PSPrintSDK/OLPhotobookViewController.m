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
#import "OLPhotobookPageViewController.h"

@interface OLPhotobookViewController () <UIPageViewControllerDataSource, UIPageViewControllerDelegate>

@property (strong, nonatomic) UIPageViewController *pageController;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (strong, nonatomic) NSMutableArray *photobookPhotos;

@end

@implementation OLPhotobookViewController

- (void)viewDidLoad{
    [super viewDidLoad];
    
    self.photobookPhotos = [[NSMutableArray alloc] initWithCapacity:self.product.quantityToFulfillOrder];
    [self.photobookPhotos addObjectsFromArray:self.userSelectedPhotos];
    for (NSInteger i = self.userSelectedPhotos.count; i < self.product.quantityToFulfillOrder; i++){
        [self.photobookPhotos addObject:[self.userSelectedPhotos objectAtIndex:i % self.userSelectedPhotos.count]];
    }
    
    self.pageController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStylePageCurl navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:@{UIPageViewControllerOptionSpineLocationKey : [NSNumber numberWithInt:UIPageViewControllerSpineLocationMid]}];
    self.pageController.dataSource = self;
    self.pageController.delegate = self;
    
    [self.pageController setViewControllers:@[[self viewControllerAtIndex:0], [self viewControllerAtIndex:1]] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    
    [self addChildViewController:self.pageController];
    [self.containerView addSubview:self.pageController.view];
    
    UIView *view = self.pageController.view;
    view.translatesAutoresizingMaskIntoConstraints = NO;
    NSDictionary *views = NSDictionaryOfVariableBindings(view);
    NSMutableArray *con = [[NSMutableArray alloc] init];
    
    NSArray *visuals = @[@"H:|-0-[view]-0-|",
                         @"V:|-0-[view]-0-|"];
    
    
    for (NSString *visual in visuals) {
        [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
    }
    
    [view.superview addConstraints:con];
    
    self.title = [NSString stringWithFormat: NSLocalizedString(@"Pages 1 & 2 of %d", @""), self.product.quantityToFulfillOrder];
}

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed{
    if (completed){
        OLPhotobookPageViewController *vc1 = [pageViewController.viewControllers firstObject];
        OLPhotobookPageViewController *vc2 = [pageViewController.viewControllers lastObject];
        self.title = [NSString stringWithFormat: NSLocalizedString(@"Pages %d & %d of %d", @""), vc1.pageIndex+1, vc2.pageIndex+1, self.product.quantityToFulfillOrder];
    }
}

- (UIViewController *)viewControllerAtIndex:(NSUInteger)index {
    if (index == NSNotFound || index >= self.photobookPhotos.count) {
        return nil;
    }
    
    OLPhotobookPageViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"OLPhotobookPageViewController"];
    vc.pageIndex = index;
    vc.userSelectedPhotos = self.photobookPhotos;
    vc.assets = self.assets;
    return vc;
}

#pragma mark - UIPageViewControllerDataSource

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    OLPhotobookPageViewController *vc = (OLPhotobookPageViewController *) viewController;
    NSUInteger index = vc.pageIndex - 1;
    if (vc.pageIndex == 0) {
        return nil;
    }
    return [self viewControllerAtIndex:index];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    OLPhotobookPageViewController *vc = (OLPhotobookPageViewController *) viewController;
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

@end
