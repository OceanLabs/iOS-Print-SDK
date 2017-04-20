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
#import "OLAsset.h"

@interface OLArtboardView () <UIGestureRecognizerDelegate>
@property (strong, nonatomic) UIView *pickedUpView;
@property (weak, nonatomic) OLArtboardAssetView *sourceAssetView;
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
    self.pickedUpView = [[UIView alloc] init];
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:assetView.imageView.image];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.clipsToBounds = YES;
    UIView *viewToAddPickedUpAsset = [self.delegate viewToAddPickedUpAsset];
    if (!viewToAddPickedUpAsset){
        return;
    }
    
    [self.pickedUpView addSubview:imageView];
    [viewToAddPickedUpAsset addSubview:self.pickedUpView];
    self.pickedUpView.frame = [self convertRect:assetView.frame toView:viewToAddPickedUpAsset];
    imageView.frame = CGRectMake(0, 0, self.pickedUpView.frame.size.width, self.pickedUpView.frame.size.height);
    
    [UIView animateWithDuration:0.15 animations:^{
        self.pickedUpView.transform = CGAffineTransformMakeScale(1.1, 1.1);
        self.pickedUpView.layer.shadowRadius = 10;
        self.pickedUpView.layer.shadowOpacity = 0.5;
    }];
    
}

- (void)dropView:(UIView *)viewDropped onView:(OLArtboardAssetView *)view{
    [UIView animateWithDuration:0.15 animations:^{
        self.pickedUpView.transform = CGAffineTransformIdentity;
        self.pickedUpView.layer.shadowRadius = 0;
        self.pickedUpView.layer.shadowOpacity = 0.0;
        self.pickedUpView.frame = [self convertRect:view.frame toView:[self.delegate viewToAddPickedUpAsset]];
    } completion:^(BOOL finished){
        [self.pickedUpView removeFromSuperview];
    }];
}

- (void)handleLongPressGesture:(UILongPressGestureRecognizer *)sender{
    if (sender.state == UIGestureRecognizerStateBegan){
        OLArtboardAssetView *assetView = (OLArtboardAssetView *)sender.view;
        assetView.pickedUp = YES;
        [self pickUpView:assetView];
    }
    else if(sender.state == UIGestureRecognizerStateEnded){
        [self dropView:self.pickedUpView onView:self.sourceAssetView];
    }
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)sender{
    if(sender.state == UIGestureRecognizerStateChanged){
        UIView *viewToAddPickedUpAsset = [self.delegate viewToAddPickedUpAsset];
        if (!viewToAddPickedUpAsset){
            return;
        }
        CGPoint translation = [sender translationInView:viewToAddPickedUpAsset];
        self.pickedUpView.transform = CGAffineTransformScale(CGAffineTransformMakeTranslation(translation.x, translation.y), 1.1, 1.1);
        
        OLArtboardAssetView *targetView = [self.delegate assetViewAtPoint:CGPointMake(self.pickedUpView.frame.origin.x + self.pickedUpView.frame.size.width/2.0, self.pickedUpView.frame.origin.y + self.pickedUpView.frame.size.height/2.0)];
        if (targetView){
            [targetView addTargetOverlay];
            NSLog(@"%@", targetView);
        }
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(nonnull UIGestureRecognizer *)otherGestureRecognizer{
    return otherGestureRecognizer.view == gestureRecognizer.view && [otherGestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]];
}

@end
