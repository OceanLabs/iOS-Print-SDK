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
#import "OLPrintOrder.h"
#import "OLProduct.h"
#import "OLProductGroup.h"
#import "OLProductHomeViewController.h"
#import "OLProductOverviewViewController.h"
#import "OLProductTemplate.h"
#import "OLProductTypeSelectionViewController.h"
#import "OLUserSession.h"
#import "UIImage+OLUtils.h"
#import "OLCaseViewController.h"
#import "OLSingleImagePosterViewController.h"
#import "OL3DProductViewController.h"
#import "OLApparelViewController.h"

static CGFloat fadeTime = 0.3;


@interface OLKiteViewController ()

@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (weak, nonatomic) IBOutlet UINavigationItem *customNavigationItem;
@property (weak, nonatomic) IBOutlet UIImageView *loadingImageView;
@property (strong, nonatomic) NSMutableArray <OLImagePickerProvider *> *customImageProviders;
@property (strong, nonatomic) NSArray *fontNames;

// Because template sync happens in the constructor it may complete before the OLKiteViewController has appeared. In such a case where sync does
// complete first we make a note to immediately transition to the appropriate view when the OLKiteViewController does appear:
@property (strong, nonatomic) NSOperationQueue *operationQueue;
@property (strong, nonatomic) NSBlockOperation *templateSyncOperation;
@property (strong, nonatomic) NSBlockOperation *remotePlistSyncOperation;
@property (strong, nonatomic) NSBlockOperation *remoteThemePlistSyncOperation;
@property (strong, nonatomic) NSBlockOperation *transitionOperation;

@property (copy, nonatomic) void (^loadingHandler)();

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

- (UINavigationBar *)navigationBar{
    if (!_navigationBar){
        [self.view class]; //Force viewDidLoad;
    }
    
    return _navigationBar;
}

- (UINavigationItem *)customNavigationItem{
    if (!_customNavigationItem){
         [self.view class]; //Force viewDidLoad;
    }
    
    return _customNavigationItem;
}

- (OLPrintOrder *)basketOrder{
    return [OLUserSession currentSession].printOrder;
}

- (void)clearBasket{
    [[OLUserSession currentSession] cleanupUserSession:OLUserSessionCleanupOptionBasket];
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
    if ((self = [[UIStoryboard storyboardWithName:@"OLKiteStoryboard" bundle:[OLKiteUtils kiteResourcesBundle]] instantiateViewControllerWithIdentifier:@"KiteViewController"])) {
        [OLUserSession currentSession].appAssets = assets;
        [[OLUserSession currentSession] resetUserSelectedPhotos];
        [OLUserSession currentSession].printOrder.userData = info;
    }
    [OLKiteABTesting sharedInstance].launchedWithPrintOrder = NO;
    
    return self;
}

