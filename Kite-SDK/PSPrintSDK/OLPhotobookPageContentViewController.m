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

#import "OLPhotobookPageContentViewController.h"
#import "OLPrintPhoto.h"
#import "OLScrollCropViewController.h"
#import "OLProduct.h"
#import "OLRemoteImageView.h"
#import "UIImage+ImageNamedInKiteBundle.h"

@interface OLPhotobookPageContentViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *pageBackground;
@property (weak, nonatomic) IBOutlet UIImageView *pageShadowRight;
@property (weak, nonatomic) IBOutlet UIImageView *pageShadowLeft;

@property (assign, nonatomic) BOOL left;

@end

@implementation OLPhotobookPageContentViewController

- (void)viewDidLoad{
    [super viewDidLoad];
        
    [self.imageView.superview addConstraint:[NSLayoutConstraint constraintWithItem:self.imageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.imageView.superview attribute:NSLayoutAttributeHeight multiplier:1-self.product.productTemplate.imageBorder.top*2 constant:0]];
    [self.imageView.superview addConstraint:[NSLayoutConstraint constraintWithItem:self.imageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.imageView.superview attribute:NSLayoutAttributeWidth multiplier:1-self.product.productTemplate.imageBorder.left*2 constant:0]];
    
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
        self.pageBackground.image = [UIImage imageNamedInKiteBundle:@"page-left"];
        self.pageShadowLeft.hidden = NO;
        self.pageShadowRight.hidden = YES;
        self.pageShadowLeft2.hidden = YES;
        self.pageShadowRight2.hidden = YES;

    }
    else{
        self.pageBackground.image = [UIImage imageNamedInKiteBundle:@"page-right"];
        self.pageShadowLeft.hidden = YES;
        self.pageShadowRight.hidden = NO;
        self.pageShadowLeft2.hidden = YES;
        self.pageShadowRight2.hidden = YES;
    }
}

- (NSInteger)imageIndexForPoint:(CGPoint)p{
    return self.pageIndex; //only one for now
}

- (void)unhighlightImageAtIndex:(NSInteger)index{
    UIView *selectedView = self.imageView; //only one for now
    
    selectedView.layer.borderColor = [UIColor clearColor].CGColor;
    selectedView.layer.borderWidth = 0;
}

- (void)highlightImageAtIndex:(NSInteger)index{
    UIView *selectedView = self.imageView; //only one for now
    
    selectedView.layer.borderColor = self.view.tintColor.CGColor;
    selectedView.layer.borderWidth = 3.0;
}

- (void)clearImage{
    self.pageShadowLeft2.hidden = YES;
    self.pageShadowRight2.hidden = YES;
    self.imageView.image = nil;
}

- (void)loadImageWithCompletionHandler:(void(^)(void))handler{
    if (self.pageIndex >= self.userSelectedPhotos.count){
        return;
    }
    OLPrintPhoto *printPhoto = [self.userSelectedPhotos objectAtIndex:self.pageIndex];
    if (printPhoto != (id)[NSNull null]){
        self.imageView.image = nil;
        dispatch_async(dispatch_get_main_queue(), ^{
            NSInteger blockIndex = self.pageIndex;
            
            [printPhoto setImageSize:self.imageView.frame.size cropped:YES progress:^(float progress){
                [self.imageView setProgress:progress];
            }completionHandler:^(UIImage *image){
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (blockIndex == self.pageIndex){
                        self.imageView.image = image;
                        
                        if (self.left){
                            self.pageShadowLeft2.hidden = NO;
                        }
                        else{
                            self.pageShadowRight2.hidden = NO;
                        }
                    }
                    if (handler){
                        handler();
                    }
                });
            }];
        });
    }
    else{
        self.pageShadowLeft2.hidden = YES;
        self.pageShadowRight2.hidden = YES;
        self.imageView.image = nil;
        if (handler){
            handler();
        }
        
    }
}

@end
