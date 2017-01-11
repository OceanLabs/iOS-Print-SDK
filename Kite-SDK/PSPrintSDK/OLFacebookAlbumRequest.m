//
//  Modified MIT License
//
//  Copyright (c) 2010-2017 Kite Tech Ltd. https://www.kite.ly
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

#import "OLFacebookAlbumRequest.h"
#import "OLFacebookImagePickerConstants.h"
#import "OLFacebookAlbum.h"
#import "OLFacebookSDKWrapper.h"
@import UIKit;

@interface OLFacebookAlbumRequest ()
@property (nonatomic, assign) BOOL cancelled;
@property (nonatomic, strong) NSString *after;
@end

@implementation OLFacebookAlbumRequest

+ (void)handleFacebookError:(NSError *)error completionHandler:(OLFacebookAlbumRequestHandler)handler {
    NSString *message;
    if ([error.userInfo objectForKey:@"FBSDKErrorLocalizedDescriptionKey"]) {
        message = [error.userInfo objectForKey:@"FBSDKErrorLocalizedDescriptionKey"];
    } else {
        message = @"Failed to access your Facebook photos. Please check your internet connectivity and try again.";
    }
    
    handler(nil, [NSError errorWithDomain:error.domain code:error.code userInfo:@{NSLocalizedDescriptionKey: message}], nil);
}

- (void)cancel {
    self.cancelled = YES;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)getAlbums:(OLFacebookAlbumRequestHandler)handler {
    if ([OLFacebookSDKWrapper currentAccessToken]) {
        // connection is open, perform the request
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        NSString *graphPath = @"me/albums?limit=100&fields=id,name,count,cover_photo";
        if (self.after) {
            graphPath = [graphPath stringByAppendingFormat:@"&after=%@", self.after];
        }
        
        id request = [OLFacebookSDKWrapper initGraphRequestWithGraphPath:graphPath];
        [OLFacebookSDKWrapper startGraphRequest:request withCompletionHandler:^(id connection, id result, NSError *error) {
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            if (self.cancelled) {
                return;
            }
            if (error) {
                [OLFacebookAlbumRequest handleFacebookError:error completionHandler:handler];
                return;
            }
            
            NSString *parsingErrorMessage = @"Failed to parse Facebook Response. Please check your internet connectivity and try again.";
            NSError *parsingError = [NSError errorWithDomain:kOLErrorDomainFacebookImagePicker code:kOLErrorCodeFacebookImagePickerBadResponse userInfo:@{NSLocalizedDescriptionKey: parsingErrorMessage}];
            id data = [result objectForKey:@"data"];
            if (![data isKindOfClass:[NSArray class]]) {
                handler(nil, parsingError, nil);
                return;
            }
            
            NSMutableArray *albums = [[NSMutableArray alloc] init];
            for (id album in data) {
                if (![album isKindOfClass:[NSDictionary class]]) {
                    continue;
                }
                
                id albumId     = [album objectForKey:@"id"];
                id photoCount  = [album objectForKey:@"count"];
                id name        = [album objectForKey:@"name"];
                
                if (!([albumId isKindOfClass:[NSString class]] && [photoCount isKindOfClass:[NSNumber class]]
                       && [name isKindOfClass:[NSString class]])) {
                    continue;
                }
                
                OLFacebookAlbum *album = [[OLFacebookAlbum alloc] init];
                album.albumId = albumId;
                album.photoCount = [photoCount unsignedIntegerValue];
                album.name = name;
                album.coverPhotoURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=album&access_token=%@", album.albumId, [OLFacebookSDKWrapper tokenString]]];
                [albums addObject:album];
            }
            
            // get next page cursor
            OLFacebookAlbumRequest *nextPageRequest = nil;
            id paging = [result objectForKey:@"paging"];
            if ([paging isKindOfClass:[NSDictionary class]]) {
                id cursors = [paging objectForKey:@"cursors"];
                id next = [paging objectForKey:@"next"]; // next will be non nil if a next page exists
                if (next && [cursors isKindOfClass:[NSDictionary class]]) {
                    id after = [cursors objectForKey:@"after"];
                    if ([after isKindOfClass:[NSString class]]) {
                        nextPageRequest = [[OLFacebookAlbumRequest alloc] init];
                        nextPageRequest.after = after;
                    }
                }
            }
            
            handler(albums, nil, nextPageRequest);
        }];
    }
    else {
        NSString *message = @"No Facebook user authentication found.";
        handler(nil, [NSError errorWithDomain:kOLErrorDomainFacebookImagePicker code:kOLErrorCodeFacebookImagePickerNoOpenSession userInfo:@{NSLocalizedDescriptionKey: message}], nil);
    }
}

@end
