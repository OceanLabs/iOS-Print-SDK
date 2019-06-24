//
//  OLCalendarPrintJob.m
//  KiteSDK
//
//  Created by Konstadinos Karayannis on 06/08/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

#import "OLCalendarPrintJob.h"

@implementation OLCalendarPrintJob

@synthesize selectedShippingMethod;

- (NSDictionary *)jsonRepresentation {
    NSMutableArray *assets = [[NSMutableArray alloc] init];

    for (NSUInteger i = 0; i < self.assetsForUploading.count; i = i + 4) {
        NSMutableDictionary *page = [@{ @"page": @((i / 4) + 1), @"layoutId": @1 } mutableCopy];
        
        NSMutableArray *images = [[NSMutableArray alloc] init];
        for (NSUInteger pos = 0; pos < 4; pos++) {
            NSInteger assetIndex = i + pos;
            
            id asset;
            if (assetIndex < self.assetsToUpload.count && self.assetsToUpload[assetIndex].uploadUrl) {
                asset = self.assetsToUpload[assetIndex].uploadUrl;
            } else {
                asset = [NSNull null];
            }
            [images addObject:@{ @"position": @(pos + 1), @"asset": asset }];
        }
        page[@"images"] = [images copy];
        
        [assets addObject: page];
    }
    
    NSMutableDictionary *json = [[NSMutableDictionary alloc] init];
    json[@"template_id"] = self.templateId;
    json[@"assets"] = assets;
    json[@"job_id"] = [self uuid];
    json[@"multiples"] = [NSNumber numberWithInteger:self.extraCopies + 1];
    json[@"shipping_class"] = [NSNumber numberWithInteger:selectedShippingMethod.id];
    json[@"starting_month"] = @1;
    
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitYear fromDate:[NSDate date]];
    json[@"starting_year"] = @(components.year);
    
    return json;
}

@end
