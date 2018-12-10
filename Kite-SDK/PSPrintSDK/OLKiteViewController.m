//
//  Modified MIT License
//
//  Copyright (c) 2010-2017 Kite Tech Ltd. https://www.kite.ly
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

#import "NSObject+Utils.h"
#import "OLAnalytics.h"
#import "OLAsset+Private.h"
#import "OLCustomViewControllerPhotoProvider.h"
#import "OLImageDownloader.h"
#import "OLImagePickerViewController.h"
#import "OLKiteABTesting.h"
#import "OLKitePrintSDK.h"
#import "OLKiteUtils.h"
#import "OLKiteViewController.h"
#import "OLNavigationController.h"
#import "OLProduct.h"
#import "OLProductGroup.h"
#import "OLProductHomeViewController.h"
#import "OLProductOverviewViewController.h"
#import "OLProductTemplate.h"
#import "OLProductTypeSelectionViewController.h"
#import "OLUserSession.h"
#import "UIImage+OLUtils.h"
#import "UIImage+ImageNamedInKiteBundle.h"
#import "OLCaseViewController.h"
#import "OLSingleImagePosterViewController.h"
#import "OL3DProductViewController.h"
#import "OLApparelViewController.h"
#import "OLCollagePosterViewController.h"
#import "OLLogoutViewController.h"
#import "OLKioskLandingViewController.h"

@import Photobook;

static CGFloat fadeTime = 0.3;


@interface OLKiteViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *loadingImageView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingActivityIndicator;
@property (strong, nonatomic) NSMutableArray <OLImagePickerProvider *> *customImageProviders;
@property (strong, nonatomic) NSArray *fontNames;
@property (strong, nonatomic) NSTimer *timer;
@property (strong, nonatomic) NSDate *lastTouchDate;
@property (weak, nonatomic) UIViewController *lastTouchedViewController;
@property (assign, nonatomic) BOOL dismissing;

// Because template sync happens in the constructor it may complete before the OLKiteViewController has appeared. In such a case where sync does
// complete first we make a note to immediately transition to the appropriate view when the OLKiteViewController does appear:
@property (strong, nonatomic) NSOperationQueue *operationQueue;
@property (strong, nonatomic) NSBlockOperation *templateSyncOperation;
@property (strong, nonatomic) NSBlockOperation *remotePlistSyncOperation;
@property (strong, nonatomic) NSBlockOperation *remoteThemePlistSyncOperation;
@property (strong, nonatomic) NSBlockOperation *transitionOperation;

@property (copy, nonatomic) void (^loadingHandler)(void);

@end

@protocol OLCustomPickerController;

@implementation OLKiteViewController

-(NSMutableArray *) customImageProviders{
    if (!_customImageProviders){
        _customImageProviders = [[NSMutableArray alloc] init];
    }
    return _customImageProviders;
}

- (void)setShowPrintAtHome:(BOOL)showPrintAtHome{
    _showPrintAtHome = showPrintAtHome;
    
    NSMutableDictionary *dict = [[OLAnalytics extraInfo] mutableCopy];
    if (!dict){
        dict = [[NSMutableDictionary alloc] init];
    }
    dict[@"Launched With Print At Home Tile Enabled"] = [NSNumber numberWithBool:showPrintAtHome];
    [OLAnalytics setExtraInfo:dict];
}

- (void)awakeFromNib{
    [super awakeFromNib];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(templateSyncDidReturn:) name:kNotificationTemplateSyncPartialComplete object:nil];
}

- (UIImageView *)loadingImageView{
    if (!_loadingImageView){
        [self.view class]; //Force viewDidLoad;
    }
    
    return _loadingImageView;
}

- (void)clearBasket{
    [[OLUserSession currentSession] cleanupUserSession:OLUserSessionCleanupOptionBasket];
}

- (instancetype _Nullable)initWithAssets:(NSArray <OLAsset *>*_Nonnull)assets{
    NSAssert(![OLKiteUtils assetArrayContainsPDF:assets], @"If you want to use a pre-rendered PDF, please use initWithPrintJobs");
    
    return [self initWithAssets:assets info:nil];
}

- (instancetype _Nullable)initWithAssets:(NSArray <OLAsset *>*_Nonnull)assets info:(NSDictionary *_Nullable)info{
    [OLAnalytics setExtraInfo:info];
    NSArray <OLAsset *>*assetsCopy = [assets copy]; // Prevents assets being nilled in some cases
    self = [[UIStoryboard storyboardWithName:@"OLKiteStoryboard" bundle:[OLKiteUtils kiteResourcesBundle]] instantiateViewControllerWithIdentifier:@"KiteViewController"];
    [OLUserSession currentSession].appAssets = assetsCopy;
    [[OLUserSession currentSession] resetUserSelectedPhotos];
    
    return self;
}

