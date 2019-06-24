//
//  OLPolaroidPrintJob.m
//  KiteSDK
//
//  Created by Jaime Landazuri on 19/03/2019.
//  Copyright © 2019 Kite.ly. All rights reserved.
//

#import "OLPolaroidPrintJob.h"
#import "OLAsset+Private.h"

@implementation OLPolaroidPrintJob

@synthesize selectedShippingMethod;

- (NSDictionary *)jsonRepresentation {
    NSMutableArray *assets = [[NSMutableArray alloc] init];
    NSMutableArray *pdfs = [[NSMutableArray alloc] init];
    
    for (NSUInteger i = 0; i < self.assetsForUploading.count; i++) {
        OLAsset *asset = self.assetsForUploading[i];

        for (NSInteger j = 0; j <= asset.extraCopies; j++) {
            NSMutableDictionary *assetDictionary = [[NSMutableDictionary alloc] init];
            if (i < self.assetsToUpload.count && self.assetsToUpload[i].uploadUrl) {
                assetDictionary[@"asset"] = self.assetsToUpload[i].uploadUrl;
            } else {
                assetDictionary[@"asset"] = @(asset.assetId);
            }
        
            NSString *borderText = asset.edits.bottomBorderText.text;
            assetDictionary[@"text"] = borderText ? borderText : @"";
        
            [assets addObject:[assetDictionary copy]];
        }
    }
    
    NSMutableDictionary *json = [[NSMutableDictionary alloc] init];
    json[@"template_id"] = self.templateId;
    json[@"assets"] = assets;
    if (pdfs.count > 0) {
        json[@"pdf"] = [pdfs firstObject];
    }
    
    json[@"job_id"] = [self uuid];
    json[@"multiples"] = [NSNumber numberWithInteger:self.extraCopies + 1];
    json[@"shipping_class"] = [NSNumber numberWithInteger:selectedShippingMethod.id];
    
    return json;
}

@end
