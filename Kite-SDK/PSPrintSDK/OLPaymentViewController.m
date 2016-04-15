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
#import <SVProgressHUD/SVProgressHUD.h>
#else
#import "SDWebImageManager.h"
#import "SVProgressHUD.h"
#endif

#import "OLPaymentViewController.h"
#import "OLReceiptViewController.h"
#import "OLPrintOrder.h"
#import "OLPrintJob.h"
#import "OLPrintOrder+History.h"
#import "OLPostcardPrintJob.h"
#import "OLCheckoutViewController.h"
#import "Util.h"
#import "OLPayPalCard.h"
#import "OLKitePrintSDK.h"
#import "OLProductTemplate.h"
#import "OLCountry.h"
#ifdef OL_OFFER_JUDOPAY
#import "OLJudoPayCard.h"
#endif
#import "NSObject+Utils.h"
#import "OLConstants.h"
#import "OLCreditCardCaptureViewController.h"
#import "OLAnalytics.h"
#import "OLPaymentLineItem.h"
#import "UIView+RoundRect.h"
#import "OLBaseRequest.h"
#import "OLPrintOrderCost.h"
#import "OLKiteABTesting.h"
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
#import "OLPosterViewController.h"
#import "OLFrameOrderReviewViewController.h"
#import "OLAsset+Private.h"
#import "UIViewController+OLMethods.h"
#import "OLAddress+AddressBook.h"
#import "NSObject+Utils.h"

#ifdef OL_KITE_OFFER_PAYPAL
#ifdef COCOAPODS
#import <PayPal-iOS-SDK/PayPalMobile.h>
#else
#import "PayPalMobile.h"
#endif

#endif

#ifdef OL_KITE_OFFER_APPLE_PAY
#ifdef COCOAPODS
#import <Stripe/Stripe+ApplePay.h>
#else
#import "Stripe+ApplePay.h"
#endif

#endif

@import PassKit;
@import AddressBook;

static NSString *const kSectionOrderSummary = @"kSectionOrderSummary";
static NSString *const kSectionPromoCodes = @"kSectionPromoCodes";
static NSString *const kSectionPayment = @"kSectionPayment";
static NSString *const kSectionContinueShopping = @"kSectionContinueShopping";

static BOOL haveLoadedAtLeastOnce = NO;

@interface OLProductPrintJob ()
@property (strong, nonatomic) NSMutableDictionary *options;
@property (strong, nonatomic) NSMutableSet <OLUpsellOffer *>*declinedOffers;
@property (strong, nonatomic) NSMutableSet <OLUpsellOffer *>*acceptedOffers;
@property (strong, nonatomic) OLUpsellOffer *redeemedOffer;
@end

@interface OLKiteViewController ()

@property (strong, nonatomic) OLPrintOrder *printOrder;
@property (strong, nonatomic) NSMutableArray *userSelectedPhotos;

@end

@interface OLProduct (PrivateMethods)
- (NSDecimalNumber*) unitCostDecimalNumber;
@property (strong, nonatomic) NSMutableArray *declinedOffers;
@property (strong, nonatomic) NSMutableArray *acceptedOffers;
@property (strong, nonatomic) NSDictionary *redeemedOffer;
@end


@interface OLAsset (Private)

@property (strong, nonatomic) id<OLAssetDataSource> dataSource;
@property (assign, nonatomic) BOOL corrupt;

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
#ifdef OL_OFFER_JUDOPAY
+ (BOOL)useJudoPayForGBP;
#endif
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
@property (nonatomic, strong) OLPrintOrderCostRequest *costReq;
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
@property (weak, nonatomic) IBOutlet UIButton *deliveryDetailsButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *totalCostActivityIndicator;
@property (assign, nonatomic) CGFloat keyboardAnimationPercent;
@property (assign, nonatomic) BOOL authorizedApplePay;
@property (assign, nonatomic) BOOL usedContinueShoppingButton;

@end

@interface OLPaymentViewController () <UITableViewDataSource, UITableViewDelegate
#ifdef OL_KITE_OFFER_APPLE_PAY
, PKPaymentAuthorizationViewControllerDelegate
#endif
>
@property (nonatomic, assign) BOOL presentedModally;
@end

@implementation OLPaymentViewController

- (BOOL)prefersStatusBarHidden {
    BOOL hidden = [OLKiteABTesting sharedInstance].darkTheme;
    
    if ([self respondsToSelector:@selector(traitCollection)]){
        if (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact && self.view.frame.size.height < self.view.frame.size.width){
            hidden |= YES;
        }
    }
    
    return hidden;
}

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
    
    self.shippingCostLabel.text = @"";
    self.promoCodeCostLabel.text = @"";
    
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
#else
    [self.paymentButton1 removeFromSuperview];
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardWillChangeFrameNotification object:nil];
    
    self.promoCodeTextField.delegate = self;
    
    UITapGestureRecognizer *tgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onBackgroundClicked)];
    [self.view addGestureRecognizer:tgr];
    
    if ([self.tableView respondsToSelector:@selector(setCellLayoutMarginsFollowReadableWidth:)]){
        self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    }
    
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackPaymentScreenViewedForOrder:self.printOrder applePayIsAvailable:applePayAvailableStr];
#endif
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    if ([self.kiteDelegate respondsToSelector:@selector(shouldStoreDeliveryAddresses)] && ![self.kiteDelegate shouldStoreDeliveryAddresses]){
        [OLAddress clearAddressBook];
    }
    
    if ([self isPushed]){
        if ([OLKitePrintSDK environment] == kOLKitePrintSDKEnvironmentSandbox){
            self.parentViewController.title = NSLocalizedStringFromTableInBundle(@"Payment (TEST)", @"KitePrintSDK", [OLConstants bundle], @"");
        }
        else{
            self.parentViewController.title = NSLocalizedStringFromTableInBundle(@"Payment", @"KitePrintSDK", [OLConstants bundle], @"");
        }
    }
    
    if (!haveLoadedAtLeastOnce){
        haveLoadedAtLeastOnce = YES;
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    
    if (!self.navigationController){
        [self.printOrder discardDuplicateJobs];
#ifndef OL_NO_ANALYTICS
        if (!self.usedContinueShoppingButton){
            [OLAnalytics trackPaymentScreenHitBackForOrder:self.printOrder applePayIsAvailable:[self isApplePayAvailable] ? @"Yes" : @"No"];
        }
#endif
    }
}

