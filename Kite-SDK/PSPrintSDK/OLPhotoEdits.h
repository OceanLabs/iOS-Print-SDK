//
//  OLPhotoEdits.h
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 16/11/15.
//  Copyright © 2015 Kite.ly. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OLPhotoEdits : NSObject <NSCoding, NSCopying>

@property (assign, nonatomic) CGRect cropImageRect;
@property (assign, nonatomic) CGRect cropImageFrame;
@property (assign, nonatomic) CGSize cropImageSize;
@property (assign, nonatomic) CGAffineTransform cropTransform;
@property (assign, nonatomic) NSInteger counterClockwiseRotations;
@property (assign, nonatomic) BOOL flipHorizontal;

+ (UIImageOrientation)orientationForNumberOfCounterClockwiseRotations:(NSInteger)number andInitialOrientation:(UIImageOrientation)orientation;

@end
