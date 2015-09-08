//
//  OLCollectionView.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 3/7/15.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import "OLPhotobookScrubberCollectionView.h"
#import "OLPhotobookViewController.h"

@interface OLPhotobookViewController ()

- (void)userDidStopTouchingScrubberAtPoint:(CGPoint)p;
- (void)userDidTouchScrubberAtPoint:(CGPoint)p;

@end

@implementation OLPhotobookScrubberCollectionView

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    [super touchesBegan:touches withEvent:event];
    if ([self.delegate respondsToSelector:@selector(userDidTouchScrubberAtPoint:)]){
        [(OLPhotobookViewController *)self.delegate userDidTouchScrubberAtPoint:[(UITouch *)[touches anyObject] locationInView:self]];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    [super touchesEnded:touches withEvent:event];
    if ([self.delegate respondsToSelector:@selector(userDidStopTouchingScrubberAtPoint:)]){
        [(OLPhotobookViewController *)self.delegate userDidStopTouchingScrubberAtPoint:[(UITouch *)[touches anyObject] locationInView:self]];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    [super touchesMoved:touches withEvent:event];
    if ([self.delegate respondsToSelector:@selector(userDidTouchScrubberAtPoint:)]){
        [(OLPhotobookViewController *)self.delegate userDidTouchScrubberAtPoint:[(UITouch *)[touches anyObject] locationInView:self]];
    }
}

@end
