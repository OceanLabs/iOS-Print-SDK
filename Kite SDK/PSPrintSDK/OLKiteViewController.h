//
//  KiteViewController.h
//  Kite Print SDK
//
//  Created by Konstadinos Karayannis on 12/24/14.
//  Copyright (c) 2014 Deon Botha. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OLProductTemplate.h"

@class OLPrintOrder;
@class OLKiteViewController;
@class ALAssetsGroup;
@class OLAsset;

@protocol OLKiteDelegate <NSObject>

@optional
- (BOOL)kiteController:(OLKiteViewController * _Nullable)controller isDefaultAssetsGroup:(ALAssetsGroup * _Nonnull)group;
- (BOOL)kiteControllerShouldAllowUserToAddMorePhotos:(OLKiteViewController * _Nullable)controller;
- (BOOL)shouldShowPhoneEntryOnCheckoutScreen;
@end

@interface OLKiteViewController : UIViewController

@property (weak, nonatomic) id<OLKiteDelegate> delegate;

@property (copy, nonatomic, nullable) NSString *userEmail; // speed up checkout by prepopulating the users email in the Shipping details if you know it
@property (copy, nonatomic, nullable) NSString *userPhone; // speed up checkout by prepopulating the users phone number in the Shipping details if you know it

// A set of product template_id strings which if present will restrict which products ultimate show up in the product selection journey
@property (copy, nonatomic, nullable) NSArray/*<NSString>*/ *filterProducts;

- (instancetype _Nullable)initWithAssets:(NSArray <OLAsset *>*_Nonnull)assets;
- (instancetype _Nullable)initWithPrintOrder:(OLPrintOrder *_Nullable)printOrder;
- (instancetype _Nullable)initWithAssets:(NSArray <OLAsset *>*_Nonnull)assets info:(NSDictionary *_Nullable)info;
- (instancetype _Nullable)initWithPrintOrder:(OLPrintOrder *_Nullable)printOrder info:(NSDictionary * _Nullable)info;

@end
