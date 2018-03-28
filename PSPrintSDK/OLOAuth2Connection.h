//
//  NXOAuth2Connection.h
//  OAuth2Client
//
//  Created by Ullrich Schäfer on 27.08.10.
//
//  Copyright 2010 nxtbgthng. All rights reserved.
//
//  Licenced under the new BSD-licence.
//  See README.md in this repository for
//  the full licence.
//

#import <Foundation/Foundation.h>

#import "OLOAuth2Constants.h"

@class OLOAuth2Client;
@protocol OLOAuth2ConnectionDelegate;


/*!
 *    The connection
 *
 *    OLOAuth2Connection is a wrapper around OLURLConnection.
 *    It's main purpose is to simplify the delegates & to provide a context
 *    ivar that can be used to put a connection object in a certain context.
 *    The context may be compared to a tag.
 *
 *    OLOAuth2Connection only provides asynchronous connections as synchronous
 *    connections are strongly discouraged.
 *
 *    The connection works together with the OAuth2 Client to sign a request
 *    before sending it. If no client is passed in the connection will sent
 *    unsigned requests.
 */


#ifndef OLOAuth2ConnectionDebug
#define OLOAuth2ConnectionDebug 0
#endif



extern NSString * const OLOAuth2ConnectionDidStartNotification;
extern NSString * const OLOAuth2ConnectionDidEndNotification;


typedef void(^OLOAuth2ConnectionResponseHandler)(NSURLResponse *response, NSData *responseData, NSError *error);
typedef void(^OLOAuth2ConnectionSendingProgressHandler)(unsigned long long bytesSend, unsigned long long bytesTotal);


@interface OLOAuth2Connection : NSObject {
@private
    NSURLConnection        *connection;
    NSMutableURLRequest    *request;
    NSURLResponse        *response;
    NSDictionary        *requestParameters;
    
    NSMutableData        *data;
    BOOL                savesData;
    
    id                    context;
    NSDictionary        *userInfo;
    
    OLOAuth2Client        *client;
    
    NSObject<OLOAuth2ConnectionDelegate>    *__unsafe_unretained delegate;    // assigned
    
    OLOAuth2ConnectionResponseHandler responseHandler;
    OLOAuth2ConnectionSendingProgressHandler sendingProgressHandler;
    
    BOOL                sendConnectionDidEndNotification;
    
#if (OLOAuth2ConnectionDebug)
    NSDate *startDate;
#endif
}

@property (nonatomic, unsafe_unretained) NSObject<OLOAuth2ConnectionDelegate>    *delegate;
@property (nonatomic, strong, readonly) NSData *data;
@property (nonatomic, assign) BOOL savesData;
@property (nonatomic, assign, readonly) long long expectedContentLength;
@property (nonatomic, strong, readonly) NSURLResponse *response;
@property (nonatomic, assign, readonly) NSInteger statusCode;
@property (nonatomic, strong) id context;
@property (nonatomic, strong) NSDictionary *userInfo;
@property (nonatomic, strong, readonly) OLOAuth2Client *client;

- (id) initWithRequest:(NSMutableURLRequest *)request
     requestParameters:(NSDictionary *)requestParameters
           oauthClient:(OLOAuth2Client *)client
sendingProgressHandler:(OLOAuth2ConnectionSendingProgressHandler)sendingProgressHandler
       responseHandler:(OLOAuth2ConnectionResponseHandler)responseHandler;

- (id)initWithRequest:(NSMutableURLRequest *)request
    requestParameters:(NSDictionary *)requestParameters
          oauthClient:(OLOAuth2Client *)client
             delegate:(NSObject<OLOAuth2ConnectionDelegate> *)delegate;

- (void)cancel;

- (void)retry;

@end
