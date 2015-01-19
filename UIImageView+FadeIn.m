//
//  UIImageView+FadeIn.m
//  KitePrintSDK
//
//  Created by Deon Botha on 19/01/2015.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import "UIImageView+FadeIn.h"
#import "UIImageView+WebCache.h"
#include <sys/time.h>

@implementation UIImageView (FadeIn)
- (void)setAndFadeInImageWithURL:(NSURL *)url {
    [self setAndFadeInImageWithURL:url placeholder:nil];
}

- (void)setAndFadeInImageWithURL:(NSURL *)url placeholder:(UIImage *)placeholder {
    struct timeval t;
    gettimeofday(&t, NULL);
    long msec = t.tv_sec * 1000 + t.tv_usec / 1000;
    
    self.alpha = 0;
    __weak UIImageView *weakImageView = self;
    
    [self sd_setImageWithURL:url placeholderImage:placeholder completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        struct timeval t;
        gettimeofday(&t, NULL);
        long elapsedTimeMillis = (t.tv_sec * 1000 + t.tv_usec / 1000) - msec;
        
        if (cacheType == SDImageCacheTypeNone || elapsedTimeMillis > 10) {
            weakImageView.alpha = 0;
            [UIView beginAnimations:@"fadeIn" context:nil];
            [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
            [UIView setAnimationDuration:0.3];
            weakImageView.alpha = 1;
            [UIView commitAnimations];
        } else {
            weakImageView.alpha = 1;
        }
    }];
    
}
@end
