//
//  KiteViewController.m
//  Kite Print SDK
//
//  Created by Konstadinos Karayannis on 12/24/14.
//  Copyright (c) 2014 Deon Botha. All rights reserved.
//

#import "OLKiteViewController.h"
#import "OLPrintOrder.h"
#import "OLProductTemplate.h"
#import "OLProductHomeViewController.h"
#import "OLKitePrintSDK.h"
#import "OLProduct.h"
#import "OLProductOverviewViewController.h"
#import "OLPosterSizeSelectionViewController.h"
#import "OLProductTypeSelectionViewController.h"
#import "OLKitePrintSDK.h"
#import "OLAnalytics.h"
#import "OLPrintPhoto.h"
#import "OLProductGroup.h"
#import "OLCustomNavigationController.h"
#import "NSObject+Utils.h"
#import <SkyLab.h>

static const NSInteger kTagNoProductsAlertView = 99;
static const NSInteger kTagTemplateSyncFailAlertView = 100;
static NSString *const kOLKiteABTestProductDescriptionWithPrintOrder = @"kOLKiteABTestProductDescriptionWithPrintOrder";
static NSString *const kOLKiteABTestHidePrice = @"kOLKiteABTestHidePrice";

@interface OLKiteViewController () <UIAlertViewDelegate>

@property (strong, nonatomic) NSArray *assets;
@property (strong, nonatomic) OLPrintOrder *printOrder;
@property (strong, nonatomic) NSMutableArray *userSelectedPhotos;
@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;

// Because template sync happens in the constructor it may complete before the OLKiteViewController has appeared. In such a case where sync does
// complete first we make a note to immediately transition to the appropriate view when the OLKiteViewController does appear:
@property (strong, nonatomic) NSOperationQueue *operationQueue;
@property (strong, nonatomic) NSBlockOperation *templateSyncOperation;
@property (strong, nonatomic) NSBlockOperation *remotePlistSyncOperation;
@property (strong, nonatomic) NSBlockOperation *transitionOperation;
@property (assign, nonatomic) BOOL showProductDescriptionWithPrintOrder;
@property (assign, nonatomic) BOOL hidePrice;

@end

@interface OLKitePrintSDK (Private)

+ (void)setCacheTemplates:(BOOL)cache;
+ (BOOL)cacheTemplates;
+ (void)fetchRemotePlistsWithCompletionHandler:(void(^)())handler;

@end

@implementation OLKiteViewController

-(NSMutableArray *) userSelectedPhotos{
    if (!_userSelectedPhotos){
        NSMutableArray *mutableUserSelectedPhotos = [[NSMutableArray alloc] init];
        for (id asset in self.assets){
            OLPrintPhoto *printPhoto = [[OLPrintPhoto alloc] init];
            printPhoto.asset = asset;
            [mutableUserSelectedPhotos addObject:printPhoto];
        }
        _userSelectedPhotos = mutableUserSelectedPhotos;
    }
    return _userSelectedPhotos;
}

