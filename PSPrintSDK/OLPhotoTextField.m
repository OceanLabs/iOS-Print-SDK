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


#import "OLPhotoTextField.h"
#import "UIImage+ImageNamedInKiteBundle.h"

@interface OLPhotoTextField()
@property (assign, nonatomic) BOOL chromeHidden;
@property (strong, nonatomic) CAShapeLayer *borderLayer;
@end

@implementation OLPhotoTextField

- (CGRect)textRectForBounds:(CGRect)bounds {
    return CGRectMake(bounds.origin.x + 15, bounds.origin.y + 15,
                      bounds.size.width - 30, bounds.size.height - 30);
}
- (CGRect)editingRectForBounds:(CGRect)bounds {
    return [self textRectForBounds:bounds];
}

- (void)initialize{
    self.textAlignment = NSTextAlignmentCenter;
    self.clipsToBounds = NO;
    self.textColor = [UIColor whiteColor];
    self.tintColor = [UIColor whiteColor];
    [self setFont:[UIFont systemFontOfSize:30]];
    
    
    UIButton *xButton = [[UIButton alloc] init];
    xButton.tag = 10;
    [xButton setImage:[UIImage imageNamedInKiteBundle:@"circle-x"] forState:UIControlStateNormal];
    [self addSubview:xButton];
    [xButton addTarget:self action:@selector(onButtonXTapped:) forControlEvents:UIControlEventTouchUpInside];
    xButton.alpha = 0;
    
    UIButton *resizeButton = [[UIButton alloc] init];
    resizeButton.tag = 20;
    [resizeButton setImage:[UIImage imageNamedInKiteBundle:@"circle-resize"] forState:UIControlStateNormal];
    [self addSubview:resizeButton];
    [resizeButton addTarget:self action:@selector(onButtonResizeTouched:) forControlEvents:UIControlEventTouchDown];
    [resizeButton addTarget:self action:@selector(onButtonResizeLetGo:) forControlEvents:UIControlEventTouchUpInside];
    [resizeButton addTarget:self action:@selector(onButtonResizeLetGo:) forControlEvents:UIControlEventTouchUpOutside];
    resizeButton.alpha = 0;
    
    UIButton *rotateButton = [[UIButton alloc] init];
    rotateButton.tag = 30;
    [rotateButton setImage:[UIImage imageNamedInKiteBundle:@"circle-rotate"] forState:UIControlStateNormal];
    [self addSubview:rotateButton];
    [rotateButton addTarget:self action:@selector(onButtonRotateTouched:) forControlEvents:UIControlEventTouchDown];
    [rotateButton addTarget:self action:@selector(onButtonRotateLetGo:) forControlEvents:UIControlEventTouchUpInside];
    [rotateButton addTarget:self action:@selector(onButtonRotateLetGo:) forControlEvents:UIControlEventTouchUpOutside];
    rotateButton.alpha = 0;
    
    self.chromeHidden = YES;
}

- (void)onButtonResizeTouched:(UIButton *)sender{
    if ([self.photoTextFieldDelegate respondsToSelector:@selector(photoTextFieldDidSendActionTouchDownForResize:)]){
        [self.photoTextFieldDelegate photoTextFieldDidSendActionTouchDownForResize:self];
    }
}

- (void)onButtonResizeLetGo:(UIButton *)sender{
    if ([self.photoTextFieldDelegate respondsToSelector:@selector(photoTextFieldDidSendActionTouchDownForResize:)]){
        [self.photoTextFieldDelegate photoTextFieldDidSendActionTouchUpForResize:self];
    }
}

- (void)onButtonXTapped:(UIButton *)sender{
    if ([self.photoTextFieldDelegate respondsToSelector:@selector(photoTextFieldDidSendActionTouchUpInsideForX:)]){
        [self.photoTextFieldDelegate photoTextFieldDidSendActionTouchUpInsideForX:self];
    }
}

- (void)onButtonRotateTouched:(UIButton *)sender{
    if ([self.photoTextFieldDelegate respondsToSelector:@selector(photoTextFieldDidSendActionTouchDownForRotate:)]){
        [self.photoTextFieldDelegate photoTextFieldDidSendActionTouchDownForRotate:self];
    }
}

