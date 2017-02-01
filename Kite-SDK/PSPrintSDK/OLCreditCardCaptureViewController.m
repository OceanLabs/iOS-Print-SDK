//
//  Modified MIT License
//
//  Copyright (c) 2010-2017 Kite Tech Ltd. https://www.kite.ly
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

#import "OLProgressHUD.h"
#import "OLCreditCardCaptureViewController.h"
#import "OLConstants.h"
#import "OLPayPalCard.h"
#import "OLPrintOrder.h"
#import "OLKitePrintSDK.h"
#import <AVFoundation/AVFoundation.h>
#import "NSString+Formatting.h"
#import "UITextField+Selection.h"
#import "UIView+RoundRect.h"
#import "OLPrintOrderCost.h"
#import "UIImage+ImageNamedInKiteBundle.h"
#import "OLKiteABTesting.h"
#import "OLKiteUtils.h"
#import "OLLuhn.h"
#import "OLImageDownloader.h"
#import "OLKiteABTesting.h"

static const NSUInteger kOLSectionCardNumber = 0;
static const NSUInteger kOLSectionExpiryDate = 1;
static const NSUInteger kOLSectionCVV = 2;

typedef enum {
    kCardTypeVisa,
    kCardTypeMasterCard,
    kCardTypeDinersClub,
    kCardTypeAmex,
    kCardTypeDiscover,
    kCardTypeUnknown
} CardType;

static NSString *const kRegexVisa = @"^4[0-9]{3}?";
static NSString *const kRegexMasterCard = @"^5[1-5][0-9]{2}$";
static NSString *const kRegexAmex = @"^3[47][0-9]{2}$";
static NSString *const kRegexDinersClub = @"^3(?:0[0-5]|[68][0-9])[0-9]$";
static NSString *const kRegexDiscover = @"^6(?:011|5[0-9]{2})$";

static CardType getCardType(NSString *cardNumber) {
    if(cardNumber.length < 4) {
        return kCardTypeUnknown;
    }
    
    CardType cardType;
    NSRegularExpression *regex;
    NSError *error;
    
    for (NSUInteger i = 0; i < kCardTypeUnknown; ++i) {
        cardType = (CardType) i;
        switch(i) {
            case kCardTypeVisa:
                regex = [NSRegularExpression regularExpressionWithPattern:kRegexVisa options:0 error:&error];
                break;
            case kCardTypeMasterCard:
                regex = [NSRegularExpression regularExpressionWithPattern:kRegexMasterCard options:0 error:&error];
                break;
            case kCardTypeAmex:
                regex = [NSRegularExpression regularExpressionWithPattern:kRegexAmex options:0 error:&error];
                break;
            case kCardTypeDinersClub:
                regex = [NSRegularExpression regularExpressionWithPattern:kRegexDinersClub options:0 error:&error];
                break;
            case kCardTypeDiscover:
                regex = [NSRegularExpression regularExpressionWithPattern:kRegexDiscover options:0 error:&error];
                break;
        }
        
        NSUInteger matches = [regex numberOfMatchesInString:cardNumber options:0 range:NSMakeRange(0, 4)];
        if (matches == 1) {
            return cardType;
        }
        
    }
    
    return kCardTypeUnknown;
}

@interface OLKitePrintSDK (Private)
+ (BOOL)useStripeForCreditCards;
@end

@interface OLCreditCardCaptureRootController : UITableViewController <UITableViewDelegate,
UITableViewDataSource, UITextFieldDelegate>
@property (nonatomic, strong) UITextField *textFieldCardNumber, *textFieldExpiryDate, *textFieldCVV;
@property (nonatomic, strong) OLPrintOrder *printOrder;
@property (nonatomic, weak) id <UINavigationControllerDelegate, OLCreditCardCaptureDelegate> delegate;
- (id)initWithPrintOrder:(OLPrintOrder *)printOrder;
@end

@interface OLCreditCardCaptureViewController ()
@property (nonatomic, strong) OLCreditCardCaptureRootController *rootVC;
- (id)initWithPrintOrder:(OLPrintOrder *)printOrder;
@end

@implementation OLCreditCardCaptureViewController

