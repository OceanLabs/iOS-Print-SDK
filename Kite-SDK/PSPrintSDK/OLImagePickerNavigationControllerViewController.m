//
//  OLImagePickerNavigationControllerViewController.m
//  KiteSDK
//
//  Created by Konstadinos Karayannis on 25/07/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

#import "OLImagePickerNavigationControllerViewController.h"

@interface OLImagePickerNavigationControllerViewController ()

@end

@implementation OLImagePickerNavigationControllerViewController

- (void)setAddingDelegate:(id<PhotobookAssetAddingDelegate>)addingDelegate {
    if ([self.viewControllers.firstObject respondsToSelector:@selector(setAddingDelegate:)]) {
        [(id<PhotobookAssetPicker>)self.viewControllers.firstObject setAddingDelegate:addingDelegate];
    }
}

- (id<PhotobookAssetAddingDelegate>)addingDelegate {
    return nil;
}

@end
