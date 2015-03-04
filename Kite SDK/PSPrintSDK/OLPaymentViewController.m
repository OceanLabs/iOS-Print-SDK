//
//  PaymentViewController.m
//  Kite Print SDK
//
//  Created by Deon Botha on 06/01/2014.
//  Copyright (c) 2014 Ocean Labs. All rights reserved.
//

#import "OLPaymentViewController.h"
#import "OLReceiptViewController.h"
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
#import "OLConstants.h"
#import "OLCreditCardCaptureViewController.h"
#import "OLAnalytics.h"

#ifdef OL_KITE_OFFER_PAYPAL
#import <PayPalMobile.h>
#endif

#ifdef OL_KITE_OFFER_APPLE_PAY
#import <Stripe+ApplePay.h>
#endif

@import PassKit;

static NSString *const kSectionOrderSummary = @"kSectionOrderSummary";
static NSString *const kSectionPromoCodes = @"kSectionPromoCodes";
static NSString *const kSectionPayment = @"kSectionPayment";
static NSString *const kSectionContinueShopping = @"kSectionContinueShopping";

@interface OLKitePrintSDK (Private)
+ (BOOL)useJudoPayForGBP;
@end

@interface OLReceiptViewController (Private)
@property (nonatomic, assign) BOOL presentedModally;
@end

@interface OLPaymentViewController () <
#ifdef OL_KITE_OFFER_PAYPAL
PayPalPaymentDelegate,
#endif
UIActionSheetDelegate, UITextFieldDelegate, OLCreditCardCaptureDelegate, UINavigationControllerDelegate>

@property (strong, nonatomic) OLPrintOrder *printOrder;
@property (strong, nonatomic) OLPayPalCard *card;
@property (strong, nonatomic) UITextField *promoTextField;
@property (strong, nonatomic) UIButton *promoApplyButton;
@property (strong, nonatomic) UIButton *payWithCreditCardButton;
@property (strong, nonatomic) UILabel *poweredByKiteLabel;

#ifdef OL_KITE_OFFER_APPLE_PAY
@property (strong, nonatomic) UIButton *payWithApplePayButton;
@property (assign, nonatomic) BOOL applePayIsAvailable;
#endif

@property (strong, nonatomic) UIView *loadingTemplatesView;
@property (strong, nonatomic) UITableView *tableView;
@property (assign, nonatomic) BOOL completedTemplateSyncSuccessfully;
@property (strong, nonatomic) NSString *paymentCurrencyCode;
@property (strong, nonatomic) NSMutableArray* sections;

#ifdef OL_KITE_OFFER_PAYPAL
@property (strong, nonatomic) UIButton *payWithPayPalButton;
#endif

@end

@interface OLPaymentViewController () <UITableViewDataSource, UITableViewDelegate
#ifdef OL_KITE_OFFER_APPLE_PAY
, PKPaymentAuthorizationViewControllerDelegate
#endif
>
@property (nonatomic, assign) BOOL presentedModally;
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

#ifdef OL_KITE_OFFER_APPLE_PAY
-(BOOL)isApplePayAvailable{
    PKPaymentRequest *request = [Stripe
                                 paymentRequestWithMerchantIdentifier:[OLKitePrintSDK appleMerchantID]
                                 amount:self.printOrder.cost
                                 currency:self.printOrder.currencyCode
                                 description:@"Prints"];
    
    return [Stripe canSubmitPaymentRequest:request];
}
#endif

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", @"")
                                                                             style:UIBarButtonItemStyleBordered
                                                                            target:nil
                                                                            action:nil];
    
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackPaymentScreenViewedForOrder:self.printOrder];
#endif
    
    
#ifdef OL_KITE_OFFER_APPLE_PAY
    self.applePayIsAvailable = [self isApplePayAvailable];
#endif
    
    self.title = NSLocalizedStringFromTableInBundle(@"Payment", @"KitePrintSDK", [OLConstants bundle], @"");
    
    self.sections = [@[kSectionOrderSummary, kSectionPromoCodes, kSectionPayment] mutableCopy];
    
    if ([self.delegate respondsToSelector:@selector(shouldShowContinueShoppingButton)]) {
        if ([self.delegate shouldShowContinueShoppingButton]){
            [self.sections insertObject:kSectionContinueShopping atIndex:1];
        }
    }
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStyleGrouped];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
    
    if ([self isShippingScreenOnTheStack]) {
        self.tableView.tableHeaderView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkout_progress_indicator2"]];
        self.tableView.tableHeaderView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.tableView.tableHeaderView.frame.size.height * [UIScreen mainScreen].bounds.size.width / 320.0);
    }
    
