//
//  OLViewController.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 05/01/16.
//  Copyright © 2016 Kite.ly. All rights reserved.
//

#import "OLViewController.h"
#import "OLKiteABTesting.h"
#import "UIViewController+OLMethods.h"

@implementation OLViewController

- (void)viewDidLoad{
    [super viewDidLoad];
    
    [self setupTheme];
}

- (void)setupTheme{
    if ([OLKiteABTesting sharedInstance].darkTheme){
        self.view.backgroundColor = [UIColor grayColor];
    }
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    
    self.isOffScreen = YES;
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    self.isOffScreen = NO;
}

- (void)tearDownLargeObjectsFromMemory{
    //To subclass
}

- (void)recreateTornDownLargeObjectsToMemory{
    //To subclass
}


@end
