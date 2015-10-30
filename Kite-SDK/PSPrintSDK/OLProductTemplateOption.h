//
//  OLProductTemplateOptions.h
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 30/10/15.
//  Copyright © 2015 Kite.ly. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OLProductTemplateOption : NSObject

@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *code;
@property (strong, nonatomic, readonly) NSArray <NSString *> *selections;


- (instancetype)initWithDictionary:(NSDictionary *)options;
- (NSString *)nameForSelection:(NSString *)selection;

@end
