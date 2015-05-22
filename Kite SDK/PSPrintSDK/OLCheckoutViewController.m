//
//  CheckoutViewController.m
//  Kite Print SDK
//
//  Created by Deon Botha on 05/01/2014.
//  Copyright (c) 2014 Ocean Labs. All rights reserved.
//

#import "OLCheckoutViewController.h"
#import "OLPaymentViewController.h"
#import "OLPrintOrder.h"
#import "OLAddressPickerController.h"
#import "OLAddress.h"
#import "OLProductTemplate.h"
#import "OLKitePrintSDK.h"
#import "OLAnalytics.h"

NSString *const kOLNotificationUserSuppliedShippingDetails = @"co.oceanlabs.pssdk.kOLNotificationUserSuppliedShippingDetails";
NSString *const kOLNotificationUserCompletedPayment = @"co.oceanlabs.pssdk.kOLNotificationUserCompletedPayment";
NSString *const kOLNotificationPrintOrderSubmission = @"co.oceanlabs.pssdk.kOLNotificationPrintOrderSubmission";

NSString *const kOLKeyUserInfoPrintOrder = @"co.oceanlabs.pssdk.kOLKeyUserInfoPrintOrder";


static const NSUInteger kMinPhoneNumberLength = 5;

static const NSUInteger kSectionDeliveryDetails = 0;
static const NSUInteger kSectionEmailAddress = 1;
static const NSUInteger kSectionPhoneNumber = 2;

static const NSUInteger kSectionCount = 3;

static NSString *const kKeyEmailAddress = @"co.oceanlabs.pssdk.kKeyEmailAddress";
static NSString *const kKeyPhone = @"co.oceanlabs.pssdk.kKeyPhone";

static const NSUInteger kInputFieldTag = 99;

@interface OLPaymentViewController (Private)
@property (nonatomic, assign) BOOL presentedModally;
@end


#define kColourLightBlue [UIColor colorWithRed:0 / 255.0 green:122 / 255.0 blue:255 / 255.0 alpha:1.0]

@interface OLCheckoutViewController () <OLAddressPickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate>
@property (strong, nonatomic) OLAddress *shippingAddress;
@property (strong, nonatomic) UITextField *textFieldEmail, *textFieldPhone;
@property (strong, nonatomic) OLPrintOrder *printOrder;
@property (assign, nonatomic) BOOL presentedModally;
@property (strong, nonatomic) UILabel *kiteLabel;
@property (strong, nonatomic) NSLayoutConstraint *kiteLabelYCon;
@end

@implementation OLCheckoutViewController

- (id)init {
    //NSAssert(NO, @"init is not a valid initializer for OLCheckoutViewController. Use initWithAPIKey:environment:printOrder:, or initWithPrintOrder: instead");
    if (self = [super initWithStyle:UITableViewStyleGrouped]) {
    }
    return self;
}

- (id)initWithAPIKey:(NSString *)apiKey environment:(OLKitePrintSDKEnvironment)env printOrder:(OLPrintOrder *)printOrder {
    //NSAssert(printOrder != nil, @"OLCheckoutViewController requires a non-nil print order");
    if (self = [super initWithStyle:UITableViewStyleGrouped]) {
        [OLKitePrintSDK setAPIKey:apiKey withEnvironment:env];
        self.printOrder = printOrder;
        //[self.printOrder preemptAssetUpload];
        [OLProductTemplate sync];
    }

    return self;
}

- (id)initWithPrintOrder:(OLPrintOrder *)printOrder {
    //NSAssert(printOrder != nil, @"OLCheckoutViewController requires a non-nil print order");
    if (self = [super initWithStyle:UITableViewStyleGrouped]) {
        self.printOrder = printOrder;
        //[self.printOrder preemptAssetUpload];
        [OLProductTemplate sync];
    }
    
    return self;
}

