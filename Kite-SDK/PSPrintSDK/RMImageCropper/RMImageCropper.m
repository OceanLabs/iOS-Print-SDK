#import "RMImageCropper.h"

#import "UIView+RMUtils.h"

@interface RMImageCropper ()

@property (nonatomic, strong) NSTimer *decelerationTimer;
@property (nonatomic, strong) NSTimer *elasticityTimer;
@property (nonatomic, assign) CGAffineTransform scaleTransform;
@property (nonatomic, assign) CGFloat originalWidth;
@property (nonatomic, assign, readonly) CGFloat rightGap;
@property (nonatomic, assign, readonly) CGFloat leftGap;
@property (nonatomic, assign, readonly) CGFloat bottomGap;
@property (nonatomic, assign, readonly) CGFloat topGap;

@end

CGFloat const DECELERATION_PERIOD = 0.01f;
CGFloat const DECELERATION_BASE = 0.70f;
CGFloat const REBOUNDING_PERIOD = 0.025f;
CGFloat const SCALE_INCREASE_STEP = 1.04f;
CGFloat const SCALE_DECREASE_STEP = 0.96f;
CGFloat const RESET_DURATION = 0.10f;

@implementation RMImageCropper

#pragma mark - Initialization

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        [self initialize];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self)
    {
        [self initialize];
    }
    
    return self;
}

- (void)initialize
{
    _enabled = true;
    _initialScale = RMImageCropperModeAspectFill;
    _minimumScale = RMImageCropperModeAspectFill;
    _imageView = [[UIImageView alloc] init];
    _imageView.userInteractionEnabled = true;
    _scaleTransform = CGAffineTransformIdentity;
    _originalWidth = 0.0f;
    
    self.clipsToBounds = true;
    
    [self addSubview:self.imageView];
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panRecognized:)];
    pan.delegate = self;
    [self addGestureRecognizer:pan];
    
    UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchRecognized:)];
    pinch.delegate = self;
    [self addGestureRecognizer:pinch];
    
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapRecognized:)];
    doubleTap.delegate = self;
    doubleTap.numberOfTapsRequired = 2;
    [self addGestureRecognizer:doubleTap];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapRecognized:)];
    tap.delegate = self;
    [tap requireGestureRecognizerToFail:doubleTap];
    [self addGestureRecognizer:tap];
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    
    [self setImageViewToFitFrame];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (self.bounds.size.width != self.originalWidth)
    {
        self.originalWidth = self.bounds.size.width;
        
        [self setImageViewToFitFrame];
    }
}

#pragma mark - Image

- (void)setImageViewToFitFrame
{
    CGSize minimumSize = self.initialScale == RMImageCropperModeAspectFill ? [self getMinimumFillImageViewSize] : [self getMinimumImageViewSize];
    
    self.scaleTransform = CGAffineTransformIdentity;
    self.imageView.transform = CGAffineTransformIdentity;
    self.imageView.frame = CGRectMake(0.0f, 0.0f, minimumSize.width, minimumSize.height);
    self.imageView.center = CGPointMake(self.frame.size.width / 2.0f, self.frame.size.height / 2.0f);
}

- (BOOL)isPortrait
{
    return [self getFrameAspectRatio] > [self getImageAspectRatio];
}

- (BOOL)isLandscape
{
    return [self getFrameAspectRatio] < [self getImageAspectRatio];
}

- (CGSize)getMinimumImageViewSize
{
    return [self getMinimumImageViewSizeForMode:self.minimumScale];
}

- (CGSize)getMinimumImageViewSizeForMode:(RMImageCropperMode)mode
{
    CGFloat width = self.rm_width;
    CGFloat height = self.rm_height;
    
    if ([self isPortrait] && mode == RMImageCropperModeAspectFill)
    {
        // We have to make the image view taller so that there are no gaps on the right and left
        height = MAX(height, width / [self getImageAspectRatio]);
    }
    else if ([self isPortrait] && mode == RMImageCropperModeAspectFit)
    {
        // We have to make the image view wide enough so that there are no gaps on the top and bottom
        width = height * [self getImageAspectRatio];
    }
    else if ([self isLandscape] && mode == RMImageCropperModeAspectFill)
    {
        // We have to make the image view wider so that there are no gaps on top and bottom
        width = MAX(width, height * [self getImageAspectRatio]);
    }
    else if ([self isLandscape] && mode == RMImageCropperModeAspectFit)
    {
        // We have to make the image view tall enough so that there are no gaps on the left and right
        height = width / [self getImageAspectRatio];
    }
    
    return CGSizeMake(width, height);
}