- (instancetype)initWithPrintOrder:(OLPrintOrder *)printOrder {
    self.rootVC = [[OLCreditCardCaptureRootController alloc] initWithPrintOrder:printOrder];
    if (self = [super initWithRootViewController:self.rootVC]) {

    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)setDelegate:(id<UINavigationControllerDelegate,OLCreditCardCaptureDelegate>)delegate {
    self.rootVC.delegate = delegate;
}

- (id<UINavigationControllerDelegate, OLCreditCardCaptureDelegate>)delegate {
    return self.rootVC.delegate;
}

@end

@implementation OLCreditCardCaptureRootController

- (id)initWithPrintOrder:(OLPrintOrder *)printOrder {
    if (self = [super initWithStyle:UITableViewStyleGrouped]) {
        self.printOrder = printOrder;
        
        if (printOrder){
            if ([OLKitePrintSDK environment] == OLKitePrintSDKEnvironmentSandbox) {
                self.title = NSLocalizedStringFromTableInBundle(@"Pay with Credit Card (TEST)", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"");
            } else {
                self.title = NSLocalizedStringFromTableInBundle(@"Pay with Credit Card", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"");
            }
        }
        else{
            if ([OLKitePrintSDK environment] == OLKitePrintSDKEnvironmentSandbox) {
                self.title = NSLocalizedStringFromTableInBundle(@"Add Credit Card (TEST)", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"");
            } else {
                self.title = NSLocalizedStringFromTableInBundle(@"Add Credit Card", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"");
            }
        }

        NSURL *cancelUrl = [NSURL URLWithString:[OLKiteABTesting sharedInstance].cancelButtonIconURL];
        if (cancelUrl && ![[OLImageDownloader sharedInstance] cachedDataExistForURL:cancelUrl]){
            [[OLImageDownloader sharedInstance] downloadImageAtURL:cancelUrl withCompletionHandler:^(UIImage *image, NSError *error){
                if (error) return;
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageWithCGImage:image.CGImage scale:2.0 orientation:UIImageOrientationUp] style:UIBarButtonItemStyleDone target:self action:@selector(onButtonCancelClicked)];
                });
            }];
        }
        else{
            self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle: NSLocalizedStringFromTableInBundle(@"Cancel", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"") style:UIBarButtonItemStylePlain target:self action:@selector(onButtonCancelClicked)];
        }
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIButton *buttonPay = [[UIButton alloc] initWithFrame:CGRectMake(0, 20, self.view.frame.size.width, 44)];
    buttonPay.backgroundColor = [UIColor colorWithRed:74 / 255.0f green:137 / 255.0f blue:220 / 255.0f alpha:1.0];
    [buttonPay addTarget:self action:@selector(onButtonPayClicked) forControlEvents:UIControlEventTouchUpInside];
    if (self.printOrder){
        [buttonPay setTitle: NSLocalizedStringFromTableInBundle(@"Pay", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"") forState:UIControlStateNormal];
    }
    else{
        [buttonPay setTitle: NSLocalizedStringFromTableInBundle(@"Add", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"") forState:UIControlStateNormal];
    }
    [buttonPay makeRoundRect];
    
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44 + 40)];
    [footerView addSubview:buttonPay];
    
    UIView *view = buttonPay;
    view.translatesAutoresizingMaskIntoConstraints = NO;
    NSDictionary *views = NSDictionaryOfVariableBindings(view);
    NSMutableArray *con = [[NSMutableArray alloc] init];
    
    NSArray *visuals = @[@"H:|-20-[view]-20-|",
                         @"V:|-20-[view(44)]"];
    
    
    for (NSString *visual in visuals) {
        [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
    }
    
    [view.superview addConstraints:con];
    
    self.tableView.tableFooterView = footerView;
    
    if (self.printOrder){
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Pay", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"")
                                                                             style:UIBarButtonItemStyleDone
                                                                            target:self
                                                                            action:@selector(onButtonPayClicked)];
    }
    else{
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Add", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"")
                                                                                  style:UIBarButtonItemStyleDone
                                                                                 target:self
                                                                                 action:@selector(onButtonPayClicked)];
    }
    
    UIColor *color1 = [OLKiteABTesting sharedInstance].lightThemeColor1;
    if (color1){
        self.navigationItem.rightBarButtonItem.tintColor = color1;
        [buttonPay setBackgroundColor:[[OLKiteABTesting sharedInstance] lightThemeColor1]];
    }
    UIFont *font = [[OLKiteABTesting sharedInstance] lightThemeFont1WithSize:17];
    if (font){
        [self.navigationItem.rightBarButtonItem setTitleTextAttributes:@{NSFontAttributeName : font} forState:UIControlStateNormal];
    }
    
    if ([self.tableView respondsToSelector:@selector(setCellLayoutMarginsFollowReadableWidth:)]){
        self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    }
}

