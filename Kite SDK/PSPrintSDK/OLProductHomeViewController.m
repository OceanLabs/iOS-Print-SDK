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
#import "OLProductTypeSelectionViewController.h"
#import "OLProductTemplate.h"
#import "OLProduct.h"
#import "OLKiteViewController.h"
#import "OLKitePrintSDK.h"
#import "OLPosterSizeSelectionViewController.h"
#import "OLAnalytics.h"

@interface OLProduct (Private)

-(void)setCoverImageToImageView:(UIImageView *)imageView;
-(void)setClassImageToImageView:(UIImageView *)imageView;
-(void)setProductPhotography:(NSUInteger)i toImageView:(UIImageView *)imageView;

@end

@interface OLProductHomeViewController ()
@property (nonatomic, strong) NSMutableDictionary *templatesPerClass;
@property (nonatomic, strong) UIImageView *topSurpriseImageView;
@property (nonatomic, strong) UIView *huggleBotSpeechBubble;
@property (nonatomic, weak) IBOutlet UILabel *huggleBotFriendNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *letsStartLabel;
@property (nonatomic, assign) BOOL startHuggleBotOnViewWillAppear;
@end

@implementation OLProductHomeViewController

- (NSMutableDictionary *)templatesPerClass{
    if (!_templatesPerClass){
        _templatesPerClass = [[NSMutableDictionary alloc] init];
        NSArray *allProducts = [OLKitePrintSDK enabledProducts] ? [OLKitePrintSDK enabledProducts] : [OLProduct products];
        for (OLProduct *product in allProducts){
            if (!product.labelColor || product.productTemplate.templateUI == kOLTemplateUINA){
                continue;
            }
            if (![[_templatesPerClass allKeys] containsObject:product.productTemplate.templateClass]){
                [_templatesPerClass setObject:[[NSMutableArray alloc] init] forKey:product.productTemplate.templateClass];
                [_templatesPerClass[product.productTemplate.templateClass] addObject:product];
            }
            else{
                [_templatesPerClass[product.productTemplate.templateClass] addObject:product];
            }
        }
    }
    return _templatesPerClass;
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
    OLProduct *product = [[self.templatesPerClass allValues][indexPath.row] firstObject];
    if (product.productTemplate.templateUI == kOLTemplateUIPoster){
        OLPosterSizeSelectionViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"sizeSelect"];
        vc.assets = self.assets;
        vc.delegate = self.delegate;
        [self.navigationController pushViewController:vc animated:YES];
    }
    else if ([self.templatesPerClass[product.productTemplate.templateClass] count] > 1 && !(product.productTemplate.templateUI == kOLTemplateUIFrame)){
        OLProductTypeSelectionViewController *typeVc = [self.storyboard instantiateViewControllerWithIdentifier:@"OLTypeSelectionViewController"];
        typeVc.delegate = self.delegate;
        typeVc.assets = self.assets;
        typeVc.templateClass = product.productTemplate.templateClass;
        [self.navigationController pushViewController:typeVc animated:YES];
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
    return [self.templatesPerClass count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *identifier = @"ProductCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    UIImageView *cellImageView = (UIImageView *)[cell.contentView viewWithTag:40];

    OLProduct *product = [self.templatesPerClass[[self.templatesPerClass allKeys][indexPath.row]] firstObject];
    [product setClassImageToImageView:cellImageView];

    UILabel *productTypeLabel = (UILabel *)[cell.contentView viewWithTag:300];

    productTypeLabel.text = product.productTemplate.templateClass;

    productTypeLabel.backgroundColor = [product labelColor];

    UIActivityIndicatorView *activityIndicator = (id)[cell.contentView viewWithTag:41];
    [activityIndicator startAnimating];
    
    return cell;
}

#pragma mark - Autorotate and Orientation Methods

- (BOOL)shouldAutorotate {
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

@end
