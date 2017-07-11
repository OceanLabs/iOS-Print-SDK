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

#ifndef KITE_UTILS
#import "OLPayPalCard.h"
#import "OLKiteABTesting.h"
#import "OLProgressHUD.h"
#import "OLConstants.h"
#import "OLPrintOrder.h"
#import "OLKitePrintSDK.h"
#import "OLPrintOrderCost.h"
#import "OLKiteUtils.h"
#import "UIImage+ImageNamedInKiteBundle.h"
#endif

#import "OLCreditCardCaptureViewController.h"
#import "NSString+Formatting.h"
#import "UITextField+Selection.h"
#import "UIView+RoundRect.h"
#import "OLLuhn.h"
#import "OLImageDownloader.h"
#import "OLStripeCard.h"
#import "OLDefines.h"

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

#ifndef KITE_UTILS
@interface OLKitePrintSDK (Private)
+ (BOOL)useStripeForCreditCards;
@end
#endif

@interface OLCreditCardCaptureRootController : UITableViewController <UITableViewDelegate,
UITableViewDataSource, UITextFieldDelegate>
@property (nonatomic, strong) UITextField *textFieldCardNumber, *textFieldExpiryDate, *textFieldCVV;
@property (nonatomic, weak) id <UINavigationControllerDelegate, OLCreditCardCaptureDelegate> delegate;
@end

@interface OLCreditCardCaptureViewController ()
@property (nonatomic, strong) OLCreditCardCaptureRootController *rootVC;
@end

@implementation OLCreditCardCaptureViewController

- (instancetype)init{
    self.rootVC = [[OLCreditCardCaptureRootController alloc] initWithStyle:UITableViewStyleGrouped];
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

- (void)viewDidLoad {
    [super viewDidLoad];
    
#ifndef KITE_UTILS
    if ([OLKitePrintSDK environment] == OLKitePrintSDKEnvironmentSandbox) {
        self.title = OLLocalizedString(@"Add Credit Card (TEST)", @"");
    } else {
        self.title = OLLocalizedString(@"Add Credit Card", @"");
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
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle: OLLocalizedString(@"Cancel", @"") style:UIBarButtonItemStylePlain target:self action:@selector(onButtonCancelClicked)];
    }
#else
    self.title = OLLocalizedString(@"Add Credit Card", @"");
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle: NSLocalizedString(@"Cancel", @"") style:UIBarButtonItemStylePlain target:self action:@selector(onButtonCancelClicked)];
#endif
    
    UIButton *buttonPay = [[UIButton alloc] initWithFrame:CGRectMake(0, 20, self.view.frame.size.width, 44)];
    buttonPay.backgroundColor = [UIColor colorWithRed:74 / 255.0f green:137 / 255.0f blue:220 / 255.0f alpha:1.0];
    [buttonPay addTarget:self action:@selector(onButtonPayClicked) forControlEvents:UIControlEventTouchUpInside];
    
    [buttonPay setTitle: OLLocalizedString(@"Add", @"") forState:UIControlStateNormal];
    
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

#ifndef KITE_UTILS
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:OLLocalizedString(@"Add", @"")
                                                                              style:UIBarButtonItemStyleDone
                                                                             target:self
                                                                             action:@selector(onButtonPayClicked)];
    
    UIColor *color1 = [OLKiteABTesting sharedInstance].lightThemeColor1;
    if (color1){
        self.navigationItem.rightBarButtonItem.tintColor = color1;
        [buttonPay setBackgroundColor:[[OLKiteABTesting sharedInstance] lightThemeColor1]];
    }
    UIFont *font = [[OLKiteABTesting sharedInstance] lightThemeFont1WithSize:17];
    if (font){
        [self.navigationItem.rightBarButtonItem setTitleTextAttributes:@{NSFontAttributeName : font} forState:UIControlStateNormal];
    }
