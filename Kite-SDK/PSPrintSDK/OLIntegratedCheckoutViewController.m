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

#import "OLIntegratedCheckoutViewController.h"
#import "OLAddressEditViewController.h"
#import "OLPaymentViewController.h"
#import "OLCountry.h"
#import "OLPrintOrder.h"
#import "OLProductTemplate.h"
#import "OLCountryPickerController.h"
#import "OLConstants.h"
#import "OLAnalytics.h"
#import "OLKiteUtils.h"
#import "OLKiteViewController.h"
#import "UIImage+ImageNamedInKiteBundle.h"

static const NSUInteger kSectionDeliveryDetails = 0;
static const NSUInteger kSectionEmail = 1;
static const NSUInteger kSectionPhone = 2;

static const NSUInteger kTagTextField = 99;

static NSString *const kKeyEmailAddress = @"co.oceanlabs.pssdk.kKeyEmailAddress";
static NSString *const kKeyPhone = @"co.oceanlabs.pssdk.kKeyPhone";
static NSString *const kKeyRecipientName = @"co.oceanlabs.pssdk.kKeyRecipientName";
static NSString *const kKeyRecipientFirstName = @"co.oceanlabs.pssdk.kKeyRecipientFirstName";
static NSString *const kKeyLine1 = @"co.oceanlabs.pssdk.kKeyLine1";
static NSString *const kKeyLine2 = @"co.oceanlabs.pssdk.kKeyLine2";
static NSString *const kKeyCity = @"co.oceanlabs.pssdk.kKeyCity";
static NSString *const kKeyCounty = @"co.oceanlabs.pssdk.kKeyCounty";
static NSString *const kKeyPostCode = @"co.oceanlabs.pssdk.kKeyPostCode";
static NSString *const kKeyCountry = @"co.oceanlabs.pssdk.kKeyCountry";

@interface OLCheckoutViewController (PrivateMethods)

@property (strong, nonatomic) UITextField *textFieldEmail, *textFieldPhone;
- (void)onBackgroundClicked;
- (BOOL)hasUserProvidedValidDetailsToProgressToPayment;
- (BOOL)showPhoneEntryField;
- (NSString *)userEmail;
- (NSString *)userPhone;
- (void)recalculateOrderCostIfNewSelectedCountryDiffers:(OLCountry *)selectedCountry;
- (void)onButtonCheckboxClicked:(UIButton *)sender;

@end

@interface OLIntegratedCheckoutViewController () <UITextFieldDelegate, OLCountryPickerControllerDelegate, UINavigationControllerDelegate, UITableViewDelegate>

@property (nonatomic, strong) UITextField *textFieldFirstName, *textFieldLastName, *textFieldLine1, *textFieldLine2, *textFieldCity, *textFieldCounty, *textFieldPostCode, *textFieldCountry;
@property (weak, nonatomic) UITextField *activeTextView;

@end

@implementation OLIntegratedCheckoutViewController

@dynamic textFieldEmail;
@dynamic textFieldPhone;
@dynamic printOrder;

-(OLAddress *) shippingAddress{
    if (!self.shippingAddresses){
        self.shippingAddresses = [[NSMutableArray alloc] initWithCapacity:1];
        self.selectedShippingAddresses = [[NSMutableArray alloc] initWithCapacity:1];
    }
    if (self.shippingAddresses.count == 0){
        [self.shippingAddresses addObject:[[OLAddress alloc] init]];
        [self.selectedShippingAddresses addObject:self.shippingAddresses.firstObject];
    }
    return self.shippingAddresses.firstObject;
}

- (id)initWithPrintOrder:(OLPrintOrder *)printOrder {
    if (self = [super initWithStyle:UITableViewStyleGrouped]) {
        self.printOrder = printOrder;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [self populateDefaultDeliveryAddress]; // call before super as this sets printOrder.shippingAddress if necessary & super gets & caches cost for shipping address
    [super viewDidLoad];
}

- (void)trackViewed{
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackShippingScreenViewedForOrder:self.printOrder variant:@"Integrated" showPhoneEntryField:[self showPhoneEntryField]];
#endif
}

