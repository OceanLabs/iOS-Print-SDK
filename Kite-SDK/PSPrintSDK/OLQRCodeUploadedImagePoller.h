//
//  QRCodeUploadedImagePoller.h
//  KitePrintSDK
//
//  Created by Deon Botha on 12/02/2016.
//  Copyright © 2016 Kite.ly. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^OLQRCodeUploadedImageDownloadProgressHandler)(NSInteger receivedSize, NSInteger expectedSize);
typedef void (^OLQRCodeUploadedImageFoundHandler)(UIImage *image);

@interface OLQRCodeUploadedImagePoller : NSObject

- (void)startPollingImageURL:(NSURL *)imageURL
     onImageDownloadProgress:(OLQRCodeUploadedImageDownloadProgressHandler)progressHandler
    onImageDownloadedHandler:(OLQRCodeUploadedImageFoundHandler)downloadedHandler;
- (void)stopPolling;

@end
