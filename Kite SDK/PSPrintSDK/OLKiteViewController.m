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

@interface OLKiteViewController () <UIAlertViewDelegate>

@property (assign, nonatomic) BOOL alreadyTransistioned;
@property (strong, nonatomic) UIViewController *nextVc;
@property (strong, nonatomic) NSArray *assets;
@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (assign, nonatomic) BOOL alreadyTransitioned;
@property (assign, nonatomic) BOOL presentLater;

@end

@implementation OLKiteViewController

- (id)initWithAssets:(NSArray *)assets {
    NSAssert(assets != nil && [assets count] > 0, @"KiteViewController requires assets to print");
    if ((self = [[UIStoryboard storyboardWithName:@"OLKiteStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"KiteViewController"])) {
        self.assets = assets;
        [OLProductTemplate sync];
    }
    
    return self;
}

-(void)viewDidLoad{
    [super viewDidLoad];
    
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackKiteViewControllerLoaded];
#endif
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(templateSyncDidFinish:) name:kNotificationTemplateSyncComplete object:nil];
    if ([[OLProductTemplate templates] count] > 0){
        [self transitionToNextScreen:NO];
    }
    if (!self.navigationController){
        self.navigationBar.hidden = NO;
    }
}

-(void) viewWillAppear:(BOOL)animated{
    if (self.presentLater){
        self.presentLater = NO;
        UIView *view = [[UIView alloc] initWithFrame:self.view.bounds];
        view.backgroundColor = [UIColor whiteColor];
        [self.nextVc.view addSubview:view];
        [self presentViewController:self.nextVc animated:NO completion:^(void){
            [UIView animateWithDuration:0.15 animations:^(void){
                view.alpha = 0;
            } completion:^(BOOL b){
                [view removeFromSuperview];
            }];
            
        }];
    }
}

-(IBAction) dismiss{
    if (self.presentedViewController){
        UIView *dummy = [self.presentedViewController.view snapshotViewAfterScreenUpdates:YES];
        [self.view addSubview:dummy];
        [self.presentedViewController dismissViewControllerAnimated:NO completion:^{
            [self dismissViewControllerAnimated:YES completion:^{
            }];
        }];
    }
    else{
        [self dismissViewControllerAnimated:YES completion:^{
        }];
    }
    
}

+ (BOOL)singleProductEnabled{
    NSArray *products = [OLKitePrintSDK enabledProducts];
    if (!products || [products count] == 0){
        return NO;
    }
    if ([products count] == 1){
        return YES;
    }
    BOOL includesFrames = NO;
    BOOL includesLargeFormat = NO;
    for (OLProduct *product in products){
        if (product.productTemplate.templateClass == kOLTemplateClassFrame){
            includesFrames = YES;
        }
        else if (product.productTemplate.templateClass == kOLTemplateClassPoster){
            includesLargeFormat = YES;
        }
    }
    return includesLargeFormat != includesFrames; //XOR, true if we have one or the other but not both
}

- (void)transitionToNextScreen:(BOOL)animated{
    self.alreadyTransistioned = YES;
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"OLKiteStoryboard" bundle:nil];
    NSString *nextVcNavIdentifier = @"SplitViewController";
    NSString *nextVcIdentifier = @"SplitViewController";
    OLProduct *product;
//    if (([OLKitePrintSDK enabledProducts] && [[OLKitePrintSDK enabledProducts] count] < 2)){
//        nextVcNavIdentifier = @"OLProductOverviewNavigationViewController";
//        nextVcIdentifier = @"OLProductOverviewNavigationViewController";
//        
//        if ([OLKiteViewController singleProductEnabled]){
//            product = [[OLKitePrintSDK enabledProducts] firstObject];
//            NSAssert(product && product.productTemplate.templateClass != kOLTemplateClassNA, @"Product chosen does not support the Print Shop User Experience. Please implement a custom checkout.");
//        }
//        
//        if (product.productTemplate.templateClass == kOLTemplateClassPoster){
//            nextVcIdentifier = @"sizeSelect";
//            nextVcNavIdentifier = @"sizeSelectNavigationController";
//        }
//    }
    
    if (!self.navigationController){
        OLProduct *product = [[OLProductHomeViewController products] firstObject];
        UIViewController *detailVc;
        if (product.productTemplate.templateClass == kOLTemplateClassPoster){
            OLPosterSizeSelectionViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"sizeSelect"];
            vc.assets = [self.assets mutableCopy];
            detailVc = vc;
        }
        else{
            UINavigationController *nvc = (UINavigationController *)[self.storyboard instantiateViewControllerWithIdentifier:@"OLProductOverviewNavigationViewController"];
            OLProductOverviewViewController *vc = (OLProductOverviewViewController *)[nvc topViewController];
            vc.assets = [self.assets mutableCopy];
            vc.product = product;
            detailVc = nvc;
        }

        self.nextVc = [sb instantiateViewControllerWithIdentifier:nextVcNavIdentifier];
        OLProductHomeViewController *home = (OLProductHomeViewController *)[(UINavigationController *)[((UISplitViewController *)self.nextVc).viewControllers firstObject] topViewController];
        home.delegate = self.delegate;
        
        home.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismiss)];
        [home setAssets:[self.assets mutableCopy]];
//        if (product){
//            [(id)((UINavigationController *)self.nextVc).topViewController setProduct:product];
//        }
        [((UISplitViewController *)self.nextVc) showDetailViewController:detailVc sender:nil];
        [((UISplitViewController *)self.nextVc) setPreferredDisplayMode:UISplitViewControllerDisplayModeAllVisible];
        ((UISplitViewController *)self.nextVc).presentsWithGesture = NO;
        
//        self.nextVc.view.alpha = 0;
//        [self.view addSubview:self.nextVc.view];
//        [UIView animateWithDuration:0.15 animations:^(void){
//            self.nextVc.view.alpha = 1;
//        }];

        self.presentLater = YES;
    }
    else{
        CGFloat standardiOSBarsHeight = self.navigationController.navigationBar.frame.size.height + [UIApplication sharedApplication].statusBarFrame.size.height;
        self.nextVc = [sb instantiateViewControllerWithIdentifier:nextVcIdentifier];
        [(OLProductHomeViewController *)((UINavigationController *)self.nextVc).topViewController setDelegate:self.delegate];
        [(id)self.nextVc setAssets:[self.assets mutableCopy]];
        if (product){
            [(id)self.nextVc setProduct:product];
        }
        [self.view addSubview:self.nextVc.view];
        UIView *dummy = [self.view snapshotViewAfterScreenUpdates:YES];
        if ([self.nextVc isKindOfClass:[UITableViewController class]]){
            dummy.transform = CGAffineTransformMakeTranslation(0, standardiOSBarsHeight);
        }
        [self.view addSubview:dummy];
        self.title = self.nextVc.title;
        [self.navigationController pushViewController:self.nextVc animated:animated];
    }
}

- (void)templateSyncDidFinish:(NSNotification *)n{
    [OLProductTemplate resetTemplates];
    if (n.userInfo[kNotificationKeyTemplateSyncError]){
        if ([[OLProductTemplate templates] count] > 0){
            return;
        }
        NSLog(@"%@", n.userInfo[kNotificationKeyTemplateSyncError]);
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
        if (!self.alreadyTransistioned){
            [self transitionToNextScreen:NO];
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

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