- (id)initWithAssets:(NSArray *)assets {
    NSAssert(assets != nil && [assets count] > 0, @"KiteViewController requires assets to print");
    if ((self = [[UIStoryboard storyboardWithName:@"OLKiteStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"KiteViewController"])) {
        self.assets = assets;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(templateSyncDidFinish:) name:kNotificationTemplateSyncComplete object:nil];
    }
    
    return self;
}

- (id)initWithPrintOrder:(OLPrintOrder *)printOrder{
    if ((self = [[UIStoryboard storyboardWithName:@"OLKiteStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"KiteViewController"])) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(templateSyncDidFinish:) name:kNotificationTemplateSyncComplete object:nil];
        self.printOrder = printOrder;
    }
    return self;
}

- (void)setupABTestVariants {
    NSDictionary *experimentDict = [[NSUserDefaults standardUserDefaults] objectForKey:kOLKiteABTestProductDescriptionWithPrintOrder];
    if (!experimentDict) {
        experimentDict = @{@"Yes" : @0.5, @"No" : @0.5};
    }
    [SkyLab splitTestWithName:kOLKiteABTestProductDescriptionWithPrintOrder
                   conditions:@{
                                @"Yes" : experimentDict[@"Yes"],
                                @"No" : experimentDict[@"No"]
                                } block:^(id choice) {
                                    self.showProductDescriptionWithPrintOrder = [choice isEqualToString:@"Yes"];
                                }];
    
    experimentDict = [[NSUserDefaults standardUserDefaults] objectForKey:kOLKiteABTestHidePrice];
    if (!experimentDict) {
        experimentDict = @{@"Yes" : @0.5, @"No" : @0.5};
    }
    [SkyLab splitTestWithName:kOLKiteABTestHidePrice
                   conditions:@{
                                @"Yes" : experimentDict[@"Yes"],
                                @"No" : experimentDict[@"No"]
                                } block:^(id choice) {
                                    self.hidePrice = [choice isEqualToString:@"Yes"];
                                }];
}

-(void)viewDidLoad {
    [super viewDidLoad];
    
    if (!self.navigationController){
        self.navigationBar.hidden = NO;
    }
    
    if (self.printOrder){
        self.navigationBar.hidden = YES;
    }
    
    self.operationQueue = [[NSOperationQueue alloc] init];
    self.templateSyncOperation = [[NSBlockOperation alloc] init];
    self.remotePlistSyncOperation = [[NSBlockOperation alloc] init];
    self.transitionOperation = [[NSBlockOperation alloc] init];
    [self.transitionOperation addDependency:self.templateSyncOperation];
    [self.transitionOperation addDependency:self.remotePlistSyncOperation];
    
    [OLKitePrintSDK fetchRemotePlistsWithCompletionHandler:^(NSError *error){
        [self setupABTestVariants];
#ifndef OL_NO_ANALYTICS
        if (self.printOrder && !self.showProductDescriptionWithPrintOrder){
            [OLAnalytics trackKiteViewControllerLoadedWithEntryPoint:@"Shipping Screen"];
        }
        else if(self.printOrder && self.showProductDescriptionWithPrintOrder){
            [OLAnalytics trackKiteViewControllerLoadedWithEntryPoint:@"Product Description Screen"];
        }
        else{
            [OLAnalytics trackKiteViewControllerLoadedWithEntryPoint:@"Home Screen"];
        }
#endif
        [self.operationQueue addOperation:self.remotePlistSyncOperation];
    }];
    
    if ([OLKitePrintSDK environment] == kOLKitePrintSDKEnvironmentLive){
        [[self.view viewWithTag:9999] removeFromSuperview];
    }
    
    [self transitionToNextScreen];
}

- (void)viewWillAppear:(BOOL)animated {
    if (![OLKitePrintSDK cacheTemplates]) {
        [OLProductTemplate deleteCachedTemplates];
        [OLProductTemplate resetTemplates];
    }
    [OLProductTemplate sync];
}

-(IBAction) dismiss{
        [self dismissViewControllerAnimated:YES completion:^{}];
}

- (void)transitionToNextScreen{
    __weak OLKiteViewController *welf = self;
    [self.transitionOperation addExecutionBlock:^{
        // The screen we transition to will depend on what products are available based on the developers filter preferences.
        NSArray *groups = [OLProductGroup groupsWithFilters:welf.filterProducts];
        
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"OLKiteStoryboard" bundle:nil];
        NSString *nextVcNavIdentifier;
        OLProduct *product;
        if (groups.count == 0) {
            if ([UIAlertController class]){
                UIAlertController *ac = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Store Maintenance", @"") message:NSLocalizedString(@"Our store is currently undergoing maintence so no products are available for purchase at this time. Please try again a little later.", @"") preferredStyle:UIAlertControllerStyleAlert];
                [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    [welf dismiss];
                }]];
                [welf presentViewController:ac animated:YES completion:NULL];
            }
            else{
                UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Store Maintenance", @"") message:NSLocalizedString(@"Our store is currently undergoing maintence so no products are available for purchase at this time. Please try again a little later.", @"") delegate:welf cancelButtonTitle:NSLocalizedString(@"OK", @"")  otherButtonTitles:nil];
                av.tag = kTagNoProductsAlertView;
                av.delegate = welf;
                [av show];
            }
            return;
        }
        else if (welf.printOrder && !welf.showProductDescriptionWithPrintOrder){
            OLCheckoutViewController *vc = [[OLCheckoutViewController alloc] initWithPrintOrder:welf.printOrder];
            [[vc navigationItem] setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:welf action:@selector(dismiss)]];
            vc.userEmail = welf.userEmail;
            vc.userPhone = welf.userPhone;
            vc.kiteDelegate = welf.delegate;
            OLCustomNavigationController *nvc = [[OLCustomNavigationController alloc] initWithRootViewController:vc];
            dispatch_async(dispatch_get_main_queue(), ^{
                [welf fadeToViewController:nvc];
            });
            return;
        }
        else if (welf.printOrder && welf.showProductDescriptionWithPrintOrder){
            OLProductOverviewViewController *vc = [welf.storyboard instantiateViewControllerWithIdentifier:@"OLProductOverviewViewController"];
            vc.product = [OLProduct productWithTemplateId:[[welf.printOrder.jobs firstObject] templateId]];
            vc.userEmail = welf.userEmail;
            vc.userPhone = welf.userPhone;
            vc.delegate = welf.delegate;
            [[vc navigationItem] setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:welf action:@selector(dismiss)]];
            [vc.navigationItem.rightBarButtonItem setTitle:NSLocalizedString(@"Next", @"")];
            OLCustomNavigationController *nvc = [[OLCustomNavigationController alloc] initWithRootViewController:vc];
            dispatch_async(dispatch_get_main_queue(), ^{
                [welf fadeToViewController:nvc];
            });
            return;
        }
        else if (groups.count == 1) {
            OLProductGroup *group = groups[0];
            product = [group.products firstObject];
            nextVcNavIdentifier = [OLKiteViewController storyboardIdentifierForGroupSelected:group];
        }
        else {
            // Launch the product home view controller where the top level groups will be displayed
            nextVcNavIdentifier = @"ProductHomeViewController";
        }
        UIViewController *vc = [sb instantiateViewControllerWithIdentifier:nextVcNavIdentifier];
        UINavigationController *nav = [[OLCustomNavigationController alloc] initWithRootViewController:vc];
        [vc safePerformSelector:@selector(setProduct:) withObject:product];
        [vc safePerformSelector:@selector(setDelegate:) withObject:welf.delegate];
        [vc safePerformSelector:@selector(setUserEmail:) withObject:welf.userEmail];
        [vc safePerformSelector:@selector(setUserPhone:) withObject:welf.userPhone];
        [vc safePerformSelector:@selector(setFilterProducts:) withObject:welf.filterProducts];
        [vc safePerformSelector:@selector(setUserSelectedPhotos:) withObject:welf.userSelectedPhotos];
        [vc safePerformSelector:@selector(setTemplateClass:) withObject:product.productTemplate.templateClass];
        [[vc navigationItem] setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:welf action:@selector(dismiss)]];
        dispatch_async(dispatch_get_main_queue(), ^{
            [welf fadeToViewController:nav];
        });
    }];
    [self.operationQueue addOperation:self.transitionOperation];
}

