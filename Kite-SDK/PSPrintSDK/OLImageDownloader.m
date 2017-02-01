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
#import "OLImageDownloadDelegate.h"
#import "OLConstants.h"

@interface OLImageDownloader ()

@property (strong, nonatomic) NSURLCache *cache;

@end

@implementation OLImageDownloader

+ (instancetype)sharedInstance {
    static dispatch_once_t once;
    static OLImageDownloader *sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
        NSURLCache *URLCache = [[NSURLCache alloc] initWithMemoryCapacity:20 * 1024 * 1024
                                                             diskCapacity:200 * 1024 * 1024
                                                                 diskPath:nil];
        [NSURLCache setSharedURLCache:URLCache];
    });
    return sharedInstance;
}

- (BOOL)cachedDataExistForURL:(NSURL *)url{
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
    NSCachedURLResponse *cachedResponse = [self.cache cachedResponseForRequest:request];
    return cachedResponse.data != nil;
}

- (NSURLSessionDownloadTask *)downloadImageAtURL:(NSURL *)url withCompletionHandler:(void(^)(UIImage *image, NSError *error))handler{
    return [self downloadImageAtURL:url progress:NULL withCompletionHandler:handler];
}

- (NSURLSessionDownloadTask *)downloadImageAtURL:(NSURL *)url progress:(void(^)(NSInteger progress, NSInteger total))progressHandler withCompletionHandler:(void(^)(UIImage *image, NSError *error))handler{
    return [self downloadImageAtURL:url priority:0.5 progress:progressHandler withCompletionHandler:handler];
}

- (NSURLSessionDownloadTask *)downloadImageAtURL:(NSURL *)url priority:(float)priority progress:(void(^)(NSInteger progress, NSInteger total))progressHandler withCompletionHandler:(void(^)(UIImage *image, NSError *error))handler{
    return [self downloadDataAtURL:url priority:priority progress:progressHandler withCompletionHandler:^(NSData *data, NSError *error){
        if (handler){
            if (error){
                handler(nil, error);
            }
            else{
                NSAssert(data, @"Should have data at this point");
                UIImage *image = [UIImage imageWithData:data];
                handler(image, nil);
            }
        }
    }];
}

- (NSURLSessionDownloadTask *)downloadDataAtURL:(NSURL *)url priority:(float)priority progress:(void(^)(NSInteger progress, NSInteger total))progressHandler withCompletionHandler:(void(^)(NSData *data, NSError *error))handler{
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
    
    NSCachedURLResponse *cachedResponse = [[NSURLCache sharedURLCache] cachedResponseForRequest:request];
    if (cachedResponse.data){
        if (handler){
            handler(cachedResponse.data, nil);
        }
        return nil;
    }
    
    OLImageDownloadDelegate *delegate = [[OLImageDownloadDelegate alloc] init];
    delegate.progressHandler = ^(NSURLSessionTask *task, NSInteger progress, NSInteger total){
        if (task.state != NSURLSessionTaskStateCanceling){
            if (progressHandler){
                progressHandler(progress, total);
            }
        }
    };
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.requestCachePolicy = NSURLRequestReturnCacheDataElseLoad;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:delegate delegateQueue:nil];
    
    delegate.completionHandler = ^(NSURLSessionTask *task, NSData *data, NSURLResponse *response, NSError *error) {
        if (task.state == NSURLSessionTaskStateCanceling){
            return;
        }
        if (error){
            if (handler){
                handler(nil, error);
            }
        }
        else if (data && [(NSHTTPURLResponse *)response statusCode] >= 200 && [(NSHTTPURLResponse *)response statusCode] <= 299){
            NSCachedURLResponse *cachedResponse = [[NSCachedURLResponse alloc] initWithResponse:response data:data userInfo:nil storagePolicy:NSURLCacheStorageAllowed];
            [configuration.URLCache storeCachedResponse:cachedResponse forRequest:request];
            if (handler){
                handler(data, nil);
            }
        }
        else{
            if (handler){
                handler(nil, [NSError errorWithDomain:kOLKiteSDKErrorDomain code:[(NSHTTPURLResponse *)response statusCode] userInfo:nil]);
            }
        }
    };
    
    NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithRequest:request];
    
    // iOS 8 doesn't call the delegate properly, handle here
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 9){
        downloadTask = [session downloadTaskWithRequest:request completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error){
            NSData *data = [NSData dataWithContentsOfURL:location];
            if (error){
                if (handler){
                    handler(nil, error);
                }
            }
            else if (data && [(NSHTTPURLResponse *)response statusCode] >= 200 && [(NSHTTPURLResponse *)response statusCode] <= 299){
                NSCachedURLResponse *cachedResponse = [[NSCachedURLResponse alloc] initWithResponse:response data:data userInfo:nil storagePolicy:NSURLCacheStorageAllowed];
                [configuration.URLCache storeCachedResponse:cachedResponse forRequest:request];
                if (handler){
                    handler(data, nil);
                }
            }
            else{
                if (handler){
                    handler(nil, [NSError errorWithDomain:kOLKiteSDKErrorDomain code:[(NSHTTPURLResponse *)response statusCode] userInfo:nil]);
                }
            }
        }];
    }
    
    downloadTask.priority = priority;
    [downloadTask resume];
    [session finishTasksAndInvalidate];
    return downloadTask;
}

@end
