//
//  Modified MIT License
//
//  Copyright (c) 2010-2016 Kite Tech Ltd. https://www.kite.ly
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The software MAY ONLY be used with the Kite Tech Ltd platform and MAY NOT be modified
//  to be used with any competitor platforms. This means the software MAY NOT be modified
//  to place orders with any competitors to Kite Tech Ltd, all orders MUST go through the
//  Kite Tech Ltd platform servers.
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#ifdef COCOAPODS
#import <SDWebImage/SDWebImageManager.h>
#import <SkyLab/SkyLab.h>
#else
#import "SDWebImageManager.h"
#import "SkyLab.h"
#endif

#import "OLCheckoutViewController.h"
#import "OLPaymentViewController.h"
#import "OLPrintOrder.h"
#import "OLAddressPickerController.h"
#import "OLAddress.h"
#import "OLProductTemplate.h"
#import "OLKitePrintSDK.h"
#import "OLAnalytics.h"
#import "OLAddressEditViewController.h"
#import "OLProductPrintJob.h"
#import "OLKiteABTesting.h"
#import "UIImage+ColorAtPixel.h"
#import "UIImage+ImageNamedInKiteBundle.h"
#import "OLKiteUtils.h"

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

@interface OLPaymentViewController (Private)
@property (nonatomic, assign) BOOL presentedModally;
@end

@interface OLPrintOrder (PrivateMethods)
@property (assign, nonatomic) BOOL optOutOfEmail;
@end


#define kColourLightBlue [UIColor colorWithRed:0 / 255.0 green:122 / 255.0 blue:255 / 255.0 alpha:1.0]

@interface OLCheckoutViewController () <OLAddressPickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate>
@property (strong, nonatomic) UITextField *textFieldEmail, *textFieldPhone;
@property (strong, nonatomic) OLPrintOrder *printOrder;
@property (assign, nonatomic) BOOL presentedModally;
@property (strong, nonatomic) UILabel *kiteLabel;
@property (strong, nonatomic) NSLayoutConstraint *kiteLabelYCon;
@property (weak, nonatomic) UITextField *activeTextView;
@end

@implementation OLCheckoutViewController

- (BOOL)prefersStatusBarHidden {
    BOOL hidden = [OLKiteABTesting sharedInstance].darkTheme;
    
    if ([self respondsToSelector:@selector(traitCollection)]){
        if (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact && self.view.frame.size.height < self.view.frame.size.width){
            hidden |= YES;
        }
    }
    
    return hidden;
}

-(NSMutableArray *) shippingAddresses{
    if (!_shippingAddresses){
        _shippingAddresses = [[NSMutableArray alloc] init];
    }
    return _shippingAddresses;
}

-(NSMutableArray *) selectedShippingAddresses{
    if (!_selectedShippingAddresses){
        _selectedShippingAddresses = [[NSMutableArray alloc] init];
    }
    return _selectedShippingAddresses;
}

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
    }
    
    return self;
}

- (id)initWithPrintOrder:(OLPrintOrder *)printOrder {
    //NSAssert(printOrder != nil, @"OLCheckoutViewController requires a non-nil print order");
    if (self = [super initWithStyle:UITableViewStyleGrouped]) {
        self.printOrder = printOrder;
        //[self.printOrder preemptAssetUpload];
    }
    
    return self;
}

- (void)presentViewControllerFrom:(UIViewController *)presentingViewController animated:(BOOL)animated completion:(void (^)(void))completion {
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:self];
    navController.modalPresentationStyle = [OLKiteUtils kiteVcForViewController:self].modalPresentationStyle;
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
//        self.tableView.contentInset = UIEdgeInsetsMake(self.edgeInsetTop, 0, 0, 0);
        [self positionKiteLabel];
    } completion:^(id<UIViewControllerTransitionCoordinator> context){
    }];
}

- (CGFloat)edgeInsetTop{
    return self.navigationController.navigationBar.translucent ? [[UIApplication sharedApplication] statusBarFrame].size.height + self.navigationController.navigationBar.frame.size.height : 0;
}



- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self registerForKeyboardNotifications];
    
    [self trackViewed];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Next", @"KitePrintSDK", [OLConstants bundle], @"") style:UIBarButtonItemStylePlain target:self action:@selector(onButtonNextClicked)];
    
    self.presentedModally = self.parentViewController.isBeingPresented || self.navigationController.viewControllers.firstObject == self;
    if (self.presentedModally) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Cancel", @"KitePrintSDK", [OLConstants bundle], @"") style:UIBarButtonItemStylePlain target:self action:@selector(onButtonCancelClicked)];
    }
    else{
        self.navigationItem.leftBarButtonItem = nil;
    }
    
    self.title = NSLocalizedStringFromTableInBundle(@"Shipping", @"KitePrintSDK", [OLConstants bundle], @"");

    UITapGestureRecognizer *tgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onBackgroundClicked)];
    tgr.cancelsTouchesInView = NO; // allow table cell selection to happen as normal
    [self.tableView addGestureRecognizer:tgr];
    
    self.tableView.allowsMultipleSelectionDuringEditing = NO;
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 0)];
    
    self.kiteLabel = [[UILabel alloc] init];
    self.kiteLabel.text = NSLocalizedString(@"Powered by Kite.ly", @"");
    self.kiteLabel.font = [UIFont systemFontOfSize:13];
    self.kiteLabel.textColor = [UIColor lightGrayColor];
    self.kiteLabel.textAlignment = NSTextAlignmentCenter;
    [self.tableView.tableFooterView addSubview:self.kiteLabel];
    self.kiteLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.tableView.tableFooterView addConstraint:[NSLayoutConstraint constraintWithItem:self.kiteLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.tableView.tableFooterView attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    
    [self.printOrder costWithCompletionHandler:nil]; // ignore outcome, internally printOrder caches the result and this will speed up things when we hit the PaymentScreen *if* the user doesn't change destination shipping country as the voids shipping price
    
    if (self.printOrder.shippingAddress && [self.printOrder.shippingAddress isValidAddress]){ //Only for single addresses
        self.shippingAddresses = [@[self.printOrder.shippingAddress] mutableCopy];
        self.selectedShippingAddresses = [[NSMutableArray alloc] init];
        [self.selectedShippingAddresses addObject:self.printOrder.shippingAddress];
    }
    else if(self.printOrder.shippingAddressesOfJobs.count > 0){
        self.shippingAddresses = [self.printOrder.shippingAddressesOfJobs mutableCopy];
        self.selectedShippingAddresses = [self.printOrder.shippingAddressesOfJobs mutableCopy];
    }
    
    if ([self.tableView respondsToSelector:@selector(setCellLayoutMarginsFollowReadableWidth:)]){
        self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    }
}

- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
}

- (void)trackViewed{
#ifndef OL_NO_ANALYTICS
    if ([OLKiteABTesting sharedInstance].offerAddressSearch) {
        [OLAnalytics trackShippingScreenViewedForOrder:self.printOrder variant:@"Classic + Address Search" showPhoneEntryField:[self showPhoneEntryField]];
    } else {
        [OLAnalytics trackShippingScreenViewedForOrder:self.printOrder variant:@"Classic" showPhoneEntryField:[self showPhoneEntryField]];
    }
#endif
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    
#ifndef OL_NO_ANALYTICS
    if (!self.navigationController){
        [OLAnalytics trackShippingScreenHitBackForOrder:self.printOrder];
    }
#endif
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
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackShippingScreenHitBackForOrder:self.printOrder];
#endif
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

