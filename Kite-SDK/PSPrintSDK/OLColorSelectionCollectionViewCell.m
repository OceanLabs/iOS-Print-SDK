//
//  OLColorSelectionCollectionViewCell.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 24/06/16.
//  Copyright © 2016 Kite.ly. All rights reserved.
//

#import "OLColorSelectionCollectionViewCell.h"

static CGFloat circlesDiff = 0.2;

@implementation OLColorSelectionCollectionViewCell

- (void)initialize{
    self.backgroundColor = [UIColor clearColor];
}

- (id)initWithCoder:(NSCoder *)aCoder{
    if(self = [super initWithCoder:aCoder]){
        [self initialize];
    }
    return self;
}

- (id)initWithFrame:(CGRect)rect{
    if(self = [super initWithFrame:rect]){
        [self initialize];
    }
    return self;
}

- (void)drawRect:(CGRect)rect{
    if (self.selected){
        if ([self.color isEqual:[UIColor whiteColor]]){
            UIBezierPath* ovalPath = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(2, 2, self.frame.size.width-4, self.frame.size.height-4)];
            [[UIColor grayColor] setStroke];
            ovalPath.lineWidth = 1;
            [ovalPath stroke];
            
            UIBezierPath* ovalPath2 = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(self.frame.size.width * circlesDiff, self.frame.size.height * circlesDiff, self.frame.size.width  * (1-2*circlesDiff), self.frame.size.height * (1-2*circlesDiff))];
            [[UIColor grayColor] setStroke];
            ovalPath2.lineWidth = 2;
            [ovalPath2 stroke];
            [self.color setFill];
            [ovalPath2 fill];
        }
        else{
            UIBezierPath* ovalPath = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(2, 2, self.frame.size.width-4, self.frame.size.height-4)];
            [self.color setStroke];
            ovalPath.lineWidth = 1;
            [ovalPath stroke];
            
            UIBezierPath* ovalPath2 = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(self.frame.size.width * circlesDiff, self.frame.size.height * circlesDiff, self.frame.size.width  * (1-2*circlesDiff), self.frame.size.height * (1-2*circlesDiff))];
            [self.color setFill];
            [ovalPath2 fill];
        }
    }
    else{
        if ([self.color isEqual:[UIColor whiteColor]]){
            UIBezierPath* ovalPath = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(2, 2, self.frame.size.width-4, self.frame.size.height-4)];
            [[UIColor grayColor] setStroke];
            ovalPath.lineWidth = 2;
            [ovalPath stroke];
            [self.color setFill];
            [ovalPath fill];
        }
        else{
            UIBezierPath* ovalPath = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(2, 2, self.frame.size.width-4, self.frame.size.height-4)];
            [self.color setFill];
            [ovalPath fill];
        }
    }
}

@end
