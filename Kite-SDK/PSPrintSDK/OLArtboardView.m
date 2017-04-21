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
#import "OLArtboardView.h"
#import "UIView+AutoLayoutHelper.h"
#import "OLAsset+Private.h"

@interface OLArtboardView () <UIGestureRecognizerDelegate>
@property (strong, nonatomic) UIView *draggingView;
@property (weak, nonatomic) OLArtboardAssetView *sourceAssetView;
@property (weak, nonatomic) OLArtboardAssetView *targetAssetView;
@property (assign, nonatomic) CGRect sourceAssetViewRect;
@property (assign, nonatomic) NSUInteger sourceAssetIndex;
@end

@implementation OLArtboardView

- (void)setImage:(UIImage *)image{
    self.assetViews.firstObject.image = image;
}

-(NSMutableArray *) assetViews{
    if (!_assetViews){
        _assetViews = [[NSMutableArray alloc] init];
    }
    
    if (_assetViews.count == 0){
        [self addAssetViewWithRelativeFrame:CGRectMake(0, 0, 1, 1) index:0];
    }
    
    return _assetViews;
}

- (void)setTargetAssetView:(OLArtboardAssetView *)targetAssetView{
    if (_targetAssetView && _targetAssetView != targetAssetView){
        _targetAssetView.targeted = NO;
    }
    _targetAssetView = targetAssetView;
}

- (void)setSourceAssetView:(OLArtboardAssetView *)sourceAssetView{
    _sourceAssetView = sourceAssetView;
    self.sourceAssetViewRect = [[self.delegate viewToAddDraggingAsset] convertRect:sourceAssetView.frame fromView:sourceAssetView.superview];
    self.sourceAssetIndex = sourceAssetView.index;
}

- (instancetype)init{
    if (self = [super init]){
        self.backgroundColor = [UIColor whiteColor];
        self.translatesAutoresizingMaskIntoConstraints = NO;
    }
    
    return self;
}

- (void)layoutSubviews{
    for (OLArtboardAssetView *view in self.assetViews){
        view.frame = CGRectMake(view.relativeFrame.origin.x * self.frame.size.width, view.relativeFrame.origin.y * self.frame.size.height, view.relativeFrame.size.width * self.frame.size.width, view.relativeFrame.size.height * self.frame.size.height);
    }
}

- (void)addAssetViewWithRelativeFrame:(CGRect)frame index:(NSUInteger)index{
    OLArtboardAssetView *view = [[OLArtboardAssetView alloc] init];
    view.contentMode = UIViewContentModeScaleAspectFill;
    view.clipsToBounds = YES;
    [view setGesturesEnabled:NO];
    [self addSubview:view];
    [_assetViews addObject:view];
    
    view.index = index;
    view.relativeFrame = frame;
    
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGesture:)];
    [view addGestureRecognizer:longPressGesture];
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    panGesture.delegate = self;
    [view addGestureRecognizer:panGesture];
}

- (void)pickUpView:(OLArtboardAssetView *)assetView{
    self.sourceAssetView = assetView;
    self.draggingView = [[UIView alloc] init];
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:assetView.imageView.image];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.clipsToBounds = YES;
    UIView *viewToAddDraggingAsset = [self.delegate viewToAddDraggingAsset];
    if (!viewToAddDraggingAsset){
        return;
    }
    
    [self.draggingView addSubview:imageView];
    [viewToAddDraggingAsset addSubview:self.draggingView];
    self.draggingView.frame = [self convertRect:assetView.frame toView:viewToAddDraggingAsset];
    imageView.frame = CGRectMake(0, 0, self.draggingView.frame.size.width, self.draggingView.frame.size.height);
    
    [UIView animateWithDuration:0.15 animations:^{
        self.draggingView.transform = CGAffineTransformMakeScale(1.1, 1.1);
        self.draggingView.layer.shadowRadius = 10;
        self.draggingView.layer.shadowOpacity = 0.5;
    } completion:^(BOOL finished){
        assetView.image = nil;
    }];
    
}

