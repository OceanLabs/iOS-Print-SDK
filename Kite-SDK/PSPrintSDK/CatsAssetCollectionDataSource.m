//
//  CTAssetCollectionDataSource.m
//  KITAssetsPickerDemo
//
//  Created by Konstadinos Karayannis on 04/11/15.
//  Copyright © 2015 Kite.ly All rights reserved.
//

#import "CatsAssetCollectionDataSource.h"
#import "AssetDataSource.h"

@interface CatsAssetCollectionDataSource ()

@property (strong, nonatomic) NSArray *array;

@end

@implementation CatsAssetCollectionDataSource

- (instancetype)init{
    if (self = [super init]){
        AssetDataSource *asset1 = [[AssetDataSource alloc] init];
        asset1.url = @"https://s3.amazonaws.com/psps/sdk_static/1.jpg";
        AssetDataSource *asset2 = [[AssetDataSource alloc] init];
        asset2.url = @"https://s3.amazonaws.com/psps/sdk_static/2.jpg";
        AssetDataSource *asset3 = [[AssetDataSource alloc] init];
        asset3.url = @"https://s3.amazonaws.com/psps/sdk_static/3.jpg";
        AssetDataSource *asset4 = [[AssetDataSource alloc] init];
        asset4.url = @"https://s3.amazonaws.com/psps/sdk_static/4.jpg";
        _array = @[asset1, asset2, asset3, asset4];
    }
    
    return self;
}

- (NSString *)title{
    return @"Awesome Cats";
}

- (id)copyWithZone:(NSZone *)zone{
    CatsAssetCollectionDataSource *copy = [[CatsAssetCollectionDataSource alloc] init];
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
