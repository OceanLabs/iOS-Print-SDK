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

#import <UIKit/UIKit.h>

@interface OLFacebookImageURL : NSObject <NSCoding, NSCopying>
- (id)initWithURL:(NSURL *)url size:(CGSize)size;
@property (nonatomic, readonly) NSURL *url;
@property (nonatomic, readonly) CGSize imageSize;
@end

/**
 The OLFacebookImage class provides a simple model object representation of an Facebook album photo.
 */
@interface OLFacebookImage : NSObject <NSCoding, NSCopying>

/**
 Initialises a new OLFacebookImage object instance.
 
 @param thumbURL The URL to access the thumbnail image
 @param fullURL The URL to access the standard resolution image
 @param albumId The Facebook album id to which this photo belongs
 @param uid The Facebook photo unique id
 @return Returns an initialised OLFacebookImage instance
 */
- (id)initWithThumbURL:(NSURL *)thumbURL fullURL:(NSURL *)fullURL albumId:(NSString *)albumId uid:(NSString *)uid sourceImages:(NSArray *)sourceImages;

- (NSURL *)bestURLForSize:(CGSize)size;

/**
 The URL to access the thumb resolution image
 */
@property (nonatomic, readonly) NSURL *thumbURL;

/**
 The URL to access the standard resolution image
 */
@property (nonatomic, readonly) NSURL *fullURL;

- (CGSize)bestSize;

/**
 The Facebook album id to which this photo belongs
 */
@property (nonatomic, readonly) NSString *albumId;

/**
 The Facebook photo unique id
 */
@property (nonatomic, readonly) NSString *uid;

@property (nonatomic, readonly) NSArray *sourceImages;

@end
