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
#import "OLProductGroup.h"
#import "NSObject+Utils.h"

@interface OLProduct (Private)

-(void)setCoverImageToImageView:(UIImageView *)imageView;
-(void)setClassImageToImageView:(UIImageView *)imageView;
-(void)setProductPhotography:(NSUInteger)i toImageView:(UIImageView *)imageView;

@end

@interface OLKiteViewController (Private)

+ (NSString *)storyboardIdentifierForGroupSelected:(OLProductGroup *)group;

@end

@interface OLProductHomeViewController ()
@property (nonatomic, strong) NSArray *productGroups;
@property (nonatomic, strong) UIImageView *topSurpriseImageView;
@property (nonatomic, strong) UIView *huggleBotSpeechBubble;
@property (nonatomic, weak) IBOutlet UILabel *huggleBotFriendNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *letsStartLabel;
@property (nonatomic, assign) BOOL startHuggleBotOnViewWillAppear;
@end

@implementation OLProductHomeViewController

- (NSArray *)productGroups {
    if (!_productGroups){
        _productGroups = [OLProductGroup groupsWithFilters:self.filterProducts];
    }
    
    return _productGroups;
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
    /*****
     * Ugly reminder that if new OLTemplateUI values are added then we need to update below AND in OLKiteViewController transitionToNextScreen: -- Yuck.
     * Heck if you're changing the below think carefully as you may need to change OLKiteViewController too!
     *****/
    OLProductGroup *group = self.productGroups[indexPath.row];
    OLProduct *product = [group.products firstObject];
    NSString *identifier = [OLKiteViewController storyboardIdentifierForGroupSelected:group];
    
    id vc = [self.storyboard instantiateViewControllerWithIdentifier:identifier];
    [vc safePerformSelector:@selector(setAssets:) withObject:self.assets];
    [vc safePerformSelector:@selector(setUserSelectedPhotos:) withObject:self.userSelectedPhotos];
    [vc safePerformSelector:@selector(setDelegate:) withObject:self.delegate];
    [vc safePerformSelector:@selector(setFilterProducts:) withObject:self.filterProducts];
    [vc safePerformSelector:@selector(setTemplateClass:) withObject:product.productTemplate.templateClass];
    [vc safePerformSelector:@selector(setProduct:) withObject:product];
    
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - UITableViewDataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.productGroups count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *identifier = @"ProductCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    UIImageView *cellImageView = (UIImageView *)[cell.contentView viewWithTag:40];

    OLProductGroup *group = self.productGroups[indexPath.row];
    OLProduct *product = [group.products firstObject];
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
