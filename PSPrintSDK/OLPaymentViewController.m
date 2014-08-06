//
//  PaymentViewController.m
//  Print Studio
//
//  Created by Deon Botha on 06/01/2014.
//  Copyright (c) 2014 Ocean Labs. All rights reserved.
//

#import "OLPaymentViewController.h"
#import "OLReceiptViewController.h"
#import "CardIO.h"
#import <PayPalMobile.h>
#import "OLPrintOrder.h"
#import "OLPrintJob.h"
#import <SVProgressHUD.h>
#import "OLPrintOrder+History.h"
#import "OLPostcardPrintJob.h"
#import "OLCheckoutViewController.h"
#import "Util.h"
#import "OLPayPalCard.h"
#import "OLKitePrintSDK.h"
#import "OLProductTemplate.h"
#import "OLCountry.h"
#import "OLJudoPayCard.h"

static NSString *const kCardIOAppToken = @"f1d07b66ad21407daf153c0ac66c09d7";
static const NSUInteger kSectionCount = 3;
static const NSUInteger kSectionOrderSummary = 0;
static const NSUInteger kSectionPromoCodes = 1;
static const NSUInteger kSectionPayment = 2;

@interface OLKitePrintSDK (Private)
+ (BOOL)useJudoPayForGBP;
@end

@interface OLPaymentViewController () <CardIOPaymentViewControllerDelegate, PayPalPaymentDelegate, UIActionSheetDelegate, UITextFieldDelegate>
@property (strong, nonatomic) OLPrintOrder *printOrder;
@property (strong, nonatomic) OLPayPalCard *card;
@property (strong, nonatomic) UITextField *promoTextField;
@property (strong, nonatomic) UIButton *promoApplyButton;
@property (strong, nonatomic) UIButton *payWithCreditCardButton;
@property (strong, nonatomic) UIButton *payWithPayPalButton;

@property (strong, nonatomic) UIView *loadingTemplatesView;
@property (strong, nonatomic) UITableView *tableView;
@property (assign, nonatomic) BOOL completedTemplateSyncSuccessfully;
@property (strong, nonatomic) NSString *paymentCurrencyCode;
@end

@interface OLPaymentViewController () <UITableViewDataSource, UITableViewDelegate>

@end

@implementation OLPaymentViewController

- (id)initWithPrintOrder:(OLPrintOrder *)printOrder {
    if (self = [super init]) {
        self.printOrder = printOrder;
        
    }
    
    return self;
}

- (BOOL)isShippingScreenOnTheStack {
    NSArray *vcStack = self.navigationController.viewControllers;
    if ([vcStack[vcStack.count - 2] isKindOfClass:[OLCheckoutViewController class]]) {
        return YES;
    }
    
    return NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Payment", @"");
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStyleGrouped];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
    
    if ([self isShippingScreenOnTheStack]) {
        self.tableView.tableHeaderView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkout_progress_indicator2"]];
    }
    
    self.payWithCreditCardButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    self.payWithCreditCardButton.backgroundColor = [UIColor colorWithRed:55 / 255.0f green:188 / 255.0f blue:155 / 255.0f alpha:1.0];
    [self.payWithCreditCardButton addTarget:self action:@selector(onButtonPayWithCreditCardClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.payWithCreditCardButton setTitle:NSLocalizedString(@"Pay with Card", @"") forState:UIControlStateNormal];
    
    self.payWithPayPalButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 52, self.view.frame.size.width, 44)];
    [self.payWithPayPalButton setTitle:NSLocalizedString(@"Pay with PayPal", @"") forState:UIControlStateNormal];
    [self.payWithPayPalButton addTarget:self action:@selector(onButtonPayWithPayPalClicked) forControlEvents:UIControlEventTouchUpInside];
    self.payWithPayPalButton.backgroundColor = [UIColor colorWithRed:74 / 255.0f green:137 / 255.0f blue:220 / 255.0f alpha:1.0];
    
    UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, CGRectGetMaxY(self.payWithPayPalButton.frame))];
    [footer addSubview:self.payWithCreditCardButton];
    [footer addSubview:self.payWithPayPalButton];
    self.tableView.tableFooterView = footer;
    
    [self updateViewsBasedOnPromoCodeChange]; // initialise based on promo state
    
    self.loadingTemplatesView = [[UIView alloc] initWithFrame:self.view.frame];
    self.loadingTemplatesView.backgroundColor = [UIColor colorWithRed:239 / 255.0 green:239 / 255.0 blue:244 / 255.0 alpha:1];
    UIActivityIndicatorView *ai = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    CGRect f = self.loadingTemplatesView.frame;
    ai.center = CGPointMake(f.size.width / 2, f.size.height / 2);
    [ai startAnimating];
    UILabel *loadingLabel = [[UILabel alloc] init];
    loadingLabel.text = @"Loading";
    loadingLabel.textColor = [UIColor colorWithRed:128 / 255.0 green:128 / 255.0 blue:128 / 255.0 alpha:1];
    [loadingLabel sizeToFit];
    loadingLabel.frame = CGRectMake((f.size.width - loadingLabel.frame.size.width) / 2, CGRectGetMaxY(ai.frame) + 10, loadingLabel.frame.size.width, loadingLabel.frame.size.height);
    
    [self.loadingTemplatesView addSubview:ai];
    [self.loadingTemplatesView addSubview:loadingLabel];
    [self.view addSubview:self.loadingTemplatesView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];

    UITapGestureRecognizer *tgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onBackgroundClicked)];
    tgr.cancelsTouchesInView = NO; // allow table cell selection to happen as normal
    [self.tableView addGestureRecognizer:tgr];
}

