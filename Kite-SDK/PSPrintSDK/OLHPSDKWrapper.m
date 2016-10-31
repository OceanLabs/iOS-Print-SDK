//
//  OLHPSDKWrapper.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 05/10/2016.
//  Copyright © 2016 Kite.ly. All rights reserved.
//

#import "OLHPSDKWrapper.h"

@implementation OLHPSDKWrapper

+ (id)printItemWithAsset:(UIImage *)image{
    Class MPPrintItemFactoryClass = NSClassFromString (@"MPPrintItemFactory");
    SEL aSelector = NSSelectorFromString(@"printItemWithAsset:");
    IMP imp = [MPPrintItemFactoryClass methodForSelector:aSelector];
    id (*func)(id, SEL, id) = (void *)imp;
    
    return func(MPPrintItemFactoryClass, aSelector, image);
}

+ (id)printViewControllerWithDelegate:(id)delegate dataSource:(id)dataSource printItem:(id)printItem fromQueue:(BOOL)fromQueue settingsOnly:(BOOL)settingsOnly{
    Class MPClass = NSClassFromString (@"MP");
    SEL aSelector = NSSelectorFromString(@"sharedInstance");
    IMP imp = [MPClass methodForSelector:aSelector];
    id (*func)(id, SEL) = (void *)imp;
    
    id sharedInstance = func(MPClass, aSelector);
    aSelector = NSSelectorFromString(@"printViewControllerWithDelegate:dataSource:printItem:fromQueue:settingsOnly:");
    imp = [sharedInstance methodForSelector:aSelector];
    id (*func1)(id, SEL, id, id, id, BOOL, BOOL) = (void *)imp;
    
    return func1(sharedInstance, aSelector, delegate, dataSource, printItem, fromQueue, settingsOnly);
}

@end
