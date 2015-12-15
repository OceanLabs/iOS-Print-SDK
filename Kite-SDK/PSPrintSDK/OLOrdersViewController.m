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
#import "OLKiteUtils.h"
#import "OLKiteViewController.h"
#import "OLAnalytics.h"

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
}

#pragma mark - UITableViewDataSource methods

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return NSLocalizedString(@"Completed Orders", "");
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return MAX([OLPrintOrder printOrderHistory].count, 1);
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    if ([OLPrintOrder printOrderHistory].count > 0){
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
    else{
        cell = [tableView dequeueReusableCellWithIdentifier:@"noOrdersCell"];
//        cell.backgroundColor = [UIColor clearColor];
    }
    return cell;
}

- (void)dismiss{
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackOrderHistoryScreenDismissed];
#endif
    [self.navigationController.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *printOrders = [OLPrintOrder printOrderHistory];
    OLPrintOrder *order = printOrders[printOrders.count - (indexPath.row + 1)];
    OLReceiptViewController *receiptVC = [[OLReceiptViewController alloc] initWithPrintOrder:order];
    [self.navigationController pushViewController:receiptVC animated:YES];
}

#pragma mark - MFMailComposeViewControllerDelegate methods
- (IBAction)emailButtonPushed:(id)sender {
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackFeedbackButtonTapped];
#endif
    
    if([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *mailCont = [[MFMailComposeViewController alloc] init];
        mailCont.mailComposeDelegate = self;
        [mailCont setSubject:@""];
        [mailCont setToRecipients:@[[OLKiteABTesting sharedInstance].supportEmail]];
        [mailCont setMessageBody:@"" isHTML:NO];
        mailCont.modalPresentationStyle = [OLKiteUtils kiteVcForViewController:self].modalPresentationStyle;
        [self presentViewController:mailCont animated:YES completion:nil];
    } else {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Support", @"") message:[NSString stringWithFormat:NSLocalizedString(@"Please email %@ for support & customer service enquiries.", @""), [OLKiteABTesting sharedInstance].supportEmail] delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
        [av show];
    }
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackFeedbackScreenFinishedWithResult:result];
#endif
    
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
