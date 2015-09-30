//
//  UIImage+ImageNamedInKiteBundle.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 9/30/15.
//  Copyright © 2015 Deon Botha. All rights reserved.
//

#import "UIImage+ImageNamedInKiteBundle.h"
#import "OLKiteUtils.h"

@implementation UIImage (ImageNamedInKiteBundle)

+ (UIImage*)imageNamedInKiteBundle:(NSString*)name{
    UIImage *image;
    
    image = [UIImage imageNamed:[NSString stringWithFormat:@"Kite_Print_SDK.bundle/%@",name]];
    if (image) {
        return image;
    }
    
    image = [UIImage imageWithContentsOfFile:[[[OLKiteUtils KiteBundle] resourcePath] stringByAppendingPathComponent:name]];
    
    if (image){
        return image;
    }
    
    image = [UIImage imageNamed:name];
    
    return image;
}

@end
