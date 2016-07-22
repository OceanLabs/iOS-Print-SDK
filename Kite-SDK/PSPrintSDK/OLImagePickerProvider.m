//
//  OLImagePickerProvider.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 22/07/16.
//  Copyright © 2016 Kite.ly. All rights reserved.
//

#import "OLImagePickerProvider.h"

@implementation OLImagePickerProvider

- (instancetype)initWithCollections:(NSArray<OLImagePickerProviderCollection *> *)collections name:(NSString *)name icon:(UIImage *)icon{
    if (self = [super init]){
        self.collections = collections;
        self.icon = icon;
        self.name = name;
    }
    return self;
}

@end