#endif
    
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
        NSString *localizedDescription = OLLocalizedString(@"Enter a valid card number", @"");
        UIAlertController *ac = [UIAlertController alertControllerWithTitle:OLLocalizedString(@"Oops!", @"") message:localizedDescription preferredStyle:UIAlertControllerStyleAlert];
        [ac addAction:[UIAlertAction actionWithTitle:OLLocalizedString(@"OK", @"Acknowledgent to an alert dialog.") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){}]];
        [self presentViewController:ac animated:YES completion:NULL];
        return;
    }
    
    if (self.textFieldExpiryDate.text.length != 5) {
        NSString *localizedDescription = OLLocalizedString(@"Enter a valid expiry date", @"For credit cards");
        UIAlertController *ac = [UIAlertController alertControllerWithTitle:OLLocalizedString(@"Oops!", @"") message:localizedDescription preferredStyle:UIAlertControllerStyleAlert];
        [ac addAction:[UIAlertAction actionWithTitle:OLLocalizedString(@"OK", @"Acknowledgent to an alert dialog.") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){}]];
        [self presentViewController:ac animated:YES completion:NULL];
        return;
    }
    
    if (self.textFieldCVV.text.length == 0) {
        NSString *localizedDescription = OLLocalizedString(@"Enter a valid CVV number", @"The credit card security number");
        UIAlertController *ac = [UIAlertController alertControllerWithTitle:OLLocalizedString(@"Oops!", @"") message:localizedDescription preferredStyle:UIAlertControllerStyleAlert];
        [ac addAction:[UIAlertAction actionWithTitle:OLLocalizedString(@"OK", @"Acknowledgent to an alert dialog.") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){}]];
        [self presentViewController:ac animated:YES completion:NULL];
        return;
    }
    
    NSUInteger expireMonth = [self cardExpireMonth];
    NSUInteger expireYear = [self cardExpireYear];
    if (expireMonth > 12) {
        NSString *localizedDescription = OLLocalizedString(@"Enter a valid expiry date", @"For credit cards");
        UIAlertController *ac = [UIAlertController alertControllerWithTitle:OLLocalizedString(@"Oops!", @"") message:localizedDescription preferredStyle:UIAlertControllerStyleAlert];
        [ac addAction:[UIAlertAction actionWithTitle:OLLocalizedString(@"OK", @"Acknowledgent to an alert dialog.") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){}]];
        [self presentViewController:ac animated:YES completion:NULL];
        return;
    }
    
    NSUInteger flags = NSCalendarUnitMonth | NSCalendarUnitYear;
    NSDateComponents *components = [[NSCalendar currentCalendar] components:flags fromDate:[NSDate date]];
    NSInteger componentsYear = components.year - 2000; //This will obviously cause problems near 2100.
    if (componentsYear > expireYear || (componentsYear == expireYear && components.month > expireMonth)){
        NSString *localizedDescription = OLLocalizedString(@"Please enter a card expiry date in the future", @"For credit cards");
        UIAlertController *ac = [UIAlertController alertControllerWithTitle:OLLocalizedString(@"Oops!", @"") message:localizedDescription preferredStyle:UIAlertControllerStyleAlert];
        [ac addAction:[UIAlertAction actionWithTitle:OLLocalizedString(@"OK", @"Acknowledgent to an alert dialog.") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){}]];
        [self presentViewController:ac animated:YES completion:NULL];
        return;
    }
    
    CardType cardType = getCardType(self.textFieldCardNumber.text);
    OLStripeCardType stripeCard;
    switch (cardType) {
        case kCardTypeAmex:
            stripeCard = kOLStripeCardTypeAmex;
            break;
        case kCardTypeMasterCard:
            stripeCard = kOLStripeCardTypeMastercard;
            break;
        case kCardTypeVisa:
            stripeCard = kOLStripeCardTypeVisa;
            break;
        case kCardTypeDiscover:
            stripeCard = kOLStripeCardTypeDiscover;
            break;
        default: {
            NSString *localizedDescription = OLLocalizedString(@"Enter a valid card number", @"");
            UIAlertController *ac = [UIAlertController alertControllerWithTitle:OLLocalizedString(@"Oops!", @"") message:localizedDescription preferredStyle:UIAlertControllerStyleAlert];
            [ac addAction:[UIAlertAction actionWithTitle:OLLocalizedString(@"OK", @"Acknowledgent to an alert dialog.") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){}]];
            [self presentViewController:ac animated:YES completion:NULL];
            return;
        }
    }
    
#ifndef KITE_UTILS
    if ([OLKitePrintSDK useStripeForCreditCards]){
#endif
        OLStripeCard *card = [[OLStripeCard alloc] init];
        card.number = [self cardNumber];
        card.expireMonth = expireMonth;
        card.expireYear = expireYear;
        card.cvv2 = [self cardCVV];
        
        [card saveAsLastUsedCard];
        [self.delegate creditCardCaptureController:(OLCreditCardCaptureViewController *) self.navigationController didFinishWithProofOfPayment:nil];
#ifndef KITE_UTILS
    }
    else{
        OLPayPalCard *card = [[OLPayPalCard alloc] init];
        card.type = (OLPayPalCardType)stripeCard;
        card.number = [self cardNumber];
        card.expireMonth = expireMonth;
        card.expireYear = expireYear;
        card.cvv2 = [self cardCVV];
        
        [card saveAsLastUsedCard];
        [self.delegate creditCardCaptureController:(OLCreditCardCaptureViewController *) self.navigationController didFinishWithProofOfPayment:nil];
    }
#endif
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
        return OLLocalizedString(@"Your 15-16 digit card number", @"");
    } else if (section == kOLSectionExpiryDate) {
        return OLLocalizedString(@"Your card expiry date", @"");
    } else if (section == kOLSectionCVV) {
        return OLLocalizedString(@"This is the 3-4 digit verification number/security code normally found on the back of your card", @"");
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
        textField.placeholder = OLLocalizedString(@"Card Number", @"");
        self.textFieldCardNumber = textField;
        
    } else if (indexPath.section == kOLSectionExpiryDate) {
        textField.placeholder = OLLocalizedString(@"MM/YY", @"Credit card date format: MonthMonth/YearYear");
        self.textFieldExpiryDate = textField;
    } else if (indexPath.section == kOLSectionCVV) {
        textField.placeholder = OLLocalizedString(@"CVV", @"The credit card security code");
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