-(BOOL)isValidAddress{
    BOOL flag = YES;
    NSString *errorMessage;
    if ([self.textFieldFirstName.text isEqualToString:@""] || [self.textFieldLastName.text isEqualToString:@""]){
        flag = NO;
        errorMessage = NSLocalizedString(@"Please enter your first and last name.", @"");
    }
    else if ([self.textFieldLine1.text isEqualToString:@""]){
        flag = NO;
        errorMessage = NSLocalizedString(@"Please fill in Line 1 of the address.", @"");
    }
    else if ([self.textFieldPostCode.text isEqualToString:@""]){
        flag = NO;
        errorMessage = NSLocalizedString(@"Please fill in your postal code", @"");
    }
    
    if (!flag){
        if ([UIAlertController class]) // iOS 8 or greater
        {
            UIAlertController *alert= [UIAlertController
                                       alertControllerWithTitle:NSLocalizedString(@"", @"")
                                       message:errorMessage
                                       preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction* ok = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"") style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * action){}];
            
            [alert addAction:ok];
            [self presentViewController:alert animated:YES completion:nil];
        }
        else{
            UIAlertView* dialog = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"", @"")
                                                             message:errorMessage
                                                            delegate:self
                                                   cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil, nil];
            [dialog show];
        }
    }
    
    
    return flag;
}

- (NSString *)addrFirstName {
    return self.textFieldFirstName ? self.textFieldFirstName.text : self.shippingAddress.recipientFirstName;
}

- (NSString *)addrLastName {
    return self.textFieldLastName ? self.textFieldLastName.text : self.shippingAddress.recipientLastName;
}

- (NSString *)addrLine1 {
    return self.textFieldLine1 ? self.textFieldLine1.text : self.shippingAddress.line1;
}

- (NSString *)addrLine2 {
    return self.textFieldLine2 ? self.textFieldLine2.text : self.shippingAddress.line2;
}

- (NSString *)addrCity {
    return self.textFieldCity ? self.textFieldCity.text : self.shippingAddress.city;
}

- (NSString *)addrCounty {
    return self.textFieldCounty ? self.textFieldCounty.text : self.shippingAddress.stateOrCounty;
}

- (NSString *)addrPostCode {
    return self.textFieldPostCode ? self.textFieldPostCode.text : self.shippingAddress.zipOrPostcode;
}

- (OLCountry *)addrCountry {
    return self.shippingAddress.country;
}

- (void)populateDefaultDeliveryAddress {
    if (![self.kiteDelegate respondsToSelector:@selector(shouldStoreDeliveryAddresses)] || [self.kiteDelegate shouldStoreDeliveryAddresses]){
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *firstName = [defaults stringForKey:kKeyRecipientFirstName];
        NSString *lastName = [defaults stringForKey:kKeyRecipientName];
        NSString *line1 = [defaults stringForKey:kKeyLine1];
        NSString *line2 = [defaults stringForKey:kKeyLine2];
        NSString *city = [defaults stringForKey:kKeyCity];
        NSString *county = [defaults stringForKey:kKeyCounty];
        NSString *postCode= [defaults stringForKey:kKeyPostCode];
        NSString *country = [defaults stringForKey:kKeyCountry];
        
        self.shippingAddress.recipientFirstName = firstName;
        self.shippingAddress.recipientLastName = lastName;
        self.shippingAddress.line1 = line1;
        self.shippingAddress.line2 = line2;
        self.shippingAddress.city = city;
        self.shippingAddress.stateOrCounty = county;
        self.shippingAddress.zipOrPostcode = postCode;
        self.shippingAddress.country = [OLCountry countryForCode:country];
    }
    
    if (self.shippingAddress.country == nil) {
        self.shippingAddress.country = [OLCountry countryForCurrentLocale];
    }
}

- (void)onBackgroundClicked {
    [self.textFieldFirstName resignFirstResponder];
    [self.textFieldLastName resignFirstResponder];
    [self.textFieldLine1 resignFirstResponder];
    [self.textFieldLine2 resignFirstResponder];
    [self.textFieldCounty resignFirstResponder];
    [self.textFieldPostCode resignFirstResponder];
    [self.textFieldCountry resignFirstResponder];
    [super onBackgroundClicked];
}

