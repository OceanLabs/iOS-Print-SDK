//
//  CheckoutViewController.h
//  Print Studio
//
//  Created by Deon Botha on 05/01/2014.
//  Copyright (c) 2014 Ocean Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OLPrintEnvironment.h"
#import "OLCheckoutDelegate.h"
@class OLPrintOrder;

NSString *const kOLNotificationUserSuppliedShippingDetails;
NSString *const kOLNotificationUserCompletedPayment;
NSString *const kOLNotificationPrintOrderSubmission;
NSString *const kOLKeyUserInfoPrintOrder;

@interface OLCheckoutViewController : UITableViewController

@property (weak, nonatomic) id<OLCheckoutDelegate> delegate;

- (id)initWithPrintOrder:(OLPrintOrder *)printOrder;
- (id)initWithAPIKey:(NSString *)apiKey environment:(OLKitePrintSDKEnvironment)env printOrder:(OLPrintOrder *)printOrder;
- (void)presentViewControllerFrom:(UIViewController *)presentingViewController animated:(BOOL)animated completion:(void (^)(void))completion;
@end
