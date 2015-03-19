//
//  NSArray+QueryingExtras.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 3/19/15.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import "NSArray+QueryingExtras.h"

@implementation NSArray (QueryingExtras)

- (BOOL)containsObjectIdenticalTo:(id)anObject{
    return [self indexOfObjectIdenticalTo:anObject] != NSNotFound;
}

@end
