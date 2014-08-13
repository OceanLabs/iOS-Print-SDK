//
//  OLCheckoutDelegate.h
//  KitePrintSDK
//
//  Created by Kostas Karayannis on 07/08/2014.
//  Copyright (c) 2014 Deon Botha. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OLCheckoutDelegate <NSObject>

@optional
-(BOOL) shouldShowContinueShoppingButton;
-(void) userDidTapContinueShoppingButton;

@end
