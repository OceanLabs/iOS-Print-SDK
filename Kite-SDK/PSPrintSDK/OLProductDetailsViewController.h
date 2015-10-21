//
//  OLProductDetailsViewController.h
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 21/10/15.
//  Copyright © 2015 Kite.ly. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OLProduct.h"

@interface OLProductDetailsViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *detailsTextLabel;
@property (strong, nonatomic) OLProduct *product;

- (CGFloat)recommendedDetailsBoxHeight;

@end
