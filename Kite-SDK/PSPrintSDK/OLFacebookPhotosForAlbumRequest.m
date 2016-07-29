//
//  OLFacebookPhotosForAlbumRequest.m
//  FacebookImagePicker
//
//  Created by Deon Botha on 16/12/2013.
//  Copyright (c) 2013 Deon Botha. All rights reserved.
//

#import "OLFacebookPhotosForAlbumRequest.h"
#import "OLFacebookAlbum.h"
#import "OLFacebookImage.h"
#import "OLFacebookImagePickerConstants.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>

@interface OLFacebookPhotosForAlbumRequest ()
@property (nonatomic, assign) BOOL cancelled;
@property (nonatomic, strong) OLFacebookAlbum *album;
@property (nonatomic, strong) NSString *after;
@end

@implementation OLFacebookPhotosForAlbumRequest

+ (void)handleFacebookError:(NSError *)error completionHandler:(OLFacebookPhotosForAlbumRequestHandler)handler {
    NSString *message;
    if ([error.userInfo objectForKey:@"FBSDKErrorLocalizedDescriptionKey"]) {
        message = [error.userInfo objectForKey:@"FBSDKErrorLocalizedDescriptionKey"];
    } else {
        message = @"Failed to access your Facebook photos. Please check your internet connectivity and try again.";
    }
    
    handler(nil, [NSError errorWithDomain:error.domain code:error.code userInfo:@{NSLocalizedDescriptionKey: message}], nil);
}

- (id)initWithAlbum:(OLFacebookAlbum *)album after:(NSString *)after {
    if (self = [super init]) {
        self.album = album;
        self.after = after;
    }
    
    return self;
}

- (id)initWithAlbum:(OLFacebookAlbum *)album {
    return [self initWithAlbum:album after:nil];
}

- (void)cancel {
    self.cancelled = YES;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)getPhotos:(OLFacebookPhotosForAlbumRequestHandler)handler {
    if ([FBSDKAccessToken currentAccessToken]) {
        // connection is open, perform the request
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        NSString *graphPath = [NSString stringWithFormat:@"%@/photos?fields=picture,source,id,images&limit=100", self.album.albumId];
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
                [OLFacebookPhotosForAlbumRequest handleFacebookError:error completionHandler:handler];
                return;
            }
            
            NSString *parsingErrorMessage = @"Failed to parse Facebook Response. Please check your internet connectivity and try again.";
            NSError *parsingError = [NSError errorWithDomain:kOLErrorDomainFacebookImagePicker code:kOLErrorCodeFacebookImagePickerBadResponse userInfo:@{NSLocalizedDescriptionKey: parsingErrorMessage}];
            
            id data = [result objectForKey:@"data"];
            if (![data isKindOfClass:[NSArray class]]) {
                handler(nil, parsingError, nil);
                return;
            }
            
            NSMutableArray *albumPhotos = [[NSMutableArray alloc] init];
            for (id photo in data) {
                id thumbURLString = [photo objectForKey:@"picture"];
                id fullURLString  = [photo objectForKey:@"source"];
                id uidString  = [photo objectForKey:@"id"];
                
                if (!([thumbURLString isKindOfClass:[NSString class]] && [fullURLString isKindOfClass:[NSString class]])) {
                    continue;
                }
                
                NSMutableArray *sourceImages = [[NSMutableArray alloc] init];
                if ([photo[@"images"] isKindOfClass:[NSArray class]]) {
                    for (id image in photo[@"images"]) {
                        id source = image[@"source"];
                        id width = image[@"width"];
                        id height = image[@"height"];
                        if ([source isKindOfClass:[NSString class]] &&
                            [width isKindOfClass:[NSNumber class]] &&
                            [height isKindOfClass:[NSNumber class]]) {
                            [sourceImages addObject:[[OLFacebookImageURL alloc] initWithURL:[NSURL URLWithString:source] size:CGSizeMake([width doubleValue], [height doubleValue])]];
                        }
                    }
                }
                
                OLFacebookImage *image = [[OLFacebookImage alloc] initWithThumbURL:[NSURL URLWithString:thumbURLString] fullURL:[NSURL URLWithString:fullURLString] albumId:self.album.albumId uid:uidString sourceImages:sourceImages];
                [albumPhotos addObject:image];
            }
            
            // get next page cursor
            OLFacebookPhotosForAlbumRequest *nextPageRequest = nil;
            id paging = [result objectForKey:@"paging"];
            if ([paging isKindOfClass:[NSDictionary class]]) {
                id cursors = [paging objectForKey:@"cursors"];
                id next = [paging objectForKey:@"next"]; // next will be non nil if a next page exists
                if (next && [cursors isKindOfClass:[NSDictionary class]]) {
                    id after = [cursors objectForKey:@"after"];
                    if ([after isKindOfClass:[NSString class]]) {
                        nextPageRequest = [[OLFacebookPhotosForAlbumRequest alloc] initWithAlbum:self.album after:after];
                    }
                }
            }
            
            handler(albumPhotos, nil, nextPageRequest);
        }];
    }
    else {
        NSString *message = @"No Facebook user authentication found.";
        handler(nil, [NSError errorWithDomain:kOLErrorDomainFacebookImagePicker code:kOLErrorCodeFacebookImagePickerNoOpenSession userInfo:@{NSLocalizedDescriptionKey: message}], nil);
    }
}

@end
