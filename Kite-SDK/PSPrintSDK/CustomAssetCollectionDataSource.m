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
        AssetDataSource *asset1 = [[AssetDataSource alloc] init];
        asset1.imageURL = [NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/1.jpg"];
        AssetDataSource *asset2 = [[AssetDataSource alloc] init];
        asset2.imageURL = [NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/2.jpg"];
        AssetDataSource *asset3 = [[AssetDataSource alloc] init];
        asset3.imageURL = [NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/3.jpg"];
        AssetDataSource *asset4 = [[AssetDataSource alloc] init];
        asset4.imageURL = [NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/4.jpg"];
        AssetDataSource *asset5 = [[AssetDataSource alloc] init];
        asset5.imageURL = [NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/5.jpg"];
        AssetDataSource *asset6 = [[AssetDataSource alloc] init];
        asset6.imageURL = [NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/6.jpg"];
        AssetDataSource *asset7 = [[AssetDataSource alloc] init];
        asset7.imageURL = [NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/7.jpg"];
        AssetDataSource *asset8 = [[AssetDataSource alloc] init];
        asset8.imageURL = [NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/8.jpg"];
        AssetDataSource *asset9 = [[AssetDataSource alloc] init];
        asset9.imageURL = [NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/9.jpg"];
        AssetDataSource *asset10 = [[AssetDataSource alloc] init];
        asset10.imageURL = [NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/10.jpg"];
        AssetDataSource *asset11 = [[AssetDataSource alloc] init];
        asset11.imageURL = [NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/11.jpg"];
        AssetDataSource *asset12 = [[AssetDataSource alloc] init];
        asset12.imageURL = [NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/12.jpg"];
        AssetDataSource *asset13 = [[AssetDataSource alloc] init];
        asset13.imageURL = [NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/13.jpg"];
        _array = @[asset1, asset2, asset3, asset4, asset5, asset6, asset7, asset8, asset9, asset10, asset11, asset12, asset13];
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
