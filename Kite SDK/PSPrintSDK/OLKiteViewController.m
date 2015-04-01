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
#import "OLKitePrintSDK.h"
#import "OLAnalytics.h"
#import "OLPrintPhoto.h"

@interface OLKiteViewController () <UIAlertViewDelegate>

@property (strong, nonatomic) UIViewController *nextVc;
@property (strong, nonatomic) NSArray *assets;
@property (strong, nonatomic) NSMutableArray *userSelectedPhotos;
@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;

// Because template sync happens in the constructor it may complete before the OLKiteViewController has appeared. In such a case where sync does
// complete first we make a note to immediately transition to the appropriate view when the OLKiteViewController does appear:
@property (assign, nonatomic) BOOL transitionOnViewDidAppear;
@property (assign, nonatomic) BOOL seenViewDidAppear;
@property (assign, nonatomic) BOOL alreadyTransitioned;

@end

@interface OLKitePrintSDK (Private)

+ (void)setCacheTemplates:(BOOL)cache;
+ (BOOL)cacheTemplates;

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

-(void)viewDidLoad {
    [super viewDidLoad];
    
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackKiteViewControllerLoaded];
#endif
    
    if (!self.navigationController){
        self.navigationBar.hidden = NO;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    if (self.isBeingPresented) {
        if (![OLKitePrintSDK cacheTemplates]) {
            [OLProductTemplate deleteCachedTemplates];
            [OLProductTemplate resetTemplates];
        }
        
        self.alreadyTransitioned = NO;
        self.transitionOnViewDidAppear = NO;
        self.seenViewDidAppear = NO;
        [OLProductTemplate sync];
    }
}

-(void) viewDidAppear:(BOOL)animated{
    self.seenViewDidAppear = YES;
    
    if ([[OLProductTemplate templates] count] > 0){
        self.transitionOnViewDidAppear = YES;
    }
    
    if (self.isBeingPresented && self.transitionOnViewDidAppear) {
        [self transitionToNextScreen];
    }
    
    self.transitionOnViewDidAppear = NO;
}

-(IBAction) dismiss{
    if (self.presentedViewController){
        UIView *dummy = [self.presentedViewController.view snapshotViewAfterScreenUpdates:YES];
        [self.view addSubview:dummy];
        [self.presentedViewController dismissViewControllerAnimated:NO completion:^{
            [self dismissViewControllerAnimated:YES completion:^{
                [dummy removeFromSuperview];
            }];
        }];
    } else {
        [self dismissViewControllerAnimated:YES completion:^{
        }];
    }
}

- (void)transitionToNextScreen{
    if (self.alreadyTransitioned) {
        return;
    }
    self.alreadyTransitioned = YES;
    
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"OLKiteStoryboard" bundle:nil];
    NSString *nextVcNavIdentifier = @"ProductsNavigationController";
    
    self.nextVc = [sb instantiateViewControllerWithIdentifier:nextVcNavIdentifier];
    OLProductHomeViewController *homeVC = (OLProductHomeViewController *)((UINavigationController *)self.nextVc).topViewController;
    [homeVC setDelegate:self.delegate];
    homeVC.userEmail = self.userEmail;
    homeVC.userPhone = self.userPhone;
    
    ((UINavigationController *)self.nextVc).topViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismiss)];
    [(id)((UINavigationController *)self.nextVc).topViewController setAssets:[self.assets mutableCopy]];
    [(id)((UINavigationController *)self.nextVc).topViewController setUserSelectedPhotos:self.userSelectedPhotos];

    CGRect bounds = self.view.bounds;
    bounds.origin.y = CGRectGetMaxY(self.navigationBar.frame);
    UIView *view = [[UIView alloc] initWithFrame:bounds];
    view.backgroundColor = [UIColor whiteColor];
    [self.nextVc.view addSubview:view];
    [self presentViewController:self.nextVc animated:NO completion:^(void){
        [UIView animateWithDuration:0.3 animations:^(void){
            view.alpha = 0;
        } completion:^(BOOL b){
            [view removeFromSuperview];
        }];
    }];
}

- (void)templateSyncDidFinish:(NSNotification *)n{
    if (n.userInfo[kNotificationKeyTemplateSyncError]){
        if ([[OLProductTemplate templates] count] > 0){
            return;
        }
        
        NSString *message = NSLocalizedString(@"There was problem getting Print Shop products. Check your Internet connectivity or try again later.", @"");
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
            av.delegate = self;
            [av show];
        }
    }
    else{
        if (self.seenViewDidAppear){
            [self transitionToNextScreen];
        } else {
            self.transitionOnViewDidAppear = YES;
        }
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 0){
        [OLProductTemplate sync];
    }
    else{
        [self dismiss];
    }
}

#pragma mark - Autorotate and Orientation Methods

- (BOOL)shouldAutorotate {
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
