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
#import "OLImageDownloader.h"
#import "OLReceiptViewController.h"
#import "OLPaymentViewController.h"
#import "Util.h"
#import "OLPrintOrder.h"
#import "OLPrintOrder+History.h"
#import "OLPrintJob.h"
#import "OLProductTemplate.h"
#import "OLConstants.h"
#import "OLPaymentLineItem.h"
#import "OLPrintOrderCost.h"
#import "OLPackProductViewController.h"
#import "OLKiteViewController.h"
#import "OLKiteABTesting.h"
#import "UIImage+OLUtils.h"
#import "UIImage+ImageNamedInKiteBundle.h"
#import "OLNavigationController.h"
#import "OLKiteUtils.h"
#import "OLUserSession.h"

static const NSUInteger kSectionOrderSummary = 0;
static const NSUInteger kSectionOrderId = 1;
static const NSUInteger kSectionErrorRetry = 2;

@interface OLReceiptViewController () <OLCheckoutDelegate>
@property (nonatomic, strong) OLPrintOrder *printOrder;
@property (nonatomic, assign) BOOL presentedModally;
@property (weak, nonatomic) id<OLCheckoutDelegate> delegate;
@end

@interface OLPrintOrder (Private)
- (void)validateOrderSubmissionWithCompletionHandler:(void(^)(NSString *orderIdReceipt, NSError *error))handler;
@end

@interface OLPackProductViewController (Private)

- (UIView *)footerViewForReceiptViewController:(UIViewController *)receiptVc;

@end

@implementation OLReceiptViewController

- (instancetype _Nullable)initWithPrintOrder:(OLPrintOrder *_Nonnull)printOrder {
    if (self = [super initWithStyle:UITableViewStyleGrouped]) {
        self.printOrder = printOrder;
    }
    
    return self;
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
    self.title = @"Receipt";
    
    [self setupHeader];
    
    if ([self.tableView respondsToSelector:@selector(setCellLayoutMarginsFollowReadableWidth:)]){
        self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    }
    
    if ([self.delegate respondsToSelector:@selector(footerViewForReceiptViewController:)]){
        self.tableView.tableFooterView = [(OLPackProductViewController *)self.delegate footerViewForReceiptViewController:self];
    }
}

- (void)setupHeader{
    NSString *url = self.printOrder.printed ? [OLKiteABTesting sharedInstance].receiptSuccessURL : [OLKiteABTesting sharedInstance].receiptFailureURL;
    if (url){
        [[OLImageDownloader sharedInstance] downloadImageAtURL:[NSURL URLWithString:url] withCompletionHandler:^(UIImage *image, NSError *error){
            image = [UIImage imageWithCGImage:image.CGImage scale:2 orientation:image.imageOrientation];
            NSString *bgUrl = self.printOrder.printed ? [OLKiteABTesting sharedInstance].receiptSuccessBgURL : [OLKiteABTesting sharedInstance].receiptFailureBgURL;
            if (bgUrl){
                [[OLImageDownloader sharedInstance] downloadImageAtURL:[NSURL URLWithString:bgUrl] withCompletionHandler:^(UIImage *bgImage, NSError *error){
                    bgImage = [UIImage imageWithCGImage:bgImage.CGImage scale:2 orientation:image.imageOrientation];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self setupBannerImage:image withBgImage:bgImage];
                    });
                }];
            }
            else{
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self setupBannerImage:image withBgImage:nil];
                });
            }
            
        }];
    }
    else{
        [self setupBannerImage:[UIImage imageNamedInKiteBundle:self.printOrder.printed ? @"receipt_success" : @"receipt_failure"] withBgImage:[UIImage imageNamedInKiteBundle:self.printOrder.printed ? @"receipt_success_bg" : @"receipt_failure_bg"]];
    }
}

- (void)onButtonDoneClicked {
    OLKiteViewController *kiteVc = [OLUserSession currentSession].kiteVc;
    if  (!kiteVc){
        [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
    }
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackKiteDismissed];
#endif
    if ([kiteVc.delegate respondsToSelector:@selector(kiteControllerDidFinish:)]){
        [kiteVc.delegate kiteControllerDidFinish:kiteVc];
    }
    else{
        [kiteVc dismissViewControllerAnimated:YES completion:^{}];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.presentedModally || [OLKiteABTesting sharedInstance].launchedWithPrintOrder) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Done", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"") style:UIBarButtonItemStyleDone target:self action:@selector(onButtonDoneClicked)];
        
        UIColor *color1 = [OLKiteABTesting sharedInstance].lightThemeColor1;
        if (color1){
            self.navigationItem.rightBarButtonItem.tintColor = color1;
        }
        UIFont *font = [[OLKiteABTesting sharedInstance] lightThemeFont1WithSize:17];
        if (font){
            [self.navigationItem.rightBarButtonItem setTitleTextAttributes:@{NSFontAttributeName : font} forState:UIControlStateNormal];
        }
        
        self.navigationController.viewControllers = @[self];
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (!(self.presentedModally || [OLKiteABTesting sharedInstance].launchedWithPrintOrder)) {
        NSMutableArray *navigationStack = self.navigationController.viewControllers.mutableCopy;
        if (navigationStack.count >= 2 &&
            [navigationStack[navigationStack.count - 2] isKindOfClass:[OLPaymentViewController class]]) {
            // clear the stack as we don't want the user to be able to return to payment as that stage of the journey is now complete.
            [navigationStack removeObjectsInRange:NSMakeRange(1, navigationStack.count - 2)];
            self.navigationController.viewControllers = navigationStack;
        }
    }
}

