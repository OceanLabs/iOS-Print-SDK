//
//  OLSelectedEffectButton.h
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 23/06/16.
//  Copyright © 2016 Kite.ly. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OLSelectedEffectButton : UIButton
@property (strong, nonatomic) UIColor *effectColor;
- (void)updateBadge:(NSString *)string;
@end
