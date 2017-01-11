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

#import "OLQRCodeUploadedImagePoller.h"
#import "OLAsset.h"
#import "OLImageDownloader.h"

@interface OLQRCodeUploadedImagePoller ()
@property (nonatomic, strong) NSURLSessionDownloadTask *op;
@property (nonatomic, assign) BOOL cancelled;
@end

@implementation OLQRCodeUploadedImagePoller

- (void)startPollingImageURL:(NSURL *)imageURL
     onImageDownloadProgress:(OLQRCodeUploadedImageDownloadProgressHandler)progressHandler
    onImageDownloadedHandler:(OLQRCodeUploadedImageFoundHandler)downloadedHandler {

    self.op = [[OLImageDownloader sharedInstance] downloadImageAtURL:imageURL progress:^(NSInteger receivedSize, NSInteger expectedSize) {
        if (expectedSize < 0) {
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!self.cancelled) {
                progressHandler(receivedSize, expectedSize);
            }
        });
    } withCompletionHandler:^(UIImage *image, NSError *error) {
        self.op = nil;
        if (image != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!self.cancelled) {
                    [self stopPolling];
                    OLAsset *asset = [OLAsset assetWithURL:imageURL];
                    downloadedHandler(asset);
                }
            });
        } else if (error) {
            // image probably doesn't exist at the endpoint yet, try polling again
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.op cancel];
                if (!self.cancelled){
                    [self startPollingImageURL:imageURL onImageDownloadProgress:progressHandler onImageDownloadedHandler:downloadedHandler];
                }
            });
        }
    }];
}

- (void)stopPolling {
    [self.op cancel];
    self.cancelled = YES;
}


@end
