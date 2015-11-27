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
#import "SVProgressHUD.h"
#import "OLPrintOrder+History.h"
#import "OLPostcardPrintJob.h"
#import "OLCheckoutViewController.h"
#import "Util.h"
#import "OLPayPalCard.h"
#import "OLKitePrintSDK.h"
#import "OLProductTemplate.h"
#import "OLCountry.h"
#import "OLJudoPayCard.h"
#import "NSObject+Utils.h"
#import "OLConstants.h"
#import "OLCreditCardCaptureViewController.h"
#import "OLAnalytics.h"
#import "OLPaymentLineItem.h"
#import "UIView+RoundRect.h"
#import "OLBaseRequest.h"
#import "OLPrintOrderCost.h"
#import "OLKiteABTesting.h"
#import "SDWebImageManager.h"
#import "UIImage+ColorAtPixel.h"
#import "UIImage+ImageNamedInKiteBundle.h"
#import "UIImageView+FadeIn.h"
#import "NSDecimalNumber+CostFormatter.h"
#import "OLKiteUtils.h"
#import "OLKiteViewController.h"
#import "OLOrderReviewViewController.h"
#import "OLPhotoSelectionViewController.h"
#import "OLPhotobookViewController.h"
#import "NSObject+Utils.h"
#import "OLProductOverviewViewController.h"
#import "OLOrdersViewController.h"
#import "OLSingleImageProductReviewViewController.h"

#ifdef OL_KITE_OFFER_PAYPAL
#import "PayPalMobile.h"
#endif

#ifdef OL_KITE_OFFER_APPLE_PAY
#import <Stripe/Stripe+ApplePay.h>
#import <ApplePayStubs/STPTestPaymentAuthorizationViewController.h>
#endif

@import PassKit;
@import AddressBook;

static NSString *const kSectionOrderSummary = @"kSectionOrderSummary";
static NSString *const kSectionPromoCodes = @"kSectionPromoCodes";
static NSString *const kSectionPayment = @"kSectionPayment";
static NSString *const kSectionContinueShopping = @"kSectionContinueShopping";

@interface OLProductPrintJob ()
@property (strong, nonatomic) NSMutableDictionary *options;
@end

@interface OLKiteViewController ()

@property (strong, nonatomic) OLPrintOrder *printOrder;

@end

@interface OLProduct (PrivateMethods)

- (NSDecimalNumber*) unitCostDecimalNumber;

@end


@interface OLAsset (Private)

@property (strong, nonatomic) id<OLAssetDataSource> dataSource;

@end

@interface OLOrdersViewController (Private)

- (void)dismiss;
- (IBAction)emailButtonPushed:(id)sender;

@end

@interface OLCheckoutViewController (Private)

+ (BOOL)validateEmail:(NSString *)candidate;
- (void)onButtonDoneClicked;

@end

@interface OLKitePrintSDK (Private)
+ (BOOL)useJudoPayForGBP;
+ (BOOL)useStripeForCreditCards;

#ifdef OL_KITE_OFFER_PAYPAL
+ (NSString *_Nonnull)paypalEnvironment;
+ (NSString *_Nonnull)paypalClientId;
#endif

#ifdef OL_KITE_OFFER_APPLE_PAY
+ (NSString *_Nonnull)stripePublishableKey;
+ (NSString *_Nonnull)appleMerchantID;
+ (NSString *)applePayPayToString;
#endif

@end

@interface OLReceiptViewController (Private)
@property (nonatomic, assign) BOOL presentedModally;
@end

@interface OLPrintOrder (Private)
- (BOOL)hasCachedCost;
- (void)saveOrder;
@property (strong, nonatomic, readwrite) NSString *submitStatusErrorMessage;
@property (strong, nonatomic, readwrite) NSString *submitStatus;
@property (nonatomic, readwrite) NSString *receipt;
@property (strong, nonatomic) OLPrintOrderCost *finalCost;
@end

@interface OLProduct (Private)
- (NSDecimalNumber*) unitCostDecimalNumber;
@end

@interface OLPaymentViewController () <
#ifdef OL_KITE_OFFER_PAYPAL
PayPalPaymentDelegate,
#endif
UIActionSheetDelegate, UITextFieldDelegate, OLCreditCardCaptureDelegate, UINavigationControllerDelegate, UITableViewDelegate, UIScrollViewDelegate, UIViewControllerPreviewingDelegate>

@property (strong, nonatomic) OLPrintOrder *printOrder;
@property (strong, nonatomic) OLPayPalCard *card;

@property (strong, nonatomic) NSBlockOperation *applePayDismissOperation;
@property (strong, nonatomic) NSBlockOperation *transitionBlockOperation;

@property (strong, nonatomic) UIVisualEffectView *visualEffectView;

@property (weak, nonatomic) IBOutlet UIButton *paymentButton1;
@property (weak, nonatomic) IBOutlet UIButton *paymentButton2;
@property (weak, nonatomic) IBOutlet UILabel *totalCostLabel;
@property (weak, nonatomic) IBOutlet UILabel *promoCodeCostLabel;
@property (weak, nonatomic) IBOutlet UILabel *shippingCostLabel;
@property (weak, nonatomic) IBOutlet UITextField *promoCodeTextField;
@property (weak, nonatomic) IBOutlet UILabel *shippingTypeLabel;
@property (weak, nonatomic) IBOutlet UIButton *shippingButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *promoBoxBottomCon;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *promoBoxTopCon;
@property (weak, nonatomic) IBOutlet UIView *promoBox;
@property (weak, nonatomic) IBOutlet UILabel *poweredByKiteLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *poweredByKiteLabelBottomCon;
@property (weak, nonatomic) IBOutlet UIView *shippingDetailsBox;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *shippingDetailsCon;
@property (weak, nonatomic) IBOutlet UIButton *backToApplePayButton;
@property (weak, nonatomic) IBOutlet UIButton *payWithApplePayButton;
@property (weak, nonatomic) IBOutlet UIButton *checkoutButton;




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
    NSBundle *currentBundle = [NSBundle bundleForClass:[OLKiteViewController class]];
    if ((self = [[UIStoryboard storyboardWithName:@"OLKiteStoryboard" bundle:currentBundle] instantiateViewControllerWithIdentifier:@"OLPaymentViewController"])) {
        self.printOrder = printOrder;
    }
    
    return self;
}

- (OLCheckoutViewController *)shippingScreenOnTheStack {
    NSArray *vcStack = self.navigationController.viewControllers;
    if (vcStack.count >= 2 && [vcStack[vcStack.count - 2] isKindOfClass:[OLCheckoutViewController class]]) {
        return vcStack[vcStack.count - 2];
    }
    
    return nil;
}

- (void)sanitizeBasket{
    NSMutableArray *templateIds = [[NSMutableArray alloc] init];
    for (OLProductTemplate *template in [OLProductTemplate templates]){
        [templateIds addObject:template.identifier];
    }
    
    NSArray *jobs = [NSArray arrayWithArray:self.printOrder.jobs];
    for (id<OLPrintJob> job in jobs){
        if (![templateIds containsObject:[job templateId]]){
            [self.printOrder removePrintJob:job];
            [self.printOrder saveOrder];
        }
    }
}

-(BOOL)isApplePayAvailable{
#ifdef OL_KITE_OFFER_APPLE_PAY
    PKPaymentRequest *request = [Stripe paymentRequestWithMerchantIdentifier:[OLKitePrintSDK appleMerchantID]];
    
    return [Stripe canSubmitPaymentRequest:request];
#else
    return NO;
#endif
}

-(BOOL)shouldShowApplePay{
    return [self isApplePayAvailable] && !self.showOtherOptions;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", @"")
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:nil
                                                                            action:nil];
    
    if (self.navigationController.viewControllers.firstObject == self){
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismiss)];
    }
    
    [self sanitizeBasket];
    
    NSString *applePayAvailableStr = @"N/A";
#ifdef OL_KITE_OFFER_APPLE_PAY
    if ([self isApplePayAvailable] && [self shouldShowApplePay]){
        applePayAvailableStr = @"Yes";
    }
    else if ([self isApplePayAvailable] && ![self shouldShowApplePay]){
        applePayAvailableStr = @"Other Options";
    }
    else{
        applePayAvailableStr = @"No";
    }
