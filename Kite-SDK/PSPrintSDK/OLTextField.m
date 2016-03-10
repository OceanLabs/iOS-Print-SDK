//
//  OLTextField.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 10/03/16.
//  Copyright © 2016 Kite.ly. All rights reserved.
//

#import "OLTextField.h"

@implementation OLTextField

- (CGRect)textRectForBounds:(CGRect)bounds {
    return CGRectMake(bounds.origin.x + self.margins, bounds.origin.y,
                      bounds.size.width - self.margins * 2, bounds.size.height);
}
- (CGRect)editingRectForBounds:(CGRect)bounds {
    return [self textRectForBounds:bounds];
}


@end