- (void)onButtonDoneClicked{
    if (![self hasUserProvidedValidDetailsToProgressToPayment]) {
        return;
    }
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackShippingScreenHitBackForOrder:self.printOrder];
#endif
    [self checkAndSaveAddress];
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)checkAndSaveAddress{
    [self.textFieldEmail resignFirstResponder];
    [self.textFieldPhone resignFirstResponder];
    
    NSString *email = [self userEmail];
    NSString *phone = [self userPhone];
    
    self.printOrder.email = email;
    self.printOrder.phone = phone;
    
    if (self.shippingAddresses.count == 1 || self.selectedShippingAddresses.count == 1){
        self.printOrder.shippingAddress = [self.selectedShippingAddresses firstObject];
    }
    else{
        self.printOrder.shippingAddress = nil;
    }
    
    [self.printOrder discardDuplicateJobs];
    [self.printOrder duplicateJobsForAddresses:self.selectedShippingAddresses];
    
    if (![self.kiteDelegate respondsToSelector:@selector(shouldStoreDeliveryAddresses)] || [self.kiteDelegate shouldStoreDeliveryAddresses]){
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:email forKey:kKeyEmailAddress];
        [defaults setObject:phone forKey:kKeyPhone];
        [defaults synchronize];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kOLNotificationUserSuppliedShippingDetails object:self userInfo:@{kOLKeyUserInfoPrintOrder: self.printOrder}];
}

- (void)onButtonNextClicked {
    if (![self hasUserProvidedValidDetailsToProgressToPayment]) {
        return;
    }
    [self checkAndSaveAddress];
    
    OLPaymentViewController *vc = [[OLPaymentViewController alloc] initWithPrintOrder:self.printOrder];
    vc.presentedModally = self.presentedModally;
    vc.delegate = self.delegate;
    vc.kiteDelegate = self.kiteDelegate;
    vc.showOtherOptions = self.showOtherOptions;
    
    [self.navigationController pushViewController:vc animated:YES];
}

- (void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
//    self.automaticallyAdjustsScrollViewInsets = NO;
//    self.tableView.contentInset = UIEdgeInsetsMake(self.edgeInsetTop, 0, 0, 0);
//    [self.tableView scrollRectToVisible:CGRectMake(0, 0, 10, 10) animated:NO];
    [self.tableView reloadData];
    if (self.kiteLabel){
        [self positionKiteLabel];
    }
}

+ (BOOL)validateEmail:(NSString *)candidate {
    NSString *emailRegex = @"(?:[a-zA-Z0-9!#$%\\&'*+/=?\\^_`{|}~-]+(?:\\.[a-zA-Z0-9!#$%\\&'*+/=?\\^_`{|}"
    @"~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\"
    @"x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-zA-Z0-9](?:[a-"
    @"z0-9-]*[a-zA-Z0-9])?\\.)+[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?|\\[(?:(?:25[0-5"
    @"]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-"
    @"9][0-9]?|[a-zA-Z0-9-]*[a-zA-Z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21"
    @"-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:candidate];
}

- (BOOL)hasUserProvidedValidDetailsToProgressToPayment {
    /*
     * Only progress to Payment screen if the user has supplied a valid Delivery Address, Email & Telephone number.
     * Otherwise highlight the error to the user.
     */
    if (self.shippingAddresses.count == 0 || self.selectedShippingAddresses.count == 0) {
        [self scrollSectionToVisible:kSectionDeliveryDetails];
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Missing Delivery Address", @"KitePrintSDK", [OLConstants bundle], @"") message:NSLocalizedStringFromTableInBundle(@"Please choose an address to have your order shipped to", @"KitePrintSDK", [OLConstants bundle], @"") delegate:nil cancelButtonTitle:NSLocalizedStringFromTableInBundle(@"OK", @"KitePrintSDK", [OLConstants bundle], @"") otherButtonTitles:nil];
        [av show];
        return NO;
    }
    
    if (![OLCheckoutViewController validateEmail:[self userEmail]]) {
        [self scrollSectionToVisible:kSectionEmailAddress];
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Invalid Email Address", @"KitePrintSDK", [OLConstants bundle], @"") message:NSLocalizedStringFromTableInBundle(@"Please enter a valid email address", @"KitePrintSDK", [OLConstants bundle], @"") delegate:nil cancelButtonTitle:NSLocalizedStringFromTableInBundle(@"OK", @"KitePrintSDK", [OLConstants bundle], @"") otherButtonTitles:nil];
        [av show];
        return NO;
    }
    
    if ([self userPhone].length < kMinPhoneNumberLength && [self showPhoneEntryField]) {
        [self scrollSectionToVisible:kSectionPhoneNumber];
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Invalid Phone Number", @"KitePrintSDK", [OLConstants bundle], @"") message:NSLocalizedStringFromTableInBundle(@"Please enter a valid phone number", @"KitePrintSDK", [OLConstants bundle], @"") delegate:nil cancelButtonTitle:NSLocalizedStringFromTableInBundle(@"OK", @"KitePrintSDK", [OLConstants bundle], @"") otherButtonTitles:nil];
        [av show];
        return NO;
    }
    
    return YES;
}