#ifdef OL_KITE_OFFER_APPLE_PAY
    CGFloat heightDiff = self.applePayIsAvailable ? 0 : 52;
#else 
    CGFloat heightDiff = 52;
#endif
    
    self.payWithCreditCardButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 52 - heightDiff, self.view.frame.size.width, 44)];
    self.payWithCreditCardButton.backgroundColor = [UIColor colorWithRed:55 / 255.0f green:188 / 255.0f blue:155 / 255.0f alpha:1.0];
    [self.payWithCreditCardButton addTarget:self action:@selector(onButtonPayWithCreditCardClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.payWithCreditCardButton setTitle:NSLocalizedStringFromTableInBundle(@"Pay with Card", @"KitePrintSDK", [OLConstants bundle], @"") forState:UIControlStateNormal];
    CGFloat maxY = CGRectGetMaxY(self.payWithCreditCardButton.frame);

    
#ifdef OL_KITE_OFFER_PAYPAL
    self.payWithPayPalButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 104 - heightDiff, self.view.frame.size.width, 44)];
    [self.payWithPayPalButton setTitle:NSLocalizedStringFromTableInBundle(@"Pay with PayPal", @"KitePrintSDK", [OLConstants bundle], @"") forState:UIControlStateNormal];
    [self.payWithPayPalButton addTarget:self action:@selector(onButtonPayWithPayPalClicked) forControlEvents:UIControlEventTouchUpInside];
    self.payWithPayPalButton.backgroundColor = [UIColor colorWithRed:74 / 255.0f green:137 / 255.0f blue:220 / 255.0f alpha:1.0];
#endif
    
#ifdef OL_KITE_OFFER_APPLE_PAY
    self.payWithApplePayButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    self.payWithApplePayButton.backgroundColor = [UIColor blackColor];
    [self.payWithApplePayButton addTarget:self action:@selector(onButtonPayWithApplePayClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.payWithApplePayButton setTitle:NSLocalizedStringFromTableInBundle(@"Pay with Pay", @"KitePrintSDK", [OLConstants bundle], @"") forState:UIControlStateNormal];
#endif
    
    self.poweredByKiteLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 100, 40, 40)];
    self.poweredByKiteLabel.text = NSLocalizedString(@"Powered by Kite.ly", @"");
    self.poweredByKiteLabel.font = [UIFont systemFontOfSize:13];
    self.poweredByKiteLabel.textColor = [UIColor lightGrayColor];
    [self.poweredByKiteLabel sizeToFit];
    self.poweredByKiteLabel.frame = CGRectMake((self.view.frame.size.width - self.poweredByKiteLabel.frame.size.width) / 2, 168 - heightDiff, self.poweredByKiteLabel.frame.size.width, self.poweredByKiteLabel.frame.size.height);
    maxY = CGRectGetMaxY(self.poweredByKiteLabel.frame);
    
    UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, maxY)];
    [footer addSubview:self.payWithCreditCardButton];
    [footer addSubview:self.poweredByKiteLabel];

#ifdef OL_KITE_OFFER_PAYPAL
    [footer addSubview:self.payWithPayPalButton];
#endif
    
#ifdef OL_KITE_OFFER_APPLE_PAY
    if (self.applePayIsAvailable){
        [footer addSubview:self.payWithApplePayButton];
    }
#endif
    
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
#ifdef OL_KITE_OFFER_PAYPAL
    [PayPalMobile initializeWithClientIdsForEnvironments:@{[OLKitePrintSDK paypalEnvironment] : [OLKitePrintSDK paypalClientId]}];
    [PayPalMobile preconnectWithEnvironment:[OLKitePrintSDK paypalEnvironment]];
#endif

#ifdef OL_KITE_OFFER_APPLE_PAY
    [Stripe setDefaultPublishableKey:[OLKitePrintSDK stripePublishableKey]];
