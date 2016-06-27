//
//  Modified MIT License
//
//  Copyright (c) 2010-2016 Kite Tech Ltd. https://www.kite.ly
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The software MAY ONLY be used with the Kite Tech Ltd platform and MAY NOT be modified
//  to be used with any competitor platforms. This means the software MAY NOT be modified
//  to place orders with any competitors to Kite Tech Ltd, all orders MUST go through the
//  Kite Tech Ltd platform servers.
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
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