- (void)dismiss{
    [self.printOrder discardDuplicateJobs];
    [self.navigationController.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
#ifndef OL_NO_ANALYTICS
    if (!self.usedContinueShoppingButton){
        [OLAnalytics trackBasketScreenHitBackForOrder:self.printOrder applePayIsAvailable:[self isApplePayAvailable] ? @"Yes" : @"No"];
    }
#endif
}

- (IBAction)onButtonMoreOptionsClicked:(id)sender{
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackPaymentScreenHitCheckoutForOrder:self.printOrder];
#endif
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
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackPaymentScreenHitBackToApplePayForOrder:self.printOrder];
#endif
    
    [self.printOrder discardDuplicateJobs];
    [self updateViewsBasedOnCostUpdate];
    
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
    NSInteger animationOptions = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    CGSize size = [[userInfo objectForKey: UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    CGFloat time = [[userInfo objectForKey: UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    CGFloat diff = size.height - (self.view.frame.size.height - (self.promoBox.frame.origin.y + self.promoBox.frame.size.height));
    
    
    if (diff > 0){
        self.keyboardAnimationPercent = diff / size.height;
        if ([self.promoCodeTextField isFirstResponder]){
            self.promoBoxBottomCon.constant = 2 + diff;
            self.promoBoxTopCon.constant = 2 - diff;
            [UIView animateKeyframesWithDuration:time  delay:0 options:animationOptions << 16 animations:^{
                [UIView addKeyframeWithRelativeStartTime:time*(1-self.keyboardAnimationPercent*((1-self.keyboardAnimationPercent))) relativeDuration:time *(1-self.keyboardAnimationPercent) animations:^{
                    [self.view layoutIfNeeded];
                }];
            }completion:^(BOOL finished){}];
        }
    }
}

- (void)keyboardWillHide:(NSNotification *)notification {
    if ([self.promoCodeTextField isFirstResponder]){
        
        NSDictionary *userInfo = [notification userInfo];
        NSInteger animationOptions = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
        CGFloat time = [[userInfo objectForKey: UIKeyboardAnimationDurationUserInfoKey] doubleValue];
        self.promoBoxBottomCon.constant = 2;
        self.promoBoxTopCon.constant = 2;
        [UIView animateKeyframesWithDuration:time  delay:0 options:animationOptions animations:^{
            [UIView addKeyframeWithRelativeStartTime:0 relativeDuration:time *(1 - self.keyboardAnimationPercent) animations:^{
                [self.view layoutIfNeeded];
            }];
        }completion:^(BOOL finished){
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.05 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [self onButtonApplyPromoCodeClicked:nil];
            });
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
    
    if ([self.printOrder hasCachedCost] && !self.printOrder.costReq) {
        [self.tableView reloadData];
        [self updateViewsBasedOnCostUpdate];
    } else {
        if (self.printOrder.jobs.count > 0){
            self.totalCostLabel.hidden = YES;
            [self.totalCostActivityIndicator startAnimating];
            [self.printOrder costWithCompletionHandler:^(OLPrintOrderCost *cost, NSError *error) {
                [self costCalculationCompletedWithError:error];
            }];
        }
    }
}

- (void)handleCostError:(NSError *)error{
    if ([UIAlertController class]){
        UIAlertController *ac = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTableInBundle(@"Oops!", @"KitePrintSDK", [OLConstants bundle], @"") message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
        if (error.code == kOLKiteSDKErrorCodeProductNotAvailableInRegion){
            [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"OK", @"KitePrintSDK", [OLConstants bundle], @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
                if ([[OLCountry countryForCurrentLocale].codeAlpha3 isEqualToString:self.printOrder.shippingAddress.country.codeAlpha3] || !self.printOrder.shippingAddress.country){
                    NSMutableArray *navigationStack = [self.navigationController.viewControllers mutableCopy];
                    if (self.printOrder.jobs.count == 1){
                        [self.printOrder removePrintJob:self.printOrder.jobs.firstObject];
                    }
                    else if (navigationStack.count > 1){
                        UIViewController *reviewVc = navigationStack[navigationStack.count-2];
                        if ([reviewVc respondsToSelector:@selector(editingPrintJob)]){
                            [self.printOrder removePrintJob:[reviewVc performSelector:@selector(editingPrintJob)]];
                        }
                    }
                    [self.printOrder saveOrder];
                    [self updateViewsBasedOnCostUpdate];
                }
            }]];
        }
        else{
            [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"Cancel", @"KitePrintSDK", [OLConstants bundle], @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
                [self.navigationController popViewControllerAnimated:YES];
            }]];
            
            [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"Retry", @"KitePrintSDK", [OLConstants bundle], @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
                [self.printOrder costWithCompletionHandler:^(OLPrintOrderCost *cost, NSError *error){
                    [self costCalculationCompletedWithError:error];
                }];
            }]];
        }
        [self presentViewController:ac animated:YES completion:NULL];
    }
    else{
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Oops!", @"KitePrintSDK", [OLConstants bundle], @"") message:error.localizedDescription delegate:self cancelButtonTitle:NSLocalizedStringFromTableInBundle(@"Cancel", @"KitePrintSDK", [OLConstants bundle], @"") otherButtonTitles:NSLocalizedStringFromTableInBundle(@"Retry", @"KitePrintSDK", [OLConstants bundle], @""), nil];
        av.delegate = self;
        [av show];
    }
}

