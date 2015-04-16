//
//  UIViewController+TraitCollectionCompatibility.h
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 4/16/15.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import <UIKit/UIKit.h>

// This category aims to provide support to pre-iOS 8 devices that lack trait collections.
// Get rid of it as soon as iOS 7 support is dropped

@interface UIViewController (TraitCollectionCompatibility)

- (BOOL)isHorizontalSizeClassCompact;

@end
