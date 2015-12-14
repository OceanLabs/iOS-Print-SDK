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

@interface OLCheckoutViewController (Private)

+ (BOOL)validateEmail:(NSString *)candidate;

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
@property (strong, nonatomic) NSString *tempPromoCode;
@property (assign, nonatomic) BOOL clearPromoCode;
@property (strong, nonatomic) UIButton *payWithCreditCardButton;
@property (strong, nonatomic) UILabel *kiteLabel;

@property (strong, nonatomic) NSBlockOperation *applePayDismissOperation;
@property (strong, nonatomic) NSBlockOperation *transitionBlockOperation;

#ifdef OL_KITE_OFFER_APPLE_PAY
@property (strong, nonatomic) UIButton *payWithApplePayButton;
@property (assign, nonatomic) BOOL applePayIsAvailable;
@property (strong, nonatomic) UIButton *moreOptionsButton;
#endif

@property (strong, nonatomic) UIView *loadingView;
@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) NSString *paymentCurrencyCode;
@property (strong, nonatomic) NSMutableArray* sections;

@property (strong, nonatomic) NSLayoutConstraint *kiteLabelYCon;
@property (strong, nonatomic) UIView *lowestView;

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
    
    return [Stripe canSubmitPaymentRequest:request] && !self.showOtherOptions;
#else
    return NO;
#endif
}

- (void)setupBannerImage:(UIImage *)bannerImage withBgImage:(UIImage *)bannerBgImage{
    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, bannerImage.size.height)];
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
    self.applePayIsAvailable = [self isApplePayAvailable];
    applePayAvailableStr = self.applePayIsAvailable ? @"Yes" : @"No";
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
    self.tableView.sectionHeaderHeight = 0;
    [self.view addSubview:self.tableView];
    
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
    
#ifdef OL_KITE_OFFER_APPLE_PAY
    CGFloat heightDiff = self.applePayIsAvailable ? 0 : 52;
#else
    CGFloat heightDiff = 52;
#endif
    
    if (![self isApplePayAvailable]){
        self.payWithCreditCardButton = [[UIButton alloc] initWithFrame:CGRectMake(20, 52 - heightDiff, self.view.frame.size.width - 40, 44)];
        self.payWithCreditCardButton.backgroundColor = [UIColor colorWithRed:55 / 255.0f green:188 / 255.0f blue:155 / 255.0f alpha:1.0];
        [self.payWithCreditCardButton addTarget:self action:@selector(onButtonPayWithCreditCardClicked) forControlEvents:UIControlEventTouchUpInside];
        [self.payWithCreditCardButton setTitle:NSLocalizedStringFromTableInBundle(@"Credit Card", @"KitePrintSDK", [OLConstants bundle], @"") forState:UIControlStateNormal];
        [self.payWithCreditCardButton makeRoundRect];
        
        self.lowestView = self.payWithCreditCardButton;
    }
    
    
#ifdef OL_KITE_OFFER_PAYPAL
    if ([OLKiteABTesting sharedInstance].offerPayPal && ![self isApplePayAvailable]){
        self.payWithPayPalButton = [[UIButton alloc] initWithFrame:CGRectMake(20, 104 - heightDiff, self.view.frame.size.width - 40, 44)];
        [self.payWithPayPalButton setTitle:NSLocalizedStringFromTableInBundle(@"PayPal", @"KitePrintSDK", [OLConstants bundle], @"") forState:UIControlStateNormal];
        [self.payWithPayPalButton addTarget:self action:@selector(onButtonPayWithPayPalClicked) forControlEvents:UIControlEventTouchUpInside];
        [self.payWithPayPalButton makeRoundRect];
        self.payWithPayPalButton.backgroundColor = [UIColor colorWithRed:74 / 255.0f green:137 / 255.0f blue:220 / 255.0f alpha:1.0];
        [self.payWithPayPalButton makeRoundRect];
        self.lowestView = self.payWithPayPalButton;
    }
#endif
    