- (void)costCalculationCompletedWithError:(NSError *)error {
    [self.totalCostActivityIndicator stopAnimating];
    if (error) {
        [self handleCostError:error];
    }else {
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
        [self.tableView reloadData];
        return;
    }
    
    NSString *deliveryDetailsTitle = NSLocalizedString(@"Delivery Details", @"");
    NSMutableSet *addresses = [[NSMutableSet alloc] init];
    for (id<OLPrintJob> job in self.printOrder.jobs){
        if ([job address]){
            [addresses addObject:[job address]];
        }
    }
    if (addresses.count > 1){
        deliveryDetailsTitle = [NSString stringWithFormat:NSLocalizedString(@"%lu Delivery Addresses", @""), (unsigned long)addresses.count];
    }
    else if ([self.printOrder.shippingAddress isValidAddress]){
        deliveryDetailsTitle = [self.printOrder.shippingAddress descriptionWithoutRecipient];
    }
    [self.deliveryDetailsButton setTitle:deliveryDetailsTitle forState:UIControlStateNormal];
    
    BOOL shouldAnimate = NO;
    if (!self.printOrder.hasCachedCost || self.totalCostActivityIndicator.isAnimating){
        self.totalCostLabel.hidden = YES;
        [self.totalCostActivityIndicator startAnimating];
        shouldAnimate = YES;
    }
    
    [self.printOrder costWithCompletionHandler:^(OLPrintOrderCost *cost, NSError *error) {
        [self.totalCostActivityIndicator stopAnimating];
        
        //Small chance that the request started before we emptied the basket.
        if (self.printOrder.jobs.count == 0){
            self.totalCostLabel.hidden = NO;
            [self.totalCostActivityIndicator stopAnimating];
            self.totalCostLabel.text = [[NSDecimalNumber decimalNumberWithString:@"0.00"] formatCostForCurrencyCode:[[OLCountry countryForCurrentLocale] currencyCode]];
            self.shippingCostLabel.text = [[NSDecimalNumber decimalNumberWithString:@"0.00"] formatCostForCurrencyCode:[[OLCountry countryForCurrentLocale] currencyCode]];
            self.promoCodeCostLabel.text = @"";
            return;
        }
        
        if (error){
            [self handleCostError:error];
        }
        
        if (!cost){
            return;
        }
        
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
        
        if ([self.tableView numberOfRowsInSection:0] != self.printOrder.jobs.count){
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
        }
        
        NSString *shippingCostString;
        NSDecimalNumber *shippingCost = [cost shippingCostInCurrency:self.printOrder.currencyCode];
        if ([shippingCost isEqualToNumber:@0]){
            shippingCostString = NSLocalizedString(@"FREE", @"");
        }
        else{
            shippingCostString = [shippingCost formatCostForCurrencyCode:self.printOrder.currencyCode];
        }
        
        [UIView animateWithDuration:shouldAnimate ? 0.1 : 0 animations:^{
            if (shouldAnimate){
                if (![self.shippingCostLabel.text isEqualToString:shippingCostString]){
                    self.shippingCostLabel.alpha = 0;
                }
                self.totalCostLabel.alpha = 0;
                self.totalCostActivityIndicator.alpha = 0;
            }
        } completion:^(BOOL finished){
            
            self.totalCostLabel.text = [[cost totalCostInCurrency:self.printOrder.currencyCode] formatCostForCurrencyCode:self.printOrder.currencyCode];
            self.totalCostLabel.hidden = NO;
            [self.totalCostActivityIndicator stopAnimating];
            self.totalCostActivityIndicator.alpha = 1;
            
            self.shippingCostLabel.text = shippingCostString;
            
            NSDecimalNumber *promoCost = [cost promoCodeDiscountInCurrency:self.printOrder.currencyCode];
            if ([promoCost isEqualToNumber:@0]){
                self.promoCodeCostLabel.text = nil;
            }
            else{
                self.promoCodeCostLabel.text = [NSString stringWithFormat:@"-%@", [promoCost formatCostForCurrencyCode:self.printOrder.currencyCode]];
            }
            [UIView animateWithDuration:0.1 animations:^{
                self.shippingCostLabel.alpha = 1;
                self.totalCostLabel.alpha = 1;
            }];
        }];
        [self validateTemplatePricing];
    }];
}

/**
 *  The price on the line items on this screen are the prices from the templates. To avoid the situation where the template prices have changed and we don't know about it, do a comparison between the expected cost (based on the known template prices) and the actual prices that we got from the /cost endpoint. If we detect a discrepancy, resync the templates here.
 */
