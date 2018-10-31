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

#import "OLInstagramMediaRequest.h"
#import "OLInstagramImage.h"
#import "OLInstagramImagePickerConstants.h"
@import UIKit;

@interface OLInstagramMediaRequest ()
@property (nonatomic, assign) BOOL cancelled;
@end

@implementation OLInstagramMediaRequest

- (id)init {
    return [self initWithBaseURL:@"https://api.instagram.com/v1/users/self/media/recent"];
}

- (id)initWithBaseURL:(NSString *)baseURL {
    if (self = [super init]) {
        _baseURL = baseURL;
    }
    
    return self;
}

- (void)cancel {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    self.cancelled = YES;
}

- (void)fetchMediaWithCompletionHandler:(InstagramMediaRequestCompletionHandler)completionHandler {
    NXOAuth2Account *account = [[[NXOAuth2AccountStore sharedStore] accounts] lastObject];
    [self fetchMediaForAccount:account completionHandler:completionHandler];
}

- (void)fetchMediaForAccount:(NXOAuth2Account *)account completionHandler:(InstagramMediaRequestCompletionHandler)completionHandler {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    if ([self.baseURL rangeOfString:@"access_token"].location == NSNotFound) {
        _baseURL = [self.baseURL stringByAppendingFormat:@"?access_token=%@", account.accessToken.accessToken];
    }
    
    NSURL *url = [NSURL URLWithString:[self.baseURL stringByAppendingString:@"&count=100"]];

    [NXOAuth2Request performMethod:@"GET"
                        onResource:url
                   usingParameters:nil
                       withAccount:account
               sendProgressHandler:^(unsigned long long bytesSend, unsigned long long bytesTotal) { }
                   responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error) {
                       [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                       if (self.cancelled) {
                           return;
                       }
                       
                       NSAssert([NSThread isMainThread], @"Oops not calling back on main thread");
                       
                       NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
                       if (httpResponse.statusCode == 400 || httpResponse.statusCode == 401) {
                           // Kill all accounts and force the user to login again.
                           NSArray *accounts = [[NXOAuth2AccountStore sharedStore] accounts];
                           for (NXOAuth2Account *account in accounts) {
                               [[NXOAuth2AccountStore sharedStore] removeAccount:account];
                           }
                           
                           NSError *error = [NSError errorWithDomain:kOLInstagramImagePickerErrorDomain code:kOLInstagramImagePickerErrorCodeOAuthTokenInvalid userInfo:@{NSLocalizedDescriptionKey: @"Instagram authorization token has expired. You'll need to log in again."}];
                           if (completionHandler) completionHandler(error, nil, nil);
                       } else {
                           NSError *error;
                           NSDictionary *json = responseData == nil ? nil : [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&error];
                           if (error) {
                               if (completionHandler) completionHandler(error, nil, nil);
                               return;
                           }
                           
                           if (httpResponse.statusCode != 200) {
                                NSError *error = [NSError errorWithDomain:kOLInstagramImagePickerErrorDomain code:kOLInstagramImagePickerErrorCodeBadResponse userInfo:@{NSLocalizedDescriptionKey: @"Failed to reach Instagram. Please check your internet connectivity and try again."}];
                               if (completionHandler) completionHandler(error, nil, nil);
                           } else {
                               
                               NSError *error = [NSError errorWithDomain:kOLInstagramImagePickerErrorDomain code:kOLInstagramImagePickerErrorCodeBadResponse userInfo:@{NSLocalizedDescriptionKey: @"Received a bad response from Instagram. Please try again."}];
                               
                               id pagination = [json objectForKey:@"pagination"];
                               id data = [json objectForKey:@"data"];
                               if (![pagination isKindOfClass:[NSDictionary class]] || ![data isKindOfClass:[NSArray class]]) {
                                   if (completionHandler) completionHandler(error, nil, nil);
                                   return;
                               }
                               
                               NSString *nextURL = [pagination objectForKey:@"next_url"];
                               if (nextURL && ![nextURL isKindOfClass:[NSString class]]) {
                                   if (completionHandler) completionHandler(error, nil, nil);
                                   return;
                               }
                               
                               NSMutableArray *media = [[NSMutableArray alloc] init];
                               
                               for (id d in data) {
                                   if (![d isKindOfClass:[NSDictionary class]]) {
                                       continue;
                                   }
                                   
                                   
                                   id images = [d objectForKey:@"images"];
                                   if (![images isKindOfClass:[NSDictionary class]]) {
                                       continue;
                                   }
                                   
                                   id thumbnailResolutionImage = [images objectForKey:@"thumbnail"];
                                   id standardResolutionImage = [images objectForKey:@"standard_resolution"];
                                   if (![thumbnailResolutionImage isKindOfClass:[NSDictionary class]] || ![standardResolutionImage isKindOfClass:[NSDictionary class]]) {
                                       continue;
                                   }
                                   
                                   id thumbnailResolutionImageURLStr = [thumbnailResolutionImage objectForKey:@"url"];
                                   id standardResolutionImageURLStr = [standardResolutionImage objectForKey:@"url"];
                                   CGSize size = CGSizeMake([[standardResolutionImage objectForKey:@"width"] floatValue], [[standardResolutionImage objectForKey:@"height"] floatValue]);
                                   if (![thumbnailResolutionImageURLStr isKindOfClass:[NSString class]] || ![standardResolutionImageURLStr isKindOfClass:[NSString class]]) {
                                       continue;
                                   }
                                   
                                   NSRange range = [thumbnailResolutionImageURLStr rangeOfString:@"http://"];
                                   if (range.location == 0) {
                                       thumbnailResolutionImageURLStr = [thumbnailResolutionImageURLStr stringByReplacingCharactersInRange:range withString:@"https://"];
                                   }
                                   
                                   range = [standardResolutionImageURLStr rangeOfString:@"http://"];
                                   if (range.location == 0) {
                                       standardResolutionImageURLStr = [standardResolutionImageURLStr stringByReplacingCharactersInRange:range withString:@"https://"];
                                   }

                                   OLInstagramImage *im = [[OLInstagramImage alloc] initWithThumbURL:[NSURL URLWithString:thumbnailResolutionImageURLStr] fullURL:[NSURL URLWithString:standardResolutionImageURLStr] size:size];
                                   [media addObject:im];
                                   
                               }
                               
                               OLInstagramMediaRequest *nextPageRequest = nil;
                               if (nextURL) {
                                   nextPageRequest = [[OLInstagramMediaRequest alloc] initWithBaseURL:nextURL];
                               }
                               
                               if (completionHandler) completionHandler(nil, media, nextPageRequest);
                           }
                           
                       }
                       
                   }];

}

@end
