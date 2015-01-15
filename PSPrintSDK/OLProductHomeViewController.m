//
//  ProductHomeViewController.m
//  Kite Print SDK
//
//  Created by Elliott Minns on 12/12/2013.
//  Copyright (c) 2013 Ocean Labs. All rights reserved.
//

#import "OLProductHomeViewController.h"
#import "OLProductOverviewViewController.h"
#import "UITableViewController+ScreenWidthFactor.h"

#import "OLProductTemplate.h"
#import "OLProduct.h"
#import "OLKiteViewController.h"
#import "OLKitePrintSDK.h"
#import "OLPosterSizeSelectionViewController.h"

@interface OLProductHomeViewController ()
@property (nonatomic, strong) NSArray *products;
@property (nonatomic, strong) UIImageView *topSurpriseImageView;
@property (nonatomic, strong) UIView *huggleBotSpeechBubble;
@property (nonatomic, weak) IBOutlet UILabel *huggleBotFriendNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *letsStartLabel;
@property (nonatomic, assign) BOOL startHuggleBotOnViewWillAppear;
@end

@implementation OLProductHomeViewController

-(NSArray *) products{
    if (!_products){
        _products = [OLKitePrintSDK enabledProducts] ? [OLKitePrintSDK enabledProducts] : [OLProduct products];
        NSMutableArray *mutableProducts = [_products mutableCopy];
        BOOL haveAtLeastOnePoster = NO;
        for (OLProduct *product in _products){
            if (!product.labelColor){
                [mutableProducts removeObject:product];
            }
            if (product.templateType == kOLTemplateTypePostcard){
                [mutableProducts removeObject:product];
            }
            if (product.templateType == kOLTemplateTypeFrame2x2 || product.templateType == kOLTemplateTypeFrame3x3 || product.templateType == kOLTemplateTypeFrame4x4){
                [mutableProducts removeObject:product];
            }
            if (product.templateType == kOLTemplateTypeLargeFormatA1 || product.templateType == kOLTemplateTypeLargeFormatA2 || product.templateType == kOLTemplateTypeLargeFormatA3){
                if (haveAtLeastOnePoster){
                    [mutableProducts removeObject:product];
                }
                else{
                    haveAtLeastOnePoster = YES;
                }
            }
        }
        _products = mutableProducts;
    }
    return _products;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Products", @"");
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [OLProductTemplate sync];
}

-(void)viewDidAppear:(BOOL)animated{
    if (self.navigationController){
        NSMutableArray *navigationStack = self.navigationController.viewControllers.mutableCopy;
        if (navigationStack.count > 1 && [navigationStack[navigationStack.count - 2] isKindOfClass:[OLKiteViewController class]]) {
            OLKiteViewController *kiteVc = navigationStack[navigationStack.count - 2];
            if (!kiteVc.presentingViewController){
                [navigationStack removeObject:kiteVc];
                self.navigationController.viewControllers = navigationStack;
            }
        }
    }
}

#pragma mark - UITableViewDelegate Methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 233 * [self screenWidthFactor];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    OLProduct *product = self.products[indexPath.row];
    if (product.templateType == kOLTemplateTypeLargeFormatA1 || product.templateType == kOLTemplateTypeLargeFormatA2 || product.templateType == kOLTemplateTypeLargeFormatA3){
        OLPosterSizeSelectionViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"sizeSelect"];
        vc.printOrder = self.printOrder;
        [self.navigationController pushViewController:vc animated:YES];
    }
    else{
        OLProductOverviewViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"OLProductOverviewViewController"];
        vc.printOrder = self.printOrder;
        vc.product = product;
        [self.navigationController pushViewController:vc animated:YES];
    }
    
}

#pragma mark - UITableViewDataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.products.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *identifier = @"ProductCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    UIImageView *cellImage = (UIImageView *)[cell.contentView viewWithTag:40];
    
    OLProduct *product = self.products[indexPath.row];
    [product setCoverImageToImageView:cellImage];
    
    UILabel *productTypeLabel = (UILabel *)[cell.contentView viewWithTag:300];
    if (product.templateType == kOLTemplateTypeLargeFormatA1 || product.templateType == kOLTemplateTypeLargeFormatA2 || product.templateType == kOLTemplateTypeLargeFormatA3){
        productTypeLabel.text = [NSLocalizedString(@"Posters", @"") uppercaseString];
    }
    else{
        productTypeLabel.text = [product.productTemplate.name uppercaseString];
    }
    productTypeLabel.backgroundColor = [product labelColor];
    
    return cell;
}

#pragma mark - Autorotate and Orientation Methods

- (BOOL)shouldAutorotate {
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

@end