- (void)validateTemplatePricing{
    NSDecimalNumber *expectedCost = [NSDecimalNumber decimalNumberWithString:@"0"];
    for (id<OLPrintJob> job in self.printOrder.jobs){
        OLProductTemplate *template = [OLProductTemplate templateWithId:[job templateId]];
        
        NSDecimalNumber *sheetCost = [template costPerSheetInCurrencyCode:[self.printOrder currencyCode]];
        NSUInteger sheetQuanity = template.quantityPerSheet == 0 ? 1 : template.quantityPerSheet;
        NSUInteger numSheets = (NSUInteger) ceil([OLProduct productWithTemplateId:[job templateId]].quantityToFulfillOrder / sheetQuanity);
        NSDecimalNumber *unitCost = [sheetCost decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%lu", (unsigned long)numSheets]]];
        
        float numberOfPhotos = [job assetsForUploading].count;
        if (template.templateUI == kOLTemplateUIPhotobook){
            // Front cover photo should count towards total photos
            if ([(OLPhotobookPrintJob *)job frontCover]){
                numberOfPhotos--;
            }
        }
        
        NSDecimalNumber *numUnitsInJob = [job numberOfItemsInJob];
        
        expectedCost = [expectedCost decimalNumberByAdding:[unitCost decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%ld", (long)([job extraCopies] + 1)*[numUnitsInJob integerValue]]]]];
    }
    [self.printOrder costWithCompletionHandler:^(OLPrintOrderCost *cost, NSError *error){
        NSDecimalNumber *actualCost = [cost totalCostInCurrency:self.printOrder.currencyCode];
        actualCost = [actualCost decimalNumberBySubtracting:[cost shippingCostInCurrency:self.printOrder.currencyCode]];
        actualCost = [actualCost decimalNumberBySubtracting:[cost promoCodeDiscountInCurrency:self.printOrder.currencyCode]];
        
        if ([actualCost compare:expectedCost] != NSOrderedSame){
            [OLProductTemplate syncWithCompletionHandler:^(NSArray *templates, NSError *error){
                [self.tableView reloadData];
            }];
        }
    }];
}

- (void(^)())transistionToReceiptBlock{
    __weak OLPaymentViewController *welf = self;
    return ^{
        [[OLKiteUtils kiteVcForViewController:welf].userSelectedPhotos removeAllObjects];
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
    };
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
        [self.transitionBlockOperation addExecutionBlock:[self transistionToReceiptBlock]];
        if ([self isApplePayAvailable] && self.applePayDismissOperation){
            [self.transitionBlockOperation addDependency:self.applePayDismissOperation];
        }
        
        [SVProgressHUD dismiss];
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        
        if (error) {
            [self.printOrder cancelSubmissionOrPreemptedAssetUpload];
            if ([UIAlertController class]){
                UIAlertController *ac = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTableInBundle(@"Oops!", @"KitePrintSDK", [OLConstants bundle], @"") message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
                if (error.code == kOLKiteSDKErrorCodeImagesCorrupt){
                    [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"View Item", @"") style:UIAlertActionStyleCancel handler:^(id action){
                        id asset = error.userInfo[@"asset"];
                        id<OLPrintJob> job;
                        for (id<OLPrintJob> orderJob in self.printOrder.jobs){
                            if (job){
                                break;
                            }
                            for (OLAsset *jobAsset in [orderJob assetsForUploading]){
                                if (asset == jobAsset || asset == jobAsset.dataSource){
                                    job = orderJob;
                                    break;
                                }
                            }
                        }
                        
                        NSInteger jobIndex = [self.printOrder.jobs indexOfObjectIdenticalTo:job];
                        if (jobIndex != NSNotFound){
                            [self editJobAtIndexPath:[NSIndexPath indexPathForItem:jobIndex inSection:0]];
                        }
                    }]];
                    [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Not now", @"") style:UIAlertActionStyleDefault handler:NULL]];
                }
                else{
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
                }
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
        
        if (self.printOrder.printed){
            [[NSNotificationCenter defaultCenter] postNotificationName:kOLNotificationPrintOrderSubmission object:self userInfo:@{kOLKeyUserInfoPrintOrder: self.printOrder}];
#ifndef OL_NO_ANALYTICS
            [OLAnalytics trackOrderSubmission:self.printOrder];
        }
#endif
        
        if (!self.presentedViewController){
            [[NSOperationQueue mainQueue] addOperation:self.transitionBlockOperation];
        }
    }];
}

- (void)popToHome{
    // Try as best we can to go to the beginning of the app
    NSMutableArray *navigationStack = self.navigationController.viewControllers.mutableCopy;
    if (navigationStack.count > 1) {
        NSMutableArray *viewControllers = [[NSMutableArray alloc] init];
        for (UIViewController *vc in self.navigationController.viewControllers){
            [viewControllers addObject:vc];
            if ([vc isKindOfClass:[OLKiteViewController class]]){
                [self.navigationController setViewControllers:viewControllers animated:YES];
                break;
            }
        }
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
    else if (navigationStack.firstObject == self){
        [self dismiss];
    }
}

- (void)onBarButtonOrdersClicked{
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackOrderHistoryScreenViewed];
#endif
    
    OLOrdersViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"OLOrdersViewController"];
    
    [(UIViewController *)vc navigationItem].leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:vc action:@selector(dismiss)];
    
    NSString *supportEmail = [OLKiteABTesting sharedInstance].supportEmail;
    if (supportEmail && ![supportEmail isEqualToString:@""]){
        vc.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamedInKiteBundle:@"support"] style:UIBarButtonItemStyleDone target:vc action:@selector(emailButtonPushed:)];
    }
    
    OLNavigationController *nvc = [[OLNavigationController alloc] initWithRootViewController:vc];
    nvc.modalPresentationStyle = [OLKiteUtils kiteVcForViewController:self].modalPresentationStyle;
    [self presentViewController:nvc animated:YES completion:NULL];
}

- (UINavigationController *)navViewControllerWithControllers:(NSArray *)vcs{
    OLNavigationController *navController = [[OLNavigationController alloc] init];
    
    navController.viewControllers = vcs;
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismissPresentedViewController)];
    
    ((UIViewController *)[vcs firstObject]).navigationItem.leftBarButtonItem = doneButton;
    
    return navController;
}

