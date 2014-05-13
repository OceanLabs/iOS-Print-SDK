//
//  URLAsset.h
//  Kite SDK
//
//  Created by Deon Botha on 20/01/2014.
//  Copyright (c) 2014 Deon Botha. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OLAsset.h"

@interface OLURLDataSource : NSObject <OLAssetDataSource>
- (id)initWithURLString:(NSString *)url;
@end
