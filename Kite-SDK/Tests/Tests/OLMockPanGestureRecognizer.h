//
//  OLMockPanGestureRecognizer.h
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 23/01/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OLMockPanGestureRecognizer : UIPanGestureRecognizer

@property (assign, nonatomic) UIGestureRecognizerState mockState;
@property (assign, nonatomic) CGPoint mockTranslation;
@property (assign, nonatomic) CGPoint mockVelocity;

@end
