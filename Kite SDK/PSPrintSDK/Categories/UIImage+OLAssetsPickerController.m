//
//  UIImage+CTAssetsPickerController.m
//  CTAssetsPickerDemo
//
//  Created by Miguel Cabeça on 25/11/14.
//  Copyright (c) 2014 Clement T. All rights reserved.
//

#import "UIImage+OLAssetsPickerController.h"
#import "NSBundle+OLAssetsPickerController.h"

@implementation UIImage (OLAssetsPickerController)

+ (UIImage *)ctassetsPickerControllerImageNamed:(NSString *)name
{
    if ([UIImage respondsToSelector:@selector(imageNamed:inBundle:compatibleWithTraitCollection:)])
    {
        return [UIImage imageNamed:name inBundle:[NSBundle mainBundle] compatibleWithTraitCollection:nil];
    }
    else
    {
        return [UIImage imageNamed:[NSString stringWithFormat:@"%@", name]];
    }
}

@end