- (NSString *)cardNumber {
    return [NSString stringByTrimmingSpecialCharacters:self.textFieldCardNumber.text];
}

- (NSUInteger)cardExpireMonth {
    NSString *expiryDate = [NSString stringByTrimmingSpecialCharacters:self.textFieldExpiryDate.text];
    return [[expiryDate substringToIndex:2] integerValue];
}

- (NSUInteger)cardExpireYear {
    NSString *expiryDate = [NSString stringByTrimmingSpecialCharacters:self.textFieldExpiryDate.text];
    return [[expiryDate substringFromIndex:2] integerValue];
}

- (NSString *)cardCVV {
    return self.textFieldCVV.text;
}

- (void)onButtonPayClicked {
    [self.textFieldCardNumber resignFirstResponder];
    [self.textFieldExpiryDate resignFirstResponder];
    [self.textFieldCVV resignFirstResponder];
    
    if (![self.textFieldCardNumber.text isValidCreditCardNumber]) {
        NSString *localizedDescription = NSLocalizedStringFromTableInBundle(@"Enter a valid expiry date", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"");
        UIAlertController *ac = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTableInBundle(@"Oops!", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"") message:localizedDescription preferredStyle:UIAlertControllerStyleAlert];
        [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"ΟΚ", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){}]];
        [self presentViewController:ac animated:YES completion:NULL];
        return;
    }
    
    if (self.textFieldExpiryDate.text.length != 5) {
        NSString *localizedDescription = NSLocalizedStringFromTableInBundle(@"Enter a valid expiry date", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"");
        UIAlertController *ac = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTableInBundle(@"Oops!", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"") message:localizedDescription preferredStyle:UIAlertControllerStyleAlert];
        [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"ΟΚ", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){}]];
        [self presentViewController:ac animated:YES completion:NULL];
        return;
    }
    
    if (self.textFieldCVV.text.length == 0) {
        NSString *localizedDescription = NSLocalizedStringFromTableInBundle(@"Enter a valid CVV number", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"");
        UIAlertController *ac = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTableInBundle(@"Oops!", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"") message:localizedDescription preferredStyle:UIAlertControllerStyleAlert];
        [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"ΟΚ", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){}]];
        [self presentViewController:ac animated:YES completion:NULL];
        return;
    }
    
    NSUInteger expireMonth = [self cardExpireMonth];
    NSUInteger expireYear = [self cardExpireYear];
    if (expireMonth > 12) {
        NSString *localizedDescription = NSLocalizedStringFromTableInBundle(@"Enter a valid expiry date", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"");
        UIAlertController *ac = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTableInBundle(@"Oops!", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"") message:localizedDescription preferredStyle:UIAlertControllerStyleAlert];
        [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"ΟΚ", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){}]];
        [self presentViewController:ac animated:YES completion:NULL];
        return;
    }
    
    NSUInteger flags = NSCalendarUnitMonth | NSCalendarUnitYear;
    NSDateComponents *components = [[NSCalendar currentCalendar] components:flags fromDate:[NSDate date]];
    NSInteger componentsYear = components.year - 2000; //This will obviously cause problems near 2100.
    if (componentsYear > expireYear || (componentsYear == expireYear && components.month > expireMonth)){
        NSString *localizedDescription = NSLocalizedStringFromTableInBundle(@"Please enter a card expiry date in the future", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"");
        UIAlertController *ac = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTableInBundle(@"Oops!", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"") message:localizedDescription preferredStyle:UIAlertControllerStyleAlert];
        [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"ΟΚ", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){}]];
        [self presentViewController:ac animated:YES completion:NULL];
        return;
    }
    
    CardType cardType = getCardType(self.textFieldCardNumber.text);
    OLPayPalCardType paypalCard;
    switch (cardType) {
        case kCardTypeAmex:
            paypalCard = kOLPayPalCardTypeAmex;
            break;
        case kCardTypeMasterCard:
            paypalCard = kOLPayPalCardTypeMastercard;
            break;
        case kCardTypeVisa:
            paypalCard = kOLPayPalCardTypeVisa;
            break;
        case kCardTypeDiscover:
            paypalCard = kOLPayPalCardTypeDiscover;
            break;
        default: {
            NSString *localizedDescription = NSLocalizedStringFromTableInBundle(@"Enter a valid credit card number", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"");
            UIAlertController *ac = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTableInBundle(@"Oops!", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"") message:localizedDescription preferredStyle:UIAlertControllerStyleAlert];
            [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"ΟΚ", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){}]];
            [self presentViewController:ac animated:YES completion:NULL];
            return;
        }
    }
    
    if ([OLKitePrintSDK useStripeForCreditCards]){
        OLStripeCard *card = [[OLStripeCard alloc] init];
        card.number = [self cardNumber];
        card.expireMonth = expireMonth;
        card.expireYear = expireYear;
        card.cvv2 = [self cardCVV];
        
        if (self.printOrder){
            [OLProgressHUD setDefaultMaskType:OLProgressHUDMaskTypeBlack];
            [OLProgressHUD showWithStatus:NSLocalizedStringFromTableInBundle(@"Processing", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"")];
            [card chargeCard:nil currencyCode:nil description:nil completionHandler:^(NSString *proofOfPayment, NSError *error) {
                if (error) {
                    [OLProgressHUD dismiss];
                    UIAlertController *ac = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTableInBundle(@"Oops!", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"") message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
                    [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"OK", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"") style:UIAlertActionStyleDefault handler:NULL]];
                    [self presentViewController:ac animated:YES completion:NULL];
                    return;
                }
                
                [OLProgressHUD dismiss];
                [self.delegate creditCardCaptureController:(OLCreditCardCaptureViewController *) self.navigationController didFinishWithProofOfPayment:proofOfPayment];
                [card saveAsLastUsedCard];
            }];
        }
        else{
            [card saveAsLastUsedCard];
            [self.delegate creditCardCaptureController:(OLCreditCardCaptureViewController *) self.navigationController didFinishWithProofOfPayment:nil];
        }
    }
    else{
        OLPayPalCard *card = [[OLPayPalCard alloc] init];
        card.type = paypalCard;
        card.number = [self cardNumber];
        card.expireMonth = expireMonth;
        card.expireYear = expireYear;
        card.cvv2 = [self cardCVV];
        
        if (self.printOrder){
            [self storeAndChargeCard:card];
        }
        else{
            [card saveAsLastUsedCard];
            [self.delegate creditCardCaptureController:(OLCreditCardCaptureViewController *) self.navigationController didFinishWithProofOfPayment:nil];
        }
    }
}