- (void)onBackgroundClicked {
    [self.promoTextField resignFirstResponder];
}

- (void)keyboardDidShow:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    CGSize size = [[userInfo objectForKey: UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    CGRect frame = CGRectMake(self.tableView.frame.origin.x,
                              self.tableView.frame.origin.y,
                              self.tableView.frame.size.width,
                              self.tableView.frame.size.height - size.height);
    self.tableView.frame = frame;
    self.tableView.clipsToBounds = NO;
}

- (void)keyboardWillHide:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    CGSize size = [[userInfo objectForKey: UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    self.tableView.frame = CGRectMake(self.tableView.frame.origin.x,
                                      self.tableView.frame.origin.y,
                                      self.tableView.frame.size.width,
                                      self.tableView.frame.size.height + size.height);
    self.tableView.clipsToBounds = YES;
}

- (BOOL)isTemplateSyncRequired {
    if (self.completedTemplateSyncSuccessfully) {
        return NO;
    }
    
    NSDate *lastSyncDate = [OLProductTemplate lastSyncDate];
    if (lastSyncDate == nil) {
        return YES; // if we've never synced successfully before then definitely sync now
    }
    
    NSTimeInterval elapsedSecondsSinceLastSync = -[lastSyncDate timeIntervalSinceNow];
    if (elapsedSecondsSinceLastSync > (60 * 60)) { // if > 1hr has passed since last successful sync then sync now
        return YES;
    }
    
    return NO;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [PayPalPaymentViewController setEnvironment:[OLKitePrintSDK paypalEnvironment]];
    [PayPalPaymentViewController prepareForPaymentUsingClientId:[OLKitePrintSDK paypalClientId]];
    
    if ([self isTemplateSyncRequired]) {
        [OLProductTemplate sync];
    }
    
    if (![OLProductTemplate isSyncInProgress]) {
        self.completedTemplateSyncSuccessfully = YES;
        self.loadingTemplatesView.hidden = YES;
        [self.tableView reloadData];
    } else {
        self.loadingTemplatesView.hidden = NO;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onTemplateSyncCompleted:) name:kNotificationTemplateSyncComplete object:nil];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)onTemplateSyncCompleted:(NSNotification *)notification {
    NSError *syncCompletionError = notification.userInfo[kNotificationKeyTemplateSyncError];
    if (!syncCompletionError) {
        self.completedTemplateSyncSuccessfully = YES;
        [self.tableView reloadData];
        [UIView animateWithDuration:0.3 animations:^{
            self.loadingTemplatesView.alpha = 0;
        } completion:^(BOOL finished) {
            self.loadingTemplatesView.hidden = YES;
        }];
    } else {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Oops!" message:syncCompletionError.localizedDescription delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"") otherButtonTitles:NSLocalizedString(@"Retry", @""), nil];
        [av show];
    }
}

- (void)updateViewsBasedOnPromoCodeChange {
    NSComparisonResult result = [self.printOrder.cost compare:[NSDecimalNumber zero]];
    if (result == NSOrderedAscending || result == NSOrderedSame) {
        self.payWithPayPalButton.hidden = YES;
        [self.payWithCreditCardButton setTitle:NSLocalizedString(@"Checkout for Free!", @"") forState:UIControlStateNormal];
    } else {
        self.payWithPayPalButton.hidden = NO;
        [self.payWithCreditCardButton setTitle:NSLocalizedString(@"Pay with Credit Card", @"") forState:UIControlStateNormal];
    }
    
    [self.tableView reloadData];
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (IBAction)onButtonApplyPromoCodeClicked:(id)sender {
    if (self.printOrder.promoCode) {
        // Clear promo code
        [self.printOrder clearPromoCode];
        [self updateViewsBasedOnPromoCodeChange];
    } else {
        // Apply promo code
        [SVProgressHUD showWithStatus:@"Checking Code"];
        [self.printOrder applyPromoCode:self.promoTextField.text withCompletionHandler:^(NSDecimalNumber *discount, NSError *error) {
            [self.tableView reloadData];
            if (error) {
                [SVProgressHUD dismiss];
                [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Oops", @"") message:error.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil] show];
            } else {
                [SVProgressHUD showSuccessWithStatus:nil];
                [self updateViewsBasedOnPromoCodeChange];
            }
        }];
    }
}

- (IBAction)onButtonPayWithCreditCardClicked {
    NSComparisonResult result = [self.printOrder.cost compare:[NSDecimalNumber zero]];
    if (result == NSOrderedAscending || result == NSOrderedSame) {
        // The user must have a promo code which reduces this order cost to nothing, lucky user :)
        [self submitOrderForPrintingWithProofOfPayment:nil];
    } else {

        id card = [OLPayPalCard lastUsedCard];
        
        if ([OLKitePrintSDK useJudoPayForGBP] && [self.printOrder.currencyCode isEqualToString:@"GBP"]) {
            card = [OLJudoPayCard lastUsedCard];
        }
        
        if (card == nil) {
            [self payWithNewCard];
        } else {
            UIActionSheet *paysheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Pay with new card", [NSString stringWithFormat:@"Pay with card ending %@", [[card numberMasked] substringFromIndex:[[card numberMasked] length] - 4]], nil];
            [paysheet showInView:self.view];
        }
    }
}


- (void)payWithNewCard {
    CardIOPaymentViewController *scanViewController = [[CardIOPaymentViewController alloc] initWithPaymentDelegate:self];
    scanViewController.appToken = kCardIOAppToken; // get your app token from the card.io website
    [self presentViewController:scanViewController animated:YES completion:nil];
}

- (void)payWithExistingPayPalCard:(OLPayPalCard *)card {
    if ([OLKitePrintSDK useJudoPayForGBP]) {
        NSAssert(![self.printOrder.currencyCode isEqualToString:@"GBP"], @"JudoPay should be used for GBP orders (and only for OceanLabs internal use)");
    }
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Processing", @"") maskType:SVProgressHUDMaskTypeBlack];
    [card chargeCard:self.printOrder.cost currencyCode:self.printOrder.currencyCode description:@"" completionHandler:^(NSString *proofOfPayment, NSError *error) {
        if (error) {
            [SVProgressHUD dismiss];
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Oops!", @"") message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            return;
        }
        
        [self submitOrderForPrintingWithProofOfPayment:proofOfPayment];
        [card saveAsLastUsedCard];
    }];
}

- (void)payWithExistingJudoPayCard:(OLJudoPayCard *)card {
    NSAssert([self.printOrder.currencyCode isEqualToString:@"GBP"], @"JudoPay should only be used for GBP orders (and only for OceanLabs internal use)");
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Processing", @"") maskType:SVProgressHUDMaskTypeBlack];
    [card chargeCard:self.printOrder.cost currency:kOLJudoPayCurrencyGBP description:@"" completionHandler:^(NSString *proofOfPayment, NSError *error) {
        if (error) {
            [SVProgressHUD dismiss];
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Oops!", @"") message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            return;
        }
        
        [self submitOrderForPrintingWithProofOfPayment:proofOfPayment];
        [card saveAsLastUsedCard];
    }];
}

- (IBAction)onButtonPayWithPayPalClicked {
    // Create a PayPalPayment
    PayPalPayment *payment = [[PayPalPayment alloc] init];
    payment.amount = self.printOrder.cost;
    payment.currencyCode = self.printOrder.currencyCode;
    payment.shortDescription = @"Product";
    NSAssert(payment.processable, @"oops");

    NSString *aPayerId = @"someuser@somedomain.com"; // TODO: Needed for vault lookup
    PayPalPaymentViewController *paymentViewController;
    paymentViewController = [[PayPalPaymentViewController alloc] initWithClientId:[OLKitePrintSDK paypalClientId]
                                                                    receiverEmail:[OLKitePrintSDK paypalReceiverEmail]
                                                                          payerId:aPayerId
                                                                          payment:payment
                                                                         delegate:self];
    paymentViewController.hideCreditCardButton = YES;
    [self presentViewController:paymentViewController animated:YES completion:nil];
}

- (void)submitOrderForPrintingWithProofOfPayment:(NSString *)proofOfPayment {
    self.printOrder.proofOfPayment = proofOfPayment;
    [[NSNotificationCenter defaultCenter] postNotificationName:kOLNotificationUserCompletedPayment object:self userInfo:@{kOLKeyUserInfoPrintOrder: self.printOrder}];
    [self.printOrder saveToHistory];
    
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Processing", @"") maskType:SVProgressHUDMaskTypeBlack];
    [self.printOrder submitForPrintingWithProgressHandler:^(NSUInteger totalAssetsUploaded, NSUInteger totalAssetsToUpload,
                                                            long long totalAssetBytesWritten, long long totalAssetBytesExpectedToWrite,
                                                            long long totalBytesWritten, long long totalBytesExpectedToWrite) {

        const float step = (1.0f / totalAssetsToUpload);
        float progress = totalAssetsUploaded * step + (totalAssetBytesWritten / (float) totalAssetBytesExpectedToWrite) * step;
        [SVProgressHUD showProgress:progress status:[NSString stringWithFormat:@"Uploading Images \n%lu / %lu", (unsigned long) totalAssetsUploaded + 1, (unsigned long) totalAssetsToUpload] maskType:SVProgressHUDMaskTypeBlack];
    } completionHandler:^(NSString *orderIdReceipt, NSError *error) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kOLNotificationPrintOrderSubmission object:self userInfo:@{kOLKeyUserInfoPrintOrder: self.printOrder}];
        [self.printOrder saveToHistory]; // save again as the print order has it's receipt set if it was successful, otherwise last error is set
        [SVProgressHUD dismiss];
        OLReceiptViewController *receiptVC = [[OLReceiptViewController alloc] initWithPrintOrder:self.printOrder];
        [self.navigationController pushViewController:receiptVC animated:YES];
        
        if (error) {
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Oops!", @"") message:error.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil] show];
        }
    }];
}

#pragma mark - CardIOPaymentViewControllerDelegate methods

- (void)userDidCancelPaymentViewController:(CardIOPaymentViewController *)paymentViewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)userDidProvideCreditCardInfoToPayByPayPal:(CardIOCreditCardInfo *)cardInfo {
    OLPayPalCardType type;
    switch (cardInfo.cardType) {
        case CardIOCreditCardTypeMastercard:
            type = kOLPayPalCardTypeMastercard;
            break;
        case CardIOCreditCardTypeVisa:
            type = kOLPayPalCardTypeVisa;
            break;
        case CardIOCreditCardTypeAmex:
            type = kOLPayPalCardTypeAmex;
            break;
        case CardIOCreditCardTypeDiscover:
            type = kOLPayPalCardTypeDiscover;
            break;
        default: {
            UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Oops!", @"") message:NSLocalizedString(@"Sorry we couldn't recognize your card. Please try again manually entering your card details if necessary.", @"") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
            [av show];
            return;
        }
    }
    
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Processing", @"") maskType:SVProgressHUDMaskTypeBlack];
    OLPayPalCard *card = [[OLPayPalCard alloc] init];
    card.type = type;
    card.number = cardInfo.cardNumber;
    card.expireMonth = cardInfo.expiryMonth;
    card.expireYear = cardInfo.expiryYear;
    card.cvv2 = cardInfo.cvv;
    
    [card storeCardWithCompletionHandler:^(NSError *error) {
        // ignore error as I'd rather the user gets a nice checkout experience than we store the card in PayPal vault.
        [self payWithExistingPayPalCard:card];
    }];

}