- (instancetype _Nullable)initWithPrintOrder:(OLPrintOrder *_Nullable)printOrder info:(NSDictionary * _Nullable)info{
    [OLAnalytics setExtraInfo:info];
    if ((self = [[UIStoryboard storyboardWithName:@"OLKiteStoryboard" bundle:[OLKiteUtils kiteResourcesBundle]] instantiateViewControllerWithIdentifier:@"KiteViewController"])) {
        [OLKiteABTesting sharedInstance].launchedWithPrintOrder = printOrder != nil;
        [OLUserSession currentSession].appAssets = [[printOrder.jobs firstObject] assetsForUploading];
        [[OLUserSession currentSession] resetUserSelectedPhotos];
        [OLUserSession currentSession].printOrder = printOrder;
        [OLUserSession currentSession].printOrder.userData = info;
    }
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

- (void)addCustomPhotoProviderWithViewController:(UIViewController<OLCustomPickerController> *_Nonnull)vc name:(NSString *_Nonnull)name icon:(UIImage *_Nullable)icon prepopulatedAssets:(NSArray <OLAsset *> *_Nullable)assets{
    OLCustomViewControllerPhotoProvider *customProvider = [[OLCustomViewControllerPhotoProvider alloc] initWithController:vc name:name icon:icon];
    [customProvider.collections.firstObject addAssets:assets unique:NO];
    customProvider.preselectedAssets = assets;
    [self.customImageProviders addObject:customProvider];
}

- (void)setFontNamesForImageEditing:(NSArray<NSString *> *_Nullable)fontNames{
    self.fontNames = fontNames;
}

- (void)startLoadingWithCompletionHandler:(void(^)())handler{
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
    
    [OLProductTemplate resetTemplates];
    
    if ([OLProductTemplate templates].count > 0){
        fadeTime = 0;
        [[OLKiteABTesting sharedInstance] setupABTestVariants];
        
        [self.operationQueue addOperation:self.templateSyncOperation];
        [self.operationQueue addOperation:self.remotePlistSyncOperation];
    }
    else{
        __weak OLKiteViewController *welf = self;
        [[OLKiteABTesting sharedInstance] fetchRemotePlistsWithCompletionHandler:^{
            [welf.operationQueue addOperation:welf.remotePlistSyncOperation];
        }];
        [OLProductTemplate syncWithCompletionHandler:^(id templates, id error){}];
    }
}

-(void)viewDidLoad {
    [super viewDidLoad];
    
    if (!self.navigationController){
        self.navigationBar.hidden = NO;
        self.customNavigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Cancel", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
    }

    if (!self.loadingHandler){
        [self loadRemoteData];
    }
    
    if ([OLKiteABTesting sharedInstance].launchedWithPrintOrder){
        self.customNavigationItem.title = @"";
    }
    
    if ([OLKitePrintSDK environment] == OLKitePrintSDKEnvironmentLive){
        [[self.view viewWithTag:9999] removeFromSuperview];
    }
    
    self.view.backgroundColor = [self.loadingImageView.image colorAtPixel:CGPointMake(3, 3)];
    
    [self transitionToNextScreen];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [OLUserSession currentSession].kiteVc = self;
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
    else if (templateUI == OLTemplateUIMug){
        return [[OL3DProductViewController alloc] init];
    }
    
    return [self.storyboard instantiateViewControllerWithIdentifier:[self reviewViewControllerIdentifierForProduct:product photoSelectionScreen:photoSelectionScreen]];
    
}

- (NSString *)reviewViewControllerIdentifierForProduct:(OLProduct *)product photoSelectionScreen:(BOOL)photoSelectionScreen{
    OLTemplateUI templateUI = product.productTemplate.templateUI;
    if (templateUI == OLTemplateUIPhotobook){
        return @"OLEditPhotobookViewController";
    }
    else if (templateUI == OLTemplateUINonCustomizable){
        return @"OLPaymentViewController";
    }
    else if (photoSelectionScreen){
        return @"OLImagePickerViewController";
    }
    else if (templateUI == OLTemplateUIPoster){
        return @"OLPosterViewController";
    }
    else if (templateUI == OLTemplateUIFrame || templateUI == OLTemplateUICalendar){
        return @"FrameOrderReviewViewController";
    }
    else{
        return @"OrderReviewViewController";
    }
}

-(void) dismiss{
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
#ifndef OL_NO_ANALYTICS
        if ([OLKiteABTesting sharedInstance].launchedWithPrintOrder){
            [OLAnalytics trackKiteViewControllerLoadedWithEntryPoint:[OLKiteABTesting sharedInstance].launchWithPrintOrderVariant];
        }
        else{
            [OLAnalytics trackKiteViewControllerLoadedWithEntryPoint:@"Home Screen"];
        }
#endif
        
        // The screen we transition to will depend on what products are available based on the developers filter preferences.
        NSArray *groups = [OLProductGroup groupsWithFilters:welf.filterProducts];
        
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"OLKiteStoryboard" bundle:[OLKiteUtils kiteResourcesBundle]];
        NSString *nextVcNavIdentifier;
        OLProduct *product;
        if (groups.count == 0 && !([OLProductTemplate templates].count != 0 && [OLKiteABTesting sharedInstance].launchedWithPrintOrder)) {
                UIAlertController *ac = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTableInBundle(@"Store Maintenance", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") message:NSLocalizedStringFromTableInBundle(@"Our store is currently undergoing maintence so no products are available for purchase at this time. Please try again a little later.", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") preferredStyle:UIAlertControllerStyleAlert];
                [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"OK", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Acknowledgent to an alert dialog.") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    [welf dismiss];
                }]];
                [welf presentViewController:ac animated:YES completion:NULL];
            return;
        }
        else if ([OLKiteABTesting sharedInstance].launchedWithPrintOrder){
            BOOL containsPDF = [OLKiteUtils assetArrayContainsPDF:[[[OLUserSession currentSession].printOrder.jobs firstObject] assetsForUploading]];
            OLProduct *product = [OLProduct productWithTemplateId:[[[OLUserSession currentSession].printOrder.jobs firstObject] templateId]];
            NSString *identifier;
            if (!containsPDF && [[OLKiteABTesting sharedInstance].launchWithPrintOrderVariant hasPrefix:@"Overview-"] && [product isValidProductForUI]){
                identifier = @"OLProductOverviewViewController";
            }
            else if (!containsPDF && [[OLKiteABTesting sharedInstance].launchWithPrintOrderVariant hasPrefix:@"Review-"] && [product isValidProductForUI]){
                identifier = [[OLUserSession currentSession].kiteVc reviewViewControllerIdentifierForProduct:product photoSelectionScreen:[OLKiteUtils imageProvidersAvailable:welf]];
            }
            else{
                [OLKiteUtils checkoutViewControllerForPrintOrder:[OLUserSession currentSession].printOrder handler:^(id vc){
                    [vc safePerformSelector:@selector(setUserEmail:) withObject:welf.userEmail];
                    [vc safePerformSelector:@selector(setUserPhone:) withObject:welf.userPhone];
                    if (welf.navigationController.viewControllers.count <= 1){
                        UINavigationController *nvc = [[OLNavigationController alloc] initWithRootViewController:vc];
                        
                        NSURL *cancelUrl = [NSURL URLWithString:[OLKiteABTesting sharedInstance].cancelButtonIconURL];
                        if (cancelUrl && ![[OLImageDownloader sharedInstance] cachedDataExistForURL:cancelUrl]){
                            [[OLImageDownloader sharedInstance] downloadImageAtURL:cancelUrl withCompletionHandler:^(UIImage *image, NSError *error){
                                if (error) return;
                                dispatch_async(dispatch_get_main_queue(), ^{
                                   ((UIViewController *)vc).navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageWithCGImage:image.CGImage scale:2.0 orientation:UIImageOrientationUp] style:UIBarButtonItemStyleDone target:welf action:@selector(dismiss)];
                                });
                            }];
                        }
                        else{
                        ((UIViewController *)vc).navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Cancel", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") style:UIBarButtonItemStylePlain target:welf action:@selector(dismiss)];
                        }
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
            [vc safePerformSelector:@selector(setProduct:) withObject:product];
            if ([vc isKindOfClass:[OLImagePickerViewController class]]){
                [(OLImagePickerViewController *)vc setOverrideImagePickerMode:YES];
            }
            
            if (welf.navigationController.viewControllers.count <= 1){
                UINavigationController *nvc = [[OLNavigationController alloc] initWithRootViewController:vc];
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
                    vc.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Cancel", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") style:UIBarButtonItemStylePlain target:welf action:@selector(dismiss)];
                }
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
        [vc safePerformSelector:@selector(setTemplateClass:) withObject:product.productTemplate.templateClass];
        if (welf.navigationController.viewControllers.count <= 1){
            UINavigationController *nvc = [[OLNavigationController alloc] initWithRootViewController:vc];
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
                vc.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Cancel", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") style:UIBarButtonItemStylePlain target:welf action:@selector(dismiss)];
            }
            [welf fadeToViewController:nvc];
        }
        else{
            [welf fadeToViewController:vc];
        }
        
        //Prefetch themed-SDK images
        [[OLKiteABTesting sharedInstance] prefetchRemoteImages];
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
            message = NSLocalizedStringFromTableInBundle(@"Our store is currently undergoing maintence so no products are available for purchase at this time. Please try again a little later.", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"");
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
                        [welf.remoteThemePlistSyncOperation addExecutionBlock:^{}];
                        [welf.operationQueue addOperation:welf.remoteThemePlistSyncOperation];
                    }];
            }
            else{
                [self.remoteThemePlistSyncOperation addExecutionBlock:^{}];
                [self.operationQueue addOperation:self.remoteThemePlistSyncOperation];
            }
        }
        if (!self.templateSyncOperation.finished){
            [self.operationQueue addOperation:self.templateSyncOperation];
        }
        
        [self.viewControllers.firstObject safePerformSelector:@selector(templateSyncDidUpdate) withObject:nil];
    }
}

