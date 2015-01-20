//
//  OLCircleMaskTableViewCell.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 1/20/15.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import "OLCircleMaskTableViewCell.h"

@implementation OLCircleMaskTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)layoutSubviews{
    [super layoutSubviews];
    
    if (self.enableMask){
        UIImageView *imageView = (UIImageView *)[self.contentView viewWithTag:10];
        UIView *circleMaskView = [self.contentView viewWithTag:89];
        CAShapeLayer *aCircle=[CAShapeLayer layer];
        aCircle.path=[UIBezierPath bezierPathWithRoundedRect:circleMaskView.bounds cornerRadius:circleMaskView.frame.size.height/2].CGPath;
        
        aCircle.fillColor=[UIColor blackColor].CGColor;
        imageView.layer.mask=aCircle;
    }
}

@end
