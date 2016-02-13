//
//  OLURLShortener.h
//  KitePrintSDK
//
//  Created by Deon Botha on 13/02/2016.
//  Copyright © 2016 Kite.ly. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^OLURLShortenerHandler)(NSString *shortenedURL, NSError *error);

@interface OLURLShortener : NSObject

- (void)shortenURL:(NSString *)url handler:(OLURLShortenerHandler)handler;

@end
