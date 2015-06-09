//
//  NSObject+Utils.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 4/10/15.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import "NSObject+Utils.h"

@implementation NSObject (Utils)

- (void)safePerformSelector:(SEL)selector withObject:(id)object{
    if ([self respondsToSelector:selector]){
        IMP imp = [self methodForSelector:selector];
        void (*func)(id, SEL, id) = (void *)imp;
        func(self, selector, object);
    }
}

@end
