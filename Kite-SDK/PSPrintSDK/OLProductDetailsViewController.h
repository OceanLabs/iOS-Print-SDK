//
//  OLProductDetailsViewController.h
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 21/10/15.
//  Copyright © 2015 Kite.ly. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OLProduct.h"

@protocol OLProductDetailsDelegate <NSObject>

-(void)optionsButtonClicked;

@end

@interface OLProductDetailsViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *detailsTextLabel;
@property (strong, nonatomic) OLProduct *product;
@property (weak, nonatomic) id<OLProductDetailsDelegate> delegate;

@property (weak, nonatomic) IBOutlet UIImageView *arrowImageView;
@property (weak, nonatomic) IBOutlet UILabel *priceLabel;

- (CGFloat)recommendedDetailsBoxHeight;

@end
