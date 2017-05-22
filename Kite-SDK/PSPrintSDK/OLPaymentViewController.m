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

#import "NSDecimalNumber+CostFormatter.h"
#import "NSObject+Utils.h"
#import "OLAddress+AddressBook.h"
#import "OLAnalytics.h"
#import "OLAsset+Private.h"
#import "OLBaseRequest.h"
#import "OLCheckoutViewController.h"
#import "OLConstants.h"
#import "OLCountry.h"
#import "OLCreditCardCaptureViewController.h"
#import "OLFrameOrderReviewViewController.h"
#import "OLImageDownloader.h"
#import "OLImagePickerViewController.h"
#import "OLKiteABTesting.h"
#import "OLKitePrintSDK.h"
#import "OLKiteUtils.h"
#import "OLKiteViewController.h"
#import "OLPackProductViewController.h"
#import "OLPaymentLineItem.h"
#import "OLPaymentMethodsViewController.h"
#import "OLPaymentViewController.h"
#import "OLPayPalCard+OLCardIcon.h"
#import "OLPayPalCard.h"
#import "OLPayPalWrapper.h"
#import "OLPhotobookPrintJob.h"
#import "OLPhotobookViewController.h"
#import "OLPostcardPrintJob.h"
#import "OLPrintJob.h"
#import "OLPrintOrder+History.h"
#import "OLPrintOrder.h"
#import "OLPrintOrderCost.h"
#import "OLProductOverviewViewController.h"
#import "OLProductTemplate.h"
#import "OLProgressHUD.h"
#import "OLReceiptViewController.h"
#import "OLSingleProductReviewViewController.h"
#import "OLStripeCard+OLCardIcon.h"
#import "OLStripeWrapper.h"
#import "OLUserSession.h"
#import "UIImage+ImageNamedInKiteBundle.h"
#import "UIImage+OLUtils.h"
#import "UIImageView+FadeIn.h"
#import "UIView+RoundRect.h"
#import "UIViewController+OLMethods.h"
#import "Util.h"
#import "OLApparelPrintJob.h"
#import "OLCaseViewController.h"
#import "OLKiteViewController+Private.h"
#import "OLCollagePosterViewController.h"
#import "OLShippingMethodsViewController.h"

@import PassKit;
@import Contacts;

static NSString *const kSectionOrderSummary = @"kSectionOrderSummary";
static NSString *const kSectionPromoCodes = @"kSectionPromoCodes";
static NSString *const kSectionPayment = @"kSectionPayment";
static NSString *const kSectionContinueShopping = @"kSectionContinueShopping";

static OLPaymentMethod selectedPaymentMethod;

@interface OLProductTemplate ()
@property (nonatomic, strong) NSDictionary<NSString *, NSDecimalNumber *> *costsByCurrencyCode;
@end

@interface OLProduct (Private)
-(OLAsset *)classImageAsset;
@end

@interface OLProductPrintJob ()
@property (strong, nonatomic) NSMutableDictionary *options;
@property (strong, nonatomic) NSMutableSet <OLUpsellOffer *>*declinedOffers;
@property (strong, nonatomic) NSMutableSet <OLUpsellOffer *>*acceptedOffers;
@property (strong, nonatomic) OLUpsellOffer *redeemedOffer;
@end

@interface OLProduct (PrivateMethods)
- (NSDecimalNumber*) unitCostDecimalNumber;
@property (strong, nonatomic) NSMutableArray *declinedOffers;
@property (strong, nonatomic) NSMutableArray *acceptedOffers;
@property (strong, nonatomic) NSDictionary *redeemedOffer;
@end

@interface OLPackProductViewController ()
-(BOOL) shouldGoToCheckout;
@end

@interface OLCheckoutViewController (Private)
+ (BOOL)validateEmail:(NSString *)candidate;
- (void)onButtonDoneClicked;
@end

@interface OLCaseViewController ()
@property (strong, nonatomic) OLAsset *backAsset;
@end

@interface OLPrintOrderCost ()
@property (strong, nonatomic) NSDictionary *specialPromoDiscount;
@end

@interface OLKitePrintSDK (Private)
+ (BOOL)useStripeForCreditCards;

+ (NSString *_Nonnull)paypalEnvironment;
+ (NSString *_Nonnull)paypalClientId;

+ (NSString *_Nonnull)stripePublishableKey;
+ (NSString *_Nonnull)appleMerchantID;
+ (NSString *)applePayPayToString;

@end

@interface OLReceiptViewController (Private)
@property (nonatomic, assign) BOOL presentedModally;
@property (weak, nonatomic) id<OLCheckoutDelegate>_Nullable delegate;
@end

@interface OLPrintOrder (Private)
- (BOOL)hasCachedCost;
- (void)saveOrder;
@property (strong, nonatomic, readwrite) NSString *submitStatusErrorMessage;
@property (strong, nonatomic, readwrite) NSString *submitStatus;
@property (nonatomic, readwrite) NSString *receipt;
@property (strong, nonatomic) OLPrintOrderCost *finalCost;
@property (nonatomic, strong) OLPrintOrderCostRequest *costReq;
@property (strong, nonatomic) NSString *paymentMethod;
@end

@interface OLPaymentViewController () <
UITableViewDataSource, UITableViewDelegate,
PKPaymentAuthorizationViewControllerDelegate,
UIActionSheetDelegate, UITextFieldDelegate, UINavigationControllerDelegate, UITableViewDelegate, UIScrollViewDelegate, UIViewControllerPreviewingDelegate, OLPaymentMethodsViewControllerDelegate>

@property (strong, nonatomic) OLPrintOrder *printOrder;
@property (strong, nonatomic) OLPayPalCard *card;
@property (strong, nonatomic) NSBlockOperation *applePayDismissOperation;
@property (strong, nonatomic) NSBlockOperation *transitionBlockOperation;
@property (weak, nonatomic) IBOutlet UIButton *paymentButton1;
@property (weak, nonatomic) IBOutlet UIButton *paymentButton2;
@property (weak, nonatomic) IBOutlet UILabel *promoCodeCostLabel;
@property (weak, nonatomic) IBOutlet UILabel *shippingCostLabel;
@property (weak, nonatomic) IBOutlet UITextField *promoCodeTextField;
@property (weak, nonatomic) IBOutlet UILabel *shippingLabel;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *promoBoxBottomCon;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *promoBoxTopCon;
@property (weak, nonatomic) IBOutlet UIView *promoBox;
@property (weak, nonatomic) IBOutlet UILabel *poweredByKiteLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *poweredByKiteLabelBottomCon;
@property (weak, nonatomic) IBOutlet UIView *shippingDetailsBox;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *deliveryDetailsCon;
@property (weak, nonatomic) IBOutlet UILabel *deliveryDetailsLabel;
@property (weak, nonatomic) IBOutlet UIButton *shippingMethodChevron;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *totalCostActivityIndicator;
@property (assign, nonatomic) CGFloat keyboardAnimationPercent;
@property (assign, nonatomic) BOOL authorizedApplePay;
@property (assign, nonatomic) BOOL usedContinueShoppingButton;
@property (assign, nonatomic) CGRect originalPromoBoxFrame;
@property (nonatomic, assign) BOOL presentedModally;
@property (weak, nonatomic) IBOutlet UIButton *addPaymentMethodButton;
@property (weak, nonatomic) IBOutlet UIImageView *payingWithImageView;
@property (weak, nonatomic) IBOutlet UIView *addPaymentBox;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *paymentMethodBottomCon;
@property (strong, nonatomic) NSArray *currentUserSelectedPhotos;
@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *shippingMethodTapGesture;
@property (strong, nonatomic) NSOperation *viewDidAppearOperation;
@property (strong, nonatomic) NSOperation *costCalculationOperation;
@property (strong, nonatomic) NSOperation *reloadTableViewOperation;

@end


@implementation OLPaymentViewController

-(NSOperation *) viewDidAppearOperation{
    if (!_viewDidAppearOperation){
        _viewDidAppearOperation = [[NSOperation alloc] init];
    }
    return _viewDidAppearOperation;
}

-(NSOperation *) costCalculationOperation{
    if (!_costCalculationOperation){
        _costCalculationOperation = [[NSOperation alloc] init];
    }
    return _costCalculationOperation;
}