#endif
    
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackPaymentScreenViewedForOrder:self.printOrder applePayIsAvailable:applePayAvailableStr];
#endif
    
    if ([OLKitePrintSDK environment] == kOLKitePrintSDKEnvironmentSandbox){
        self.title = NSLocalizedStringFromTableInBundle(@"Payment (TEST)", @"KitePrintSDK", [OLConstants bundle], @"");
    }
    else{
        self.title = NSLocalizedStringFromTableInBundle(@"Payment", @"KitePrintSDK", [OLConstants bundle], @"");
    }
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    [self.paymentButton1 makeRoundRect];
    [self.paymentButton2 makeRoundRect];
    [self.payWithApplePayButton makeRoundRect];
    [self.checkoutButton makeRoundRect];
    
    if ([UITraitCollection class] && [self.traitCollection respondsToSelector:@selector(forceTouchCapability)] && self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable){
        [self registerForPreviewingWithDelegate:self sourceView:self.tableView];
    }
    
    
#ifdef OL_KITE_OFFER_PAYPAL
    if ([OLKiteABTesting sharedInstance].offerPayPal && ![self shouldShowApplePay]){
        self.payWithApplePayButton.hidden = YES;
        self.checkoutButton.hidden = YES;
    }
#endif
    
    if ([self shouldShowApplePay]){
        self.paymentButton1.hidden = YES;
        self.paymentButton2.hidden = YES;
    }
    else{
        self.payWithApplePayButton.hidden = YES;
        self.checkoutButton.hidden = YES;
        self.shippingDetailsCon.constant = 2;
        self.shippingDetailsBox.alpha = 1;
    }
    
    [self updateViewsBasedOnCostUpdate];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardWillChangeFrameNotification object:nil];
    
    self.promoCodeTextField.delegate = self;
    
    UITapGestureRecognizer *tgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onBackgroundClicked)];
    [self.view addGestureRecognizer:tgr];
    
    if ([self.tableView respondsToSelector:@selector(setCellLayoutMarginsFollowReadableWidth:)]){
        self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    }
}

- (void)dismiss{
    [self.navigationController.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)onButtonMoreOptionsClicked:(id)sender{
    if (![self.printOrder.shippingAddress isValidAddress]){
        self.printOrder.shippingAddress = nil;
    }
    
    self.poweredByKiteLabelBottomCon.constant = -110;
    [UIView animateWithDuration:0.25 animations:^{
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished){
        self.payWithApplePayButton.hidden = YES;
        self.checkoutButton.hidden = YES;
        self.paymentButton1.hidden = NO;
        self.paymentButton2.hidden = NO;
        
        self.poweredByKiteLabelBottomCon.constant = 5;
        self.shippingDetailsCon.constant = 2;
        if (sender){
            self.backToApplePayButton.hidden = NO;
        }
        [UIView animateWithDuration:0.25 animations:^{
            [self.view layoutIfNeeded];
            self.shippingDetailsBox.alpha = 1;
        }];
    }];
}

- (IBAction)onButtonBackToApplePayClicked:(UIButton *)sender {
    [self.printOrder discardDuplicateJobs];
    [self.tableView reloadData];
    
    self.poweredByKiteLabelBottomCon.constant = -110;
    [UIView animateWithDuration:0.25 animations:^{
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished){
        self.payWithApplePayButton.hidden = NO;
        self.checkoutButton.hidden = NO;
        self.paymentButton1.hidden = YES;
        self.paymentButton2.hidden = YES;
        
        self.poweredByKiteLabelBottomCon.constant = 5;
        self.shippingDetailsCon.constant = -35;
        self.backToApplePayButton.hidden = YES;
        [UIView animateWithDuration:0.25 animations:^{
            [self.view layoutIfNeeded];
            self.shippingDetailsBox.alpha = 0;
        }];
    }];
}

- (void)onBackgroundClicked {
    [self textFieldShouldReturn:self.promoCodeTextField];
}

- (void)keyboardDidShow:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    CGSize size = [[userInfo objectForKey: UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    
    CGFloat diff = size.height - (self.view.frame.size.height - (self.promoBox.frame.origin.y + self.promoBox.frame.size.height));
    
    if (diff > 0){
        if ([self.promoCodeTextField isFirstResponder]){
            self.promoBoxBottomCon.constant = 2 + diff;
            self.promoBoxTopCon.constant = 2 - diff;
            [UIView animateWithDuration:[notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue] animations:^{
                [self.view layoutIfNeeded];
            }];
        }
    }
}

- (void)keyboardWillHide:(NSNotification *)notification {
    if ([self.promoCodeTextField isFirstResponder]){
        [self onButtonApplyPromoCodeClicked:nil];
        
        self.promoBoxBottomCon.constant = 2;
        self.promoBoxTopCon.constant = 2;
        [UIView animateWithDuration:[notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue] animations:^{
            [self.view layoutIfNeeded];
        }];
    }
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
    
    if ([self.printOrder hasCachedCost]) {
        [self.tableView reloadData];
        [self updateViewsBasedOnCostUpdate];
    } else {
        if (self.printOrder.jobs.count > 0){
            [self.printOrder costWithCompletionHandler:^(OLPrintOrderCost *cost, NSError *error) {
                [self costCalculationCompletedWithError:error];
            }];
        }
    }
}

- (void)costCalculationCompletedWithError:(NSError *)error {
    if (error) {
        if ([UIAlertController class]){
            UIAlertController *ac = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTableInBundle(@"Oops!", @"KitePrintSDK", [OLConstants bundle], @"") message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
            [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"Cancel", @"KitePrintSDK", [OLConstants bundle], @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
                [self.navigationController popViewControllerAnimated:YES];
            }]];
            [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"Retry", @"KitePrintSDK", [OLConstants bundle], @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
                [self.printOrder costWithCompletionHandler:^(OLPrintOrderCost *cost, NSError *error) {
                    [self costCalculationCompletedWithError:error];
                }];
            }]];
            [self presentViewController:ac animated:YES completion:NULL];
        }
        else{
            UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Oops!", @"KitePrintSDK", [OLConstants bundle], @"") message:error.localizedDescription delegate:self cancelButtonTitle:NSLocalizedStringFromTableInBundle(@"Cancel", @"KitePrintSDK", [OLConstants bundle], @"") otherButtonTitles:NSLocalizedStringFromTableInBundle(@"Retry", @"KitePrintSDK", [OLConstants bundle], @""), nil];
            av.delegate = self;
            [av show];
        }
    } else {
        [self.tableView reloadData];
        [self updateViewsBasedOnCostUpdate];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)updateViewsBasedOnCostUpdate {
    if (self.printOrder.jobs.count == 0){
        self.totalCostLabel.text = [[NSDecimalNumber decimalNumberWithString:@"0.00"] formatCostForCurrencyCode:[[OLCountry countryForCurrentLocale] currencyCode]];
        self.shippingCostLabel.text = [[NSDecimalNumber decimalNumberWithString:@"0.00"] formatCostForCurrencyCode:[[OLCountry countryForCurrentLocale] currencyCode]];
        self.promoCodeCostLabel.text = @"";
        return;
    }
    
    self.totalCostLabel.text = NSLocalizedString(@"Loading...", @"");
    self.shippingCostLabel.text = nil;
    self.promoCodeCostLabel.text = nil;
    
    
    [self.printOrder costWithCompletionHandler:^(OLPrintOrderCost *cost, NSError *error) {
        //Small chance that the request started before we emptied the basket.
        if (self.printOrder.jobs.count == 0){
            self.totalCostLabel.text = [[NSDecimalNumber decimalNumberWithString:@"0.00"] formatCostForCurrencyCode:[[OLCountry countryForCurrentLocale] currencyCode]];
            self.shippingCostLabel.text = [[NSDecimalNumber decimalNumberWithString:@"0.00"] formatCostForCurrencyCode:[[OLCountry countryForCurrentLocale] currencyCode]];
            self.promoCodeCostLabel.text = @"";
            return;
        }
        
        // impossible for an error to exist as we checked for cachedcost path above...
        NSAssert(error == nil, @"Print order did not actually have a cached cost...");
        NSComparisonResult result = [[cost totalCostInCurrency:self.printOrder.currencyCode] compare:[NSDecimalNumber zero]];
        if (result == NSOrderedAscending || result == NSOrderedSame) {
#ifdef OL_KITE_OFFER_PAYPAL
            self.paymentButton1.hidden = YES;
#endif
#ifdef OL_KITE_OFFER_APPLE_PAY
            self.paymentButton1.hidden = YES;
#endif
            if ([self shouldShowApplePay] && self.paymentButton2.tag != 7777){
                [self onButtonMoreOptionsClicked:nil];
            }
            [self.paymentButton2 setTitle:NSLocalizedStringFromTableInBundle(@"Checkout for Free!", @"KitePrintSDK", [OLConstants bundle], @"") forState:UIControlStateNormal];
            self.paymentButton2.tag = 7777; //Tag button to know it is showing free checkout;
        }
        else {
#ifdef OL_KITE_OFFER_PAYPAL
            self.paymentButton1.hidden = NO;
#endif
#ifdef OL_KITE_OFFER_APPLE_PAY
            self.paymentButton1.hidden = NO;
#endif
            if ([self shouldShowApplePay] && self.paymentButton2.tag == 7777){
                [self onButtonBackToApplePayClicked:nil];
            }
            [self.paymentButton2 setTitle:NSLocalizedStringFromTableInBundle(@"Credit Card", @"KitePrintSDK", [OLConstants bundle], @"") forState:UIControlStateNormal];
        }
        
        [self.tableView reloadData];
        
        self.totalCostLabel.text = [[cost totalCostInCurrency:self.printOrder.currencyCode] formatCostForCurrencyCode:self.printOrder.currencyCode];
        
        NSDecimalNumber *shippingCost = [cost shippingCostInCurrency:self.printOrder.currencyCode];
        if ([shippingCost isEqualToNumber:@0]){
            self.shippingCostLabel.text = NSLocalizedString(@"FREE", @"");
        }
        else{
            self.shippingCostLabel.text = [shippingCost formatCostForCurrencyCode:self.printOrder.currencyCode];
        }
        
        NSDecimalNumber *promoCost = [cost promoCodeDiscountInCurrency:self.printOrder.currencyCode];
        if ([promoCost isEqualToNumber:@0]){
            self.promoCodeCostLabel.text = nil;
        }
        else{
            self.promoCodeCostLabel.text = [promoCost formatCostForCurrencyCode:self.printOrder.currencyCode];
        }
        [self validateTemplatePricing];
    }];
}

