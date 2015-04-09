//
//  OLProductGroup.h
//  KitePrintSDK
//
//  Created by Deon Botha on 09/04/2015.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OLProductGroup : NSObject

+ (NSArray *)groups;
+ (NSArray *)groupsWithFilters:(NSSet *)templateIds;

@property (nonatomic, copy, readonly) NSString *templateClass;
@property (nonatomic, copy, readonly) NSMutableArray *products;

@end
