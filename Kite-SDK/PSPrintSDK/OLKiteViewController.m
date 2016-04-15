//
//  Modified MIT License
//
//  Copyright (c) 2010-2016 Kite Tech Ltd. https://www.kite.ly
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The software MAY ONLY be used with the Kite Tech Ltd platform and MAY NOT be modified
//  to be used with any competitor platforms. This means the software MAY NOT be modified
//  to place orders with any competitors to Kite Tech Ltd, all orders MUST go through the
//  Kite Tech Ltd platform servers.
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
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
#import "OLNavigationController.h"
#import "NSObject+Utils.h"
#import "OLKiteABTesting.h"
#import "UIImage+ColorAtPixel.h"
#import "OLKiteUtils.h"

#ifdef COCOAPODS
#import <SDWebImage/SDImageCache.h>
#else
#import "SDImageCache.h"
#endif


#ifdef OL_KITE_OFFER_CUSTOM_IMAGE_PROVIDERS
#import "OLCustomPhotoProvider.h"
#endif

static const NSInteger kTagNoProductsAlertView = 99;
static const NSInteger kTagTemplateSyncFailAlertView = 100;

static CGFloat fadeTime = 0.3;


@interface OLKiteViewController () <UIAlertViewDelegate>

@property (strong, nonatomic) NSArray *assets;
@property (strong, nonatomic) OLPrintOrder *printOrder;
@property (strong, nonatomic) NSMutableArray *userSelectedPhotos;
@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (weak, nonatomic) IBOutlet UINavigationItem *customNavigationItem;
@property (weak, nonatomic) IBOutlet UIImageView *loadingImageView;
#ifdef OL_KITE_OFFER_CUSTOM_IMAGE_PROVIDERS
@property (strong, nonatomic) NSMutableArray <OLCustomPhotoProvider *> *customImageProviders;
#endif


@property (assign, nonatomic) BOOL useDarkTheme; //XXX: Delete this when exposed in header

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

@property (weak, nonatomic) NSArray *userSelectedPhotos;
- (void)saveOrder;
+ (id)loadOrder;

@end

@class KITCustomAssetPickerController;
@class KITAssetCollectionDataSource;

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
    _printOrder.userSelectedPhotos = self.userSelectedPhotos;
    return _printOrder;
}

- (void)clearBasket{
    self.printOrder = [[OLPrintOrder alloc] init];
    [self.printOrder saveOrder];
}

- (void)setUseDarkTheme:(BOOL)useDarkTheme{
    _useDarkTheme = useDarkTheme;
    [OLKiteABTesting sharedInstance].darkTheme = useDarkTheme;
}

- (BOOL)prefersStatusBarHidden {
    BOOL hidden = self.useDarkTheme;
    
    if ([self respondsToSelector:@selector(traitCollection)]){
        if (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact && self.view.frame.size.height < self.view.frame.size.width){
            hidden |= YES;
        }
    }
    
    return hidden;
}

- (UIStatusBarStyle)preferredStatusBarStyle{
    if (self.childViewControllers.count == 0){
        return self.useDarkTheme ? UIStatusBarStyleLightContent : UIStatusBarStyleDefault;
    }
    return [[self.childViewControllers firstObject] preferredStatusBarStyle];
}

-(NSMutableArray *) userSelectedPhotos{
    if (!_userSelectedPhotos || _userSelectedPhotos.count == 0){
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
    NSAssert(![OLKiteUtils assetArrayContainsPDF:assets], @"If you want to use a pre-rendered PDF, please use initWithPrintOrder");
    
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
        self.printOrder.userData = info;
    }
    [OLKiteABTesting sharedInstance].launchedWithPrintOrder = NO;
    
    return self;
}

- (instancetype _Nullable)initWithPrintOrder:(OLPrintOrder *_Nullable)printOrder info:(NSDictionary * _Nullable)info{
    [OLAnalytics setExtraInfo:info];
    NSBundle *currentBundle = [NSBundle bundleForClass:[OLKiteViewController class]];
    if ((self = [[UIStoryboard storyboardWithName:@"OLKiteStoryboard" bundle:currentBundle] instantiateViewControllerWithIdentifier:@"KiteViewController"])) {
        self.printOrder = printOrder;
        self.printOrder.userData = info;
        self.assets = [[printOrder.jobs firstObject] assetsForUploading];
        [OLKiteABTesting sharedInstance].launchedWithPrintOrder = printOrder != nil;
    }
    return self;
}

- (void)addCustomPhotoProviderWithCollections:(NSArray <id<KITAssetCollectionDataSource>>*_Nonnull)collections name:(NSString *_Nonnull)name icon:(UIImage *_Nullable)image{
#ifdef OL_KITE_OFFER_CUSTOM_IMAGE_PROVIDERS
    if (!self.customImageProviders){
        self.customImageProviders = [[NSMutableArray<OLCustomPhotoProvider *> alloc] init];
    }
    [self.customImageProviders addObject:[[OLCustomPhotoProvider alloc] initWithCollections:collections name:name icon:image]];
#endif
}

- (void)addCustomPhotoProviderWithViewController:(UIViewController<KITCustomAssetPickerController> *_Nonnull)vc name:(NSString *_Nonnull)name icon:(UIImage *_Nullable)icon{
#ifdef OL_KITE_OFFER_CUSTOM_IMAGE_PROVIDERS
    if (!self.customImageProviders){
        self.customImageProviders = [[NSMutableArray<OLCustomPhotoProvider *> alloc] init];
    }
    [self.customImageProviders addObject:[[OLCustomPhotoProvider alloc] initWithController:vc name:name icon:icon]];
#endif
}