/**
 *  The price on the line items on this screen are the prices from the templates. To avoid the situation where the template prices have changed and we don't know about it, do a comparison between the expected cost (based on the known template prices) and the actual prices that we got from the /cost endpoint. If we detect a discrepancy, resync the templates here.
 */
- (void)validateTemplatePricing{
    double expectedCost = 0.0;
    for (id<OLPrintJob> job in self.printOrder.jobs){
        OLProductTemplate *template = [OLProductTemplate templateWithId:[job templateId]];
        
        NSDecimalNumber *sheetCost = [template costPerSheetInCurrencyCode:[self.printOrder currencyCode]];
        NSUInteger sheetQuanity = template.quantityPerSheet == 0 ? 1 : template.quantityPerSheet;
        NSUInteger numSheets = (NSUInteger) ceil([OLProduct productWithTemplateId:[job templateId]].quantityToFulfillOrder / sheetQuanity);
        NSDecimalNumber *unitCost = [sheetCost decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%lu", (unsigned long)numSheets]]];
        
        expectedCost += unitCost.doubleValue * ([job extraCopies] + 1);
    }
    [self.printOrder costWithCompletionHandler:^(OLPrintOrderCost *cost, NSError *error){
        double actualCost = [cost totalCostInCurrency:self.printOrder.currencyCode].doubleValue;
        actualCost -= [cost shippingCostInCurrency:self.printOrder.currencyCode].doubleValue;
        actualCost -= [cost promoCodeDiscountInCurrency:self.printOrder.currencyCode].doubleValue;
        
        if (actualCost != expectedCost){
            [OLProductTemplate syncWithCompletionHandler:^(NSArray *templates, NSError *error){
                [self.tableView reloadData];
            }];
        }
    }];
}

- (void)submitOrderForPrintingWithProofOfPayment:(NSString *)proofOfPayment paymentMethod:(NSString *)paymentMethod completion:(void (^)(PKPaymentAuthorizationStatus)) handler{
    [self.printOrder cancelSubmissionOrPreemptedAssetUpload];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    self.printOrder.proofOfPayment = proofOfPayment;
    
    NSString *applePayAvailableStr = @"N/A";
#ifdef OL_KITE_OFFER_APPLE_PAY
    applePayAvailableStr = [self isApplePayAvailable] ? @"Yes" : @"No";
#endif
    
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackPaymentCompletedForOrder:self.printOrder paymentMethod:paymentMethod applePayIsAvailable:applePayAvailableStr];
#endif
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kOLNotificationUserCompletedPayment object:self userInfo:@{kOLKeyUserInfoPrintOrder: self.printOrder}];
    [self.printOrder saveToHistory];
    
    __block BOOL handlerUsed = NO;
    
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeBlack];
    [SVProgressHUD showWithStatus:NSLocalizedStringFromTableInBundle(@"Processing", @"KitePrintSDK", [OLConstants bundle], @"")];
    [self.printOrder submitForPrintingWithProgressHandler:^(NSUInteger totalAssetsUploaded, NSUInteger totalAssetsToUpload,
                                                            long long totalAssetBytesWritten, long long totalAssetBytesExpectedToWrite,
                                                            long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        if (!handlerUsed) {
            handler(PKPaymentAuthorizationStatusSuccess);
            handlerUsed = YES;
        }
        
        const float step = (1.0f / totalAssetsToUpload);
        NSUInteger totalURLAssets = self.printOrder.totalAssetsToUpload - totalAssetsToUpload;
        float progress = totalAssetsUploaded * step + (totalAssetBytesWritten / (float) totalAssetBytesExpectedToWrite) * step;
        [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeBlack];
        if (progress < 1.0){
            [SVProgressHUD showProgress:progress status:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Uploading Images \n%lu / %lu", @"KitePrintSDK", [OLConstants bundle], @""), (unsigned long) totalAssetsUploaded + 1 + totalURLAssets, (unsigned long) self.printOrder.totalAssetsToUpload]];
        }
        else{
            [SVProgressHUD showWithStatus:NSLocalizedStringFromTableInBundle(@"Processing", @"KitePrintSDK", [OLConstants bundle], @"")];
        }
    } completionHandler:^(NSString *orderIdReceipt, NSError *error) {
        [self.printOrder saveToHistory]; // save again as the print order has it's receipt set if it was successful, otherwise last error is set
        
        self.transitionBlockOperation = [[NSBlockOperation alloc] init];
        __weak OLPaymentViewController *welf = self;
        [self.transitionBlockOperation addExecutionBlock:^{
            if ([welf.delegate respondsToSelector:@selector(shouldDismissPaymentViewControllerAfterPayment)] && self.delegate.shouldDismissPaymentViewControllerAfterPayment){
                [(UITableView *)[(OLReceiptViewController *)welf.delegate tableView] reloadData];
                [welf.navigationController.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
                return ;
            }
            OLReceiptViewController *receiptVC = [[OLReceiptViewController alloc] initWithPrintOrder:welf.printOrder];
            receiptVC.delegate = welf.delegate;
            receiptVC.presentedModally = welf.presentedModally;
            receiptVC.delegate = welf.delegate;
            if (!welf.presentedViewController) {
                [welf.navigationController pushViewController:receiptVC animated:YES];
                
                [OLKiteUtils kiteVcForViewController:welf].printOrder = [[OLPrintOrder alloc] init];
                [[OLKiteUtils kiteVcForViewController:welf].printOrder saveOrder];
            }
        }];
        if ([self isApplePayAvailable] && self.applePayDismissOperation){
            [self.transitionBlockOperation addDependency:self.applePayDismissOperation];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kOLNotificationPrintOrderSubmission object:self userInfo:@{kOLKeyUserInfoPrintOrder: self.printOrder}];
        
        [SVProgressHUD dismiss];
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        
        if (error) {
            [self.printOrder cancelSubmissionOrPreemptedAssetUpload];
            if ([UIAlertController class]){
                UIAlertController *ac = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTableInBundle(@"Oops!", @"KitePrintSDK", [OLConstants bundle], @"") message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
                [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"OK", @"KitePrintSDK", [OLConstants bundle], @"") style:UIAlertActionStyleDefault handler:^(id action){
                    if (error.code != kOLKiteSDKErrorCodeOrderValidationFailed){
                        self.printOrder.receipt = nil;
                        self.printOrder.submitStatus = OLPrintOrderSubmitStatusUnknown;
                        self.printOrder.submitStatusErrorMessage = nil;
                        [[NSOperationQueue mainQueue] addOperation:self.transitionBlockOperation];
                    }
                    else{
                        [self.printOrder deleteFromHistory];
                        
                        OLPrintOrder *freshPrintOrder = [[OLPrintOrder alloc] init];
                        for (id<OLPrintJob> job in self.printOrder.jobs){
                            [freshPrintOrder addPrintJob:job];
                        }
                        freshPrintOrder.email = self.printOrder.email;
                        freshPrintOrder.phone = self.printOrder.phone;
                        freshPrintOrder.promoCode = self.printOrder.promoCode;
                        freshPrintOrder.shippingAddress = self.printOrder.shippingAddress;
                        [OLKiteUtils kiteVcForViewController:self].printOrder = freshPrintOrder;
                        self.printOrder = freshPrintOrder;
                        [self.printOrder saveOrder];
                    }
                }]];
                NSBlockOperation *presentAlertBlock = [NSBlockOperation blockOperationWithBlock:^{
                    [self presentViewController:ac animated:YES completion:NULL];
                }];
                if ([self isApplePayAvailable] && self.applePayDismissOperation){
                    [presentAlertBlock addDependency:self.applePayDismissOperation];
                }
                [[NSOperationQueue mainQueue] addOperation:presentAlertBlock];
            }
            else{
                UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Oops!", @"KitePrintSDK", [OLConstants bundle], @"") message:error.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedStringFromTableInBundle(@"OK", @"KitePrintSDK", [OLConstants bundle], @"") otherButtonTitles:nil];
                if (error.code != kOLKiteSDKErrorCodeOrderValidationFailed){
                    self.printOrder.receipt = nil;
                    self.printOrder.submitStatus = OLPrintOrderSubmitStatusUnknown;
                    self.printOrder.submitStatusErrorMessage = nil;
                    [[NSOperationQueue mainQueue] addOperation:self.transitionBlockOperation];
                }
                else{
                    self.printOrder.finalCost = nil;
                }
                [av show];
            }
            return;
        }
        
        if (!handlerUsed) {
            handler(PKPaymentAuthorizationStatusSuccess);
            handlerUsed = YES;
        }
        
#ifndef OL_NO_ANALYTICS
        [OLAnalytics trackOrderSubmission:self.printOrder];
#endif
        
        if (!self.presentedViewController){
            [[NSOperationQueue mainQueue] addOperation:self.transitionBlockOperation];
        }
    }];
}