- (id)initWithPrintOrder:(OLPrintOrder *)printOrder {
    if ((self = [[UIStoryboard storyboardWithName:@"OLKiteStoryboard" bundle:[OLKiteUtils kiteResourcesBundle]] instantiateViewControllerWithIdentifier:@"OLPaymentViewController"])) {
        self.printOrder = printOrder;
    }
    
    return self;
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

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[OLKiteABTesting sharedInstance].backButtonText
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:nil
                                                                            action:nil];
    
    self.poweredByKiteLabel.text = NSLocalizedStringFromTableInBundle(@"Powered by Kite.ly", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"");
    [self.paymentButton1 setTitle:NSLocalizedStringFromTableInBundle(@"Continue Shopping", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") forState:UIControlStateNormal];
    
    self.reloadTableViewOperation = [NSBlockOperation blockOperationWithBlock:^{
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
    }];
    [self.reloadTableViewOperation addDependency:self.viewDidAppearOperation];
    [self.reloadTableViewOperation addDependency:self.costCalculationOperation];
    [[NSOperationQueue mainQueue] addOperation:self.reloadTableViewOperation];
    
    if (self.navigationController.viewControllers.firstObject == self){
        NSURL *cancelUrl = [NSURL URLWithString:[OLKiteABTesting sharedInstance].cancelButtonIconURL];
        if (cancelUrl && ![[OLImageDownloader sharedInstance] cachedDataExistForURL:cancelUrl]){
            [[OLImageDownloader sharedInstance] downloadImageAtURL:cancelUrl withCompletionHandler:^(UIImage *image, NSError *error){
                if (error) return;
                dispatch_async(dispatch_get_main_queue(), ^{
                   self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageWithCGImage:image.CGImage scale:2.0 orientation:UIImageOrientationUp] style:UIBarButtonItemStyleDone target:self action:@selector(dismiss)];
                });
            }];
        }
        else{
            self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Cancel", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
        }
    }
    
    [self sanitizeBasket];
    
    self.shippingCostLabel.text = @"";
    self.promoCodeCostLabel.text = @"";
    self.promoCodeTextField.placeholder = NSLocalizedStringFromTableInBundle(@"Promo Code", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"");
    self.promoCodeTextField.text = self.printOrder.promoCode;
    
    NSString *applePayAvailableStr;
    if ([OLKiteUtils isApplePayAvailable]){
        applePayAvailableStr = @"Yes";
    }
    else{
        applePayAvailableStr = @"No";
    }
    
    if ([OLKitePrintSDK environment] == OLKitePrintSDKEnvironmentSandbox){
        self.title = NSLocalizedStringFromTableInBundle(@"Payment (TEST)", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"");
    }
    else{
        self.title = NSLocalizedStringFromTableInBundle(@"Payment", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"");
    }
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    [self.paymentButton1 makeRoundRectWithRadius:2.0];
    [self.paymentButton2 makeRoundRectWithRadius:2.0];
    
    if ([self.traitCollection respondsToSelector:@selector(forceTouchCapability)] && self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable){
        [self registerForPreviewingWithDelegate:self sourceView:self.tableView];
    }
    
    
    if (![OLKiteUtils isApplePayAvailable]){
        self.deliveryDetailsCon.constant = 2;
        self.shippingDetailsBox.alpha = 1;
    }
    
    if ([OLUserSession currentSession].kiteVc.hideContinueShoppingButton || [OLKiteABTesting sharedInstance].launchedWithPrintOrder || self.navigationController.viewControllers.firstObject == self){
        [self.paymentButton1 removeFromSuperview];
    }
    
    if (selectedPaymentMethod == kOLPaymentMethodNone && [OLKiteUtils isApplePayAvailable]){
        selectedPaymentMethod = kOLPaymentMethodApplePay;
    }
    [self updateSelectedPaymentMethodView];
    
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
    [OLAnalytics trackBasketScreenViewedForOrder:self.printOrder applePayIsAvailable:applePayAvailableStr];
#endif
    
    if ([OLKiteABTesting sharedInstance].lightThemeColor1){
        [self.paymentButton1 setBackgroundColor:[UIColor clearColor]];
        [self.paymentButton1 setTitleColor:[OLKiteABTesting sharedInstance].lightThemeColor1 forState:UIControlStateNormal];
        self.paymentButton1.layer.cornerRadius = 2;
        self.paymentButton1.layer.borderColor = [OLKiteABTesting sharedInstance].lightThemeColor1.CGColor;
        self.paymentButton1.layer.borderWidth = 1;
        
        [self.paymentButton2 setBackgroundColor:[OLKiteABTesting sharedInstance].lightThemeColor1];
    }
    UIFont *font = [[OLKiteABTesting sharedInstance] lightThemeFont1WithSize:17];
    if (font){
        [self.paymentButton1.titleLabel setFont:font];
        [self.paymentButton2.titleLabel setFont:font];
    }
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    //Drop previous screens from the navigation stack
    NSMutableArray *navigationStack = self.navigationController.viewControllers.mutableCopy;
    if (navigationStack.count > 1) {
        NSMutableArray *viewControllers = [[NSMutableArray alloc] init];
        for (UIViewController *vc in self.navigationController.viewControllers){
            [viewControllers addObject:vc];
            if ([vc isKindOfClass:[OLKiteViewController class]]){
                [viewControllers addObject:self];
                [self.navigationController setViewControllers:viewControllers animated:YES];
                break;
            }
        }
        [self.navigationController setViewControllers:@[navigationStack.firstObject, self] animated:NO];
        [[OLUserSession currentSession] clearUserSelectedPhotos];
    }
    
    if ([OLUserSession currentSession].kiteVc.discardDeliveryAddresses){
        [OLAddress clearAddressBook];
    }
    
    if ([self isPushed]){
        if ([OLKitePrintSDK environment] == OLKitePrintSDKEnvironmentSandbox){
            self.parentViewController.title = NSLocalizedStringFromTableInBundle(@"Payment (TEST)", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"");
        }
        else{
            self.parentViewController.title = NSLocalizedStringFromTableInBundle(@"Payment", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"");
        }
    }
    
    if (!self.viewDidAppearOperation.finished){
        [[NSOperationQueue mainQueue] addOperation:self.viewDidAppearOperation];
    }
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    
    if (!self.navigationController){
#ifndef OL_NO_ANALYTICS
        if (!self.usedContinueShoppingButton){
            [OLAnalytics trackBasketScreenHitBackForOrder:self.printOrder applePayIsAvailable:[OLKiteUtils isApplePayAvailable] ? @"Yes" : @"No"];
        }
#endif
    }
}

- (BOOL)finishedLoading{
    return self.viewDidAppearOperation.finished && self.costCalculationOperation.finished;
}