- (void)presentViewControllerFrom:(UIViewController *)presentingViewController animated:(BOOL)animated completion:(void (^)(void))completion {
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:self];
    [presentingViewController presentViewController:navController animated:animated completion:completion];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (![self.parentViewController isKindOfClass:[UINavigationController class]]) {
        [[[UIAlertView alloc] initWithTitle:@"Oops" message:@"OLCheckoutViewController should be part of a UINavigationController stack. Either push the OLCheckoutViewController onto a stack (or make it the rootViewController) or present it modally with OLCheckoutViewController.presentViewControllerFrom:animated:completion:" delegate:nil cancelButtonTitle:nil otherButtonTitles:nil] show];
        return;
    }
    
    if (self.printOrder == nil) {
        [[[UIAlertView alloc] initWithTitle:@"Oops" message:@"OLCheckoutViewController printOrder is nil. Did you use the correct initializer (initWithAPIKey:environment:printOrder:, or initWithPrintOrder:). Nothing will work as you expect until you resolve the issue in code." delegate:nil cancelButtonTitle:nil otherButtonTitles:nil] show];
        return;
    }
    
    if ([OLKitePrintSDK apiKey] == nil) {
        [[[UIAlertView alloc] initWithTitle:@"Oops" message:@"It appears you have not specified your Kite API Key. Did you use the correct initializer for OLCheckoutViewController (initWithAPIKey:environment:printOrder:) or alternatively  directly set it using OLKitePrintSDK.setAPIKey:withEnvironment:. Nothing will work as you expect until you resolve the issue in code." delegate:nil cancelButtonTitle:nil otherButtonTitles:nil] show];
        return;
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinator> context){
        [self positionKiteLabel];
    } completion:NULL];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackShippingScreenViewedForOrder:self.printOrder];
#endif
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Next", @"KitePrintSDK", [OLConstants bundle], @"") style:UIBarButtonItemStylePlain target:self action:@selector(onButtonNextClicked)];
    
    self.presentedModally = self.parentViewController.isBeingPresented && self.navigationController.viewControllers.lastObject == self;
    if (self.presentedModally) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Cancel", @"KitePrintSDK", [OLConstants bundle], @"") style:UIBarButtonItemStylePlain target:self action:@selector(onButtonCancelClicked)];
    }
    
    self.title = NSLocalizedStringFromTableInBundle(@"Shipping", @"KitePrintSDK", [OLConstants bundle], @"");
    self.tableView.tableHeaderView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkout_progress_indicator"]];
    self.tableView.tableHeaderView.contentMode = UIViewContentModeCenter;
    self.tableView.tableHeaderView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.tableView.tableHeaderView.frame.size.height);

    UITapGestureRecognizer *tgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onBackgroundClicked)];
    tgr.cancelsTouchesInView = NO; // allow table cell selection to happen as normal
    [self.tableView addGestureRecognizer:tgr];
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 0)];
    
    self.kiteLabel = [[UILabel alloc] init];
    self.kiteLabel.text = NSLocalizedString(@"Powered by Kite.ly", @"");
    self.kiteLabel.font = [UIFont systemFontOfSize:13];
    self.kiteLabel.textColor = [UIColor lightGrayColor];
    self.kiteLabel.textAlignment = NSTextAlignmentCenter;
    [self.tableView.tableFooterView addSubview:self.kiteLabel];
    self.kiteLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.tableView.tableFooterView addConstraint:[NSLayoutConstraint constraintWithItem:self.kiteLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.tableView.tableFooterView attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    
    [self.printOrder costWithCompletionHandler:^(NSDecimalNumber *totalCost, NSDecimalNumber *shippingCost, NSArray *lineItems, NSDictionary *jobCosts, NSError * error){
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationCostFetchComplete object:nil];
    }];
}

- (void)positionKiteLabel {
    [self.kiteLabel.superview removeConstraint:self.kiteLabelYCon];
    
    CGSize size = self.view.frame.size;
    CGFloat navBarHeight = [[UIApplication sharedApplication] statusBarFrame].size.height + self.navigationController.navigationBar.frame.size.height;
    CGFloat blankSpace = MAX(size.height - self.tableView.contentSize.height - navBarHeight - 5, 30);
    
    self.kiteLabelYCon = [NSLayoutConstraint constraintWithItem:self.kiteLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.kiteLabel.superview attribute:NSLayoutAttributeBottom multiplier:1 constant:blankSpace];
    [self.kiteLabel.superview addConstraint:self.kiteLabelYCon];
}