- (void)popToHome{
    // Try as best we can to go to the beginning of the app
    NSMutableArray *navigationStack = self.navigationController.viewControllers.mutableCopy;
    if (navigationStack.count > 2) {
        [navigationStack removeObjectsInRange:NSMakeRange(1, navigationStack.count - 2)];
        self.navigationController.viewControllers = navigationStack;
        [self.navigationController popViewControllerAnimated:YES];
    }
    else if (navigationStack.firstObject == self){
        [self dismiss];
    }
}

- (void)onBarButtonOrdersClicked{
    OLOrdersViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"OLOrdersViewController"];
    
    [(UIViewController *)vc navigationItem].leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:vc action:@selector(dismiss)];
    
    NSString *supportEmail = [OLKiteABTesting sharedInstance].supportEmail;
    if (supportEmail && ![supportEmail isEqualToString:@""]){
        vc.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamedInKiteBundle:@"support"] style:UIBarButtonItemStyleDone target:vc action:@selector(emailButtonPushed:)];
    }
    
    OLCustomNavigationController *nvc = [[OLCustomNavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:nvc animated:YES completion:NULL];
}

- (BOOL)shouldShowAddMorePhotos{
    if (![self.kiteDelegate respondsToSelector:@selector(kiteControllerShouldAllowUserToAddMorePhotos:)]){
        return YES;
    }
    else{
        return [self.kiteDelegate kiteControllerShouldAllowUserToAddMorePhotos:[OLKiteUtils kiteVcForViewController:self]];
    }
}

- (UINavigationController *)navViewControllerWithControllers:(NSArray *)vcs{
    OLCustomNavigationController *navController = [[OLCustomNavigationController alloc] init];
    
    navController.viewControllers = vcs;
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", "")
                                                                   style:UIBarButtonItemStyleDone target:self
                                                                  action:@selector(dismissPresentedViewController)];
    
    
    ((UIViewController *)[vcs firstObject]).navigationItem.leftBarButtonItem = doneButton;
    
    return navController;
}

- (void)saveAndDismissReviewController{
    OLCustomNavigationController *nvc = (OLCustomNavigationController *)self.presentedViewController;
    if (![nvc isKindOfClass:[OLCustomNavigationController class]]){
        return;
    }
    
    OLOrderReviewViewController *editingVc = nvc.viewControllers.lastObject;
    if ([editingVc respondsToSelector:@selector(saveJobWithCompletionHandler:)]){
        [editingVc saveJobWithCompletionHandler:^{
            [self dismissPresentedViewController];
        }];
        
        //If the user edits the job that they just created, prevent them from going back
        NSMutableArray *navigationStack = [self.navigationController.viewControllers mutableCopy];
        if (navigationStack.count > 1){
            UIViewController *reviewVc = navigationStack[navigationStack.count-2];
            OLProduct *reviewProduct = [reviewVc safePerformSelectorWithReturn:@selector(product) withObject:nil];
            OLProduct *editingProduct = [editingVc safePerformSelectorWithReturn:@selector(product) withObject:nil];
            if ([reviewProduct.uuid isEqualToString:editingProduct.uuid]){
                [navigationStack removeObjectsInRange:NSMakeRange(1, navigationStack.count - 2)];
                self.navigationController.viewControllers = navigationStack;
            }
        }
    }
}

- (void)dismissPresentedViewController{
    [self dismissViewControllerAnimated:YES completion:^{
        [self updateViewsBasedOnCostUpdate];
    }];
}

- (void)applyPromoCode:(NSString *)promoCode {
    if (promoCode != nil) {
        [SVProgressHUD showWithStatus:NSLocalizedStringFromTableInBundle(@"Checking Code", @"KitePrintSDK", [OLConstants bundle], @"")];
    } else {
        [SVProgressHUD showWithStatus:NSLocalizedStringFromTableInBundle(@"Clearing Code", @"KitePrintSDK", [OLConstants bundle], @"")];
    }
    
    NSString *previousCode = self.printOrder.promoCode;
    self.printOrder.promoCode = promoCode;
    [self.printOrder costWithCompletionHandler:^(OLPrintOrderCost *cost, NSError *error) {
        if (error) {
            [SVProgressHUD dismiss];
            if ([UIAlertController class]){
                UIAlertController *ac = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTableInBundle(@"Oops!", @"KitePrintSDK", [OLConstants bundle], @"") message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
                [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"OK", @"KitePrintSDK", [OLConstants bundle], @"") style:UIAlertActionStyleDefault handler:NULL]];
                [self presentViewController:ac animated:YES completion:NULL];
            }
            else{
                UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Oops!", @"KitePrintSDK", [OLConstants bundle], @"") message:error.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedStringFromTableInBundle(@"OK", @"KitePrintSDK", [OLConstants bundle], @"") otherButtonTitles:nil];
                [av show];
            }
        } else {
            if (cost.promoCodeInvalidReason) {
                self.printOrder.promoCode = previousCode; // reset print order promo code as it was invalid
                [SVProgressHUD dismiss];
                if ([UIAlertController class]){
                    UIAlertController *ac = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTableInBundle(@"Oops!", @"KitePrintSDK", [OLConstants bundle], @"") message:cost.promoCodeInvalidReason preferredStyle:UIAlertControllerStyleAlert];
                    [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"OK", @"KitePrintSDK", [OLConstants bundle], @"") style:UIAlertActionStyleDefault handler:NULL]];
                    [self presentViewController:ac animated:YES completion:NULL];
                }
                else{
                    UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Oops!", @"KitePrintSDK", [OLConstants bundle], @"") message:cost.promoCodeInvalidReason delegate:nil cancelButtonTitle:NSLocalizedStringFromTableInBundle(@"OK", @"KitePrintSDK", [OLConstants bundle], @"") otherButtonTitles:nil];
                    [av show];
                }
            } else {
                if (self.printOrder.promoCode) {
                    [SVProgressHUD showSuccessWithStatus:nil];
                } else {
                    [SVProgressHUD dismiss];
                }
            }
            
            [self updateViewsBasedOnCostUpdate];
        }
    }];
}

