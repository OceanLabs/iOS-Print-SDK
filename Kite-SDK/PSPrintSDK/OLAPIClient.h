//
//  OLAPIClient.h
//  KiteSDK
//
//  Created by Jaime Landazuri on 18/03/2019.
//  Copyright © 2019 Kite.ly. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^OLAPIClientRequestHandler)(NSInteger httpStatusCode, id json, NSError *error);

@interface OLAPIClient : NSObject

+ (id)shared;
- (void)getWithURL:(NSURL *)url parameters:(NSDictionary *)parameters headers:(NSDictionary *)headers requestIdentifier:(NSNumber **)requestIdentifier completionHandler:(OLAPIClientRequestHandler)completionHandler;
- (void)cancelRequestWithIdentifier:(NSNumber *)requestIdentifier;

@end
