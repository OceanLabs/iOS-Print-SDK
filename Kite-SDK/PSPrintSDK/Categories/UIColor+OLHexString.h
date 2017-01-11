//
//  UIColor+HexString.h
//
//  Created by Micah Hainline
//  http://stackoverflow.com/users/590840/micah-hainline
//

#import <UIKit/UIKit.h>

@interface UIColor (OLHexString)

+ (UIColor *) colorWithHexString: (NSString *) hexString;
- (NSString *)hexString;

@end
