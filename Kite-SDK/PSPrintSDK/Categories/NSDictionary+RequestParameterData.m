//
//  NSDictionary+RequestParameterData.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 08/03/16.
//  Copyright © 2016 Kite.ly. All rights reserved.
//

#import "NSDictionary+RequestParameterData.h"
#import "NSString+Formatting.h"

@implementation NSDictionary (RequestParameterData)

- (NSData *)requestParameterData{
    NSMutableArray *parts = [NSMutableArray array];
    
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id val, __unused BOOL *stop) {
        NSAssert([val isKindOfClass:[NSString class]], @"Only supports string values");
        if ([val isKindOfClass:[NSString class]]){
            [parts addObject:[NSString stringWithFormat:@"%@=%@", key, [NSString stringByURLEncoding:val]]];
        }
        
    }];
    
    return [[parts componentsJoinedByString:@"&"] dataUsingEncoding:NSUTF8StringEncoding];
}

@end
