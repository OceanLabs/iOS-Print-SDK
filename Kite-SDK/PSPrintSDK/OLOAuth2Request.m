//
//  NXOAuth2Request.m
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

#import "OLOAuth2Connection.h"
#import "OLOAuth2ConnectionDelegate.h"
#import "OLOAuth2AccessToken.h"
#import "OLOAuth2Account.h"
#import "OLOAuth2Client.h"
#import "OLOAuth2PostBodyStream.h"

#import "NSURL+OLOAuth2.h"

#import "OLOAuth2Request.h"

@interface OLOAuth2Request () <OLOAuth2ConnectionDelegate>
@property (nonatomic,  strong, readwrite) OLOAuth2Connection *connection;
@property (nonatomic,  strong, readwrite) OLOAuth2Request *me;
#pragma mark Apply Parameters
- (void)applyParameters:(NSDictionary *)someParameters onRequest:(NSMutableURLRequest *)aRequest;
@end


@implementation OLOAuth2Request

#pragma mark Class Methods

+ (void)performMethod:(NSString *)aMethod
           onResource:(NSURL *)aResource
      usingParameters:(NSDictionary *)someParameters
          withAccount:(OLOAuth2Account *)anAccount
  sendProgressHandler:(OLOAuth2ConnectionSendingProgressHandler)progressHandler
      responseHandler:(OLOAuth2ConnectionResponseHandler)responseHandler;
{
    OLOAuth2Request *request = [[OLOAuth2Request alloc] initWithResource:aResource
                                                                  method:aMethod
                                                              parameters:someParameters];
    request.account = anAccount;
    [request performRequestWithSendingProgressHandler:progressHandler responseHandler:responseHandler];
}


#pragma mark Lifecycle

- (id)initWithResource:(NSURL *)aResource method:(NSString *)aMethod parameters:(NSDictionary *)someParameters;
{
    self = [super init];
    if (self) {
        resource = aResource;
        parameters = someParameters;
        requestMethod = aMethod;
    }
    return self;
}


#pragma mark Accessors

@synthesize parameters;
@synthesize resource;
@synthesize requestMethod;
@synthesize account;
@synthesize connection;
@synthesize me;


#pragma mark Signed NSURLRequest

- (NSURLRequest *)signedURLRequest;
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.resource];
    
    [request setHTTPMethod:self.requestMethod];
    
    [self applyParameters:self.parameters onRequest:request];
    
    if (self.account.oauthClient.userAgent && ![request valueForHTTPHeaderField:@"User-Agent"]) {
        [request setValue:self.account.oauthClient.userAgent forHTTPHeaderField:@"User-Agent"];
    }
    
    if (self.account) {
        NSString *oauthAuthorizationHeader = [NSString stringWithFormat:@"%@ %@", self.account.accessToken.tokenType, self.account.accessToken.accessToken];
        [request setValue:oauthAuthorizationHeader forHTTPHeaderField:@"Authorization"];
    }
    
    return request;
}


#pragma mark Perform Request

- (void)performRequestWithSendingProgressHandler:(OLOAuth2ConnectionSendingProgressHandler)progressHandler
                                 responseHandler:(OLOAuth2ConnectionResponseHandler)responseHandler;
{
    NSAssert(self.me == nil, @"This object an only perform one request at the same time.");
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.resource];
    [request setHTTPMethod:self.requestMethod];
    self.connection = [[OLOAuth2Connection alloc] initWithRequest:request
                                                requestParameters:self.parameters
                                                      oauthClient:self.account.oauthClient
                                           sendingProgressHandler:progressHandler
                                                  responseHandler:responseHandler];
    self.connection.delegate = self;
    
    // Keep request object alive during the request is performing.
    self.me = self;
}


#pragma mark Cancel

- (void)cancel;
{
    [self.connection cancel];
    self.connection = nil;
    
    // Release the referens to self (break cycle) after the current run loop.
    __autoreleasing __attribute__((unused)) id runloopMe = self.me;
    self.me = nil;
}

#pragma mark OLOAuth2ConnectionDelegate

- (void)oauthConnection:(OLOAuth2Connection *)connection didFinishWithData:(NSData *)data;
{
    self.connection = nil;
    
    // Release the referens to self (break cycle) after the current run loop.
    __autoreleasing __attribute__((unused)) id runloopMe = self.me;
    self.me = nil;
}

- (void)oauthConnection:(OLOAuth2Connection *)connection didFailWithError:(NSError *)error;
{
    self.connection = nil;
    
    // Release the reference to self (break cycle) after the current run loop.
    __autoreleasing __attribute__((unused)) id runloopMe = self.me;
    self.me = nil;
}


#pragma mark Apply Parameters

- (void)applyParameters:(NSDictionary *)someParameters onRequest:(NSMutableURLRequest *)aRequest;
{
    if (!someParameters) return;
    
    NSString *httpMethod = [aRequest HTTPMethod];
    if (![@[@"POST",@"PUT",@"PATCH"] containsObject: [httpMethod uppercaseString]]) {
        aRequest.URL = [aRequest.URL oloauth2_URLByAddingParameters:someParameters];
    } else {
        NSInputStream *postBodyStream = [[OLOAuth2PostBodyStream alloc] initWithParameters:parameters];
        
        NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", [(OLOAuth2PostBodyStream *)postBodyStream boundary]];
        NSString *contentLength = [NSString stringWithFormat:@"%llu", [(OLOAuth2PostBodyStream *)postBodyStream length]];
        [aRequest setValue:contentType forHTTPHeaderField:@"Content-Type"];
        [aRequest setValue:contentLength forHTTPHeaderField:@"Content-Length"];
        
        [aRequest setHTTPBodyStream:postBodyStream];
    }
}

@end
