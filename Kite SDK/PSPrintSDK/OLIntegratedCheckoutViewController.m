//
//  IntegratedCheckoutViewController.m
//  HuggleUp
//
//  Created by Kostas Karayannis on 08/08/2014.
//  Copyright (c) 2014 Ocean Labs. All rights reserved.
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

static const NSUInteger kSectionDeliveryDetails = 0;

static const NSUInteger kTagTextField = 99;
static const NSUInteger kTagLabel = 100;

static NSString *const kKeyEmailAddress = @"co.oceanlabs.pssdk.kKeyEmailAddress";
static NSString *const kKeyPhone = @"co.oceanlabs.pssdk.kKeyPhone";
static NSString *const kKeyRecipientName = @"co.oceanlabs.pssdk.kKeyRecipientName";
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
- (void)setupABTestVariants;
- (NSString *)userEmail;
- (NSString *)userPhone;
- (void)recalculateOrderCostIfNewSelectedCountryDiffers:(OLCountry *)selectedCountry;

@end

@interface OLIntegratedCheckoutViewController () <UITextFieldDelegate, OLCountryPickerControllerDelegate, UINavigationControllerDelegate, UITableViewDelegate>

@property (nonatomic, strong) UITextField *textFieldName, *textFieldLine1, *textFieldLine2, *textFieldCity, *textFieldCounty, *textFieldPostCode, *textFieldCountry;
@property (weak, nonatomic) UITextField *activeTextView;

@end

@implementation OLIntegratedCheckoutViewController

@dynamic shippingAddress;
@dynamic textFieldEmail;
@dynamic textFieldPhone;
@dynamic printOrder;

- (id)initWithPrintOrder:(OLPrintOrder *)printOrder {
    if (self = [super initWithStyle:UITableViewStyleGrouped]) {
        self.printOrder = printOrder;
        //[self.printOrder preemptAssetUpload];
        [super setupABTestVariants];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self populateDefaultDeliveryAddress];
}

- (void)trackViewed{
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackShippingScreenViewedForOrder:self.printOrder variant:@"Integrated" showPhoneEntryField:[self showPhoneEntryField]];
#endif
}

