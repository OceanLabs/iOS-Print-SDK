//
//  CTAssetCollectionDataSource.h
//  KITAssetsPickerDemo
//
//  Created by Konstadinos Karayannis on 04/11/15.
//  Copyright © 2015 Clement T. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KITAssetCollectionDataSource.h"

@interface CTAssetCollectionDataSource : NSObject <KITAssetCollectionDataSource>

- (NSUInteger)count;
- (id)objectAtIndex:(NSUInteger)index;


@end
