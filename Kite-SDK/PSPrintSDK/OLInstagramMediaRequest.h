//
//  InstagramMediaRequest.h
//  Ps
//
//  Created by Deon Botha on 09/12/2013.
//  Copyright (c) 2013 dbotha. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OLInstagramMediaRequest;
@class NXOAuth2Account;



typedef void (^InstagramMediaRequestCompletionHandler)(NSError *error, NSArray *media, OLInstagramMediaRequest *nextPageRequest);

@interface OLInstagramMediaRequest : NSObject

@property (nonatomic, readonly) NSString *baseURL;

- (void)cancel;
- (void)fetchMediaWithCompletionHandler:(InstagramMediaRequestCompletionHandler)completionHandler;
- (void)fetchMediaForAccount:(NXOAuth2Account *)account completionHandler:(InstagramMediaRequestCompletionHandler)completionHandler;

@end
