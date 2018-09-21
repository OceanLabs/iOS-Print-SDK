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

#import "NSMutableArray+OLUserSelectedAssetsUtils.h"
#import "OLPlaceholderAsset.h"
#import "OLAsset+Private.h"

@implementation NSMutableArray (OLUserSelectedAssetsUtils)

- (NSArray *)nonPlaceholderAssets{
    NSMutableArray *assets = [[NSMutableArray alloc] init];
    for (id asset in self){
        if (![asset isKindOfClass:[OLPlaceholderAsset class]]){
            [assets addObject:asset];
        }
    }
    
    return assets;
}

- (void)adjustNumberOfSelectedAssetsWithTotalNumberOfAssets:(NSInteger)totalNumberOfAssets trim:(BOOL)trim{
    if (trim){
        for (NSUInteger i = self.count; i > totalNumberOfAssets; i--){
            [self removeObjectAtIndex:i-1];
        }
    }
    for (NSUInteger i = self.count; i < totalNumberOfAssets; i++){
        [self addObject:[[OLPlaceholderAsset alloc] init]];
    }
}

- (NSIndexSet *)updateUserSelectedAssetsAtIndex:(NSInteger)insertIndex withAddedAssets:(NSArray<OLAsset *> *)addedAssets removedAssets:(NSArray<OLAsset *> *)removedAssets{
    NSMutableIndexSet *changedIndexes = [[NSMutableIndexSet alloc] init];
    for (OLAsset *asset in addedAssets){
        for (NSInteger bookPhoto = 0; bookPhoto < self.count; bookPhoto++){
            NSInteger index = (bookPhoto + insertIndex) % self.count;
            if ([[self objectAtIndex:index] isKindOfClass:[OLPlaceholderAsset class]]){
                [self replaceObjectAtIndex:index withObject:asset];
                [changedIndexes addIndex:index];
                break;
            }
        }
    }
    for (OLAsset *asset in removedAssets){
        NSInteger index = [self indexOfObjectIdenticalTo:asset];
        [self replaceObjectAtIndex:index withObject:[[OLPlaceholderAsset alloc] init]];
        [changedIndexes addIndex:index];
    }
    
    return changedIndexes;
}

- (BOOL)containsAssetIgnoringEdits:(OLAsset *)anObject{
    for (OLAsset *asset in self){
        if ([asset isEqual:anObject ignoreEdits:YES]){
            return YES;
        }
    }
    
    return NO;
}

@end
