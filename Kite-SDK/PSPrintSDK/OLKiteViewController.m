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
#import "OLProductTypeSelectionViewController.h"
#import "OLKitePrintSDK.h"
#import "OLAnalytics.h"
#import "OLPrintPhoto.h"
#import "OLProductGroup.h"
#import "OLCustomNavigationController.h"
#import "NSObject+Utils.h"
#import "OLKiteABTesting.h"
#import "UIImage+ColorAtPixel.h"
#import "OLKiteUtils.h"

static const NSInteger kTagNoProductsAlertView = 99;
static const NSInteger kTagTemplateSyncFailAlertView = 100;


@interface OLKiteViewController () <UIAlertViewDelegate>

@property (strong, nonatomic) NSArray *assets;
@property (strong, nonatomic) OLPrintOrder *printOrder;
@property (strong, nonatomic) NSMutableArray *userSelectedPhotos;
@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (weak, nonatomic) IBOutlet UINavigationItem *customNavigationItem;
@property (weak, nonatomic) IBOutlet UIImageView *loadingImageView;

// Because template sync happens in the constructor it may complete before the OLKiteViewController has appeared. In such a case where sync does
// complete first we make a note to immediately transition to the appropriate view when the OLKiteViewController does appear:
@property (strong, nonatomic) NSOperationQueue *operationQueue;
@property (strong, nonatomic) NSBlockOperation *templateSyncOperation;
@property (strong, nonatomic) NSBlockOperation *remotePlistSyncOperation;
@property (strong, nonatomic) NSBlockOperation *transitionOperation;

@end

@interface OLKitePrintSDK (Private)

+ (void)setCacheTemplates:(BOOL)cache;
+ (BOOL)cacheTemplates;

@end

@interface OLPrintOrder (Private)

- (void)saveOrder;
+ (id)loadOrder;

@end

@implementation OLKiteViewController

- (void)awakeFromNib{
    [super awakeFromNib];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(templateSyncDidFinish:) name:kNotificationTemplateSyncComplete object:nil];
}

-(OLPrintOrder *) printOrder{
    if (!_printOrder){
        _printOrder = [OLPrintOrder loadOrder];
    }
    if (!_printOrder){
        _printOrder = [[OLPrintOrder alloc] init];
    }
    return _printOrder;
}

- (void)clearBasket{
    self.printOrder = [[OLPrintOrder alloc] init];
    [self.printOrder saveOrder];
}

- (UIStatusBarStyle)preferredStatusBarStyle{
    return [[self.childViewControllers firstObject] preferredStatusBarStyle];
}

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

- (instancetype _Nullable)initWithAssets:(NSArray <OLAsset *>*_Nonnull)assets{
    return [self initWithAssets:assets info:nil];
}

- (instancetype _Nullable)initWithPrintOrder:(OLPrintOrder *_Nullable)printOrder{
    return [self initWithPrintOrder:printOrder info:nil];
}

- (instancetype _Nullable)initWithAssets:(NSArray <OLAsset *>*_Nonnull)assets info:(NSDictionary *_Nullable)info{
    [OLAnalytics setExtraInfo:info];
    NSBundle *currentBundle = [NSBundle bundleForClass:[OLKiteViewController class]];
    if ((self = [[UIStoryboard storyboardWithName:@"OLKiteStoryboard" bundle:currentBundle] instantiateViewControllerWithIdentifier:@"KiteViewController"])) {
        self.assets = assets;
    }
    
    return self;
}

- (instancetype _Nullable)initWithPrintOrder:(OLPrintOrder *_Nullable)printOrder info:(NSDictionary * _Nullable)info{
    [OLAnalytics setExtraInfo:info];
    NSBundle *currentBundle = [NSBundle bundleForClass:[OLKiteViewController class]];
    if ((self = [[UIStoryboard storyboardWithName:@"OLKiteStoryboard" bundle:currentBundle] instantiateViewControllerWithIdentifier:@"KiteViewController"])) {
        self.printOrder = printOrder;
        self.assets = [[printOrder.jobs firstObject] assetsForUploading];
        [OLKiteABTesting sharedInstance].launchedWithPrintOrder = printOrder != nil;
    }
    return self;
}