- (void)saveAndDismissReviewController{
    OLNavigationController *nvc = (OLNavigationController *)self.presentedViewController;
    if (![nvc isKindOfClass:[OLNavigationController class]]){
        return;
    }
    
    OLOrderReviewViewController *editingVc = nvc.viewControllers.lastObject;
    if ([editingVc respondsToSelector:@selector(saveJobWithCompletionHandler:)]){
        [editingVc saveJobWithCompletionHandler:^{
            [self.tableView reloadData];
            [self dismissPresentedViewController];
#ifndef OL_NO_ANALYTICS
            [OLAnalytics trackPaymentScreenHitEditItemDone:editingVc.editingPrintJob inOrder:self.printOrder applePayIsAvailable:[self isApplePayAvailable] ? @"Yes" : @"No"];
#endif
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
        [self.printOrder costWithCompletionHandler:^(OLPrintOrderCost *cost, NSError *error){
            [self costCalculationCompletedWithError:error];
        }];
    }];
}

- (void)applyPromoCode:(NSString *)promoCode {
    if (promoCode != nil) {
        if ([promoCode isEqualToString:self.printOrder.promoCode]){
            return;
        }
        [SVProgressHUD showWithStatus:NSLocalizedStringFromTableInBundle(@"Checking Code", @"KitePrintSDK", [OLConstants bundle], @"")];
    } else {
        if (!self.printOrder.promoCode || [self.printOrder.promoCode isEqualToString:@""]){
            return;
        }
        [SVProgressHUD showWithStatus:NSLocalizedStringFromTableInBundle(@"Clearing Code", @"KitePrintSDK", [OLConstants bundle], @"")];
    }
    
    NSString *previousCode = self.printOrder.promoCode;
    self.printOrder.promoCode = promoCode;
    [self.printOrder costWithCompletionHandler:^(OLPrintOrderCost *cost, NSError *error) {
        if (error) {
#ifndef OL_NO_ANALYTICS
            [OLAnalytics trackPaymentScreenUnsuccessfullyAppliedPromoCode:promoCode withError:error forOrder:self.printOrder];
#endif
            [SVProgressHUD dismiss];
            [self costCalculationCompletedWithError:error];
        } else {
            if (cost.promoCodeInvalidReason) {
#ifndef OL_NO_ANALYTICS
                [OLAnalytics trackPaymentScreenUnsuccessfullyAppliedPromoCode:promoCode withError:[NSError errorWithDomain:@"ly.kite.sdk" code:0 userInfo:@{NSLocalizedDescriptionKey : cost.promoCodeInvalidReason}] forOrder:self.printOrder];
#endif
                self.printOrder.promoCode = previousCode; // reset print order promo code as it was invalid
                self.promoCodeTextField.text = previousCode;
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
                [self updateViewsBasedOnCostUpdate];
                if (self.printOrder.promoCode) {
#ifndef OL_NO_ANALYTICS
                    [OLAnalytics trackPaymentScreenSuccessfullyAppliedPromoCode:self.printOrder.promoCode forOrder:self.printOrder];
#endif
                    sleep(1);
                    [SVProgressHUD showSuccessWithStatus:nil];
                } else {
                    [SVProgressHUD dismiss];
                }
            }
        }
    }];
}

- (BOOL)showPhoneEntryField {
    if ([self.kiteDelegate respondsToSelector:@selector(shouldShowPhoneEntryOnCheckoutScreen)]) {
        return [self.kiteDelegate shouldShowPhoneEntryOnCheckoutScreen]; // delegate overrides whatever the A/B test might say.
    }
    
    return [OLKiteABTesting sharedInstance].requirePhoneNumber;
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
                [self.printOrder costWithCompletionHandler:^(OLPrintOrderCost *cost, NSError *error){
                    [self costCalculationCompletedWithError:error];
                }];
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
        if (!cost){
            [self updateViewsBasedOnCostUpdate];
            return;
        }
        
#ifndef OL_NO_ANALYTICS
        [OLAnalytics trackPaymentScreenPaymentMethodHit:@"Credit Card" forOrder:self.printOrder applePayIsAvailable:[self isApplePayAvailable] ? @"Yes" : @"No"];
#endif
        
        NSComparisonResult result = [[cost totalCostInCurrency:self.printOrder.currencyCode] compare:[NSDecimalNumber zero]];
        if (result == NSOrderedAscending || result == NSOrderedSame) {
            // The user must have a promo code which reduces this order cost to nothing, lucky user :)
            [self submitOrderForPrintingWithProofOfPayment:nil paymentMethod:@"Free Checkout" completion:^void(PKPaymentAuthorizationStatus status){}];
        } else {
            
            id card = [OLPayPalCard lastUsedCard];
            
            if ([OLKitePrintSDK useStripeForCreditCards]){
                card = [OLStripeCard lastUsedCard];
            }
#ifdef OL_OFFER_JUDOPAY
            else if ([OLKitePrintSDK useJudoPayForGBP] && [self.printOrder.currencyCode isEqualToString:@"GBP"]) {
                card = [OLJudoPayCard lastUsedCard];
            }
#endif
            
            
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
                        }
#ifdef OL_OFFER_JUDOPAY
                        else if ([OLKitePrintSDK useJudoPayForGBP] && [self.printOrder.currencyCode isEqualToString:@"GBP"]) {
                            [self payWithExistingJudoPayCard:[OLJudoPayCard lastUsedCard]];
                        }
#endif
                        else {
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
    ccCaptureController.modalPresentationStyle = [OLKiteUtils kiteVcForViewController:self].modalPresentationStyle;
    [self presentViewController:ccCaptureController animated:YES completion:nil];
}

- (void)payWithExistingPayPalCard:(OLPayPalCard *)card {
#ifdef OL_OFFER_JUDOPAY
    if ([OLKitePrintSDK useJudoPayForGBP]) {
        NSAssert(![self.printOrder.currencyCode isEqualToString:@"GBP"], @"JudoPay should be used for GBP orders (and only for Kite internal use)");
    }
#endif
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

#ifdef OL_OFFER_JUDOPAY
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
#endif

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
        if (!cost){
            [self updateViewsBasedOnCostUpdate];
            return;
        }
#ifndef OL_NO_ANALYTICS
        [OLAnalytics trackPaymentScreenPaymentMethodHit:@"PayPal" forOrder:self.printOrder applePayIsAvailable:[self isApplePayAvailable] ? @"Yes" : @"No"];
#endif
        
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
        paymentViewController.modalPresentationStyle = [OLKiteUtils kiteVcForViewController:self].modalPresentationStyle;
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
        if (!cost){
            [self updateViewsBasedOnCostUpdate];
            return;
        }
#ifndef OL_NO_ANALYTICS
        [OLAnalytics trackPaymentScreenPaymentMethodHit:@"Apple Pay" forOrder:self.printOrder applePayIsAvailable:[self isApplePayAvailable] ? @"Yes" : @"No"];
#endif
        
        NSMutableArray *lineItems = [[NSMutableArray alloc] init];
        for (OLPaymentLineItem *item in cost.lineItems){
            [lineItems addObject:[PKPaymentSummaryItem summaryItemWithLabel:item.description  amount:[item costInCurrency:self.printOrder.currencyCode]]];
        }
        [lineItems addObject:[PKPaymentSummaryItem summaryItemWithLabel:[OLKitePrintSDK applePayPayToString] amount:[cost totalCostInCurrency:self.printOrder.currencyCode]]];
        paymentRequest.paymentSummaryItems = lineItems;
        NSUInteger requiredFields = PKAddressFieldPostalAddress | PKAddressFieldName | PKAddressFieldEmail;
        if ([self showPhoneEntryField]){
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
#ifndef OL_NO_ANALYTICS
                [OLAnalytics trackPaymentScreenDidDeleteItem:printJob inOrder:self.printOrder applePayIsAvailable:[self isApplePayAvailable] ? @"Yes" : @"No"];
#endif
                [self.printOrder removePrintJob:printJob];
                
                NSMutableSet *addresses = [[NSMutableSet alloc] init];
                for (id<OLPrintJob> job in self.printOrder.jobs){
                    if ([job address]){
                        [addresses addObject:[job address]];
                    }
                }
                if (addresses.count == 1){
                    self.printOrder.shippingAddress = [addresses anyObject];
                    [self.printOrder discardDuplicateJobs];
                }
                
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
                [self.printOrder saveOrder];
                [self updateViewsBasedOnCostUpdate];
            }]];
            [self presentViewController:ac animated:YES completion:NULL];
        }
        else{ //on iOS 7, just delete without prompt
#ifndef OL_NO_ANALYTICS
            [OLAnalytics trackPaymentScreenDidDeleteItem:printJob inOrder:self.printOrder applePayIsAvailable:[self isApplePayAvailable] ? @"Yes" : @"No"];
#endif
            [self.printOrder removePrintJob:printJob];
            
            NSMutableSet *addresses = [[NSMutableSet alloc] init];
            for (id<OLPrintJob> job in self.printOrder.jobs){
                if ([job address]){
                    [addresses addObject:[job address]];
                }
            }
            if (addresses.count == 1){
                self.printOrder.shippingAddress = [addresses anyObject];
                [self.printOrder discardDuplicateJobs];
            }
            
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.printOrder saveOrder];
            [self updateViewsBasedOnCostUpdate];
        }
        
    }
    else{
        printJob.extraCopies--;
        
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        [self.printOrder saveOrder];
        [self updateViewsBasedOnCostUpdate];
        
#ifndef OL_NO_ANALYTICS
        [OLAnalytics trackPaymentScreenHitItemQtyDownForItem:printJob inOrder:self.printOrder applePayIsAvailable:[self isApplePayAvailable] ? @"Yes" : @"No"];
#endif
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
    
    [self.printOrder saveOrder];
    [self updateViewsBasedOnCostUpdate];
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackPaymentScreenHitItemQtyUpForItem:printJob inOrder:self.printOrder applePayIsAvailable:[self isApplePayAvailable] ? @"Yes" : @"No"];
#endif
}

