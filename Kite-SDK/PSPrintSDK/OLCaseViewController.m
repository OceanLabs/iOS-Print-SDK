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

#ifdef COCOAPODS
#import <SDWebImage/SDWebImageManager.h>
#import <SDWebImage/SDWebImagePrefetcher.h>
#else
#import "SDWebImageManager.h"
#import "SDWebImagePrefetcher.h"
#endif

#import "OLCaseViewController.h"
#import "OLRemoteImageCropper.h"
#import "UIImage+ImageNamedInKiteBundle.h"

@interface OLSingleImageProductReviewViewController (Private)

@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet OLRemoteImageCropper *imageCropView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *maskAspectRatio;
-(void) doCheckout;

@end

@interface OLCaseViewController ()

@property (assign, nonatomic) BOOL downloadedMask;
@property (strong, nonatomic) UIVisualEffectView *visualEffectView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *maskActivityIndicator;
@property (strong, nonatomic) UIImage *maskImage;
@property (strong, nonatomic) OLPrintPhoto *imageDisplayed;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *centerYCon;
@property (weak, nonatomic) IBOutlet UIImageView *deviceView;
@property (weak, nonatomic) IBOutlet UIImageView *highlightsView;
@property (strong, nonatomic) NSOperation *downloadImagesOperation;

@end

@implementation OLCaseViewController

-(void)viewDidLoad{
    [super viewDidLoad];
    
    self.downloadImagesOperation = [NSBlockOperation blockOperationWithBlock:^{}];
    NSMutableArray *urls = [[NSMutableArray alloc] init];
    
    if (self.product.productTemplate.maskImageURL){
        [urls addObject:self.product.productTemplate.maskImageURL];
    }
    if (self.product.productTemplate.productHighlightsImageURL){
        [urls addObject:self.product.productTemplate.productHighlightsImageURL];
    }
    if (self.product.productTemplate.productBackgroundImageURL){
        [urls addObject:self.product.productTemplate.productBackgroundImageURL];
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[SDWebImagePrefetcher sharedImagePrefetcher] prefetchURLs:urls progress:NULL completed:^(NSUInteger numberOfCompletedURLs, NSUInteger numberOfSkippedURLs){
            [[NSOperationQueue mainQueue] addOperation:self.downloadImagesOperation];
        }];
    });
    
    self.downloadedMask = NO;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    self.centerYCon.constant = (88.0 - ([[UIApplication sharedApplication] statusBarFrame].size.height + self.navigationController.navigationBar.frame.size.height + 20.0))/2.0;
    
    if (self.downloadedMask){
        return;
    }
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0){
        if (!self.visualEffectView){
            UIVisualEffect *blurEffect;
            blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
            
            self.visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
            UIView *view = self.visualEffectView;
            [view.layer setMasksToBounds:YES];
            [self.containerView insertSubview:view belowSubview:self.maskActivityIndicator];
            
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
    }
    else{
        
    }
    
    UIImage *tempMask = [UIImage imageNamedInKiteBundle:@"dummy mask"];
    [self.containerView removeConstraint:self.maskAspectRatio];
    NSLayoutConstraint *con = [NSLayoutConstraint constraintWithItem:self.containerView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.containerView attribute:NSLayoutAttributeWidth multiplier:tempMask.size.height / tempMask.size.width constant:0];
    [self.containerView addConstraints:@[con]];
    self.maskAspectRatio = con;
    
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
    
    [self maskWithImage:tempMask targetView:self.imageCropView];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    NSBlockOperation *block = [NSBlockOperation blockOperationWithBlock:^{
        [self applyDownloadedMask];
    }];
    [block addDependency:self.downloadImagesOperation];
    [[NSOperationQueue mainQueue] addOperation:block];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context){
        self.centerYCon.constant = (88.0 - ([[UIApplication sharedApplication] statusBarFrame].size.height + self.navigationController.navigationBar.frame.size.height + 20.0))/2.0;
        [self.view layoutIfNeeded];
        [self maskWithImage:self.maskImage targetView:self.imageCropView];
    }completion:^(id <UIViewControllerTransitionCoordinatorContext> context){}];
}

- (void)applyDownloadedMask {
    if (self.downloadedMask){
        return;
    }
    [[SDWebImageManager sharedManager] downloadImageWithURL:self.product.productTemplate.maskImageURL options:SDWebImageHighPriority progress:NULL completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL){
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        if (error) {
            UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Oops", @"")  message:NSLocalizedString(@"Failed to download phone case mask. Please check your internet connectivity and try again", @"")  delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"") otherButtonTitles:@"Retry", nil];
            av.tag = 99;
            [av show];
        } else {
            [self.containerView removeConstraint:self.maskAspectRatio];
            NSLayoutConstraint *con = [NSLayoutConstraint constraintWithItem:self.containerView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.containerView attribute:NSLayoutAttributeWidth multiplier:self.product.productTemplate.sizePx.height / self.product.productTemplate.sizePx.width constant:0];
            [self.containerView addConstraints:@[con]];
            
            [self.view setNeedsLayout];
            [self.view layoutIfNeeded];
            
            self.maskImage = image;
            [self maskWithImage:self.maskImage targetView:self.imageCropView];
            
            [[SDWebImageManager sharedManager] downloadImageWithURL:self.product.productTemplate.productBackgroundImageURL options:SDWebImageHighPriority progress:NULL completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL){
                self.deviceView.image = image;
            }];
             [[SDWebImageManager sharedManager] downloadImageWithURL:self.product.productTemplate.productHighlightsImageURL options:SDWebImageHighPriority progress:NULL completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL){
                self.highlightsView.image = image;
             }];
            
            
            
            self.visualEffectView.hidden = YES;
            self.downloadedMask = YES;
            [self.maskActivityIndicator removeFromSuperview];
            self.maskActivityIndicator = nil;
            
            self.imageCropView.imageView.transform = self.imageDisplayed.edits.cropTransform;
        }
    }];
}

-(void) maskWithImage:(UIImage*) maskImage targetView:(UIView*) targetView{
    CALayer *_maskingLayer = [CALayer layer];
    CGRect f = targetView.bounds;
    UIEdgeInsets imageBleed = self.product.productTemplate.imageBleed;
    CGSize size = self.product.productTemplate.sizePx;
    
    UIEdgeInsets adjustedBleed = UIEdgeInsetsMake(f.size.height * imageBleed.top / size.height,
                                                  f.size.width * imageBleed.left / size.width,
                                                  f.size.height * imageBleed.bottom / size.height,
                                                  f.size.width * imageBleed.right / size.width);
    
    _maskingLayer.frame = CGRectMake(f.origin.x + adjustedBleed.left,
                                     f.origin.y + adjustedBleed.top,
                                     f.size.width - (adjustedBleed.left + adjustedBleed.right),
                                     f.size.height - (adjustedBleed.top + adjustedBleed.bottom));
    [_maskingLayer setContents:(id)[maskImage CGImage]];
    [targetView.layer setMask:_maskingLayer];
}

-(void) doCheckout{
    if (!self.imageCropView.image || !self.downloadedMask) {
        return;
    }
    [super doCheckout];
}

#pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 99) {
        if (buttonIndex == 0) {
            [self.navigationController popViewControllerAnimated:YES];
        } else {
            [self applyDownloadedMask];
        }
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

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8) {
        return UIInterfaceOrientationMaskAll;
    }
    else{
        return UIInterfaceOrientationMaskPortrait;
    }
}

@end
