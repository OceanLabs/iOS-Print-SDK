//
//  CTAssetCollectionDataSource.m
//  KITAssetsPickerDemo
//
//  Created by Konstadinos Karayannis on 04/11/15.
//  Copyright © 2015 Kite.ly All rights reserved.
//

#import "DogsAssetCollectionDataSource.h"
#import "AssetDataSource.h"

@interface DogsAssetCollectionDataSource ()

@property (strong, nonatomic) NSArray *array;

@end

@implementation DogsAssetCollectionDataSource

- (instancetype)init{
    if (self = [super init]){
        AssetDataSource *asset1 = [[AssetDataSource alloc] init];
        asset1.url = @"https://s3.amazonaws.com/psps/sdk_static/5.jpg";
        AssetDataSource *asset2 = [[AssetDataSource alloc] init];
        asset2.url = @"https://s3.amazonaws.com/psps/sdk_static/6.jpg";
        _array = @[asset1, asset2];
    }
    
    return self;
}

- (NSString *)title{
    return @"Awesome Dogs";
}

- (id)copyWithZone:(NSZone *)zone{
    DogsAssetCollectionDataSource *copy = [[DogsAssetCollectionDataSource alloc] init];
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