#pragma mark Button Actions

- (IBAction)onButtonApplyPromoCodeClicked:(id)sender {
    if ([self.promoCodeTextField.text isEqualToString:@""]) {
        // Clear promo code
        [self applyPromoCode:nil];
    } else {
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
        // Ugly bit of code for S9, it's such a small bit of work it doesn't warrant forking the repo & associated overhead just to add client side promo rejection
        if ([self.delegate respondsToSelector:@selector(shouldAcceptPromoCode:)]) {
            NSString *rejectMessage = [self.delegate performSelector:@selector(shouldAcceptPromoCode:) withObject:self.promoCodeTextField.text];
            if (rejectMessage) {
                [[[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Oops", @"KitePrintSDK", [OLConstants bundle], @"") message:rejectMessage delegate:nil cancelButtonTitle:NSLocalizedStringFromTableInBundle(@"OK", @"KitePrintSDK", [OLConstants bundle], @"") otherButtonTitles:nil] show];
                
                self.printOrder.promoCode = nil;
                [self updateViewsBasedOnCostUpdate];
                return;
            }
        }
#pragma clang diagnostic pop
        
        NSString *promoCode = [self.promoCodeTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        [self applyPromoCode:promoCode];
    }
}

- (IBAction)onButtonPayWithCreditCardClicked {
    if (self.printOrder.jobs.count == 0){
        return;
    }
    
    if ((!self.printOrder.shippingAddress && self.printOrder.shippingAddressesOfJobs.count == 0) || !self.printOrder.email){
        [UIView animateWithDuration:0.1 animations:^{
            self.shippingDetailsBox.backgroundColor = [UIColor colorWithWhite:0.929 alpha:1.000];
            self.shippingDetailsBox.transform = CGAffineTransformMakeTranslation(-10, 0);
        } completion:^(BOOL finished){
            [UIView animateWithDuration:0.25 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0 options:0 animations:^{
                self.shippingDetailsBox.backgroundColor = [UIColor whiteColor];
                self.shippingDetailsBox.transform = CGAffineTransformIdentity;
            }completion:NULL];
        }];
        return;
    }
    
    [self.printOrder costWithCompletionHandler:^(OLPrintOrderCost *cost, NSError *error) {
        NSComparisonResult result = [[cost totalCostInCurrency:self.printOrder.currencyCode] compare:[NSDecimalNumber zero]];
        if (result == NSOrderedAscending || result == NSOrderedSame) {
            // The user must have a promo code which reduces this order cost to nothing, lucky user :)
            [self submitOrderForPrintingWithProofOfPayment:nil paymentMethod:@"Free Checkout" completion:^void(PKPaymentAuthorizationStatus status){}];
        } else {
            
            id card = [OLPayPalCard lastUsedCard];
            
            if ([OLKitePrintSDK useStripeForCreditCards]){
                card = [OLStripeCard lastUsedCard];
            }
            else if ([OLKitePrintSDK useJudoPayForGBP] && [self.printOrder.currencyCode isEqualToString:@"GBP"]) {
                card = [OLJudoPayCard lastUsedCard];
            }
            
            
            if (card == nil) {
                [self payWithNewCard];
            } else {
                if ([UIAlertController class]){
                    UIAlertController *ac = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
                    [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"Cancel", @"KitePrintSDK", [OLConstants bundle], @"")  style:UIAlertActionStyleCancel handler:NULL]];
                    [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"Pay with new card", @"KitePrintSDK", [OLConstants bundle], @"")  style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
                        [self payWithNewCard];
                    }]];
                    [ac addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Pay with card ending %@", @"KitePrintSDK", [OLConstants bundle], @""), [[card numberMasked] substringFromIndex:[[card numberMasked] length] - 4]]  style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
                        
                        if ([OLKitePrintSDK useStripeForCreditCards]){
                            [self payWithExistingStripeCard:[OLStripeCard lastUsedCard]];
                        } else if ([OLKitePrintSDK useJudoPayForGBP] && [self.printOrder.currencyCode isEqualToString:@"GBP"]) {
                            [self payWithExistingJudoPayCard:[OLJudoPayCard lastUsedCard]];
                        } else {
                            [self payWithExistingPayPalCard:[OLPayPalCard lastUsedCard]];
                        }
                    }]];
                    ac.popoverPresentationController.sourceView = self.paymentButton2;
                    ac.popoverPresentationController.sourceRect = self.paymentButton2.frame;
                    [self presentViewController:ac animated:YES completion:NULL];
                }
                else{
                    UIActionSheet *paysheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedStringFromTableInBundle(@"Cancel", @"KitePrintSDK", [OLConstants bundle], @"") destructiveButtonTitle:nil otherButtonTitles:NSLocalizedStringFromTableInBundle(@"Pay with new card", @"KitePrintSDK", [OLConstants bundle], @""), [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Pay with card ending %@", @"KitePrintSDK", [OLConstants bundle], @""), [[card numberMasked] substringFromIndex:[[card numberMasked] length] - 4]], nil];
                    [paysheet showInView:self.view];
                }
            }
        }
    }];
}


- (void)payWithNewCard {
    OLCreditCardCaptureViewController *ccCaptureController = [[OLCreditCardCaptureViewController alloc] initWithPrintOrder:self.printOrder];
    ccCaptureController.delegate = self;
    [self presentViewController:ccCaptureController animated:YES completion:nil];
}

- (void)payWithExistingPayPalCard:(OLPayPalCard *)card {
    if ([OLKitePrintSDK useJudoPayForGBP]) {
        NSAssert(![self.printOrder.currencyCode isEqualToString:@"GBP"], @"JudoPay should be used for GBP orders (and only for Kite internal use)");
    }
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeBlack];
    [SVProgressHUD showWithStatus:NSLocalizedStringFromTableInBundle(@"Processing", @"KitePrintSDK", [OLConstants bundle], @"")];
    [self.printOrder costWithCompletionHandler:^(OLPrintOrderCost *cost, NSError *error) {
        [card chargeCard:[cost totalCostInCurrency:self.printOrder.currencyCode] currencyCode:self.printOrder.currencyCode description:self.printOrder.paymentDescription completionHandler:^(NSString *proofOfPayment, NSError *error) {
            if (error) {
                [SVProgressHUD dismiss];
                if ([UIAlertController class]){
                    UIAlertController *ac = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTableInBundle(@"Oops!", @"KitePrintSDK", [OLConstants bundle], @"") message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
                    [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"OK", @"KitePrintSDK", [OLConstants bundle], @"") style:UIAlertActionStyleDefault handler:NULL]];
                    [self presentViewController:ac animated:YES completion:NULL];
                }
                else{
                    UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Oops!", @"KitePrintSDK", [OLConstants bundle], @"") message:error.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedStringFromTableInBundle(@"OK", @"KitePrintSDK", [OLConstants bundle], @"") otherButtonTitles:nil];
                    [av show];
                }
                return;
            }
            
            [self submitOrderForPrintingWithProofOfPayment:proofOfPayment paymentMethod:@"Credit Card" completion:^void(PKPaymentAuthorizationStatus status){}];
            [card saveAsLastUsedCard];
        }];
    }];
}

- (void)payWithExistingStripeCard:(OLStripeCard *)card {
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeBlack];
    [SVProgressHUD showWithStatus:NSLocalizedStringFromTableInBundle(@"Processing", @"KitePrintSDK", [OLConstants bundle], @"")];
    [self.printOrder costWithCompletionHandler:^(OLPrintOrderCost *cost, NSError *error) {
        [card chargeCard:[cost totalCostInCurrency:self.printOrder.currencyCode] currencyCode:self.printOrder.currencyCode description:self.printOrder.paymentDescription completionHandler:^(NSString *proofOfPayment, NSError *error) {
            if (error) {
                [SVProgressHUD dismiss];
                if ([UIAlertController class]){
                    UIAlertController *ac = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTableInBundle(@"Oops!", @"KitePrintSDK", [OLConstants bundle], @"") message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
                    [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"OK", @"KitePrintSDK", [OLConstants bundle], @"") style:UIAlertActionStyleDefault handler:NULL]];
                    [self presentViewController:ac animated:YES completion:NULL];
                }
                else{
                    UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Oops!", @"KitePrintSDK", [OLConstants bundle], @"") message:error.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedStringFromTableInBundle(@"OK", @"KitePrintSDK", [OLConstants bundle], @"") otherButtonTitles:nil];
                    [av show];
                }
                return;
            }
            
            [self submitOrderForPrintingWithProofOfPayment:proofOfPayment paymentMethod:@"Credit Card" completion:^void(PKPaymentAuthorizationStatus status){}];
            [card saveAsLastUsedCard];
        }];
    }];
}