- (CGSize)getMinimumFillImageViewSize
{
    return [self getMinimumImageViewSizeForMode:RMImageCropperModeAspectFill];
}

- (CGSize)getMaximumImageViewSize
{
    CGFloat targetMinimumDimension = self.minimum / _image.scale;
    
    CGFloat maxImageViewWidth = self.rm_width / targetMinimumDimension * _image.size.width;
    CGFloat maxImageViewHeight = self.rm_height / targetMinimumDimension * _image.size.height;
    
    if ([self isPortrait])
    {
        // The width of the image will be the limiting factor
        maxImageViewHeight = maxImageViewWidth / [self getImageAspectRatio];
    }
    else if ([self isLandscape])
    {
        // The height of the image will be the limiting factor
        maxImageViewWidth = maxImageViewHeight * [self getImageAspectRatio];
    }
    
    CGSize minimumSize = [self getMinimumImageViewSize];
    
    if (minimumSize.height > maxImageViewHeight)
    {
        maxImageViewHeight = minimumSize.height;
    }
    
    if (minimumSize.width > maxImageViewWidth)
    {
        maxImageViewWidth = minimumSize.width;
    }
    
    return CGSizeMake(maxImageViewWidth, maxImageViewHeight);
}

- (CGFloat)getImageAspectRatio
{
    return _image.size.width / _image.size.height;
}

- (CGRect)getImageRect
{
    return CGRectMake(self.imageView.rm_topLeft.x, self.imageView.rm_topLeft.y, self.imageView.rm_width, self.imageView.rm_height);
}

- (void)setImage:(UIImage *)newImage
{
    UIImage *originalImage = _image;
    
    _image = newImage;
    self.imageView.image = newImage;
    
    [self stopCorrections];
    
    if (originalImage.size.height != newImage.size.height || originalImage.size.width != newImage.size.width)
    {
        [self setImageViewToFitFrame];
    }
}

- (void)setInitialScale:(RMImageCropperMode)initialScale
{
    _initialScale = initialScale;
    
    [self stopCorrections];
    
    [self setImageViewToFitFrame];
}

- (void)setMinimumScale:(RMImageCropperMode)minimumScale
{
    _minimumScale = minimumScale;
    
    [self stopCorrections];
    
    [self setImageViewToFitFrame];
}

- (UIImage *)editedImage
{
    
    CGRect frameRect = [self getFrameRect];
    CGRect imageRect = [self getImageRect];
    
    return [RMImageCropper editedImageFromImage:self.image andFrame:frameRect andImageRect:imageRect andImageViewWidth:self.imageView.rm_width andImageViewHeight:self.imageView.rm_height];
}

- (CGSize)croppedImageSize{
    return CGSizeMake(self.imageView.rm_width, self.imageView.rm_height);
}

- (void)editedImageAsync:(void (^)(UIImage *image))complete
{
    CGRect frameRect = [self getFrameRect];
    CGRect imageRect = [self getImageRect];
    UIImage *image = self.image;
    CGFloat width = self.imageView.rm_width;
    CGFloat height = self.imageView.rm_height;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        UIImage *editedImage = [RMImageCropper editedImageFromImage:image andFrame:frameRect andImageRect:imageRect andImageViewWidth:width andImageViewHeight:height];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            complete(editedImage);
        });
    });
}