- (void)onButtonCancelClicked {
    if ([self.delegate respondsToSelector:@selector(checkoutViewControllerDidCancel:)]) {
        [self.delegate checkoutViewControllerDidCancel:self];
    } else {
        [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)onBackgroundClicked {
    [self.textFieldEmail resignFirstResponder];
    [self.textFieldPhone resignFirstResponder];
}

- (void)populateDefaultEmailAndPhone {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *email = [defaults stringForKey:kKeyEmailAddress];
    NSString *phone = [defaults stringForKey:kKeyPhone];
    if (self.textFieldEmail.text.length == 0) {
        if (email.length > 0) {
            self.textFieldEmail.text = email;
        } else if (self.userEmail.length > 0) {
            self.textFieldEmail.text = self.userEmail;
        }
    }
    
    if (self.textFieldPhone.text.length == 0) {
        if (phone.length > 0) {
            self.textFieldPhone.text = phone;
        } else if (self.userPhone.length > 0) {
            self.textFieldPhone.text = self.userPhone;
        }
    }
}

- (void)onButtonNextClicked {
    if (![self hasUserProvidedValidDetailsToProgressToPayment]) {
        return;
    }
    
    [self.textFieldEmail resignFirstResponder];
    [self.textFieldPhone resignFirstResponder];
    
    NSString *email = self.textFieldEmail.text ? self.textFieldEmail.text : @"";
    NSString *phone = self.textFieldPhone.text ? self.textFieldPhone.text : @"";
    
    NSMutableDictionary *d = [[NSMutableDictionary alloc] init];
    if (self.printOrder.userData) {
        d = [self.printOrder.userData mutableCopy];
    }
    
    d[@"email"] = email;
    d[@"phone"] = phone;
    self.printOrder.userData = d;
    
    self.printOrder.shippingAddress = self.shippingAddress;
    OLPaymentViewController *vc = [[OLPaymentViewController alloc] initWithPrintOrder:self.printOrder];
    vc.presentedModally = self.presentedModally;
    vc.delegate = self.delegate;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:email forKey:kKeyEmailAddress];
    [defaults setObject:phone forKey:kKeyPhone];
    [defaults synchronize];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kOLNotificationUserSuppliedShippingDetails object:self userInfo:@{kOLKeyUserInfoPrintOrder: self.printOrder}];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void) viewWillAppear:(BOOL)animated{
    if (self.kiteLabel){
        [self positionKiteLabel];
    }
}

- (void) viewWillDisappear:(BOOL)animated {
    if ([self.navigationController.viewControllers indexOfObject:self] == NSNotFound) {
        // back button pressed. we're going back to photo selection view so lets cancel any
        // preempted asset upload
        //[self.printOrder cancelSubmissionOrPreemptedAssetUpload];
    }
}

+ (BOOL)validateEmail:(NSString *)candidate {
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:candidate];
}

