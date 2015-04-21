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

@interface OLPhotobookViewController () <UIPageViewControllerDataSource, UIPageViewControllerDelegate, UIGestureRecognizerDelegate, OLScrollCropViewControllerDelegate>

@property (strong, nonatomic) UIPageViewController *pageController;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (strong, nonatomic) NSMutableArray *photobookPhotos;
@property (strong, nonatomic) OLPrintPhoto *editingPrintPhoto;
@property (assign, nonatomic) NSInteger editingPageIndex;
@property (strong, nonatomic) NSLayoutConstraint *centerXCon;

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
    
    NSArray *visuals = @[@"H:|-20-[view]-20-|", @"V:|-20-[view]-20-|"];
    
    for (NSString *visual in visuals) {
        [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
    }
    
    [view.superview addConstraints:con];
    
    CGFloat minimumDimension = MIN(self.view.frame.size.width, self.view.frame.size.height);
    
    NSLayoutConstraint *heightCon = [NSLayoutConstraint constraintWithItem:self.containerView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.containerView attribute:NSLayoutAttributeHeight multiplier:1 constant:minimumDimension - 34];
    heightCon.priority = UILayoutPriorityDefaultHigh;
    [self.containerView addConstraint:heightCon];
    
    
    self.centerXCon = [NSLayoutConstraint constraintWithItem:self.containerView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1 constant:0];
    if (self.view.frame.size.width > self.view.frame.size.height){
        [self.view addConstraint:self.centerXCon];
    }
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapGestureRecognized:)];
    tapGesture.delegate = self;
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPanGestureRecognized:)];
    panGesture.delegate = self;
    
    [self.pageController.view addGestureRecognizer:tapGesture];
    [self.pageController.view addGestureRecognizer:panGesture];
    
    self.title = [NSString stringWithFormat: NSLocalizedString(@"Pages 1 & 2 of %d", @""), self.product.quantityToFulfillOrder];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator{
    if (size.width > size.height){
        [self.view addConstraint:self.centerXCon];
    }
    else{
        [self.view removeConstraint:self.centerXCon];
    }
}

- (void)onTapGestureRecognized:(UITapGestureRecognizer *)sender{
    OLPrintPhoto *tempPrintPhoto = [[OLPrintPhoto alloc] init];
    NSInteger index = 0;
    if ([sender locationInView:self.pageController.view].x < self.pageController.view.frame.size.width / 2.0){
        self.editingPageIndex = 0;
    }
    else{
        self.editingPageIndex = 1;
    }
    
    index = [[self.pageController.viewControllers objectAtIndex:self.editingPageIndex] pageIndex];
    tempPrintPhoto.asset = self.assets[index];
    self.editingPrintPhoto = self.photobookPhotos[index];
    
    UINavigationController *nav = [self.storyboard instantiateViewControllerWithIdentifier:@"CropViewNavigationController"];
    OLScrollCropViewController *cropVc = (id)nav.topViewController;
    cropVc.enableCircleMask = self.product.productTemplate.templateUI == kOLTemplateUICircle;
    cropVc.delegate = self;
    cropVc.aspectRatio = [self productAspectRatio];
    [tempPrintPhoto getImageWithProgress:NULL completion:^(UIImage *image){
        [cropVc setFullImage:image];
        [self presentViewController:nav animated:YES completion:NULL];
    }];

}

- (void)onPanGestureRecognized:(UIPanGestureRecognizer *)recognizer{
    CGPoint translation = [recognizer translationInView:self.pageController.view];
    recognizer.view.center = CGPointMake(recognizer.view.center.x + translation.x,
                                         recognizer.view.center.y);
    [recognizer setTranslation:CGPointMake(0, 0) inView:self.pageController.view];
    
//    if (recognizer.state == UIGestureRecognizerStateEnded) {
//        
//        CGPoint velocity = [recognizer velocityInView:self.pageController.view];
//        CGFloat magnitude = sqrtf((velocity.x * velocity.x) + (velocity.y * velocity.y));
//        CGFloat slideMult = magnitude / 200;
//        
//        float slideFactor = 0.1 * slideMult; // Increase for more of a slide
//        CGPoint finalPoint = CGPointMake(recognizer.view.center.x + (velocity.x * slideFactor),
//                                         recognizer.view.center.y);
//        finalPoint.x = MIN(MAX(finalPoint.x, 0), self.pageController.view.bounds.size.width);
//        finalPoint.y = MIN(MAX(finalPoint.y, 0), self.pageController.view.bounds.size.height);
//        
//        [UIView animateWithDuration:slideFactor*2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
//            recognizer.view.center = finalPoint;
//        } completion:nil];
//        
//    }
}

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]] && [otherGestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]){
        return NO;
    }
    else if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]] && [otherGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]){
        return NO;
    }
    return YES;
}

- (CGFloat) productAspectRatio{
    return 1;//self.product.productTemplate.sizePx.height / self.product.productTemplate.sizePx.width;
}

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed{
    if (completed){
        OLPhotobookPageContentViewController *vc1 = [pageViewController.viewControllers firstObject];
        OLPhotobookPageContentViewController *vc2 = [pageViewController.viewControllers lastObject];
        self.title = [NSString stringWithFormat: NSLocalizedString(@"Pages %d & %d of %d", @""), vc1.pageIndex+1, vc2.pageIndex+1, self.product.quantityToFulfillOrder];
    }
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

-(void)userDidCropImage:(UIImage *)croppedImage{
    [self.editingPrintPhoto unloadImage];
    self.editingPrintPhoto.asset = [OLAsset assetWithImageAsJPEG:croppedImage];
    
    [(OLPhotobookPageContentViewController *)[self.pageController.viewControllers objectAtIndex:self.editingPageIndex] loadImage];
}

#pragma mark - UIPageViewControllerDataSource

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

@end