- (void)dropView:(UIView *)viewDropped onView:(OLArtboardAssetView *)targetView{
    UIImageView *swappingView;
    if (targetView != self.sourceAssetView){
        swappingView = [[UIImageView alloc] initWithImage:targetView.imageView.image];
        swappingView.contentMode = [[OLAsset userSelectedAssets][targetView.index] isKindOfClass:[OLPlaceholderAsset class]] ? UIViewContentModeCenter : UIViewContentModeScaleAspectFill;
        swappingView.clipsToBounds = YES;
        UIView *viewToAddDraggingAsset = [self.delegate viewToAddDraggingAsset];
        [viewToAddDraggingAsset insertSubview:swappingView belowSubview:self.draggingView];
        swappingView.frame = [viewToAddDraggingAsset convertRect:targetView.frame fromView:targetView.superview];
    }
    
    [UIView animateWithDuration:0.25 animations:^{
        self.draggingView.transform = CGAffineTransformIdentity;
        self.draggingView.layer.shadowRadius = 0;
        self.draggingView.layer.shadowOpacity = 0.0;
        self.draggingView.frame = [[self.delegate viewToAddDraggingAsset] convertRect:targetView.frame fromView:targetView.superview];
        
        swappingView.frame = self.sourceAssetViewRect;
    } completion:^(BOOL finished){
        if (self.sourceAssetIndex == self.sourceAssetView.index){
            self.sourceAssetView.image = swappingView.image;
            self.sourceAssetView.imageView.contentMode = [[OLAsset userSelectedAssets][targetView.index] isKindOfClass:[OLPlaceholderAsset class]] ? UIViewContentModeCenter : UIViewContentModeScaleAspectFill;
        }
        if (!self.targetAssetView){
            self.targetAssetView = self.sourceAssetView;
        }
        self.targetAssetView.image = [self.draggingView.subviews.firstObject image];
        self.targetAssetView.imageView.contentMode = [[OLAsset userSelectedAssets][self.sourceAssetIndex] isKindOfClass:[OLPlaceholderAsset class]] ? UIViewContentModeCenter : UIViewContentModeScaleAspectFill;
        self.targetAssetView = nil;
        
        [[OLAsset userSelectedAssets] exchangeObjectAtIndex:self.sourceAssetIndex withObjectAtIndex:targetView.index];
        
        [self.draggingView removeFromSuperview];
        [swappingView removeFromSuperview];
    }];
}

- (void)handleLongPressGesture:(UILongPressGestureRecognizer *)sender{
    if (sender.state == UIGestureRecognizerStateBegan){
        OLArtboardAssetView *assetView = (OLArtboardAssetView *)sender.view;
        assetView.dragging = YES;
        [self pickUpView:assetView];
    }
    else if(sender.state == UIGestureRecognizerStateEnded){
        OLArtboardAssetView *target = self.targetAssetView;
        if (!target){
            target = self.sourceAssetView;
        }
        [self dropView:self.draggingView onView:target];
    }
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)sender{
    if(sender.state == UIGestureRecognizerStateChanged){
        UIView *viewToAddDraggingAsset = [self.delegate viewToAddDraggingAsset];
        if (!viewToAddDraggingAsset){
            return;
        }
        CGPoint translation = [sender translationInView:viewToAddDraggingAsset];
        self.draggingView.transform = CGAffineTransformScale(CGAffineTransformMakeTranslation(translation.x, translation.y), 1.1, 1.1);
        
        OLArtboardAssetView *targetView = [self.delegate assetViewAtPoint:CGPointMake(self.draggingView.frame.origin.x + self.draggingView.frame.size.width/2.0, self.draggingView.frame.origin.y + self.draggingView.frame.size.height/2.0)];
        if (!targetView.targeted){
            [targetView setTargeted:YES];
            self.targetAssetView = targetView;
        }
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(nonnull UIGestureRecognizer *)otherGestureRecognizer{
    return otherGestureRecognizer.view == gestureRecognizer.view && [otherGestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]];
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer{
    OLArtboardAssetView *assetView = (OLArtboardAssetView *)gestureRecognizer.view;
    return assetView.dragging;
}

@end
