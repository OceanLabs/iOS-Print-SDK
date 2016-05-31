//
//  OLStripeCard+OLCardIcon.h
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 31/05/16.
//  Copyright © 2016 Kite.ly. All rights reserved.
//

#import "OLStripeCard.h"

@import UIKit;

@interface OLStripeCard (OLCardIcon)

-(UIImage *)cardIcon;
- (BOOL)isValidCardNumber;

@end
