//
//  OLFacebookAlbumRequest.m
//  FacebookImagePicker
//
//  Created by Deon Botha on 15/12/2013.
//  Copyright (c) 2013 Deon Botha. All rights reserved.
//

#import "OLFacebookAlbumRequest.h"
#import "OLFacebookImagePickerConstants.h"
#import "OLFacebookAlbum.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>

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
    if ([FBSDKAccessToken currentAccessToken]) {
        // connection is open, perform the request
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        NSString *graphPath = @"me/albums?limit=100&fields=id,name,count,cover_photo";
        if (self.after) {
            graphPath = [graphPath stringByAppendingFormat:@"&after=%@", self.after];
        }
        
        FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:graphPath parameters:nil];
        [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
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
                album.coverPhotoURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=small&access_token=%@", album.albumId, [FBSDKAccessToken currentAccessToken].tokenString]];
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
