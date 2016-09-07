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

#import "OLProductTemplateOption.h"
#import "OLImageDownloader.h"
#import "UIImage+ImageNamedInKiteBundle.h"

@interface OLProductTemplateOption ()

@property (strong, nonatomic, readwrite) NSArray <OLProductTemplateOptionChoice *> *choices;
@property (strong, nonatomic) NSURL *iconURL;
@property (strong, nonatomic) NSString *iconImageName;

@end

@implementation OLProductTemplateOption

- (instancetype)initWithDictionary:(NSDictionary *)options{
    if (self = [super init]){
        _code = options[@"code"];
        _name = options[@"name"];
        
        NSMutableArray *choices = [[NSMutableArray alloc] init];
        if (![options[@"options"] isKindOfClass:[NSArray class]]){
            return nil;
        }
        for (NSDictionary *dict in options[@"options"]){
            if (![dict isKindOfClass:[NSDictionary class]]){
                continue;
            }
            OLProductTemplateOptionChoice *choice = [[OLProductTemplateOptionChoice alloc] init];
            choice.option = self;
            choice.code = dict[@"code"];
            choice.name = dict[@"name"];
            if (dict[@"icon"]){
                choice.iconURL = [NSURL URLWithString:dict[@"icon"]];
            }
            if (dict[@"color"]){
//                choice.color =
            }
            if (dict[@"extraCost"]){
//                choice.extraCost = 
            }
            if (dict[@"productOverlay"]){
                choice.productOverlay = [NSURL URLWithString:dict[@"productOverlay"]];
            }
            if (dict[@"borderOverride"]){
//                choice.borderOverride = UIEdgeInsetsMake(0, 0, 0, 0);
            }
            
            [choices addObject:choice];
        }
        _choices = choices;
    }
    return self;
}

- (void)iconWithCompletionHandler:(void(^)(UIImage *icon))handler{
    handler(nil);
    if (self.iconURL){
        [[OLImageDownloader sharedInstance] downloadImageAtURL:self.iconURL withCompletionHandler:^(UIImage *image, NSError *error){
            if (error || !image){
                handler([self fallbackIcon]);
            }
            else{
                handler(image);
            }
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
        if ([self.code isEqualToString:@"case_style"]){
            return [UIImage imageNamedInKiteBundle:@"case-options"];
        }
    }
    
    return nil;
}

@end
