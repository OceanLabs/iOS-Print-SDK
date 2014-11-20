//
//  OLCreditCardCaptureViewController.h
//  KitePrintSDK
//
//  Created by Deon Botha on 20/11/2014.
//  Copyright (c) 2014 Deon Botha. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OLCreditCardCaptureViewController;
@class OLPrintOrder;

@protocol OLCreditCardCaptureDelegate <NSObject>
- (void)creditCardCaptureController:(OLCreditCardCaptureViewController *)vc didFinishWithProofOfPayment:(NSString *)proofOfPayment;
@optional
- (void)creditCardCaptureControllerDismissed:(OLCreditCardCaptureViewController *)vc;
@end

@interface OLCreditCardCaptureViewController : UINavigationController
- (id)initWithPrintOrder:(OLPrintOrder *)printOrder;

@property (nonatomic, weak) id <UINavigationControllerDelegate, OLCreditCardCaptureDelegate> delegate;

@end