- (IBAction)onButtonEditClicked:(UIButton *)sender {
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
    
    [self editJobAtIndexPath:indexPath];
}

- (void)editJobAtIndexPath:(NSIndexPath *)indexPath{
    UIViewController *vc = [self viewControllerForItemAtIndexPath:indexPath];
    vc.modalPresentationStyle = [OLKiteUtils kiteVcForViewController:self].modalPresentationStyle;
    [self presentViewController:vc animated:YES completion:NULL];
#ifndef OL_NO_ANALYTICS
    OLProductPrintJob* printJob = ((OLProductPrintJob*)[self.printOrder.jobs objectAtIndex:indexPath.row]);
    [OLAnalytics trackPaymentScreenHitEditItem:printJob inOrder:self.printOrder applePayIsAvailable:[self isApplePayAvailable] ? @"Yes" : @"No"];
#endif
}

- (IBAction)onButtonContinueShoppingClicked:(UIButton *)sender {
    self.usedContinueShoppingButton = YES;
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackContinueShoppingButtonPressed:self.printOrder];
#endif
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(userDidTapContinueShoppingButton)]){
        [self.delegate userDidTapContinueShoppingButton];
    }
    else{
        [self popToHome];
    }
}

- (IBAction)onShippingDetailsGestureRecognized:(id)sender {
    [OLKiteUtils shippingControllerForPrintOrder:self.printOrder handler:^(id vc){
        [vc safePerformSelector:@selector(setUserEmail:) withObject:self.userEmail];
        [vc safePerformSelector:@selector(setUserPhone:) withObject:self.userPhone];
        [vc safePerformSelector:@selector(setDelegate:) withObject:self.delegate];
        [vc safePerformSelector:@selector(setKiteDelegate:) withObject:self.kiteDelegate];
        
        OLNavigationController *nvc = [[OLNavigationController alloc] initWithRootViewController:vc];
        [[(UINavigationController *)vc view] class]; //force viewDidLoad;
        [(OLCheckoutViewController *)vc navigationItem].rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:vc action:@selector(onButtonDoneClicked)];
        
        nvc.modalPresentationStyle = [OLKiteUtils kiteVcForViewController:self].modalPresentationStyle;
        [self presentViewController:nvc animated:YES completion:NULL];
    }];
}

#pragma mark - PayPalPaymentDelegate methods

#ifdef OL_KITE_OFFER_PAYPAL
- (void)payPalPaymentDidCancel:(PayPalPaymentViewController *)paymentViewController {
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackPaymentScreenPaymentMethodDidCancel:@"PayPal" forOrder:self.printOrder applePayIsAvailable:[self isApplePayAvailable] ? @"Yes" : @"No"];
#endif
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
    self.authorizedApplePay = YES;
    [self handlePaymentAuthorizationWithPayment:payment completion:completion];
}

