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


#import "OLPhotoTextField.h"
#import "UIImage+ImageNamedInKiteBundle.h"

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
    
    UIButton *moveButton = [[UIButton alloc] init];
    moveButton.tag = 20;
    [moveButton setImage:[UIImage imageNamedInKiteBundle:@"circle-move"] forState:UIControlStateNormal];
    [self addSubview:moveButton];
    [moveButton addTarget:self action:@selector(onButtonMoveTouched:) forControlEvents:UIControlEventTouchDown];
}

- (void)onButtonMoveTouched:(UIButton *)sender{
    
}

- (void)layoutCornerButtons{
    [self viewWithTag:10].frame = CGRectMake(self.frame.size.width - 30, 0, 30, 30);
    [self viewWithTag:20].frame = CGRectMake(self.frame.size.width - 30, self.frame.size.height - 30, 30, 30);
}

- (void)updateSize{
    CGPoint center = self.center;
    [self sizeToFit];
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, MAX(self.frame.size.width + self.margins*2, 100), MAX(self.frame.size.height, 40));
    self.center = center;
    [self setNeedsDisplay];
}

- (void)onButtonXTapped:(UIButton *)sender{
    [sender.superview removeFromSuperview];
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

-(void)drawRect:(CGRect)rect
{
    //// Rectangle Drawing
    UIBezierPath* rectanglePath = [UIBezierPath bezierPathWithRect: CGRectMake(15, 15, self.frame.size.width-30, self.frame.size.height-30)];
    [[UIColor blackColor] setStroke];
    rectanglePath.lineWidth = 2;
    [rectanglePath stroke];
    
    [self layoutCornerButtons];
}

@end