- (void)setAssets:(NSArray *_Nonnull)assets{
    [OLUserSession currentSession].appAssets = assets;
    [[OLUserSession currentSession] resetUserSelectedPhotos];
}

- (void)addCustomPhotoProviderWithCollections:(NSArray <OLImagePickerProviderCollection *>*_Nonnull)collections name:(NSString *_Nonnull)name icon:(UIImage *_Nullable)image{
    [self.customImageProviders addObject:[[OLImagePickerProvider alloc] initWithCollections:(NSArray <id<NSFastEnumeration>> *)collections name:name icon:image]];
}

- (void)addCustomPhotoProviderWithViewController:(UIViewController<OLCustomPickerController> *_Nonnull)vc name:(NSString *_Nonnull)name icon:(UIImage *_Nullable)icon{
    [self addCustomPhotoProviderWithViewController:vc name:name icon:icon prepopulatedAssets:nil];
}

- (void)addCustomPhotoProviderWithViewController:(UIViewController<OLCustomPickerController> *_Nullable)vc name:(NSString *_Nonnull)name icon:(UIImage *_Nullable)icon prepopulatedAssets:(NSArray <OLAsset *> *_Nullable)assets{
    OLCustomViewControllerPhotoProvider *customProvider = [[OLCustomViewControllerPhotoProvider alloc] initWithController:vc name:name icon:icon];
    [customProvider.collections.firstObject addAssets:assets unique:NO];
    customProvider.preselectedAssets = assets;
    [self.customImageProviders addObject:customProvider];
}

- (void)setFontNamesForImageEditing:(NSArray<NSString *> *_Nullable)fontNames{
    self.fontNames = fontNames;
}

- (void)startLoadingWithCompletionHandler:(void(^)(void))handler{
    if (!handler){
        return;
    }
    self.loadingHandler = handler;
    [self loadRemoteData];
}

- (void)loadRemoteData{
    [OLUserSession currentSession].kiteVc = self;
    [[OLUserSession currentSession] calcScreenScaleForTraitCollection:self.traitCollection];
    
    self.operationQueue = [NSOperationQueue mainQueue];
    self.templateSyncOperation = [[NSBlockOperation alloc] init];
    self.remotePlistSyncOperation = [[NSBlockOperation alloc] init];
    self.remoteThemePlistSyncOperation = [[NSBlockOperation alloc] init];
    self.transitionOperation = [[NSBlockOperation alloc] init];
    
    [self.transitionOperation addDependency:self.templateSyncOperation];
    [self.transitionOperation addDependency:self.remotePlistSyncOperation];
    [self.transitionOperation addDependency:self.remoteThemePlistSyncOperation];
    [self.remoteThemePlistSyncOperation addDependency:self.remotePlistSyncOperation];
    
    if (self.loadingHandler){
        NSBlockOperation *loadingHandlerOperation = [NSBlockOperation blockOperationWithBlock:^{
            self.loadingHandler();
        }];
        [loadingHandlerOperation addDependency:self.templateSyncOperation];
        [loadingHandlerOperation addDependency:self.remotePlistSyncOperation];
        [loadingHandlerOperation addDependency:self.remoteThemePlistSyncOperation];
        [self.operationQueue addOperation:loadingHandlerOperation];
    }
    
    if (!self.preserveExistingTemplates){
        [OLProductTemplate resetTemplates];
    }
    
    if ([OLProductTemplate templates].count > 0){
        fadeTime = 0;
        [[OLKiteABTesting sharedInstance] setupABTestVariants];
        
        [self.operationQueue addOperation:self.templateSyncOperation];
        [self.operationQueue addOperation:self.remotePlistSyncOperation];
        [self.operationQueue addOperation:self.remoteThemePlistSyncOperation];
    }
    else{
        __weak OLKiteViewController *welf = self;
        [[OLKiteABTesting sharedInstance] fetchRemotePlistsWithCompletionHandler:^{
            [welf.operationQueue addOperation:welf.remotePlistSyncOperation];
        }];
        [OLProductTemplate syncWithCompletionHandler:^(id templates, id error){}];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];

    if (!self.loadingHandler){
        [self loadRemoteData];
    }
    
    if ([OLKitePrintSDK environment] == OLKitePrintSDKEnvironmentLive){
        [[self.view viewWithTag:9999] removeFromSuperview];
    }
    
    if (self.loadingImageView){
        self.view.backgroundColor = [self.loadingImageView.image colorAtPixel:CGPointMake(3, 3)];
    }
    
    [self transitionToNextScreen];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [OLUserSession currentSession].kiteVc = self;
    
    if ([[PhotobookSDK shared] isProcessingOrder]) {
        UIViewController *receiptViewController = [[PhotobookSDK shared] receiptViewControllerWithEmbedInNavigation:YES dismissClosure:^(UIViewController *viewController, BOOL success){
            [viewController dismissViewControllerAnimated:YES completion:NULL];
        }];
        if (receiptViewController) {
            [self presentViewController:receiptViewController animated:YES completion:nil];
        }
    }
}

