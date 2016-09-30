//
//  NXOAuth2Request.h
//  OAuth2Client
//
//  Created by Tobias Kräntzer on 13.07.11.
//
//  Copyright 2011 nxtbgthng. All rights reserved.
//
//  Licenced under the new BSD-licence.
//  See README.md in this repository for
//  the full licence.
//

#import <Foundation/Foundation.h>

#import "OLOAuth2Connection.h"

@class OLOAuth2Account;

@interface OLOAuth2Request : NSObject {
@private
    NSDictionary *parameters;
    NSURL *resource;
    NSString *requestMethod;
    OLOAuth2Account *account;
    OLOAuth2Connection *connection;
    OLOAuth2Request *me;
}


#pragma mark Class Methods

+ (void)performMethod:(NSString *)method
           onResource:(NSURL *)resource
      usingParameters:(NSDictionary *)parameters
          withAccount:(OLOAuth2Account *)account
  sendProgressHandler:(OLOAuth2ConnectionSendingProgressHandler)progressHandler
      responseHandler:(OLOAuth2ConnectionResponseHandler)responseHandler;


#pragma mark Lifecycle

- (id)initWithResource:(NSURL *)url method:(NSString *)method parameters:(NSDictionary *)parameter;


#pragma mark Accessors

@property (nonatomic, strong, readwrite) OLOAuth2Account *account;

@property (nonatomic, strong, readwrite) NSString *requestMethod;
@property (nonatomic, strong, readwrite) NSURL *resource;
@property (nonatomic, strong, readwrite) NSDictionary *parameters;


#pragma mark Signed NSURLRequest

- (NSURLRequest *)signedURLRequest;


#pragma mark Perform Request

- (void)performRequestWithSendingProgressHandler:(OLOAuth2ConnectionSendingProgressHandler)progressHandler
                                 responseHandler:(OLOAuth2ConnectionResponseHandler)responseHandler;


#pragma mark Cancel

- (void)cancel;

@end