- (void)payWithExistingJudoPayCard:(OLJudoPayCard *)card {
    NSAssert([self.printOrder.currencyCode isEqualToString:@"GBP"], @"JudoPay should only be used for GBP orders (and only for Kite internal use)");
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeBlack];
    [SVProgressHUD showWithStatus:NSLocalizedStringFromTableInBundle(@"Processing", @"KitePrintSDK", [OLConstants bundle], @"")];
    [self.printOrder costWithCompletionHandler:^(OLPrintOrderCost *cost, NSError *error) {
        [card chargeCard:[cost totalCostInCurrency:@"GBP"] currency:kOLJudoPayCurrencyGBP description:self.printOrder.paymentDescription completionHandler:^(NSString *proofOfPayment, NSError *error) {
            if (error) {
                [SVProgressHUD dismiss];
                if ([UIAlertController class]){
                    UIAlertController *ac = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTableInBundle(@"Oops!", @"KitePrintSDK", [OLConstants bundle], @"") message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
                    [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"OK", @"KitePrintSDK", [OLConstants bundle], @"") style:UIAlertActionStyleDefault handler:NULL]];
                    [self presentViewController:ac animated:YES completion:NULL];
                }
                else{
                    UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Oops!", @"KitePrintSDK", [OLConstants bundle], @"") message:error.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedStringFromTableInBundle(@"OK", @"KitePrintSDK", [OLConstants bundle], @"") otherButtonTitles:nil];
                    [av show];
                }
                return;
            }
            
            [self submitOrderForPrintingWithProofOfPayment:proofOfPayment paymentMethod:@"Credit Card" completion:^void(PKPaymentAuthorizationStatus status){}];
            [card saveAsLastUsedCard];
        }];
    }];
}



#ifdef OL_KITE_OFFER_PAYPAL
- (IBAction)onButtonPayWithPayPalClicked {
    if (self.printOrder.jobs.count == 0){
        return;
    }
    if ((!self.printOrder.shippingAddress && self.printOrder.shippingAddressesOfJobs.count == 0) || !self.printOrder.email){
        [UIView animateWithDuration:0.1 animations:^{
            self.shippingDetailsBox.backgroundColor = [UIColor colorWithWhite:0.929 alpha:1.000];
            self.shippingDetailsBox.transform = CGAffineTransformMakeTranslation(-10, 0);
        } completion:^(BOOL finished){
            [UIView animateWithDuration:0.25 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0 options:0 animations:^{
                self.shippingDetailsBox.backgroundColor = [UIColor whiteColor];
                self.shippingDetailsBox.transform = CGAffineTransformIdentity;
            }completion:NULL];
        }];
        return;
    }
    
    [self.printOrder costWithCompletionHandler:^(OLPrintOrderCost *cost, NSError *error) {
        // Create a PayPalPayment
        PayPalPayment *payment = [[PayPalPayment alloc] init];
        payment.amount = [cost totalCostInCurrency:self.printOrder.currencyCode];
        payment.currencyCode = self.printOrder.currencyCode;
        payment.shortDescription = self.printOrder.paymentDescription;
        payment.intent = PayPalPaymentIntentAuthorize;
        NSAssert(payment.processable, @"oops");
        
        PayPalPaymentViewController *paymentViewController;
        PayPalConfiguration *payPalConfiguration = [[PayPalConfiguration alloc] init];
        payPalConfiguration.acceptCreditCards = NO;
        paymentViewController = [[PayPalPaymentViewController alloc] initWithPayment:payment configuration:payPalConfiguration delegate:self];
        [self presentViewController:paymentViewController animated:YES completion:nil];
    }];
}
#endif

#ifdef OL_KITE_OFFER_APPLE_PAY
- (IBAction)onButtonPayWithApplePayClicked{
    if (self.printOrder.jobs.count == 0){
        return;
    }
    
    self.applePayDismissOperation = [[NSBlockOperation alloc] init];
    
    PKPaymentRequest *paymentRequest = [Stripe paymentRequestWithMerchantIdentifier:[OLKitePrintSDK appleMerchantID]];
    paymentRequest.currencyCode = self.printOrder.currencyCode;
    [self.printOrder costWithCompletionHandler:^(OLPrintOrderCost *cost, NSError *error){
        NSMutableArray *lineItems = [[NSMutableArray alloc] init];
        for (OLPaymentLineItem *item in cost.lineItems){
            [lineItems addObject:[PKPaymentSummaryItem summaryItemWithLabel:item.description  amount:[item costInCurrency:self.printOrder.currencyCode]]];
        }
        [lineItems addObject:[PKPaymentSummaryItem summaryItemWithLabel:[OLKitePrintSDK applePayPayToString] amount:[cost totalCostInCurrency:self.printOrder.currencyCode]]];
        paymentRequest.paymentSummaryItems = lineItems;
        NSUInteger requiredFields = PKAddressFieldPostalAddress | PKAddressFieldName | PKAddressFieldEmail;
        if ([OLKiteABTesting sharedInstance].requirePhoneNumber){
            requiredFields = requiredFields | PKAddressFieldPhone;
        }
        paymentRequest.requiredShippingAddressFields = requiredFields;
        UIViewController *paymentController;
        paymentController = [[PKPaymentAuthorizationViewController alloc]
                             initWithPaymentRequest:paymentRequest];
        ((PKPaymentAuthorizationViewController *)paymentController).delegate = self;
        [self presentViewController:paymentController animated:YES completion:nil];
    }];
}
#endif

- (IBAction)onButtonMinusClicked:(UIButton *)sender {
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
    OLProductPrintJob* printJob = ((OLProductPrintJob*)[self.printOrder.jobs objectAtIndex:indexPath.row]);
    
    if (printJob.extraCopies == 0){
        if ([UIAlertController class]){
            UIAlertController *ac = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Delete Item", @"") message:NSLocalizedString(@"Are you sure you want to delete this item?", @"") preferredStyle:UIAlertControllerStyleAlert];
            [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:NULL]];
            [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Yes", @"") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action){
                [self.printOrder removePrintJob:printJob];
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
                [self.printOrder saveOrder];
                [self updateViewsBasedOnCostUpdate];
            }]];
            [self presentViewController:ac animated:YES completion:NULL];
        }
        //on iOS 7, just delete without prompt
    }
    else{
        printJob.extraCopies--;
        
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        [self updateViewsBasedOnCostUpdate];
        [self.printOrder saveOrder];
    }
}

- (IBAction)onButtonPlusClicked:(UIButton *)sender {
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
    OLProductPrintJob* printJob = ((OLProductPrintJob*)[self.printOrder.jobs objectAtIndex:indexPath.row]);
    
    printJob.extraCopies += 1;
    
    if (indexPath){
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    }
    
    [self updateViewsBasedOnCostUpdate];
    [self.printOrder saveOrder];
}

- (IBAction)onButtonEditClicked:(UIButton *)sender {
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
    
    [self presentViewController:[self viewControllerForItemAtIndexPath:indexPath] animated:YES completion:NULL];;
}

- (IBAction)onButtonContinueShoppingClicked:(UIButton *)sender {
    [OLAnalytics trackContinueShoppingButtonPressed:[NSNumber numberWithInteger:self.printOrder.jobs.count]];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(userDidTapContinueShoppingButton)]){
        [self.delegate userDidTapContinueShoppingButton];
    }
    else{
        [self popToHome];
    }
}

- (IBAction)onShippingDetailsGestureRecognized:(id)sender {
    [OLKiteUtils shippingControllerForPrintOrder:self.printOrder handler:^(id vc){
        OLCustomNavigationController *nvc = [[OLCustomNavigationController alloc] initWithRootViewController:vc];
        [[(UINavigationController *)vc view] class]; //force viewDidLoad;
        [(OLCheckoutViewController *)vc navigationItem].rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:vc action:@selector(onButtonDoneClicked)];
        [vc safePerformSelector:@selector(setUserEmail:) withObject:self.userEmail];
        [vc safePerformSelector:@selector(setUserPhone:) withObject:self.userPhone];
        
        [self presentViewController:nvc animated:YES completion:NULL];
    }];
}

