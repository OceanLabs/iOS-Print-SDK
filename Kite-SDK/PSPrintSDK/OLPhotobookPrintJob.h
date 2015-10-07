//
//  OLPhotobookPrintJob.h
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 23/6/15.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OLPrintJob.h"

@interface OLPhotobookPrintJob : NSObject <OLPrintJob, NSCopying>

- (id)initWithTemplateId:(NSString *)templateId OLAssets:(NSArray <OLAsset *>*)assets;
@property (strong, nonatomic) OLAsset *frontCover;
@property (strong, nonatomic) OLAsset *backCover;

@end