+ (UIImage *)editedImageFromImage:(UIImage *)image andFrame:(CGRect)frameRect andImageRect:(CGRect)imageRect andImageViewWidth:(CGFloat)width andImageViewHeight:(CGFloat)height
{
    CGFloat x = frameRect.origin.x - imageRect.origin.x;
    CGFloat y = frameRect.origin.y - imageRect.origin.y;
    
    CGRect croppingRect = CGRectMake(x, y, frameRect.size.width, frameRect.size.height);
    CGRect imageCroppingRect;
    
    imageCroppingRect.origin.x = croppingRect.origin.x / width * image.size.width * image.scale;
    imageCroppingRect.origin.y = croppingRect.origin.y / height * image.size.height * image.scale;
    imageCroppingRect.size.width = croppingRect.size.width / width * image.size.width * image.scale;
    imageCroppingRect.size.height = croppingRect.size.height / height * image.size.height * image.scale;
    
    image = [RMImageCropper imageByRotatingImage:image fromImageOrientation:image.imageOrientation];
    
    CGImageRef imageReference = CGImageCreateWithImageInRect([image CGImage], imageCroppingRect);
    UIImage *croppedImage = [UIImage imageWithCGImage:imageReference scale:image.scale orientation:image.imageOrientation];
    CGImageRelease(imageReference);
    
    return croppedImage;
}

+(UIImage*)imageByRotatingImage:(UIImage*)initImage fromImageOrientation:(UIImageOrientation)orientation
{
    CGImageRef imgRef = initImage.CGImage;
    
    CGFloat width = CGImageGetWidth(imgRef);
    CGFloat height = CGImageGetHeight(imgRef);
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    CGRect bounds = CGRectMake(0, 0, width, height);
    CGSize imageSize = CGSizeMake(CGImageGetWidth(imgRef), CGImageGetHeight(imgRef));
    CGFloat boundHeight;
    UIImageOrientation orient = orientation;
    switch(orient) {
            
        case UIImageOrientationUp: //EXIF = 1
            return initImage;
            break;
            
        case UIImageOrientationDownMirrored: //EXIF = 2
            transform = CGAffineTransformMakeTranslation(imageSize.width, 0.0);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            break;
            
        case UIImageOrientationDown: //EXIF = 3
            transform = CGAffineTransformMakeTranslation(0, 0);
            transform = CGAffineTransformRotate(transform, 0);
            break;
            
        case UIImageOrientationUpMirrored: //EXIF = 4
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.height);
            transform = CGAffineTransformScale(transform, 1.0, -1.0);
            break;
            
        case UIImageOrientationRightMirrored: //EXIF = 5
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.width);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
            
        case UIImageOrientationLeft: //EXIF = 6
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.width);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
            
        case UIImageOrientationLeftMirrored: //EXIF = 7
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeScale(-1.0, 1.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
            
        case UIImageOrientationRight: //EXIF = 8
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, 0.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
            
        default:
            [NSException raise:NSInternalInconsistencyException format:@"Invalid image orientation"];
            
    }
    // Create the bitmap context
    CGContextRef    context = NULL;
    void *          bitmapData;
    int             bitmapByteCount;
    int             bitmapBytesPerRow;
    
    // Declare the number of bytes per row. Each pixel in the bitmap in this
    // example is represented by 4 bytes; 8 bits each of red, green, blue, and
    // alpha.
    bitmapBytesPerRow   = (bounds.size.width * 4);
    bitmapByteCount     = (bitmapBytesPerRow * bounds.size.height);
    bitmapData = malloc( bitmapByteCount );
    if (bitmapData == NULL)
    {
        return nil;
    }
    
    // Create the bitmap context. We want pre-multiplied ARGB, 8-bits
    // per component. Regardless of what the source image format is
    // (CMYK, Grayscale, and so on) it will be converted over to the format
    // specified here by CGBitmapContextCreate.
    CGColorSpaceRef colorspace = CGImageGetColorSpace(imgRef);
    context = CGBitmapContextCreate (bitmapData,bounds.size.width,bounds.size.height,8,bitmapBytesPerRow,
                                     colorspace, kCGBitmapAlphaInfoMask & kCGImageAlphaPremultipliedLast);
    
    if (context == NULL)
        // error creating context
        return nil;
    
    CGContextScaleCTM(context, -1.0, -1.0);
    CGContextTranslateCTM(context, -bounds.size.width, -bounds.size.height);
    
    CGContextConcatCTM(context, transform);
    
    // Draw the image to the bitmap context. Once we draw, the memory
    // allocated for the context for rendering will then contain the
    // raw image data in the specified color space.
    CGContextDrawImage(context, CGRectMake(0,0,width, height), imgRef);
    
    CGImageRef imgRef2 = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    free(bitmapData);
    UIImage * image = [UIImage imageWithCGImage:imgRef2 scale:initImage.scale orientation:UIImageOrientationUp];
    CGImageRelease(imgRef2);
    return image;
}

