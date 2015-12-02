//
//  CTAssetCollectionDataSource.m
//  KITAssetsPickerDemo
//
//  Created by Konstadinos Karayannis on 04/11/15.
//  Copyright © 2015 Clement T. All rights reserved.
//

#import "CTAssetCollectionDataSource.h"
#import "CTAssetDataSource.h"

@interface CTAssetCollectionDataSource ()

@property (strong, nonatomic) NSArray *array;

@end

@implementation CTAssetCollectionDataSource

- (instancetype)init{
    if (self = [super init]){
        _array = @[[[CTAssetDataSource alloc] init], [[CTAssetDataSource alloc] init]];
    }
    
    return self;
}

- (NSString *)title{
    return @"My 1337 Album";
}

- (id)copyWithZone:(NSZone *)zone{
    CTAssetCollectionDataSource *copy = [[CTAssetCollectionDataSource alloc] init];
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
