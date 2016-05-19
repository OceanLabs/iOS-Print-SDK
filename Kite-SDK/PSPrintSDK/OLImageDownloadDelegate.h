//
//  OLImageDownloadDelegate.h
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 19/05/16.
//  Copyright © 2016 Kite.ly. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OLImageDownloadDelegate : NSObject <NSURLSessionDownloadDelegate>

@property (copy, nonatomic) void (^progressHandler)(NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite);
@property (copy, nonatomic) void (^completionHandler)(NSData *data, NSURLResponse *response, NSError *error);

@end
