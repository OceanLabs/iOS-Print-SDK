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
#import <SVProgressHUD/SVProgressHUD.h>
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
#import "OLPaymentLineItem.h"
#import "UIView+RoundRect.h"
#import "OLBaseRequest.h"
#import "OLPrintOrderCost.h"
#import "OLKiteABTesting.h"
#import <SDWebImage/SDWebImageManager.h>
#import "UIImage+ColorAtPixel.h"
#import "UIImage+ImageNamedInKiteBundle.h"
#import "UIImageView+FadeIn.h"
#import "NSDecimalNumber+CostFormatter.h"

#ifdef OL_KITE_OFFER_PAYPAL
#import <PayPal-iOS-SDK/PayPalMobile.h>
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

@interface OLCheckoutViewController (Private)

+ (BOOL)validateEmail:(NSString *)candidate;

@end

@interface OLKitePrintSDK (Private)
+ (BOOL)useJudoPayForGBP;

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
@end

@interface OLProduct (Private)
- (NSDecimalNumber*) unitCostDecimalNumber;
@end

@interface OLPaymentViewController () <
#ifdef OL_KITE_OFFER_PAYPAL
PayPalPaymentDelegate,
#endif
UIActionSheetDelegate, UITextFieldDelegate, OLCreditCardCaptureDelegate, UINavigationControllerDelegate, UITableViewDelegate, UIScrollViewDelegate>

@property (strong, nonatomic) OLPrintOrder *printOrder;
@property (strong, nonatomic) OLPayPalCard *card;
@property (assign, nonatomic) BOOL clearPromoCode;

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

- (void)setupBannerImage:(UIImage *)bannerImage withBgImage:(UIImage *)bannerBgImage{
    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, bannerImage.size.height + 20)];
    UIImageView *banner = [[UIImageView alloc] initWithImage:bannerImage];
    
    UIImageView *bannerBg;
    if(bannerBgImage){
        bannerBg = [[UIImageView alloc] initWithImage:bannerBgImage];
    }
    else{
        bannerBg = [[UIImageView alloc] init];
        bannerBg.backgroundColor = [bannerImage colorAtPixel:CGPointMake(3, 3)];
    }
    [self.tableView.tableHeaderView addSubview:bannerBg];
    [self.tableView.tableHeaderView addSubview:banner];
    if (bannerBgImage.size.width > 100){
        bannerBg.contentMode = UIViewContentModeTop;
    }
    else{
        bannerBg.contentMode = UIViewContentModeScaleToFill;
    }
    banner.contentMode = UIViewContentModeCenter;
    
    banner.translatesAutoresizingMaskIntoConstraints = NO;
    NSDictionary *views = NSDictionaryOfVariableBindings(banner);
    NSMutableArray *con = [[NSMutableArray alloc] init];
    
    NSArray *visuals = @[@"H:|-0-[banner]-0-|",
                         @"V:|-0-[banner]-0-|"];
    
    
    for (NSString *visual in visuals) {
        [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
    }
    
    [banner.superview addConstraints:con];
    
    bannerBg.translatesAutoresizingMaskIntoConstraints = NO;
    views = NSDictionaryOfVariableBindings(bannerBg);
    con = [[NSMutableArray alloc] init];
    
    visuals = @[@"H:|-0-[bannerBg]-0-|",
                @"V:|-0-[bannerBg]-0-|"];
    
    
    for (NSString *visual in visuals) {
        [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
    }
    
    [bannerBg.superview addConstraints:con];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", @"")
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:nil
                                                                            action:nil];
    
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
    self.tableView.sectionHeaderHeight = 0;
    
    if ([self shippingScreenOnTheStack]) {
        NSString *url = [OLKiteABTesting sharedInstance].checkoutProgress2URL;
        if (url){
            [[SDWebImageManager sharedManager] downloadImageWithURL:[NSURL URLWithString:url] options:0 progress:NULL completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL){
                image = [UIImage imageWithCGImage:image.CGImage scale:2 orientation:image.imageOrientation];
                NSString *bgUrl = [OLKiteABTesting sharedInstance].checkoutProgress2BgURL;
                if (bgUrl){
                    [[SDWebImageManager sharedManager] downloadImageWithURL:[NSURL URLWithString:bgUrl] options:0 progress:NULL completed:^(UIImage *bgImage, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL){
                        bgImage = [UIImage imageWithCGImage:bgImage.CGImage scale:2 orientation:image.imageOrientation];
                        [self setupBannerImage:image withBgImage:bgImage];
                    }];
                }
                else{
                    [self setupBannerImage:image withBgImage:nil];
                }
                
            }];
        }
        else{
            [self setupBannerImage:[UIImage imageNamedInKiteBundle:@"checkout_progress_indicator2"] withBgImage:[UIImage imageNamedInKiteBundle:@"checkout_progress_indicator2_bg"]];
        }
        
    }
    
    [self.paymentButton1 makeRoundRect];
    [self.paymentButton2 makeRoundRect];
    
    
