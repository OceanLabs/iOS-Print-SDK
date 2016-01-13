//
//  OLCollectionViewController.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 05/01/16.
//  Copyright © 2016 Kite.ly. All rights reserved.
//

#import "OLCollectionViewController.h"
#import "OLKiteABTesting.h"

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

@end
