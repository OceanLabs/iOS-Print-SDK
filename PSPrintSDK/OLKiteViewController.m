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

@interface OLKiteViewController ()

@property (assign, nonatomic) BOOL alreadyTransistioned;
@property (strong, nonatomic) UIViewController *nextVc;
@property (strong, nonatomic) NSArray *assets;

@end

@implementation OLKiteViewController

- (id)initWithAssets:(NSArray *)assets {
    NSAssert(assets != nil && [assets count] > 0, @"KiteViewController requires assets to print");
    if (self = [super init]) {
        self.assets = assets;
        //[self.printOrder preemptAssetUpload];
        [OLProductTemplate sync];
    }
    
    return self;
}

-(void)viewDidLoad{
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"OLKiteStoryboard" bundle:nil];
    NSString *nextVcNavIdentifier = @"ProductsNavigationController";
    NSString *nextVcIdentifier = @"ProductHomeViewController";
    if (([OLKitePrintSDK enabledProducts] && [[OLKitePrintSDK enabledProducts] count] < 2) || self.templateType != kOLTemplateTypeNoTemplate){
        nextVcNavIdentifier = @"OLProductOverviewNavigationViewController";
        nextVcIdentifier = @"OLProductOverviewViewController";
    }
    
    if (!self.navigationController){
        self.nextVc = [sb instantiateViewControllerWithIdentifier:nextVcIdentifier];
        ((UINavigationController *)self.nextVc).topViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismiss)];
        [(id)self.nextVc setAssets:self.assets];
        [self.view addSubview:self.nextVc.view];
    }
    else{
        self.nextVc = [sb instantiateViewControllerWithIdentifier:nextVcIdentifier];
        [(id)self.nextVc setAssets:self.assets];
        [self.view addSubview:self.nextVc.view];
        UIView *dummy = [self.view snapshotViewAfterScreenUpdates:YES];
        dummy.transform = CGAffineTransformMakeTranslation(0, self.navigationController.navigationBar.frame.size.height + [UIApplication sharedApplication].statusBarFrame.size.height);
        [self.view addSubview:dummy];
        
        [self.navigationController pushViewController:self.nextVc animated:NO];
    }
}

-(void) dismiss{
    [self dismissViewControllerAnimated:YES completion:^{
    }];
    
}

@end