#ifdef OL_KITE_OFFER_APPLE_PAY
    self.payWithApplePayButton = [[UIButton alloc] initWithFrame:CGRectMake(20, 0, self.view.frame.size.width-40, 44)];
    self.payWithApplePayButton.backgroundColor = [UIColor blackColor];
    [self.payWithApplePayButton makeRoundRect];
    [self.payWithApplePayButton setImage:[UIImage imageNamedInKiteBundle:@"button_apple_pay"] forState:UIControlStateNormal];
    [self.payWithApplePayButton addTarget:self action:@selector(onButtonPayWithApplePayClicked) forControlEvents:UIControlEventTouchUpInside];
    
    self.moreOptionsButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 84, self.view.frame.size.width, 20)];
    [self.moreOptionsButton setTitleColor:[UIColor colorWithRed: 0 green: 0.529 blue: 1 alpha: 1] forState:UIControlStateNormal];
    [self.moreOptionsButton setTitle:NSLocalizedString(@"More payment options", @"") forState:UIControlStateNormal];
    self.moreOptionsButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.moreOptionsButton.titleLabel setFont:[UIFont systemFontOfSize:13]];
    [self.moreOptionsButton addTarget:self action:@selector(onButtonMoreOptionsClicked) forControlEvents:UIControlEventTouchUpInside];
    
    if (!self.lowestView){
        self.lowestView = self.moreOptionsButton;
    }
