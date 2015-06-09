//
//  OLCircleMaskCollectionViewCell.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 1/29/15.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import "OLCircleMaskCollectionViewCell.h"

@implementation OLCircleMaskCollectionViewCell

-(void)layoutSubviews{
    [super layoutSubviews];
    
    if (self.enableMask){
        UIImageView *imageView = (UIImageView *)[self.contentView viewWithTag:10];
        CAShapeLayer *aCircle=[CAShapeLayer layer];
        aCircle.path=[UIBezierPath bezierPathWithRoundedRect:imageView.bounds cornerRadius:imageView.frame.size.height/2].CGPath;
        
        aCircle.fillColor=[UIColor blackColor].CGColor;
        imageView.layer.mask=aCircle;
    }
}

@end