- (void)fadeToViewController:(UIViewController *)vc{
    vc.view.alpha = 0;
    [self addChildViewController:vc];
    [self.view addSubview:vc.view];
    [UIView animateWithDuration:0.3 animations:^(void){
        vc.view.alpha = 1;
    } completion:^(BOOL b){}];
    
}

- (void)templateSyncDidFinish:(NSNotification *)n{
    if (n.userInfo[kNotificationKeyTemplateSyncError]){
        if ([[OLProductTemplate templates] count] > 0){
            return;
        }
        
        NSError *error = n.userInfo[kNotificationKeyTemplateSyncError];
        NSString *message = NSLocalizedString(@"There was problem getting Print Shop products. Check your Internet connectivity or try again later.", @"");
        if (error.code == kOLKiteSDKErrorCodeMaintenanceMode) {
            message = kOLKiteSDKErrorMessageMaintenanceMode;
        }
        
        if ([UIAlertController class]){
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:message preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action){
                [self dismiss];
            }]];
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Retry", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
                [OLProductTemplate sync];
            }]];
            [self presentViewController:alert animated:YES completion:^(void){}];
        }
        else{
            UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"" message:message delegate:self cancelButtonTitle:NSLocalizedString(@"Retry", @"")  otherButtonTitles:NSLocalizedString(@"Cancel", @""), nil];
            av.tag = kTagTemplateSyncFailAlertView;
            av.delegate = self;
            [av show];
        }
    }
    
    else{
        if (!self.templateSyncOperation.finished){
            [self.operationQueue addOperation:self.templateSyncOperation];
        }
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == kTagTemplateSyncFailAlertView) {
        if (buttonIndex == 0){
            [OLProductTemplate sync];
        }
        else{
            [self dismiss];
        }
    } else if (alertView.tag == kTagNoProductsAlertView) {
        [self dismiss];
    }
}

+ (NSString *)storyboardIdentifierForGroupSelected:(OLProductGroup *)group{
    OLProduct *product = [group.products firstObject];
    if (product.productTemplate.templateUI == kOLTemplateUIPoster && group.products.count > 1) {
        return @"sizeSelect";
    }
    else if (group.products.count > 1){
        return @"OLTypeSelectionViewController";
    }
    else {
        return @"OLProductOverviewViewController";
    }
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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

- (NSUInteger)supportedInterfaceOrientations {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8) {
        return UIInterfaceOrientationMaskAll;
    }
    else{
        return UIInterfaceOrientationMaskPortrait;
    }
}

@end
