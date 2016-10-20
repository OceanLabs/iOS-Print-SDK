//
//  OLSelectedEffectButton.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 23/06/16.
//  Copyright © 2016 Kite.ly. All rights reserved.
//

#import "OLSelectedEffectButton.h"

@interface OLSelectedEffectButton ()

@property (strong, nonatomic) UIView *selectedView;

@end

@implementation OLSelectedEffectButton

- (void)setSelected:(BOOL)selected{
    if (!self.selected && selected){
        if (!self.selectedView){
            self.selectedView = [[UIView alloc] initWithFrame:CGRectMake(0, self.frame.size.height, self.frame.size.width, 3.5)];
            self.selectedView.backgroundColor = self.effectColor ? self.effectColor : [UIColor colorWithRed:0.349 green:0.757 blue:0.890 alpha:1.000];
            [self addSubview:self.selectedView];
        }
        
        [UIView animateWithDuration:0.25 animations:^{
            self.selectedView.transform = CGAffineTransformMakeTranslation(0, -3.5);
        }];

    }
    else if (self.selected && !selected){
        [UIView animateWithDuration:0.25 animations:^{
            self.selectedView.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished){}];
    }
    super.selected = selected;
}


@end