#endif
    
    self.kiteLabel = [[UILabel alloc] init];
    self.kiteLabel.text = NSLocalizedString(@"Powered by Kite.ly", @"");
    self.kiteLabel.font = [UIFont systemFontOfSize:13];
    self.kiteLabel.textColor = [UIColor lightGrayColor];
    
    UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, CGRectGetMaxY(self.lowestView.frame)+30)];
    if (self.payWithCreditCardButton){
        [footer addSubview:self.payWithCreditCardButton];
    }
    [footer addSubview:self.kiteLabel];
    
    self.kiteLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    [footer addConstraint:[NSLayoutConstraint constraintWithItem:self.kiteLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:footer attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    
#ifdef OL_KITE_OFFER_PAYPAL
    if ([OLKiteABTesting sharedInstance].offerPayPal && ![self isApplePayAvailable]){
        [footer addSubview:self.payWithPayPalButton];
        self.lowestView = self.payWithPayPalButton;
    }
#endif
    
#ifdef OL_KITE_OFFER_APPLE_PAY
    if (self.applePayIsAvailable){
        [footer addSubview:self.payWithApplePayButton];
        [footer addSubview:self.moreOptionsButton];
        UIView *view = self.payWithApplePayButton;
        UIView *moreOptionsButton = self.moreOptionsButton;
        view.translatesAutoresizingMaskIntoConstraints = NO;
        NSDictionary *views = NSDictionaryOfVariableBindings(view, moreOptionsButton);
        NSMutableArray *con = [[NSMutableArray alloc] init];
        
        NSArray *visuals = @[@"H:|-20-[view]-20-|", @"V:|-0-[view(44)]-20-[moreOptionsButton]", @"H:|-0-[moreOptionsButton]-0-|"];
        
        for (NSString *visual in visuals) {
            [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
        }
        
        [view.superview addConstraints:con];
    }
#endif
    
    if (self.payWithCreditCardButton){
        UIView *view = self.payWithCreditCardButton;
        view.translatesAutoresizingMaskIntoConstraints = NO;
        NSDictionary *views = NSDictionaryOfVariableBindings(view);
        NSMutableArray *con = [[NSMutableArray alloc] init];
        
        NSString *v = [NSString stringWithFormat:@"V:|-%f-[view(44)]", 52 - heightDiff];
        NSArray *visuals = @[@"H:|-20-[view]-20-|", v];
        
        
        for (NSString *visual in visuals) {
            [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
        }
        
        [view.superview addConstraints:con];
    }
    
#ifdef OL_KITE_OFFER_PAYPAL
    if ([OLKiteABTesting sharedInstance].offerPayPal && ![self isApplePayAvailable]){
        UIView *view = self.payWithPayPalButton;
        view.translatesAutoresizingMaskIntoConstraints = NO;
        NSDictionary *views = NSDictionaryOfVariableBindings(view);
        NSMutableArray *con = [[NSMutableArray alloc] init];
        
        NSString *v = [NSString stringWithFormat:@"V:|-%f-[view(44)]", 104 - heightDiff];
        NSArray *visuals = @[@"H:|-20-[view]-20-|", v];
        
        for (NSString *visual in visuals) {
            [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
        }
        
        [view.superview addConstraints:con];
    }
#endif
    
    self.tableView.tableFooterView = footer;
    
    [self updateViewsBasedOnPromoCodeChange]; // initialise based on promo state
    
    self.loadingView = [[UIView alloc] initWithFrame:self.view.frame];
    self.loadingView.backgroundColor = [UIColor colorWithRed:239 / 255.0 green:239 / 255.0 blue:244 / 255.0 alpha:1];
    UIActivityIndicatorView *ai = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    CGRect f = self.loadingView.frame;
    ai.center = CGPointMake(f.size.width / 2, f.size.height / 2);
    [ai startAnimating];
    UILabel *loadingLabel = [[UILabel alloc] init];
    loadingLabel.text = @"Loading";
    loadingLabel.textColor = [UIColor colorWithRed:128 / 255.0 green:128 / 255.0 blue:128 / 255.0 alpha:1];
    [loadingLabel sizeToFit];
    loadingLabel.textAlignment = NSTextAlignmentCenter;
    loadingLabel.frame = CGRectMake((f.size.width - loadingLabel.frame.size.width) / 2, CGRectGetMaxY(ai.frame) + 10, loadingLabel.frame.size.width, loadingLabel.frame.size.height);
    
    [self.loadingView addSubview:ai];
    [self.loadingView addSubview:loadingLabel];
    [self.view addSubview:self.loadingView];
    
    ai.translatesAutoresizingMaskIntoConstraints = NO;
    [self.loadingView addConstraints:@[[NSLayoutConstraint constraintWithItem:ai attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:ai.superview attribute:NSLayoutAttributeCenterY multiplier:1 constant:0],[NSLayoutConstraint constraintWithItem:ai attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:ai.superview attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]]];
    
    UIView *view = self.loadingView;
    
    view.translatesAutoresizingMaskIntoConstraints = NO;
    NSDictionary *views = NSDictionaryOfVariableBindings(view);
    NSMutableArray *con = [[NSMutableArray alloc] init];
    
    NSArray *visuals = @[@"H:|-0-[view]-0-|",
                         @"V:|-0-[view]-0-|"];
    
    
    for (NSString *visual in visuals) {
        [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
    }
    
    [view.superview addConstraints:con];
    
    view = loadingLabel;
    
    view.translatesAutoresizingMaskIntoConstraints = NO;
    views = NSDictionaryOfVariableBindings(view, ai);
    con = [[NSMutableArray alloc] init];
    
    visuals = @[@"H:|-0-[view]-0-|",
                @"V:[ai]-0-[view]"];
    
    
    for (NSString *visual in visuals) {
        [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
    }
    
    [view.superview addConstraints:con];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    UITapGestureRecognizer *tgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onBackgroundClicked)];
    tgr.cancelsTouchesInView = NO; // allow table cell selection to happen as normal
    [self.tableView addGestureRecognizer:tgr];
    
    if ([self.tableView respondsToSelector:@selector(setCellLayoutMarginsFollowReadableWidth:)]){
        self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    }
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    
#ifndef OL_NO_ANALYTICS
    if (!self.navigationController){
        [OLAnalytics trackPaymentScreenHitBackForOrder:self.printOrder applePayIsAvailable:[self isApplePayAvailable] ? @"Yes" : @"No"];
    }
#endif
}

- (void)onButtonMoreOptionsClicked{
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackPaymentScreenHitCheckoutForOrder:self.printOrder];
#endif
    OLCheckoutViewController *vc = [[OLCheckoutViewController alloc] initWithPrintOrder:self.printOrder];
    vc.delegate = self.delegate;
    vc.showOtherOptions = YES;
    [vc safePerformSelector:@selector(setUserEmail:) withObject:self.userEmail];
    [vc safePerformSelector:@selector(setUserPhone:) withObject:self.userPhone];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    BOOL keyboardIsVisible = [self.promoTextField isFirstResponder];
    self.tempPromoCode = self.promoTextField.text;
    [self.promoTextField resignFirstResponder];
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinator> context){
        [self positionKiteLabel];
    } completion:^(id context){
        [self.tableView reloadData];
        if (keyboardIsVisible){
            [self.promoTextField becomeFirstResponder];
        }
    }];
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
        self.loadingView.hidden = YES;
        [self.tableView reloadData];
        [self updateViewsBasedOnPromoCodeChange];
    } else {
        self.loadingView.hidden = NO;
        [self.printOrder costWithCompletionHandler:^(OLPrintOrderCost *cost, NSError *error) {
            [self costCalculationCompletedWithError:error];
        }];
    }
    
    [self positionKiteLabel];
    
    if ([self isApplePayAvailable]){
        [self.printOrder discardDuplicateJobs];
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
        [self updateViewsBasedOnPromoCodeChange];
        [UIView animateWithDuration:0.15 animations:^{
            self.loadingView.alpha = 0;
        } completion:^(BOOL finished) {
            self.loadingView.hidden = YES;
        }];
    }
}

