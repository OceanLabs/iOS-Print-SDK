//
//  CTAssetDataSource.m
//  KITAssetsPickerDemo
//
//  Created by Konstadinos Karayannis on 04/11/15.
//  Copyright © 2015 Clement T. All rights reserved.
//

#import "CTAssetDataSource.h"

@implementation CTAssetDataSource

- (void)dataLengthWithCompletionHandler:(void (^)(long long, NSError *))handler{
    handler(UIImageJPEGRepresentation([UIImage imageNamed:@"1"], 0.7).length, nil);
}

- (void)dataWithCompletionHandler:(void (^)(NSData *, NSError *))handler{
    handler(UIImageJPEGRepresentation([UIImage imageNamed:@"1"], 0.7), nil);
}

- (NSString *)mimeType{
    return @"image/jpeg";
}

- (void)encodeWithCoder:(NSCoder *)aCoder {

}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
       
    }
    
    return self;
}

- (void)thumbnailImageWithCompletionHandler:(void (^)(UIImage *))handler{
    handler([UIImage imageNamed:@"1"]);
}

- (CGFloat)pixelWidth{
    return [UIImage imageNamed:@"1"].size.width;
}
- (CGFloat)pixelHeight{
    return [UIImage imageNamed:@"1"].size.height;
}


@end
