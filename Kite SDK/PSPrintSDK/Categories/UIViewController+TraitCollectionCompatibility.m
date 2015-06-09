//
//  UIViewController+TraitCollectionCompatibility.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 4/16/15.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import "UIViewController+TraitCollectionCompatibility.h"

@implementation UIViewController (TraitCollectionCompatibility)

- (BOOL)isHorizontalSizeClassCompact{
    if ([self respondsToSelector:@selector(traitCollection)]){
        return self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact;
    }
    else{
        return [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone;
    }
}

@end
