//
//  NSBundle+CTAssetsPickerController.m
//  CTAssetsPickerDemo
//
//  Created by Miguel Cabeça on 25/11/14.
//  Copyright (c) 2014 Clement T. All rights reserved.
//

#import "NSBundle+OLAssetsPickerController.h"
#import "OLAssetsPickerController.h"

@implementation NSBundle (OLAssetsPickerController)

+ (NSBundle *)ctassetsPickerControllerBundle
{
    return [NSBundle bundleWithPath:[NSBundle ctassetsPickerControllerBundlePath]];
}

+ (NSString *)ctassetsPickerControllerBundlePath
{
    return [[NSBundle bundleForClass:[OLAssetsPickerController class]]
            pathForResource:@"CTAssetsPickerController" ofType:@"bundle"];
}

@end