#endif
    
    if ([self isTemplateSyncRequired]) {
        [OLProductTemplate sync];
    }
    
    if (![OLProductTemplate isSyncInProgress]) {
        self.completedTemplateSyncSuccessfully = YES;
        self.loadingTemplatesView.hidden = YES;
        [self.tableView reloadData];
        [self positionPoweredByKiteLabel];
    } else {
        self.loadingTemplatesView.hidden = NO;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onTemplateSyncCompleted:) name:kNotificationTemplateSyncComplete object:nil];
    }
}

- (void)positionPoweredByKiteLabel {
    // position Powered by Kite label dynamically based on content size
    CGRect tvFrame = self.tableView.frame;
    CGFloat extraHeight = 0;
    if ([self.delegate respondsToSelector:@selector(shouldShowContinueShoppingButton)] && [self.delegate shouldShowContinueShoppingButton]){
        extraHeight = 64;
    }
    CGFloat height = tvFrame.size.height - (self.tableView.contentSize.height - self.tableView.tableHeaderView.frame.size.height - extraHeight);
    
    if (height > self.tableView.tableFooterView.frame.size.height) {
        CGRect frame = self.tableView.tableFooterView.frame;
        self.tableView.tableFooterView.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, height);
        frame = self.poweredByKiteLabel.frame;
        self.poweredByKiteLabel.frame = CGRectMake(frame.origin.x, height - frame.size.height, frame.size.width, frame.size.height);
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
        [self positionPoweredByKiteLabel];
        [UIView animateWithDuration:0.3 animations:^{
            self.loadingTemplatesView.alpha = 0;
        } completion:^(BOOL finished) {
            self.loadingTemplatesView.hidden = YES;
        }];
    } else {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Oops!", @"KitePrintSDK", [OLConstants bundle], @"") message:syncCompletionError.localizedDescription delegate:self cancelButtonTitle:NSLocalizedStringFromTableInBundle(@"Cancel", @"KitePrintSDK", [OLConstants bundle], @"") otherButtonTitles:NSLocalizedStringFromTableInBundle(@"Retry", @"KitePrintSDK", [OLConstants bundle], @""), nil];
        [av show];
    }
}

