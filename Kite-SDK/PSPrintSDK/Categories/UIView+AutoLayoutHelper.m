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

#import "UIView+AutoLayoutHelper.h"

@implementation UIView (AutoLayoutHelper)

- (void)fillSuperView{
    self.translatesAutoresizingMaskIntoConstraints = NO;
    [self leadingFromSuperview:0 relation:NSLayoutRelationEqual];
    [self trailingToSuperview:0 relation:NSLayoutRelationEqual];
    [self bottomToSuperview:0 relation:NSLayoutRelationEqual];
    [self topFromSuperview:0 relation:NSLayoutRelationEqual];
}

- (void)leadingFromSuperview:(CGFloat)constant relation:(NSLayoutRelation)relation{
    self.translatesAutoresizingMaskIntoConstraints = NO;
    [self.superview addConstraint:[NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeLeading relatedBy:relation toItem:self.superview attribute:NSLayoutAttributeLeading multiplier:1 constant:constant]];
}

- (void)trailingToSuperview:(CGFloat)constant relation:(NSLayoutRelation)relation{
    self.translatesAutoresizingMaskIntoConstraints = NO;
    [self.superview addConstraint:[NSLayoutConstraint constraintWithItem:self.superview attribute:NSLayoutAttributeTrailing relatedBy:relation toItem:self attribute:NSLayoutAttributeTrailing multiplier:1 constant:constant]];
}

- (void)bottomToSuperview:(CGFloat)constant relation:(NSLayoutRelation)relation{
    self.translatesAutoresizingMaskIntoConstraints = NO;
    [self.superview addConstraint:[NSLayoutConstraint constraintWithItem:self.superview attribute:NSLayoutAttributeBottom relatedBy:relation toItem:self attribute:NSLayoutAttributeBottom multiplier:1 constant:constant]];
}

- (void)topFromSuperview:(CGFloat)constant relation:(NSLayoutRelation)relation{
    self.translatesAutoresizingMaskIntoConstraints = NO;
    [self.superview addConstraint:[NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeTop relatedBy:relation toItem:self.superview attribute:NSLayoutAttributeTop multiplier:1 constant:constant]];
}

- (void)verticalSpacingToView:(UIView *)view constant:(CGFloat)constant relation:(NSLayoutRelation)relation{
    self.translatesAutoresizingMaskIntoConstraints = NO;
    [self.superview addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeTop relatedBy:relation toItem:self attribute:NSLayoutAttributeBottom multiplier:1 constant:constant]];
}

- (void)horizontalSpacingToView:(UIView *)view constant:(CGFloat)constant relation:(NSLayoutRelation)relation{
    self.translatesAutoresizingMaskIntoConstraints = NO;
    [self.superview addConstraint:[NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeLeft relatedBy:relation toItem:view attribute:NSLayoutAttributeRight multiplier:1 constant:constant]];
}

- (void)heightConstraint:(CGFloat)constant{
    self.translatesAutoresizingMaskIntoConstraints = NO;
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:constant]];
}

- (void)widthConstraint:(CGFloat)constant{
    self.translatesAutoresizingMaskIntoConstraints = NO;
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:constant]];
}

@end
