//
//  PrintOrderHistoryViewController.m
//  PS SDK
//
//  Created by Deon Botha on 24/03/2014.
//  Copyright (c) 2014 Deon Botha. All rights reserved.
//

#import "PrintOrderHistoryViewController.h"
#import "OLPrintOrder.h"
#import "OLPrintOrder+History.h"
#import "OLReceiptViewController.h"

@interface PrintOrderHistoryViewController ()

@end

@implementation PrintOrderHistoryViewController

#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [OLPrintOrder printOrderHistory].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    NSArray *orders = [OLPrintOrder printOrderHistory];
    OLPrintOrder *order = orders[indexPath.row];
    cell.textLabel.text = order.printed ? order.receipt : @"Failed to Print";
    return cell;
}

#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    NSArray *orders = [OLPrintOrder printOrderHistory];
    OLPrintOrder *order = orders[indexPath.row];
    OLReceiptViewController *receiptVC = [[OLReceiptViewController alloc] initWithPrintOrder:order];
    [self.navigationController pushViewController:receiptVC animated:YES];
}

@end
