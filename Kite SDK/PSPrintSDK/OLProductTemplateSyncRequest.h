//
//  OLTemplateSyncRequest.h
//  Kite SDK
//
//  Created by Deon Botha on 18/03/2014.
//  Copyright (c) 2014 Deon Botha. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^OLTemplateSyncRequestCompletionHandler)(NSArray *templates, NSError *error);

@interface OLProductTemplateSyncRequest : NSObject

- (void)sync:(OLTemplateSyncRequestCompletionHandler)handler;
- (void)cancel;

@end
