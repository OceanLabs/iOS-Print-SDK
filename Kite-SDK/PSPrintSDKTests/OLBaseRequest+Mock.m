//
//  OLBaseRequest+Mock.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 20/01/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

#import "OLBaseRequest+Mock.h"
#import "OLKiteTestHelper.h"
#import "OLKitePrintSDK.h"

@interface OLBaseRequest ()
@property (nonatomic, strong) NSURL *url;
@property (strong, nonatomic) NSString *requestBody;
@end

@interface OLKitePrintSDK ()
+ (NSString *)apiEndpoint;
+ (NSString *)apiVersion;
@end

@implementation OLBaseRequest (Mock)

- (void)mockTemplateStartWithCompletionHandler:(void(^)(NSInteger httpStatusCode, id json, NSError *error))handler{
    if (![self.url.absoluteString isEqualToString:[NSString stringWithFormat:@"%@/%@/template/?limit=100", [OLKitePrintSDK apiEndpoint], [OLKitePrintSDK apiVersion]]]){
        [self mockTemplateStartWithCompletionHandler:handler];
        return;
    }
    
    NSDictionary *response = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[OLKiteTestHelper class]] pathForResource:@"templates" ofType:@"json"]] options:0 error:nil];
    handler(200, response, nil);
}

- (void)mockTemplateServerErrorWithCompletionHandler:(void(^)(NSInteger httpStatusCode, id json, NSError *error))handler{
    if (![self.url.absoluteString isEqualToString:[NSString stringWithFormat:@"%@/%@/template/?limit=100", [OLKitePrintSDK apiEndpoint], [OLKitePrintSDK apiVersion]]]){
        [self mockTemplateServerErrorWithCompletionHandler:handler];
        return;
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        handler(kOLKiteSDKErrorCodeServerFault, nil, [NSError errorWithDomain:kOLKiteSDKErrorDomain code:kOLKiteSDKErrorCodeServerFault userInfo:@{NSLocalizedDescriptionKey : @"This is not the response you are looking for 👻"}]);
    });
    
}

- (void)mockCostRequestWithCompletionHandler:(void(^)(NSInteger httpStatusCode, id json, NSError *error))handler{
    if (![self.url.absoluteString isEqualToString:[NSString stringWithFormat:@"%@/%@/price/", [OLKitePrintSDK apiEndpoint], [OLKitePrintSDK apiVersion]]]){
        [self mockCostRequestWithCompletionHandler:handler];
        return;
    }
    
    NSMutableDictionary *response = [[NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[OLKiteTestHelper class]] pathForResource:@"cost" ofType:@"json"]] options:0 error:nil] mutableCopy];
    NSMutableArray *lineItems = [response[@"line_items"] mutableCopy];
    NSMutableDictionary *dict = [[lineItems firstObject] mutableCopy];
    dict[@"job_id"] = [[[[NSJSONSerialization JSONObjectWithData:[self.requestBody dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:nil] objectForKey:@"basket"] firstObject] objectForKey:@"job_id"];
    [lineItems replaceObjectAtIndex:0 withObject:dict];
    [response setObject:lineItems forKey:@"line_items"];
    handler(200, response, nil);
}

- (void)mockCostServerErrorWithCompletionHandler:(void(^)(NSInteger httpStatusCode, id json, NSError *error))handler{
    if (![self.url.absoluteString isEqualToString:[NSString stringWithFormat:@"%@/%@/price/", [OLKitePrintSDK apiEndpoint], [OLKitePrintSDK apiVersion]]]){
        [self mockCostServerErrorWithCompletionHandler:handler];
        return;
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        handler(kOLKiteSDKErrorCodeServerFault, nil, [NSError errorWithDomain:kOLKiteSDKErrorDomain code:kOLKiteSDKErrorCodeServerFault userInfo:@{NSLocalizedDescriptionKey : @"This is not the response you are looking for 👻"}]);
    });
    
}

@end
