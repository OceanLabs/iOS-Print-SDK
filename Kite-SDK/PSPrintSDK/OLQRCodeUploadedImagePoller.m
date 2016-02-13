//
//  QRCodeUploadedImagePoller.m
//  KitePrintSDK
//
//  Created by Deon Botha on 12/02/2016.
//  Copyright © 2016 Kite.ly. All rights reserved.
//

#import "OLQRCodeUploadedImagePoller.h"
#import "SDWebImageDownloader.h"

@interface OLQRCodeUploadedImagePoller ()
@property (nonatomic, strong) id<SDWebImageOperation> op;
@end

@implementation OLQRCodeUploadedImagePoller

- (void)startPollingImageURL:(NSURL *)imageURL
     onImageDownloadProgress:(OLQRCodeUploadedImageDownloadProgressHandler)progressHandler
    onImageDownloadedHandler:(OLQRCodeUploadedImageFoundHandler)downloadedHandler {

    SDWebImageDownloader *downloader = [SDWebImageDownloader sharedDownloader];
    self.op = [downloader downloadImageWithURL:imageURL
                             options:0
                            progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                                if (expectedSize < 0) {
                                    return;
                                }
                                
                                progressHandler(receivedSize, expectedSize);
                            }
                           completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished) {
                               self.op = nil;
                               if (image != nil) {
                                   downloadedHandler(image);
                               } else if (error) {
                                   // image probably doesn't exist at the endpoint yet, try polling again
                                   [self startPollingImageURL:imageURL onImageDownloadProgress:progressHandler onImageDownloadedHandler:downloadedHandler];
                               }
                           }];
}

- (void)stopPolling {
    [self.op cancel];
}


@end
