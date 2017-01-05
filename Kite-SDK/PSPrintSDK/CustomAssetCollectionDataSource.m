//
//  Modified MIT License
//
//  Copyright (c) 2010-2016 Kite Tech Ltd. https://www.kite.ly
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The software MAY ONLY be used with the Kite Tech Ltd platform and MAY NOT be modified
//  to be used with any competitor platforms. This means the software MAY NOT be modified
//  to place orders with any competitors to Kite Tech Ltd, all orders MUST go through the
//  Kite Tech Ltd platform servers.
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
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
