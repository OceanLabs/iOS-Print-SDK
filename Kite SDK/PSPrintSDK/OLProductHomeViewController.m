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
#import "OLAnalytics.h"

@interface OLProductHomeViewController ()
@property (nonatomic, strong) UIImageView *topSurpriseImageView;
@property (nonatomic, strong) UIView *huggleBotSpeechBubble;
@property (nonatomic, weak) IBOutlet UILabel *huggleBotFriendNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *letsStartLabel;
@property (nonatomic, assign) BOOL startHuggleBotOnViewWillAppear;
@end

@implementation OLProductHomeViewController

static NSArray *products;

+(NSArray *) products{
    if (!products){
        products = [OLKitePrintSDK enabledProducts] ? [OLKitePrintSDK enabledProducts] : [OLProduct products];
        NSMutableArray *mutableProducts = [products mutableCopy];
        BOOL haveAtLeastOnePoster = NO;
        BOOL haveAtLeastOneFrame = NO;
        for (OLProduct *product in products){
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
        }
        products = mutableProducts;
    }
    return products;
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
    return 233 * self.view.bounds.size.width / 320.0;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    OLProduct *product = [OLProductHomeViewController products][indexPath.row];
    if (product.productTemplate.templateClass == kOLTemplateClassPoster){
        UINavigationController *vc = (UINavigationController *)[self.storyboard instantiateViewControllerWithIdentifier:@"sizeSelectNavigationController"];
        ((OLPosterSizeSelectionViewController *)vc.topViewController).assets = self.assets;
        ((OLPosterSizeSelectionViewController *)vc.topViewController).delegate = self.delegate;
        [self showDetailViewController:vc sender:nil];

//        [self.navigationController pushViewController:vc animated:YES];
    }
    else{
        UINavigationController *nvc = (UINavigationController *)[self.storyboard instantiateViewControllerWithIdentifier:@"OLProductOverviewNavigationViewController"];
        OLProductOverviewViewController *vc = (OLProductOverviewViewController *)[nvc topViewController];
        vc.assets = self.assets;
        vc.product = product;
        vc.delegate = self.delegate;
        [self showDetailViewController:nvc sender:nil];
//        [self.navigationController pushViewController:vc animated:YES];
    }
    
}

#pragma mark - UITableViewDataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[OLProductHomeViewController products] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *identifier = @"ProductCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    UIImageView *cellImageView = (UIImageView *)[cell.contentView viewWithTag:40];
    
    OLProduct *product = [OLProductHomeViewController products][indexPath.row];
    [product setCoverImageToImageView:cellImageView];
    
    UILabel *productTypeLabel = (UILabel *)[cell.contentView viewWithTag:300];
    if (product.productTemplate.templateClass == kOLTemplateClassPoster){
        productTypeLabel.text = [NSLocalizedString(@"Posters", @"") uppercaseString];
    }
    else if (product.productTemplate.templateClass == kOLTemplateClassFrame){
        productTypeLabel.text = [NSLocalizedString(@"Frames", @"") uppercaseString];
    }
    else{
        productTypeLabel.text = [product.productTemplate.name uppercaseString];
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