- (BOOL)hasUserProvidedValidDetailsToProgressToPayment {
    /*
     * Only progress to Payment screen if the user has supplied a valid Delivery Address, Email & Telephone number.
     * Otherwise highlight the error to the user.
     */
    if (self.shippingAddress == nil) {
        [self scrollSectionToVisible:kSectionDeliveryDetails];
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Missing Delivery Address", @"KitePrintSDK", [OLConstants bundle], @"") message:NSLocalizedStringFromTableInBundle(@"Please choose an address to have your order shipped to", @"KitePrintSDK", [OLConstants bundle], @"") delegate:nil cancelButtonTitle:NSLocalizedStringFromTableInBundle(@"OK", @"KitePrintSDK", [OLConstants bundle], @"") otherButtonTitles:nil];
        [av show];
        return NO;
    }

    if (![OLCheckoutViewController validateEmail:self.textFieldEmail.text]) {
        [self scrollSectionToVisible:kSectionEmailAddress];
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Invalid Email Address", @"KitePrintSDK", [OLConstants bundle], @"") message:NSLocalizedStringFromTableInBundle(@"Please enter a valid email address", @"KitePrintSDK", [OLConstants bundle], @"") delegate:nil cancelButtonTitle:NSLocalizedStringFromTableInBundle(@"OK", @"KitePrintSDK", [OLConstants bundle], @"") otherButtonTitles:nil];
        [av show];
        return NO;
    }
    
    if (self.textFieldPhone.text.length < kMinPhoneNumberLength && (([self.kiteDelegate respondsToSelector:@selector(shouldShowPhoneEntryOnCheckoutScreen)] && [self.kiteDelegate shouldShowPhoneEntryOnCheckoutScreen]) || ![self.kiteDelegate respondsToSelector:@selector(shouldShowPhoneEntryOnCheckoutScreen)])) {
        [self scrollSectionToVisible:kSectionPhoneNumber];
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Invalid Phone Number", @"KitePrintSDK", [OLConstants bundle], @"") message:NSLocalizedStringFromTableInBundle(@"Please enter a valid phone number", @"KitePrintSDK", [OLConstants bundle], @"") delegate:nil cancelButtonTitle:NSLocalizedStringFromTableInBundle(@"OK", @"KitePrintSDK", [OLConstants bundle], @"") otherButtonTitles:nil];
        [av show];
        return NO;
    }
    
    return YES;
}

- (void)scrollSectionToVisible:(NSUInteger)section {
    CGRect sectionRect = [self.tableView rectForSection:section];
    [self.tableView scrollRectToVisible:sectionRect animated:YES];
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.kiteDelegate respondsToSelector:@selector(shouldShowPhoneEntryOnCheckoutScreen)] && ![self.kiteDelegate shouldShowPhoneEntryOnCheckoutScreen] ? kSectionCount - 1 : kSectionCount;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == kSectionDeliveryDetails) {
        return NSLocalizedStringFromTableInBundle(@"Delivery Details", @"KitePrintSDK", [OLConstants bundle], @"");
    } else {
        return nil;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == kSectionEmailAddress) {
        return NSLocalizedStringFromTableInBundle(@"We'll send you confirmation and order updates", @"KitePrintSDK", [OLConstants bundle], @"");
    } else if (section == kSectionPhoneNumber) {
        return NSLocalizedStringFromTableInBundle(@"Required by the postal service in case there are any issues during delivery", @"KitePrintSDK", [OLConstants bundle], @"");
    }
    
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == kSectionDeliveryDetails) {
        return 1;
    } else if (section == kSectionEmailAddress) {
        return 1;
    } else if (section == kSectionPhoneNumber) {
        return 1;
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    if (indexPath.section == kSectionDeliveryDetails) {
        static NSString *const kDeliveryAddressCell = @"DeliveryAddressCell";
        static NSString *const kAddDeliveryAddressCell = @"AddDeliveryAddressCell";
        
        if (self.shippingAddress) {
            cell = [tableView dequeueReusableCellWithIdentifier:kDeliveryAddressCell];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kDeliveryAddressCell];
            }
                cell.textLabel.textColor = [UIColor blackColor];
                cell.textLabel.text = self.shippingAddress.recipientName;
                cell.detailTextLabel.text = self.shippingAddress.descriptionWithoutRecipient;
        } else {
            cell = [tableView dequeueReusableCellWithIdentifier:kAddDeliveryAddressCell];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kAddDeliveryAddressCell];
                cell.textLabel.text = NSLocalizedStringFromTableInBundle(@"Choose Delivery Address", @"KitePrintSDK", [OLConstants bundle], @"");
                cell.textLabel.adjustsFontSizeToFitWidth = YES;
                cell.textLabel.textColor = kColourLightBlue;
            }
        }
    } else if (indexPath.section == kSectionEmailAddress) {
        static NSString *const TextFieldCell = @"EmailFieldCell";
        cell = [tableView dequeueReusableCellWithIdentifier:TextFieldCell];
        if (cell == nil) {
            cell = [self createTextFieldCellWithReuseIdentifier:TextFieldCell title:NSLocalizedStringFromTableInBundle(@"Email", @"KitePrintSDK", [OLConstants bundle], @"")  keyboardType:UIKeyboardTypeEmailAddress];
            self.textFieldEmail = (UITextField *) [cell viewWithTag:kInputFieldTag];
            self.textFieldEmail.autocapitalizationType = UITextAutocapitalizationTypeNone;
            [self populateDefaultEmailAndPhone];
        }
        
    } else if (indexPath.section == kSectionPhoneNumber) {
        static NSString *const TextFieldCell = @"PhoneFieldCell";
        cell = [tableView dequeueReusableCellWithIdentifier:TextFieldCell];
        if (cell == nil) {
            cell = [self createTextFieldCellWithReuseIdentifier:TextFieldCell title:NSLocalizedStringFromTableInBundle(@"Phone", @"KitePrintSDK", [OLConstants bundle], @"") keyboardType:UIKeyboardTypePhonePad];
            self.textFieldPhone = (UITextField *) [cell viewWithTag:kInputFieldTag];
            [self populateDefaultEmailAndPhone];
        }
    }

    return cell;
}

