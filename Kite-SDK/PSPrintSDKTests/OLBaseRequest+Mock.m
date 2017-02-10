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
@end

@interface OLKitePrintSDK ()
+ (NSString *)apiEndpoint;
+ (NSString *)apiVersion;
@end

@implementation OLBaseRequest (Mock)

- (void)mockTemplateStartStartWithCompletionHandler:(void(^)(NSInteger httpStatusCode, id json, NSError *error))handler{
    if (![self.url.absoluteString isEqualToString:[NSString stringWithFormat:@"%@/%@/template/?limit=100", [OLKitePrintSDK apiEndpoint], [OLKitePrintSDK apiVersion]]]){
        [self mockTemplateStartStartWithCompletionHandler:handler];
        return;
    }
    
    NSDictionary *response = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[OLKiteTestHelper class]] pathForResource:@"templates" ofType:@"json"]] options:0 error:nil];
    handler(200, response, nil);
}

@end
