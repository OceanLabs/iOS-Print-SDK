//
//  OLQRCodeUploadViewController.m
//  KitePrintSDK
//
//  Created by Deon Botha on 11/02/2016.
//  Copyright © 2016 Kite.ly. All rights reserved.
//

#import "OLQRCodeUploadViewController.h"
#import "OLQRCodeUploadedImagePoller.h"
#import "OLURLShortener.h"
#import <UIImage+MDQRCode.h>

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