- (UIViewController *)reviewViewControllerForProduct:(OLProduct *)product photoSelectionScreen:(BOOL)photoSelectionScreen{
    OLTemplateUI templateUI = product.productTemplate.templateUI;
    if (templateUI == OLTemplateUICase){
        return [[OLCaseViewController alloc] init];
    }
    else if (templateUI == OLTemplateUIApparel){
        return [[OLApparelViewController alloc] init];
    }
    else if (templateUI == OLTemplateUIPoster && product.productTemplate.gridCountX == 1 && product.productTemplate.gridCountY == 1){
        return [[OLSingleImagePosterViewController alloc] init];
    }
    else if (templateUI == OLTemplateUIPoster){
        return [[OLCollagePosterViewController alloc] init];
    }
    else if (templateUI == OLTemplateUIMug){
        return [[OL3DProductViewController alloc] init];
    }
    else if (templateUI == OLTemplateUINonCustomizable){
        return [[UIStoryboard storyboardWithName:@"OLKiteStoryboard" bundle:[OLKiteUtils kiteResourcesBundle]] instantiateViewControllerWithIdentifier:@"OLPaymentViewController"];
    }
    else if (photoSelectionScreen){
        return [[UIStoryboard storyboardWithName:@"OLKiteStoryboard" bundle:[OLKiteUtils kiteResourcesBundle]] instantiateViewControllerWithIdentifier:@"OLImagePickerViewController"];
    }
    else if (templateUI == OLTemplateUIPhotobook){
        return [[PhotobookSDK shared] photobookViewControllerWith:[OLAsset photobookAssetsFromAssets:[OLAsset userSelectedAssets]] embedInNavigation:NO navigatesToCheckout:YES delegate:[OLUserSession currentSession] completion:^(UIViewController *viewController, BOOL success){
            if (![OLUserSession currentSession].kiteVc){
                [viewController dismissViewControllerAnimated:YES completion:NULL];
            }
            else if ([viewController isKindOfClass:[NSClassFromString(@"Photobook.PhotobookViewController") class]]){
                [viewController.navigationController popViewControllerAnimated:YES];
            } else {
                [viewController.navigationController popToRootViewControllerAnimated:YES];
            }
        }];
    }
    else if (templateUI == OLTemplateUIPoster){
        return [[UIStoryboard storyboardWithName:@"OLKiteStoryboard" bundle:[OLKiteUtils kiteResourcesBundle]] instantiateViewControllerWithIdentifier:@"OLPosterViewController"];
    }
    else if (templateUI == OLTemplateUIFrame || templateUI == OLTemplateUICalendar){
        return [[UIStoryboard storyboardWithName:@"OLKiteStoryboard" bundle:[OLKiteUtils kiteResourcesBundle]] instantiateViewControllerWithIdentifier:@"FrameOrderReviewViewController"];
    }
    else{
        return [[UIStoryboard storyboardWithName:@"OLKiteStoryboard" bundle:[OLKiteUtils kiteResourcesBundle]] instantiateViewControllerWithIdentifier:@"OrderReviewViewController"];
    }
    
}

