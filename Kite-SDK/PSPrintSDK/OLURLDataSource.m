//
//  URLAsset.m
//  Kite SDK
//
//  Created by Deon Botha on 20/01/2014.
//  Copyright (c) 2014 Deon Botha. All rights reserved.
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