- (void)userDidProvideCreditCardInfoToPayByJudoPay:(CardIOCreditCardInfo *)cardInfo {
    OLJudoPayCardType type;
    switch (cardInfo.cardType) {
        case CardIOCreditCardTypeMastercard:
            type = kOLJudoPayCardTypeMastercard;
            break;
        case CardIOCreditCardTypeVisa:
            type = kOLJudoPayCardTypeVisa;
            break;
        case CardIOCreditCardTypeAmex:
            type = kOLJudoPayCardTypeAmex;
            break;
        case CardIOCreditCardTypeDiscover:
            type = kOLJudoPayCardTypeDiscover;
            break;
        default: {
            UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Oops!", @"") message:NSLocalizedString(@"Sorry we couldn't recognize your card. Please try again manually entering your card details if necessary.", @"") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
            [av show];
            return;
        }
    }
    
    OLJudoPayCard *card = [[OLJudoPayCard alloc] init];
    card.type = type;
    card.number = cardInfo.cardNumber;
    card.expireMonth = cardInfo.expiryMonth;
    card.expireYear = cardInfo.expiryYear;
    card.cvv2 = cardInfo.cvv;
    [self payWithExistingJudoPayCard:card];
}

- (void)userDidProvideCreditCardInfo:(CardIOCreditCardInfo *)cardInfo inPaymentViewController:(CardIOPaymentViewController *)paymentViewController {
    [self dismissViewControllerAnimated:YES completion:^() {
        if ([OLKitePrintSDK useJudoPayForGBP] && [self.printOrder.currencyCode isEqualToString:@"GBP"]) {
            [self userDidProvideCreditCardInfoToPayByJudoPay:cardInfo];
        } else {
            [self userDidProvideCreditCardInfoToPayByPayPal:cardInfo];
        }

    }];
}

