//
//  OLCollectionViewController.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 05/01/16.
//  Copyright © 2016 Kite.ly. All rights reserved.
//

#import "OLCollectionViewController.h"
#import "OLKiteABTesting.h"
#import "UIViewController+OLMethods.h"

@implementation OLCollectionViewController

- (void)viewDidLoad{
    [super viewDidLoad];
    
    [self setupTheme];
}

- (void)setupTheme{
    if ([OLKiteABTesting sharedInstance].darkTheme){
        self.collectionView.backgroundColor = [UIColor grayColor];
    }
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    
    self.isOffScreen = YES;
    [self tearDownLargeObjectsFromMemory];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    self.isOffScreen = NO;
    [self recreateTornDownLargeObjectsToMemory];
}

- (void)tearDownLargeObjectsFromMemory{
    //To subclass
}

- (void)recreateTornDownLargeObjectsToMemory{
    //To subclass
}

@end