- (void)onButtonRetryClicked{
    if (self.printOrder.submitStatus == OLPrintOrderSubmitStatusError){
        [self.printOrder cancelSubmissionOrPreemptedAssetUpload];
        UIAlertController *ac = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTableInBundle(@"Oops!", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"") message:self.printOrder.submitStatusErrorMessage preferredStyle:UIAlertControllerStyleAlert];
        [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"New Payment", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"") style:UIAlertActionStyleDefault handler:^(id action){
            OLPaymentViewController *vc = [[OLPaymentViewController alloc] initWithPrintOrder:self.printOrder];
            vc.delegate = self;
            OLNavigationController *nvc = [[OLNavigationController alloc] initWithRootViewController:vc];
            nvc.modalPresentationStyle = [OLUserSession currentSession].kiteVc.modalPresentationStyle;
            [self presentViewController:nvc animated:YES completion:NULL];
        }]];
        [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"Cancel", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"") style:UIAlertActionStyleCancel handler:NULL]];
        [self presentViewController:ac animated:YES completion:NULL];
        return;
    }
    else if (self.printOrder.submitStatus == OLPrintOrderSubmitStatusAccepted || self.printOrder.submitStatus == OLPrintOrderSubmitStatusReceived){
        [OLProgressHUD setDefaultMaskType:OLProgressHUDMaskTypeBlack];
        [OLProgressHUD showWithStatus:NSLocalizedStringFromTableInBundle(@"Processing", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"")];
        [self.printOrder validateOrderSubmissionWithCompletionHandler:^(NSString *orderReceipt, NSError *error){
            [OLProgressHUD dismiss];
            if (error){
                UIAlertController *ac = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTableInBundle(@"Oops!", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"") message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
                [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"OK", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"") style:UIAlertActionStyleDefault handler:NULL]];
                [self presentViewController:ac animated:YES completion:NULL];
                
            }
            else{
                [self retryWasSuccessful];
            }
        }];
        return;
    }
    else{
        [self retrySubmittingOrderForPrinting];
    }
}

- (void)retrySubmittingOrderForPrinting {
    [self.printOrder cancelSubmissionOrPreemptedAssetUpload];
    [OLProgressHUD setDefaultMaskType:OLProgressHUDMaskTypeBlack];
    [OLProgressHUD showWithStatus:@"Processing"];
    [self.printOrder submitForPrintingWithProgressHandler:^(NSUInteger totalAssetsUploaded, NSUInteger totalAssetsToUpload,
                                                            long long totalAssetBytesWritten, long long totalAssetBytesExpectedToWrite,
                                                            long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        const float step = (1.0f / totalAssetsToUpload);
        float progress = totalAssetsUploaded * step + (totalAssetBytesWritten / (float) totalAssetBytesExpectedToWrite) * step;
        [OLProgressHUD setDefaultMaskType:OLProgressHUDMaskTypeBlack];
        [OLProgressHUD showProgress:progress status:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Uploading Images \n%lu / %lu", @"KitePrintSDK", [OLKiteUtils kiteBundle], @""), (unsigned long) totalAssetsUploaded + 1, (unsigned long) totalAssetsToUpload]];
    } completionHandler:^(NSString *orderIdReceipt, NSError *error) {
        [self.printOrder saveToHistory]; // save again as the print order has it's receipt set if it was successful, otherwise last error is set
        [OLProgressHUD dismiss];
        
        if (error) {
            UIAlertController *ac = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTableInBundle(@"Oops!", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"") message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
            [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"OK", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){}]];
            [self presentViewController:ac animated:YES completion:NULL];
        } else {
            [self retryWasSuccessful];
        }
    }];
}

- (void)retryWasSuccessful{
    if (self.printOrder.printed){
        [[NSNotificationCenter defaultCenter] postNotificationName:kOLNotificationPrintOrderSubmission object:self userInfo:@{kOLKeyUserInfoPrintOrder: self.printOrder}];
#ifndef OL_NO_ANALYTICS
        [OLAnalytics trackOrderSubmission:self.printOrder];
    }
#endif
    
    [UIView transitionWithView:self.view duration:0.3f options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        [self setupHeader];
    } completion:nil];
    
    [self.tableView reloadData];
}

#pragma mark - Checkout delegate

