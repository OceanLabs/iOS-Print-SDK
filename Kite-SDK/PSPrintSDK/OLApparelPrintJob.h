//
//  OLApparelPrintJob.h
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 23/6/15.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OLPrintJob.h"

@interface OLApparelPrintJob : NSObject <OLPrintJob, NSCopying>

- (id)initWithTemplateId:(NSString *)templateId OLAssets:(NSDictionary<NSString *, OLAsset *> *)assets;
@property (strong, nonatomic) NSDictionary<NSString *, OLAsset *> *assets;

@end