- (void)updateViewsBasedOnPromoCodeChange {
    NSComparisonResult result = [self.printOrder.cost compare:[NSDecimalNumber zero]];
    if (result == NSOrderedAscending || result == NSOrderedSame) {
#ifdef OL_KITE_OFFER_PAYPAL
        self.payWithPayPalButton.hidden = YES;
#endif
#ifdef OL_KITE_OFFER_APPLE_PAY
        self.payWithApplePayButton.hidden = YES;
#endif
        [self.payWithCreditCardButton setTitle:NSLocalizedStringFromTableInBundle(@"Checkout for Free!", @"KitePrintSDK", [OLConstants bundle], @"") forState:UIControlStateNormal];
    } else {
#ifdef OL_KITE_OFFER_PAYPAL
        self.payWithPayPalButton.hidden = NO;
#endif
#ifdef OL_KITE_OFFER_APPLE_PAY
        self.payWithApplePayButton.hidden = NO;
#endif
        [self.payWithCreditCardButton setTitle:NSLocalizedStringFromTableInBundle(@"Pay with Credit Card", @"KitePrintSDK", [OLConstants bundle], @"") forState:UIControlStateNormal];
    }
    
    [self.tableView reloadData];
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (void)onButtonContinueShoppingClicked:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(userDidTapContinueShoppingButton)]){
        [self.delegate userDidTapContinueShoppingButton];
    }
    else{ // Try as best we can to go to the beginning of the app
        NSMutableArray *navigationStack = self.navigationController.viewControllers.mutableCopy;
        if (navigationStack.count > 2 && [navigationStack[navigationStack.count - 2] isKindOfClass:[OLCheckoutViewController class]]) {
            // clear the stack as we don't want the user to be able to return to payment as that stage of the journey is now complete.
            [navigationStack removeObjectsInRange:NSMakeRange(1, navigationStack.count - 2)];
            self.navigationController.viewControllers = navigationStack;
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
}

- (IBAction)onButtonApplyPromoCodeClicked:(id)sender {
    if (self.printOrder.promoCode) {
        // Clear promo code
        [self.printOrder clearPromoCode];
        [self updateViewsBasedOnPromoCodeChange];
    } else {
        // Apply promo code
        [SVProgressHUD showWithStatus:NSLocalizedStringFromTableInBundle(@"Checking Code", @"KitePrintSDK", [OLConstants bundle], @"")];
        [self.printOrder applyPromoCode:self.promoTextField.text withCompletionHandler:^(NSDecimalNumber *discount, NSError *error) {
            [self.tableView reloadData];
            if (error) {
                [SVProgressHUD dismiss];
                [[[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Oops", @"KitePrintSDK", [OLConstants bundle], @"") message:error.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedStringFromTableInBundle(@"OK", @"KitePrintSDK", [OLConstants bundle], @"") otherButtonTitles:nil] show];
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
        [self submitOrderForPrintingWithProofOfPayment:nil completion:^void(PKPaymentAuthorizationStatus status){}];
    } else {
        
        id card = [OLPayPalCard lastUsedCard];
        
        if ([OLKitePrintSDK useJudoPayForGBP] && [self.printOrder.currencyCode isEqualToString:@"GBP"]) {
            card = [OLJudoPayCard lastUsedCard];
        }
        
        if (card == nil) {
            [self payWithNewCard];
        } else {
            UIActionSheet *paysheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedStringFromTableInBundle(@"Cancel", @"KitePrintSDK", [OLConstants bundle], @"") destructiveButtonTitle:nil otherButtonTitles:NSLocalizedStringFromTableInBundle(@"Pay with new card", @"KitePrintSDK", [OLConstants bundle], @""), [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Pay with card ending %@", @"KitePrintSDK", [OLConstants bundle], @""), [[card numberMasked] substringFromIndex:[[card numberMasked] length] - 4]], nil];
            [paysheet showInView:self.view];
        }
    }
}


- (void)payWithNewCard {
    OLCreditCardCaptureViewController *ccCaptureController = [[OLCreditCardCaptureViewController alloc] initWithPrintOrder:self.printOrder];
    ccCaptureController.delegate = self;
    [self presentViewController:ccCaptureController animated:YES completion:nil];
}

- (void)payWithExistingPayPalCard:(OLPayPalCard *)card {
    if ([OLKitePrintSDK useJudoPayForGBP]) {
        NSAssert(![self.printOrder.currencyCode isEqualToString:@"GBP"], @"JudoPay should be used for GBP orders (and only for OceanLabs internal use)");
    }
    [SVProgressHUD showWithStatus:NSLocalizedStringFromTableInBundle(@"Processing", @"KitePrintSDK", [OLConstants bundle], @"") maskType:SVProgressHUDMaskTypeBlack];
    [card chargeCard:self.printOrder.cost currencyCode:self.printOrder.currencyCode description:@"" completionHandler:^(NSString *proofOfPayment, NSError *error) {
        if (error) {
            [SVProgressHUD dismiss];
            [[[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Oops!", @"KitePrintSDK", [OLConstants bundle], @"") message:error.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedStringFromTableInBundle(@"OK", @"KitePrintSDK", [OLConstants bundle], @"") otherButtonTitles:nil] show];
            return;
        }
        
        [self submitOrderForPrintingWithProofOfPayment:proofOfPayment completion:^void(PKPaymentAuthorizationStatus status){}];
        [card saveAsLastUsedCard];
    }];
}

- (void)payWithExistingJudoPayCard:(OLJudoPayCard *)card {
    NSAssert([self.printOrder.currencyCode isEqualToString:@"GBP"], @"JudoPay should only be used for GBP orders (and only for OceanLabs internal use)");
    [SVProgressHUD showWithStatus:NSLocalizedStringFromTableInBundle(@"Processing", @"KitePrintSDK", [OLConstants bundle], @"") maskType:SVProgressHUDMaskTypeBlack];
    [card chargeCard:self.printOrder.cost currency:kOLJudoPayCurrencyGBP description:@"" completionHandler:^(NSString *proofOfPayment, NSError *error) {
        if (error) {
            [SVProgressHUD dismiss];
            [[[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Oops!", @"KitePrintSDK", [OLConstants bundle], @"") message:error.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedStringFromTableInBundle(@"OK", @"KitePrintSDK", [OLConstants bundle], @"") otherButtonTitles:nil] show];
            return;
        }
        
        [self submitOrderForPrintingWithProofOfPayment:proofOfPayment completion:^void(PKPaymentAuthorizationStatus status){}];
        [card saveAsLastUsedCard];
    }];
}

#ifdef OL_KITE_OFFER_PAYPAL
- (IBAction)onButtonPayWithPayPalClicked {
    // Create a PayPalPayment
    PayPalPayment *payment = [[PayPalPayment alloc] init];
    payment.amount = self.printOrder.cost;
    payment.currencyCode = self.printOrder.currencyCode;
    payment.shortDescription = @"Product";
    NSAssert(payment.processable, @"oops");
    
    PayPalPaymentViewController *paymentViewController;
    PayPalConfiguration *payPalConfiguration = [[PayPalConfiguration alloc] init];
    payPalConfiguration.acceptCreditCards = NO;
    paymentViewController = [[PayPalPaymentViewController alloc] initWithPayment:payment configuration:payPalConfiguration delegate:self];
    [self presentViewController:paymentViewController animated:YES completion:nil];
}
#endif

#ifdef OL_KITE_OFFER_APPLE_PAY
- (IBAction)onButtonPayWithApplePayClicked{
    PKPaymentRequest *paymentRequest = [Stripe
                                        paymentRequestWithMerchantIdentifier:[OLKitePrintSDK appleMerchantID]
                                        amount:self.printOrder.cost
                                        currency:self.printOrder.currencyCode
                                        description:@"Prints"];
    UIViewController *paymentController;
    //#if DEBUG
    //    paymentController = [[STPTestPaymentAuthorizationViewController alloc]
    //                         initWithPaymentRequest:paymentRequest];
    //    paymentController.delegate = self;
    //#else
    paymentController = [[PKPaymentAuthorizationViewController alloc]
                         initWithPaymentRequest:paymentRequest];
    ((PKPaymentAuthorizationViewController *)paymentController).delegate = self;
    //#end
    [self presentViewController:paymentController animated:YES completion:nil];
}
#endif

- (void)submitOrderForPrintingWithProofOfPayment:(NSString *)proofOfPayment completion:(void (^)(PKPaymentAuthorizationStatus)) handler{
    self.printOrder.proofOfPayment = proofOfPayment;
    
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackPaymentCompletedForOrder:self.printOrder];
#endif
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kOLNotificationUserCompletedPayment object:self userInfo:@{kOLKeyUserInfoPrintOrder: self.printOrder}];
    [self.printOrder saveToHistory];
    
    __block BOOL handlerUsed = NO;
    
    [SVProgressHUD showWithStatus:NSLocalizedStringFromTableInBundle(@"Processing", @"KitePrintSDK", [OLConstants bundle], @"") maskType:SVProgressHUDMaskTypeBlack];
    [self.printOrder submitForPrintingWithProgressHandler:^(NSUInteger totalAssetsUploaded, NSUInteger totalAssetsToUpload,
                                                            long long totalAssetBytesWritten, long long totalAssetBytesExpectedToWrite,
                                                            long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        if (!handlerUsed) {
            handler(PKPaymentAuthorizationStatusSuccess);
            handlerUsed = YES;
        }
        
        const float step = (1.0f / totalAssetsToUpload);
        float progress = totalAssetsUploaded * step + (totalAssetBytesWritten / (float) totalAssetBytesExpectedToWrite) * step;
        [SVProgressHUD showProgress:progress status:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Uploading Images \n%lu / %lu", @"KitePrintSDK", [OLConstants bundle], @""), (unsigned long) totalAssetsUploaded + 1, (unsigned long) totalAssetsToUpload] maskType:SVProgressHUDMaskTypeBlack];
    } completionHandler:^(NSString *orderIdReceipt, NSError *error) {
        if (error) {
            handler(PKPaymentAuthorizationStatusFailure);
            [[[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Oops!", @"KitePrintSDK", [OLConstants bundle], @"") message:error.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedStringFromTableInBundle(@"OK", @"KitePrintSDK", [OLConstants bundle], @"") otherButtonTitles:nil] show];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kOLNotificationPrintOrderSubmission object:self userInfo:@{kOLKeyUserInfoPrintOrder: self.printOrder}];
        
#ifndef OL_NO_ANALYTICS
        [OLAnalytics trackOrderSubmission:self.printOrder];
#endif
        
        [self.printOrder saveToHistory]; // save again as the print order has it's receipt set if it was successful, otherwise last error is set
        [SVProgressHUD dismiss];
        OLReceiptViewController *receiptVC = [[OLReceiptViewController alloc] initWithPrintOrder:self.printOrder];
        receiptVC.presentedModally = self.presentedModally;
        [self.navigationController pushViewController:receiptVC animated:YES];
    }];
}

#pragma mark - PayPalPaymentDelegate methods

#ifdef OL_KITE_OFFER_PAYPAL
- (void)payPalPaymentDidCancel:(PayPalPaymentViewController *)paymentViewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)payPalPaymentViewController:(PayPalPaymentViewController *)paymentViewController didCompletePayment:(PayPalPayment *)completedPayment {
    [self dismissViewControllerAnimated:YES completion:nil];
    [self submitOrderForPrintingWithProofOfPayment:completedPayment.confirmation[@"response"][@"id"] completion:^void(PKPaymentAuthorizationStatus status){}];
}
#endif

#pragma mark - Apple Pay Delegate Methods

#ifdef OL_KITE_OFFER_APPLE_PAY
- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller
                       didAuthorizePayment:(PKPayment *)payment
                                completion:(void (^)(PKPaymentAuthorizationStatus))completion {
    /*
     We'll implement this method below in 'Creating a single-use token'.
     Note that we've also been given a block that takes a
     PKPaymentAuthorizationStatus. We'll call this function with either
     PKPaymentAuthorizationStatusSuccess or PKPaymentAuthorizationStatusFailure
     after all of our asynchronous code is finished executing. This is how the
     PKPaymentAuthorizationViewController knows when and how to update its UI.
     */
    [self handlePaymentAuthorizationWithPayment:payment completion:completion];
}

- (void)paymentAuthorizationViewControllerDidFinish:(PKPaymentAuthorizationViewController *)controller {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark Stripe

- (void)handlePaymentAuthorizationWithPayment:(PKPayment *)payment
                                   completion:(void (^)(PKPaymentAuthorizationStatus))completion {
    [Stripe createTokenWithPayment:payment
                        completion:^(STPToken *token, NSError *error) {
                            if (error) {
                                completion(PKPaymentAuthorizationStatusFailure);
                                return;
                            }
                            /*
                             We'll implement this below in "Sending the token to your server".
                             Notice that we're passing the completion block through.
                             See the above comment in didAuthorizePayment to learn why.
                             */
                            [self createBackendChargeWithToken:token completion:completion];
                        }];
}

- (void)createBackendChargeWithToken:(STPToken *)token
                          completion:(void (^)(PKPaymentAuthorizationStatus))completion {
    [self submitOrderForPrintingWithProofOfPayment:token.tokenId completion:^void(PKPaymentAuthorizationStatus status){}];
}
#endif

#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.completedTemplateSyncSuccessfully ? [self.sections count] : 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSString* sectionString = [self.sections objectAtIndex:section];
    if ([sectionString isEqualToString:kSectionOrderSummary]) {
        if (self.printOrder.jobs.count <= 1) {
            return self.printOrder.jobs.count;
        } else {
            return self.printOrder.jobs.count + 1; // additional cell to show total
        }
    }
    else if ([sectionString isEqualToString:kSectionContinueShopping]){
        return 1;
    }
    else if ([sectionString isEqualToString:kSectionPromoCodes]){
        return 1;
    }
    else if ([sectionString isEqualToString:kSectionPayment]){
        return 0;
    }
    else{
        return 0;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString* sectionString = [self.sections objectAtIndex:section];
    if ([sectionString isEqualToString:kSectionPayment]) {
        if ([OLKitePrintSDK environment] == kOLKitePrintSDKEnvironmentSandbox) {
            return NSLocalizedStringFromTableInBundle(@"Payment Options (Sandbox)", @"KitePrintSDK", [OLConstants bundle], @"");
        } else {
            return NSLocalizedStringFromTableInBundle(@"Payment Options", @"KitePrintSDK", [OLConstants bundle], @"");
        }
    } else if ([sectionString isEqualToString:kSectionOrderSummary]) {
        return NSLocalizedStringFromTableInBundle(@"Order Summary", @"KitePrintSDK", [OLConstants bundle], @"");
    } else if ([sectionString isEqualToString:kSectionPromoCodes]) {
        return NSLocalizedStringFromTableInBundle(@"Promotional Codes", @"KitePrintSDK", [OLConstants bundle], @"");
    } else if ([sectionString isEqualToString:kSectionContinueShopping]) {
        return @""; //Don't need a section title here.
    }
    
    return @"";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    NSString* sectionString = [self.sections objectAtIndex:indexPath.section];
    if ([sectionString isEqualToString:kSectionOrderSummary]) {
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
            cell.textLabel.text = NSLocalizedStringFromTableInBundle(@"Total", @"KitePrintSDK", [OLConstants bundle], @"");
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
            } else if ([job.templateId isEqualToString:@"frames_2x2"] || [job.templateId isEqualToString:@"frames_3x3"] || [job.templateId isEqualToString:@"frames_4x4"] || [job.templateId hasPrefix:@"frames"]) {
                cell.textLabel.text = [NSString stringWithFormat:@"%lu x %@", (unsigned long) (job.quantity + template.quantityPerSheet - 1 ) / template.quantityPerSheet, job.productName];
            } else if ([job.templateId rangeOfString:@"poster"].location != NSNotFound){
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
    } else if ([sectionString isEqualToString:kSectionContinueShopping]) {
        static NSString *const CellIdentifier = @"ContinueShoppingCell";
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.frame = CGRectMake(0, 0, tableView.frame.size.width, 44);
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        UIButton *continueShoppingButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [continueShoppingButton setTitle:NSLocalizedStringFromTableInBundle(@"Continue Shopping", @"KitePrintSDK", [OLConstants bundle], @"") forState:UIControlStateNormal];
        continueShoppingButton.frame = cell.frame;
        continueShoppingButton.titleLabel.adjustsFontSizeToFitWidth = YES;
        continueShoppingButton.titleLabel.minimumScaleFactor = 0.5;
        [continueShoppingButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [continueShoppingButton setBackgroundColor:[UIColor colorWithRed:74 / 255.0f green:137 / 255.0f blue:220 / 255.0f alpha:1.0]];
        [continueShoppingButton addTarget:self action:@selector(onButtonContinueShoppingClicked:) forControlEvents:UIControlEventTouchUpInside];
        [cell addSubview:continueShoppingButton];
    } else if ([sectionString isEqualToString:kSectionPromoCodes]) {
        static NSString *const CellIdentifier = @"PromoCodeCell";
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            cell.frame = CGRectMake(0, 0, tableView.frame.size.width, 43);
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            UITextField *promoCodeTextField = [[UITextField alloc] initWithFrame:CGRectMake(20, 0, self.view.frame.size.width - 20 - 60, 43)];
            promoCodeTextField.placeholder = NSLocalizedStringFromTableInBundle(@"Code", @"KitePrintSDK", [OLConstants bundle], @"");
            promoCodeTextField.delegate = self;
            
            UIButton *applyButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [applyButton setTitle:NSLocalizedStringFromTableInBundle(@"Apply", @"KitePrintSDK", [OLConstants bundle], @"") forState:UIControlStateNormal];
            applyButton.frame = CGRectMake(self.view.frame.size.width - 60, 7, 40, 30);
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
            self.promoApplyButton.enabled = YES;
            [self.promoApplyButton setTitle:NSLocalizedStringFromTableInBundle(@"Clear", @"KitePrintSDK", [OLConstants bundle], @"") forState:UIControlStateNormal];
            [self.promoApplyButton sizeToFit];
        } else {
            self.promoTextField.text = @"";
            self.promoTextField.enabled = YES;
            [self.promoApplyButton setTitle:NSLocalizedStringFromTableInBundle(@"Apply", @"KitePrintSDK", [OLConstants bundle], @"") forState:UIControlStateNormal];
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

#pragma mark - OLCreditCardCaptureDelegate methods

- (void)creditCardCaptureController:(OLCreditCardCaptureViewController *)vc didFinishWithProofOfPayment:(NSString *)proofOfPayment {
    [self dismissViewControllerAnimated:YES completion:^{
        [self submitOrderForPrintingWithProofOfPayment:proofOfPayment completion:^void(PKPaymentAuthorizationStatus status){}];
    }];
}


@end