- (void)setMinimum:(NSInteger)minimum
{
    _minimum = minimum;
    
    [self correctSizeAndTranslationErrors];
}

- (void)resetToScale:(RMImageCropperMode)scale WithDuration:(NSTimeInterval)duration andCompletion:(void (^) (void))completion;
{
    self.enabled = false;
    
    CGSize minimumSize = scale == RMImageCropperModeAspectFill ? [self getMinimumFillImageViewSize] : [self getMinimumImageViewSize];
    
    [UIView animateWithDuration:duration animations:^{
        
        self.imageView.transform = CGAffineTransformIdentity;
        self.imageView.bounds = CGRectMake(0.0f, 0.0f, minimumSize.width, minimumSize.height);
        
    } completion:^(BOOL finished) {
        
        self.enabled = true;
        self.scaleTransform = CGAffineTransformIdentity;
        
        if (completion)
            completion();
    }];
}

#pragma mark - Frame

- (CGFloat)getFrameAspectRatio
{
    return self.frame.size.width / self.frame.size.height;
}

- (CGRect)getFrameRect
{
    return CGRectMake(0.0f, 0.0f, self.rm_width, self.rm_height);
}

- (CGFloat)leftGap
{
    return self.imageView.rm_left.x > 0.0f ? self.imageView.rm_left.x : 0.0f;
}

- (CGFloat)rightGap
{
    return self.rm_width - self.imageView.rm_right.x > 0.0f ? self.rm_width - self.imageView.rm_right.x : 0.0f;
}

- (CGFloat)bottomGap
{
    return self.rm_height - self.imageView.rm_bottom.y > 0.0f ? self.rm_height - self.imageView.rm_bottom.y : 0.0f;
}

- (CGFloat)topGap
{
    return self.imageView.rm_top.y > 0.0f ? self.imageView.rm_top.y : 0.0f;
}

#pragma mark - Translation

- (CGVector)translateImage:(CGVector)translation
{
    CGFloat currentFrameError = [self getTranslationError];
    
    CGAffineTransform originalTransform = self.imageView.transform;
    
    self.imageView.transform = CGAffineTransformTranslate(self.imageView.transform, translation.dx, translation.dy);
    
    CGFloat postTransformFrameError = [self getTranslationError];
    
    if (postTransformFrameError > currentFrameError)
    {
        // We are moving in the wrong direction so reduce the translation
        self.imageView.transform = originalTransform;
        CGFloat slowingFactor = postTransformFrameError > 0.5f ? 0.0f : 1.0f - 2.0f * postTransformFrameError;
        translation.dx = translation.dx * slowingFactor;
        translation.dy = translation.dy * slowingFactor;
        self.imageView.transform = CGAffineTransformTranslate(self.imageView.transform, translation.dx, translation.dy);
    }
    
    return translation;
}

- (BOOL)isImageOutOfFrame
{
    CGRect frame = [self getFrameRect];
    CGRect image = [self getImageRect];
    
    CGRect frameImageIntersection = CGRectIntersection(frame, image);
    
    return !CGRectEqualToRect(frameImageIntersection, frame);
}

- (CGFloat)getTranslationError
{
    CGFloat leftRightDifferential = ABS(self.rightGap - self.leftGap) / self.rm_width;
    CGFloat topBottomDifferential = ABS(self.topGap - self.bottomGap) / self.rm_height;
    
    CGFloat translationError = (leftRightDifferential + topBottomDifferential) / 2.0f;
    
    return translationError;
}

