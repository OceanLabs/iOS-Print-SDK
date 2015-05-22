//
//  IntegratedCheckoutViewController.h
//  HuggleUp
//
//  Created by Kostas Karayannis on 08/08/2014.
//  Copyright (c) 2014 Ocean Labs. All rights reserved.
//

#import "OLCheckoutViewController.h"
#import "OLAddress.h"

@interface OLIntegratedCheckoutViewController : OLCheckoutViewController

@property (strong, nonatomic) OLAddress* shippingAddress;
@property (strong, nonatomic) UITextField* textFieldEmail;
@property (strong, nonatomic) UITextField* textFieldPhone;
@property (strong, nonatomic) OLPrintOrder* printOrder;

- (id)initWithPrintOrder:(OLPrintOrder *)printOrder;

@end
