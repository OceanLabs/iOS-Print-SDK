//
//  QRCodeUploadedImagePoller.m
//  KitePrintSDK
//
//  Created by Deon Botha on 12/02/2016.
//  Copyright © 2016 Kite.ly. All rights reserved.
//

#import "OLQRCodeUploadedImagePoller.h"
#import "SDWebImageManager.h"
#import "OLAsset.h"
#import "OLURLDataSource.h"

@interface OLQRCodeUploadedImagePoller ()
@property (nonatomic, strong) id<SDWebImageOperation> op;
@property (nonatomic, assign) BOOL cancelled;
@end

@implementation OLQRCodeUploadedImagePoller

- (void)startPollingImageURL:(NSURL *)imageURL
     onImageDownloadProgress:(OLQRCodeUploadedImageDownloadProgressHandler)progressHandler
    onImageDownloadedHandler:(OLQRCodeUploadedImageFoundHandler)downloadedHandler {

    SDWebImageManager *downloader = [SDWebImageManager sharedManager];
    self.op = [downloader downloadImageWithURL:imageURL
                             options:SDWebImageRetryFailed
                            progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                                if (expectedSize < 0) {
                                    return;
                                }
                                
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    if (!self.cancelled) {
                                        progressHandler(receivedSize, expectedSize);
                                    }
                                });
                            }
                           completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                               self.op = nil;
                               if (image != nil) {
                                   dispatch_async(dispatch_get_main_queue(), ^{
                                       if (!self.cancelled) {
                                           OLAsset *asset = [OLAsset assetWithDataSource:[[OLURLDataSource alloc] initWithURLString:imageURL.absoluteString]];
                                           downloadedHandler(asset);
                                       }
                                   });
                               } else if (error) {
                                   // image probably doesn't exist at the endpoint yet, try polling again
                                   dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                       [self startPollingImageURL:imageURL onImageDownloadProgress:progressHandler onImageDownloadedHandler:downloadedHandler];
                                   });
                               }
                           }];
}

- (void)stopPolling {
    [self.op cancel];
    self.cancelled = YES;
}


@end