-(void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    
    if (!self.navigationController){
        self.navigationBar.hidden = NO;
    }
    
    
    if ([OLKiteABTesting sharedInstance].launchedWithPrintOrder){
        self.customNavigationItem.title = @"";
    }
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8) {
        [OLPrintPhoto calcScreenScaleForTraitCollection:self.traitCollection];
    }
    
    [OLAnalytics setKiteDelegate:self.delegate];
    
    self.operationQueue = [NSOperationQueue mainQueue];
    self.templateSyncOperation = [[NSBlockOperation alloc] init];
    self.remotePlistSyncOperation = [[NSBlockOperation alloc] init];
    self.transitionOperation = [[NSBlockOperation alloc] init];
    [self.transitionOperation addDependency:self.templateSyncOperation];
    [self.transitionOperation addDependency:self.remotePlistSyncOperation];
    
    [[OLKiteABTesting sharedInstance] fetchRemotePlistsWithCompletionHandler:^{
        [self.operationQueue addOperation:self.remotePlistSyncOperation];
        
#ifndef OL_NO_ANALYTICS
        if ([OLKiteABTesting sharedInstance].launchedWithPrintOrder){
            [OLAnalytics trackKiteViewControllerLoadedWithEntryPoint:[OLKiteABTesting sharedInstance].launchWithPrintOrderVariant];
        }
        else{
            [OLAnalytics trackKiteViewControllerLoadedWithEntryPoint:@"Home Screen"];
        }
#endif
    }];
    
    if ([OLKitePrintSDK environment] == kOLKitePrintSDKEnvironmentLive){
        [[self.view viewWithTag:9999] removeFromSuperview];
    }
    
    self.view.backgroundColor = [self.loadingImageView.image colorAtPixel:CGPointMake(3, 3)];
    
    [self transitionToNextScreen];
    
    if (![OLKitePrintSDK cacheTemplates]) {
        [OLProductTemplate deleteCachedTemplates];
        [OLProductTemplate resetTemplates];
    }
    [OLProductTemplate sync];
}

-(IBAction) dismiss{
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackKiteDismissed];
#endif
    if ([self.delegate respondsToSelector:@selector(kiteControllerDidFinish:)]){
        [self.delegate kiteControllerDidFinish:self];
    }
    else{
        [self dismissViewControllerAnimated:YES completion:^{}];
    }
}