- (void)populateDefaultEmailAndPhone {
    if ([self.kiteDelegate respondsToSelector:@selector(shouldStoreDeliveryAddresses)] && ![self.kiteDelegate shouldStoreDeliveryAddresses]){
        self.textFieldEmail.text = self.printOrder.email;
        self.textFieldPhone.text = self.printOrder.phone;
        return;
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *email = [defaults stringForKey:kKeyEmailAddress];
    if (!email){
        email = _userEmail;
    }
    NSString *phone = [defaults stringForKey:kKeyPhone];
    if (!phone){
        phone = _userPhone;
    }
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


- (NSString *)userEmail {
    if (self.textFieldEmail == nil) {
        if ([self.kiteDelegate respondsToSelector:@selector(shouldStoreDeliveryAddresses)] && ![self.kiteDelegate shouldStoreDeliveryAddresses]){
            return @"";
        }
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *email = [defaults stringForKey:kKeyEmailAddress];
        return email ? email : @"";
    }
    
    return self.textFieldEmail.text;
}

- (NSString *)userPhone {
    if (self.textFieldPhone == nil) {
        if ([self.kiteDelegate respondsToSelector:@selector(shouldStoreDeliveryAddresses)] && ![self.kiteDelegate shouldStoreDeliveryAddresses]){
            return @"";
        }
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *phone = [defaults stringForKey:kKeyPhone];
        return phone ? phone : @"";
    }
    
    return self.textFieldPhone.text;
}

- (void)scrollSectionToVisible:(NSUInteger)section {
    CGRect sectionRect = [self.tableView rectForSection:section];
    [self.tableView scrollRectToVisible:sectionRect animated:YES];
}

- (BOOL)showPhoneEntryField {
    if ([self.kiteDelegate respondsToSelector:@selector(shouldShowPhoneEntryOnCheckoutScreen)]) {
        return [self.kiteDelegate shouldShowPhoneEntryOnCheckoutScreen]; // delegate overrides whatever the A/B test might say.
    }
    
    return [OLKiteABTesting sharedInstance].requirePhoneNumber;
}


#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self showPhoneEntryField] ? kSectionCount : kSectionCount - 1;
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
        return NSLocalizedStringFromTableInBundle(@"We'll send you confirmation and order updates.", @"KitePrintSDK", [OLConstants bundle], @"");
    } else if (section == kSectionPhoneNumber) {
        return NSLocalizedStringFromTableInBundle(@"Required by the postal service in case there are any issues during delivery.", @"KitePrintSDK", [OLConstants bundle], @"");
    }
    
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == kSectionDeliveryDetails) {
        return self.shippingAddresses.count + 1;
    } else if (section == kSectionEmailAddress) {
        return 1;
    } else if (section == kSectionPhoneNumber) {
        return 1;
    }
    
    return 0;
}

