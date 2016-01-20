//
//  Modified MIT License
//
//  Copyright (c) 2010-2016 Kite Tech Ltd. https://www.kite.ly
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

#ifdef COCOAPODS
#import <SDWebImage/SDWebImageManager.h>
#else
#import "SDWebImageManager.h"
#endif

#import "OLURLDataSource.h"

static NSString *const kKeyURL = @"co.oceanlabs.pssdk.kKeyURL";

@interface OLURLDataSource ()
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) id<SDWebImageOperation> inProgressDownload;
@end

@implementation OLURLDataSource

- (id)initWithURLString:(NSString *)url {
    if (self = [super init]) {
        self.url = [NSURL URLWithString:url];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.url = [aDecoder decodeObjectForKey:kKeyURL];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.url forKey:kKeyURL];
}

- (NSString *)mimeType {
    return kOLMimeTypeJPEG;
}

- (void)dataLengthWithCompletionHandler:(GetDataLengthHandler)handler {
    self.inProgressDownload = [[SDWebImageManager sharedManager] downloadImageWithURL:self.url
                                                                              options:0
                                                                             progress:nil
                                                                            completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                                                                                dispatch_async(dispatch_get_main_queue(), ^{
                                                                                    if (finished) {
                                                                                        self.inProgressDownload = nil;
                                                                                        if (image) {
                                                                                            NSData *data = UIImageJPEGRepresentation(image, 0.6);
                                                                                            handler(data.length, error);
                                                                                        } else {
                                                                                            handler(0, error);
                                                                                        }
                                                                                    }
                                                                                });
                                                                            }];
}

- (void)dataWithCompletionHandler:(GetDataHandler)handler {
    self.inProgressDownload = [[SDWebImageManager sharedManager] downloadImageWithURL:self.url
                                                                              options:0
                                                                             progress:nil
                                                                            completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                                                                                dispatch_async(dispatch_get_main_queue(), ^{
                                                                                    if (finished) {
                                                                                        self.inProgressDownload = nil;
                                                                                        if (image) {
                                                                                            handler(UIImageJPEGRepresentation(image, 0.6), error);
                                                                                        } else {
                                                                                            handler(nil, error);
                                                                                        }
                                                                                    }
                                                                                });
                                                                            }];
}

- (void)cancelAnyLoadingOfData {
    [self.inProgressDownload cancel];
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[OLURLDataSource class]]) {
        return NO;
    }
    
    return [self.url isEqual:[object url]];
}

- (NSUInteger)hash {
    return self.url.hash;
}

@end
