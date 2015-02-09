#import <UIKit/UIKit.h>

@interface UIView (RMUtils)

@property (readonly, nonatomic) CGPoint rm_topLeft;
@property (readonly, nonatomic) CGPoint rm_topRight;
@property (readonly, nonatomic) CGPoint rm_bottomLeft;
@property (readonly, nonatomic) CGPoint rm_bottomRight;
@property (readonly, nonatomic) CGPoint rm_top;
@property (readonly, nonatomic) CGPoint rm_bottom;
@property (readonly, nonatomic) CGPoint rm_right;
@property (readonly, nonatomic) CGPoint rm_left;
@property (readonly, nonatomic) CGSize rm_size;
@property (readonly, nonatomic) CGFloat rm_height;
@property (readonly, nonatomic) CGFloat rm_width;

@end