- (void)paymentAuthorizationViewControllerDidFinish:(PKPaymentAuthorizationViewController *)controller {
    [self dismissViewControllerAnimated:YES completion:^{
#ifndef OL_NO_ANALYTICS
        if (!self.authorizedApplePay){
            [OLAnalytics trackPaymentScreenPaymentMethodDidCancel:@"Apple Pay" forOrder:self.printOrder applePayIsAvailable:[self isApplePayAvailable] ? @"Yes" : @"No"];
        }
#endif
        if (![[NSOperationQueue mainQueue].operations containsObject:self.transitionBlockOperation] && !self.transitionBlockOperation.finished){
            [[NSOperationQueue mainQueue] addOperation:self.transitionBlockOperation];
        }
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
    CFTypeRef emails = ABRecordCopyValue(address, kABPersonEmailProperty);
    for (NSInteger i = 0; i < ABMultiValueGetCount(emails); i++){
        email = (__bridge_transfer NSString *)(ABMultiValueCopyValueAtIndex(emails, i));
    }
    CFTypeRef phones = ABRecordCopyValue(address, kABPersonPhoneProperty);
    for (NSInteger i = 0; i < ABMultiValueGetCount(phones); i++){
        phone = (__bridge_transfer NSString *)(ABMultiValueCopyValueAtIndex(phones, i));
    }
    
    self.printOrder.email = email;
    self.printOrder.phone = phone;
    
    if (![OLCheckoutViewController validateEmail:email] && [OLKitePrintSDK environment] == kOLKitePrintSDKEnvironmentLive){
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
        shippingAddress.country = [OLCountry countryForCode:[dict objectForKey:(id)kABPersonAddressCountryKey]];
        if (!shippingAddress.country){
            shippingAddress.country = [OLCountry countryForName:[dict objectForKey:(id)kABPersonAddressCountryKey]];
        }
        if (!shippingAddress.country){
            shippingAddress.country = [OLCountry countryForCode:[dict objectForKey:(id)kABPersonAddressCountryCodeKey]];
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
        [self costCalculationCompletedWithError:error];
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
    else if (self.navigationController.viewControllers.firstObject == self){
        return 1;
    }
    else{
        return 2;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0 && self.printOrder.jobs.count > 0){
        return haveLoadedAtLeastOnce ? self.printOrder.jobs.count : 1;
    }
    else if (section == 0 && self.printOrder.jobs.count == 0){
        return 1;
    }
    else{
        return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && !haveLoadedAtLeastOnce){
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"loadingCell"];
        UIActivityIndicatorView *activity = [cell viewWithTag:10];
        [activity startAnimating];
        cell.backgroundColor = [UIColor clearColor];
        
        return cell;
    }
    else if (indexPath.section == 0 && self.printOrder.jobs.count > 0){
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"jobCell"];
        UIImageView *imageView = (UIImageView *)[cell.contentView viewWithTag:20];
        UILabel *quantityLabel = (UILabel *)[cell.contentView viewWithTag:30];
        UILabel *productNameLabel = (UILabel *)[cell.contentView viewWithTag:50];
        UIButton *editButton = (UIButton *)[cell.contentView viewWithTag:60];
        UIButton *largeEditButton = (UIButton *)[cell.contentView viewWithTag:61];
        UILabel *priceLabel = (UILabel *)[cell.contentView viewWithTag:70];
        UILabel *addressLabel = (UILabel *)[cell.contentView viewWithTag:80];
        
        id<OLPrintJob> job = self.printOrder.jobs[indexPath.row];
        
        if ([job address]){
            addressLabel.text = [[job address] descriptionWithoutRecipient];
        }
        else{
            addressLabel.text = nil;
        }
        
        OLProduct *product = [OLProduct productWithTemplateId:[job templateId]];
        
        if (product.productTemplate.templateUI == kOLTemplateUINA || product.productTemplate.templateUI == kOLTemplateUINonCustomizable || [OLKiteUtils assetArrayContainsPDF:[job assetsForUploading]]){
            editButton.hidden = YES;
            largeEditButton.hidden = YES;
        }
        else{
            editButton.hidden = NO;
            largeEditButton.hidden = NO;
        }
        
        [SDWebImageManager.sharedManager downloadImageWithURL:product.productTemplate.coverPhotoURL options:0 progress:NULL completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
            imageView.image = image;
        }];
        
        quantityLabel.text = [NSString stringWithFormat:@"%ld", (long)[job extraCopies]+1];

        NSDecimalNumber *numUnitsInJob = [job numberOfItemsInJob];
        
        priceLabel.text = [[numUnitsInJob decimalNumberByMultiplyingBy:[[product unitCostDecimalNumber] decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%ld", (long)[job extraCopies]+1]]]] formatCostForCurrencyCode:self.printOrder.currencyCode];
        
        if ([numUnitsInJob integerValue] == 1){
            productNameLabel.text = product.productTemplate.name;
        }
        else{
            productNameLabel.text = [NSString stringWithFormat:@"%@ (x %ld)", product.productTemplate.name, (long)[numUnitsInJob integerValue]];
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
    return NO;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField{
    return self.printOrder.jobs.count > 0;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField{
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackPaymentScreenDidTapOnPromoCodeBoxforOrder:self.printOrder];
#endif
}

- (BOOL) tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    return indexPath.section == 0;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        id<OLPrintJob> job = self.printOrder.jobs[indexPath.row];
        [self.printOrder removePrintJob:job];
        
        NSMutableSet *addresses = [[NSMutableSet alloc] init];
        for (id<OLPrintJob> job in self.printOrder.jobs){
            if ([job address]){
                [addresses addObject:[job address]];
            }
        }
        if (addresses.count == 1){
            self.printOrder.shippingAddress = [addresses anyObject];
            [self.printOrder discardDuplicateJobs];
        }
        
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.printOrder saveOrder];
        [self updateViewsBasedOnCostUpdate];
        
#ifndef OL_NO_ANALYTICS
        [OLAnalytics trackPaymentScreenDidDeleteItem:job inOrder:self.printOrder applePayIsAvailable:[self isApplePayAvailable] ? @"Yes" : @"No"];
#endif
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
    viewControllerToCommit.modalPresentationStyle = [OLKiteUtils kiteVcForViewController:self].modalPresentationStyle;
    [self presentViewController:viewControllerToCommit animated:YES completion:NULL];
}

- (UIViewController *)viewControllerForItemAtIndexPath:(NSIndexPath *)indexPath{
    OLProductPrintJob* printJob = ((OLProductPrintJob*)[self.printOrder.jobs objectAtIndex:indexPath.row]);
    OLProduct *product = [OLProduct productWithTemplateId:printJob.templateId];
    product.acceptedOffers = [[[printJob safePerformSelectorWithReturn:@selector(acceptedOffers)withObject:nil] allObjects] mutableCopy];
    product.declinedOffers = [[[printJob safePerformSelectorWithReturn:@selector(declinedOffers)withObject:nil] allObjects] mutableCopy];
    product.redeemedOffer = [printJob safePerformSelectorWithReturn:@selector(redeemedOffer) withObject:nil];
    product.uuid = printJob.uuid;
    
    for (NSString *option in printJob.options.allKeys){
        product.selectedOptions[option] = printJob.options[option];
    }
    
    NSMutableArray *userSelectedPhotos = [[NSMutableArray alloc] init];
    NSMutableSet *addedAssetsUUIDs = [[NSMutableSet alloc] init];
    
    NSMutableArray *jobAssets = [[printJob assetsForUploading] mutableCopy];
    
    //Special handling of products
    if (product.productTemplate.templateUI == kOLTemplateUIPhotobook && [(OLPhotobookPrintJob *)printJob frontCover]){
        //Make sure we don't add the cover photo asset in the book photos
        OLAsset *asset = [(OLPhotobookPrintJob *)printJob frontCover];
        OLPrintPhoto *printPhoto = [[OLPrintPhoto alloc] init];
        printPhoto.asset = asset;
        
        if ([asset.dataSource isKindOfClass:[OLPrintPhoto class]]){
            printPhoto = (OLPrintPhoto *)asset.dataSource;
        }
        if (printPhoto.uuid){
            [addedAssetsUUIDs addObject:printPhoto.uuid];
        }
    }
    else if (product.productTemplate.templateUI == kOLTemplateUIPoster){
        [OLPosterViewController changeOrderOfPhotosInArray:jobAssets forProduct:product];
    }
    else if (product.productTemplate.templateUI == kOLTemplateUIFrame){
        [OLFrameOrderReviewViewController reverseRowsOfPhotosInArray:jobAssets forProduct:product];
    }
    
    for (OLAsset *asset in jobAssets){
        if ([asset corrupt]){
            continue;
        }
        OLPrintPhoto *printPhoto = [[OLPrintPhoto alloc] init];
        printPhoto.asset = asset;
        
        if ([asset.dataSource isKindOfClass:[OLPrintPhoto class]]){
            printPhoto = (OLPrintPhoto *)asset.dataSource;
        }
        [printPhoto unloadImage];
        if (![addedAssetsUUIDs containsObject:printPhoto.uuid]){
            [addedAssetsUUIDs addObject:printPhoto.uuid];
            [userSelectedPhotos addObject:printPhoto];
        }
    
    }
    
    if ([OLKiteUtils imageProvidersAvailable:self] && product.productTemplate.templateUI != kOLTemplateUICase && product.productTemplate.templateUI != kOLTemplateUIPhotobook && product.productTemplate.templateUI != kOLTemplateUIPostcard && !(product.productTemplate.templateUI == kOLTemplateUIPoster && product.productTemplate.gridCountX == 1 && product.productTemplate.gridCountY == 1)){
        OLPhotoSelectionViewController *photoVc = [self.storyboard instantiateViewControllerWithIdentifier:@"PhotoSelectionViewController"];
        photoVc.product = product;
        photoVc.userSelectedPhotos = userSelectedPhotos;
        return [self navViewControllerWithControllers:@[photoVc]];
    }
    else{
        UIViewController* orvc = [self.storyboard instantiateViewControllerWithIdentifier:[OLKiteUtils reviewViewControllerIdentifierForProduct:product photoSelectionScreen:NO]];
        if ([printJob isKindOfClass:[OLPhotobookPrintJob class]] && [(OLPhotobookPrintJob *)printJob frontCover]){
            OLPrintPhoto *coverPhoto = [[OLPrintPhoto alloc] init];
            coverPhoto.asset = [(OLPhotobookPrintJob *)printJob frontCover];
            [orvc safePerformSelector:@selector(setCoverPhoto:) withObject:coverPhoto];
        }
        else{
            [orvc safePerformSelector:@selector(setCoverPhoto:) withObject:[NSNull null]];
        }
        
        [orvc safePerformSelector:@selector(setProduct:) withObject:product];
        [orvc safePerformSelector:@selector(setUserSelectedPhotos:) withObject:userSelectedPhotos];
        [orvc safePerformSelector:@selector(setEditingPrintJob:) withObject:printJob];
        return [self navViewControllerWithControllers:@[orvc]];
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
        }
#ifdef OL_OFFER_JUDOPAY
        else if ([OLKitePrintSDK useJudoPayForGBP] && [self.printOrder.currencyCode isEqualToString:@"GBP"]) {
            [self payWithExistingJudoPayCard:[OLJudoPayCard lastUsedCard]];
        }
#endif
        else {
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

- (void)creditCardCaptureControllerDismissed:(OLCreditCardCaptureViewController *)vc{
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackPaymentScreenPaymentMethodDidCancel:@"Credit Card" forOrder:self.printOrder applePayIsAvailable:[self isApplePayAvailable] ? @"Yes" : @"No"];
#endif
    [self dismissViewControllerAnimated:YES completion:NULL];
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
