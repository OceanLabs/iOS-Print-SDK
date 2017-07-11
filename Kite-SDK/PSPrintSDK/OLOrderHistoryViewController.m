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


#import "OLOrderHistoryViewController.h"
#import "OLReceiptViewController.h"
#import "OLProduct.h"
#import "OLPrintJob.h"
#import "OLPrintOrderCost.h"
#import "OLPrintOrder+History.h"
#import "OLKiteUtils.h"
#import "OLAnalytics.h"
#import "OLKiteViewController.h"
#import "OLUserSession.h"
#import "OLKiteViewController+Private.h"

@interface OLOrderHistoryViewController ()
@property (strong, nonatomic) NSArray *printOrderHistory;
@end

@implementation OLOrderHistoryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setTitle:OLLocalizedString(@"Order History", @"")];
    
    NSAssert(self.navigationController, @"Should be shown as part of a UINavigationController");
    
    self.printOrderHistory = [OLPrintOrder printOrderHistory];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:OLLocalizedString(@"Cancel", @"") style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackOrderHistoryScreenViewed];
#endif
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", @"") style:UIBarButtonItemStylePlain target:nil action:nil];
}

- (void)dismiss{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)dealloc{
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackOrderHistoryScreenDismissed];
#endif
}

#pragma mark - UITableViewDataSource methods

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return OLLocalizedString(@"Completed Orders", @"");
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return MAX(self.printOrderHistory.count, 1);
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    if (self.printOrderHistory.count > 0){
        static NSString *CellIdentifier = @"OrderCell";
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        NSArray *printOrders = self.printOrderHistory;
        OLPrintOrder *order = printOrders[printOrders.count - (indexPath.row + 1)];
        UILabel *titleLabel = (UILabel *) [cell.contentView viewWithTag:101];
        UILabel *subtitleLabel = (UILabel *) [cell.contentView viewWithTag:100];
        UILabel *priceLabel = (UILabel *) [cell.contentView viewWithTag:102];
        priceLabel.text = nil;
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
        [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [dateFormatter setLocale:[NSLocale currentLocale]];
        
        NSString *s = @"";
        for (id <OLPrintJob> job in order.jobs){
            OLProduct *product = [OLProduct productWithTemplateId:job.templateId];
            if (product.productTemplate){
                s = [[s stringByAppendingString:product.productTemplate.name] stringByAppendingString:@", "];
            }
            else{
                s = [[s stringByAppendingString:job.templateId] stringByAppendingString:@", "];
            }
        }
        
        s = [s stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@", "]];
        
        subtitleLabel.text = [NSString stringWithFormat:@"%@", s];
        
        titleLabel.text = [dateFormatter stringFromDate:order.lastPrintSubmissionDate];
        
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
        [formatter setCurrencyCode:order.currencyCode];
        [order costWithCompletionHandler:^(OLPrintOrderCost *cost, NSError *error){
            priceLabel.text = [formatter stringFromNumber:[cost totalCostInCurrency:order.currencyCode]];
        }];
    }
    else{
        cell = [tableView dequeueReusableCellWithIdentifier:@"noOrdersCell"];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *printOrders = self.printOrderHistory;
    OLPrintOrder *order = printOrders[printOrders.count - (indexPath.row + 1)];
    OLReceiptViewController *receiptVC = [[OLUserSession currentSession].kiteVc receiptViewControllerForPrintOrder:order];
    if (!receiptVC){
        receiptVC = [[OLReceiptViewController alloc] initWithPrintOrder:order];
    }
    [self.navigationController pushViewController:receiptVC animated:YES];
}

@end
