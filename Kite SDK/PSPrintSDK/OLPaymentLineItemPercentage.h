//
//  OLPaymentLineItemPercentage.h
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 5/12/15.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import "OLPaymentLineItem.h"
#import "OLPrintJob.h"

@interface OLPaymentLineItemPercentage : OLPaymentLineItem <NSCoding>

@property (strong, nonatomic) id<OLPrintJob> printJob;

@end
