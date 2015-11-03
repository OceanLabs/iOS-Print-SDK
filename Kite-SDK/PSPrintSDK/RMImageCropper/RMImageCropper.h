#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, RMImageCropperMode) {
    RMImageCropperModeAspectFill,
    RMImageCropperModeAspectFit
};

@interface RMImageCropper : UIView <UIGestureRecognizerDelegate>

@property (nonatomic, assign) NSInteger minimum;
@property (nonatomic, strong) UIImage * image;
@property (nonatomic, readonly) UIImage * editedImage;
@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, assign) RMImageCropperMode initialScale;
@property (nonatomic, assign) RMImageCropperMode minimumScale;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, copy) void (^tapped)();

- (void)editedImageAsync:(void (^)(UIImage *image))complete;
- (CGRect)getFrameRect;
- (CGRect)getImageRect;
- (CGSize)croppedImageSize;
+ (UIImage *)editedImageFromImage:(UIImage *)image andFrame:(CGRect)frameRect andImageRect:(CGRect)imageRect andImageViewWidth:(CGFloat)width andImageViewHeight:(CGFloat)height;

@end

