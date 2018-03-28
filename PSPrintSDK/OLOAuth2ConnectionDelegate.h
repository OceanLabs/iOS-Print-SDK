//
//  NXOAuth2ConnectionDelegate.h
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

#import "OLOAuth2Constants.h"
#import "OLOAuth2TrustDelegate.h"

@class OLOAuth2Connection;


@protocol OLOAuth2ConnectionDelegate <NSObject, OLOAuth2TrustDelegate>
@optional

/*!
 *    The connection did receive a response.
 *
 *    This method is not called if the response was a 401 with an expired token & a refresh token.
 *    If so, then the token is refreshed & the connection will be automagically retried.
 */
- (void)oauthConnection:(OLOAuth2Connection *)connection didReceiveResponse:(NSURLResponse *)response;

/*!
 *    The connection did finish and recieved the whole data.
 */
- (void)oauthConnection:(OLOAuth2Connection *)connection didFinishWithData:(NSData *)data;

/*!
 *    The connection did fail with an error
 *
 *    The domain of the error is OLOAuth2ErrorDomain.
 *    Check the error code to see if it's been an HTTP error (OLOAuth2HTTPErrorCode). If so you can get the original error from the userInfo with the key OLOAuth2HTTPErrorKey
 */
- (void)oauthConnection:(OLOAuth2Connection *)connection didFailWithError:(NSError *)error;

/*!
 *    The connection recieved a new chunk of bytes.
 *
 *    Note: use connection.data.length and connection.expectedContentLength to get the overall progress
 */
- (void)oauthConnection:(OLOAuth2Connection *)connection didReceiveData:(NSData *)data;

/*!
 *    The connection did send new data
 */
- (void)oauthConnection:(OLOAuth2Connection *)connection didSendBytes:(unsigned long long)bytesSend ofTotal:(unsigned long long)bytesTotal;

/*!
 * The connection received a redirect response
 */
- (void)oauthConnection:(OLOAuth2Connection *)connection didReceiveRedirectToURL:(NSURL *)redirectURL;


@end
