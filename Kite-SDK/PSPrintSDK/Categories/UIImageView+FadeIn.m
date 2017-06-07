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

#import "OLImageDownloader.h"

#import "UIImageView+FadeIn.h"
#import "OLImageDownloader.h"
#import "objc/runtime.h"
#import "UIImage+OLUtils.h"
#import "OLUserSession.h"
#import "OLAsset+Private.h"
#import "UIImage+ImageNamedInKiteBundle.h"

static char tasksKey;

@implementation UIImageView (FadeIn)
- (void)setAndFadeInImageWithURL:(NSURL *)url {
    [self setAndFadeInImageWithURL:url size:CGSizeZero placeholder:nil progress:NULL completionHandler:NULL];
}

- (void)setAndFadeInImageWithURL:(NSURL *)url size:(CGSize)size{
    [self setAndFadeInImageWithURL:url size:size placeholder:nil progress:NULL completionHandler:NULL];
}

- (void)setAndFadeInImageWithURL:(NSURL *)url size:(CGSize)size placeholder:(UIImage *)placeholder{
    [self setAndFadeInImageWithURL:url size:size placeholder:placeholder progress:NULL completionHandler:NULL];
}

- (void)setAndFadeInImageWithURL:(NSURL *)url size:(CGSize)size placeholder:(UIImage *)placeholder progress:(void(^)(float progress))progressHandler completionHandler:(void(^)(void))handler{
    for (id key in self.tasks.allKeys){
        if (![key isEqual:url]){
            [self.tasks[key] cancel];
        }
    }
    
    if (size.height == 0 || size.width == 0){
        size = [UIScreen mainScreen].bounds.size;
    }
    
    self.alpha = 0;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSURLSessionTask *task = [[OLImageDownloader sharedInstance] downloadImageAtURL:url progress:^(NSInteger downloaded, NSInteger total){
            if (progressHandler){
                float progress = (float)downloaded / (float)total;
                dispatch_async(dispatch_get_main_queue(), ^{
                    progressHandler(progress);
                });
            }
        }withCompletionHandler:^(UIImage *image, NSError *error){
            if ([self.tasks[url] state] == NSURLSessionTaskStateCanceling){
                [self.tasks removeObjectForKey:url];
                return;
            }
            if (error){
                return;
            }
            [self.tasks removeObjectForKey:url];
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                UIImage *resizedImage = [image shrinkToSize:size forScreenScale:[OLUserSession currentSession].screenScale aspectFit:self.contentMode == UIViewContentModeScaleAspectFit];
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.image = resizedImage;
                    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                        self.alpha = 1;
                    }completion:^(BOOL finished){
                        if (handler){
                            handler();
                        }
                    }];
                });
            });
        }];
        if (url){
            self.tasks[url] = task;
        }
    });
}

- (void)setAndFadeInImageWithPHAsset:(PHAsset *)asset size:(CGSize)size options:(PHImageRequestOptions *)options{
    [self setAndFadeInImageWithPHAsset:asset size:size options:options placeholder:nil progress:nil completionHandler:NULL];
}

- (void)setAndFadeInImageWithPHAsset:(PHAsset *)asset size:(CGSize)size options:(PHImageRequestOptions *)options placeholder:(UIImage *)placeholder{
    [self setAndFadeInImageWithPHAsset:asset size:size options:options placeholder:placeholder progress:nil completionHandler:NULL];
}

- (void)setAndFadeInImageWithOLAsset:(OLAsset *)asset size:(CGSize)size applyEdits:(BOOL)applyEdits placeholder:(UIImage *)placeholder progress:(void(^)(float progress))progressHandler completionHandler:(void(^)(void))handler{
    for (id key in self.tasks.allKeys){
        if (![asset isKindOfClass:[OLAsset class]] || ![key isEqual:asset.uuid]){
            [self.tasks removeObjectForKey:key];
        }
    }
    
    if ([asset isKindOfClass:[OLPlaceholderAsset class]]){
        self.image = [UIImage imageNamedInKiteBundle:@"plus"];
        self.contentMode = UIViewContentModeCenter;
        if (handler){
            handler();
        }
        return;
    }
    
    if (size.height == 0 || size.width == 0){
        size = CGSizeMake(self.frame.size.width * [UIScreen mainScreen].scale, self.frame.size.height * [UIScreen mainScreen].scale);
    }
    
    self.tasks[asset.uuid] = [NSNull null];
    [asset imageWithSize:self.frame.size applyEdits:applyEdits progress:^(float progress){
        if (progressHandler){
            if (!self.tasks[asset.uuid]){
                progressHandler(1);
                return;
            }
            progressHandler(progress);
        }
    }completion:^(UIImage *image, NSError *error){
        if (!self.tasks[asset.uuid]){
            return;
        }
        [self.tasks removeObjectForKey:asset.uuid];
        
        if (progressHandler){
            progressHandler(1);
        }
        
        self.contentMode = UIViewContentModeScaleAspectFill;
        self.alpha = 0;
        self.image = image;
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.alpha = 1;
        }completion:^(BOOL finished){
            if (handler){
                handler();
            }
        }];
    }];
}

- (void)setAndFadeInImageWithPHAsset:(PHAsset *)asset size:(CGSize)size options:(PHImageRequestOptions *)options placeholder:(UIImage *)placeholder progress:(void(^)(float progress))progressHandler completionHandler:(void(^)(void))handler{
    for (id key in self.tasks.allKeys){
        if (![key isEqual:asset.localIdentifier] && [self.tasks[key] isKindOfClass:[NSNumber class]]){
            PHImageRequestID requestID = (PHImageRequestID)[self.tasks[key] longValue];
            [[PHImageManager defaultManager] cancelImageRequest:requestID];
            [self.tasks removeObjectForKey:key];
        }
    }
    
    self.alpha = 0;
    
    if (progressHandler){
        options.progressHandler = ^(double progress, NSError *__nullable error, BOOL *stop, NSDictionary *__nullable info){
            if (progressHandler){
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (!self.tasks[asset.localIdentifier]){
                        progressHandler(1);
                        return;
                    }
                    progressHandler(progress);
                });
            }
        };
    }
    
    PHImageRequestID requestID = [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:size contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage *result, NSDictionary *info){
        if (!result){
            return;
        }
        if (![info[PHImageResultIsDegradedKey] boolValue]){
            if ([self.tasks.allKeys containsObject:asset.localIdentifier]){
                [self.tasks removeObjectForKey:asset.localIdentifier];
            }
            else{
                return;
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (options.progressHandler){
                BOOL dummyBool = NO;
                options.progressHandler(1, nil, &dummyBool, nil);
            }
            
            self.image = result;
            [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                self.alpha = 1;
            }completion:^(BOOL finished){
                if (handler){
                    handler();
                }
            }];
        });
    }];
    self.tasks[asset.localIdentifier] = [NSNumber numberWithLong:requestID];
}

- (NSMutableDictionary *)tasks{
    NSMutableDictionary *tasks = objc_getAssociatedObject(self, &tasksKey);
    if (tasks){
        return tasks;
    }
    tasks = [[NSMutableDictionary alloc] init];
    objc_setAssociatedObject(self, &tasksKey, tasks, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return tasks;
}

@end