- (void)dismiss{
    if (self.currentUserSelectedPhotos){
        [[OLAsset userSelectedAssets] removeAllObjects];
        for (OLAsset *asset in self.currentUserSelectedPhotos){
            [[OLAsset userSelectedAssets] addObject:asset];
        }
    }
    [self.navigationController.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
#ifndef OL_NO_ANALYTICS
    if (!self.usedContinueShoppingButton){
        [OLAnalytics trackBasketScreenHitBackForOrder:self.printOrder applePayIsAvailable:[OLKiteUtils isApplePayAvailable] ? @"Yes" : @"No"];
    }
#endif
}

- (void)onBackgroundClicked {
    [self textFieldShouldReturn:self.promoCodeTextField];
}

- (void)keyboardDidShow:(NSNotification *)notification {
    if (self.promoBoxTopCon.constant == 2){
        self.originalPromoBoxFrame = self.promoBox.frame;
    }
    NSDictionary *userInfo = [notification userInfo];
    NSInteger animationOptions = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    CGSize size = [[userInfo objectForKey: UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    CGFloat time = [[userInfo objectForKey: UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    CGFloat diff = size.height - (self.view.frame.size.height - (self.originalPromoBoxFrame.origin.y + self.promoBox.frame.size.height));
    
    if (diff <= 0){
        return;
    }
    
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
    if ([OLKiteUtils isPayPalAvailable]){
        [OLPayPalWrapper initializeWithClientIdsForEnvironments:@{[OLKitePrintSDK paypalEnvironment] : [OLKitePrintSDK paypalClientId]}];
        [OLPayPalWrapper preconnectWithEnvironment:[OLKitePrintSDK paypalEnvironment]];
    }
    
    if ([OLKiteUtils isApplePayAvailable]){
        [OLStripeWrapper setDefaultPublishableKey:[OLKitePrintSDK stripePublishableKey]];
    }
    
    if ([self.printOrder hasCachedCost] && !self.printOrder.costReq) {
        [self.tableView reloadData];
        [self updateViewsBasedOnCostUpdate];
    } else {
        if (self.printOrder.jobs.count > 0){
            [self.paymentButton2 setTitle:nil forState:UIControlStateNormal];
            [self.totalCostActivityIndicator startAnimating];
            [self.printOrder costWithCompletionHandler:^(OLPrintOrderCost *cost, NSError *error) {
                [self costCalculationCompletedWithError:error];
            }];
        }
    }
    
    NSString *deliveryDetailsTitle = NSLocalizedStringFromTableInBundle(@"Delivery Details", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"");
    NSMutableSet *addresses = [[NSMutableSet alloc] init];
    for (id<OLPrintJob> job in self.printOrder.jobs){
        if ([job address]){
            [addresses addObject:[job address]];
        }
    }
    if ([self.printOrder.shippingAddress isValidAddress]){
        deliveryDetailsTitle = [self.printOrder.shippingAddress descriptionWithoutRecipient];
    }
    self.deliveryDetailsLabel.text = deliveryDetailsTitle;
}

- (void)handleCostError:(NSError *)error{
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTableInBundle(@"Oops!", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
    if (error.code == kOLKiteSDKErrorCodeProductNotAvailableInRegion){
        [self setViewsToBlank];
        [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"OK", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Acknowledgent to an alert dialog.") style:UIAlertActionStyleDefault handler:NULL]];
    }
    else{
        [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"Cancel", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
            [self.navigationController popViewControllerAnimated:YES];
        }]];
        
        [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"Retry", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
            [self.printOrder costWithCompletionHandler:^(OLPrintOrderCost *cost, NSError *error){
                [self costCalculationCompletedWithError:error];
            }];
        }]];
    }
    [self presentViewController:ac animated:YES completion:NULL];
}

- (void)costCalculationCompletedWithError:(NSError *)error {
    if (!self.costCalculationOperation.finished){
        [[NSOperationQueue mainQueue] addOperation:self.costCalculationOperation];
    }
    
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

- (void)updateSelectedPaymentMethodView{
    if (selectedPaymentMethod == kOLPaymentMethodNone){
        [self.addPaymentMethodButton setTitle:NSLocalizedStringFromTableInBundle(@"Add Payment Method", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") forState:UIControlStateNormal];
        self.payingWithImageView.hidden = YES;
        self.deliveryDetailsCon.constant = 2;
        self.shippingDetailsBox.alpha = 1;
    }
    else if (selectedPaymentMethod == kOLPaymentMethodCreditCard){
        id existingCard = [OLKitePrintSDK useStripeForCreditCards] ? [OLStripeCard lastUsedCard] : [OLPayPalCard lastUsedCard];
        [self.addPaymentMethodButton setTitle:NSLocalizedStringFromTableInBundle(@"Paying With", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Paying with [PayPal/Credit Card]") forState:UIControlStateNormal];
        self.payingWithImageView.image = [existingCard cardIcon];
        self.payingWithImageView.hidden = NO;
        self.deliveryDetailsCon.constant = 2;
        self.shippingDetailsBox.alpha = 1;
    }
    else if (selectedPaymentMethod == kOLPaymentMethodApplePay){
        [self.addPaymentMethodButton setTitle:NSLocalizedStringFromTableInBundle(@"Paying With", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Paying with [PayPal/Credit Card]") forState:UIControlStateNormal];
        self.payingWithImageView.image = [UIImage imageNamedInKiteBundle:@"apple-pay-method"];
        self.payingWithImageView.hidden = NO;
        self.deliveryDetailsCon.constant = -50;
        self.shippingDetailsBox.alpha = 0;
    }
    else if (selectedPaymentMethod == kOLPaymentMethodPayPal){
        [self.addPaymentMethodButton setTitle:NSLocalizedStringFromTableInBundle(@"Paying With", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Paying with [PayPal/Credit Card]") forState:UIControlStateNormal];
        self.payingWithImageView.image = [UIImage imageNamedInKiteBundle:@"paypal-method"];
        self.payingWithImageView.hidden = NO;
        self.deliveryDetailsCon.constant = 2;
        self.shippingDetailsBox.alpha = 1;
    }
    
    [self.view layoutIfNeeded];
}

- (void)setViewsToBlank{
    [self.paymentButton2 setTitle:@"0.00" forState:UIControlStateNormal];
    self.shippingCostLabel.text = [[NSDecimalNumber decimalNumberWithString:@"0.00"] formatCostForCurrencyCode:[[OLCountry countryForCurrentLocale] currencyCode]];
    self.promoCodeCostLabel.text = @"";
    [self.tableView reloadData];
}

- (void)updateViewsBasedOnCostUpdate {
    if (self.printOrder.jobs.count == 0 ){
        [self setViewsToBlank];
        return;
    }
    
    BOOL shouldAnimate = NO;
    if (!self.printOrder.hasCachedCost || self.totalCostActivityIndicator.isAnimating){
        [self.paymentButton2 setTitle:nil forState:UIControlStateNormal];
        [self.totalCostActivityIndicator startAnimating];
        shouldAnimate = YES;
    }
    
    [self.printOrder costWithCompletionHandler:^(OLPrintOrderCost *cost, NSError *error) {
        [self.totalCostActivityIndicator stopAnimating];
        
        //Small chance that the request started before we emptied the basket.
        if (self.printOrder.jobs.count == 0){
            [self.totalCostActivityIndicator stopAnimating];
            [self.paymentButton2 setTitle:@"0.00" forState:UIControlStateNormal];
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
        if (![OLKiteABTesting sharedInstance].theme.kioskRequirePromoCode && (result == NSOrderedAscending || result == NSOrderedSame)) {
            [self.paymentButton2 setTitle:NSLocalizedStringFromTableInBundle(@"Checkout for Free!", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") forState:UIControlStateNormal];
            
            self.paymentMethodBottomCon.constant = 2 - self.addPaymentBox.frame.size.height;
            self.deliveryDetailsCon.constant = 2;
            self.shippingDetailsBox.alpha = 1;
            [UIView animateWithDuration:0.25 animations:^{
                [self.view layoutIfNeeded];
            } completion:^(BOOL finished){}];
        }
        else {
            [self.paymentButton2 setTitle:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Pay %@", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Pay [$10.00]"), [[cost totalCostInCurrency:self.printOrder.currencyCode] formatCostForCurrencyCode:self.printOrder.currencyCode]] forState:UIControlStateNormal];
            
            self.paymentMethodBottomCon.constant = 2;
            if (selectedPaymentMethod == kOLPaymentMethodApplePay){
                self.deliveryDetailsCon.constant = -50;
                self.shippingDetailsBox.alpha = 0;
            }
            else{
                self.deliveryDetailsCon.constant = 2;
                self.shippingDetailsBox.alpha = 1;
            }
            [UIView animateWithDuration:0.25 animations:^{
                [self.view layoutIfNeeded];
            } completion:^(BOOL finished){}];
        }
        
        if ([self.tableView numberOfRowsInSection:0] != self.printOrder.jobs.count){
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
        }
        
        NSString *shippingCostString;
        NSDecimalNumber *shippingCost = [cost shippingCostInCurrency:self.printOrder.currencyCode];
        if ([shippingCost isEqualToNumber:@0]){
            shippingCostString = NSLocalizedStringFromTableInBundle(@"FREE", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Free, no cost");
        }
        else{
            shippingCostString = [shippingCost formatCostForCurrencyCode:self.printOrder.currencyCode];
        }
        
        [UIView animateWithDuration:shouldAnimate ? 0.1 : 0 animations:^{
            if (shouldAnimate){
                if (![self.shippingCostLabel.text isEqualToString:shippingCostString]){
                    self.shippingCostLabel.alpha = 0;
                }
                self.totalCostActivityIndicator.alpha = 0;
            }
        } completion:^(BOOL finished){
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
            }];
        }];
        [self.tableView reloadData];
    }];
}

- (void(^)())transistionToReceiptBlock{
    __weak OLPaymentViewController *welf = self;
    return ^{
        [[OLUserSession currentSession] clearUserSelectedPhotos];
        if ([welf.delegate respondsToSelector:@selector(shouldDismissPaymentViewControllerAfterPayment)] && self.delegate.shouldDismissPaymentViewControllerAfterPayment){
            [(UITableView *)[(OLReceiptViewController *)welf.delegate tableView] reloadData];
            [welf.navigationController.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
            return ;
        }
        OLReceiptViewController *receiptVC = [[OLUserSession currentSession].kiteVc receiptViewControllerForPrintOrder:welf.printOrder];
        receiptVC.delegate = welf.delegate;
        receiptVC.presentedModally = welf.presentedModally;
        receiptVC.delegate = welf.delegate;
        if (!welf.presentedViewController) {
            [welf.navigationController pushViewController:receiptVC animated:YES];
            
            [OLUserSession currentSession].printOrder = [[OLPrintOrder alloc] init];
            [[OLUserSession currentSession].printOrder saveOrder];
        }
    };
}

- (void)submitOrderForPrintingWithProofOfPayment:(NSString *)proofOfPayment paymentMethod:(NSString *)paymentMethod completion:(void (^)(PKPaymentAuthorizationStatus)) handler{
    [self.printOrder cancelSubmissionOrPreemptedAssetUpload];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    self.printOrder.proofOfPayment = proofOfPayment;
    
    NSString *applePayAvailableStr = @"N/A";
    applePayAvailableStr = [OLKiteUtils isApplePayAvailable] ? @"Yes" : @"No";
    
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackPaymentCompletedForOrder:self.printOrder paymentMethod:paymentMethod applePayIsAvailable:applePayAvailableStr];
#endif
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kOLNotificationUserCompletedPayment object:self userInfo:@{kOLKeyUserInfoPrintOrder: self.printOrder}];
    [self.printOrder saveToHistory];
    
    __block BOOL handlerUsed = NO;
    
    [OLProgressHUD setDefaultMaskType:OLProgressHUDMaskTypeBlack];
    [OLProgressHUD showWithStatus:NSLocalizedStringFromTableInBundle(@"Processing", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Processing the order")];
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
        [OLProgressHUD setDefaultMaskType:OLProgressHUDMaskTypeBlack];
        if (progress < 1.0){
            NSString *status;
            if (self.printOrder.jobs.count == 1){
                OLProductTemplate *template = [OLProductTemplate templateWithId:[self.printOrder.jobs.firstObject templateId]];
                if (template){
                    if (template.templateUI == OLTemplateUIPhotobook && [OLKiteUtils assetArrayContainsPDF:[self.printOrder.jobs.firstObject assetsForUploading]]){
                        status = NSLocalizedStringFromTableInBundle(@"Uploading book", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"");
                    }
                }
                
            }
            if (!status){
                status = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Uploading Images \n%lu / %lu", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @""), (unsigned long) totalAssetsUploaded + 1 + totalURLAssets, (unsigned long) self.printOrder.totalAssetsToUpload];
            }
            [OLProgressHUD showProgress:progress status:status];
        }
        else{
            [OLProgressHUD showWithStatus:NSLocalizedStringFromTableInBundle(@"Processing", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Processing the order")];
        }
    } completionHandler:^(NSString *orderIdReceipt, NSError *error) {
        [self.printOrder saveToHistory]; // save again as the print order has it's receipt set if it was successful, otherwise last error is set
        
        self.transitionBlockOperation = [[NSBlockOperation alloc] init];
        [self.transitionBlockOperation addExecutionBlock:[self transistionToReceiptBlock]];
        if ([OLKiteUtils isApplePayAvailable] && self.applePayDismissOperation){
            [self.transitionBlockOperation addDependency:self.applePayDismissOperation];
        }
        
        [OLProgressHUD dismiss];
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        
        if (error) {
            [self.printOrder cancelSubmissionOrPreemptedAssetUpload];
            UIAlertController *ac = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTableInBundle(@"Oops!", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
            if (error.code == kOLKiteSDKErrorCodeImagesCorrupt){
                [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"View Item", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"View [basket] item") style:UIAlertActionStyleCancel handler:^(id action){
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
                [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"Not now", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") style:UIAlertActionStyleDefault handler:NULL]];
            }
            else{
                [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"OK", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Acknowledgent to an alert dialog.") style:UIAlertActionStyleDefault handler:^(id action){
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
                        [OLUserSession currentSession].printOrder = freshPrintOrder;
                        self.printOrder = freshPrintOrder;
                        [self.printOrder saveOrder];
                    }
                }]];
            }
            NSBlockOperation *presentAlertBlock = [NSBlockOperation blockOperationWithBlock:^{
                [self presentViewController:ac animated:YES completion:NULL];
            }];
            if ([OLKiteUtils isApplePayAvailable] && self.applePayDismissOperation){
                [presentAlertBlock addDependency:self.applePayDismissOperation];
            }
            [[NSOperationQueue mainQueue] addOperation:presentAlertBlock];
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

- (UINavigationController *)navViewControllerWithControllers:(NSArray *)vcs{
    OLNavigationController *navController = [[OLNavigationController alloc] init];
    
    navController.viewControllers = vcs;
    NSURL *cancelUrl = [NSURL URLWithString:[OLKiteABTesting sharedInstance].cancelButtonIconURL];
    if (cancelUrl && ![[OLImageDownloader sharedInstance] cachedDataExistForURL:cancelUrl]){
        [[OLImageDownloader sharedInstance] downloadImageAtURL:cancelUrl withCompletionHandler:^(UIImage *image, NSError *error){
            if (error) return;
            dispatch_async(dispatch_get_main_queue(), ^{
                ((UIViewController *)[vcs firstObject]).navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageWithCGImage:image.CGImage scale:2.0 orientation:UIImageOrientationUp] style:UIBarButtonItemStyleDone target:self action:@selector(dismissPresentedViewController)];
            });
        }];
    }
    else{
       ((UIViewController *)[vcs firstObject]).navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Cancel", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") style:UIBarButtonItemStylePlain target:self action:@selector(dismissPresentedViewController)];
    }
    
    return navController;
}

- (void)saveAndDismissReviewController{
    OLNavigationController *nvc = (OLNavigationController *)self.presentedViewController;
    if (![nvc isKindOfClass:[OLNavigationController class]]){
        return;
    }
    
    OLPackProductViewController *editingVc = nvc.viewControllers.lastObject;
    if ([editingVc respondsToSelector:@selector(saveJobWithCompletionHandler:)]){
        [editingVc saveJobWithCompletionHandler:^{
            [self.tableView reloadData];
            [self dismissPresentedViewController];
#ifndef OL_NO_ANALYTICS
            [OLAnalytics trackBasketScreenHitEditItemDone:nil inOrder:self.printOrder applePayIsAvailable:[OLKiteUtils isApplePayAvailable] ? @"Yes" : @"No"];
#endif
        }];
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
        [OLProgressHUD showWithStatus:NSLocalizedStringFromTableInBundle(@"Checking Code", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Checking promo code")];
    } else {
        if (!self.printOrder.promoCode || [self.printOrder.promoCode isEqualToString:@""]){
            return;
        }
        [OLProgressHUD showWithStatus:NSLocalizedStringFromTableInBundle(@"Clearing Code", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Clearing promo code")];
    }
    
    NSString *previousCode = self.printOrder.promoCode;
    self.printOrder.promoCode = promoCode;
    [self.printOrder costWithCompletionHandler:^(OLPrintOrderCost *cost, NSError *error) {
        if (error) {
#ifndef OL_NO_ANALYTICS
            [OLAnalytics trackBasketScreenUnsuccessfullyAppliedPromoCode:promoCode withError:error forOrder:self.printOrder];
#endif
            [OLProgressHUD dismiss];
            [self costCalculationCompletedWithError:error];
        } else {
            if (cost.promoCodeInvalidReason) {
#ifndef OL_NO_ANALYTICS
                [OLAnalytics trackBasketScreenUnsuccessfullyAppliedPromoCode:promoCode withError:[NSError errorWithDomain:@"ly.kite.sdk" code:0 userInfo:@{NSLocalizedDescriptionKey : cost.promoCodeInvalidReason}] forOrder:self.printOrder];
#endif
                self.printOrder.promoCode = previousCode; // reset print order promo code as it was invalid
                self.promoCodeTextField.text = previousCode;
                [OLProgressHUD dismiss];
                UIAlertController *ac = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTableInBundle(@"Oops!", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") message:cost.promoCodeInvalidReason preferredStyle:UIAlertControllerStyleAlert];
                [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"OK", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Acknowledgent to an alert dialog.") style:UIAlertActionStyleDefault handler:NULL]];
                [self presentViewController:ac animated:YES completion:NULL];
                
            } else {
                [self updateViewsBasedOnCostUpdate];
                if (self.printOrder.promoCode) {
#ifndef OL_NO_ANALYTICS
                    [OLAnalytics trackBasketScreenSuccessfullyAppliedPromoCode:self.printOrder.promoCode forOrder:self.printOrder];
#endif
                    sleep(1);
                    [OLProgressHUD showSuccessWithStatus:nil];
                } else {
                    [OLProgressHUD dismiss];
                }
            }
        }
    }];
}

#pragma mark Button Actions

- (IBAction)onButtonApplyPromoCodeClicked:(id)sender {
    if ([self.promoCodeTextField.text isEqualToString:@""]) {
        // Clear promo code
        [self applyPromoCode:nil];
    }
    else {
        NSString *promoCode = [self.promoCodeTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        [self applyPromoCode:promoCode];
    }
}

- (void)payWithExistingPayPalCard:(OLPayPalCard *)card {
    [OLProgressHUD setDefaultMaskType:OLProgressHUDMaskTypeBlack];
    [OLProgressHUD showWithStatus:NSLocalizedStringFromTableInBundle(@"Processing", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Processing the order")];
    [self.printOrder costWithCompletionHandler:^(OLPrintOrderCost *cost, NSError *error) {
        [card chargeCard:[cost totalCostInCurrency:self.printOrder.currencyCode] currencyCode:self.printOrder.currencyCode description:self.printOrder.paymentDescription completionHandler:^(NSString *proofOfPayment, NSError *error) {
            if (error) {
                [OLProgressHUD dismiss];
                    UIAlertController *ac = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTableInBundle(@"Oops!", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
                    [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"OK", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Acknowledgent to an alert dialog.") style:UIAlertActionStyleDefault handler:NULL]];
                    [self presentViewController:ac animated:YES completion:NULL];
                return;
            }
            
            [self submitOrderForPrintingWithProofOfPayment:proofOfPayment paymentMethod:@"Credit Card" completion:^void(PKPaymentAuthorizationStatus status){}];
            [card saveAsLastUsedCard];
        }];
    }];
}

- (void)payWithExistingStripeCard:(OLStripeCard *)card {
    [OLProgressHUD setDefaultMaskType:OLProgressHUDMaskTypeBlack];
    [OLProgressHUD showWithStatus:NSLocalizedStringFromTableInBundle(@"Processing", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Processing the order")];
    [self.printOrder costWithCompletionHandler:^(OLPrintOrderCost *cost, NSError *error) {
        [card chargeCard:[cost totalCostInCurrency:self.printOrder.currencyCode] currencyCode:self.printOrder.currencyCode description:self.printOrder.paymentDescription completionHandler:^(NSString *proofOfPayment, NSError *error) {
            if (error) {
                [OLProgressHUD dismiss];
                UIAlertController *ac = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTableInBundle(@"Oops!", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
                [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"OK", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Acknowledgent to an alert dialog.") style:UIAlertActionStyleDefault handler:NULL]];
                [self presentViewController:ac animated:YES completion:NULL];
                return;
            }
            
            [self submitOrderForPrintingWithProofOfPayment:proofOfPayment paymentMethod:@"Credit Card" completion:^void(PKPaymentAuthorizationStatus status){}];
            [card saveAsLastUsedCard];
        }];
    }];
}

- (void)payWithPayPal{
    if (![OLKiteUtils isPayPalAvailable]){
        return;
    }
    if (self.printOrder.jobs.count == 0){
        return;
    }
    
    self.printOrder.paymentMethod = @"PAYPAL";
    [self.printOrder costWithCompletionHandler:^(OLPrintOrderCost *cost, NSError *error) {
        if (!cost){
            [self updateViewsBasedOnCostUpdate];
            return;
        }
        
        // Create a PayPalPayment
        id paypalShippingAddress = [OLPayPalWrapper payPalShippingAddressWithRecipientName:[NSString stringWithFormat:@"%@ %@", self.printOrder.shippingAddress.recipientFirstName, self.printOrder.shippingAddress.recipientLastName] withLine1:self.printOrder.shippingAddress.line1 withLine2:self.printOrder.shippingAddress.line2 withCity:self.printOrder.shippingAddress.city withState:self.printOrder.shippingAddress.stateOrCounty withPostalCode:self.printOrder.shippingAddress.zipOrPostcode withCountryCode:self.printOrder.shippingAddress.country.codeAlpha2];
        id payment = [OLPayPalWrapper payPalPaymentWithAmount:[cost totalCostInCurrency:self.printOrder.currencyCode] currencyCode:self.printOrder.currencyCode shortDescription:self.printOrder.paymentDescription intent:1/*PayPalPaymentIntentAuthorize*/ shippingAddress:paypalShippingAddress];
        
        id payPalConfiguration = [OLPayPalWrapper payPalConfigurationWithShippingAddressOption:1/*PayPalShippingAddressOptionProvided*/ acceptCreditCards:NO];
        id paymentViewController = [OLPayPalWrapper payPalPaymentViewControllerWithPayment:payment configuration:payPalConfiguration delegate:self];
        ((UIViewController *)paymentViewController).modalPresentationStyle = [OLUserSession currentSession].kiteVc.modalPresentationStyle;
        
        if (paymentViewController){
            [self presentViewController:paymentViewController animated:YES completion:nil];
        }
    }];
}

+ (PKPaymentRequest *)paymentRequestWithMerchantIdentifier:(NSString *)merchantIdentifier {
    if (![PKPaymentRequest class]) {
        return nil;
    }
    PKPaymentRequest *paymentRequest = [PKPaymentRequest new];
    [paymentRequest setMerchantIdentifier:merchantIdentifier];
    [paymentRequest setSupportedNetworks:[OLKiteUtils supportedPKPaymentNetworks]];
    [paymentRequest setMerchantCapabilities:PKMerchantCapability3DS];
    [paymentRequest setCountryCode:@"US"];
    [paymentRequest setCurrencyCode:@"USD"];
    return paymentRequest;
}

- (void)payWithApplePay{
    self.applePayDismissOperation = [[NSBlockOperation alloc] init];
    
    self.printOrder.paymentMethod = @"APPLE_PAY";
    PKPaymentRequest *paymentRequest = [OLPaymentViewController paymentRequestWithMerchantIdentifier:[OLKitePrintSDK appleMerchantID]];
    paymentRequest.currencyCode = self.printOrder.currencyCode;
    [self.printOrder costWithCompletionHandler:^(OLPrintOrderCost *cost, NSError *error){
        if (!cost){
            [self updateViewsBasedOnCostUpdate];
            return;
        }
        
        NSMutableArray *lineItems = [[NSMutableArray alloc] init];
        for (OLPaymentLineItem *item in cost.lineItems){
            [lineItems addObject:[PKPaymentSummaryItem summaryItemWithLabel:item.description  amount:[item costInCurrency:self.printOrder.currencyCode]]];
        }
        
        // if a special discount exists, then first remove the normal discount and add a new discount line item
        if (cost.specialPromoDiscount){
            NSDecimalNumber *currencyDiscount = cost.specialPromoDiscount[self.printOrder.currencyCode];
            if ([currencyDiscount doubleValue] != 0) {
                if ([currencyDiscount doubleValue] > 0) {
                    currencyDiscount = [currencyDiscount decimalNumberByMultiplyingBy:(NSDecimalNumber *)[NSDecimalNumber numberWithInteger:-1]];
                }
                
                for (PKPaymentSummaryItem *item in lineItems){
                    if ([item.amount doubleValue] < 0){
                        [lineItems removeObject:item];
                    }
                }
                
                [lineItems addObject:[PKPaymentSummaryItem summaryItemWithLabel:NSLocalizedStringFromTableInBundle(@"Promotional Discount", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") amount:currencyDiscount]];
            }
        }
        
        [lineItems addObject:[PKPaymentSummaryItem summaryItemWithLabel:[OLKitePrintSDK applePayPayToString] amount:[cost totalCostInCurrency:self.printOrder.currencyCode]]];
        paymentRequest.paymentSummaryItems = lineItems;
        paymentRequest.requiredShippingAddressFields = PKAddressFieldPostalAddress | PKAddressFieldName | PKAddressFieldEmail | PKAddressFieldPhone;
        UIViewController *paymentController;
        paymentController = [[PKPaymentAuthorizationViewController alloc]
                             initWithPaymentRequest:paymentRequest];
        ((PKPaymentAuthorizationViewController *)paymentController).delegate = self;
        [self presentViewController:paymentController animated:YES completion:nil];
    }];
}

- (IBAction)onButtonMinusClicked:(UIButton *)sender {
    CGPoint buttonPosition = [sender.superview convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
    OLProductPrintJob* printJob = ((OLProductPrintJob*)[self.printOrder.jobs objectAtIndex:indexPath.row]);
    
    if (printJob.extraCopies == 0){
        UIAlertController *ac = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTableInBundle(@"Delete Item", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Delete [basket item]") message:NSLocalizedStringFromTableInBundle(@"Are you sure you want to delete this item?", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Refers to a basket item") preferredStyle:UIAlertControllerStyleAlert];
        [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"Cancel", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") style:UIAlertActionStyleCancel handler:NULL]];
        [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"Yes", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action){
            [self.printOrder removePrintJob:printJob];
            
            NSMutableSet *addresses = [[NSMutableSet alloc] init];
            for (id<OLPrintJob> job in self.printOrder.jobs){
                if ([job address]){
                    [addresses addObject:[job address]];
                }
            }
            if (addresses.count == 1){
                self.printOrder.shippingAddress = [addresses anyObject];
            }
            
            [self.printOrder saveOrder];
            [self updateViewsBasedOnCostUpdate];
            
#ifndef OL_NO_ANALYTICS
            [OLAnalytics trackBasketScreenDidDeleteItem:printJob inOrder:self.printOrder applePayIsAvailable:[OLKiteUtils isApplePayAvailable] ? @"Yes" : @"No"];
#endif
        }]];
        [self presentViewController:ac animated:YES completion:NULL];
    }
    else{
        printJob.extraCopies--;
        
        if (indexPath){
            [(UILabel *)[[self.tableView cellForRowAtIndexPath:indexPath].contentView viewWithTag:70] setText:@""];
            [(UILabel *)[[self.tableView cellForRowAtIndexPath:indexPath].contentView viewWithTag:1000] setText:@""];
            [(UIActivityIndicatorView *)[[self.tableView cellForRowAtIndexPath:indexPath].contentView viewWithTag:90] startAnimating];
        }
        [self.printOrder saveOrder];
        [self updateViewsBasedOnCostUpdate];
        
#ifndef OL_NO_ANALYTICS
        [OLAnalytics trackBasketItemQtyDownForItem:printJob inOrder:self.printOrder applePayIsAvailable:[OLKiteUtils isApplePayAvailable] ? @"Yes" : @"No"];
#endif
    }
}

- (IBAction)onButtonPlusClicked:(UIButton *)sender {
    CGPoint buttonPosition = [sender.superview convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
    OLProductPrintJob* printJob = ((OLProductPrintJob*)[self.printOrder.jobs objectAtIndex:indexPath.row]);
    printJob.extraCopies += 1;
    
    if (indexPath){
        [(UILabel *)[[self.tableView cellForRowAtIndexPath:indexPath].contentView viewWithTag:70] setText:@""];
        [(UILabel *)[[self.tableView cellForRowAtIndexPath:indexPath].contentView viewWithTag:1000] setText:@""];
        [(UIActivityIndicatorView *)[[self.tableView cellForRowAtIndexPath:indexPath].contentView viewWithTag:90] startAnimating];
    }
    
    [self.printOrder saveOrder];
    [self updateViewsBasedOnCostUpdate];
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackBasketItemQtyUpForItem:printJob inOrder:self.printOrder applePayIsAvailable:[OLKiteUtils isApplePayAvailable] ? @"Yes" : @"No"];
#endif
}

- (IBAction)onButtonEditClicked:(UIButton *)sender {
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
    
    [self editJobAtIndexPath:indexPath];
}

- (void)editJobAtIndexPath:(NSIndexPath *)indexPath{
    UIViewController *vc = [self viewControllerForItemAtIndexPath:indexPath];
    vc.modalPresentationStyle = [OLUserSession currentSession].kiteVc.modalPresentationStyle;
    [self presentViewController:vc animated:YES completion:NULL];
#ifndef OL_NO_ANALYTICS
    OLProductPrintJob* printJob = ((OLProductPrintJob*)[self.printOrder.jobs objectAtIndex:indexPath.row]);
    [OLAnalytics trackBasketScreenHitEditItem:printJob inOrder:self.printOrder applePayIsAvailable:[OLKiteUtils isApplePayAvailable] ? @"Yes" : @"No"];
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

- (BOOL)checkForShippingAddress{
    if ((![self.printOrder.shippingAddress isValidAddress] && self.printOrder.shippingAddressesOfJobs.count == 0) || !self.printOrder.email){
        [UIView animateWithDuration:0.1 animations:^{
            self.shippingDetailsBox.backgroundColor = [UIColor colorWithWhite:0.929 alpha:1.000];
            self.shippingDetailsBox.transform = CGAffineTransformMakeTranslation(-10, 0);
        } completion:^(BOOL finished){
            [UIView animateWithDuration:0.25 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0 options:0 animations:^{
                self.shippingDetailsBox.backgroundColor = [UIColor whiteColor];
                self.shippingDetailsBox.transform = CGAffineTransformIdentity;
            }completion:NULL];
        }];
        return NO;
    }
    else{
        return YES;
    }
}

- (IBAction)onButtonPayClicked:(UIButton *)sender {
    if (self.printOrder.jobs.count == 0){
        return;
    }
    if ((selectedPaymentMethod == kOLPaymentMethodPayPal || selectedPaymentMethod == kOLPaymentMethodCreditCard) && ![self checkForShippingAddress]){
        return;
    }
    
    [self.printOrder costWithCompletionHandler:^(OLPrintOrderCost *cost, NSError *error){
        if (error.code == kOLKiteSDKErrorCodeProductNotAvailableInRegion){
            UIAlertController *ac = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTableInBundle(@"Oops!", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
            [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"OK", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Acknowledgent to an alert dialog.") style:UIAlertActionStyleDefault handler:NULL]];
            [self presentViewController:ac animated:YES completion:NULL];
            return;
        }
        
        NSComparisonResult result = [[cost totalCostInCurrency:self.printOrder.currencyCode] compare:[NSDecimalNumber zero]];
        if (result == NSOrderedAscending || result == NSOrderedSame) {
            if (![self checkForShippingAddress]){
                return;
            }
            // The user must have a promo code which reduces this order cost to nothing, lucky user :)
            [self submitOrderForPrintingWithProofOfPayment:nil paymentMethod:@"Free Checkout" completion:^void(PKPaymentAuthorizationStatus status){}];
        }
        else if (selectedPaymentMethod == kOLPaymentMethodNone){
            [UIView animateWithDuration:0.1 animations:^{
                self.addPaymentBox.backgroundColor = [UIColor colorWithWhite:0.929 alpha:1.000];
                self.addPaymentBox.transform = CGAffineTransformMakeTranslation(-10, 0);
            } completion:^(BOOL finished){
                [UIView animateWithDuration:0.25 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0 options:0 animations:^{
                    self.addPaymentBox.backgroundColor = [UIColor whiteColor];
                    self.addPaymentBox.transform = CGAffineTransformIdentity;
                }completion:NULL];
            }];
        }
        else if (selectedPaymentMethod == kOLPaymentMethodCreditCard){
            if ([self checkForShippingAddress]){
                if ([OLKitePrintSDK useStripeForCreditCards]){
                    [self payWithExistingStripeCard:[OLStripeCard lastUsedCard]];
                }
                else{
                    [self payWithExistingPayPalCard:[OLPayPalCard lastUsedCard]];
                }
            }
        }
        else if (selectedPaymentMethod == kOLPaymentMethodApplePay){
            [self payWithApplePay];
        }
        else if (selectedPaymentMethod == kOLPaymentMethodPayPal){
            [self payWithPayPal];
        }
    }];
}

- (IBAction)onButtonAddPaymentMethodClicked:(id)sender {
    OLPaymentMethodsViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"OLPaymentMethodsViewController"];
    vc.delegate = self;
    vc.selectedPaymentMethod = selectedPaymentMethod;
    
    
    [self.navigationController pushViewController:vc animated:YES];
}


- (IBAction)onShippingDetailsGestureRecognized:(id)sender {
    [OLKiteUtils shippingControllerForPrintOrder:self.printOrder handler:^(id vc){
        [vc safePerformSelector:@selector(setUserEmail:) withObject:self.userEmail];
        [vc safePerformSelector:@selector(setUserPhone:) withObject:self.userPhone];
        [vc safePerformSelector:@selector(setDelegate:) withObject:self.delegate];
        [vc safePerformSelector:@selector(setKiteDelegate:) withObject:self.kiteDelegate];
        
        [self.navigationController pushViewController:vc animated:YES];
    }];
}

- (IBAction)onShippingMethodGestureRecognized:(id)sender {
    OLShippingMethodsViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"OLShippingMethodsViewController"];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - PayPalPaymentDelegate methods

- (void)payPalPaymentDidCancel:(id)paymentViewController {
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackBasketScreenPaymentMethodDidCancel:@"PayPal" forOrder:self.printOrder applePayIsAvailable:[OLKiteUtils isApplePayAvailable] ? @"Yes" : @"No"];
#endif
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)payPalPaymentViewController:(id)paymentViewController didCompletePayment:(id)completedPayment {
    [self dismissViewControllerAnimated:YES completion:nil];
    NSString *token = [OLPayPalWrapper confirmationWithPayment:completedPayment][@"response"][@"id"];
    token = [token stringByReplacingCharactersInRange:NSMakeRange(0, 3) withString:@"PAUTH"];
    [self submitOrderForPrintingWithProofOfPayment:token paymentMethod:@"PayPal" completion:^void(PKPaymentAuthorizationStatus status){}];
}

#pragma mark - Apple Pay Delegate Methods

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
            [OLAnalytics trackBasketScreenPaymentMethodDidCancel:@"Apple Pay" forOrder:self.printOrder applePayIsAvailable:[OLKiteUtils isApplePayAvailable] ? @"Yes" : @"No"];
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
                UIAlertController *ac = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTableInBundle(@"Oops!", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
                [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"OK", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Acknowledgent to an alert dialog.") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
                    [self.navigationController popViewControllerAnimated:YES];
                }]];
                [self presentViewController:ac animated:YES completion:NULL];
            }
        }];
    }];
}

- (void)handlePaymentAuthorizationWithPayment:(PKPayment *)payment
                                   completion:(void (^)(PKPaymentAuthorizationStatus))completion {
    if (![OLKiteUtils isApplePayAvailable]){
        return;
    }
    OLAddress *shippingAddress = [[OLAddress alloc] init];
    NSString *email;
    NSString *phone;
    shippingAddress.recipientFirstName = payment.shippingContact.name.givenName;
    shippingAddress.recipientLastName = payment.shippingContact.name.familyName;
    shippingAddress.line1 = payment.shippingContact.postalAddress.street;
    shippingAddress.city = payment.shippingContact.postalAddress.city;
    shippingAddress.stateOrCounty = payment.shippingContact.postalAddress.state;
    shippingAddress.zipOrPostcode = payment.shippingContact.postalAddress.postalCode;
    shippingAddress.country = [OLCountry countryForCode:payment.shippingContact.postalAddress.ISOCountryCode];
    if (!shippingAddress.country){
        shippingAddress.country = [OLCountry countryForName:payment.shippingContact.postalAddress.country];
    }
    email = payment.shippingContact.emailAddress;
    phone = [payment.shippingContact.phoneNumber stringValue];
    
    self.printOrder.shippingAddress = shippingAddress;
    
    self.printOrder.email = email;
    self.printOrder.phone = phone;
    
    if (![self.printOrder.shippingAddress isValidAddress]){
        completion(PKPaymentAuthorizationStatusInvalidShippingPostalAddress);
        return;
    }
    if (![OLCheckoutViewController validateEmail:email] && [OLKitePrintSDK environment] == OLKitePrintSDKEnvironmentLive){
        completion(PKPaymentAuthorizationStatusInvalidShippingContact);
        return;
    }
    id client = [OLStripeWrapper initSTPAPIClientWithPublishableKey:[OLKitePrintSDK stripePublishableKey]];
    [OLStripeWrapper client:client createTokenWithPayment:payment completion:^(id token, NSError *error) {
        if (error) {
            completion(PKPaymentAuthorizationStatusFailure);
            return;
        }
        [self submitOrderForPrintingWithProofOfPayment:[OLStripeWrapper tokenIdFromToken:token] paymentMethod:@"Apple Pay" completion:completion];
    }];
}

- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller didSelectShippingContact:(PKContact *)contact completion:(void (^)(PKPaymentAuthorizationStatus, NSArray<PKShippingMethod *> *, NSArray <PKPaymentSummaryItem *>*))completion{
    OLAddress *shippingAddress = [[OLAddress alloc] init];
    shippingAddress.country = [OLCountry countryForCode:contact.postalAddress.ISOCountryCode];
    
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
        
        // if a special discount exists, then add a Discount line item
        if (cost.specialPromoDiscount){
            NSDecimalNumber *currencyDiscount = cost.specialPromoDiscount[self.printOrder.currencyCode];
            if ([currencyDiscount doubleValue] != 0) {
                if ([currencyDiscount doubleValue] > 0) {
                    currencyDiscount = [currencyDiscount decimalNumberByMultiplyingBy:(NSDecimalNumber *)[NSDecimalNumber numberWithInteger:-1]];
                }
                
                for (PKPaymentSummaryItem *item in lineItems){
                    if ([item.amount doubleValue] < 0){
                        [lineItems removeObject:item];
                    }
                }
                
                [lineItems addObject:[PKPaymentSummaryItem summaryItemWithLabel:NSLocalizedStringFromTableInBundle(@"Promotional Discount", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") amount:currencyDiscount]];
            }
        }
        
        [lineItems addObject:[PKPaymentSummaryItem summaryItemWithLabel:[OLKitePrintSDK applePayPayToString] amount:[cost totalCostInCurrency:self.printOrder.currencyCode]]];
        if (!error){
            completion(PKPaymentAuthorizationStatusSuccess, nil, lineItems);
        }
        else{
            self.printOrder.shippingAddress = nil;
            completion(PKPaymentAuthorizationStatusFailure, nil, lineItems);
        }
    }];
}

- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller didSelectShippingMethod:(PKShippingMethod *)shippingMethod completion:(void (^)(PKPaymentAuthorizationStatus, NSArray<PKPaymentSummaryItem *> * _Nonnull))completion{
    [self.printOrder costWithCompletionHandler:^(OLPrintOrderCost *cost, NSError *error){
        [self costCalculationCompletedWithError:error];
        NSMutableArray *lineItems = [[NSMutableArray alloc] init];
        for (OLPaymentLineItem *item in cost.lineItems){
            [lineItems addObject:[PKPaymentSummaryItem summaryItemWithLabel:item.description  amount:[item costInCurrency:self.printOrder.currencyCode]]];
        }
        
        // if a special discount exists, then add a Discount line item
        if (cost.specialPromoDiscount){
            NSDecimalNumber *currencyDiscount = cost.specialPromoDiscount[self.printOrder.currencyCode];
            if ([currencyDiscount doubleValue] != 0) {
                if ([currencyDiscount doubleValue] > 0) {
                    currencyDiscount = [currencyDiscount decimalNumberByMultiplyingBy:(NSDecimalNumber *)[NSDecimalNumber numberWithInteger:-1]];
                }
                
                for (PKPaymentSummaryItem *item in lineItems){
                    if ([item.amount doubleValue] < 0){
                        [lineItems removeObject:item];
                    }
                }
                
                [lineItems addObject:[PKPaymentSummaryItem summaryItemWithLabel:NSLocalizedStringFromTableInBundle(@"Promotional Discount", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") amount:currencyDiscount]];
            }
        }
        
        [lineItems addObject:[PKPaymentSummaryItem summaryItemWithLabel:[OLKitePrintSDK applePayPayToString] amount:[cost totalCostInCurrency:self.printOrder.currencyCode]]];
        if (!error){
            completion(PKPaymentAuthorizationStatusSuccess, lineItems);
        }
        else{
            self.printOrder.shippingAddress = nil;
            completion(PKPaymentAuthorizationStatusFailure, lineItems);
        }
    }];
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfItems = self.printOrder.jobs.count;
    
    if (section == 0 && numberOfItems > 0){
        return [self finishedLoading] ? numberOfItems : 1;
    }
    else if (section == 0 && self.printOrder.jobs.count == 0){
        return 1;
    }
    else{
        return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && ![self finishedLoading] && self.printOrder.jobs.count > 0){
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
        productNameLabel.text = @"";
        UIButton *editButton = (UIButton *)[cell.contentView viewWithTag:60];
        UIButton *largeEditButton = (UIButton *)[cell.contentView viewWithTag:61];
        UILabel *priceLabel = (UILabel *)[cell.contentView viewWithTag:70];
        
        id<OLPrintJob> job = self.printOrder.jobs[indexPath.row];
        
        OLProduct *product = [OLProduct productWithTemplateId:[job templateId]];
        
        if (product.productTemplate.templateUI == OLTemplateUINA || product.productTemplate.templateUI == OLTemplateUINonCustomizable || [OLKiteUtils assetArrayContainsPDF:[job assetsForUploading]]){
            editButton.hidden = YES;
            largeEditButton.hidden = YES;
        }
        else{
            editButton.hidden = NO;
            largeEditButton.hidden = NO;
        }
        [editButton setTitle:[@"  " stringByAppendingString:NSLocalizedStringFromTableInBundle(@"basket.Edit", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Edit basket item")] forState:UIControlStateNormal];
        
        CGFloat rowHeight = [self tableView:self.tableView heightForRowAtIndexPath:indexPath];
        
        [imageView setAndFadeInImageWithOLAsset:[product coverPhotoAsset] size:CGSizeMake(rowHeight, rowHeight) applyEdits:NO placeholder:nil progress:NULL completionHandler:NULL];
        
        quantityLabel.text = [NSString stringWithFormat:@"%ld", (long)[job extraCopies]+1];
        
        [[cell viewWithTag:1000] removeFromSuperview];
        
        [self.printOrder costWithCompletionHandler:^(OLPrintOrderCost *cost, NSError *error){
            for (OLPaymentLineItem *item in cost.lineItems){
                if ([item.identifier isEqualToString:[job uuid]]){
                    productNameLabel.text = item.description;
                    
                    priceLabel.text = [item costStringInCurrency:self.printOrder.currencyCode];
                    
                    NSString *discountedPrice = [item discountedCostStringInCurrency:self.printOrder.currencyCode];
                    if (discountedPrice && ![discountedPrice isEqualToString:@""]){
                        UILabel *finalCostLabel = [cell.contentView viewWithTag:1000];
                        if (!finalCostLabel){
                            finalCostLabel = [[UILabel alloc] init];
                            
                            finalCostLabel.font = priceLabel.font;
                            finalCostLabel.tag = 1000;
                            
                            [cell.contentView addSubview:finalCostLabel];
                            finalCostLabel.translatesAutoresizingMaskIntoConstraints = NO;
                            [cell.contentView addConstraint:[NSLayoutConstraint constraintWithItem:priceLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:finalCostLabel attribute:NSLayoutAttributeTop multiplier:1 constant:-5]];
                            [cell.contentView addConstraint:[NSLayoutConstraint constraintWithItem:priceLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:finalCostLabel attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
                        }
                        finalCostLabel.text = discountedPrice;
                        
                        priceLabel.attributedText = [[NSAttributedString alloc] initWithString:priceLabel.text attributes:@{NSFontAttributeName : priceLabel.font, NSStrikethroughStyleAttributeName : [NSNumber numberWithInteger:NSUnderlineStyleSingle], NSForegroundColorAttributeName : [UIColor colorWithWhite:0.40 alpha:1.000]}];
                    }
                }
            }
            [(UIActivityIndicatorView *)[[self.tableView cellForRowAtIndexPath:indexPath].contentView viewWithTag:90] stopAnimating];
        }];
        
        cell.backgroundColor = [UIColor clearColor];
        
        return cell;
    }
    else{
        UITableViewCell *cell =  [tableView dequeueReusableCellWithIdentifier:@"emptyCell"];
        cell.backgroundColor = [UIColor clearColor];
        UILabel *label = [cell viewWithTag:10];
        label.text = NSLocalizedStringFromTableInBundle(@"Basket is empty", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"");
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 75;
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
    [OLAnalytics trackBasketScreenDidTapOnPromoCodeBoxforOrder:self.printOrder];
#endif
}

- (BOOL) tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    return self.printOrder.jobs.count > 0;
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
        }
        
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.printOrder saveOrder];
        [self updateViewsBasedOnCostUpdate];
        
#ifndef OL_NO_ANALYTICS
        [OLAnalytics trackBasketScreenDidDeleteItem:job inOrder:self.printOrder applePayIsAvailable:[OLKiteUtils isApplePayAvailable] ? @"Yes" : @"No"];
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
    viewControllerToCommit.modalPresentationStyle = [OLUserSession currentSession].kiteVc.modalPresentationStyle;
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
    
    NSMutableArray<OLAsset *> *jobAssets = [[printJob assetsForUploading] mutableCopy];
    
    //Special handling of products
    if (product.productTemplate.templateUI == OLTemplateUIPhotobook && [(OLPhotobookPrintJob *)printJob frontCover]){
        //Make sure we don't add the cover photo asset in the book photos
        OLAsset *potentialAsset = [(OLPhotobookPrintJob *)printJob frontCover];
        OLAsset *asset = potentialAsset;
        
        if ([potentialAsset.dataSource isKindOfClass:[OLAsset class]]){
            asset = (OLAsset *)potentialAsset.dataSource;
        }
        if (asset.uuid){
            [addedAssetsUUIDs addObject:asset.uuid];
        }
    }
    else if (product.productTemplate.templateUI == OLTemplateUIApparel && [printJob isKindOfClass:[OLApparelPrintJob class]]){
        [jobAssets removeAllObjects];
        OLAsset *asset = ((OLApparelPrintJob *)printJob).assets[@"center_chest"];
        if (!asset) {
            asset = ((OLApparelPrintJob *)printJob).assets[@"front_image"];
        }
        if (asset){
            [jobAssets addObject:asset];
        }
    }
    else if (product.productTemplate.templateUI == OLTemplateUIPoster){
        [OLCollagePosterViewController changeOrderOfPhotosInArray:jobAssets forProduct:product];
    }
    else if (product.productTemplate.templateUI == OLTemplateUIFrame){
        [OLFrameOrderReviewViewController reverseRowsOfPhotosInArray:jobAssets forProduct:product];
    }
    
    for (OLAsset *jobAsset in jobAssets){
        if ([jobAsset corrupt]){
            continue;
        }
        OLAsset *asset = jobAsset;
        
        if ([jobAsset.dataSource isKindOfClass:[OLAsset class]]){
            asset = (OLAsset *)jobAsset.dataSource;
        }
        [asset unloadImage];
        if (![addedAssetsUUIDs containsObject:asset.uuid]){
            [addedAssetsUUIDs addObject:asset.uuid];
            [userSelectedPhotos addObject:[asset copy]];
        }
        else if (product.productTemplate.templateUI == OLTemplateUIRectagle || product.productTemplate.templateUI == OLTemplateUICircle){
            for (OLAsset *existingAsset in userSelectedPhotos){
                if ([asset.uuid isEqualToString:existingAsset.uuid]){
                    existingAsset.extraCopies++;
                }
            }
        }
    }
    
    self.currentUserSelectedPhotos = [[OLAsset userSelectedAssets] copy];
    [[OLAsset userSelectedAssets] removeAllObjects];
    [[OLAsset userSelectedAssets] addObjectsFromArray:userSelectedPhotos];
    
    if ([OLKiteUtils imageProvidersAvailable:self] && product.productTemplate.templateUI != OLTemplateUIMug && product.productTemplate.templateUI != OLTemplateUICase && product.productTemplate.templateUI != OLTemplateUIApparel && product.productTemplate.templateUI != OLTemplateUIPhotobook && product.productTemplate.templateUI != OLTemplateUIPostcard && product.productTemplate.templateUI != OLTemplateUIPoster){
        OLImagePickerViewController *photoVc = [self.storyboard instantiateViewControllerWithIdentifier:@"OLImagePickerViewController"];
        photoVc.product = product;
        photoVc.overrideImagePickerMode = YES;
        return [self navViewControllerWithControllers:@[photoVc]];
    }
    else{
        UIViewController* orvc = [[OLUserSession currentSession].kiteVc reviewViewControllerForProduct:product photoSelectionScreen:NO];
        if ([printJob isKindOfClass:[OLApparelPrintJob class]]){
            OLAsset *asset = ((OLApparelPrintJob *)printJob).assets[@"center_back"];
            if (!asset){
                asset = ((OLApparelPrintJob *)printJob).assets[@"back_image"];
            }
            [orvc safePerformSelector:@selector(setBackAsset:) withObject:asset];
        }
        else if ([printJob isKindOfClass:[OLPhotobookPrintJob class]] && [(OLPhotobookPrintJob *)printJob frontCover]){
            OLAsset *coverPhoto = [(OLPhotobookPrintJob *)printJob frontCover];
            [orvc safePerformSelector:@selector(setCoverPhoto:) withObject:coverPhoto];
        }
        else{
            [orvc safePerformSelector:@selector(setCoverPhoto:) withObject:[[OLPlaceholderAsset alloc] init]];
        }
        
        [orvc safePerformSelector:@selector(setProduct:) withObject:product];
        return [self navViewControllerWithControllers:@[orvc]];
    }
}

- (void)paymentMethodsViewController:(OLPaymentMethodsViewController *)vc didPickPaymentMethod:(OLPaymentMethod)method{
    selectedPaymentMethod = method;
    [self updateSelectedPaymentMethodView];
#ifndef OL_NO_ANALYTICS
    NSString *methodName;
    switch (method) {
        case kOLPaymentMethodPayPal:
            methodName = @"PayPal";
            break;
        case kOLPaymentMethodApplePay:
            methodName = @"Apple Pay";
            break;
        case kOLPaymentMethodCreditCard:
            methodName = @"Credit Card";
            break;
        case kOLPaymentMethodNone:
            methodName = @"None";
            break;
            
        default:
            break;
    }
    [OLAnalytics trackPaymentMethodSelected:self.printOrder methodName:methodName];
#endif
}

@end