- (BOOL)shouldDismissPaymentViewControllerAfterPayment{
    return YES;
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.printOrder.printed ? 2 : 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == kSectionOrderSummary) {
        __block NSUInteger count = 0;
        [self.printOrder costWithCompletionHandler:^(OLPrintOrderCost *cost, NSError *error) {
            // this will actually do the right thing. Either this will callback immediately because printOrder
            // has cached costs and the count will be updated before below conditionals are hit or it will make an async request and count will remain 0 for below.
            count = cost.lineItems.count;
        }];
        if (count == 0){
            return self.printOrder.jobs.count;
        }
        if (count == 1) {
            return count;
        } else {
            return count + 1; // additional cell to show total
        }
    } else if (section == kSectionOrderId) {
        return 1;
    } else if (section  == kSectionErrorRetry) {
        return self.printOrder.printed ? 0 : 1;
    } else {
        return 0;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == kSectionOrderSummary) {
        return NSLocalizedStringFromTableInBundle(@"Order Summary", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"");
    } else if (section == kSectionOrderId) {
        return NSLocalizedStringFromTableInBundle(@"Order Id", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"");
    }
    
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    if (indexPath.section == kSectionOrderId) {
        static NSString *const kCellIdOrderId = @"kCellIdOrderId";
        cell = [tableView dequeueReusableCellWithIdentifier:kCellIdOrderId];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellIdOrderId];
            cell.textLabel.adjustsFontSizeToFitWidth = YES;
            cell.textLabel.minimumScaleFactor = 0.5;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        
        if (self.printOrder.printed) {
            cell.textLabel.text = self.printOrder.receipt;
        } else {
            NSMutableString *receipt = [[NSMutableString alloc] init];
            if (self.printOrder.proofOfPayment) {
                [receipt appendString:self.printOrder.proofOfPayment];
            }
            
            if (self.printOrder.promoCode) {
                if (receipt.length > 0) {
                    [receipt appendString:@" "];
                }
                
                [receipt appendString:@"PROMO-"];
                [receipt appendString:self.printOrder.promoCode];
            }
            
            cell.textLabel.text = receipt;
        }
    } else if (indexPath.section == kSectionOrderSummary) {
        static NSString *const CellIdentifier = @"JobCostSummaryCell";
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
            cell.textLabel.font = [UIFont systemFontOfSize:14];
            cell.detailTextLabel.font = [UIFont systemFontOfSize:14];
            cell.textLabel.adjustsFontSizeToFitWidth = YES;
            cell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
            cell.textLabel.minimumScaleFactor = 0.5;
            cell.textLabel.numberOfLines = 2;
            cell.detailTextLabel.minimumScaleFactor = 0.5;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            [cell.detailTextLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
            
            cell.textLabel.translatesAutoresizingMaskIntoConstraints = NO;
            cell.detailTextLabel.translatesAutoresizingMaskIntoConstraints = NO;
            [cell.textLabel.superview addConstraint:[NSLayoutConstraint constraintWithItem:cell.textLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:cell.textLabel.superview attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
            [cell.detailTextLabel.superview addConstraint:[NSLayoutConstraint constraintWithItem:cell.detailTextLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:cell.detailTextLabel.superview attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
            [cell.contentView addConstraint:[NSLayoutConstraint constraintWithItem:cell.textLabel attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationLessThanOrEqual toItem:cell.detailTextLabel attribute:NSLayoutAttributeLeading multiplier:1 constant:-5]];
            [cell.textLabel.superview addConstraint:[NSLayoutConstraint constraintWithItem:cell.textLabel attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:cell.textLabel.superview attribute:NSLayoutAttributeLeading multiplier:1 constant:15]];
            [cell.detailTextLabel.superview addConstraint:[NSLayoutConstraint constraintWithItem:cell.detailTextLabel attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:cell.detailTextLabel.superview attribute:NSLayoutAttributeTrailing multiplier:1 constant:-15]];
        }
        
        [self.printOrder costWithCompletionHandler:^(OLPrintOrderCost *orderCost, NSError *error) {
            if (orderCost){
                NSArray *lineItems = orderCost.lineItems;
                NSDecimalNumber *totalCost = [orderCost totalCostInCurrency:self.printOrder.currencyCode];
                
                BOOL total = indexPath.row >= lineItems.count;
                NSDecimalNumber *cost;
                NSString *currencyCode = self.printOrder.currencyCode;
                if (total) {
                    cell.textLabel.text = NSLocalizedStringFromTableInBundle(@"Total", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"");
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
            }
            else{
                cell.textLabel.text = [self.printOrder.jobs[indexPath.item] productName];
                cell.textLabel.font = [UIFont systemFontOfSize:cell.textLabel.font.pointSize];
            }
        }];
    } else if (indexPath.section == kSectionErrorRetry) {
        static NSString *const kCellRetry = @"kCellRetry";
        cell = [tableView dequeueReusableCellWithIdentifier:kCellRetry];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellRetry];
            cell.textLabel.textColor = [UIColor colorWithRed:0 green:135 / 255.0 blue:1 alpha:1];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        
        cell.textLabel.text = NSLocalizedStringFromTableInBundle(@"Retry", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"");
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section != kSectionErrorRetry) {
        return;
    }
    
    [self onButtonRetryClicked];
}

@end