- (void)onButtonCheckboxClicked:(UIButton *)sender{
    self.printOrder.optOutOfEmail = !self.printOrder.optOutOfEmail;
    
    [sender setImage:self.printOrder.optOutOfEmail ? [UIImage imageNamedInKiteBundle:@"checkbox_off"] : [UIImage imageNamedInKiteBundle:@"checkbox_on"] forState:UIControlStateNormal];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    if (section == kSectionDeliveryDetails){
        return 0;
    }
    if (section == kSectionEmailAddress && ([[[UIDevice currentDevice] systemVersion] floatValue] < 8 || ![self.kiteDelegate respondsToSelector:@selector(shouldShowOptOutOfEmailsCheckbox)] || ![self.kiteDelegate shouldShowOptOutOfEmailsCheckbox])){
        return 28;
    }
    return 44;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    if (section != kSectionEmailAddress){
        return nil;
    }
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8 || ![self.kiteDelegate respondsToSelector:@selector(shouldShowOptOutOfEmailsCheckbox)] || ![self.kiteDelegate shouldShowOptOutOfEmailsCheckbox]){
        return nil;
    }
    
    UIView *cell = [[UIView alloc] init];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 11, 61, 21)];
    
    titleLabel.text = NSLocalizedStringFromTableInBundle(@"We'll send you confirmation and order updates. Uncheck this box to opt out of email campaigns.", @"KitePrintSDK", [OLConstants bundle], @"");
    titleLabel.adjustsFontSizeToFitWidth = YES;
    titleLabel.tag = kTagInputFieldLabel;
    titleLabel.numberOfLines = 3;
    titleLabel.font = [UIFont systemFontOfSize:13];
    //            cell.backgroundColor = [UIColor clearColor];
    titleLabel.textColor = [UIColor darkGrayColor];
    
    [cell addSubview:titleLabel];
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8){
        UIButton *checkbox = [[UIButton alloc] init];
        [checkbox setImage:self.printOrder.optOutOfEmail ? [UIImage imageNamedInKiteBundle:@"checkbox_off"] : [UIImage imageNamedInKiteBundle:@"checkbox_on"] forState:UIControlStateNormal];
        [checkbox addTarget:self action:@selector(onButtonCheckboxClicked:) forControlEvents:UIControlEventTouchUpInside];
        checkbox.translatesAutoresizingMaskIntoConstraints = NO;
        [titleLabel.superview addSubview:checkbox];
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        NSDictionary *views = NSDictionaryOfVariableBindings(titleLabel, checkbox);
        NSMutableArray *con = [[NSMutableArray alloc] init];
        
        NSArray *visuals = @[[NSString stringWithFormat:@"H:|-20-[titleLabel]-5-[checkbox(%f)]-20-|", checkbox.imageView.image.size.width],
                             @"V:[titleLabel(43)]",
                             @"V:[checkbox(43)]"];
        
        
        for (NSString *visual in visuals) {
            [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
        }
        
        NSLayoutConstraint *textFieldCenterY = [NSLayoutConstraint constraintWithItem:titleLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:titleLabel.superview attribute:NSLayoutAttributeCenterY multiplier:1 constant:0];
        NSLayoutConstraint *checkboxCenterY = [NSLayoutConstraint constraintWithItem:checkbox attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:checkbox.superview attribute:NSLayoutAttributeCenterY multiplier:1 constant:0];
        [con addObjectsFromArray:@[textFieldCenterY, checkboxCenterY]];
        
        [titleLabel.superview addConstraints:con];
    }
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    if (indexPath.section == kSectionDeliveryDetails) {
        static NSString *const kDeliveryAddressCell = @"DeliveryAddressCell";
        static NSString *const kAddDeliveryAddressCell = @"AddDeliveryAddressCell";
        
        if (self.shippingAddresses.count > indexPath.row) {
            cell = [tableView dequeueReusableCellWithIdentifier:kDeliveryAddressCell];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kDeliveryAddressCell];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
            }
            OLAddress *address = (OLAddress *)self.shippingAddresses[indexPath.row];
            cell.textLabel.textColor = [UIColor blackColor];
            cell.imageView.image = [self.selectedShippingAddresses containsObject:address] ? [UIImage imageNamedInKiteBundle:@"checkmark_on"] : [UIImage imageNamedInKiteBundle:@"checkmark_off"];
            cell.textLabel.text = [(OLAddress *)self.shippingAddresses[indexPath.row] fullNameFromFirstAndLast];
            cell.detailTextLabel.text = [address descriptionWithoutRecipient];
        } else {
            cell = [tableView dequeueReusableCellWithIdentifier:kAddDeliveryAddressCell];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kAddDeliveryAddressCell];
                cell.textLabel.adjustsFontSizeToFitWidth = YES;
                cell.textLabel.textColor = kColourLightBlue;
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
            }
            if (self.shippingAddresses.count > 0 && [OLKiteABTesting sharedInstance].allowsMultipleRecipients){
                cell.textLabel.text = NSLocalizedStringFromTableInBundle(@"Add Another Recipient", @"KitePrintSDK",[OLConstants bundle], @"");
            }
            else{
                cell.textLabel.text = NSLocalizedStringFromTableInBundle(@"Choose Delivery Address", @"KitePrintSDK", [OLConstants bundle], @"");
            }
        }
    } else if (indexPath.section == kSectionEmailAddress) {
        static NSString *const TextFieldCell = @"EmailFieldCell";
        cell = [tableView dequeueReusableCellWithIdentifier:TextFieldCell];
        if (cell == nil) {
            cell = [self createTextFieldCellWithReuseIdentifier:TextFieldCell title:NSLocalizedStringFromTableInBundle(@"Email", @"KitePrintSDK", [OLConstants bundle], @"")  keyboardType:UIKeyboardTypeEmailAddress];
            self.textFieldEmail = (UITextField *) [cell viewWithTag:kInputFieldTag];
            self.textFieldEmail.autocapitalizationType = UITextAutocapitalizationTypeNone;
            self.textFieldEmail.autocorrectionType = UITextAutocorrectionTypeNo;
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
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 11, 61, 21)];
    
    titleLabel.text = title;
    titleLabel.adjustsFontSizeToFitWidth = YES;
    titleLabel.tag = kTagInputFieldLabel;
    UITextField *inputField = [[UITextField alloc] initWithFrame:CGRectMake(86, 0, [UIScreen mainScreen].bounds.size.width - 86, 43)];
    inputField.delegate = self;
    inputField.tag = kInputFieldTag;
    [inputField setKeyboardType:type];
    [inputField setReturnKeyType:UIReturnKeyNext];
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

