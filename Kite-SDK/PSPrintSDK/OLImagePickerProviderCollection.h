//
//  OLImagePickerProviderCollection.h
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 22/07/16.
//  Copyright © 2016 Kite.ly. All rights reserved.
//

#import <Foundation/Foundation.h>
@import Photos;
#import "OLAsset.h"

@interface OLImagePickerProviderCollection : NSObject <NSFastEnumeration, NSCopying>

- (instancetype)initWithArray:(NSArray<OLAsset *> *)array name:(NSString *)name;
- (instancetype)initWithPHFetchResult:(PHFetchResult *)fetchResult name:(NSString *)name;

- (NSUInteger)indexOfObject:(id)obj;
- (id)objectAtIndex:(NSUInteger)index;
- (NSUInteger)count;

@property (strong, nonatomic, readonly) NSString *name;

@end
