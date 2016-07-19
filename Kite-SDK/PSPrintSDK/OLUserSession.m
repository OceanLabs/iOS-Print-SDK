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

#import "OLUserSession.h"

@interface OLPrintOrder (Private)

@property (weak, nonatomic) NSArray *userSelectedPhotos;
- (void)saveOrder;
+ (id)loadOrder;

@end

@implementation OLUserSession

+ (instancetype)currentSession {
    static dispatch_once_t once;
    static OLUserSession * sharedInstance;
    dispatch_once(&once, ^ { sharedInstance = [[self alloc] init]; });
    return sharedInstance;
}

-(OLMutableAssetArray *) userSelectedPhotos{
    if (!_userSelectedPhotos || _userSelectedPhotos.count == 0){
        OLMutableAssetArray *mutableUserSelectedPhotos = [[OLMutableAssetArray alloc] init];
        for (id asset in self.appAssets){
            OLPrintPhoto *printPhoto = [[OLPrintPhoto alloc] init];
            printPhoto.asset = asset;
            [mutableUserSelectedPhotos addObject:printPhoto];
        }
        _userSelectedPhotos = mutableUserSelectedPhotos;
    }
    return _userSelectedPhotos;
}

-(OLPrintOrder *) printOrder{
    if (!_printOrder){
        _printOrder = [OLPrintOrder loadOrder];
    }
    if (!_printOrder){
        _printOrder = [[OLPrintOrder alloc] init];
    }
    _printOrder.userSelectedPhotos = self.userSelectedPhotos;
    return _printOrder;
}

- (void)cleanupUserSession:(OLUserSessionCleanupOption)cleanupOptions{
    if ((cleanupOptions & OLUserSessionCleanupOptionPhotos) == OLUserSessionCleanupOptionPhotos){
        self.userSelectedPhotos = nil;
    }
    if ((cleanupOptions & OLUserSessionCleanupOptionBasket) == OLUserSessionCleanupOptionBasket){
        self.printOrder = [[OLPrintOrder alloc] init];
        [self.printOrder saveOrder];
    }
    if ((cleanupOptions & OLUserSessionCleanupOptionPayment) == OLUserSessionCleanupOptionPayment){
        //TODO
    }
    if ((cleanupOptions & OLUserSessionCleanupOptionSocial) == OLUserSessionCleanupOptionSocial){
        //TODO
    }
    if ((cleanupOptions & OLUserSessionCleanupOptionAll) == OLUserSessionCleanupOptionAll){
        self.userSelectedPhotos = nil;
        //TODO
    }
    
}

@end
