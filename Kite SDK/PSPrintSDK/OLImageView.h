//
//  OLImageView.h
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 19/6/15.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol OLImageViewDelegate <NSObject>

@end

@interface OLImageView : UIImageView

@property (weak, nonatomic) id<OLImageViewDelegate> delegate;

@end