- (void)transitionToNextScreen{
    __weak OLKiteViewController *welf = self;
    [self.transitionOperation addExecutionBlock:^{
        // The screen we transition to will depend on what products are available based on the developers filter preferences.
        NSArray *groups = [OLProductGroup groupsWithFilters:welf.filterProducts];
        
        NSBundle *currentBundle = [NSBundle bundleForClass:[OLKiteViewController class]];
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"OLKiteStoryboard" bundle:currentBundle];
        NSString *nextVcNavIdentifier;
        OLProduct *product;
        if (groups.count == 0 && !([OLProductTemplate templates].count != 0 && [OLKiteABTesting sharedInstance].launchedWithPrintOrder)) {
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
        else if ([OLKiteABTesting sharedInstance].launchedWithPrintOrder){
            OLProduct *product = [OLProduct productWithTemplateId:[[welf.printOrder.jobs firstObject] templateId]];
            NSString *identifier;
            if ([[OLKiteABTesting sharedInstance].launchWithPrintOrderVariant hasPrefix:@"Overview-"] && [product isValidProductForUI]){
                identifier = @"OLProductOverviewViewController";
            }
            else if ([[OLKiteABTesting sharedInstance].launchWithPrintOrderVariant hasPrefix:@"Review-"] && [product isValidProductForUI]){
                BOOL photoSelection = ![welf.delegate respondsToSelector:@selector(kiteControllerShouldAllowUserToAddMorePhotos:)];
                if (!photoSelection){
                    photoSelection = [welf.delegate kiteControllerShouldAllowUserToAddMorePhotos:welf];
                }
                identifier = [OLKiteUtils reviewViewControllerIdentifierForProduct:product photoSelectionScreen:photoSelection];
            }
            else{
                [OLKiteUtils checkoutViewControllerForPrintOrder:welf.printOrder handler:^(id vc){
                    [[vc navigationItem] setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:welf action:@selector(dismiss)]];
                    [vc safePerformSelector:@selector(setUserEmail:) withObject:welf.userEmail];
                    [vc safePerformSelector:@selector(setUserPhone:) withObject:welf.userPhone];
                    [vc safePerformSelector:@selector(setKiteDelegate:) withObject:welf.delegate];
                    OLCustomNavigationController *nvc = [[OLCustomNavigationController alloc] initWithRootViewController:vc];
                    
                    [welf fadeToViewController:nvc];
                }];
                
                return;
            }
            UIViewController *vc = [welf.storyboard instantiateViewControllerWithIdentifier:identifier];
            [vc safePerformSelector:@selector(setUserEmail:) withObject:welf.userEmail];
            [vc safePerformSelector:@selector(setUserPhone:) withObject:welf.userPhone];
            [vc safePerformSelector:@selector(setKiteDelegate:) withObject:welf.delegate];
            [vc safePerformSelector:@selector(setProduct:) withObject:product];
            [vc safePerformSelector:@selector(setUserSelectedPhotos:) withObject:welf.userSelectedPhotos];
            
            [[vc navigationItem] setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:welf action:@selector(dismiss)]];
            [vc.navigationItem.rightBarButtonItem setTitle:NSLocalizedString(@"Next", @"")];
            OLCustomNavigationController *nvc = [[OLCustomNavigationController alloc] initWithRootViewController:vc];
            [welf fadeToViewController:nvc];
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
        [welf fadeToViewController:nav];
        
        //Prefetch themed-SDK images
        [[OLKiteABTesting sharedInstance] prefetchRemoteImages];
    }];
    
    [OLAnalytics setKiteDelegate:self.delegate];

    [self.operationQueue addOperation:self.transitionOperation];
}

- (void)fadeToViewController:(UIViewController *)vc{
    vc.view.alpha = 0;
    [self addChildViewController:vc];
    [vc beginAppearanceTransition: YES animated: YES];
    [self.view addSubview:vc.view];
    
    UIView *view = vc.view;
    
    view.translatesAutoresizingMaskIntoConstraints = NO;
    NSDictionary *views = NSDictionaryOfVariableBindings(view);
    NSMutableArray *con = [[NSMutableArray alloc] init];
    
    NSArray *visuals = @[@"H:|-0-[view]-0-|",
                         @"V:|-0-[view]-0-|"];
    
    
    for (NSString *visual in visuals) {
        [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
    }
    
    [view.superview addConstraints:con];

    
    [UIView animateWithDuration:0.3 animations:^(void){
        vc.view.alpha = 1;
    } completion:^(BOOL b){
        [vc endAppearanceTransition];
    }];
    
}

- (void)templateSyncDidFinish:(NSNotification *)n{
    NSAssert([NSThread isMainThread], @"assumption about main thread callback is incorrect");
    if (n.userInfo[kNotificationKeyTemplateSyncError]){
        if ([[OLProductTemplate templates] count] > 0){
            [self.operationQueue addOperation:self.templateSyncOperation];
            return;
        }
        
        NSError *error = n.userInfo[kNotificationKeyTemplateSyncError];
        NSString *message = NSLocalizedString(@"There was a problem getting Print Shop products. Check your Internet connectivity or try again later.", @"");
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

- (NSArray *)viewControllers{
    return [(UINavigationController *)self.childViewControllers.firstObject viewControllers];
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
    if (group.products.count > 1){
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

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8) {
        return UIInterfaceOrientationMaskAll;
    }
    else{
        return UIInterfaceOrientationMaskPortrait;
    }
}

@end