#pragma mark - PayPalPaymentDelegate methods

- (void)payPalPaymentDidCancel {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)payPalPaymentDidComplete:(PayPalPayment *)completedPayment {
    [self dismissViewControllerAnimated:YES completion:nil];
    [self submitOrderForPrintingWithProofOfPayment:completedPayment.confirmation[@"proof_of_payment"][@"adaptive_payment"][@"pay_key"]];
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.completedTemplateSyncSuccessfully ? kSectionCount : 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case kSectionOrderSummary: {
            if (self.printOrder.jobs.count <= 1) {
                return self.printOrder.jobs.count;
            } else {
                return self.printOrder.jobs.count + 1; // additional cell to show total
            }
        };
        case kSectionPromoCodes: return 1;
        case kSectionPayment: return 0;
        default: return 0;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == kSectionPayment) {
        if ([OLKitePrintSDK environment] == kOLKitePrintSDKEnvironmentSandbox) {
            return NSLocalizedString(@"Payment (Sandbox)", @"");
        } else {
            return NSLocalizedString(@"Payment", @"");
        }
    } else if (section == kSectionOrderSummary) {
        return NSLocalizedString(@"Order Summary", @"");
    } else if (section == kSectionPromoCodes) {
        return NSLocalizedString(@"Promotional Codes", @"");
    }
    
    return @"";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    if (indexPath.section == kSectionOrderSummary) {
        static NSString *const CellIdentifier = @"JobCostSummaryCell";
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
            cell.textLabel.font = [UIFont systemFontOfSize:14];
            cell.detailTextLabel.font = [UIFont systemFontOfSize:14];
            cell.textLabel.adjustsFontSizeToFitWidth = YES;
            cell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
            cell.textLabel.minimumScaleFactor = 0.5;
            cell.detailTextLabel.minimumScaleFactor = 0.5;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        
        BOOL total = self.printOrder.jobs.count > 1 && indexPath.row == self.printOrder.jobs.count;
        NSDecimalNumber *cost = nil;
        NSString *currencyCode = self.printOrder.currencyCode;
        if (total) {
            cell.textLabel.text = NSLocalizedString(@"Total", @"");
            cell.textLabel.font = [UIFont boldSystemFontOfSize:cell.textLabel.font.pointSize];
            cell.detailTextLabel.font = [UIFont boldSystemFontOfSize:cell.detailTextLabel.font.pointSize];
            cost = [self.printOrder cost];
        } else {
            // TODO: Server to return parent product type.
            id<OLPrintJob> job = self.printOrder.jobs[indexPath.row];
            cell.textLabel.text = [NSString stringWithFormat:@"%lu x %@", (unsigned long)job.quantity, job.productName];
            OLProductTemplate *template = [OLProductTemplate templateWithId:job.templateId];
            if ([job.templateId isEqualToString:@"ps_postcard"] || [job.templateId isEqualToString:@"60_postcards"]) {
                cell.textLabel.text = [NSString stringWithFormat:@"%@", job.productName];
            } else if ([job.templateId isEqualToString:@"frames_2"] || [job.templateId isEqualToString:@"frames_3"] || [job.templateId isEqualToString:@"frames_4"]) {
                cell.textLabel.text = [NSString stringWithFormat:@"%lu x %@", (unsigned long) (job.quantity + template.quantityPerSheet - 1 ) / template.quantityPerSheet, job.productName];
            } else {
                cell.textLabel.text = [NSString stringWithFormat:@"Pack of %lu %@", (unsigned long)job.quantity, job.productName];
            }
            
            cell.textLabel.font = [UIFont systemFontOfSize:cell.textLabel.font.pointSize];
            cell.detailTextLabel.font = [UIFont systemFontOfSize:cell.detailTextLabel.font.pointSize];
            cost = self.printOrder.jobs.count == 1 ? self.printOrder.cost : [job costInCurrency:currencyCode]; // if there is only 1 job then use the print order total cost as a promo discount may have been applied
        }
        
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
        [formatter setCurrencyCode:currencyCode];
        cell.detailTextLabel.text = [formatter stringFromNumber:cost];
        
        return cell;
    } else if (indexPath.section == kSectionPromoCodes) {
        static NSString *const CellIdentifier = @"PromoCodeCell";
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            cell.frame = CGRectMake(0, 0, tableView.frame.size.width, 43);
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            UITextField *promoCodeTextField = [[UITextField alloc] initWithFrame:CGRectMake(20, 0, 232, 43)];
            promoCodeTextField.placeholder = NSLocalizedString(@"Code", @"");
            promoCodeTextField.delegate = self;
            
            UIButton *applyButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [applyButton setTitle:NSLocalizedString(@"Apply", @"") forState:UIControlStateNormal];
            applyButton.frame = CGRectMake(260, 7, 40, 30);
            applyButton.titleLabel.adjustsFontSizeToFitWidth = YES;
            applyButton.titleLabel.minimumScaleFactor = 0.5;
            [applyButton setTitleColor:[UIColor colorWithRed:0 green:122 / 255.0 blue:255 / 255.0 alpha:1.0f] forState:UIControlStateNormal];
            [applyButton setTitleColor:[UIColor colorWithRed:146 / 255.0 green:146 / 255.0 blue:146 / 255.0 alpha:1.0f] forState:UIControlStateDisabled];
            applyButton.enabled = NO;

            [applyButton addTarget:self action:@selector(onButtonApplyPromoCodeClicked:) forControlEvents:UIControlEventTouchUpInside];
            [cell addSubview:promoCodeTextField];
            [cell addSubview:applyButton];
            
            self.promoTextField = promoCodeTextField;
            self.promoApplyButton = applyButton;
        }
        
        if (self.printOrder.promoCode) {
            self.promoTextField.text = self.printOrder.promoCode;
            self.promoTextField.enabled = NO;
            [self.promoApplyButton setTitle:NSLocalizedString(@"Clear", @"") forState:UIControlStateNormal];
            [self.promoApplyButton sizeToFit];
        } else {
            self.promoTextField.text = @"";
            self.promoTextField.enabled = YES;
            [self.promoApplyButton setTitle:NSLocalizedString(@"Apply", @"") forState:UIControlStateNormal];
            [self.promoApplyButton sizeToFit];
        }
    }
    
    return cell;
}

#pragma mark - UIActionSheetDelegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        // pay with new card
        [self payWithNewCard];
    } else if (buttonIndex == 1) {
        // pay with existing card
        if ([OLKitePrintSDK useJudoPayForGBP] && [self.printOrder.currencyCode isEqualToString:@"GBP"]) {
            [self payWithExistingJudoPayCard:[OLJudoPayCard lastUsedCard]];
        } else {
            [self payWithExistingPayPalCard:[OLPayPalCard lastUsedCard]];
        }
    }
}

#pragma mark - UITextFieldDelegate methods

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField == self.promoTextField) {
        NSString *newPromoText = [textField.text stringByReplacingCharactersInRange:range withString:string];
        self.promoApplyButton.enabled = newPromoText.length > 0;
    }
    
    return YES;
}

#pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        // Clicked cancel
        [self.navigationController popViewControllerAnimated:YES];
    } else if (buttonIndex == 1) {
        // Clicked retry, attempt syncing again
        [OLProductTemplate sync];
    }
}

@end
