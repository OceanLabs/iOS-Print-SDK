//
//  OLLongPressGestureRecognizer.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 15/05/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

#import "OLMockLongPressGestureRecognizer.h"

@implementation OLMockLongPressGestureRecognizer

- (UIGestureRecognizerState)state{
    return self.mockState;
}

@end
