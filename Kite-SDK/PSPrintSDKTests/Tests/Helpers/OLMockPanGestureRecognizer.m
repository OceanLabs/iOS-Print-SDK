//
//  OLMockPanGestureRecognizer.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 23/01/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

#import "OLMockPanGestureRecognizer.h"

@interface UIPanGestureRecognizer ()

@end

@implementation OLMockPanGestureRecognizer

- (UIGestureRecognizerState)state{
    return self.mockState;
}

- (CGPoint) velocityInView:(UIView *)view{
    return self.mockVelocity;
}

- (CGPoint) translationInView:(UIView *)view{
    return self.mockTranslation;
}

@end