- (IBAction) dismiss{
    self.dismissing = YES;
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
        [OLAnalytics trackKiteViewControllerLoadedWithEntryPoint:@"Home Screen"];
        
        // The screen we transition to will depend on what products are available based on the developers filter preferences.
        NSArray *groups = [OLProductGroup groupsWithFilters:welf.filterProducts];
        
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"OLKiteStoryboard" bundle:[OLKiteUtils kiteResourcesBundle]];
        UIViewController *vc;
        OLProduct *product;
        if (groups.count == 0 && ![OLProductTemplate isSyncInProgress]) {
                UIAlertController *ac = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTableInBundle(@"Store Maintenance", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") message:NSLocalizedStringFromTableInBundle(@"Our store is currently undergoing maintenance so no products are available for purchase at this time. Please try again a little later.", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") preferredStyle:UIAlertControllerStyleAlert];
                [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"OK", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Acknowledgent to an alert dialog.") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    [welf dismiss];
                }]];
                [welf presentViewController:ac animated:YES completion:NULL];
            return;
        }
        else if ([OLKitePrintSDK isKiosk]){
            OLKioskLandingViewController *vc = [[OLKioskLandingViewController alloc] init];
            [welf fadeToViewController:[[OLNavigationController alloc] initWithRootViewController:vc]];
            return;
        }
        else if (groups.count == 1) {
            OLProductGroup *group = groups[0];
            product = [group.products firstObject];
            vc = [self viewControllerForGroupSelected:group];
        }
        else {
            // Launch the product home view controller where the top level groups will be displayed
            vc = [sb instantiateViewControllerWithIdentifier:@"ProductHomeViewController"];
        }
        [vc safePerformSelector:@selector(setProduct:) withObject:product];
        [vc safePerformSelector:@selector(setDelegate:) withObject:welf.delegate];
        [vc safePerformSelector:@selector(setFilterProducts:) withObject:welf.filterProducts];
        [vc safePerformSelector:@selector(setTemplateClass:) withObject:product.productTemplate.templateClass];
        if (welf.navigationController.viewControllers.count <= 1){
            UINavigationController *nvc = [[OLNavigationController alloc] initWithNavigationBarClass:[PhotobookNavigationBar class] toolbarClass:nil];
            nvc.viewControllers = @[vc];
            NSURL *cancelUrl = [NSURL URLWithString:[OLKiteABTesting sharedInstance].cancelButtonIconURL];
            if (cancelUrl && ![[OLImageDownloader sharedInstance] cachedDataExistForURL:cancelUrl]){
                [[OLImageDownloader sharedInstance] downloadImageAtURL:cancelUrl withCompletionHandler:^(UIImage *image, NSError *error){
                    if (error) return;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        vc.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageWithCGImage:image.CGImage scale:2.0 orientation:UIImageOrientationUp] style:UIBarButtonItemStyleDone target:welf action:@selector(dismiss)];
                    });
                }];
            }
            else{
                vc.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamedInKiteBundle:@"x-button"] style:UIBarButtonItemStylePlain target:welf action:@selector(dismiss)];
            }
            [welf fadeToViewController:nvc];
        }
        else{
            [welf fadeToViewController:vc];
        }
        
    }];
        
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

- (void)templateSyncDidReturn:(NSNotification *)n{
    if (self.dismissing){
        return;
    }
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
        NSString *message = NSLocalizedStringFromTableInBundle(@"There was a problem getting Print Shop products. Check your Internet connectivity or try again later.", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"");
        if (error.code == kOLKiteSDKErrorCodeMaintenanceMode) {
            message = NSLocalizedStringFromTableInBundle(@"Our store is currently undergoing maintenance so no products are available for purchase at this time. Please try again a little later.", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"");
        }
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:message preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"Cancel", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action){
            [self dismiss];
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"Retry", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
            [OLProductTemplate sync];
        }]];
        [self presentViewController:alert animated:YES completion:^(void){}];
    }
    
    else{
        if (!self.remoteThemePlistSyncOperation.finished && ![self.operationQueue.operations containsObject:self.remoteThemePlistSyncOperation]){
            if ([OLKiteABTesting sharedInstance].userConfig[@"theme"]){
                __weak OLKiteViewController *welf = self;
                [[OLKiteABTesting sharedInstance] fetchRemotePlistsWithCompletionHandler:^{
                    if (!welf.remoteThemePlistSyncOperation.executing && !welf.remoteThemePlistSyncOperation.finished && ![self.operationQueue.operations containsObject:self.remoteThemePlistSyncOperation]){
                        [welf.remoteThemePlistSyncOperation addExecutionBlock:^{}];
                        [welf.operationQueue addOperation:welf.remoteThemePlistSyncOperation];
                    }
                }];
            }
            else{
                if (!self.remoteThemePlistSyncOperation.executing && !self.remoteThemePlistSyncOperation.finished && ![self.operationQueue.operations containsObject:self.remoteThemePlistSyncOperation]){
                    [self.remoteThemePlistSyncOperation addExecutionBlock:^{}];
                    [self.operationQueue addOperation:self.remoteThemePlistSyncOperation];
                }
            }
        }
        if (!self.templateSyncOperation.executing && !self.templateSyncOperation.finished && ![self.operationQueue.operations containsObject:self.templateSyncOperation]){
            [self.operationQueue addOperation:self.templateSyncOperation];
        }
        
        [self.viewControllers.firstObject safePerformSelector:@selector(templateSyncDidUpdate) withObject:nil];
    }
}

