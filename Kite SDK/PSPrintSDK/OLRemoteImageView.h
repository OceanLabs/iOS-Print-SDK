//
//  OLRemoteImageView.h
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 9/4/15.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OLPrintPhoto.h"

@interface OLRemoteImageView : UIImageView <OLPrintPhotoDownloadDelegate>

@property (strong, nonatomic) void (^downloadProgress)(BOOL degraded, double progress, NSError *error, BOOL *stop);

@end