- (UITableViewCell *)createTextFieldCellWithReuseIdentifier:(NSString *)identifier title:(NSString *)title keyboardType:(UIKeyboardType)type {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 43)];
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 11, 61, 21)];
    titleLabel.text = title;
    titleLabel.adjustsFontSizeToFitWidth = YES;
    UITextField *inputField = [[UITextField alloc] initWithFrame:CGRectMake(86, 0, [UIScreen mainScreen].bounds.size.width - 86, 43)];
    inputField.delegate = self;
    inputField.tag = kInputFieldTag;
    [inputField setKeyboardType:type];
    [cell addSubview:titleLabel];
    [cell addSubview:inputField];
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8){
        UIView *view = inputField;
        view.translatesAutoresizingMaskIntoConstraints = NO;
        NSDictionary *views = NSDictionaryOfVariableBindings(view);
        NSMutableArray *con = [[NSMutableArray alloc] init];
        
        NSArray *visuals = @[@"H:|-86-[view]-0-|", @"V:[view(43)]"];
        
        
        for (NSString *visual in visuals) {
            [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
        }
        
        NSLayoutConstraint *centerY = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:view.superview attribute:NSLayoutAttributeCenterY multiplier:1 constant:0];
        [con addObject:centerY];
        
        [view.superview addConstraints:con];
    }

    
    return cell;
}

#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == kSectionDeliveryDetails) {
        OLAddressPickerController *c = [[OLAddressPickerController alloc] init];
        c.delegate = self;
        [self presentViewController:c animated:YES completion:nil];
    }
}

#pragma mark - UITextFieldDelegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.textFieldEmail && ([self.kiteDelegate respondsToSelector:@selector(shouldShowPhoneEntryOnCheckoutScreen)] && [self.kiteDelegate shouldShowPhoneEntryOnCheckoutScreen])) {
        [self scrollSectionToVisible:kSectionPhoneNumber];
        [self.textFieldPhone becomeFirstResponder];
    }
    else{
        [textField resignFirstResponder];
    }
    
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if (textField == self.textFieldEmail) {
        [self scrollSectionToVisible:kSectionEmailAddress];
    } else if (textField == self.textFieldPhone) {
        [self scrollSectionToVisible:kSectionPhoneNumber];
    }
}

#pragma mark - OLAddressPickerController delegate

- (void)addressPicker:(OLAddressPickerController *)picker didFinishPickingAddresses:(NSArray/*<OLAddress>*/ *)addresses {
    self.shippingAddress = addresses[0];
    [self dismissViewControllerAnimated:YES completion:nil];
//    [self.tableView reloadData];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:kSectionDeliveryDetails]] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)addressPickerDidCancelPicking:(OLAddressPickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Autorotate and Orientation Methods
// Currently here to disable landscape orientations and rotation on iOS 7. When support is dropped, these can be deleted.

- (BOOL)shouldAutorotate {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8) {
        return YES;
    }
    else{
        return NO;
    }
}

- (NSUInteger)supportedInterfaceOrientations {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8) {
        return UIInterfaceOrientationMaskAll;
    }
    else{
        return UIInterfaceOrientationMaskPortrait;
    }
}


@end
