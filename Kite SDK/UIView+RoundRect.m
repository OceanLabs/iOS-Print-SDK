//
//  UIView+RoundRect.m
//  Get Squared
//
//  Created by Konstadinos Karayannis on 29/8/14.
//  Copyright (c) 2014 Ocean Labs. All rights reserved.
//

#import "UIView+RoundRect.h"

@implementation UIView (RoundRect)

-(void) makeRoundRect{
    CALayer *layer = [self layer];
    [layer setMasksToBounds:YES];
    [layer setCornerRadius:6.0f];
}

@end
