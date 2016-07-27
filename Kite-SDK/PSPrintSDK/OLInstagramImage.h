//
//  InstagramImage.h
//  Ps
//
//  Created by Deon Botha on 10/12/2013.
//  Copyright (c) 2013 dbotha. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 The OLInstagramImage class provides a simple model object representation of an Instagram image.
 */
@interface OLInstagramImage : NSObject <NSCoding, NSCopying>

/**
 Initialises a new OLInstagramImage object instance.
 
 @param thumbURL The URL to access the thumbnail image
 @param fullURL The URL to access the standard resolution image
 @return Returns an initialised OLInstagramImage instance
 */
- (id)initWithThumbURL:(NSURL *)thumbURL fullURL:(NSURL *)fullURL;

/**
 The URL to access the thumb resolution image
 */
@property (nonatomic, readonly) NSURL *thumbURL;

/**
 The URL to access the standard resolution image
 */
@property (nonatomic, readonly) NSURL *fullURL;

@end