- (void)correctTranslationError
{
    CGFloat frameHeight = self.rm_height;
    CGFloat frameWidth = self.rm_width;
    
    CGFloat imageHeight = self.imageView.rm_height;
    CGFloat imageWidth = self.imageView.rm_width;
    CGFloat xCorrection = 0.0f;
    CGFloat yCorrection = 0.0f;
    
    CGFloat rightGap = self.rm_width - self.imageView.rm_right.x > 0.0f ? self.rm_width - self.imageView.rm_right.x : 0.0f;
    CGFloat leftGap = self.imageView.rm_left.x > 0.0f ? self.imageView.rm_left.x : 0.0f;
    CGFloat topGap = self.imageView.rm_top.y > 0.0f ? self.imageView.rm_top.y : 0.0f;
    CGFloat bottomGap = self.rm_height - self.imageView.rm_bottom.y > 0.0f ? self.rm_height - self.imageView.rm_bottom.y : 0.0f;
    
    xCorrection = 0.0f;
    yCorrection = 0.0f;
    
    if (imageWidth >= frameWidth)
    {
        xCorrection = rightGap - leftGap;
    }
    else
    {
        xCorrection = (self.rm_width - self.imageView.rm_right.x - self.imageView.rm_left.x) / 2.0f;
    }
    
    if (imageHeight > frameHeight)
    {
        yCorrection = bottomGap - topGap;
    }
    else
    {
        yCorrection = (self.rm_height - self.imageView.rm_bottom.y - self.imageView.rm_top.y) / 2.0f;
    }
    
    CGPoint correction = CGPointMake(xCorrection, yCorrection);
    CGPoint scaledCorrection = CGPointApplyAffineTransform(correction, CGAffineTransformInvert(self.scaleTransform));
    
    [self startDecelerationWithVelocity:[self getVelocityForDisplacement:scaledCorrection]];
}

#pragma mark - Size

- (BOOL)shouldScaleImage
{
    CGSize minimumSize = [self getMinimumImageViewSize];
    CGSize maximumSize = [self getMaximumImageViewSize];
    
    return maximumSize.width > minimumSize.width && maximumSize.height > minimumSize.height;
}

- (void)scaleImage:(CGFloat)scale
{
    if ([self shouldScaleImage])
    {
        CGFloat currentSizeError = [self getSizeError];
        
        CGAffineTransform originalTransform = self.imageView.transform;
        CGAffineTransform originalScaleTransform = self.scaleTransform;
        
        self.imageView.transform = CGAffineTransformScale(self.imageView.transform, scale, scale);
        self.scaleTransform = CGAffineTransformScale(self.scaleTransform, scale, scale);
        
        CGFloat postTransformSizeError = [self getSizeError];
        
        if (ABS(postTransformSizeError) > ABS(currentSizeError))
        {
            // We have either making the image too large or too small so reduce the scaling factor towards 1
            self.imageView.transform = originalTransform;
            self.scaleTransform = originalScaleTransform;
            
            CGFloat slowingFactor = postTransformSizeError > 0.5f ? 0.0f : 1.0f - 2.0f * postTransformSizeError;
            CGFloat adjustedScale = slowingFactor * scale + (1 - slowingFactor);
            self.imageView.transform = CGAffineTransformScale(self.imageView.transform, adjustedScale, adjustedScale);
            self.scaleTransform = CGAffineTransformScale(self.scaleTransform, adjustedScale, adjustedScale);
        }
    }
}

- (BOOL)isImageSizeOutOfBounds
{
    return [self isImageSizeTooSmall] || [self isImageSizeTooLarge];
}

- (BOOL)isImageSizeTooSmall
{
    CGSize minimumSize = [self getMinimumImageViewSize];
    
    return self.imageView.rm_height < minimumSize.height && self.imageView.rm_width < minimumSize.width;
}

