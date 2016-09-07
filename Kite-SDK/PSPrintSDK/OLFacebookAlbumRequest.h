//
//  OLFacebookAlbumRequest.h
//  FacebookImagePicker
//
//  Created by Deon Botha on 15/12/2013.
//  Copyright (c) 2013 Deon Botha. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OLFacebookAlbumRequest;

typedef void (^OLFacebookAlbumRequestHandler)(NSArray/*<OLFacebookAlbum>*/ *albums, NSError *error, OLFacebookAlbumRequest *nextPageRequest);

@interface OLFacebookAlbumRequest : NSObject
- (void)cancel;
- (void)getAlbums:(OLFacebookAlbumRequestHandler)handler;
@end