#pragma mark - PayPalPaymentDelegate methods

#ifdef OL_KITE_OFFER_PAYPAL
- (void)payPalPaymentDidCancel:(PayPalPaymentViewController *)paymentViewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)payPalPaymentViewController:(PayPalPaymentViewController *)paymentViewController didCompletePayment:(PayPalPayment *)completedPayment {
    [self dismissViewControllerAnimated:YES completion:nil];
    NSString *token = completedPayment.confirmation[@"response"][@"id"];
    token = [token stringByReplacingCharactersInRange:NSMakeRange(0, 3) withString:@"PAUTH"];
    [self submitOrderForPrintingWithProofOfPayment:token paymentMethod:@"PayPal" completion:^void(PKPaymentAuthorizationStatus status){}];
}
#endif

#pragma mark - Apple Pay Delegate Methods

#ifdef OL_KITE_OFFER_APPLE_PAY
- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller
                       didAuthorizePayment:(PKPayment *)payment
                                completion:(void (^)(PKPaymentAuthorizationStatus))completion {
    [self handlePaymentAuthorizationWithPayment:payment completion:completion];
}

- (void)paymentAuthorizationViewControllerDidFinish:(PKPaymentAuthorizationViewController *)controller {
    [self dismissViewControllerAnimated:YES completion:^{
        [self.printOrder costWithCompletionHandler:^(id cost, NSError *error){
            if (!self.applePayDismissOperation.finished){
                [[NSOperationQueue mainQueue] addOperation:self.applePayDismissOperation];
            }
            if (error){
                //Apple Pay only available on ios 8+ so no need to worry about UIAlertController not available.
                UIAlertController *ac = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Oops!", @"") message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
                [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
                    [self.navigationController popViewControllerAnimated:YES];
                }]];
                [self presentViewController:ac animated:YES completion:NULL];
            }
        }];
    }];
}

- (void)handlePaymentAuthorizationWithPayment:(PKPayment *)payment
                                   completion:(void (^)(PKPaymentAuthorizationStatus))completion {
    ABRecordRef address = payment.shippingAddress;
    OLAddress *shippingAddress = [[OLAddress alloc] init];
    shippingAddress.recipientFirstName = (__bridge_transfer NSString *)ABRecordCopyValue(address, kABPersonFirstNameProperty);
    shippingAddress.recipientLastName = (__bridge_transfer NSString *)ABRecordCopyValue(address, kABPersonLastNameProperty);
    
    CFTypeRef values = ABRecordCopyValue(address, kABPersonAddressProperty);
    for (NSInteger i = 0; i < ABMultiValueGetCount(values); i++){
        NSDictionary *dict = (__bridge_transfer NSDictionary *)ABMultiValueCopyValueAtIndex(values, i);
        shippingAddress.line1 = [dict objectForKey:(id)kABPersonAddressStreetKey];
        shippingAddress.city = [dict objectForKey:(id)kABPersonAddressCityKey];
        shippingAddress.stateOrCounty = [dict objectForKey:(id)kABPersonAddressStateKey];
        shippingAddress.zipOrPostcode = [dict objectForKey:(id)kABPersonAddressZIPKey];
        shippingAddress.country = [OLCountry countryForCode:[dict objectForKey:(id)kABPersonAddressCountryCodeKey]];
        if (!shippingAddress.country){
            shippingAddress.country = [OLCountry countryForCode:[dict objectForKey:(id)kABPersonAddressCountryKey]];
        }
        if (!shippingAddress.country){
            shippingAddress.country = [OLCountry countryForName:[dict objectForKey:(id)kABPersonAddressCountryKey]];
        }
        if (!shippingAddress.country){
            completion(PKPaymentAuthorizationStatusFailure);
        }
    }
    
    if (![shippingAddress isValidAddress]){
        completion(PKPaymentAuthorizationStatusInvalidShippingPostalAddress);
        return;
    }
    
    self.printOrder.shippingAddress = shippingAddress;
    NSString *email;
    NSString *phone;
    NSMutableDictionary *d = [[NSMutableDictionary alloc] init];
    if (self.printOrder.userData) {
        d = [self.printOrder.userData mutableCopy];
    }
    CFTypeRef emails = ABRecordCopyValue(address, kABPersonEmailProperty);
    for (NSInteger i = 0; i < ABMultiValueGetCount(emails); i++){
        email = (__bridge_transfer NSString *)(ABMultiValueCopyValueAtIndex(emails, i));
    }
    CFTypeRef phones = ABRecordCopyValue(address, kABPersonPhoneProperty);
    for (NSInteger i = 0; i < ABMultiValueGetCount(phones); i++){
        phone = (__bridge_transfer NSString *)(ABMultiValueCopyValueAtIndex(phones, i));
    }
    d[@"email"] = email ? email : @"";
    d[@"phone"] = phone ? phone : @"";
    
    self.printOrder.email = email;
    self.printOrder.phone = phone;
    
    self.printOrder.userData = d;
    
    if (![OLCheckoutViewController validateEmail:d[@"email"]] && [OLKitePrintSDK environment] == kOLKitePrintSDKEnvironmentLive){
        completion(PKPaymentAuthorizationStatusInvalidShippingContact);
        return;
    }
    
    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:[OLKitePrintSDK stripePublishableKey]];
    
    [client createTokenWithPayment:payment completion:^(STPToken *token, NSError *error) {
        if (error) {
            completion(PKPaymentAuthorizationStatusFailure);
            return;
        }
        [self submitOrderForPrintingWithProofOfPayment:token.tokenId paymentMethod:@"Apple Pay" completion:completion];
    }];
}

- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller didSelectShippingAddress:(ABRecordRef)address completion:(void (^)(PKPaymentAuthorizationStatus, NSArray<PKShippingMethod *> *, NSArray <PKPaymentSummaryItem *>*))completion{
    OLAddress *shippingAddress = [[OLAddress alloc] init];
    
    CFTypeRef values = ABRecordCopyValue(address, kABPersonAddressProperty);
    for (NSInteger i = 0; i < ABMultiValueGetCount(values); i++){
        NSDictionary *dict = (__bridge NSDictionary *)ABMultiValueCopyValueAtIndex(values, i);
        shippingAddress.country = [OLCountry countryForCode:[dict objectForKey:(id)kABPersonAddressCountryCodeKey]];
        if (!shippingAddress.country){
            shippingAddress.country = [OLCountry countryForCode:[dict objectForKey:(id)kABPersonAddressCountryKey]];
        }
        if (!shippingAddress.country){
            shippingAddress.country = [OLCountry countryForName:[dict objectForKey:(id)kABPersonAddressCountryKey]];
        }
        if (!shippingAddress.country){
            completion(PKPaymentAuthorizationStatusFailure, nil, nil);
        }
    }
    
    self.printOrder.shippingAddress = shippingAddress;
    for (id<OLPrintJob> printJob in self.printOrder.jobs){
        if ([printJob respondsToSelector:@selector(setAddress:)]){
            [printJob setAddress:nil];
        }
    }
    [self.printOrder costWithCompletionHandler:^(OLPrintOrderCost *cost, NSError *error){
        [self.tableView reloadData];
        NSMutableArray *lineItems = [[NSMutableArray alloc] init];
        for (OLPaymentLineItem *item in cost.lineItems){
            [lineItems addObject:[PKPaymentSummaryItem summaryItemWithLabel:item.description  amount:[item costInCurrency:self.printOrder.currencyCode]]];
        }
        [lineItems addObject:[PKPaymentSummaryItem summaryItemWithLabel:[OLKitePrintSDK applePayPayToString] amount:[cost totalCostInCurrency:self.printOrder.currencyCode]]];
        if (!error){
            completion(PKPaymentAuthorizationStatusSuccess, nil, lineItems);
        }
        else{
            self.printOrder.shippingAddress = nil;
            completion(PKPaymentAuthorizationStatusFailure, nil, nil);
        }
    }];
}

#endif

