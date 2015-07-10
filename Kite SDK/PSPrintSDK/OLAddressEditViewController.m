//
//  OLAddressEditViewController.m
//  Kite SDK
//
//  Created by Deon Botha on 04/01/2014.
//  Copyright (c) 2014 Deon Botha. All rights reserved.
//

#import "OLAddressEditViewController.h"

#import "OLAddress+AddressBook.h"
#import "OLCountry.h"
#import "OLCountryPickerController.h"
#import "OLAddressSelectionViewController.h"
#import "OLAddressPickerController.h"

static const NSUInteger kTagTextField = 99;
static const NSUInteger kTagLabel = 100;

@interface OLAddressSelectionViewController ()
@property (nonatomic, strong) OLAddress *addressToAddToListOnViewDidAppear;
@end

@interface OLAddressEditViewController () <UITextFieldDelegate, UINavigationControllerDelegate, OLCountryPickerControllerDelegate>
@property (nonatomic, strong) OLAddress *address;
@property (nonatomic, strong) UITextField *textFieldName, *textFieldLine1, *textFieldLine2, *textFieldCity, *textFieldCounty, *textFieldPostCode, *textFieldCountry;
@property (nonatomic, assign) BOOL editingExistingSavedAddress;
@end

@implementation OLAddressEditViewController

- (id)init {
    return [self initWithAddress:nil];
}

- (id)initWithAddress:(OLAddress *)address {
    if (self = [super initWithStyle:UITableViewStyleGrouped]) {
        self.address = address;
        if (self.address == nil) {
            self.address = [[OLAddress alloc] init];
        }
        
        if (self.address.country == nil) {
            self.address.country = [OLCountry countryForCurrentLocale];
        }
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.editingExistingSavedAddress = self.address.isSavedInAddressBook;
    self.title = self.editingExistingSavedAddress ? NSLocalizedStringFromTableInBundle(@"Edit Address", @"KitePrintSDK", [NSBundle mainBundle], @"") : NSLocalizedStringFromTableInBundle(@"Add Address", @"KitePrintSDK", [NSBundle mainBundle], @"");
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:self.editingExistingSavedAddress ? NSLocalizedStringFromTableInBundle(@"Save", @"KitePrintSDK", [NSBundle mainBundle], @"") : NSLocalizedStringFromTableInBundle(@"Add", @"KitePrintSDK", [NSBundle mainBundle], @"") style:UIBarButtonItemStyleDone target:self action:@selector(onSaveButtonClicked)];
    self.navigationItem.rightBarButtonItem = doneButton;
    
    if ([self.navigationController.viewControllers firstObject] == self){
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Cancel", @"KitePrintSDK", [NSBundle mainBundle], @"") style:UIBarButtonItemStylePlain target:self action:@selector(onCancelButtonClicked)];
        self.navigationItem.leftBarButtonItem = cancelButton;
    }
}

