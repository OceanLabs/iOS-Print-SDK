//
//  OLCaseSelectionViewController.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 2/24/15.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import "OLCaseSelectionViewController.h"
#import "OLKitePrintSDK.h"
#import "OLProduct.h"
#import "OLSingleImageProductReviewViewController.h"
#import "UITableViewController+ScreenWidthFactor.h"

@interface OLCaseSelectionViewController ()

@property (strong, nonatomic) NSMutableArray *caseProducts;

@end

@implementation OLCaseSelectionViewController

- (void)viewDidLoad{
    self.caseProducts = [[NSMutableArray alloc] init];
    NSArray *allProducts = [OLKitePrintSDK enabledProducts] ? [OLKitePrintSDK enabledProducts] : [OLProduct products];
    for (OLProduct *product in allProducts){
        if (product.productTemplate.templateClass == self.templateClass){
            [self.caseProducts insertObject:product atIndex:0];
        }
    }
    
    self.title = NSLocalizedString(@"Pick Device", @"");
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{    
    OLProduct *product = self.caseProducts[indexPath.row];
    
    OLSingleImageProductReviewViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"OLSingleImageProductReviewViewController"];
    vc.delegate = self.delegate;
    vc.assets = self.assets;
    vc.product = product;
    
    [self.navigationController pushViewController:vc animated:YES];
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"caseCell"];
    
    OLProduct *product = (OLProduct *)self.caseProducts[indexPath.row];
    
    UIImageView *imageView = (UIImageView *)[cell.contentView viewWithTag:10];
    NSString *imageName;
    if ([product.productTemplate.productCode hasSuffix:@"PHONE_4"]){
        imageName = @"cover-iphone4";
    }
    else if ([product.productTemplate.productCode hasSuffix:@"PHONE_5"]){
        imageName = @"cover-iphone5";
    }
    else if ([product.productTemplate.productCode hasSuffix:@"PHONE_5C"]){
        imageName = @"cover-iphone5c";
    }
    else if ([product.productTemplate.productCode hasSuffix:@"PHONE_6"]){
        imageName = @"cover-iphone6";
    }
    else if ([product.productTemplate.productCode hasSuffix:@"PHONE_6P"]){
        imageName = @"cover-iphone6plus";
    }
    imageView.image = [UIImage imageNamed:imageName];
    
    UITextView *textView = (UITextView *)[cell.contentView viewWithTag:20];
    textView.text = [product.productTemplate.name stringByReplacingOccurrencesOfString:@" Case" withString:@""];
    textView.backgroundColor = product.productTemplate.labelColor;
    
    UITextView *priceTextView = (UITextView *)[cell.contentView viewWithTag:30];
    priceTextView.text = product.unitCost;
    priceTextView.backgroundColor = product.productTemplate.labelColor;
    
    return cell;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.caseProducts.count;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 233 * [self screenWidthFactor];
}

@end
