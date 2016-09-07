//
//  OLFacebookAlbum.h
//  FacebookImagePicker
//
//  Created by Deon Botha on 15/12/2013.
//  Copyright (c) 2013 Deon Botha. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OLFacebookAlbum : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) NSURL *coverPhotoURL;
@property (nonatomic, copy) NSString *albumId;
@property (nonatomic, assign) NSUInteger photoCount;
@end
