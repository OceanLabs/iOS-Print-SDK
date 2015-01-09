//
//  WhiteSquare.m
//  HuggleUp
//
//  Created by Konstadinos Karayannis on 16/10/14.
//  Copyright (c) 2014 Ocean Labs. All rights reserved.
//

#import "WhiteSquare.h"

@implementation WhiteSquare


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    //// Color Declarations
    UIColor* color = [UIColor colorWithRed: 1 green: 1 blue: 1 alpha: 1];
    
    //// Rectangle Drawing
    CGSize s = self.bounds.size;
    CGFloat p = 0.2;
    UIBezierPath* rectanglePath = [UIBezierPath bezierPathWithRect: CGRectMake(s.height * p, s.height * p, s.width - s.height * p * 2, s.height * (1-p*2))];
    [[UIColor clearColor] setFill];
    [rectanglePath fill];
    [color setStroke];
    rectanglePath.lineWidth = 1;
    [rectanglePath stroke];
}


@end
