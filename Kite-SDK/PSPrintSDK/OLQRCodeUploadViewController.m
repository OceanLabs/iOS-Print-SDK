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

#import "OLQRCodeUploadViewController.h"
#import "OLQRCodeUploadedImagePoller.h"
#import "OLURLShortener.h"
#ifdef COCOAPODS
#import <ios-qr-encoder/UIImage+MDQRCode.h>
#else
#import "UIImage+MDQRCode.h"
#endif


@interface OLQRCodeUploadViewController ()
@property (nonatomic, retain) IBOutlet UIImageView *qrCodeImageView;
@property (nonatomic, retain) IBOutlet UILabel *titleLabel;
@property (nonatomic, retain) IBOutlet UILabel *instructionsLabel;
@property (nonatomic, retain) IBOutlet UILabel *alternateInstructionsLabel;
@property (nonatomic, retain) IBOutlet UILabel *urlLabel;
@property (nonatomic, retain) IBOutlet UIProgressView *downloadProgressView;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (nonatomic, strong) OLQRCodeUploadedImagePoller *imagePoller;
@property (nonatomic, strong) OLURLShortener *urlShortner;
@end

@implementation OLQRCodeUploadViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    
    NSString *uuid = [[NSUUID UUID] UUIDString];;
    NSString *uploadURL = [NSString stringWithFormat:@"http://api.kite.ly/public_upload/%@", uuid];
    NSString *downloadURL = [NSString stringWithFormat:@"https://s3-eu-west-1.amazonaws.com/co.oceanlabs.ps/kiosk/%@.jpeg", uuid];
    
    self.urlShortner = [[OLURLShortener alloc] init];
    [self.urlShortner shortenURL:uploadURL handler:^(NSString *shortenedURL, NSError *error) {
        if (error) {
            [self dismissViewControllerAnimated:YES completion:^{
                [[[UIAlertView alloc] initWithTitle:@"Oops" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            }];
        } else {
            self.activityIndicator.hidden = YES;
            self.titleLabel.hidden = NO;
            self.instructionsLabel.hidden = NO;
            self.qrCodeImageView.hidden = NO;
            self.alternateInstructionsLabel.hidden = NO;
            self.urlLabel.hidden = NO;
            
            if ([shortenedURL hasPrefix:@"http://"]) {
                self.urlLabel.text = [shortenedURL substringFromIndex:[@"http://" length]];
            } else {
                self.urlLabel.text = shortenedURL;
            }
            
            self.qrCodeImageView.image = [UIImage mdQRCodeForString:uploadURL size:self.qrCodeImageView.bounds.size.width fillColor:[UIColor blackColor]];
            self.imagePoller = [[OLQRCodeUploadedImagePoller alloc] init];
            [self.imagePoller startPollingImageURL:[NSURL URLWithString:downloadURL] onImageDownloadProgress:^(NSInteger receivedSize, NSInteger expectedSize) {
                if (self.downloadProgressView.hidden) {
                    self.downloadProgressView.hidden = NO;
                    self.qrCodeImageView.hidden = YES;
                    self.urlLabel.hidden = YES;
                    self.alternateInstructionsLabel.hidden = YES;
                    self.titleLabel.text = @"Downloading Photo";
                    self.instructionsLabel.text = @"Please wait while your photo is downloaded";
                }
                
                self.downloadProgressView.progress = receivedSize / (float) expectedSize;
            } onImageDownloadedHandler:^(OLAsset *asset) {
                [self.delegate qrCodeUpload:self didFinishPickingAsset:asset];
            }];
        }
    }];
}

- (void)dealloc {
    [self.imagePoller stopPolling];
}


@end
