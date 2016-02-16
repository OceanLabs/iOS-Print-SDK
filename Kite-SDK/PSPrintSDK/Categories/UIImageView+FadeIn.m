//
//  Modified MIT License
//
//  Copyright (c) 2010-2015 Kite Tech Ltd. https://www.kite.ly
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
