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

#import "OLProductTemplateOptionChoice.h"
#import "UIImage+ImageNamedInKiteBundle.h"
#import "OLImageDownloader.h"
#import "OLProductTemplateOption.h"
#import "OLProduct.h"

@implementation OLProductTemplateOptionChoice

- (void)iconWithCompletionHandler:(void(^)(UIImage *icon))handler{
    handler(nil);
    if (self.iconURL){
        [[OLImageDownloader sharedInstance] downloadImageAtURL:self.iconURL withCompletionHandler:^(UIImage *image, NSError *error){
            dispatch_async(dispatch_get_main_queue(), ^{
                if (error || !image){
                    handler([self fallbackIcon]);
                }
                else{
                    handler(image);
                }
            });
        }];
    }
    else{
        handler([self fallbackIcon]);
    }
}

- (UIImage *)fallbackIcon{
    if (self.iconImageName){
        return [UIImage imageNamedInKiteBundle:self.iconImageName];
    }
    else{ //Match known options with embedded assets
        if ([self.option.code isEqualToString:@"case_style"]){
            if ([self.code isEqualToString:@"gloss"]){
                return [UIImage imageNamedInKiteBundle:@"case-options-gloss"];
            }
            else if ([self.code isEqualToString:@"matte"]){
                return [UIImage imageNamedInKiteBundle:@"case-options-matte"];
            }
        }
    }
    
    return nil;
}

- (NSString *)extraCost{
    OLProduct *product = [OLProduct productWithTemplateId:self.code];
    return [product unitCost];
}

@end