- (BOOL) tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section != kSectionDeliveryDetails){
        return NO;
    }
    return indexPath.row < self.shippingAddresses.count;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.selectedShippingAddresses removeObject:self.shippingAddresses[indexPath.row]];
        [self.shippingAddresses removeObjectAtIndex:indexPath.row];
        [self.tableView reloadSections:[[NSIndexSet alloc] initWithIndex:kSectionDeliveryDetails] withRowAnimation:UITableViewRowAnimationFade];
    }
}


#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == kSectionDeliveryDetails) {
        if ([OLKiteABTesting sharedInstance].offerAddressSearch || [OLAddress addressBook].count > 0 || [OLKiteABTesting sharedInstance].allowsMultipleRecipients) {
            if ([OLKiteABTesting sharedInstance].allowsMultipleRecipients && self.shippingAddresses.count > indexPath.row){
                OLAddress *address = self.shippingAddresses[indexPath.row];
                BOOL selected = YES;
                if ([self.selectedShippingAddresses containsObject:address]) {
                    selected = NO;
                    [self.selectedShippingAddresses removeObject:address];
                } else {
                    [self.selectedShippingAddresses addObject:address];
                }
                
                UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                cell.imageView.image = selected ? [UIImage imageNamedInKiteBundle:@"checkmark_on"] : [UIImage imageNamedInKiteBundle:@"checkmark_off"];
            }
            else{
                OLAddressPickerController *addressPicker = [[OLAddressPickerController alloc] init];
                addressPicker.delegate = self;
                addressPicker.allowsAddressSearch = [OLKiteABTesting sharedInstance].offerAddressSearch;
                addressPicker.allowsMultipleSelection = [OLKiteABTesting sharedInstance].allowsMultipleRecipients;
                addressPicker.selected = self.shippingAddresses;
                addressPicker.modalPresentationStyle = [OLKiteUtils kiteVcForViewController:self].modalPresentationStyle;
                [self presentViewController:addressPicker animated:YES completion:nil];
            }
        } else {
            OLAddressEditViewController *editVc = [[OLAddressEditViewController alloc] init];
            editVc.delegate = self;
            UINavigationController *nvc = [[UINavigationController alloc] initWithRootViewController:editVc];
            nvc.modalPresentationStyle = [OLKiteUtils kiteVcForViewController:self].modalPresentationStyle;
            [self presentViewController:nvc animated:YES completion:nil];
        }
    }
}