#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    id<OLKiteDelegate> kiteDelegate = [OLKiteUtils kiteDelegate:self];
    if (([kiteDelegate respondsToSelector:@selector(shouldShowContinueShoppingButton)] && ![kiteDelegate shouldShowContinueShoppingButton]) || [OLKiteABTesting sharedInstance].launchedWithPrintOrder){
        return 1;
    }
    else{
        return 2;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0 && self.printOrder.jobs.count > 0){
        return self.printOrder.jobs.count;
    }
    else if (section == 0 && self.printOrder.jobs.count == 0){
        return 1;
    }
    else{
        return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && self.printOrder.jobs.count > 0){
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"jobCell"];
        UIImageView *imageView = (UIImageView *)[cell.contentView viewWithTag:20];
        UILabel *quantityLabel = (UILabel *)[cell.contentView viewWithTag:30];
        UILabel *productNameLabel = (UILabel *)[cell.contentView viewWithTag:50];
        UIButton *editButton = (UIButton *)[cell.contentView viewWithTag:60];
        UIButton *largeEditButton = (UIButton *)[cell.contentView viewWithTag:61];
        UILabel *priceLabel = (UILabel *)[cell.contentView viewWithTag:70];
        
        id<OLPrintJob> job = self.printOrder.jobs[indexPath.row];
        OLProduct *product = [OLProduct productWithTemplateId:[job templateId]];
        
        [SDWebImageManager.sharedManager downloadImageWithURL:product.productTemplate.coverPhotoURL options:0 progress:NULL completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
            imageView.image = image;
        }];
        
        quantityLabel.text = [NSString stringWithFormat:@"%ld", (long)[job extraCopies]+1];
        productNameLabel.text = product.productTemplate.name;
        
        if ([self.printOrder hasCachedCost]){
            priceLabel.text = [[[product unitCostDecimalNumber] decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%ld", (long)[job extraCopies]+1]]]formatCostForCurrencyCode:self.printOrder.currencyCode];
        }
        else{
            priceLabel.text = nil;
        }
        
        if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8){
            editButton.hidden = YES;
            largeEditButton.hidden = YES;
        }
        cell.backgroundColor = [UIColor clearColor];
        
        return cell;
    }
    else if (indexPath.section == 0 && self.printOrder.jobs.count == 0){
        UITableViewCell *cell =  [tableView dequeueReusableCellWithIdentifier:@"emptyCell"];
        cell.backgroundColor = [UIColor clearColor];
        return cell;
    }
    else{
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"continueCell"];
        cell.backgroundColor = [UIColor clearColor];
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 0){
        return 60;
    }
    else{
        return 40;
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    self.printOrder.promoCode = textField.text;
    [self updateViewsBasedOnCostUpdate];
    return NO;
}

- (BOOL) tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    return indexPath.section == 0;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.printOrder removePrintJob:self.printOrder.jobs[indexPath.row]];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.printOrder saveOrder];
        [self updateViewsBasedOnCostUpdate];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    [self textFieldShouldReturn:self.promoCodeTextField];
}

- (UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location{
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    [previewingContext setSourceRect:cell.frame];
    return [self viewControllerForItemAtIndexPath:indexPath];
}

- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit{
    [self presentViewController:viewControllerToCommit animated:YES completion:NULL];
}

- (UIViewController *)viewControllerForItemAtIndexPath:(NSIndexPath *)indexPath{
    OLProductPrintJob* printJob = ((OLProductPrintJob*)[self.printOrder.jobs objectAtIndex:indexPath.row]);
    OLProduct *product = [OLProduct productWithTemplateId:printJob.templateId];
    product.uuid = printJob.uuid;
    
    for (NSString *option in printJob.options.allKeys){
        product.selectedOptions[option] = printJob.options[option];
    }
    
    OLProductOverviewViewController *overviewVc = [self.storyboard instantiateViewControllerWithIdentifier:@"OLProductOverviewViewController"];
    overviewVc.product = product;
    
    UIViewController* orvc = [self.storyboard instantiateViewControllerWithIdentifier:[OLKiteUtils reviewViewControllerIdentifierForProduct:product photoSelectionScreen:NO]];
    [orvc safePerformSelector:@selector(setProduct:) withObject:product];
    
    NSMutableArray *userSelectedPhotos = [[NSMutableArray alloc] init];
    for (OLAsset *asset in [printJob assetsForUploading]){
        OLPrintPhoto *printPhoto = [[OLPrintPhoto alloc] init];
        printPhoto.asset = asset;
        
        if ([asset.dataSource isKindOfClass:[OLPrintPhoto class]]){
            printPhoto = (OLPrintPhoto *)asset.dataSource;
        }
        
        [userSelectedPhotos addObject:printPhoto];
    }
    
    if (product.productTemplate.templateUI == kOLTemplateUIFrame || product.productTemplate.templateUI == kOLTemplateUIPoster){
        [OLKiteUtils reverseRowsOfPhotosInArray:userSelectedPhotos forProduct:product];
    }
    
    [orvc safePerformSelector:@selector(setUserSelectedPhotos:) withObject:userSelectedPhotos];
    [overviewVc safePerformSelector:@selector(setUserSelectedPhotos:) withObject:userSelectedPhotos];
    
    [orvc safePerformSelector:@selector(setEditingPrintJob:) withObject:printJob];
    
    if ([self shouldShowAddMorePhotos] && product.productTemplate.templateUI != kOLTemplateUICase && product.productTemplate.templateUI != kOLTemplateUIPhotobook && product.productTemplate.templateUI != kOLTemplateUIPostcard){
        OLPhotoSelectionViewController *photoVc = [self.storyboard instantiateViewControllerWithIdentifier:@"PhotoSelectionViewController"];
        photoVc.product = product;
        photoVc.userSelectedPhotos = userSelectedPhotos;
        return [self navViewControllerWithControllers:@[overviewVc, photoVc, orvc]];
    }
    else if (product.productTemplate.templateUI == kOLTemplateUIPhotobook){
        OLPhotobookViewController *photobookVc = [self.storyboard instantiateViewControllerWithIdentifier:@"PhotobookViewController"];
        photobookVc.product = product;
        photobookVc.photobookPhotos = [orvc safePerformSelectorWithReturn:@selector(photobookPhotos) withObject:nil];
        photobookVc.userSelectedPhotos = userSelectedPhotos;
        
        if ([printJob isKindOfClass:[OLPhotobookPrintJob class]] && [(OLPhotobookPrintJob *)printJob frontCover]){
            OLPrintPhoto *coverPhoto = [[OLPrintPhoto alloc] init];
            coverPhoto.asset = [(OLPhotobookPrintJob *)printJob frontCover];
            
            photobookVc.coverPhoto = coverPhoto;
            [orvc safePerformSelector:@selector(setCoverPhoto:) withObject:coverPhoto];
        }
        
        return [self navViewControllerWithControllers:@[overviewVc, orvc, photobookVc]];
    }
    else{
        return [self navViewControllerWithControllers:@[overviewVc, orvc]];
    }
}

#pragma mark - UIActionSheetDelegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        // pay with new card
        [self payWithNewCard];
    } else if (buttonIndex == 1) {
        // pay with existing card
        if ([OLKitePrintSDK useStripeForCreditCards]){
            [self payWithExistingStripeCard:[OLStripeCard lastUsedCard]];
        } else if ([OLKitePrintSDK useJudoPayForGBP] && [self.printOrder.currencyCode isEqualToString:@"GBP"]) {
            [self payWithExistingJudoPayCard:[OLJudoPayCard lastUsedCard]];
        } else {
            [self payWithExistingPayPalCard:[OLPayPalCard lastUsedCard]];
        }
    }
}

#pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        // Clicked cancel
        [self.navigationController popViewControllerAnimated:YES];
    } else if (buttonIndex == 1) {
        // Clicked retry, attempt syncing again
        [self.printOrder costWithCompletionHandler:^(OLPrintOrderCost *cost, NSError *error) {
            [self costCalculationCompletedWithError:error];
        }];
    }
}

#pragma mark - OLCreditCardCaptureDelegate methods

- (void)creditCardCaptureController:(OLCreditCardCaptureViewController *)vc didFinishWithProofOfPayment:(NSString *)proofOfPayment {
    [self dismissViewControllerAnimated:YES completion:^{
        [self submitOrderForPrintingWithProofOfPayment:proofOfPayment paymentMethod:@"Credit Card" completion:^void(PKPaymentAuthorizationStatus status){}];
    }];
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

@end