- (NSArray *)viewControllers{
    return [(UINavigationController *)self.childViewControllers.firstObject viewControllers];
}

- (UIViewController *)productDescriptionViewController{
    return [[UIStoryboard storyboardWithName:@"OLKiteStoryboard" bundle:[OLKiteUtils kiteResourcesBundle]] instantiateViewControllerWithIdentifier:@"OLProductOverviewViewController"];
}

- (UIViewController *)infoViewController{
    return [[UIStoryboard storyboardWithName:@"OLKiteStoryboard" bundle:[OLKiteUtils kiteResourcesBundle]]instantiateViewControllerWithIdentifier:@"InfoPageViewController"];
}

- (UIViewController *)viewControllerForGroupSelected:(OLProductGroup *)group{
    if (group.products.count > 1){
        return [[UIStoryboard storyboardWithName:@"OLKiteStoryboard" bundle:[OLKiteUtils kiteResourcesBundle]] instantiateViewControllerWithIdentifier:@"OLTypeSelectionViewController"];
    }
    else if ([OLKiteABTesting sharedInstance].disableProductCategories && [OLKiteABTesting sharedInstance].skipProductOverview){
        return [[OLUserSession currentSession].kiteVc reviewViewControllerForProduct:group.products.firstObject photoSelectionScreen:[OLKiteUtils imageProvidersAvailable]];
    }
    else{
        return [self productDescriptionViewController];
    }
}

- (void)didReceiveMemoryWarning{
    for (OLAsset *asset in [OLAsset userSelectedAssets]){
        [asset unloadImage];
    }
}

- (void)dealloc{
    [[OLUserSession currentSession] cleanupUserSession:OLUserSessionCleanupOptionPhotos];
    [OLUserSession currentSession].userSelectedAssets = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Kiosk

- (void)startTimer{
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateTimer:) userInfo:nil repeats:YES];
}

- (void)stopTimer{
    [self.timer invalidate];
}

- (void)updateTimer:(NSTimer *)timer {
    // has the target time passed?
    if (self.touchReporter){
        [self.touchReporter.superview bringSubviewToFront:self.touchReporter];
    }
    NSInteger timeout = 240;
        NSLog(@"Auto log out in: %f",timeout+[self.lastTouchDate timeIntervalSinceNow]);
    if ([self.lastTouchDate timeIntervalSinceNow] <= -timeout) {
        [timer invalidate];
        
        OLLogoutViewController *vc = [[UIStoryboard storyboardWithName:@"OLKiteStoryboard" bundle:[OLKiteUtils kiteResourcesBundle]] instantiateViewControllerWithIdentifier:@"LogoutViewController"];
        vc.modalPresentationStyle = UIModalPresentationFormSheet;
        vc.preferredContentSize = CGSizeMake(435, 563);
        
        [self.lastTouchedViewController presentViewController:vc animated:YES completion:NULL];
    }
}

- (void)setLastTouchDate:(NSDate *)date forViewController:(UIViewController *)vc{
    self.lastTouchedViewController = vc;
    self.lastTouchDate = date;
}

- (void)kioskLogout{
    [self.timer invalidate];
    
    void (^logout)(void) = ^{
        [[OLUserSession currentSession] cleanupUserSession:OLUserSessionCleanupOptionAll];
        self.transitionOperation = [[NSBlockOperation alloc] init];
        [self transitionToNextScreen];
    };
    
    if (self.presentedViewController){
    [self.presentedViewController dismissViewControllerAnimated:YES completion:^{
        if (self.presentedViewController){
            [self dismissViewControllerAnimated:NO completion:^{
                logout();
            }];
        }
        else{
            logout();
        }
        [self.childViewControllers.firstObject removeFromParentViewController];
    }];
    }
    else{
        logout();
    }
    
}

- (BOOL)shouldAutorotate {
    if ([self.childViewControllers.firstObject respondsToSelector: @selector(shouldAutorotate)]) {
        return self.childViewControllers.firstObject.shouldAutorotate;
    }
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return self.childViewControllers.firstObject.supportedInterfaceOrientations ?: UIInterfaceOrientationMaskAll;
}

@end