- (BOOL)hasUserProvidedValidDetailsToProgressToPayment{
    if (![self isValidAddress]){
        return NO;
    }
    return [super hasUserProvidedValidDetailsToProgressToPayment];
}

- (void)onButtonNextClicked{
    self.printOrder.shippingAddress = self.shippingAddress;
    
    if (![self hasUserProvidedValidDetailsToProgressToPayment]) {
        return;
    }
    
    [self.textFieldEmail resignFirstResponder];
    [self.textFieldPhone resignFirstResponder];
    
    [self saveAddress];
    
    NSString *email = [super userEmail];
    NSString *phone = [super userPhone];
    
    self.printOrder.email = email;
    self.printOrder.phone = phone;
    
    OLPaymentViewController *vc = [[OLPaymentViewController alloc] initWithPrintOrder:self.printOrder];
    vc.delegate = self.delegate;
    
    if (![self.kiteDelegate respondsToSelector:@selector(shouldStoreDeliveryAddresses)] || [self.kiteDelegate shouldStoreDeliveryAddresses]){
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:email forKey:kKeyEmailAddress];
        [defaults setObject:phone forKey:kKeyPhone];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kOLNotificationUserSuppliedShippingDetails object:self userInfo:@{kOLKeyUserInfoPrintOrder: self.printOrder}];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)saveAddress{
    if ([self.kiteDelegate respondsToSelector:@selector(shouldStoreDeliveryAddresses)] && ![self.kiteDelegate shouldStoreDeliveryAddresses]){
        return;
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSString *email = [super userEmail];
    NSString *phone = [super userPhone];
    NSString *firstName = [self addrFirstName];
    NSString *lastName = [self addrLastName];
    NSString *line1 = [self addrLine1];
    NSString *line2 = [self addrLine2];
    NSString *city = [self addrCity];
    NSString *county = [self addrCounty];
    NSString *postCode = [self addrPostCode];
    NSString *country = [self addrCountry].codeAlpha3;
    
    [defaults setObject:email forKey:kKeyEmailAddress];
    [defaults setObject:phone forKey:kKeyPhone];
    [defaults setObject:firstName forKey:kKeyRecipientFirstName];
    [defaults setObject:lastName forKey:kKeyRecipientName];
    [defaults setObject:line1 forKey:kKeyLine1];
    [defaults setObject:line2 forKey:kKeyLine2];
    [defaults setObject:city forKey:kKeyCity];
    [defaults setObject:county forKey:kKeyCounty];
    [defaults setObject:postCode forKey:kKeyPostCode];
    [defaults setObject:country forKey:kKeyCountry];
    
    [defaults synchronize];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    if (indexPath.section == kSectionDeliveryDetails) {
        static NSString *const kAddDeliveryAddressCell = @"AddDeliveryAddressCell";
        
        cell = [tableView dequeueReusableCellWithIdentifier:kAddDeliveryAddressCell];
        if (!cell) {
            cell = [self createTextFieldCellWithReuseIdentifier:kAddDeliveryAddressCell title:@"" keyboardType:UIKeyboardTypeAlphabet];
        }
        
        UITextField *tf = (UITextField *) [cell viewWithTag:kTagTextField];
        tf.enabled = YES;
        tf.returnKeyType = UIReturnKeyNext;
        cell.accessoryType = UITableViewCellAccessoryNone;
        tf.autocapitalizationType = UITextAutocapitalizationTypeWords;
        tf.autocorrectionType = UITextAutocorrectionTypeNo;
        tf.delegate = self;
        switch (indexPath.row) {
            case 0:
                [tf.superview removeConstraints:tf.superview.constraints];
                tf.translatesAutoresizingMaskIntoConstraints = YES;
                tf.text = self.shippingAddress.recipientFirstName;
                tf.frame = CGRectMake(20, 0, ((cell.frame.size.width - 20) / 2.0)-10, cell.frame.size.height);
                tf.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedStringFromTableInBundle(@"First Name", @"KitePrintSDK", [NSBundle mainBundle], @"") attributes:@{NSForegroundColorAttributeName : [UIColor colorWithRed:108.0/255.0 green:108.0/255.0 blue:108.0/255.0 alpha:1]}];
                self.textFieldFirstName = tf;
                self.textFieldFirstName.tag = 1000;
                
                self.textFieldLastName = [[UITextField alloc] initWithFrame:CGRectMake(((cell.frame.size.width - 20) / 2.0)+20, 0, (cell.frame.size.width - 20) / 2.0, cell.frame.size.height)];
                [cell.contentView addSubview:self.textFieldLastName];
                self.textFieldLastName.text = self.shippingAddress.recipientLastName;
                self.textFieldLastName.returnKeyType = UIReturnKeyNext;
                self.textFieldLastName.adjustsFontSizeToFitWidth = YES;
                self.textFieldLastName.textColor = [UIColor blackColor];
                self.textFieldLastName.autocorrectionType = UITextAutocorrectionTypeNo;
                self.textFieldLastName.textAlignment = NSTextAlignmentLeft;
                self.textFieldLastName.tag = kTagTextField;
                self.textFieldLastName.clearButtonMode = UITextFieldViewModeNever;
                self.textFieldLastName.delegate = self;
                self.textFieldLastName.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedStringFromTableInBundle(@"Last Name", @"KitePrintSDK", [NSBundle mainBundle], @"") attributes:@{NSForegroundColorAttributeName : [UIColor colorWithRed:108.0/255.0 green:108.0/255.0 blue:108.0/255.0 alpha:1]}];
                
                if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8){
                    UIView *view = self.textFieldLastName;
                    view.translatesAutoresizingMaskIntoConstraints = NO;
                    tf.translatesAutoresizingMaskIntoConstraints = NO;
                    NSDictionary *views = NSDictionaryOfVariableBindings(view, tf);
                    NSMutableArray *con = [[NSMutableArray alloc] init];
                    
                    NSArray *visuals = @[@"H:|-20-[tf]-0-[view]-0-|"];
                    
                    
                    for (NSString *visual in visuals) {
                        [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
                    }
                    
                    NSLayoutConstraint *centerY = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:view.superview attribute:NSLayoutAttributeCenterY multiplier:1 constant:0];
                    [con addObject:centerY];
                    
                    [cell addConstraints:con];
                    
                    centerY = [NSLayoutConstraint constraintWithItem:tf attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:tf.superview attribute:NSLayoutAttributeCenterY multiplier:1 constant:0];
                    [cell addConstraint:centerY];
                    
                    [cell addConstraint:[NSLayoutConstraint constraintWithItem:tf attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.textFieldLastName attribute:NSLayoutAttributeWidth multiplier:1 constant:0]];
                }
                
                break;
            case 1:
                tf.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedStringFromTableInBundle(@"Line 1", @"KitePrintSDK", [NSBundle mainBundle], @"") attributes:@{NSForegroundColorAttributeName : [UIColor colorWithRed:108.0/255.0 green:108.0/255.0 blue:108.0/255.0 alpha:1]}];
                tf.text = self.shippingAddress.line1;
                self.textFieldLine1 = tf;
                break;
            case 2:
                tf.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedStringFromTableInBundle(@"Line 2", @"KitePrintSDK", [NSBundle mainBundle], @"") attributes:@{NSForegroundColorAttributeName : [UIColor colorWithRed:108.0/255.0 green:108.0/255.0 blue:108.0/255.0 alpha:1]}];
                tf.text = self.shippingAddress.line2;
                self.textFieldLine2 = tf;
                break;
            case 3:
                tf.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedStringFromTableInBundle(@"City", @"KitePrintSDK", [NSBundle mainBundle], @"") attributes:@{NSForegroundColorAttributeName : [UIColor colorWithRed:108.0/255.0 green:108.0/255.0 blue:108.0/255.0 alpha:1]}];
                tf.text = self.shippingAddress.city;
                self.textFieldCity = tf;
                break;
            case 4:
                if (self.shippingAddress.country == [OLCountry countryForCode:@"USA"]) {
                    tf.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedStringFromTableInBundle(@"State", @"KitePrintSDK", [NSBundle mainBundle], @"") attributes:@{NSForegroundColorAttributeName : [UIColor colorWithRed:108.0/255.0 green:108.0/255.0 blue:108.0/255.0 alpha:1]}];
                } else {
                    tf.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedStringFromTableInBundle(@"County", @"KitePrintSDK", [NSBundle mainBundle], @"") attributes:@{NSForegroundColorAttributeName : [UIColor colorWithRed:108.0/255.0 green:108.0/255.0 blue:108.0/255.0 alpha:1]}];
                }
                tf.text = self.shippingAddress.stateOrCounty;
                self.textFieldCounty = tf;
                break;
            case 5:
                if (self.shippingAddress.country == [OLCountry countryForCode:@"USA"]) {
                    tf.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedStringFromTableInBundle(@"ZIP Code", @"KitePrintSDK", [NSBundle mainBundle], @"") attributes:@{NSForegroundColorAttributeName : [UIColor colorWithRed:108.0/255.0 green:108.0/255.0 blue:108.0/255.0 alpha:1]}];
                } else {
                    tf.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedStringFromTableInBundle(@"Postcode", @"KitePrintSDK", [NSBundle mainBundle], @"") attributes:@{NSForegroundColorAttributeName : [UIColor colorWithRed:108.0/255.0 green:108.0/255.0 blue:108.0/255.0 alpha:1]}];
                }
                tf.text = self.shippingAddress.zipOrPostcode;
                tf.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
                self.textFieldPostCode = tf;
                break;
            case 6:
                tf.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedStringFromTableInBundle(@"Country", @"KitePrintSDK", [NSBundle mainBundle], @"") attributes:@{NSForegroundColorAttributeName : [UIColor colorWithRed:108.0/255.0 green:108.0/255.0 blue:108.0/255.0 alpha:1]}];
                tf.text = self.shippingAddress.country.name;
                tf.enabled = NO;
                [tf setNeedsLayout];
                [tf setNeedsDisplay];
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                tf.returnKeyType = UIReturnKeyDone;
                self.textFieldCountry = tf;
                break;
        }

    } else{
        cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
        UITextField *tf = (UITextField *) [cell viewWithTag:kTagTextField];
        NSString *s;
        if (indexPath.section == kSectionEmail){
            s = NSLocalizedString(@"Email", @"");
        }
        else if (indexPath.section == kSectionPhone){
            s = NSLocalizedString(@"Phone", @"");
        }
        else{
            s = @"";
        }
        tf.attributedPlaceholder = [[NSAttributedString alloc] initWithString:s attributes:@{NSForegroundColorAttributeName : [UIColor colorWithRed:108.0/255.0 green:108.0/255.0 blue:108.0/255.0 alpha:1]}];
        
    }
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == kSectionDeliveryDetails) {
        return 7;
    } else {
        return [super tableView:tableView numberOfRowsInSection:section];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == kSectionDeliveryDetails) {
        if (indexPath.row == 6) {
            
            OLCountryPickerController *controller = [[OLCountryPickerController alloc] init];
            controller.delegate = self;

            if (!self.shippingAddress.country){
                self.shippingAddress.country = [OLCountry countryForCode:@"GBR"];
                controller.selected = @[self.shippingAddress.country];
            }
            controller.modalPresentationStyle = [OLKiteUtils kiteVcForViewController:self].modalPresentationStyle;
            [self presentViewController:controller animated:YES completion:nil];
        }
        
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == kSectionDeliveryDetails) {
        return NSLocalizedStringFromTableInBundle(@"Delivery Address", @"KitePrintSDK", [OLConstants bundle], @"");
    } else {
        return nil;
    }
}

