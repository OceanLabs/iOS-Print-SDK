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

#import "OLButtonCollectionViewCell.h"
#import "UIView+RoundRect.h"

@interface OLButtonCollectionViewCell ()

@property (strong, nonatomic) UIView *borderView;

@end

@implementation OLButtonCollectionViewCell

- (void)initialize{
    self.backgroundColor = [UIColor clearColor];
    
    UIButton *button = [[UIButton alloc] init];
    [button addTarget:self action:@selector(onButtonTouchUpInside) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:button];
    
    button.translatesAutoresizingMaskIntoConstraints = NO;
    NSDictionary *views = NSDictionaryOfVariableBindings(button);
    NSMutableArray *con = [[NSMutableArray alloc] init];
    
    NSArray *visuals = @[@"H:|-0-[button]-0-|",
                         @"V:|-0-[button]-0-|"];
    
    
    for (NSString *visual in visuals) {
        [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
    }
    
    [button.superview addConstraints:con];
}

- (void)setSelected:(BOOL)selected{
    [super setSelected:selected];
    
    if (self.borderView || self.circleSelectionStyle){
        [self.borderView removeFromSuperview];
        
        if (self.circleSelectionStyle){
            [self setNeedsDisplay];
            return;
        }
    }
    
    if (!self.colorForSelection){
        return;
    }
    
    self.borderView = [[UIView alloc] init];
    self.borderView.userInteractionEnabled = NO;
    [self.borderView makeRoundRectWithRadius:2];
    [self addSubview:self.borderView];
    [self sendSubviewToBack:self.borderView];
    
    UIView *view = self.borderView;
    view.translatesAutoresizingMaskIntoConstraints = NO;
    NSDictionary *views = NSDictionaryOfVariableBindings(view);
    NSMutableArray *con = [[NSMutableArray alloc] init];
    
    NSArray *visuals = @[@"H:|-0-[view]-0-|",
                self.extendedSelectionBox ? @"V:|-(-10)-[view]-(-5)-|" : @"V:|-(-5)-[view]-(-5)-|"];
    
    
    for (NSString *visual in visuals) {
        [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
    }
    
    [view.superview addConstraints:con];
    
    if (selected){
        self.borderView.layer.borderWidth = 1.5;
        self.borderView.layer.borderColor = self.colorForSelection.CGColor;
    }
    else{
        self.borderView.layer.borderWidth = 0;
    }
}

- (void)onButtonTouchUpInside{
    self.selected = !self.selected;
    [self setNeedsDisplay];
    
    UIView *view = self.superview;
    while (view && ![view isKindOfClass:[UICollectionView class]]){
        view = view.superview;
    }
    
    [[(UICollectionView *)view delegate] collectionView:(UICollectionView *)view didSelectItemAtIndexPath:[(UICollectionView *)view indexPathForCell:self]];
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

- (void)drawRect:(CGRect)rect{
    if (self.circleSelectionStyle && self.isSelected){
        CGFloat thickness = 1.5;
        CGFloat diameter = MIN(rect.size.height, rect.size.width) - thickness;
        
        UIBezierPath* ovalPath = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(rect.size.width/2.0 - diameter/2.0, thickness/2.0, diameter, diameter)];
        [[UIColor blackColor] setStroke];
        ovalPath.lineWidth = thickness;
        [ovalPath stroke];
    }
}

@end
