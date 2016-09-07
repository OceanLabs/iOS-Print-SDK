//
//  OLFacebookPhotosForAlbumRequest.h
//  FacebookImagePicker
//
//  Created by Deon Botha on 16/12/2013.
//  Copyright (c) 2013 Deon Botha. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OLFacebookAlbum;
@class OLFacebookPhotosForAlbumRequest;
@class OLFacebookImage;

typedef void (^OLFacebookPhotosForAlbumRequestHandler)(NSArray<OLFacebookImage *> *photos, NSError *error, OLFacebookPhotosForAlbumRequest *nextPageRequest);

@interface OLFacebookPhotosForAlbumRequest : NSObject

- (id)initWithAlbum:(OLFacebookAlbum *)album;

- (void)cancel;
- (void)getPhotos:(OLFacebookPhotosForAlbumRequestHandler)handler;

@end
