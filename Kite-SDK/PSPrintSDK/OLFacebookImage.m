//
//  Modified MIT License
//
//  Copyright (c) 2010-2017 Kite Tech Ltd. https://www.kite.ly
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The software MAY ONLY be used with the Kite Tech Ltd platform and MAY NOT be modified
//  to be used with any competitor platforms. This means the software MAY NOT be modified
//  to place orders with any competitors to Kite Tech Ltd, all orders MUST go through the
//  Kite Tech Ltd platform servers.
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
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
- (id)initWithThumbURL:(NSURL *)thumbURL fullURL:(NSURL *)fullURL albumId:(NSString *)albumId uid:(NSString *)uid sourceImages:(NSArray *)sourceImages {
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

- (CGSize)bestSize {
    if (self.sourceImages.count == 0) {
        return CGSizeZero;
    }
    
    OLFacebookImageURL *bestSeen = self.sourceImages[0];
    for (OLFacebookImageURL *image in self.sourceImages) {
        if (image.imageSize.width * image.imageSize.height < bestSeen.imageSize.width * bestSeen.imageSize.height) {
            bestSeen = image;
        }
    }
    
    return bestSeen == nil ? CGSizeZero : bestSeen.imageSize;
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
