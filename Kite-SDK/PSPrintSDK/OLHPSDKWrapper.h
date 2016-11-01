//
//  OLHPSDKWrapper.h
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 05/10/2016.
//  Copyright © 2016 Kite.ly. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OLHPSDKWrapper : NSObject

+ (id)printItemWithAsset:(UIImage *)image;
+ (id)printViewControllerWithDelegate:(id)delegate dataSource:(id)dataSource printItem:(id)printItem fromQueue:(BOOL)fromQueue settingsOnly:(BOOL)settingsOnly;

@end
