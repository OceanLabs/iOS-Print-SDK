//
//  OLPhotoEdits.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 16/11/15.
//  Copyright © 2015 Kite.ly. All rights reserved.
//

#import "OLPhotoEdits.h"

static NSString *const kKeyCropFrameRect = @"co.oceanlabs.psprintstudio.kKeyCropFrameRect";
static NSString *const kKeyCropImageRect = @"co.oceanlabs.psprintstudio.kKeyCropImageRect";
static NSString *const kKeyCropImageSize = @"co.oceanlabs.psprintstudio.kKeyCropImageSize";
static NSString *const kKeyCropTransform = @"co.oceanlabs.psprintstudio.kKeyCropTransform";
static NSString *const kKeyCCRotations = @"co.oceanlabs.psprintstudio.kKeyCCRotations";
static NSString *const kKeyFlipHorizontal = @"co.oceanlabs.psprintstudio.kKeyFlipHorizontal";

@implementation OLPhotoEdits

-(CGAffineTransform) cropTransform{
    if (CGAffineTransformEqualToTransform(_cropTransform, CGAffineTransformMake(0, 0, 0, 0, 0, 0))){
        _cropTransform = CGAffineTransformIdentity;
    }
    return _cropTransform;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        _cropImageFrame = [aDecoder decodeCGRectForKey:kKeyCropFrameRect];
        _cropImageRect = [aDecoder decodeCGRectForKey:kKeyCropImageRect];
        _cropImageSize = [aDecoder decodeCGSizeForKey:kKeyCropImageSize];
        _cropTransform = [aDecoder decodeCGAffineTransformForKey:kKeyCropTransform];
        _counterClockwiseRotations = [aDecoder decodeIntegerForKey:kKeyCCRotations];
        _flipHorizontal = [aDecoder decodeBoolForKey:kKeyFlipHorizontal];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeCGRect:self.cropImageFrame forKey:kKeyCropFrameRect];
    [aCoder encodeCGRect:self.cropImageRect forKey:kKeyCropImageRect];
    [aCoder encodeCGSize:self.cropImageSize forKey:kKeyCropImageSize];
    [aCoder encodeCGAffineTransform:self.cropTransform forKey:kKeyCropTransform];
    [aCoder encodeInteger:self.counterClockwiseRotations forKey:kKeyCCRotations];
    [aCoder encodeBool:self.flipHorizontal forKey:kKeyFlipHorizontal];
}

+ (UIImageOrientation)orientationForNumberOfCounterClockwiseRotations:(NSInteger)number andInitialOrientation:(UIImageOrientation)orientation{
    UIImageOrientation newOrientation = orientation;
    
    while (number > 0) {
        if (newOrientation == UIImageOrientationUp){
            newOrientation = UIImageOrientationLeft;
        }
        else if (newOrientation == UIImageOrientationLeft){
            newOrientation = UIImageOrientationDown;
        }
        else if (newOrientation == UIImageOrientationDown){
            newOrientation = UIImageOrientationRight;
        }
        else if (newOrientation == UIImageOrientationRight){
            newOrientation = UIImageOrientationUp;
        }
        number--;
    }

    return newOrientation;
}

- (id)copyWithZone:(NSZone *)zone {
    OLPhotoEdits *copy = [[OLPhotoEdits alloc] init];
    copy.cropImageFrame = self.cropImageFrame;
    copy.cropImageRect = self.cropImageRect;
    copy.cropImageSize = self.cropImageSize;
    copy.cropTransform = self.cropTransform;
    copy.counterClockwiseRotations = self.counterClockwiseRotations;
    copy.flipHorizontal = self.flipHorizontal;

    return copy;
}

@end
