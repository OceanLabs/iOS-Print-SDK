//
//  ReceiptViewController.m
//  Kite Print SDK
//
//  Created by Deon Botha on 10/01/2014.
//  Copyright (c) 2014 Ocean Labs. All rights reserved.
//

#import "OLReceiptViewController.h"
#import "OLPaymentViewController.h"
#import "Util.h"
#import "OLPrintOrder.h"
#import "OLPrintOrder+History.h"
#import "OLPrintJob.h"
#import "OLProductTemplate.h"
#import "OLConstants.h"
#import <SVProgressHUD.h>

static const NSUInteger kSectionOrderSummary = 0;
static const NSUInteger kSectionOrderId = 1;
static const NSUInteger kSectionErrorRetry = 2;

@interface OLReceiptViewController ()
@property (nonatomic, strong) OLPrintOrder *printOrder;
@property (nonatomic, assign) BOOL presentedModally;
@end

@implementation OLReceiptViewController

- (id)initWithPrintOrder:(OLPrintOrder *)printOrder {
    if (self = [super initWithStyle:UITableViewStyleGrouped]) {
        self.printOrder = printOrder;
    }
    
    return self;
}


- (BOOL)shouldAutorotate {
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Receipt";
    
    self.tableView.tableHeaderView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, 86 * [UIScreen mainScreen].bounds.size.width / 320.0)];
    
    if (self.printOrder.printed) {
        ((UIImageView *) self.tableView.tableHeaderView).image = [UIImage imageNamed:@"receipt_success"];
    } else {
        ((UIImageView *) self.tableView.tableHeaderView).image = [UIImage imageNamed:@"receipt_failure"];
    }
}

- (void)onButtonDoneClicked {
    [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.presentedModally) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Done", @"KitePrintSDK", [OLConstants bundle], @"") style:UIBarButtonItemStylePlain target:self action:@selector(onButtonDoneClicked)];
        self.navigationController.viewControllers = @[self];
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (!self.presentedModally) {
        NSMutableArray *navigationStack = self.navigationController.viewControllers.mutableCopy;
        if ([navigationStack[navigationStack.count - 2] isKindOfClass:[OLPaymentViewController class]]) {
            // clear the stack as we don't want the user to be able to return to payment as that stage of the journey is now complete.
            [navigationStack removeObjectsInRange:NSMakeRange(1, navigationStack.count - 2)];
            self.navigationController.viewControllers = navigationStack;
        }
    }
}

- (void)retrySubmittingOrderForPrinting {
    [SVProgressHUD showWithStatus:@"Processing" maskType:SVProgressHUDMaskTypeBlack];
    [self.printOrder submitForPrintingWithProgressHandler:^(NSUInteger totalAssetsUploaded, NSUInteger totalAssetsToUpload,
                                                            long long totalAssetBytesWritten, long long totalAssetBytesExpectedToWrite,
                                                            long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        const float step = (1.0f / totalAssetsToUpload);
        float progress = totalAssetsUploaded * step + (totalAssetBytesWritten / (float) totalAssetBytesExpectedToWrite) * step;
        [SVProgressHUD showProgress:progress status:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Uploading Images \n%lu / %lu", @"KitePrintSDK", [OLConstants bundle], @""), (unsigned long) totalAssetsUploaded + 1, (unsigned long) totalAssetsToUpload] maskType:SVProgressHUDMaskTypeBlack];
    } completionHandler:^(NSString *orderIdReceipt, NSError *error) {
        [self.printOrder saveToHistory]; // save again as the print order has it's receipt set if it was successful, otherwise last error is set
        [SVProgressHUD dismiss];

        if (error) {
            [[[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Oops!", @"KitePrintSDK", [OLConstants bundle], @"") message:error.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedStringFromTableInBundle(@"OK", @"KitePrintSDK", [OLConstants bundle], @"") otherButtonTitles:nil] show];
        } else {
            [UIView transitionWithView:self.view duration:0.3f options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
                ((UIImageView *) self.tableView.tableHeaderView).image = [UIImage imageNamed:@"receipt_success"];
            } completion:nil];
            
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:kSectionErrorRetry] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView reloadData];
        }
    }];
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.printOrder.printed ? 2 : 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == kSectionOrderSummary) {
        if (self.printOrder.jobs.count <= 1) {
            return self.printOrder.jobs.count;
        } else {
            return self.printOrder.jobs.count + 1; // additional cell to show total
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
        return NSLocalizedStringFromTableInBundle(@"Order Summary", @"KitePrintSDK", [OLConstants bundle], @"");
    } else if (section == kSectionOrderId) {
        return NSLocalizedStringFromTableInBundle(@"Order Id", @"KitePrintSDK", [OLConstants bundle], @"");
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
                cell.textLabel.text = [NSString stringWithFormat:@"%lu x %@", (unsigned long)self.printOrder.jobs.count, job.productName];
            } else if (template.templateClass == kOLTemplateClassFrame) {
                cell.textLabel.text = [NSString stringWithFormat:@"%lu x %@", (unsigned long) (job.quantity + template.quantityPerSheet - 1 ) / template.quantityPerSheet, job.productName];
            } else if (template.templateClass == kOLTemplateClassPoster){
                cell.textLabel.text = [NSString stringWithFormat:@"%lu x %@", (unsigned long) (job.quantity + template.quantityPerSheet - 1 ) / template.quantityPerSheet, job.productName];
            }
            else if (template.templateClass == kOLTemplateClassCase || template.templateClass == kOLTemplateClassDecal){
                cell.textLabel.text = [NSString stringWithFormat:@"%lu x %@", (unsigned long) (job.quantity + template.quantityPerSheet - 1 ) / template.quantityPerSheet, job.productName];
            }
            else {
                cell.textLabel.text = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Pack of %lu %@", @"KitePrintSDK", [OLConstants bundle], @""), (unsigned long)job.quantity, job.productName];
            }
            
            cell.textLabel.font = [UIFont systemFontOfSize:cell.textLabel.font.pointSize];
            cell.detailTextLabel.font = [UIFont systemFontOfSize:cell.detailTextLabel.font.pointSize];
            cost = self.printOrder.jobs.count == 1 ? self.printOrder.cost : [job costInCurrency:currencyCode]; // if there is only 1 job then use the print order total cost as a promo discount may have been applied
        }
        
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
        [formatter setCurrencyCode:currencyCode];
        cell.detailTextLabel.text = [formatter stringFromNumber:cost];
    } else if (indexPath.section == kSectionErrorRetry) {
        static NSString *const kCellRetry = @"kCellRetry";
        cell = [tableView dequeueReusableCellWithIdentifier:kCellRetry];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellRetry];
            cell.textLabel.textColor = [UIColor colorWithRed:0 green:135 / 255.0 blue:1 alpha:1];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        
        cell.textLabel.text = NSLocalizedStringFromTableInBundle(@"Retry", @"KitePrintSDK", [OLConstants bundle], @"");
    }

    return cell;
}

#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section != kSectionErrorRetry) {
        return;
    }
    
    [self retrySubmittingOrderForPrinting];
}

#pragma mark - Autorotate and Orientation Methods

- (BOOL)shouldAutorotate {
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

@end
