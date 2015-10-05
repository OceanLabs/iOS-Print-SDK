//
//  CheckoutViewController.h
//  Kite Print SDK
//
//  Created by Deon Botha on 05/01/2014.
//  Copyright (c) 2014 Ocean Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OLPrintEnvironment.h"
#import "OLCheckoutDelegate.h"
#import "OLKiteViewController.h"
@class OLPrintOrder;

extern NSString *const kOLNotificationUserSuppliedShippingDetails;
extern NSString *const kOLNotificationUserCompletedPayment;
extern NSString *const kOLNotificationPrintOrderSubmission;
extern NSString *const kOLKeyUserInfoPrintOrder;

static const NSUInteger kInputFieldTag = 99;
static const NSUInteger kTagInputFieldLabel = 100;

@interface OLCheckoutViewController : UITableViewController

@property (weak, nonatomic) id<OLCheckoutDelegate> delegate;
@property (weak, nonatomic) id<OLKiteDelegate> kiteDelegate;

@property (strong, nonatomic) NSMutableArray *shippingAddresses;
@property (strong, nonatomic) NSMutableArray *selectedShippingAddresses;

@property (copy, nonatomic) NSString *userEmail;
@property (copy, nonatomic) NSString *userPhone;

@property (assign, nonatomic) BOOL showOtherOptions;

- (id)initWithPrintOrder:(OLPrintOrder *)printOrder;
- (id)initWithAPIKey:(NSString *)apiKey environment:(OLKitePrintSDKEnvironment)env printOrder:(OLPrintOrder *)printOrder;
- (void)presentViewControllerFrom:(UIViewController *)presentingViewController animated:(BOOL)animated completion:(void (^)(void))completion;
- (UITableViewCell *)createTextFieldCellWithReuseIdentifier:(NSString *)identifier title:(NSString *)title keyboardType:(UIKeyboardType)type;
@end
