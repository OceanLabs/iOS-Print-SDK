//
//  Modified MIT License
//
//  Copyright (c) 2010-2016 Kite Tech Ltd. https://www.kite.ly
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

#import "OLFacebookSDKWrapper.h"
#import "OLUserSession.h"
#import "OLKiteViewController.h"

@implementation OLFacebookSDKWrapper

+ (id)currentAccessToken{
    Class FBSDKAccessTokenClass = NSClassFromString (@"FBSDKAccessToken");
    SEL aSelector = NSSelectorFromString(@"currentAccessToken");
    IMP imp = [FBSDKAccessTokenClass methodForSelector:aSelector];
    id (*func)(id, SEL) = (void *)imp;
    
    return func(FBSDKAccessTokenClass, aSelector);
}

+ (id)initGraphRequestWithGraphPath:(NSString *)graphPath{
    Class FBSDKGraphRequestClass = NSClassFromString (@"FBSDKGraphRequest");
    id graph = [FBSDKGraphRequestClass alloc];
    
    SEL aSelector = NSSelectorFromString(@"initWithGraphPath:parameters:");
    IMP imp = [graph methodForSelector:aSelector];
    id (*func)(id, SEL, id, id) = (void *)imp;
    
    graph = func(graph, aSelector, graphPath, @{});
    return graph;
}

+ (void)startGraphRequest:(id)graphRequest withCompletionHandler:(void(^)(id connection, id result, NSError *error))handler{
    SEL aSelector = NSSelectorFromString(@"startWithCompletionHandler:");
    IMP imp = [graphRequest methodForSelector:aSelector];
    id (*func)(id, SEL, id) = (void *)imp;
    
    func(graphRequest, aSelector, handler);
}

+ (void)login:(id)login withReadPermissions:(NSArray *)permissions fromViewController:(UIViewController *)vc handler:(void(^)(id result, NSError *error))handler{
    SEL aSelector = NSSelectorFromString(@"logInWithReadPermissions:fromViewController:handler:");
    void (*imp)(id, SEL, id, id, id) = (void(*)(id,SEL,id, id, id))[login methodForSelector:aSelector];
    if( imp ) imp(login, aSelector, permissions, vc, handler);
}

+ (id)tokenString{
    id token = [self currentAccessToken];
    SEL aSelector = NSSelectorFromString(@"tokenString");
    IMP imp = [token methodForSelector:aSelector];
    id (*func)(id, SEL) = (void *)imp;
    
    return func(token, aSelector);
}

+ (id)loginManager{
    Class FBSDKLoginManagerClass = NSClassFromString (@"FBSDKLoginManager");
    return [[FBSDKLoginManagerClass alloc] init];
}

+ (void)logout{
    id loginManager = [OLFacebookSDKWrapper loginManager];
    SEL aSelector = NSSelectorFromString(@"logOut");
    
    void (*imp)(id, SEL) = (void(*)(id,SEL))[loginManager methodForSelector:aSelector];
    if( imp ) imp(loginManager, aSelector);
}

+ (BOOL)isFacebookAvailable{
    if ([OLUserSession currentSession].kiteVc.disableFacebook){
        return NO;
    }
    Class FBSDKLoginManagerClass = NSClassFromString (@"FBSDKLoginManager");
    if (![FBSDKLoginManagerClass class]){
        return NO;
    }
    for (NSString *s in @[@"logOut", @"logInWithReadPermissions:fromViewController:handler:"]){
        SEL aSelector = NSSelectorFromString(s);
        if (![FBSDKLoginManagerClass instancesRespondToSelector:aSelector]){
            NSLog(@"Warning: Facebook API version mismatch.");
            return NO;
        }
    }
    
    Class FBSDKAccessTokenClass = NSClassFromString (@"FBSDKAccessToken");
    if (![FBSDKAccessTokenClass class]){
        return NO;
    }
    for (NSString *s in @[@"currentAccessToken", @"setCurrentAccessToken:"]){
        SEL aSelector = NSSelectorFromString(s);
        if (![FBSDKAccessTokenClass respondsToSelector:aSelector]){
            NSLog(@"Warning: Facebook API version mismatch.");
            return NO;
        }
    }
    
    Class FBSDKGraphRequestClass = NSClassFromString (@"FBSDKGraphRequest");
    if (![FBSDKGraphRequestClass class]){
        NSLog(@"Warning: Facebook API version mismatch.");
        return NO;
    }
    
    SEL aSelector = NSSelectorFromString(@"startWithCompletionHandler:");
    if (![FBSDKGraphRequestClass instancesRespondToSelector:aSelector]){
        NSLog(@"Warning: Facebook API version mismatch.");
        return NO;
    }
    
    return YES;
    
}

@end
