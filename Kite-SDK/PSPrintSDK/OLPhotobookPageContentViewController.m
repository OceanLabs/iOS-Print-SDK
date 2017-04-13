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

#import "OLArtboardTemplate.h"
#import "OLAsset+Private.h"
#import "OLImageEditViewController.h"
#import "OLPhotobookPageContentViewController.h"
#import "OLProduct.h"
#import "OLRemoteImageView.h"
#import "OLUserSession.h"
#import "UIImage+ImageNamedInKiteBundle.h"
#import "UIImageView+FadeIn.h"

@interface OLPhotobookPageContentViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *pageShadowRight;
@property (weak, nonatomic) IBOutlet UIImageView *pageShadowLeft;

@property (assign, nonatomic) BOOL left;

@end

@implementation OLPhotobookPageContentViewController

- (void)viewDidLoad{
    [super viewDidLoad];
        
    [self setupImageViews];
}

- (void)setupImageViews{
    OLArtboardTemplate *layout = self.product.productTemplate.productRepresentation.pages[self.pageIndex];
    CGRect imageViewPosition = [layout.positions.firstObject CGRectValue];
    
    [self.artboardView.superview addConstraint:[NSLayoutConstraint constraintWithItem:self.artboardView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.artboardView.superview attribute:NSLayoutAttributeHeight multiplier:imageViewPosition.size.height constant:0]];
    [self.artboardView.superview addConstraint:[NSLayoutConstraint constraintWithItem:self.artboardView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.artboardView.superview attribute:NSLayoutAttributeWidth multiplier:imageViewPosition.size.width constant:0]];
    
    [self loadImageWithCompletionHandler:NULL];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self setPage:(self.pageIndex % 2 == 0)];
}

//- (void)setPageIndex:(NSInteger)pageIndex{
//    _pageIndex = pageIndex;
//    
//    [self setPage:(pageIndex % 2 == 0)];
//}

- (void)setPage:(BOOL)left{
    self.left = left;
    if (left){
        self.pageShadowLeft.hidden = NO;
        self.pageShadowRight.hidden = YES;
        self.pageShadowLeft2.hidden = YES;
        self.pageShadowRight2.hidden = YES;

    }
    else{
        self.pageShadowLeft.hidden = YES;
        self.pageShadowRight.hidden = NO;
        self.pageShadowLeft2.hidden = YES;
        self.pageShadowRight2.hidden = YES;
    }
}

- (NSInteger)imageIndexForPoint:(CGPoint)p{
    return self.pageIndex;
}

- (void)unhighlightImageAtIndex:(NSInteger)index{
    UIView *selectedView = self.artboardView.assetViews.firstObject;
    
    selectedView.layer.borderColor = [UIColor clearColor].CGColor;
    selectedView.layer.borderWidth = 0;
}

- (void)highlightImageAtIndex:(NSInteger)index{
    UIView *selectedView = self.artboardView.assetViews.firstObject;
    
    selectedView.layer.borderColor = self.view.tintColor.CGColor;
    selectedView.layer.borderWidth = 3.0;
}

- (void)clearImage{
    self.pageShadowLeft2.hidden = YES;
    self.pageShadowRight2.hidden = YES;
    self.artboardView.assetViews.firstObject.image = nil;
}

- (void)loadImageWithCompletionHandler:(void(^)(void))handler{
    NSInteger imageIndex = self.pageIndex + 1;
    self.artboardView.assetViews.firstObject.image = nil;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.artboardView.assetViews.firstObject.index = imageIndex;
        [self.artboardView.assetViews.firstObject loadImageWithCompletionHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.left){
                    self.pageShadowLeft2.hidden = NO;
                }
                else{
                    self.pageShadowRight2.hidden = NO;
                }
                if (handler){
                    handler();
                }
            });
        }];
    });
}

@end