- (void)storeAndChargeCard:(id)card{
    [OLProgressHUD setDefaultMaskType:OLProgressHUDMaskTypeBlack];
    [OLProgressHUD showWithStatus:NSLocalizedStringFromTableInBundle(@"Processing", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"")];
    [card storeCardWithCompletionHandler:^(NSError *error) {
        // ignore error as I'd rather the user gets a nice checkout experience than we store the card in PayPal vault.
        [self.printOrder costWithCompletionHandler:^(OLPrintOrderCost *cost, NSError *error) {
            [card chargeCard:[cost totalCostInCurrency:self.printOrder.currencyCode] currencyCode:self.printOrder.currencyCode description:self.printOrder.paymentDescription completionHandler:^(NSString *proofOfPayment, NSError *error) {
                if (error) {
                    [OLProgressHUD dismiss];
                    UIAlertController *ac = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTableInBundle(@"Oops!", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"") message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
                    [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"ΟΚ", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){}]];
                    [self presentViewController:ac animated:YES completion:NULL];
                    return;
                }
                
                [OLProgressHUD dismiss];
                [self.delegate creditCardCaptureController:(OLCreditCardCaptureViewController *) self.navigationController didFinishWithProofOfPayment:proofOfPayment];
                [card saveAsLastUsedCard];
            }];
        }];
    }];
}

