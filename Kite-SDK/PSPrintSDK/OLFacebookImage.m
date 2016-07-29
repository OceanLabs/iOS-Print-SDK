//
//  OLFacebookImage.m
//  FacebookImagePicker
//
//  Created by Deon Botha on 15/12/2013.
//  Copyright (c) 2013 Deon Botha. All rights reserved.
//

#import "OLFacebookImage.h"

static NSString *const kKeyThumbURL = @"co.oceanlabs.FacebookImagePicker.kKeyThumbURL";
static NSString *const kKeyFullURL = @"co.oceanlabs.FacebookImagePicker.kKeyFullURL";
static NSString *const kKeyAlbumId = @"co.oceanlabs.FacebookImagePicker.kKeyAlbumId";
static NSString *const kKeyUid = @"co.oceanlabs.FacebookImagePicker.kKeyUid";
static NSString *const kKeySourceImages = @"co.oceanlabs.FacebookImagePicker.kKeySourceImages";

static NSString *const kKeyURL = @"co.oceanlabs.FacebookImagePicker.kKeyURL";
static NSString *const kKeyImageWidth = @"co.oceanlabs.FacebookImagePicker.kKeyImageWidth";
static NSString *const kKeyImageHeight = @"co.oceanlabs.FacebookImagePicker.kKeyImageHeight";

@implementation OLFacebookImageURL
- (id)initWithURL:(NSURL *)url size:(CGSize)size {
    if (self = [super init]) {
        _url = url;
        _imageSize = size;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        _url = [aDecoder decodeObjectForKey:kKeyURL];
        CGFloat w = [aDecoder decodeDoubleForKey:kKeyImageWidth];
        CGFloat h = [aDecoder decodeDoubleForKey:kKeyImageHeight];
        _imageSize = CGSizeMake(w, h);
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_url forKey:kKeyURL];
    [aCoder encodeDouble:_imageSize.width forKey:kKeyImageWidth];
    [aCoder encodeDouble:_imageSize.height forKey:kKeyImageHeight];
}

- (id)copyWithZone:(NSZone *)zone {
    return [[OLFacebookImageURL allocWithZone:zone] initWithURL:_url size:_imageSize];
}

@end

@interface OLFacebookImage ()

@end

@implementation OLFacebookImage
- (id)initWithThumbURL:(NSURL *)thumbURL fullURL:(NSURL *)fullURL albumId:(NSString *)albumId uid:(NSString *)uid sourceImages:(NSArray/*<OLFacebookImageURL>*/ *)sourceImages {
    if (self = [super init]) {
        _thumbURL = thumbURL;
        _fullURL = fullURL;
        _albumId = albumId;
        _uid = uid;
        _sourceImages = sourceImages;
    }
    
    return self;
}

- (NSURL *)bestURLForSize:(CGSize)size {
    if (self.sourceImages.count == 0) {
        return self.thumbURL;
    }
    
    OLFacebookImageURL *bestSeen = self.sourceImages[0];
    for (OLFacebookImageURL *image in self.sourceImages) {
        if (image.imageSize.width >= size.width && image.imageSize.height >= size.height) {
            if (image.imageSize.width * image.imageSize.height < bestSeen.imageSize.width * bestSeen.imageSize.height) {
                bestSeen = image;
            }
        }
    }
    
    return bestSeen == nil ? self.thumbURL : bestSeen.url;
}

- (BOOL)isEqual:(id)object {
    if (![object isMemberOfClass:[OLFacebookImage class]]) {
        return NO;
    }
    
    return [self.uid isEqualToString:[object uid]];
}

- (NSUInteger)hash {
    return self.uid.hash;
}

#pragma mark - NSCoding protocol methods

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.thumbURL forKey:kKeyThumbURL];
    [aCoder encodeObject:self.fullURL forKey:kKeyFullURL];
    [aCoder encodeObject:self.albumId forKey:kKeyAlbumId];
    [aCoder encodeObject:self.uid forKey:kKeyUid];
    [aCoder encodeObject:self.sourceImages forKey:kKeySourceImages];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        _thumbURL = [aDecoder decodeObjectForKey:kKeyThumbURL];
        _fullURL = [aDecoder decodeObjectForKey:kKeyFullURL];
        _albumId = [aDecoder decodeObjectForKey:kKeyAlbumId];
        _uid = [aDecoder decodeObjectForKey:kKeyUid];
        _sourceImages = [aDecoder decodeObjectForKey:kKeySourceImages];
    }
    
    return self;
}

#pragma mark - NSCopying protocol methods

- (id)copyWithZone:(NSZone *)zone {
    OLFacebookImage *copy = [[OLFacebookImage allocWithZone:zone] initWithThumbURL:self.thumbURL fullURL:self.fullURL albumId:self.albumId uid:self.uid sourceImages:self.sourceImages];
    return copy;
}

@end
