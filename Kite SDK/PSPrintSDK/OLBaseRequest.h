//
//  OLBaseRequest.h
//  Kite SDK
//
//  Created by Deon Botha on 19/12/2013.
//  Copyright (c) 2013 Deon Botha. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
  kOLHTTPMethodGET,
  kOLHTTPMethodPOST,
  kOLHTTPMethodPATCH
} OLHTTPMethod;

typedef void (^OLBaseRequestHandler)(NSInteger httpStatusCode, id json, NSError *error);

@interface OLBaseRequest : NSObject
- (id)initWithURL:(NSURL *)url httpMethod:(OLHTTPMethod)method headers:(NSDictionary *)headers body:(NSString *)body;
- (void)startWithCompletionHandler:(OLBaseRequestHandler)handler;
- (void)cancel;
@end
