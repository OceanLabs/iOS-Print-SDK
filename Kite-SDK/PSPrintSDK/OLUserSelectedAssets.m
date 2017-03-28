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

#import "OLUserSelectedAssets.h"
#import "OLPlaceholderAsset.h"

@interface OLUserSelectedAssets ()
@property (strong, nonatomic) NSMutableArray<OLAsset *> *assets;
@end

@implementation OLUserSelectedAssets

-(NSMutableArray *) assets{
    if (!_assets){
        _assets = [[NSMutableArray alloc] init];
    }
    return _assets;
}

- (OLAsset *)assetAtIndex:(NSInteger)index{
    return [self.assets objectAtIndex:index];
}

- (void)addAsset:(OLAsset *)asset{
    [self.assets addObject:asset];
}

- (void)removeAsset:(OLAsset *)asset{
    [self.assets removeObject:asset];
}

- (void)removeAssetAtIndex:(NSInteger)index{
    [self.assets removeObjectAtIndex:index];
}

- (void)replaceAsset:(OLAsset *)asset withNewAsset:(OLAsset *)newAsset{
    NSInteger index = [self.assets indexOfObject:asset];
    [self.assets replaceObjectAtIndex:index withObject:newAsset];
}

- (NSInteger)count{
    NSInteger count = 0;
    for (OLAsset *asset in self.assets){
        if (![asset isKindOfClass:[OLPlaceholderAsset class]]){
            count++;
        }
    }
    
    return count;
}

- (void)clearAssets{
    [self.assets removeAllObjects];
}

- (NSArray *)nonPlaceholderAssets{
    NSMutableArray *assets = [[NSMutableArray alloc] init];
    for (OLAsset *asset in self.assets){
        if (![asset isKindOfClass:[OLPlaceholderAsset class]]){
            [assets addObject:asset];
        }
    }
    
    return assets;
}

- (void)discardPlaceholderAssets{
    self.assets = (NSMutableArray *)[self nonPlaceholderAssets];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(__unsafe_unretained id  _Nonnull *)buffer count:(NSUInteger)len{
    return [self.assets countByEnumeratingWithState:state objects:buffer count:len];
}

- (void)exchangeAssetAtIndex:(NSInteger)index1 withAssetAtIndex:(NSInteger)index2{
    [self.assets exchangeObjectAtIndex:index1 withObjectAtIndex:index2];
}

- (void)trimAndPadWithPlaceholderAssetsWithTotalNumberOfAssets:(NSInteger)totalNumberOfAssets{
    for (NSUInteger i = self.assets.count; i > totalNumberOfAssets; i++){
        [self.assets removeObjectAtIndex:i-1];
    }
    for (NSUInteger i = self.assets.count; i < totalNumberOfAssets; i++){
        [self.assets addObject:[[OLPlaceholderAsset alloc] init]];
    }
}

@end
