//
//  OLQRCodeUploadViewController.m
//  KitePrintSDK
//
//  Created by Deon Botha on 11/02/2016.
//  Copyright © 2016 Kite.ly. All rights reserved.
//

#import "OLQRCodeUploadViewController.h"
#import "OLQRCodeUploadedImagePoller.h"
#import <UIImage+MDQRCode.h>

@interface OLQRCodeUploadViewController ()
@property (nonatomic, retain) IBOutlet UIImageView *qrCodeImageView;
@property (nonatomic, strong) OLQRCodeUploadedImagePoller *imagePoller;
@end

@implementation OLQRCodeUploadViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    NSURL *imageURL = [NSURL URLWithString:@"https://s3-eu-west-1.amazonaws.com/co.oceanlabs.ps/kiosk/deon2.jpeg"];
    self.qrCodeImageView.image = [UIImage mdQRCodeForString:@"http://api.kite.ly/public_upload/1234567890123456" size:self.qrCodeImageView.bounds.size.width fillColor:[UIColor blackColor]];
    self.imagePoller = [[OLQRCodeUploadedImagePoller alloc] init];
    [self.imagePoller startPollingImageURL:imageURL onImageDownloadProgress:^(NSInteger receivedSize, NSInteger expectedSize) {
        NSLog(@"%d/%d", receivedSize, expectedSize);
    } onImageDownloadedHandler:^(UIImage *image) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
