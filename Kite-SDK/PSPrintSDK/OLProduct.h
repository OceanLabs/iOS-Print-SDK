//
//  OLProduct.h
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 12/23/14.
//  Copyright (c) 2014 Deon Botha. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OLProductTemplate.h"

@interface OLProduct : NSObject

@property (strong, nonatomic) UIColor *labelColor;
@property (strong, nonatomic) OLProductTemplate *productTemplate;
@property (strong, nonatomic) id coverPhoto;
@property (strong, nonatomic) NSArray *productPhotos;
@property (strong, nonatomic) NSMutableDictionary *selectedOptions;
@property (strong, nonatomic) NSString *uuid;

+(NSArray *)products;
+(NSArray *)productsWithFilters:(NSArray *)allowedTemplateIds;
-(instancetype)initWithTemplate:(OLProductTemplate *)productTemplate;
- (NSUInteger)quantityToFulfillOrder;
- (NSString *)templateId;
- (NSString *)unitCost;
- (NSString *)packInfo;
- (NSString *)dimensions;
- (NSString *)detailsString;
- (BOOL)isValidProductForUI;
+(OLProduct *)productWithTemplateId:(NSString *)templateId;

@end