- (BOOL)isImageSizeTooLarge
{
    CGSize maximumSize = [self getMaximumImageViewSize];
    
    return self.imageView.rm_height > maximumSize.height && self.imageView.rm_width > maximumSize.width;
}

- (CGFloat)getSizeError
{
    CGFloat sizeError = 0.0f;
    
    if ([self isImageSizeTooSmall])
    {
        CGRect image = [self getImageRect];
        CGRect frame = [self getFrameRect];
        
        if (self.minimumScale == RMImageCropperModeAspectFit)
        {
            CGSize minimumSize = [self getMinimumImageViewSize];
            frame = CGRectMake(0.0f, 0.0f, minimumSize.width, minimumSize.height);
        }
        
        // We don't care about positional differences only relative size
        frame.origin = image.origin;
        
        CGRect intersection = CGRectIntersection(image, frame);
        
        CGFloat frameArea = frame.size.width * frame.size.height;
        CGFloat intersectionArea = intersection.size.width * intersection.size.height;
        
        sizeError = (frameArea - intersectionArea) / frameArea;
    }
    else if ([self isImageSizeTooLarge])
    {
        CGSize maximumSize = [self getMaximumImageViewSize];
        CGRect image = [self getImageRect];
        CGFloat imageArea = image.size.width * image.size.height;
        CGFloat maxImageArea = maximumSize.width * maximumSize.height;
        
        sizeError = 1.0f - maxImageArea / imageArea;
    }
    
    return sizeError;
}

- (void)correctSizeError
{
    [self startReboundingToFitImage];
}

#pragma mark - Size & Translation

- (BOOL)isCorrecting{
    return self.elasticityTimer || self.decelerationTimer;
}

- (void)correctSizeAndTranslationErrors
{
    if ([self isImageSizeOutOfBounds])
    {
        [self correctSizeError];
    }
    
    if ([self isImageOutOfFrame])
    {
        [self correctTranslationError];
    }
}

- (void)stopCorrections
{
    [self stopRebounding];
    [self stopDeceleration];
}

#pragma mark - Gesture Handlers

- (void)notifyDelegateOfTransform {
    if ([self.delegate respondsToSelector:@selector(imageCropperDidTransformImage:)]) {
        [self.delegate imageCropperDidTransformImage:self];
    }
}

- (void)pinchRecognized:(UIPinchGestureRecognizer *)recognizer
{
    if (self.enabled)
    {
        [self stopCorrections];
        
        CGFloat scale = recognizer.scale;
        [self scaleImage:scale];
        recognizer.scale = 1.0f;
        
        if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled || recognizer.state == UIGestureRecognizerStateFailed)
        {
            [self correctSizeAndTranslationErrors];
        }
        
        [self notifyDelegateOfTransform];
    }
}

- (void)panRecognized:(UIPanGestureRecognizer *)recognizer
{
    if (self.enabled)
    {
        [self stopCorrections];
        
        CGPoint translation = [recognizer translationInView:self.imageView];
        [self translateImage:CGVectorMake(translation.x, translation.y)];
        [recognizer setTranslation:CGPointMake(0.0f, 0.0f) inView:self.imageView];
        
        if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled || recognizer.state == UIGestureRecognizerStateFailed)
        {
            CGPoint velocity = [recognizer velocityInView:self.imageView];
            [self startDecelerationWithVelocity:velocity];
        }
        
        [self notifyDelegateOfTransform];
    }
}

- (void)tapRecognized:(UITapGestureRecognizer *)recognizer
{
    if (self.tapped != nil) {
        self.tapped();
        [self notifyDelegateOfTransform];
    }
}

- (void)doubleTapRecognized:(UITapGestureRecognizer *)recognizer
{
    RMImageCropperMode scale = RMImageCropperModeAspectFit;
    
    if ([self isPortrait] && (self.leftGap > 0.5f || self.rightGap > 0.5f))
    {
        scale = RMImageCropperModeAspectFill;
    }
    else if ([self isLandscape] && (self.topGap > 0.5f || self.bottomGap > 0.5f))
    {
        scale = RMImageCropperModeAspectFill;
    }
    
    [self resetToScale:scale WithDuration:RESET_DURATION andCompletion:nil];
    [self notifyDelegateOfTransform];
}

