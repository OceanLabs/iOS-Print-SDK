//
//  NSObject+Utils.h
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 4/10/15.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (Utils)

- (void)safePerformSelector:(SEL)selector withObject:(id)object;
- (id)safePerformSelectorWithReturn:(SEL)selector withObject:(id)object;

@end
