//
//  NXOAuth2Account.h
//  OAuth2Client
//
//  Created by Tobias Kräntzer on 12.07.11.
//
//  Copyright 2011 nxtbgthng. All rights reserved.
//
//  Licenced under the new BSD-licence.
//  See README.md in this repository for
//  the full licence.
//

#import <Foundation/Foundation.h>

@class OLOAuth2Client;
@class OLOAuth2AccessToken;

#pragma mark Notifications

extern NSString * const OLOAuth2AccountDidChangeUserDataNotification;
extern NSString * const OLOAuth2AccountDidChangeAccessTokenNotification;
extern NSString * const OLOAuth2AccountDidLoseAccessTokenNotification;
extern NSString * const OLOAuth2AccountDidFailToGetAccessTokenNotification;

#pragma mark -

@interface OLOAuth2Account : NSObject {
@private
    NSString *accountType;
    NSString *identifier;
    id <NSObject, NSCoding, NSCopying> userData;
    OLOAuth2Client *oauthClient;
    OLOAuth2AccessToken *accessToken;
}

#pragma mark Accessors

@property (nonatomic, copy, readonly) NSString *accountType;
@property (nonatomic, copy, readonly) NSString *identifier;
@property (nonatomic, copy) id <NSObject, NSCoding, NSCopying> userData;

@property (nonatomic, strong, readonly) OLOAuth2Client *oauthClient;
@property (nonatomic, strong, readonly) OLOAuth2AccessToken *accessToken;

@end
