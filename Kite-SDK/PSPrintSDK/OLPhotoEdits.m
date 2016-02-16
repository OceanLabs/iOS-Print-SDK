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

#import "OLPhotoEdits.h"

static NSString *const kKeyCropFrameRect = @"co.oceanlabs.psprintstudio.kKeyCropFrameRect";
static NSString *const kKeyCropImageRect = @"co.oceanlabs.psprintstudio.kKeyCropImageRect";
static NSString *const kKeyCropImageSize = @"co.oceanlabs.psprintstudio.kKeyCropImageSize";
static NSString *const kKeyCropTransform = @"co.oceanlabs.psprintstudio.kKeyCropTransform";
static NSString *const kKeyCCRotations = @"co.oceanlabs.psprintstudio.kKeyCCRotations";
static NSString *const kKeyFlipHorizontal = @"co.oceanlabs.psprintstudio.kKeyFlipHorizontal";
static NSString *const kKeyFlipVertical = @"co.oceanlabs.psprintstudio.kKeyFlipVertical";

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
        _flipVertical = [aDecoder decodeBoolForKey:kKeyFlipVertical];
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
    [aCoder encodeBool:self.flipVertical forKey:kKeyFlipVertical];
}

- (void)performHorizontalFlipEditFromOrientation:(UIImageOrientation)orientation{
    switch (orientation) {
        case UIImageOrientationUp:
            self.flipHorizontal = !self.flipHorizontal;
            break;
        case UIImageOrientationLeft:
            self.flipVertical = !self.flipVertical;
            break;
        case UIImageOrientationRight:
            self.flipVertical = !self.flipVertical;
            break;
        case UIImageOrientationDown:
            self.flipHorizontal = !self.flipHorizontal;
            break;
        case UIImageOrientationUpMirrored:
            self.flipHorizontal = !self.flipHorizontal;
            break;
        case UIImageOrientationLeftMirrored:
            self.flipVertical = !self.flipVertical;
            break;
        case UIImageOrientationRightMirrored:
            self.flipVertical = !self.flipVertical;
            break;
        case UIImageOrientationDownMirrored:
            self.flipHorizontal = !self.flipHorizontal;
            break;
            
        default:
            break;
    }
}

+ (UIImageOrientation)orientationForNumberOfCounterClockwiseRotations:(NSInteger)number andInitialOrientation:(UIImageOrientation)orientation horizontalFlip:(BOOL)horizontalFlip verticalFlip:(BOOL)verticalFlip{
    UIImageOrientation newOrientation = orientation;
    
    while (number > 0) {
        switch (newOrientation) {
            case UIImageOrientationUp:
                newOrientation = UIImageOrientationLeft;
                break;
            case UIImageOrientationLeft:
                newOrientation = UIImageOrientationDown;
                break;
            case UIImageOrientationRight:
                newOrientation = UIImageOrientationUp;
                break;
            case UIImageOrientationDown:
                newOrientation = UIImageOrientationRight;
                break;
            case UIImageOrientationUpMirrored:
                newOrientation = UIImageOrientationLeftMirrored;
                break;
            case UIImageOrientationLeftMirrored:
                newOrientation = UIImageOrientationDownMirrored;
                break;
            case UIImageOrientationRightMirrored:
                newOrientation = UIImageOrientationUpMirrored;
                break;
            case UIImageOrientationDownMirrored:
                newOrientation = UIImageOrientationRightMirrored;
                break;
                
            default:
                break;
        }
        number--;
    }
    
    if (horizontalFlip){
        switch (newOrientation) {
            case UIImageOrientationUp:
                newOrientation = UIImageOrientationUpMirrored;
                break;
            case UIImageOrientationLeft:
                newOrientation = UIImageOrientationLeftMirrored;
                break;
            case UIImageOrientationRight:
                newOrientation = UIImageOrientationRightMirrored;
                break;
            case UIImageOrientationDown:
                newOrientation = UIImageOrientationDownMirrored;
                break;
            case UIImageOrientationUpMirrored:
                newOrientation = UIImageOrientationUp;
                break;
            case UIImageOrientationLeftMirrored:
                newOrientation = UIImageOrientationRight;
                break;
            case UIImageOrientationRightMirrored:
                newOrientation = UIImageOrientationLeft;
                break;
            case UIImageOrientationDownMirrored:
                newOrientation = UIImageOrientationDown;
                break;
                
            default:
                break;
        }
    }
    
    if (verticalFlip){
        switch (newOrientation) {
            case UIImageOrientationUp:
                newOrientation = UIImageOrientationDownMirrored;
                break;
            case UIImageOrientationLeft:
                newOrientation = UIImageOrientationRightMirrored;
                break;
            case UIImageOrientationRight:
                newOrientation = UIImageOrientationLeftMirrored;
                break;
            case UIImageOrientationDown:
                newOrientation = UIImageOrientationUpMirrored;
                break;
            case UIImageOrientationUpMirrored:
                newOrientation = UIImageOrientationDown;
                break;
            case UIImageOrientationLeftMirrored:
                newOrientation = UIImageOrientationRight;
                break;
            case UIImageOrientationRightMirrored:
                newOrientation = UIImageOrientationLeft;
                break;
            case UIImageOrientationDownMirrored:
                newOrientation = UIImageOrientationUp;
                break;
                
            default:
                break;
        }
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
    copy.flipVertical = self.flipVertical;

    return copy;
}

- (BOOL)isEqual:(id)object{
    BOOL retVal = [object class] == [self class];
    if (retVal) {
        OLPhotoEdits *other = object;
        retVal &= CGRectEqualToRect(self.cropImageRect, other.cropImageRect);
        retVal &= CGRectEqualToRect(self.cropImageFrame, other.cropImageFrame);
        retVal &= CGSizeEqualToSize(self.cropImageSize, other.cropImageSize);
        retVal &= CGAffineTransformEqualToTransform(self.cropTransform, other.cropTransform);
        retVal &= self.counterClockwiseRotations == other.counterClockwiseRotations;
        retVal &= self.flipHorizontal == self.flipHorizontal;
        retVal &= self.flipVertical == self.flipVertical;
    }
    
    return retVal;
}

@end