#ifdef OL_KITE_OFFER_PAYPAL
    if ([OLKiteABTesting sharedInstance].offerPayPal && ![self shouldShowApplePay]){
        //TODO: Set up paypal here
    }
#endif
    
#ifdef OL_KITE_OFFER_APPLE_PAY
    if ([self shouldShowApplePay]){
        //TODO set up apple pay here
        [self.paymentButton1 setImage:[UIImage imageNamedInKiteBundle:@"button_apple_pay"] forState:UIControlStateNormal];
        [self.paymentButton1 setTitle:nil forState:UIControlStateNormal];
        [self.paymentButton1 setBackgroundColor:[UIColor blackColor]];
        [self.paymentButton1 addTarget:self action:@selector(onButtonPayWithApplePayClicked) forControlEvents:UIControlEventTouchUpInside];
        
        [self.paymentButton2 setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [self.paymentButton2 setBackgroundColor:[UIColor colorWithRed:1.000 green:0.841 blue:0.000 alpha:1.000]];
        [self.paymentButton2 setTitle:NSLocalizedString(@"Checkout", @"") forState:UIControlStateNormal];
        [self.paymentButton2 addTarget:self action:@selector(onButtonMoreOptionsClicked) forControlEvents:UIControlEventTouchUpInside];
    }
#endif
    
    [self updateViewsBasedOnCostUpdate]; // initialise based on promo state
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardWillChangeFrameNotification object:nil];
    
    self.promoCodeTextField.delegate = self;
    
    UITapGestureRecognizer *tgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onBackgroundClicked)];
    tgr.cancelsTouchesInView = NO; // allow table cell selection to happen as normal
    [self.view addGestureRecognizer:tgr];
    
    if ([self.tableView respondsToSelector:@selector(setCellLayoutMarginsFollowReadableWidth:)]){
        self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    }
}

- (void)onButtonMoreOptionsClicked{
    OLCheckoutViewController *vc = [[OLCheckoutViewController alloc] initWithPrintOrder:self.printOrder];
    vc.delegate = self.delegate;
    vc.showOtherOptions = YES;
    [self.navigationController pushViewController:vc animated:YES];
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
        [self.printOrder costWithCompletionHandler:^(OLPrintOrderCost *cost, NSError *error) {
            [self costCalculationCompletedWithError:error];
        }];
    }
    
    if ([self shouldShowApplePay]){
        [self.printOrder discardDuplicateJobs];
    }
}

