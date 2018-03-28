//
//  UIColor+HexString.h
//
//  Created by Micah Hainline
//  http://stackoverflow.com/users/590840/micah-hainline
//

#import <UIKit/UIKit.h>

@interface UIColor (OLHexString)

+ (CGFloat) colorComponentFrom: (NSString *) string start: (NSUInteger) start length: (NSUInteger) length;
+ (UIColor *) colorWithHexString: (NSString *) hexString;
+ (UIColor *) textColorForBackGroundColor:(UIColor *)color;
- (NSString *)hexString;

@end
