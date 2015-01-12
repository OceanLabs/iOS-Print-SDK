//
//  KiteViewController.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 12/24/14.
//  Copyright (c) 2014 Deon Botha. All rights reserved.
//

#import "OLKiteViewController.h"
#import "OLPrintOrder.h"
#import "OLProductTemplate.h"
#import "OLProductHomeViewController.h"

@interface OLKiteViewController ()

@property (assign, nonatomic) BOOL alreadyTransistioned;
@property (strong, nonatomic) UIViewController *nextVc;
@property (strong, nonatomic) OLPrintOrder *printOrder;

@end

@implementation OLKiteViewController

- (id)initWithPrintOrder:(OLPrintOrder *)printOrder {
    NSAssert(printOrder != nil, @"KiteViewController requires a non-nil print order");
    if (self = [super init]) {
        self.printOrder = printOrder;
        //[self.printOrder preemptAssetUpload];
        [OLProductTemplate sync];
    }
    
    return self;
}

-(void)viewDidLoad{
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"OLKiteStoryboard" bundle:nil];
    NSAssert(self.printOrder != nil, @"KiteViewController requires a non-nil print order");
    
    if (!self.navigationController){
        self.nextVc = [sb instantiateViewControllerWithIdentifier:@"ProductsNavigationController"];
        ((UINavigationController *)self.nextVc).topViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismiss)];
        [(OLProductHomeViewController *)self.nextVc setPrintOrder:self.printOrder];
        [self.view addSubview:self.nextVc.view];
    }
    else{
        self.nextVc = [sb instantiateViewControllerWithIdentifier:@"ProductHomeViewController"];
        [(OLProductHomeViewController *)self.nextVc setPrintOrder:self.printOrder];
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
