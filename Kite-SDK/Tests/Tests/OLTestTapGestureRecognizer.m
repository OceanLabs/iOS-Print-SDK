//
//  OLTestTapGestureRecognizer.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 06/05/16.
//  Copyright © 2016 Kite.ly. All rights reserved.
//

#import "OLTestTapGestureRecognizer.h"

@implementation OLTestTapGestureRecognizer

- (CGPoint)locationInView:(UIView *)view{
    return self.customLocationInView;
}

@end