- (void)onButtonCancelClicked {
    [self.textFieldCardNumber resignFirstResponder];
    [self.textFieldCVV resignFirstResponder];
    [self.textFieldExpiryDate resignFirstResponder];
    if ([self.delegate respondsToSelector:@selector(creditCardCaptureControllerDismissed:)]){
        [self.delegate creditCardCaptureControllerDismissed:(OLCreditCardCaptureViewController *) self.navigationController];
    }
    else{
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == kOLSectionCardNumber) {
        return NSLocalizedStringFromTableInBundle(@"Your 15-16 digit card number", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"");
    } else if (section == kOLSectionExpiryDate) {
        return NSLocalizedStringFromTableInBundle(@"Your card expiry date", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"");
    } else if (section == kOLSectionCVV) {
        return NSLocalizedStringFromTableInBundle(@"This is the 3-4 digit verification number/security code normally found on the back of your card", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"");
    } else {
        return @"";
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *const CellIdentifier = @"CreditCardCaptureCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(20, 0, self.view.frame.size.width - 63, 43)];
        textField.delegate = self;
        textField.tag = 99;
        textField.keyboardType = UIKeyboardTypeNumberPad;
        [cell addSubview:textField];
        
        UIView *view = textField;
        view.translatesAutoresizingMaskIntoConstraints = NO;
        NSDictionary *views = NSDictionaryOfVariableBindings(view);
        NSMutableArray *con = [[NSMutableArray alloc] init];
        
        NSArray *visuals = @[@"H:|-20-[view]-43-|", @"V:[view(43)]"];
        
        
        for (NSString *visual in visuals) {
            [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
        }
        
        NSLayoutConstraint *centerY = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:view.superview attribute:NSLayoutAttributeCenterY multiplier:1 constant:0];
        [con addObject:centerY];
        
        [view.superview addConstraints:con];
        
    }
    
    UITextField *textField = (UITextField *) [cell viewWithTag:99];
    if (indexPath.section == kOLSectionCardNumber) {
        textField.placeholder = NSLocalizedStringFromTableInBundle(@"Card Number", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"");
        self.textFieldCardNumber = textField;
        
    } else if (indexPath.section == kOLSectionExpiryDate) {
        textField.placeholder = NSLocalizedStringFromTableInBundle(@"MM/YY", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"");
        self.textFieldExpiryDate = textField;
    } else if (indexPath.section == kOLSectionCVV) {
        textField.placeholder = NSLocalizedStringFromTableInBundle(@"CVV", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"");
        self.textFieldCVV = textField;
    }
    
    return cell;
}

#pragma mark - UITextFieldDelegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    if (textField == self.textFieldCardNumber){
        [self.textFieldExpiryDate becomeFirstResponder];
    }
    else if (textField == self.textFieldExpiryDate){
        [self.textFieldCVV becomeFirstResponder];
    }
    else if (textField == self.textFieldCVV){
        [self.textFieldCVV resignFirstResponder];
    }
    
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField == self.textFieldExpiryDate) {
        self.textFieldExpiryDate.text = [NSString stringByFormattingCreditCardExpiry:[self.textFieldExpiryDate.text stringByReplacingCharactersInRange:range withString:string]];
        if (string.length == 0 && self.textFieldExpiryDate.text.length == 3) {
            self.textFieldExpiryDate.text = [self.textFieldExpiryDate.text substringToIndex:2];
        }
        
        return NO;
    }
    else if (textField == self.textFieldCardNumber) {
        UITextRange *selRange = textField.selectedTextRange;
        UITextPosition *selStartPos = selRange.start;
        NSInteger idx = [textField offsetFromPosition:textField.beginningOfDocument toPosition:selStartPos];
        NSInteger offset = -1;
        
        if ([[self.textFieldCardNumber.text substringWithRange:range] isEqualToString:@" "] && string.length == 0){
            range = NSMakeRange(range.location-1, range.length);
            offset = -2;
        }
        
        self.textFieldCardNumber.text = [NSString stringByFormattingCreditCardNumber:[self.textFieldCardNumber.text stringByReplacingCharactersInRange:range withString:string]];
        
        if (string.length == 0 && idx + offset > textField.text.length){
            offset = -2;
        }
        else if (string.length > 0){
            offset = 1;
            if (textField.text.length > idx){
                NSString *s = [textField.text substringWithRange:NSMakeRange(idx, 1)];
                if ([s isEqualToString:@" "]){
                    offset = 2;
                }
            }
            else{
                offset = 0;
            }
        }
        [textField setSelectedRange:NSMakeRange(idx + offset, 0)];
        
        return NO;
    }
    
    return YES;
}

@end
