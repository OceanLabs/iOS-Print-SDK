//
//  OLURLShortener.m
//  KitePrintSDK
//
//  Created by Deon Botha on 13/02/2016.
//  Copyright © 2016 Kite.ly. All rights reserved.
//

#import "OLURLShortener.h"
#import "AFNetworking.h"
#import "OLConstants.h"

@implementation OLURLShortener

- (void)shortenURL:(NSString *)url handler:(OLURLShortenerHandler)handler {
    NSString *isGoodEndpoint = [NSString stringWithFormat:@"https://is.gd/create.php?format=json&url=%@", url];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:isGoodEndpoint]];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    operation.responseSerializer = [AFJSONResponseSerializer serializer];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *json = (NSDictionary *)responseObject;
        NSString *shortURL = [json objectForKey:@"shorturl"];
        if (shortURL == nil) {
            handler(nil, [NSError errorWithDomain:kOLKiteSDKErrorDomain code:kOLKiteSDKErrorCodeURLShorteningFailed userInfo:@{NSLocalizedDescriptionKey: @"URL shortening service is currently unavailable. Please try again."}]);
        } else {
            handler(shortURL, nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        handler(nil, error);
    }];
    
    [operation start];
}

@end
