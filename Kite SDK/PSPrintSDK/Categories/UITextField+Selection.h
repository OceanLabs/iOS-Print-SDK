//
//  UITextField+Selection.h
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 2/19/15.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UITextField (Selection)

- (void)setSelectedRange:(NSRange)selectedRange;
- (NSRange)selectedRange;

@end
