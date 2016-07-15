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

#import "OLImageDownloader.h"

#import "UIImageView+FadeIn.h"
#import "OLImageDownloader.h"
#import "OLPrintPhoto.h"
#import "objc/runtime.h"

static char tasksKey;

@implementation UIImageView (FadeIn)
- (void)setAndFadeInImageWithURL:(NSURL *)url {
    [self setAndFadeInImageWithURL:url placeholder:nil completionHandler:NULL];
}

- (void)setAndFadeInImageWithURL:(NSURL *)url placeholder:(UIImage *)placeholder{
    [self setAndFadeInImageWithURL:url placeholder:placeholder completionHandler:NULL];
}

- (void)setAndFadeInImageWithURL:(NSURL *)url placeholder:(UIImage *)placeholder completionHandler:(void(^)())handler{
    for (id key in self.tasks.allKeys){
        if (![key isEqual:url]){
            [self.tasks[key] cancel];
        }
    }
    
    self.alpha = 0;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSURLSessionTask *task = [[OLImageDownloader sharedInstance] downloadImageAtURL:url withCompletionHandler:^(UIImage *image, NSError *error){
            if ([self.tasks[url] state] == NSURLSessionTaskStateCanceling){
                [self.tasks removeObjectForKey:url];
                return;
            }
            [self.tasks removeObjectForKey:url];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                UIImage *resizedImage = [OLPrintPhoto imageWithImage:image scaledToSize:[UIScreen mainScreen].bounds.size];
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.image = resizedImage;
                    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                        self.alpha = 1;
                    }completion:^(BOOL finished){
                        if (handler){
                            handler();
                        }
                    }];
                });
            });
        }];
        self.tasks[url] = task;
    });
}

- (NSMutableDictionary *)tasks{
    NSMutableDictionary *tasks = objc_getAssociatedObject(self, &tasksKey);
    if (tasks){
        return tasks;
    }
    tasks = [[NSMutableDictionary alloc] init];
    objc_setAssociatedObject(self, &tasksKey, tasks, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return tasks;
}

@end
