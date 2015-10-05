//
//  UITableViewController+ScreenWidthFactor.m
//  HuggleUp
//
//  Created by Konstadinos Karayannis on 30/9/14.
//  Copyright (c) 2014 Ocean Labs. All rights reserved.
//

#import "UITableViewController+ScreenWidthFactor.h"

@implementation UITableViewController (ScreenWidthFactor)

-(CGFloat) screenWidthFactor{
    return [UIScreen mainScreen].bounds.size.width / 320.0;
}

@end
