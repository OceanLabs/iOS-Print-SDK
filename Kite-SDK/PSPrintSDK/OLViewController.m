//
//  OLViewController.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 05/01/16.
//  Copyright © 2016 Kite.ly. All rights reserved.
//

#import "OLViewController.h"
#import "OLKiteABTesting.h"

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

@end
