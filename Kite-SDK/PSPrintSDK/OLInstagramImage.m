//
//  InstagramImage.m
//  Ps
//
//  Created by Deon Botha on 10/12/2013.
//  Copyright (c) 2013 dbotha. All rights reserved.
//

#import "OLInstagramImage.h"

static NSString *const kKeyThumbURL = @"co.oceanlabs.InstagramImagePicker.kKeyThumbURL";
static NSString *const kKeyFullURL = @"co.oceanlabs.InstagramImagePicker.kKeyFullURL";

@implementation OLInstagramImage
- (id)initWithThumbURL:(NSURL *)thumbURL fullURL:(NSURL *)fullURL {
    if (self = [super init]) {
        _thumbURL = thumbURL;
        _fullURL = fullURL;
    }
    
    return self;
}

- (BOOL)isEqual:(id)object {
    if (![object isMemberOfClass:[OLInstagramImage class]]) {
        return NO;
    }
    
    return [self.thumbURL isEqual:[object thumbURL]] && [self.fullURL isEqual:[object fullURL]];
}

- (NSUInteger)hash {
    return self.thumbURL.hash + self.fullURL.hash;
}

#pragma mark - NSCoding protocol methods

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.thumbURL forKey:kKeyThumbURL];
    [aCoder encodeObject:self.fullURL forKey:kKeyFullURL];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        _thumbURL = [aDecoder decodeObjectForKey:kKeyThumbURL];
        _fullURL = [aDecoder decodeObjectForKey:kKeyFullURL];
    }
    
    return self;
}

#pragma mark - NSCopying protocol methods

- (id)copyWithZone:(NSZone *)zone {
    OLInstagramImage *copy = [[OLInstagramImage allocWithZone:zone] initWithThumbURL:self.thumbURL fullURL:self.fullURL];
    return copy;
}

@end
