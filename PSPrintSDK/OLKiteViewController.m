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

-(IBAction) dismiss{
    [self dismissViewControllerAnimated:YES completion:^{
    }];
    
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
        if (product.templateType == kOLTemplateTypeFrame || product.templateType == kOLTemplateTypeFrame2x2 || product.templateType == kOLTemplateTypeFrame3x3 || product.templateType == kOLTemplateTypeFrame4x4){
            includesFrames = YES;
        }
        else if (product.templateType == kOLTemplateTypeLargeFormatA1 || product.templateType == kOLTemplateTypeLargeFormatA2 || product.templateType == kOLTemplateTypeLargeFormatA3){
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
    if (([OLKitePrintSDK enabledProducts] && [[OLKitePrintSDK enabledProducts] count] < 2) || self.templateType != kOLTemplateTypeNoTemplate){
        nextVcNavIdentifier = @"OLProductOverviewNavigationViewController";
        nextVcIdentifier = @"OLProductOverviewNavigationViewController";
        
        if ([OLKitePrintSDK enabledProducts] && [[OLKitePrintSDK enabledProducts] count] == 1){
            product = [[OLKitePrintSDK enabledProducts] firstObject];
        }
        else{
            for (OLProduct *productIter in [OLProduct products]){
                if (productIter.templateType == self.templateType){
                    product = productIter;
                }
            }
        }
        
        if (product.templateType == kOLTemplateTypeLargeFormatA1 || product.templateType == kOLTemplateTypeLargeFormatA2 || product.templateType == kOLTemplateTypeLargeFormatA3){
            nextVcIdentifier = @"sizeSelect";
            nextVcNavIdentifier = @"sizeSelectNavigationController";
        }
    }
    
    if (!self.navigationController){
        self.nextVc = [sb instantiateViewControllerWithIdentifier:nextVcNavIdentifier];
        OLProduct *product = [[OLProductHomeViewController products] firstObject];
        UIViewController *detailVc;
        if (product.templateType == kOLTemplateTypeLargeFormatA1 || product.templateType == kOLTemplateTypeLargeFormatA2 || product.templateType == kOLTemplateTypeLargeFormatA3){
            OLPosterSizeSelectionViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"sizeSelect"];
            vc.assets = self.assets;
            detailVc = vc;
        }
        else{
            UINavigationController *nvc = (UINavigationController *)[self.storyboard instantiateViewControllerWithIdentifier:@"OLProductOverviewNavigationViewController"];
            OLProductOverviewViewController *vc = (OLProductOverviewViewController *)[nvc topViewController];
            vc.assets = self.assets;
            vc.product = product;
            detailVc = nvc;
        }
        [((UISplitViewController *)self.nextVc) showDetailViewController:detailVc sender:nil];
        [((UISplitViewController *)self.nextVc) setPreferredDisplayMode:UISplitViewControllerDisplayModeAllVisible];
        ((UISplitViewController *)self.nextVc).presentsWithGesture = NO;
        
//        ((UINavigationController *)self.nextVc).topViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismiss)];
//        [(id)((UINavigationController *)self.nextVc).topViewController setAssets:self.assets];
//        if (product){
//            [(id)((UINavigationController *)self.nextVc).topViewController setProduct:product];
//        }
        self.nextVc.view.alpha = 0;
        [self.view addSubview:self.nextVc.view];
        [UIView animateWithDuration:0.15 animations:^(void){
            self.nextVc.view.alpha = 1;
        }];
    }
    else{
        CGFloat standardiOSBarsHeight = self.navigationController.navigationBar.frame.size.height + [UIApplication sharedApplication].statusBarFrame.size.height;
        self.nextVc = [sb instantiateViewControllerWithIdentifier:nextVcIdentifier];
        [(id)self.nextVc setAssets:self.assets];
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
