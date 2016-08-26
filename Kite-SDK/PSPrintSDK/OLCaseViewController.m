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

#import "OLImageDownloader.h"
#import "OLCaseViewController.h"
#import "OLRemoteImageCropper.h"
#import "UIImage+ImageNamedInKiteBundle.h"
#import "UIImage+OLUtils.h"
#import "OLUserSession.h"
#import "OLAsset+Private.h"

@interface OLSingleImageProductReviewViewController (Private)

-(void) doCheckout;
@property (weak, nonatomic) IBOutlet UIView *printContainerView;

@end

@interface OLCaseViewController ()

@property (assign, nonatomic) BOOL downloadedMask;
@property (strong, nonatomic) IBOutlet UIVisualEffectView *caseVisualEffectView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *maskActivityIndicator;
@property (strong, nonatomic) UIImage *maskImage;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *centerYCon;
@property (weak, nonatomic) IBOutlet UIImageView *deviceView;
@property (weak, nonatomic) IBOutlet UIImageView *highlightsView;
@property (strong, nonatomic) NSOperation *downloadImagesOperation;

@end

@implementation OLCaseViewController

- (CGFloat)aspectRatio{
    return self.product.productTemplate.sizePx.height / self.product.productTemplate.sizePx.width;
}

-(void)viewDidLoad{
    [super viewDidLoad];
    
    self.downloadImagesOperation = [NSBlockOperation blockOperationWithBlock:^{}];
    
    
    if (self.product.productTemplate.maskImageURL){
        NSOperation *op1 = [NSBlockOperation blockOperationWithBlock:^{}];
        [self.downloadImagesOperation addDependency:op1];
        
        [[OLImageDownloader sharedInstance] downloadImageAtURL:self.product.productTemplate.maskImageURL withCompletionHandler:^(UIImage *image, NSError *error){
            [[NSOperationQueue mainQueue] addOperation:op1];
        }];
    }
    if (self.product.productTemplate.productHighlightsImageURL){
        NSOperation *op2 = [NSBlockOperation blockOperationWithBlock:^{}];
        [self.downloadImagesOperation addDependency:op2];
        
        [[OLImageDownloader sharedInstance] downloadImageAtURL:self.product.productTemplate.productHighlightsImageURL withCompletionHandler:^(UIImage *image, NSError *error){
            [[NSOperationQueue mainQueue] addOperation:op2];
        }];
    }
    if (self.product.productTemplate.productBackgroundImageURL){
        NSOperation *op3 = [NSBlockOperation blockOperationWithBlock:^{}];
        [self.downloadImagesOperation addDependency:op3];
        
        [[OLImageDownloader sharedInstance] downloadImageAtURL:self.product.productTemplate.productBackgroundImageURL withCompletionHandler:^(UIImage *image, NSError *error){
            [[NSOperationQueue mainQueue] addOperation:op3];
        }];
    }
    
    [[NSOperationQueue mainQueue] addOperation:self.downloadImagesOperation];
    
    self.downloadedMask = NO;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    self.centerYCon.constant = (88.0 - ([[UIApplication sharedApplication] statusBarFrame].size.height + self.navigationController.navigationBar.frame.size.height + 20.0))/2.0;
    
    if (self.downloadedMask){
        return;
    }
    
    UIImage *tempMask = [UIImage imageNamedInKiteBundle:@"dummy mask"];
    [self.printContainerView removeConstraint:self.aspectRatioConstraint];
    NSLayoutConstraint *con = [NSLayoutConstraint constraintWithItem:self.printContainerView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.printContainerView attribute:NSLayoutAttributeWidth multiplier:tempMask.size.height / tempMask.size.width constant:0];
    [self.printContainerView addConstraints:@[con]];
    self.aspectRatioConstraint = con;
    
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
    
    [self maskWithImage:tempMask targetView:self.cropView];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}

- (UIColor *)containerBackgroundColor{
    return [UIColor clearColor];
}

- (void)orderViews{
    [self.view bringSubviewToFront:self.deviceView];
    [self.view bringSubviewToFront:self.printContainerView];
    [self.view bringSubviewToFront:self.cropView];
    [self.view bringSubviewToFront:self.highlightsView];
    [self.view bringSubviewToFront:self.editingTools.drawerView];
    [self.view bringSubviewToFront:self.editingTools];
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
        [self maskWithImage:self.maskImage targetView:self.cropView];
    }completion:^(id <UIViewControllerTransitionCoordinatorContext> context){}];
}

- (void)applyDownloadedMask {
    if (self.downloadedMask){
        return;
    }
    [[OLImageDownloader sharedInstance] downloadImageAtURL:self.product.productTemplate.maskImageURL priority:1 progress:NULL withCompletionHandler:^(UIImage *image, NSError *error){
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        if (error) {
            UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Oops", @"")  message:NSLocalizedString(@"Failed to download phone case mask. Please check your internet connectivity and try again", @"")  delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"") otherButtonTitles:@"Retry", nil];
            av.tag = 99;
            [av show];
        } else {
            [self.printContainerView removeConstraint:self.aspectRatioConstraint];
            NSLayoutConstraint *con = [NSLayoutConstraint constraintWithItem:self.printContainerView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.printContainerView attribute:NSLayoutAttributeWidth multiplier:self.product.productTemplate.sizePx.height / self.product.productTemplate.sizePx.width constant:0];
            [self.printContainerView addConstraints:@[con]];
            
            [self.view setNeedsLayout];
            [self.view layoutIfNeeded];
            
            self.maskImage = [image shrinkToSize:[UIScreen mainScreen].bounds.size forScreenScale:[OLUserSession currentSession].screenScale];
            [self maskWithImage:self.maskImage targetView:self.cropView];
            
            [[OLImageDownloader sharedInstance] downloadImageAtURL:self.product.productTemplate.productBackgroundImageURL priority:1.0 progress:NULL withCompletionHandler:^(UIImage *image, NSError *error){
                self.deviceView.image = [image shrinkToSize:[UIScreen mainScreen].bounds.size forScreenScale:[OLUserSession currentSession].screenScale];
            }];
            [[OLImageDownloader sharedInstance] downloadImageAtURL:self.product.productTemplate.productHighlightsImageURL priority:0.9 progress:NULL withCompletionHandler:^(UIImage *image, NSError *error){
                self.highlightsView.image = [image shrinkToSize:[UIScreen mainScreen].bounds.size forScreenScale:[OLUserSession currentSession].screenScale];
             }];
            
            self.caseVisualEffectView.hidden = YES;
            self.downloadedMask = YES;
            [self.maskActivityIndicator removeFromSuperview];
            self.maskActivityIndicator = nil;
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
    if (!self.cropView.image || !self.downloadedMask) {
        return;
    }
    [super doCheckout];
}

@end
