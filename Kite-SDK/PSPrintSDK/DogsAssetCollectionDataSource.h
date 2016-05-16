//
//  CTAssetCollectionDataSource.h
//  KITAssetsPickerDemo
//
//  Created by Konstadinos Karayannis on 04/11/15.
//  Copyright © 2015 Kite.ly All rights reserved.
//

#import <Foundation/Foundation.h>
#import <KITAssetsPickerController/KITAssetCollectionDataSource.h>

@interface DogsAssetCollectionDataSource : NSObject <KITAssetCollectionDataSource>

- (NSUInteger)count;
- (id)objectAtIndex:(NSUInteger)index;


@end
