//
//  OLPostcardPrintJob.h
//  Kite SDK
//
//  Created by Deon Botha on 30/12/2013.
//  Copyright (c) 2013 Deon Botha. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OLPrintJob.h"

@class OLAddress;
@class OLAsset;


@interface OLPostcardPrintJob : NSObject <OLPrintJob, NSCopying>

- (id)initWithTemplateId:(NSString *)templateId frontImageOLAsset:(OLAsset *)frontImageAsset message:(NSString *)message address:(OLAddress *)address;

- (id)initWithTemplateId:(NSString *)templateId frontImageOLAsset:(OLAsset *)frontImageAsset backImageOLAsset:(OLAsset *)backImageAsset;

@end
