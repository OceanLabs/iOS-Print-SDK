//
//  OLFacebookAlbum.m
//  FacebookImagePicker
//
//  Created by Deon Botha on 15/12/2013.
//  Copyright (c) 2013 Deon Botha. All rights reserved.
//

#import "OLFacebookAlbum.h"

@implementation OLFacebookAlbum

- (BOOL)isEqual:(id)object{
    if (![object isKindOfClass:[self class]]) {
        return NO;
    }
    
    if (object == self) {
        return YES;
    }
    
    return [self.albumId isEqualToString:[(OLFacebookAlbum *)object albumId]];
}

@end
