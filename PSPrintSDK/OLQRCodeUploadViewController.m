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

#import "OLQRCodeUploadViewController.h"
#import "OLRemoteDataPoller.h"
#import "OLURLShortener.h"
#import "OLKiteUtils.h"

@interface OLQRCodeUploadViewController ()
@property (nonatomic, retain) IBOutlet UIImageView *qrCodeImageView;
@property (nonatomic, retain) IBOutlet UILabel *titleLabel;
@property (nonatomic, retain) IBOutlet UILabel *instructionsLabel;
@property (nonatomic, retain) IBOutlet UILabel *alternateInstructionsLabel;
@property (nonatomic, retain) IBOutlet UILabel *urlLabel;
@property (nonatomic, retain) IBOutlet UIProgressView *downloadProgressView;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (nonatomic, strong) OLRemoteDataPoller *imagePoller;
@property (nonatomic, strong) OLURLShortener *urlShortner;
@end

@implementation OLQRCodeUploadViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.titleLabel.text = NSLocalizedStringFromTableInBundle(@"Scan QR Code", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"");
    self.instructionsLabel.text = NSLocalizedStringFromTableInBundle(@"Please scan the QR code using a QR reader app on your device.", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"");
    self.alternateInstructionsLabel.text = NSLocalizedStringFromTableInBundle(@"Alternatively type the following URL into your mobile browser's address bar", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"");
    
    NSString *uuid = [[NSUUID UUID] UUIDString];;
    NSString *uploadURL = [NSString stringWithFormat:@"https://api.kite.ly/public_upload/%@", uuid];
    NSString *downloadURL = [NSString stringWithFormat:@"https://s3-eu-west-1.amazonaws.com/co.oceanlabs.ps/kiosk/%@.jpeg", uuid];
    
    self.urlShortner = [[OLURLShortener alloc] init];
    [self.urlShortner shortenURL:uploadURL handler:^(NSString *shortenedURL, NSError *error) {
        if (error) {
            [self dismissViewControllerAnimated:YES completion:^{
                UIAlertController *ac = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTableInBundle(@"Oops!", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
                [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"OK", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Acknowledgent to an alert dialog.") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){}]];
                [self presentViewController:ac animated:YES completion:NULL];
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
            
            self.qrCodeImageView.image = [self generateQRCodeImage:uploadURL];
            self.imagePoller = [[OLRemoteDataPoller alloc] init];
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
                [self.delegate assetsPickerController:self didFinishPickingAssets:@[asset]];
            }];
        }
    }];
}

- (UIImage *)generateQRCodeImage:(NSString *)input{
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    [filter setValue:[input dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:NO] forKey:@"inputMessage"];
    
    CGAffineTransform transform = CGAffineTransformMakeScale(12, 12);
    UIImage *image = [UIImage imageWithCIImage:[filter.outputImage imageByApplyingTransform: transform]];
    return image;
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    [self.imagePoller stopPolling];
}

- (void)onBarButtonItemCancelTapped:(id)sender{
    [self.imagePoller stopPolling];
    [self dismissViewControllerAnimated:YES completion:NULL];
}


@end
