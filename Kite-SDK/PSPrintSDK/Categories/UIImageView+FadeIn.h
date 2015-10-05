//
//  UIImageView+FadeIn.h
//  KitePrintSDK
//
//  Created by Deon Botha on 19/01/2015.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImageView (FadeIn)
- (void)setAndFadeInImageWithURL:(NSURL *)url;
- (void)setAndFadeInImageWithURL:(NSURL *)url placeholder:(UIImage *)placeholder;
@end