-(void) saveAddressFromTextField:(UITextField *)textField{
    UIView* view = textField.superview;
    while (![view isKindOfClass:[UITableViewCell class]]){
        view = view.superview;
    }
    NSIndexPath* indexPath = [self.tableView indexPathForCell:(UITableViewCell*)view];
    if (indexPath.section == kSectionDeliveryDetails){
        switch (indexPath.row) {
            case 0:
                if (textField.tag == 1000){
                    self.shippingAddress.recipientFirstName = self.textFieldFirstName.text;
                }
                else{
                    self.shippingAddress.recipientLastName = textField.text;
                }
                break;
            case 1:
                self.shippingAddress.line1 = textField.text;
                break;
            case 2:
                self.shippingAddress.line2 = textField.text;
                break;
            case 3:
                self.shippingAddress.city = textField.text;
                break;
            case 4:
                self.shippingAddress.stateOrCounty = textField.text;
                break;
            case 5:
                self.shippingAddress.zipOrPostcode = textField.text;
                break;
            case 6:
//                self.shippingAddress.country = [OLCountry countryForCode:textField.text];
                break;
            default:
                break;
        }
        [self saveAddress];
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    [self saveAddressFromTextField:textField];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField{
    [self saveAddressFromTextField:textField];
    self.activeTextView = nil;
}

-(void) countryPicker:(OLCountryPickerController *)picker didSucceedWithCountries:(NSArray *)countries{
    [super recalculateOrderCostIfNewSelectedCountryDiffers:countries.lastObject];
    
    [self dismissViewControllerAnimated:YES completion:nil];
    self.shippingAddress.country = countries.lastObject;
    self.textFieldCountry.text = self.shippingAddress.country.name;
    [self.tableView reloadData]; // refesh labels if country has changed i.e. Postal Code -> ZIP Code if UK -> USA.
    
    
}

-(void) countryPickerDidCancelPicking:(OLCountryPickerController *)picker{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.textFieldFirstName) {
        [self.textFieldLastName becomeFirstResponder];
    } else if (textField == self.textFieldLastName){
        [self.textFieldLine1 becomeFirstResponder];
    } else if (textField == self.textFieldLine1) {
        [self.textFieldLine2 becomeFirstResponder];
    } else if (textField == self.textFieldLine2) {
        [self.textFieldCity becomeFirstResponder];
    } else if (textField == self.textFieldCity) {
        [self.textFieldCounty becomeFirstResponder];
    } else if (textField == self.textFieldCounty) {
        [self.textFieldPostCode becomeFirstResponder];
    } else if (textField == self.textFieldPostCode) {
        [self.textFieldEmail becomeFirstResponder];
    } else if (textField == self.textFieldCountry) {
        
    } else if (textField == self.textFieldEmail && [super showPhoneEntryField]) {
        [self.textFieldPhone becomeFirstResponder];
    }
    else{
        [textField resignFirstResponder];
    }
    [self saveAddressFromTextField:textField];
    return YES;
}

- (UITableViewCell *)createTextFieldCellWithReuseIdentifier:(NSString *)identifier title:(NSString *)title keyboardType:(UIKeyboardType)type {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithFrame:CGRectMake(20, 0, [UIScreen mainScreen].bounds.size.width, 43)];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    UITextField *inputField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 43)];
    inputField.delegate = self;
    inputField.tag = kInputFieldTag;
    [inputField setKeyboardType:type];
    [inputField setReturnKeyType:UIReturnKeyNext];
    [cell addSubview:inputField];
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8){
        UIView *view = inputField;
        view.translatesAutoresizingMaskIntoConstraints = NO;
        NSDictionary *views = NSDictionaryOfVariableBindings(view);
        NSMutableArray *con = [[NSMutableArray alloc] init];
        
        NSArray *visuals = @[@"H:|-20-[view]-0-|", @"V:[view(43)]"];
        
        
        for (NSString *visual in visuals) {
            [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
        }
        
        NSLayoutConstraint *centerY = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:view.superview attribute:NSLayoutAttributeCenterY multiplier:1 constant:0];
        [con addObject:centerY];
        
        [view.superview addConstraints:con];
    }
    
    
    return cell;
}

//-(CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
//    if (indexPath.section == kSectionDeliveryDetails) {
//    return 400;
//    }
//    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
//}


@end