- (void)costCalculationCompletedWithError:(NSError *)error {
    if (error) {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Oops!", @"KitePrintSDK", [OLConstants bundle], @"") message:error.localizedDescription delegate:self cancelButtonTitle:NSLocalizedStringFromTableInBundle(@"Cancel", @"KitePrintSDK", [OLConstants bundle], @"") otherButtonTitles:NSLocalizedStringFromTableInBundle(@"Retry", @"KitePrintSDK", [OLConstants bundle], @""), nil];
        av.delegate = self;
        [av show];
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
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)updateViewsBasedOnCostUpdate {
    self.totalCostLabel.text = NSLocalizedString(@"Loading...", @"");
    self.shippingCostLabel.text = nil;
    self.promoCodeCostLabel.text = nil;
    
    
    [self.printOrder costWithCompletionHandler:^(OLPrintOrderCost *cost, NSError *error) {
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
            [self.paymentButton2 setTitle:NSLocalizedStringFromTableInBundle(@"Checkout for Free!", @"KitePrintSDK", [OLConstants bundle], @"") forState:UIControlStateNormal];
        } else {
#ifdef OL_KITE_OFFER_PAYPAL
            self.paymentButton1.hidden = NO;
#endif
#ifdef OL_KITE_OFFER_APPLE_PAY
            self.paymentButton1.hidden = NO;
#endif
            if ([self shouldShowApplePay]){
                [self.paymentButton2 setTitle:NSLocalizedString(@"Checkout", @"") forState:UIControlStateNormal];
            }
            else{
                [self.paymentButton2 setTitle:NSLocalizedStringFromTableInBundle(@"Credit Card", @"KitePrintSDK", [OLConstants bundle], @"") forState:UIControlStateNormal];
            }
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
            UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Oops!", @"KitePrintSDK", [OLConstants bundle], @"") message:error.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedStringFromTableInBundle(@"OK", @"KitePrintSDK", [OLConstants bundle], @"") otherButtonTitles:nil];
            [av show];
        } else {
            if (cost.promoCodeInvalidReason) {
                self.printOrder.promoCode = previousCode; // reset print order promo code as it was invalid
                [SVProgressHUD dismiss];
                UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Oops!", @"KitePrintSDK", [OLConstants bundle], @"") message:cost.promoCodeInvalidReason delegate:nil cancelButtonTitle:NSLocalizedStringFromTableInBundle(@"OK", @"KitePrintSDK", [OLConstants bundle], @"") otherButtonTitles:nil];
                [av show];
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

- (IBAction)onButtonApplyPromoCodeClicked:(id)sender {
    if (self.clearPromoCode) {
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
    [self.printOrder costWithCompletionHandler:^(OLPrintOrderCost *cost, NSError *error) {
        NSComparisonResult result = [[cost totalCostInCurrency:self.printOrder.currencyCode] compare:[NSDecimalNumber zero]];
        if (result == NSOrderedAscending || result == NSOrderedSame) {
            // The user must have a promo code which reduces this order cost to nothing, lucky user :)
            [self submitOrderForPrintingWithProofOfPayment:nil paymentMethod:@"Free Checkout" completion:^void(PKPaymentAuthorizationStatus status){}];
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
    [SVProgressHUD showWithStatus:NSLocalizedStringFromTableInBundle(@"Processing", @"KitePrintSDK", [OLConstants bundle], @"") maskType:SVProgressHUDMaskTypeBlack];
    [self.printOrder costWithCompletionHandler:^(OLPrintOrderCost *cost, NSError *error) {
        [card chargeCard:[cost totalCostInCurrency:self.printOrder.currencyCode] currencyCode:self.printOrder.currencyCode description:self.printOrder.paymentDescription completionHandler:^(NSString *proofOfPayment, NSError *error) {
            if (error) {
                [SVProgressHUD dismiss];
                [[[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Oops!", @"KitePrintSDK", [OLConstants bundle], @"") message:error.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedStringFromTableInBundle(@"OK", @"KitePrintSDK", [OLConstants bundle], @"") otherButtonTitles:nil] show];
                return;
            }
            
            [self submitOrderForPrintingWithProofOfPayment:proofOfPayment paymentMethod:@"Credit Card" completion:^void(PKPaymentAuthorizationStatus status){}];
            [card saveAsLastUsedCard];
        }];
    }];
}

- (void)payWithExistingJudoPayCard:(OLJudoPayCard *)card {
    NSAssert([self.printOrder.currencyCode isEqualToString:@"GBP"], @"JudoPay should only be used for GBP orders (and only for Kite internal use)");
    [SVProgressHUD showWithStatus:NSLocalizedStringFromTableInBundle(@"Processing", @"KitePrintSDK", [OLConstants bundle], @"") maskType:SVProgressHUDMaskTypeBlack];
    [self.printOrder costWithCompletionHandler:^(OLPrintOrderCost *cost, NSError *error) {
        [card chargeCard:[cost totalCostInCurrency:@"GBP"] currency:kOLJudoPayCurrencyGBP description:self.printOrder.paymentDescription completionHandler:^(NSString *proofOfPayment, NSError *error) {
            if (error) {
                [SVProgressHUD dismiss];
                [[[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Oops!", @"KitePrintSDK", [OLConstants bundle], @"") message:error.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedStringFromTableInBundle(@"OK", @"KitePrintSDK", [OLConstants bundle], @"") otherButtonTitles:nil] show];
                return;
            }
            
            [self submitOrderForPrintingWithProofOfPayment:proofOfPayment paymentMethod:@"Credit Card" completion:^void(PKPaymentAuthorizationStatus status){}];
            [card saveAsLastUsedCard];
        }];
    }];
}

#ifdef OL_KITE_OFFER_PAYPAL
- (IBAction)onButtonPayWithPayPalClicked {
    [self.printOrder costWithCompletionHandler:^(OLPrintOrderCost *cost, NSError *error) {
        // Create a PayPalPayment
        PayPalPayment *payment = [[PayPalPayment alloc] init];
        payment.amount = [cost totalCostInCurrency:self.printOrder.currencyCode];
        payment.currencyCode = self.printOrder.currencyCode;
        payment.shortDescription = self.printOrder.paymentDescription;
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
        if ([OLKitePrintSDK environment] == kOLKitePrintSDKEnvironmentSandbox) {
            paymentController = [[STPTestPaymentAuthorizationViewController alloc]
                                 initWithPaymentRequest:paymentRequest];
            ((STPTestPaymentAuthorizationViewController *)paymentController).delegate = self;
        }
        else{
            paymentController = [[PKPaymentAuthorizationViewController alloc]
                                 initWithPaymentRequest:paymentRequest];
            ((PKPaymentAuthorizationViewController *)paymentController).delegate = self;
        }
        [self presentViewController:paymentController animated:YES completion:nil];
    }];
}
#endif

- (void)submitOrderForPrintingWithProofOfPayment:(NSString *)proofOfPayment paymentMethod:(NSString *)paymentMethod completion:(void (^)(PKPaymentAuthorizationStatus)) handler{
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    self.printOrder.proofOfPayment = proofOfPayment;
    
    NSString *applePayAvailableStr = @"N/A";
#ifdef OL_KITE_OFFER_APPLE_PAY
    applePayAvailableStr = [self shouldShowApplePay] ? @"Yes" : @"No";
#endif
    
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackPaymentCompletedForOrder:self.printOrder paymentMethod:paymentMethod applePayIsAvailable:applePayAvailableStr];
#endif
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kOLNotificationUserCompletedPayment object:self userInfo:@{kOLKeyUserInfoPrintOrder: self.printOrder}];
    [self.printOrder saveToHistory];
    
    __block BOOL handlerUsed = NO;
    
    [SVProgressHUD showWithStatus:NSLocalizedStringFromTableInBundle(@"Processing", @"KitePrintSDK", [OLConstants bundle], @"") maskType:SVProgressHUDMaskTypeBlack];
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
        [SVProgressHUD showProgress:progress status:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Uploading Images \n%lu / %lu", @"KitePrintSDK", [OLConstants bundle], @""), (unsigned long) totalAssetsUploaded + 1 + totalURLAssets, (unsigned long) self.printOrder.totalAssetsToUpload] maskType:SVProgressHUDMaskTypeBlack];
    } completionHandler:^(NSString *orderIdReceipt, NSError *error) {
        if (error) {
            handler(PKPaymentAuthorizationStatusFailure);
            [[[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Oops!", @"KitePrintSDK", [OLConstants bundle], @"") message:error.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedStringFromTableInBundle(@"OK", @"KitePrintSDK", [OLConstants bundle], @"") otherButtonTitles:nil] show];
        }
        
        if (!handlerUsed) {
            handler(PKPaymentAuthorizationStatusSuccess);
            handlerUsed = YES;
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kOLNotificationPrintOrderSubmission object:self userInfo:@{kOLKeyUserInfoPrintOrder: self.printOrder}];
        
#ifndef OL_NO_ANALYTICS
        [OLAnalytics trackOrderSubmission:self.printOrder];
#endif
        
        [self.printOrder saveToHistory]; // save again as the print order has it's receipt set if it was successful, otherwise last error is set
        [SVProgressHUD dismiss];
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        self.transitionBlockOperation = [[NSBlockOperation alloc] init];
        __weak OLPaymentViewController *welf = self;
        [self.transitionBlockOperation addExecutionBlock:^{
            OLReceiptViewController *receiptVC = [[OLReceiptViewController alloc] initWithPrintOrder:welf.printOrder];
            receiptVC.delegate = welf.delegate;
            receiptVC.presentedModally = welf.presentedModally;
            receiptVC.delegate = welf.delegate;
            [welf.navigationController pushViewController:receiptVC animated:YES];
        }];
        if ([self shouldShowApplePay]){
            [self.transitionBlockOperation addDependency:self.applePayDismissOperation];
        }
        [[NSOperationQueue mainQueue] addOperation:self.transitionBlockOperation];
    }];
}

- (IBAction)onButtonMinusClicked:(UIButton *)sender {
    UIView* cellContentView = sender.superview;
    UIView* cell = cellContentView.superview;
    while (![cell isKindOfClass:[UITableViewCell class]]){
        cell = cell.superview;
    }
    NSIndexPath* indexPath = [self.tableView indexPathForCell:(UITableViewCell*)cell];
    OLProductPrintJob* printJob = ((OLProductPrintJob*)[self.printOrder.jobs objectAtIndex:indexPath.row]);
    
    if (printJob.extraCopies == 0){
        if ([UIAlertController class]){
            UIAlertController *ac = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Delete Item", @"") message:NSLocalizedString(@"Are you sure you want to delete this item?", @"") preferredStyle:UIAlertControllerStyleAlert];
            [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:NULL]];
            [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Yes", @"") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action){
                [self.printOrder removePrintJob:printJob];
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
                [self updateViewsBasedOnCostUpdate];
            }]];
            [self presentViewController:ac animated:YES completion:NULL];
        }
    }
    else{
        printJob.extraCopies--;
        
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        [self updateViewsBasedOnCostUpdate];
    }
}

- (IBAction)onButtonPlusClicked:(UIButton *)sender {
    UIView* cellContentView = sender.superview;
    UIView* cell = cellContentView.superview;
    while (![cell isKindOfClass:[UITableViewCell class]]){
        cell = cell.superview;
    }
    NSIndexPath* indexPath = [self.tableView indexPathForCell:(UITableViewCell*)cell];
    OLProductPrintJob* printJob = ((OLProductPrintJob*)[self.printOrder.jobs objectAtIndex:indexPath.row]);
    
    printJob.extraCopies += 1;
    
    if (indexPath){
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    }
    
    [self updateViewsBasedOnCostUpdate];
}

- (IBAction)onButtonEditClicked:(UIButton *)sender {
    
}

- (IBAction)onButtonContinueShoppingClicked:(UIButton *)sender {
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
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    [self textFieldShouldReturn:self.promoCodeTextField];
}


#pragma mark - PayPalPaymentDelegate methods

#ifdef OL_KITE_OFFER_PAYPAL
- (void)payPalPaymentDidCancel:(PayPalPaymentViewController *)paymentViewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)payPalPaymentViewController:(PayPalPaymentViewController *)paymentViewController didCompletePayment:(PayPalPayment *)completedPayment {
    [self dismissViewControllerAnimated:YES completion:nil];
    [self submitOrderForPrintingWithProofOfPayment:completedPayment.confirmation[@"response"][@"id"] paymentMethod:@"PayPal" completion:^void(PKPaymentAuthorizationStatus status){}];
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
        [[NSOperationQueue mainQueue] addOperation:self.applePayDismissOperation];
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
    
    if ([OLKitePrintSDK environment] == kOLKitePrintSDKEnvironmentSandbox){
        STPCard *card = [STPCard new];
        card.number = @"4242424242424242";
        card.expMonth = 12;
        card.expYear = 2020;
        card.cvc = @"123";
        [client createTokenWithCard:card completion:^(STPToken *token, NSError *error) {
            if (error) {
                completion(PKPaymentAuthorizationStatusFailure);
                return;
            }
            [self createBackendChargeWithToken:token completion:completion];
        }];
    }
    else{
        [client createTokenWithPayment:payment completion:^(STPToken *token, NSError *error) {
            if (error) {
                completion(PKPaymentAuthorizationStatusFailure);
                return;
            }
            [self createBackendChargeWithToken:token completion:completion];
        }];
    }
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
            completion(PKPaymentAuthorizationStatusFailure, nil, nil);
        }
    }];
}

- (void)createBackendChargeWithToken:(STPToken *)token
                          completion:(void (^)(PKPaymentAuthorizationStatus))completion {
    [self submitOrderForPrintingWithProofOfPayment:token.tokenId paymentMethod:@"Apple Pay" completion:completion];
}

#endif

#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if ([self.delegate respondsToSelector:@selector(shouldShowContinueShoppingButton)] && [self.delegate shouldShowContinueShoppingButton]){
        return 2;
    }
    else{
        return 1;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0){
        return self.printOrder.jobs.count;
    }
    else{
        return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0){
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"jobCell"];
        UIImageView *imageView = (UIImageView *)[cell.contentView viewWithTag:20];
        UILabel *quantityLabel = (UILabel *)[cell.contentView viewWithTag:30];
        UILabel *productNameLabel = (UILabel *)[cell.contentView viewWithTag:50];
        UILabel *priceLabel = (UILabel *)[cell.contentView viewWithTag:70];
        
        id<OLPrintJob> job = self.printOrder.jobs[indexPath.row];
        OLProduct *product = [OLProduct productWithTemplateId:[job templateId]];
        
        [imageView setAndFadeInImageWithURL:product.productTemplate.coverPhotoURL];
        quantityLabel.text = [NSString stringWithFormat:@"%ld", (long)[job extraCopies]+1];
        productNameLabel.text = product.productTemplate.name;
        
        if ([self.printOrder hasCachedCost]){
            priceLabel.text = [[[product unitCostDecimalNumber] decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%ld", (long)[job extraCopies]+1]]]formatCostForCurrencyCode:self.printOrder.currencyCode];
        }
        else{
            priceLabel.text = nil;
        }
        
        return cell;
    }
    else{
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"continueCell"];
        
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 0){
        return 40;
    }
    else{
        return 45;
    }
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
