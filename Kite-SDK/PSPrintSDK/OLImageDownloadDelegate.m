//
//  OLImageDownloadDelegate.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 19/05/16.
//  Copyright © 2016 Kite.ly. All rights reserved.
//

#import "OLImageDownloadDelegate.h"

@implementation OLImageDownloadDelegate

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite{
    if (self.progressHandler){
        self.progressHandler(totalBytesWritten, totalBytesExpectedToWrite);
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location{
    if (self.completionHandler){
        self.completionHandler([NSData dataWithContentsOfURL:location], downloadTask.response, nil);
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{
    if (self.completionHandler){
        self.completionHandler(nil, task.response, error);
    }
}

@end
