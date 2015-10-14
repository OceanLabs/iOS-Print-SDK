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
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8){
        return [UIImage imageNamed:name];
    }
    else{
        return [UIImage imageNamed:name inBundle:[OLKiteUtils kiteBundle] compatibleWithTraitCollection:nil];
    }
}

@end
