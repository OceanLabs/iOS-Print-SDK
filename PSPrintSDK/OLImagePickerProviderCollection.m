//
//  Modified MIT License
//
//  Copyright (c) 2010-2017 Kite Tech Ltd. https://www.kite.ly
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

#import "OLImagePickerProviderCollection.h"
#import "OLAsset+Private.h"

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
    if (self.fetchResult && self.fetchResult.count > index){
        return [self.fetchResult objectAtIndex:index];
    }
    if (self.array.count > index){
        return [self.array objectAtIndex:index];
    }
    
    return nil;
}

- (NSUInteger)indexOfObject:(id)obj{
    if (self.fetchResult){
        return [self.fetchResult indexOfObject:obj];
    }
    return [self.array indexOfObject:obj];
}

- (void)removeAsset:(OLAsset *)asset{
    [self.array removeObject:asset];
}


- (void)addAssets:(NSArray<OLAsset *> *)assets unique:(BOOL)unique{
    if (unique){
        for (OLAsset *asset in assets){
            for (OLAsset *arrayAsset in [self.array copy]){
                if ([arrayAsset isEqual:asset ignoreEdits:YES]){
                    [self.array removeObject:arrayAsset];
                }
            }
        }
    }
    
    [self.array addObjectsFromArray:assets];
}

@end
