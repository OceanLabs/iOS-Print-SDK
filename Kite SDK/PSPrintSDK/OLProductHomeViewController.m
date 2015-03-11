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
#import "OLCaseSelectionViewController.h"
#import "OLProductTemplate.h"
#import "OLProduct.h"
#import "OLKiteViewController.h"
#import "OLKitePrintSDK.h"
#import "OLPosterSizeSelectionViewController.h"
#import "OLAnalytics.h"

@interface OLProduct (Private)

-(void)setCoverImageToImageView:(UIImageView *)imageView;
-(void)setProductPhotography:(NSUInteger)i toImageView:(UIImageView *)imageView;

@end

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
        BOOL haveAtLeastOneFrame = NO;
        BOOL haveAtLeastOneCase = NO;
        BOOL haveAtLeastOneDecal = NO;
        for (OLProduct *product in _products){
            if (!product.labelColor){
                [mutableProducts removeObject:product];
            }
            if (product.productTemplate.templateClass == kOLTemplateClassNA){
                [mutableProducts removeObject:product];
            }
            if (product.productTemplate.templateClass == kOLTemplateClassFrame){
                if (haveAtLeastOneFrame){
                    [mutableProducts removeObject:product];
                }
                else{
                    haveAtLeastOneFrame = YES;
                }
            }
            if (product.productTemplate.templateClass == kOLTemplateClassPoster){
                if (haveAtLeastOnePoster){
                    [mutableProducts removeObject:product];
                }
                else{
                    haveAtLeastOnePoster = YES;
                }
            }
            if (product.productTemplate.templateClass == kOLTemplateClassCase){
                if (haveAtLeastOneCase){
                    [mutableProducts removeObject:product];
                }
                else{
                    haveAtLeastOneCase = YES;
                }
            }
            if (product.productTemplate.templateClass == kOLTemplateClassDecal){
                if (haveAtLeastOneDecal){
                    [mutableProducts removeObject:product];
                }
                else{
                    haveAtLeastOneDecal = YES;
                }
            }
        }
        _products = mutableProducts;
    }
    return _products;
}

- (void)viewDidLoad {
    [super viewDidLoad];

#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackProductSelectionScreenViewed];
#endif

    self.title = NSLocalizedString(@"Print Shop", @"");
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
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
    if ([self tableView:tableView numberOfRowsInSection:indexPath.section] == 2){
        return (self.view.bounds.size.height - 64) / 2;
    }
    else{
        return 233 * [self screenWidthFactor];
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    OLProduct *product = self.products[indexPath.row];
    if (product.productTemplate.templateClass == kOLTemplateClassPoster){
        OLPosterSizeSelectionViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"sizeSelect"];
        vc.assets = self.assets;
        vc.delegate = self.delegate;
        [self.navigationController pushViewController:vc animated:YES];
    }
    else if (product.productTemplate.templateClass == kOLTemplateClassCase || product.productTemplate.templateClass == kOLTemplateClassDecal){
        OLCaseSelectionViewController *caseVc = [self.storyboard instantiateViewControllerWithIdentifier:@"OLCaseSelectionViewController"];
        caseVc.delegate = self.delegate;
        caseVc.assets = self.assets;
        caseVc.templateClass = product.productTemplate.templateClass;
        [self.navigationController pushViewController:caseVc animated:YES];
    }
    else{
        OLProductOverviewViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"OLProductOverviewViewController"];
        vc.assets = self.assets;
        vc.product = product;
        vc.delegate = self.delegate;
        [self.navigationController pushViewController:vc animated:YES];
    }
}

#pragma mark - UITableViewDataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.products count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *identifier = @"ProductCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    UIImageView *cellImageView = (UIImageView *)[cell.contentView viewWithTag:40];
    
    OLProduct *product = self.products[indexPath.row];
    [product setCoverImageToImageView:cellImageView];
    
    UILabel *productTypeLabel = (UILabel *)[cell.contentView viewWithTag:300];
    if (product.productTemplate.templateClass == kOLTemplateClassPoster){
        productTypeLabel.text = NSLocalizedString(@"Posters", @"");
    }
    else if (product.productTemplate.templateClass == kOLTemplateClassFrame){
        productTypeLabel.text = NSLocalizedString(@"Frames", @"");
    }
    else if (product.productTemplate.templateClass == kOLTemplateClassCase){
        productTypeLabel.text = NSLocalizedString(@"Phone Cases", @"");
    }
    else if (product.productTemplate.templateClass == kOLTemplateClassDecal){
        productTypeLabel.text = NSLocalizedString(@"Cases & Stickers", @"");
    }
    else{
        productTypeLabel.text = product.productTemplate.name;
    }
    productTypeLabel.backgroundColor = [product labelColor];
    
    UIActivityIndicatorView *activityIndicator = (id)[cell.contentView viewWithTag:41];
    [activityIndicator startAnimating];
    
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