-(BOOL)isValidAddress{
    BOOL flag = YES;
    NSString *errorMessage;
    if ([self.textFieldName.text isEqualToString:@""]){
        flag = NO;
        errorMessage = NSLocalizedString(@"Please enter your full name.", @"");
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

- (NSString *)addrName {
    return self.textFieldName ? self.textFieldName.text : self.shippingAddress.recipientName;
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
    if (!self.shippingAddress){
        self.shippingAddress = [[OLAddress alloc] init];
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *name = [defaults stringForKey:kKeyRecipientName];
    NSString *line1 = [defaults stringForKey:kKeyLine1];
    NSString *line2 = [defaults stringForKey:kKeyLine2];
    NSString *city = [defaults stringForKey:kKeyCity];
    NSString *county = [defaults stringForKey:kKeyCounty];
    NSString *postCode= [defaults stringForKey:kKeyPostCode];
    NSString *country = [defaults stringForKey:kKeyCountry];
    
    self.shippingAddress.recipientName = name;
    self.shippingAddress.line1 = line1;
    self.shippingAddress.line2 = line2;
    self.shippingAddress.city = city;
    self.shippingAddress.stateOrCounty = county;
    self.shippingAddress.zipOrPostcode = postCode;
    self.shippingAddress.country = [OLCountry countryForCode:country];
    
    if (self.shippingAddress.country == nil) {
        self.shippingAddress.country = [OLCountry countryForCurrentLocale];
    }
}

- (void)onBackgroundClicked {
    [self.textFieldName resignFirstResponder];
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
    if (![self hasUserProvidedValidDetailsToProgressToPayment]) {
        return;
    }
    
    [self.textFieldEmail resignFirstResponder];
    [self.textFieldPhone resignFirstResponder];
    
    [self saveAddress];
    
    NSString *email = [super userEmail];
    NSString *phone = [super userPhone];
    
    
    NSMutableDictionary *d = [[NSMutableDictionary alloc] init];
    if (self.printOrder.userData) {
        d = [self.printOrder.userData mutableCopy];
    }
    
    d[@"email"] = email;
    d[@"phone"] = phone;
    self.printOrder.userData = d;
    
    self.printOrder.shippingAddress = self.shippingAddress;
    OLPaymentViewController *vc = [[OLPaymentViewController alloc] initWithPrintOrder:self.printOrder];
    vc.delegate = self.delegate;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:email forKey:kKeyEmailAddress];
    [defaults setObject:phone forKey:kKeyPhone];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kOLNotificationUserSuppliedShippingDetails object:self userInfo:@{kOLKeyUserInfoPrintOrder: self.printOrder}];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)saveAddress{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSString *email = [super userEmail];
    NSString *phone = [super userPhone];
    NSString *name = [self addrName];
    NSString *line1 = [self addrLine1];
    NSString *line2 = [self addrLine2];
    NSString *city = [self addrCity];
    NSString *county = [self addrCounty];
    NSString *postCode = [self addrPostCode];
    NSString *country = [self addrCountry].codeAlpha3;
    
    [defaults setObject:email forKey:kKeyEmailAddress];
    [defaults setObject:phone forKey:kKeyPhone];
    [defaults setObject:name forKey:kKeyRecipientName];
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
        UILabel *label = (UILabel *) [cell viewWithTag:kTagLabel];
        tf.enabled = YES;
        tf.returnKeyType = UIReturnKeyNext;
        cell.accessoryType = UITableViewCellAccessoryNone;
        tf.autocapitalizationType = UITextAutocapitalizationTypeWords;
        tf.autocorrectionType = UITextAutocorrectionTypeNo;
        tf.delegate = self;
        switch (indexPath.row) {
            case 0:
                label.text = NSLocalizedStringFromTableInBundle(@"Name", @"KitePrintSDK", [NSBundle mainBundle], @"");
                tf.text = self.shippingAddress.recipientName;
                self.textFieldName = tf;
                break;
            case 1:
                label.text = NSLocalizedStringFromTableInBundle(@"Line 1", @"KitePrintSDK", [NSBundle mainBundle], @"");
                tf.text = self.shippingAddress.line1;
                self.textFieldLine1 = tf;
                break;
            case 2:
                label.text = NSLocalizedStringFromTableInBundle(@"Line 2", @"KitePrintSDK", [NSBundle mainBundle], @"");
                tf.text = self.shippingAddress.line2;
                self.textFieldLine2 = tf;
                break;
            case 3:
                label.text = NSLocalizedStringFromTableInBundle(@"City", @"KitePrintSDK", [NSBundle mainBundle], @"");
                tf.text = self.shippingAddress.city;
                self.textFieldCity = tf;
                break;
            case 4:
                if (self.shippingAddress.country == [OLCountry countryForCode:@"USA"]) {
                    label.text = @"State";
                } else {
                    label.text = NSLocalizedStringFromTableInBundle(@"County", @"KitePrintSDK", [NSBundle mainBundle], @"");
                }
                tf.text = self.shippingAddress.stateOrCounty;
                self.textFieldCounty = tf;
                break;
            case 5:
                if (self.shippingAddress.country == [OLCountry countryForCode:@"USA"]) {
                    label.text = @"ZIP Code";
                } else {
                    label.text = NSLocalizedStringFromTableInBundle(@"Postcode", @"KitePrintSDK", [NSBundle mainBundle], @"");
                }
                tf.text = self.shippingAddress.zipOrPostcode;
                tf.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
                self.textFieldPostCode = tf;
                break;
            case 6:
                label.text = NSLocalizedStringFromTableInBundle(@"Country", @"KitePrintSDK", [NSBundle mainBundle], @"");
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
            if (!self.shippingAddress){
                self.shippingAddress = [[OLAddress alloc] init];
            }
            
            OLCountryPickerController *controller = [[OLCountryPickerController alloc] init];
            controller.delegate = self;

            if (!self.shippingAddress.country){
                self.shippingAddress.country = [OLCountry countryForCode:@"GBR"];
                controller.selected = @[self.shippingAddress.country];
            }
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
                self.shippingAddress.recipientName = textField.text;
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
    
    if (!self.shippingAddress){
        self.shippingAddress = [[OLAddress alloc] init];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
    self.shippingAddress.country = countries.lastObject;
    self.textFieldCountry.text = self.shippingAddress.country.name;
    [self.tableView reloadData]; // refesh labels if country has changed i.e. Postal Code -> ZIP Code if UK -> USA.
    
    
}

-(void) countryPickerDidCancelPicking:(OLCountryPickerController *)picker{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.textFieldName) {
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
    UITableViewCell *cell = [[UITableViewCell alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 43)];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 11, 110, 21)];
    titleLabel.text = title;
    titleLabel.adjustsFontSizeToFitWidth = YES;
    titleLabel.tag = kTagInputFieldLabel;
    UITextField *inputField = [[UITextField alloc] initWithFrame:CGRectMake(125, 0, [UIScreen mainScreen].bounds.size.width - 86, 43)];
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
        
        NSArray *visuals = @[@"H:|-125-[view]-0-|", @"V:[view(43)]"];
        
        
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
