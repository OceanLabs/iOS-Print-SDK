//
//  OLSelectedEffectButton.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 23/06/16.
//  Copyright © 2016 Kite.ly. All rights reserved.
//

#import "OLSelectedEffectButton.h"
#import "UIView+RoundRect.h"

@interface OLSelectedEffectButton ()

@property (strong, nonatomic) UIView *selectedView;
@property (strong, nonatomic) UILabel *badgeLabel;

@end

@implementation OLSelectedEffectButton

- (UIColor *)colorToUse{
    return self.effectColor ? self.effectColor : [UIColor colorWithRed:0.349 green:0.757 blue:0.890 alpha:1.000];
}

- (void)setSelected:(BOOL)selected{
    if (!self.selected && selected){
        if (!self.selectedView){
            self.selectedView = [[UIView alloc] initWithFrame:CGRectMake(0, self.frame.size.height, self.frame.size.width, 3.5)];
            self.selectedView.backgroundColor = [self colorToUse];
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

- (void)updateBadge:(NSString *)string{
    if (!self.badgeLabel){
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(40, 7, 13, 13)];
        label.font = [UIFont systemFontOfSize:9];
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor blackColor];
        label.minimumScaleFactor = 0.5;
        label.adjustsFontSizeToFitWidth = YES;
        label.backgroundColor = [self colorToUse];
        [label makeRoundRectWithRadius:6.5];
        self.badgeLabel = label;
        
        [self addSubview:label];
    }
    
    if (!string || [string isEqualToString:@""]){
        self.badgeLabel.hidden = YES;
    }
    else{
        self.badgeLabel.hidden = NO;
        self.badgeLabel.text = string;
    }
}


@end
