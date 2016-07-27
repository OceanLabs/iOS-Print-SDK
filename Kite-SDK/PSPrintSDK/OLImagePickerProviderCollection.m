//
//  OLImagePickerProviderCollection.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 22/07/16.
//  Copyright © 2016 Kite.ly. All rights reserved.
//

#import "OLImagePickerProviderCollection.h"

@interface OLImagePickerProviderCollection ()

@property (strong, nonatomic) NSMutableArray<OLAsset *> *array;
@property (strong, nonatomic) PHFetchResult *fetchResult;
@property (strong, nonatomic, readwrite) NSString *name;

@end

@implementation OLImagePickerProviderCollection

- (instancetype)initWithArray:(NSArray<OLAsset *> *)array name:(NSString *)name{
    self = [super init];
    if (self){
        self.array = [array mutableCopy];
        self.name = name;
    }
    
    return self;
}

- (instancetype)initWithPHFetchResult:(PHFetchResult *)fetchResult name:(NSString *)name{
    self = [super init];
    if (self){
        self.fetchResult = fetchResult;
        self.name = name;
    }
    
    return self;
}

- (id)copyWithZone:(NSZone *)zone{
    OLImagePickerProviderCollection *copy = [[OLImagePickerProviderCollection alloc] init];
    copy.array = [[NSMutableArray alloc] initWithArray:self.array copyItems:NO];
    copy.fetchResult = [self.fetchResult copyWithZone:zone];
    return copy;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(__unsafe_unretained id  _Nonnull *)buffer count:(NSUInteger)len{
    if (self.fetchResult){
        return [self.fetchResult countByEnumeratingWithState:state objects:buffer count:len];
    }
    return [self.array countByEnumeratingWithState:state objects:buffer count:len];
}

- (NSUInteger)count{
    if (self.fetchResult){
        return self.fetchResult.count;
    }
    return self.array.count;
}

- (id)objectAtIndex:(NSUInteger)index{
    if (self.fetchResult){
        return [self.fetchResult objectAtIndex:index];
    }
    return [self.array objectAtIndex:index];
}

- (NSUInteger)indexOfObject:(id)obj{
    if (self.fetchResult){
        return [self.fetchResult indexOfObject:obj];
    }
    return [self.array indexOfObject:obj];
}

@end
