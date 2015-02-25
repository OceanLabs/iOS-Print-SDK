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

+(NSArray *)products;
-(instancetype)initWithTemplate:(OLProductTemplate *)template;
- (NSUInteger) quantityToFulfillOrder;
- (NSString *)templateId;
- (NSString *)unitCost;
- (NSString *) packInfo;
- (NSString *) dimensions;
-(CGSize)serverImageSize;
-(void)setCoverImageToImageView:(UIImageView *)imageView;
-(void)setProductPhotography:(NSUInteger)i toImageView:(UIImageView *)imageView;
+(OLProduct *) productWithTemplateId:(NSString *)templateId;
- (NSDecimalNumber*) decimalNumberUnitCost;
+ (NSString*) unitCostWithCost:(NSDecimalNumber*)cost;

@end