-(void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.useDarkTheme){
        self.navigationBar.barTintColor = [UIColor blackColor];
        self.navigationBar.tintColor = [UIColor grayColor];
        self.navigationBar.barStyle = UIBarStyleBlackTranslucent;
    }
    
    [SDImageCache sharedImageCache].maxMemoryCountLimit = 1;
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
    
    if ([OLKitePrintSDK environment] == kOLKitePrintSDKEnvironmentLive){
        [[self.view viewWithTag:9999] removeFromSuperview];
    }
    
    self.view.backgroundColor = [self.loadingImageView.image colorAtPixel:CGPointMake(3, 3)];
    
    if (![OLKitePrintSDK cacheTemplates]) {
        [OLProductTemplate deleteCachedTemplates];
        [OLProductTemplate resetTemplates];
    }
    
    if ([OLProductTemplate templates].count > 0){
        fadeTime = 0;
        [[OLKiteABTesting sharedInstance] setupABTestVariants];
        
        [self.operationQueue addOperation:self.templateSyncOperation];
        [self.operationQueue addOperation:self.remotePlistSyncOperation];
    }
    else{
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
        [OLProductTemplate sync];
    }
    
    [self transitionToNextScreen];
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
            BOOL containsPDF = [OLKiteUtils assetArrayContainsPDF:[[welf.printOrder.jobs firstObject] assetsForUploading]];
            OLProduct *product = [OLProduct productWithTemplateId:[[welf.printOrder.jobs firstObject] templateId]];
            NSString *identifier;
            if (!containsPDF && [[OLKiteABTesting sharedInstance].launchWithPrintOrderVariant hasPrefix:@"Overview-"] && [product isValidProductForUI]){
                identifier = @"OLProductOverviewViewController";
            }
            else if (!containsPDF && [[OLKiteABTesting sharedInstance].launchWithPrintOrderVariant hasPrefix:@"Review-"] && [product isValidProductForUI]){
                identifier = [OLKiteUtils reviewViewControllerIdentifierForProduct:product photoSelectionScreen:[OLKiteUtils imageProvidersAvailable:welf]];
            }
            else{
                [OLKiteUtils checkoutViewControllerForPrintOrder:welf.printOrder handler:^(id vc){
                    [vc safePerformSelector:@selector(setUserEmail:) withObject:welf.userEmail];
                    [vc safePerformSelector:@selector(setUserPhone:) withObject:welf.userPhone];
                    [vc safePerformSelector:@selector(setKiteDelegate:) withObject:welf.delegate];
                    if (self.navigationController.viewControllers.count <= 1){
                        UINavigationController *nvc = [[OLNavigationController alloc] initWithRootViewController:vc];
                        ((UIViewController *)vc).navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:welf action:@selector(dismiss)];
                        [welf fadeToViewController:nvc];
                    }
                    else{
                        [welf fadeToViewController:vc];
                    }
                    
                }];
                
                return;
            }
            UIViewController *vc = [welf.storyboard instantiateViewControllerWithIdentifier:identifier];
            [vc safePerformSelector:@selector(setUserEmail:) withObject:welf.userEmail];
            [vc safePerformSelector:@selector(setUserPhone:) withObject:welf.userPhone];
            [vc safePerformSelector:@selector(setKiteDelegate:) withObject:welf.delegate];
            [vc safePerformSelector:@selector(setProduct:) withObject:product];
            [vc safePerformSelector:@selector(setUserSelectedPhotos:) withObject:welf.userSelectedPhotos];
            if (self.navigationController.viewControllers.count <= 1){
                UINavigationController *nvc = [[OLNavigationController alloc] initWithRootViewController:vc];
                vc.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:welf action:@selector(dismiss)];
                [welf fadeToViewController:nvc];
            }
            else{
                [welf fadeToViewController:vc];
            }
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
        [vc safePerformSelector:@selector(setProduct:) withObject:product];
        [vc safePerformSelector:@selector(setDelegate:) withObject:welf.delegate];
        [vc safePerformSelector:@selector(setUserEmail:) withObject:welf.userEmail];
        [vc safePerformSelector:@selector(setUserPhone:) withObject:welf.userPhone];
        [vc safePerformSelector:@selector(setFilterProducts:) withObject:welf.filterProducts];
        [vc safePerformSelector:@selector(setUserSelectedPhotos:) withObject:welf.userSelectedPhotos];
        [vc safePerformSelector:@selector(setTemplateClass:) withObject:product.productTemplate.templateClass];
        if (self.navigationController.viewControllers.count <= 1){
            UINavigationController *nvc = [[OLNavigationController alloc] initWithRootViewController:vc];
            vc.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:welf action:@selector(dismiss)];
            [welf fadeToViewController:nvc];
        }
        else{
            [welf fadeToViewController:vc];
        }
        
        //Prefetch themed-SDK images
        [[OLKiteABTesting sharedInstance] prefetchRemoteImages];
    }];
    
    [OLAnalytics setKiteDelegate:self.delegate];
    
    [self.operationQueue addOperation:self.transitionOperation];
}

- (void)fadeToViewController:(UIViewController *)vc{
    [self addChildViewController:vc];
    vc.view.alpha = 0;
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
    
    
    [UIView animateWithDuration:fadeTime animations:^(void){
        vc.view.alpha = 1;
    } completion:^(BOOL b){
        [vc endAppearanceTransition];
        self.loadingImageView.image = nil;
    }];
    
}

- (void)templateSyncDidFinish:(NSNotification *)n{
    NSAssert([NSThread isMainThread], @"assumption about main thread callback is incorrect");
    if (n.userInfo[kNotificationKeyTemplateSyncError]){
        if (self.templateSyncOperation.finished){
            return;
        }
        
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
