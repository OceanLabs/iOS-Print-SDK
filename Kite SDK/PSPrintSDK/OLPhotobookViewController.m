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

@property (strong, nonatomic) UIDynamicAnimator* dynamicAnimator;
@property (strong, nonatomic) UIDynamicItemBehavior* discardBehavior;
@property (weak, nonatomic) IBOutlet UILabel *leftPageLabel;
@property (weak, nonatomic) IBOutlet UILabel *rightPageLabel;

@end

@implementation OLPhotobookViewController

-(UIDynamicAnimator*) dynamicAnimator{
    if (!_dynamicAnimator) _dynamicAnimator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    return _dynamicAnimator;
}

-(UIDynamicItemBehavior*) discardBehavior{
    if (!_discardBehavior){
        _discardBehavior = [[UIDynamicItemBehavior alloc] init];
        [self.dynamicAnimator addBehavior:_discardBehavior];
    }
    return _discardBehavior;
}

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
    
    CGFloat maximumDimension = MAX(self.view.frame.size.width, self.view.frame.size.height);
    
    NSLayoutConstraint *heightCon = [NSLayoutConstraint constraintWithItem:self.containerView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:maximumDimension];
    heightCon.priority = UILayoutPriorityDefaultHigh;
    [self.containerView addConstraint:heightCon];
    
    self.centerXCon = [NSLayoutConstraint constraintWithItem:self.containerView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.containerView.superview attribute:NSLayoutAttributeCenterX multiplier:1 constant:0];
    if (self.view.frame.size.width > self.view.frame.size.height){
        [self.containerView.superview addConstraint:self.centerXCon];
    }
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapGestureRecognized:)];
    tapGesture.delegate = self;
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPanGestureRecognized:)];
    panGesture.delegate = self;
    
    [self.pageController.view addGestureRecognizer:tapGesture];
    [self.pageController.view addGestureRecognizer:panGesture];
    
    self.title = [NSString stringWithFormat: NSLocalizedString(@"%d / %d", @""), self.userSelectedPhotos.count, self.product.quantityToFulfillOrder];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", @"") style:UIBarButtonItemStylePlain target:self action:@selector(onBackButtonTapped)];
    
    if (self.view.frame.size.width < self.view.frame.size.height){
        self.containerView.transform = CGAffineTransformMakeTranslation(-self.containerView.frame.size.width/4, 0);
        self.containerView.transform = CGAffineTransformScale(self.containerView.transform, 0.5, 0.5);
    }
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [UIView animateWithDuration:0.5 delay:0.2 options:0 animations:^{
        self.containerView.transform = CGAffineTransformIdentity;
    } completion:NULL];
}

- (void)onBackButtonTapped{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator{
    self.containerView.transform = CGAffineTransformIdentity;
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
    tempPrintPhoto.asset = self.assets[index % [self.assets count]];
    self.editingPrintPhoto = self.photobookPhotos[index];
    
    UINavigationController *nav = [self.storyboard instantiateViewControllerWithIdentifier:@"CropViewNavigationController"];
    OLScrollCropViewController *cropVc = (id)nav.topViewController;
    cropVc.delegate = self;
    cropVc.aspectRatio = [self productAspectRatio];
    [tempPrintPhoto getImageWithProgress:NULL completion:^(UIImage *image){
        [cropVc setFullImage:image];
        [self presentViewController:nav animated:YES completion:NULL];
    }];
}

- (BOOL)isContainerViewAtRightEdge:(BOOL)useFrame{
    if (!useFrame){
        return (self.containerView.transform.tx <= -self.containerView.frame.size.width + self.view.frame.size.width);
    }
    else{
        return self.containerView.frame.origin.x + self.containerView.frame.size.width  <= self.view.frame.size.width;
    }
}

- (BOOL)isContainerViewAtLeftEdge:(BOOL)useFrame{
    if (!useFrame){
        return self.containerView.transform.tx >= 0;
    }
    else{
        return self.containerView.center.x - self.containerView.frame.size.width / 2 >= 0;
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

- (void)onPanGestureRecognized:(UIPanGestureRecognizer *)recognizer{
    if ([self isContainerViewAtLeftEdge:NO] && [self isContainerViewAtRightEdge:NO]){
        return;
    }
    CGPoint translation = [recognizer translationInView:self.containerView];
    BOOL draggingLeft = translation.x < 0;
    BOOL draggingRight = translation.x > 0;
    if (!(([self isContainerViewAtLeftEdge:NO] && draggingRight) || ([self isContainerViewAtRightEdge:NO] && draggingLeft))){
        CGFloat translationX = translation.x;
    
        self.containerView.transform = CGAffineTransformTranslate(self.containerView.transform, translationX, 0);
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
        [self.discardBehavior addItem:self.containerView];
        [self.discardBehavior addLinearVelocity:CGPointMake([recognizer velocityInView:self.containerView].x, 0) forItem:self.containerView];
        __weak OLPhotobookViewController *welf = self;
        [self.discardBehavior setAction:^{
            if ([welf isContainerViewAtRightEdge:YES] ){
                [welf.discardBehavior removeItem:welf.containerView];
                
                welf.containerView.transform = CGAffineTransformMakeTranslation(-welf.containerView.frame.size.width + welf.view.frame.size.width, 0);
                
                [welf.view setNeedsLayout];
                [welf.view layoutIfNeeded];
            }
            else if ([welf isContainerViewAtLeftEdge:YES] && [self.discardBehavior linearVelocityForItem:welf.containerView].x > 0){
                [welf.discardBehavior removeItem:welf.containerView];
                
                welf.containerView.transform = CGAffineTransformIdentity;
                
                [welf.view setNeedsLayout];
                [welf.view layoutIfNeeded];
            }
        }];
    }
}

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]] && [otherGestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]){
        return NO;
    }
    else if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]] && [otherGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]){
        CGPoint translation = [(UIPanGestureRecognizer *)gestureRecognizer translationInView:self.containerView];
        BOOL draggingLeft = translation.x < 0;
        BOOL draggingRight = translation.x > 0;
        if (([self isContainerViewAtRightEdge:NO] && draggingLeft) || ([self isContainerViewAtLeftEdge:NO] && draggingRight)){
            gestureRecognizer.enabled = NO;
            gestureRecognizer.enabled = YES;
            return YES;
        }
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
        self.leftPageLabel.text = [NSString stringWithFormat:@"%ld", (long)vc1.pageIndex+1];
        self.rightPageLabel.text = [NSString stringWithFormat:@"%ld", (long)vc2.pageIndex+1];
        
        [UIView animateWithDuration:0.2 animations:^{
            if ([(OLPhotobookPageContentViewController *)[previousViewControllers firstObject] pageIndex] < vc1.pageIndex){
                self.containerView.transform = CGAffineTransformIdentity;
            }
            else{
                self.containerView.transform = CGAffineTransformMakeTranslation(-self.containerView.frame.size.width + self.view.frame.size.width, 0);
            }
        }];
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
