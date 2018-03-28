//
//  NXOAuth2Constants.m
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


#pragma mark OAuth2 Errors

NSString * const OLOAuth2ErrorDomain = @"OLOAuth2ErrorDomain";

NSInteger const OLOAuth2InvalidRequestErrorCode            = -1001;
NSInteger const OLOAuth2InvalidClientErrorCode            = -1002;
NSInteger const OLOAuth2UnauthorizedClientErrorCode        = -1003;
NSInteger const OLOAuth2RedirectURIMismatchErrorCode    = -1004;
NSInteger const OLOAuth2AccessDeniedErrorCode            = -1005;
NSInteger const OLOAuth2UnsupportedResponseTypeErrorCode = -1006;
NSInteger const OLOAuth2InvalidScopeErrorCode            = -1007;

NSInteger const OLOAuth2CouldNotRefreshTokenErrorCode    = -2001;


#pragma mark HTTP Errors

NSString * const OLOAuth2HTTPErrorDomain = @"OLOAuth2HTTPErrorDomain";
// The error code represents the http status code


#pragma mark UserInfo Keys

NSString * const OLOAuth2AccountStoreErrorKey = @"OLOAuth2AccountStoreErrorKey";