#pragma mark - UITextFieldDelegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.textFieldEmail && [self showPhoneEntryField]) {
        [self.textFieldPhone becomeFirstResponder];
    }
    else{
        [textField resignFirstResponder];
    }
    
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.activeTextView = textField;
}

- (void)recalculateOrderCostIfNewSelectedCountryDiffers:(NSArray *)selectedCountries {
    //    if (self.printOrder.shippingAddress == nil) {
    //        // just populate with a blank address for now with default local country -- this will get replaced on filling out address and proceeding to the next screen
    //        self.printOrder.shippingAddress = [[OLAddress alloc] init];
    //        self.printOrder.shippingAddress.country = self.shippingAddress ? self.shippingAddress.country : [OLCountry countryForCurrentLocale];
    //    }
    //
    //    NSMutableArray *countries = [[NSMutableArray alloc] init];
    //    for (OLAddress *address in self.printOrder.shippingAddress){
    //        [countries addObject:address.country];
    //    }
    //    if (![countries isEqualToArray:selectedCountries]) {
    //        // changing destination address voids internal printOrder cached costs, recalc early to speed things up before we hit the Payment screen
    //        [self.printOrder costWithCompletionHandler:nil]; // ignore outcome, internally printOrder caches the result and this will speed up things when we hit the PaymentScreen
    //    }
}

#pragma mark - OLAddressPickerController delegate

- (void)addressPicker:(OLAddressPickerController *)picker didFinishPickingAddresses:(NSArray/*<OLAddress>*/ *)addresses {
    [self.shippingAddresses removeAllObjects];
    [self.selectedShippingAddresses removeAllObjects];
    for (OLAddress *address in addresses){
        OLAddress *addressCopy = [address copy];
        [self.shippingAddresses addObject:addressCopy];
        [self.selectedShippingAddresses addObject:addressCopy];
    }
    
    NSMutableArray *countries = [[NSMutableArray alloc] init];
    for (OLAddress *address in addresses){
        [countries addObject:address.country];
    }
    [self recalculateOrderCostIfNewSelectedCountryDiffers:addresses];
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.tableView reloadSections:[[NSIndexSet alloc] initWithIndex:kSectionDeliveryDetails] withRowAnimation:UITableViewRowAnimationFade];
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

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8) {
        return UIInterfaceOrientationMaskAll;
    }
    else{
        return UIInterfaceOrientationMaskPortrait;
    }
}

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification*)aNotification
{
    
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(self.edgeInsetTop, 0.0, kbSize.height, 0.0);
    [UIView animateWithDuration:0.1 animations:^{
        self.tableView.contentInset = contentInsets;
        self.tableView.scrollIndicatorInsets = contentInsets;
    }];
    
    // If active text field is hidden by keyboard, scroll it so it's visible
    // Your application might not need or want this behavior.
    CGRect aRect = self.view.frame;
    aRect.size.height -= kbSize.height;
    CGPoint p = self.activeTextView.superview.frame.origin;
    if (!CGRectContainsPoint(aRect, CGPointMake(p.x, p.y + self.activeTextView.frame.size.height)) ) {
        CGPoint scrollPoint = CGPointMake(0.0, self.activeTextView.superview.frame.origin.y-kbSize.height);
        [self.tableView setContentOffset:scrollPoint animated:YES];
    }
    
}

// Called when the UIKeyboardWillHideNotification is received
- (void)keyboardWillBeHidden:(NSNotification *)aNotification
{
    // scroll back..
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(self.edgeInsetTop, 0, 0, 0);
    self.tableView.contentInset = contentInsets;
    self.tableView.scrollIndicatorInsets = contentInsets;
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
