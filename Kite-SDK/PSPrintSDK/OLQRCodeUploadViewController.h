//
//  OLQRCodeUploadViewController.h
//  KitePrintSDK
//
//  Created by Deon Botha on 11/02/2016.
//  Copyright © 2016 Kite.ly. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OLAsset;
@class OLQRCodeUploadViewController;

@protocol OLQRCodeUploadViewControllerDelegate <NSObject>
- (void)qrCodeUpload:(OLQRCodeUploadViewController *)vc didFinishPickingAsset:(OLAsset *)asset;
@end

@interface OLQRCodeUploadViewController : UIViewController
@property (nonatomic, weak) id<OLQRCodeUploadViewControllerDelegate> delegate;
@end