#pragma mark - Inertia

- (void)startDecelerationWithVelocity:(CGPoint)velocity
{
    [self stopDeceleration];
    
    // We don't want to start moving with an incredibly low velocity
    if (ABS(velocity.x) > 0.01f || ABS(velocity.y) > 0.01f)
    {
        NSMutableDictionary *userInfo = [NSMutableDictionary new];
        userInfo[@"velocity"] = [NSValue valueWithCGPoint:velocity];
        
        self.decelerationTimer = [NSTimer scheduledTimerWithTimeInterval:DECELERATION_PERIOD target:self selector:@selector(decelerationStep:) userInfo:userInfo repeats:true];
    }
}

- (void)stopDeceleration
{
    [self.decelerationTimer invalidate];
    self.decelerationTimer = nil;
}

- (void)decelerationStep:(NSTimer *)decelerationTimer
{
    CGPoint velocity = [decelerationTimer.userInfo[@"velocity"] CGPointValue];
    velocity.x *= DECELERATION_BASE;
    velocity.y *= DECELERATION_BASE;
    decelerationTimer.userInfo[@"velocity"] = [NSValue valueWithCGPoint:velocity];
    
    CGVector translation;
    translation.dx = velocity.x * DECELERATION_PERIOD;
    translation.dy = velocity.y * DECELERATION_PERIOD;
    
    translation = [self translateImage:translation];
    
    // Handles the inevitable floating point errors from using a decreasing exponential velocity function
    if (ABS(translation.dx) <= 0.5f && ABS(translation.dy) <= 0.5f)
    {
        [self stopDeceleration];
        
        [self correctSizeAndTranslationErrors];
    }
}

- (CGPoint)getVelocityForDisplacement:(CGPoint)displacement
{
    return CGPointMake([self getSpeedForDistance:displacement.x], [self getSpeedForDistance:displacement.y]);
}

- (CGFloat)getSpeedForDistance:(CGFloat)distance
{
    // Inverting the geometric series produced by the deceleration function
    return (distance / (DECELERATION_BASE * DECELERATION_PERIOD)) * ((1.0f - DECELERATION_BASE) / (1.0f - powf(DECELERATION_BASE, [self getNumberOfDecelerationPeriodsToRestoration])));
}

- (CGFloat)getNumberOfDecelerationPeriodsToRestoration
{
    return floorf(MAX(self.rm_width, self.rm_height) / 10.0f);
}

#pragma mark - Elasticity

- (void)startReboundingToFitImage
{
    [self stopRebounding];
    
    self.elasticityTimer = [NSTimer scheduledTimerWithTimeInterval:REBOUNDING_PERIOD target:self selector:@selector(reboundingStep:) userInfo:nil repeats:true];
}

- (void)stopRebounding
{
    [self.elasticityTimer invalidate];
    self.elasticityTimer = nil;
}

- (CGFloat)getReboundingStep
{
    CGFloat sizeError = [self getSizeError];
    CGFloat stepPercentage = ABS(sizeError) > 0.5f ? 1.0 : ABS(sizeError) / 0.5f;
    
    if ([self isImageSizeTooLarge])
    {
        return stepPercentage * SCALE_DECREASE_STEP + (1 - stepPercentage);
    }
    else if ([self isImageSizeTooSmall])
    {
        return stepPercentage * SCALE_INCREASE_STEP + (1 - stepPercentage);
    }
    else
    {
        return 1.0;
    }
}

- (void)reboundingStep:(NSTimer *)elasticityTimer
{
    if (![self isImageSizeOutOfBounds] || [self getSizeError] <= 0.001f || ![self shouldScaleImage])
    {
        [self stopRebounding];
    }
    else if ([self isImageSizeTooLarge])
    {
        [self scaleImage:[self getReboundingStep]];
    }
    else if ([self isImageSizeTooSmall])
    {
        [self scaleImage:[self getReboundingStep]];
    }
    
    [self correctTranslationError];
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return true;
}

@end