- (void)positionKiteLabel {
    [self.kiteLabel.superview removeConstraint:self.kiteLabelYCon];
    
    CGSize size = self.view.frame.size;
    CGFloat navBarHeight = [[UIApplication sharedApplication] statusBarFrame].size.height + self.navigationController.navigationBar.frame.size.height;
    CGFloat blankSpace = MAX(size.height - self.tableView.contentSize.height - navBarHeight + 5, 10);
    
    self.kiteLabelYCon = [NSLayoutConstraint constraintWithItem:self.kiteLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.lowestView attribute:NSLayoutAttributeBottom multiplier:1 constant:blankSpace];
    [self.kiteLabel.superview addConstraint:self.kiteLabelYCon];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)updateViewsBasedOnPromoCodeChange {
    if (![self.printOrder hasCachedCost]) {
        return;
    }
    
    [self.printOrder costWithCompletionHandler:^(OLPrintOrderCost *cost, NSError *error) {
        // impossible for an error to exist as we checked for cachedcost path above...
        NSAssert(error == nil, @"Print order did not actually have a cached cost...");
        NSComparisonResult result = [[cost totalCostInCurrency:self.printOrder.currencyCode] compare:[NSDecimalNumber zero]];
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
            [self.payWithCreditCardButton setTitle:NSLocalizedStringFromTableInBundle(@"Credit Card", @"KitePrintSDK", [OLConstants bundle], @"") forState:UIControlStateNormal];
        }
        
        [self.tableView reloadData];
        
    }];
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
            
            [self updateViewsBasedOnPromoCodeChange];
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
            NSString *rejectMessage = [self.delegate performSelector:@selector(shouldAcceptPromoCode:) withObject:self.promoTextField.text];
            if (rejectMessage) {
                [[[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Oops", @"KitePrintSDK", [OLConstants bundle], @"") message:rejectMessage delegate:nil cancelButtonTitle:NSLocalizedStringFromTableInBundle(@"OK", @"KitePrintSDK", [OLConstants bundle], @"") otherButtonTitles:nil] show];
                
                self.printOrder.promoCode = nil;
                [self updateViewsBasedOnPromoCodeChange];
                return;
            }
        }
#pragma clang diagnostic pop
        
        NSString *promoCode = [self.promoTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
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
                    ac.popoverPresentationController.sourceView = self.payWithCreditCardButton;
                    ac.popoverPresentationController.sourceRect = self.payWithCreditCardButton.frame;
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
    applePayAvailableStr = self.applePayIsAvailable ? @"Yes" : @"No";
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
        [SVProgressHUD showProgress:progress status:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Uploading Images \n%lu / %lu", @"KitePrintSDK", [OLConstants bundle], @""), (unsigned long) totalAssetsUploaded + 1 + totalURLAssets, (unsigned long) self.printOrder.totalAssetsToUpload]];
    } completionHandler:^(NSString *orderIdReceipt, NSError *error) {
        [self.printOrder saveToHistory]; // save again as the print order has it's receipt set if it was successful, otherwise last error is set
        
        self.transitionBlockOperation = [[NSBlockOperation alloc] init];
        __weak OLPaymentViewController *welf = self;
        [self.transitionBlockOperation addExecutionBlock:^{
            OLReceiptViewController *receiptVC = [[OLReceiptViewController alloc] initWithPrintOrder:welf.printOrder];
            receiptVC.delegate = welf.delegate;
            receiptVC.presentedModally = welf.presentedModally;
            receiptVC.delegate = welf.delegate;
            if (!welf.presentedViewController) {
                [welf.navigationController pushViewController:receiptVC animated:YES];
            }
        }];
        if ([self isApplePayAvailable]){
            [self.transitionBlockOperation addDependency:self.applePayDismissOperation];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kOLNotificationPrintOrderSubmission object:self userInfo:@{kOLKeyUserInfoPrintOrder: self.printOrder}];
        
        [SVProgressHUD dismiss];
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        
        if (error) {
            if (!handlerUsed) {
                handler(PKPaymentAuthorizationStatusFailure);
                handlerUsed = YES;
            }
            if ([UIAlertController class]){
                UIAlertController *ac = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTableInBundle(@"Oops!", @"KitePrintSDK", [OLConstants bundle], @"") message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
                [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"OK", @"KitePrintSDK", [OLConstants bundle], @"") style:UIAlertActionStyleDefault handler:^(id action){
                    [[NSOperationQueue mainQueue] addOperation:self.transitionBlockOperation];
                }]];
                [self presentViewController:ac animated:YES completion:NULL];
            }
            else{
                UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Oops!", @"KitePrintSDK", [OLConstants bundle], @"") message:error.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedStringFromTableInBundle(@"OK", @"KitePrintSDK", [OLConstants bundle], @"") otherButtonTitles:nil];
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
        [self.printOrder costWithCompletionHandler:^(id cost, NSError *error){
            if (!self.applePayDismissOperation.finished){
                [[NSOperationQueue mainQueue] addOperation:self.applePayDismissOperation];
            }
            if (error){
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
            self.printOrder.shippingAddress = nil;
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
    return [self.sections count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSString* sectionString = [self.sections objectAtIndex:section];
    if ([sectionString isEqualToString:kSectionOrderSummary]) {
        __block NSUInteger count = 0;
        [self.printOrder costWithCompletionHandler:^(OLPrintOrderCost *cost, NSError *error) {
            // this will actually do the right thing. Either this will callback immediately because printOrder
            // has cached costs and the count will be updated before below conditionals are hit or it will make an async request and count will remain 0 for below.
            count = cost.lineItems.count;
        }];
        if (count <= 1) {
            return count;
        } else {
            return count + 1; // additional cell to show total
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
            return NSLocalizedStringFromTableInBundle(@"Payment Options (TEST)", @"KitePrintSDK", [OLConstants bundle], @"");
        } else {
            return NSLocalizedStringFromTableInBundle(@"Payment Options", @"KitePrintSDK", [OLConstants bundle], @"");
        }
    } else if ([sectionString isEqualToString:kSectionOrderSummary]) {
        return NSLocalizedStringFromTableInBundle(@"Order Summary", @"KitePrintSDK", [OLConstants bundle], @"");
    } else if ([sectionString isEqualToString:kSectionPromoCodes]) {
        return @"";
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
        
        [self.printOrder costWithCompletionHandler:^(OLPrintOrderCost *orderCost, NSError *error) {
            NSArray *lineItems = orderCost.lineItems;
            NSDecimalNumber *totalCost = [orderCost totalCostInCurrency:self.printOrder.currencyCode];
            
            BOOL total = indexPath.row >= lineItems.count;
            NSDecimalNumber *cost;
            NSString *currencyCode = self.printOrder.currencyCode;
            if (total) {
                cell.textLabel.text = NSLocalizedStringFromTableInBundle(@"Total", @"KitePrintSDK", [OLConstants bundle], @"");
                cell.textLabel.font = [UIFont boldSystemFontOfSize:cell.textLabel.font.pointSize];
                cell.detailTextLabel.font = [UIFont boldSystemFontOfSize:cell.detailTextLabel.font.pointSize];
                
                cost = totalCost;
                
                NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
                [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
                [formatter setCurrencyCode:currencyCode];
                cell.detailTextLabel.text = [formatter stringFromNumber:totalCost];
            }
            else{
                OLPaymentLineItem *item = lineItems[indexPath.row];
                cell.textLabel.text = item.description;
                cell.textLabel.font = [UIFont systemFontOfSize:cell.textLabel.font.pointSize];
                cell.detailTextLabel.font = [UIFont systemFontOfSize:cell.detailTextLabel.font.pointSize];
                cell.detailTextLabel.text = [item costStringInCurrency:self.printOrder.currencyCode];
            }
        }];
        
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
        
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8){
            UIView *view = continueShoppingButton;
            view.translatesAutoresizingMaskIntoConstraints = NO;
            NSDictionary *views = NSDictionaryOfVariableBindings(view);
            NSMutableArray *con = [[NSMutableArray alloc] init];
            
            NSArray *visuals = @[@"H:|-0-[view]-0-|",
                                 @"V:|-0-[view]-0-|"];
            
            
            for (NSString *visual in visuals) {
                [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
            }
            
            [view.superview addConstraints:con];
        }
        
        
    } else if ([sectionString isEqualToString:kSectionPromoCodes]) {
        static NSString *const CellIdentifier = @"PromoCodeCell";
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            cell.frame = CGRectMake(0, 0, tableView.frame.size.width, 43);
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            UITextField *promoCodeTextField = [[UITextField alloc] initWithFrame:CGRectMake(20, 0, self.view.frame.size.width - 20 - 60, 43)];
            promoCodeTextField.placeholder = NSLocalizedStringFromTableInBundle(@"Promo Code", @"KitePrintSDK", [OLConstants bundle], @"");
            promoCodeTextField.delegate = self;
            promoCodeTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
            promoCodeTextField.autocorrectionType = UITextAutocorrectionTypeNo;
            promoCodeTextField.spellCheckingType = UITextSpellCheckingTypeNo;
            
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
            
            if ([[[UIDevice currentDevice] systemVersion] floatValue] >=8){
                UIView *view = promoCodeTextField;
                view.translatesAutoresizingMaskIntoConstraints = NO;
                NSDictionary *views = NSDictionaryOfVariableBindings(view);
                NSMutableArray *con = [[NSMutableArray alloc] init];
                
                NSArray *visuals = @[@"H:|-20-[view]-60-|", @"V:[view(43)]"];
                
                
                for (NSString *visual in visuals) {
                    [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
                }
                
                [view.superview addConstraints:con];
                
                NSLayoutConstraint *centerY = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:view.superview attribute:NSLayoutAttributeCenterY multiplier:1 constant:0];
                [con addObject:centerY];
                
                view = applyButton;
                view.translatesAutoresizingMaskIntoConstraints = NO;
                views = NSDictionaryOfVariableBindings(view);
                con = [[NSMutableArray alloc] init];
                
                visuals = @[@"H:[view(60)]-0-|"];
                
                
                for (NSString *visual in visuals) {
                    [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
                }
                
                NSLayoutConstraint *buttonCenterY = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:view.superview attribute:NSLayoutAttributeCenterY multiplier:1 constant:0];
                [con addObject:buttonCenterY];
                
                [view.superview addConstraints:con];
            }
            
            self.promoTextField = promoCodeTextField;
            self.promoApplyButton = applyButton;
        }
        
        if (self.printOrder.promoCode) {
            self.promoTextField.text = self.printOrder.promoCode;
            self.promoTextField.textColor = [UIColor lightGrayColor];
            self.promoTextField.enabled = NO;
            self.promoApplyButton.enabled = YES;
            [self.promoApplyButton setTitle:NSLocalizedStringFromTableInBundle(@"Clear", @"KitePrintSDK", [OLConstants bundle], @"") forState:UIControlStateNormal];
            [self.promoApplyButton sizeToFit];
            self.clearPromoCode = YES;
        } else {
            self.promoTextField.text = @"";
            self.promoTextField.textColor = [UIColor darkTextColor];
            self.promoTextField.enabled = YES;
            self.promoApplyButton.enabled = NO;
            [self.promoApplyButton setTitle:NSLocalizedStringFromTableInBundle(@"Apply", @"KitePrintSDK", [OLConstants bundle], @"") forState:UIControlStateNormal];
            [self.promoApplyButton sizeToFit];
            self.clearPromoCode = NO;
        }
        if (self.tempPromoCode){
            self.promoTextField.text = self.tempPromoCode;
            self.tempPromoCode = nil;
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
        if ([OLKitePrintSDK useStripeForCreditCards]){
            [self payWithExistingStripeCard:[OLStripeCard lastUsedCard]];
        } else if ([OLKitePrintSDK useJudoPayForGBP] && [self.printOrder.currencyCode isEqualToString:@"GBP"]) {
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