- (void)onButtonRotateLetGo:(UIButton *)sender{
    if ([self.photoTextFieldDelegate respondsToSelector:@selector(photoTextFieldDidSendActionTouchDownForRotate:)]){
        [self.photoTextFieldDelegate photoTextFieldDidSendActionTouchUpForRotate:self];
    }
}

- (id)initWithCoder:(NSCoder *)aCoder{
    if(self = [super initWithCoder:aCoder]){
        [self initialize];
    }
    return self;
}

- (id)initWithFrame:(CGRect)rect{
    if(self = [super initWithFrame:rect]){
        [self initialize];
    }
    return self;
}

- (void)layoutCornerButtons{
    [self viewWithTag:10].frame = CGRectMake(0, 0, 30, 30);
    [self viewWithTag:20].frame = CGRectMake(self.frame.size.width - 30, self.frame.size.height - 30, 30, 30);
    [self viewWithTag:30].frame = CGRectMake(0, self.frame.size.height - 30, 30, 30);
}

- (void)hideButtons{
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"strokeColor"];
    animation.duration = 0.15;
    animation.fromValue = (__bridge id _Nullable)([UIColor blackColor].CGColor);
    animation.toValue = (__bridge id _Nullable)([UIColor clearColor].CGColor);
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    self.borderLayer.strokeColor = [UIColor clearColor].CGColor;
    [self.borderLayer addAnimation:animation forKey:@"fadeOut"];
    [UIView animateWithDuration:0.15 animations:^{
        [self viewWithTag:10].alpha = 0;
        [self viewWithTag:20].alpha = 0;
        [self viewWithTag:30].alpha = 0;
    }completion:^(BOOL finished){
        self.chromeHidden = YES;
    }];
}

- (void)showButtons{
    self.chromeHidden = NO;
    [self setNeedsDisplay];
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"strokeColor"];
    animation.duration = 0.15;
    animation.fromValue = (__bridge id _Nullable)([UIColor clearColor].CGColor);
    animation.toValue = (__bridge id _Nullable)([UIColor blackColor].CGColor);
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    self.borderLayer.strokeColor = [UIColor blackColor].CGColor;
    [self.borderLayer addAnimation:animation forKey:@"fadeIn"];
    [UIView animateWithDuration:0.15 animations:^{
        [self viewWithTag:10].alpha = 1;
        [self viewWithTag:20].alpha = 1;
        [self viewWithTag:30].alpha = 1;
    }completion:NULL];
}

- (void)updateSize{
    CGFloat angle = atan2(self.transform.b, self.transform.a);
    CGAffineTransform translationOnly = CGAffineTransformIdentity;
    translationOnly.tx = self.transform.tx;
    translationOnly.ty = self.transform.ty;
    self.transform = translationOnly;
    
    CGPoint center = self.center;
    [self sizeToFit];
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, MAX(self.frame.size.width + self.margins*2, 100), MAX(self.frame.size.height, 40));
    self.center = center;
    
    self.transform = CGAffineTransformRotate(self.transform, angle);
    
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    if (self.borderLayer){
        [self.borderLayer removeFromSuperlayer];
    }
    CGFloat angle = atan2(self.transform.b, self.transform.a);
    CGAffineTransform translationOnly = CGAffineTransformIdentity;
    translationOnly.tx = self.transform.tx;
    translationOnly.ty = self.transform.ty;
    self.transform = translationOnly;
    
    UIBezierPath* rectanglePath = [UIBezierPath bezierPathWithRect: CGRectMake(15, 15, self.frame.size.width-30, self.frame.size.height-30)];
    rectanglePath.lineWidth = 1;
    
    self.borderLayer = [[CAShapeLayer alloc] init];
    self.borderLayer.path = rectanglePath.CGPath;
    self.borderLayer.strokeColor = self.chromeHidden ? [UIColor clearColor].CGColor : [UIColor blackColor].CGColor;
    self.borderLayer.lineWidth = 1;
    self.borderLayer.fillColor = [UIColor clearColor].CGColor;
    self.borderLayer.lineDashPattern = @[@4, @2];
    [self.layer insertSublayer:self.borderLayer below:[self viewWithTag:10].layer];
    
    [self layoutCornerButtons];
    
    self.transform = CGAffineTransformRotate(self.transform, angle);
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event{
    return [super hitTest:point withEvent:event];
}

@end
