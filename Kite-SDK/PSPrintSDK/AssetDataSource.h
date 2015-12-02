//
//  CTAssetDataSource.h
//  KITAssetsPickerDemo
//
//  Created by Konstadinos Karayannis on 04/11/15.
//  Copyright © 2015 Kite.ly All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KITAssetDataSource.h"

@interface AssetDataSource : NSObject <KITAssetDataSource>

@property (strong, nonatomic) NSString *url;

@end
