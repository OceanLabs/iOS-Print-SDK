//
//  OrdersViewController.m
//  Print Studio
//
//  Created by Deon Botha on 13/01/2014.
//  Copyright (c) 2014 Ocean Labs. All rights reserved.
//

#import "OLOrdersViewController.h"
#import "OLReceiptViewController.h"
#import "OLProduct.h"
#import "OLPrintJob.h"
#import "OLPrintOrder+History.h"
#import "OLPrintOrderCost.h"
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "OLKiteABTesting.h"

static const NSInteger kSectionCompletedOrders = 0;

@interface OLOrdersViewController () <MFMailComposeViewControllerDelegate>
@end

@implementation OLOrdersViewController

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setTitle:NSLocalizedString(@"Orders", @"")];
    
    if ([OLPrintOrder printOrderHistory].count == 0) {
        UILabel* noOrdersLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 100)];
        noOrdersLabel.text = NSLocalizedString(@"Buy some products & they'll appear here!", @"");
        noOrdersLabel.textAlignment = NSTextAlignmentCenter;
        noOrdersLabel.adjustsFontSizeToFitWidth = YES;
        [self.view addSubview:noOrdersLabel];
    }
}

#pragma mark - UITableViewDataSource methods

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == kSectionCompletedOrders) {
        return NSLocalizedString(@"Completed Orders", "");
    }
    return @"";
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if ([OLPrintOrder printOrderHistory].count > 0) {
        return 1;
    }
    
    return 0;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [OLPrintOrder printOrderHistory].count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    if (indexPath.section == kSectionCompletedOrders) {
        static NSString *CellIdentifier = @"OrderCell";
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        NSArray *printOrders = [OLPrintOrder printOrderHistory];
        OLPrintOrder *order = printOrders[printOrders.count - (indexPath.row + 1)];
        UILabel *titleLabel = (UILabel *) [cell.contentView viewWithTag:101];
        UILabel *subtitleLabel = (UILabel *) [cell.contentView viewWithTag:100];
        UILabel *priceLabel = (UILabel *) [cell.contentView viewWithTag:102];
        
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
    
    return cell;
}

- (void)dismiss{
    [self.navigationController.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == kSectionCompletedOrders) {
        NSArray *printOrders = [OLPrintOrder printOrderHistory];
        OLPrintOrder *order = printOrders[printOrders.count - (indexPath.row + 1)];
        OLReceiptViewController *receiptVC = [[OLReceiptViewController alloc] initWithPrintOrder:order];
        [self.navigationController pushViewController:receiptVC animated:YES];
    }
}

#pragma mark - MFMailComposeViewControllerDelegate methods
- (IBAction)emailButtonPushed:(id)sender {
    
    if([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *mailCont = [[MFMailComposeViewController alloc] init];
        mailCont.mailComposeDelegate = self;
        [mailCont setSubject:@""];
        [mailCont setToRecipients:@[[OLKiteABTesting sharedInstance].supportEmail]];
        [mailCont setMessageBody:@"" isHTML:NO];
        [self presentViewController:mailCont animated:YES completion:nil];
    } else {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Support", @"") message:[NSString stringWithFormat:NSLocalizedString(@"Please email %@ for support & customer service enquiries.", @""), [OLKiteABTesting sharedInstance].supportEmail] delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
        [av show];
    }
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    //handle any error
    [controller dismissViewControllerAnimated:YES completion:nil];
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
