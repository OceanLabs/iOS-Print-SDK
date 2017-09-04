//
//  UIColor+HexString.m
//
//  Created by Micah Hainline
//  http://stackoverflow.com/users/590840/micah-hainline
//

#import "UIColor+OLHexString.h"


@implementation UIColor (OLHexString)

+ (CGFloat) colorComponentFrom: (NSString *) string start: (NSUInteger) start length: (NSUInteger) length {
    NSString *substring = [string substringWithRange: NSMakeRange(start, length)];
    NSString *fullHex = length == 2 ? substring : [NSString stringWithFormat: @"%@%@", substring, substring];
    unsigned hexComponent;
    [[NSScanner scannerWithString: fullHex] scanHexInt: &hexComponent];
    return hexComponent / 255.0;
}

+ (UIColor *) colorWithHexString: (NSString *) hexString {
    NSString *colorString = [[hexString stringByReplacingOccurrencesOfString: @"#" withString: @""] uppercaseString];
    CGFloat alpha, red, blue, green;
    switch ([colorString length]) {
        case 3: // #RGB
            alpha = 1.0f;
            red   = [self colorComponentFrom: colorString start: 0 length: 1];
            green = [self colorComponentFrom: colorString start: 1 length: 1];
            blue  = [self colorComponentFrom: colorString start: 2 length: 1];
            break;
        case 4: // #ARGB
            alpha = [self colorComponentFrom: colorString start: 0 length: 1];
            red   = [self colorComponentFrom: colorString start: 1 length: 1];
            green = [self colorComponentFrom: colorString start: 2 length: 1];
            blue  = [self colorComponentFrom: colorString start: 3 length: 1];          
            break;
        case 6: // #RRGGBB
            alpha = 1.0f;
            red   = [self colorComponentFrom: colorString start: 0 length: 2];
            green = [self colorComponentFrom: colorString start: 2 length: 2];
            blue  = [self colorComponentFrom: colorString start: 4 length: 2];                      
            break;
        case 8: // #AARRGGBB
            alpha = [self colorComponentFrom: colorString start: 0 length: 2];
            red   = [self colorComponentFrom: colorString start: 2 length: 2];
            green = [self colorComponentFrom: colorString start: 4 length: 2];
            blue  = [self colorComponentFrom: colorString start: 6 length: 2];                      
            break;
        default:
            return nil;
    }
    return [UIColor colorWithRed: red green: green blue: blue alpha: alpha];
}

//Adapted from: http://stackoverflow.com/questions/26341008/how-to-convert-uicolor-to-hex-and-display-in-nslog
//Returns in RGBA format
- (NSString *)hexString{
    const CGFloat *components = CGColorGetComponents(self.CGColor);
    
    CGFloat r = components[0];
    CGFloat g = components[1];
    CGFloat b = components[2];
    CGFloat a = components[3];
    
    return [NSString stringWithFormat:@"%02lX%02lX%02lX%02lX",
            lroundf(r * 255),
            lroundf(g * 255),
            lroundf(b * 255),
            lroundf(a * 255)];
}

+ (UIColor *) textColorForBackGroundColor:(UIColor *)color{
    NSString *colorString = color.hexString;
    CGFloat red   = [UIColor colorComponentFrom: colorString start: 0 length: 1];
    red = red <= 0.03928 ? red/12.92 : pow(((red+0.055)/1.055), 2.4);
    
    CGFloat green = [UIColor colorComponentFrom: colorString start: 1 length: 1];
    green = green <= 0.03928 ? green/12.92 : pow(((green+0.055)/1.055), 2.4);
    
    CGFloat blue  = [UIColor colorComponentFrom: colorString start: 2 length: 1];
    blue = blue <= 0.03928 ? blue/12.92 : pow(((blue+0.055)/1.055), 2.4);
    
    CGFloat L = 0.2126 * red + 0.7152 * green + 0.0722 * blue;
    
    //Formula taken from: https://stackoverflow.com/a/3943023/3265861
    return (L + 0.05) / (0.0 + 0.05) > (1.0 + 0.05) / (L + 0.05) ? [UIColor blackColor] : [UIColor whiteColor];
}

@end
