#import "UIView+RMUtils.h"

@implementation UIView (RMtils)

- (CGRect)rm_originalFrame
{
    CGAffineTransform transform = self.transform;
    self.transform = CGAffineTransformIdentity;
    CGRect frame = self.frame;
    self.transform = transform;
    
    return frame;
}

- (CGPoint)rm_transformPoint:(CGPoint)point
{
    CGPoint pointInCenterCoordinates = CGPointMake(point.x - self.center.x, point.y - self.center.y);
    CGPoint transformedPointInCenterCoordinates = CGPointApplyAffineTransform(pointInCenterCoordinates, self.transform);
    
    return CGPointMake(transformedPointInCenterCoordinates.x + self.center.x, transformedPointInCenterCoordinates.y + self.center.y);
}

- (CGPoint)rm_topLeft
{
    CGRect originalFrame = [self rm_originalFrame];
    return [self rm_transformPoint:originalFrame.origin];
}

- (CGPoint)rm_topRight
{
    CGRect originalFrame = [self rm_originalFrame];
    CGPoint topRight = originalFrame.origin;
    topRight.x += originalFrame.size.width;
    return [self rm_transformPoint:topRight];
}

- (CGPoint)rm_bottomLeft
{
    CGRect originalFrame = [self rm_originalFrame];
    CGPoint bottomLeft = originalFrame.origin;
    bottomLeft.y += originalFrame.size.height;
    return [self rm_transformPoint:bottomLeft];
}

- (CGPoint)rm_bottomRight
{
    CGRect originalFrame = [self rm_originalFrame];
    CGPoint bottomRight = originalFrame.origin;
    bottomRight.x += originalFrame.size.width;
    bottomRight.y += originalFrame.size.height;
    return [self rm_transformPoint:bottomRight];
}

- (CGPoint)rm_midPointBetween:(CGPoint)point1 and:(CGPoint)point2
{
    return CGPointMake(point1.x / 2.0 + point2.x / 2.0, point1.y / 2.0 + point2.y / 2.0);
}

- (CGPoint)rm_top
{
    return [self rm_midPointBetween:[self rm_topLeft] and:[self rm_topRight]];
}

- (CGPoint)rm_bottom
{
    return [self rm_midPointBetween:[self rm_bottomLeft] and:[self rm_bottomRight]];
}

- (CGPoint)rm_left
{
    return [self rm_midPointBetween:[self rm_topLeft] and:[self rm_bottomLeft]];
}

- (CGPoint)rm_right
{
    return [self rm_midPointBetween:[self rm_topRight] and:[self rm_bottomRight]];
}

- (CGSize)rm_size
{
    CGPoint topLeft = self.rm_topLeft;
    CGPoint bottomRight = self.rm_bottomRight;
    
    CGFloat width = bottomRight.x - topLeft.x;
    CGFloat height = bottomRight.y - topLeft.y;
    
    return CGSizeMake(width, height);
}

- (CGFloat)rm_height
{
    return self.rm_size.height;
}

- (CGFloat)rm_width
{
    return self.rm_size.width;
}

@end