- (void)onSaveButtonClicked {
    if ([self isValidAddress]){
        [self saveAddressAndReturn];
    }
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

- (void)saveAddressAndReturn {
    self.address.recipientName = self.textFieldName.text;
    self.address.line1 = self.textFieldLine1.text;
    self.address.line2 = self.textFieldLine2.text;
    self.address.city = self.textFieldCity.text;
    self.address.stateOrCounty = self.textFieldCounty.text;
    self.address.zipOrPostcode = self.textFieldPostCode.text;
    
    OLAddressSelectionViewController *vc = self.navigationController.viewControllers[0];
    if ([vc.delegate respondsToSelector:@selector(addressSelectionController:didFinishPickingAddresses:)]){
        if (self.address.isSavedInAddressBook) {
            [self.address saveToAddressBook]; // save
            [vc.tableView reloadData];
        } else {
            vc.addressToAddToListOnViewDidAppear = self.address;
        }
        [self.address saveToAddressBook];
        if (vc.allowMultipleSelection){
            [self.navigationController popToRootViewControllerAnimated:YES];
        }
        else{
            [vc.delegate addressSelectionController:vc didFinishPickingAddresses:@[self.address]];
        }
    }
    else if ([vc.delegate respondsToSelector:@selector(addressPicker:didFinishPickingAddresses:)]){
        [self.address saveToAddressBook];
        [(id)(vc.delegate) addressPicker:nil didFinishPickingAddresses:@[self.address]];
    }
}

- (void)onCancelButtonClicked{
    OLAddressSelectionViewController *vc = self.navigationController.viewControllers[0];
    if ([vc.delegate respondsToSelector:@selector(addressSelectionControllerDidCancelPicking:)]){
        [vc.delegate addressSelectionControllerDidCancelPicking:vc];
    }
    else if ([vc.delegate respondsToSelector:@selector(addressPickerDidCancelPicking:)]){
        [(id)(vc.delegate) addressPickerDidCancelPicking:nil];
    }
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 7;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *const kCellIdentifier = @"CellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.frame = CGRectMake(0, 0, self.view.frame.size.width, 43);
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, 110, cell.frame.size.height)];
        label.font = cell.textLabel.font;
        label.tag = kTagLabel;
        
        UITextField *tf = [[UITextField alloc] initWithFrame:CGRectMake(110, 0, cell.frame.size.width - 110, cell.frame.size.height)];
        tf.adjustsFontSizeToFitWidth = YES;
        tf.textColor = [UIColor blackColor];
        tf.autocorrectionType = UITextAutocorrectionTypeNo;
        tf.textAlignment = NSTextAlignmentLeft;
        tf.tag = kTagTextField;
        tf.clearButtonMode = UITextFieldViewModeWhileEditing;
        tf.delegate = self;
        
        [cell.contentView addSubview:tf];
        [cell.contentView addSubview:label];
    }
    
    UITextField *tf = (UITextField *) [cell viewWithTag:kTagTextField];
    UILabel *label = (UILabel *) [cell viewWithTag:kTagLabel];
    tf.enabled = YES;
    tf.returnKeyType = UIReturnKeyNext;
    cell.accessoryType = UITableViewCellAccessoryNone;
    tf.autocapitalizationType = UITextAutocapitalizationTypeWords;
    switch (indexPath.row) {
        case 0:
            label.text = NSLocalizedStringFromTableInBundle(@"Name", @"KitePrintSDK", [NSBundle mainBundle], @"");
            tf.text = self.address.recipientName;
            self.textFieldName = tf;
            break;
        case 1:
            label.text = NSLocalizedStringFromTableInBundle(@"Line 1", @"KitePrintSDK", [NSBundle mainBundle], @"");
            tf.text = self.address.line1;
            self.textFieldLine1 = tf;
            break;
        case 2:
            label.text = NSLocalizedStringFromTableInBundle(@"Line 2", @"KitePrintSDK", [NSBundle mainBundle], @"");
            tf.text = self.address.line2;
            self.textFieldLine2 = tf;
            break;
        case 3:
            label.text = NSLocalizedStringFromTableInBundle(@"City", @"KitePrintSDK", [NSBundle mainBundle], @"");
            tf.text = self.address.city;
            self.textFieldCity = tf;
            break;
        case 4:
            if (self.address.country == [OLCountry countryForCode:@"USA"]) {
                label.text = @"State";
            } else {
                label.text = NSLocalizedStringFromTableInBundle(@"County", @"KitePrintSDK", [NSBundle mainBundle], @"");
            }
            tf.text = self.address.stateOrCounty;
            self.textFieldCounty = tf;
            break;
        case 5:
            if (self.address.country == [OLCountry countryForCode:@"USA"]) {
                label.text = @"ZIP Code";
            } else {
                label.text = NSLocalizedStringFromTableInBundle(@"Postcode", @"KitePrintSDK", [NSBundle mainBundle], @"");
            }
            tf.text = self.address.zipOrPostcode;
            tf.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
            self.textFieldPostCode = tf;
            break;
        case 6:
            label.text = NSLocalizedStringFromTableInBundle(@"Country", @"KitePrintSDK", [NSBundle mainBundle], @"");
            tf.text = self.address.country.name;
            tf.enabled = NO;
            [tf setNeedsLayout];
            [tf setNeedsDisplay];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            tf.returnKeyType = UIReturnKeyDone;
            self.textFieldCountry = tf;
            break;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 6) {
        OLCountryPickerController *controller = [[OLCountryPickerController alloc] init];
        controller.delegate = self;
        OLCountry *selectedCountry = self.address.country;
        controller.selected = @[selectedCountry ? selectedCountry : [OLCountry countryForCode:@"GBR"]];
        [self presentViewController:controller animated:YES completion:nil];
    }
}

#pragma mark - OLCountryPickerControllerDelegate methods 

- (void)countryPicker:(OLCountryPickerController *)picker didSucceedWithCountries:(NSArray/*<OLCountry>*/ *)countries {
    [self dismissViewControllerAnimated:YES completion:nil];
    self.address.country = countries.lastObject;
    self.textFieldCountry.text = self.address.country.name;
    [self.tableView reloadData];
}

- (void)countryPickerDidCancelPicking:(OLCountryPickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITextFieldDelegate methods

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
        [textField resignFirstResponder];
    } else if (textField == self.textFieldCountry) {
        [self saveAddressAndReturn];
    }
    
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *s = [textField.text stringByReplacingCharactersInRange:range withString:string];
    if (textField == self.textFieldName) {
        self.address.recipientName = s;
    } else if (textField == self.textFieldLine1) {
        self.address.line1 = s;
    } else if (textField == self.textFieldLine2) {
        self.address.line2 = s;
    } else if (textField == self.textFieldCity) {
        self.address.city = s;
    } else if (textField == self.textFieldCounty) {
        self.address.stateOrCounty = s;
    } else if (textField == self.textFieldPostCode) {
        self.address.zipOrPostcode = s;
    }
    
    return YES;
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
