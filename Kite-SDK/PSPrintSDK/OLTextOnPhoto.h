//
//  OLTextOnPhoto.h
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 10/03/16.
//  Copyright © 2016 Kite.ly. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OLTextOnPhoto : NSObject <NSCoding, NSCopying>

@property (strong, nonatomic) NSString *text;
@property (assign, nonatomic) CGRect frame;
@property (assign, nonatomic) CGAffineTransform transform;

@end