- (NSArray *)viewControllers{
    return [(UINavigationController *)self.childViewControllers.firstObject viewControllers];
}

- (OLReceiptViewController *)receiptViewControllerForPrintOrder:(OLPrintOrder *)printOrder{
    return [[OLReceiptViewController alloc] initWithPrintOrder:printOrder];
}

+ (NSString *)storyboardIdentifierForGroupSelected:(OLProductGroup *)group{
    if (group.products.count > 1){
        return @"OLTypeSelectionViewController";
    }
    else if ([OLKiteABTesting sharedInstance].disableProductCategories && [OLKiteABTesting sharedInstance].skipProductOverview){
        return [[OLUserSession currentSession].kiteVc reviewViewControllerIdentifierForProduct:group.products.firstObject photoSelectionScreen:YES];
    }
    else{
        return @"OLProductOverviewViewController";
    }
}

+ (UINavigationController *)orderHistoryViewController{
    UIViewController *vc = [[UIStoryboard storyboardWithName:@"OLKiteStoryboard" bundle:[OLKiteUtils kiteResourcesBundle]] instantiateViewControllerWithIdentifier:@"OLOrderHistoryViewController"];
    
    return [[OLNavigationController alloc] initWithRootViewController:vc];
}

- (void)didReceiveMemoryWarning{
    for (OLAsset *asset in [OLUserSession currentSession].userSelectedPhotos){
        [asset unloadImage];
    }
}

- (void)dealloc{
    [[OLUserSession currentSession] cleanupUserSession:OLUserSessionCleanupOptionPhotos];
    [OLUserSession currentSession].userSelectedPhotos = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
