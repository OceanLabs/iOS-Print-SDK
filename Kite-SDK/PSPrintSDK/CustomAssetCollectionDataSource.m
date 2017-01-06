//
//  CTAssetCollectionDataSource.m
//  KITAssetsPickerDemo
//
//  Created by Konstadinos Karayannis on 04/11/15.
//  Copyright © 2015 Kite.ly All rights reserved.
//

#import "CustomAssetCollectionDataSource.h"
#import "AssetDataSource.h"

@interface CustomAssetCollectionDataSource ()

@property (strong, nonatomic) NSArray *array;

@end

@implementation CustomAssetCollectionDataSource

- (instancetype)init{
    if (self = [super init]){
        NSArray *urls = @[@"https://s3.amazonaws.com/psps/sdk_static/1.jpg", @"https://s3.amazonaws.com/psps/sdk_static/2.jpg", @"https://s3.amazonaws.com/psps/sdk_static/3.jpg", @"https://s3.amazonaws.com/psps/sdk_static/4.jpg", @"https://s3.amazonaws.com/psps/sdk_static/5.jpg", @"https://s3.amazonaws.com/psps/sdk_static/6.jpg", @"https://s3.amazonaws.com/psps/sdk_static/7.jpg", @"https://s3.amazonaws.com/psps/sdk_static/8.jpg", @"https://s3.amazonaws.com/psps/sdk_static/9.jpg", @"https://s3.amazonaws.com/psps/sdk_static/10.jpg", @"https://s3.amazonaws.com/psps/sdk_static/11.jpg", @"https://s3.amazonaws.com/psps/sdk_static/12.jpg", @"https://s3.amazonaws.com/psps/sdk_static/13.jpg", @"https://s3.amazonaws.com/psps/sdk_static/14.jpg", @"https://s3.amazonaws.com/psps/sdk_static/15.jpg", @"https://s3.amazonaws.com/psps/sdk_static/16.jpg", @"https://s3.amazonaws.com/psps/sdk_static/17.jpg", @"https://s3.amazonaws.com/psps/sdk_static/18.jpg", @"https://s3.amazonaws.com/psps/sdk_static/19.jpg", @"https://s3.amazonaws.com/psps/sdk_static/20.jpg", @"https://s3.amazonaws.com/psps/sdk_static/21.jpg", @"https://s3.amazonaws.com/psps/sdk_static/22.jpg", @"https://s3.amazonaws.com/psps/sdk_static/23.jpg", @"https://s3.amazonaws.com/psps/sdk_static/24.jpg", @"https://s3.amazonaws.com/psps/sdk_static/25.jpg", @"https://s3.amazonaws.com/psps/sdk_static/26.jpg", @"https://s3.amazonaws.com/psps/sdk_static/27.jpg", @"https://s3.amazonaws.com/psps/sdk_static/28.jpg", @"https://s3.amazonaws.com/psps/sdk_static/29.jpg", @"https://s3.amazonaws.com/psps/sdk_static/30.jpg", @"https://s3.amazonaws.com/psps/sdk_static/31.jpg", @"https://s3.amazonaws.com/psps/sdk_static/32.jpg", @"https://s3.amazonaws.com/psps/sdk_static/33.jpg", @"https://s3.amazonaws.com/psps/sdk_static/34.jpg", @"https://s3.amazonaws.com/psps/sdk_static/35.jpg", @"https://s3.amazonaws.com/psps/sdk_static/36.jpg", @"https://s3.amazonaws.com/psps/sdk_static/37.jpg", @"https://s3.amazonaws.com/psps/sdk_static/38.jpg", @"https://s3.amazonaws.com/psps/sdk_static/39.jpg", @"https://s3.amazonaws.com/psps/sdk_static/40.jpg", @"https://s3.amazonaws.com/psps/sdk_static/41.jpg", @"https://s3.amazonaws.com/psps/sdk_static/42.jpg", @"https://s3.amazonaws.com/psps/sdk_static/43.jpg", @"https://s3.amazonaws.com/psps/sdk_static/44.jpg", @"https://s3.amazonaws.com/psps/sdk_static/45.jpg", @"https://s3.amazonaws.com/psps/sdk_static/46.jpg", @"https://s3.amazonaws.com/psps/sdk_static/47.jpg", @"https://s3.amazonaws.com/psps/sdk_static/48.jpg", @"https://s3.amazonaws.com/psps/sdk_static/49.jpg", @"https://s3.amazonaws.com/psps/sdk_static/50.jpg"];
        NSMutableArray *assets = [[NSMutableArray alloc] init];
        for (NSString *s in urls){
            AssetDataSource *asset = [AssetDataSource assetWithURL:[NSURL URLWithString:s]];
            [assets addObject:asset];
        }
        _array = assets;
    }
    
    return self;
}

- (NSString *)title{
    return @"Awesome Dogs";
}

- (id)copyWithZone:(NSZone *)zone{
    CustomAssetCollectionDataSource *copy = [[CustomAssetCollectionDataSource alloc] init];
    copy.array = [[NSArray alloc] initWithArray:self.array copyItems:NO];
    return copy;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(__unsafe_unretained id  _Nonnull *)buffer count:(NSUInteger)len{
    return [self.array countByEnumeratingWithState:state objects:buffer count:len];
}

- (NSUInteger)count{
    return self.array.count;
}

- (id)objectAtIndex:(NSUInteger)index{
    return [self.array objectAtIndex:index];
}

- (NSUInteger)indexOfObject:(id)obj{
    return [self.array indexOfObject:obj];
}



@end
