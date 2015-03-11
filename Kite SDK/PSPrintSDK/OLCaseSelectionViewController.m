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
#import "OLProductOverviewViewController.h"

@interface OLProduct (Private)

-(void)setCoverImageToImageView:(UIImageView *)imageView;
-(void)setProductPhotography:(NSUInteger)i toImageView:(UIImageView *)imageView;

@end

@interface OLCaseSelectionViewController ()

@property (strong, nonatomic) NSMutableArray *caseProducts;

@end

@implementation OLCaseSelectionViewController

- (void)viewDidLoad{
    self.caseProducts = [[NSMutableArray alloc] init];
    NSArray *allProducts = [OLKitePrintSDK enabledProducts] ? [OLKitePrintSDK enabledProducts] : [OLProduct products];
    for (OLProduct *product in allProducts){
        if (product.productTemplate.templateClass == self.templateClass){
            [self.caseProducts addObject:product];
        }
    }
    
    self.title = NSLocalizedString(@"Choose Device", @"");
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", @"")
                                                                             style:UIBarButtonItemStyleBordered
                                                                            target:nil
                                                                            action:nil];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{    
    OLProduct *product = self.caseProducts[indexPath.row];
    
    OLProductOverviewViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"OLProductOverviewViewController"];
    vc.delegate = self.delegate;
    vc.assets = self.assets;
    vc.product = product;
    
    [self.navigationController pushViewController:vc animated:YES];
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"caseCell"];
    
    OLProduct *product = (OLProduct *)self.caseProducts[indexPath.row];
    
    UIImageView *imageView = (UIImageView *)[cell.contentView viewWithTag:10];
    [product setCoverImageToImageView:imageView];
    
    UITextView *textView = (UITextView *)[cell.contentView viewWithTag:20];
    NSString *productName = [product.productTemplate.name stringByReplacingOccurrencesOfString:@" Clear Case Decals Only" withString:@""];
    productName = [productName stringByReplacingOccurrencesOfString:@" Clear Case and Decals" withString:@""];
    productName = [productName stringByReplacingOccurrencesOfString:@" Clear Decals" withString:@""];
    productName = [productName stringByReplacingOccurrencesOfString:@" Case" withString:@""];
    textView.text = productName;
    textView.backgroundColor = product.productTemplate.labelColor;
    
    return cell;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.caseProducts.count;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if ([self tableView:tableView numberOfRowsInSection:indexPath.section] == 2){
        return (self.view.bounds.size.height - 64) / 2;
    }
    else{
        return 233 * [self screenWidthFactor];
    }
}

@end
