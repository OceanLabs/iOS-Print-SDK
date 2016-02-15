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

#import "OLProductGroup.h"
#import "OLProduct.h"


static OLProductGroup *findGroupWithTemplateClass(NSArray *groups, NSString *templateClass) {
    for (OLProductGroup *group in groups) {
        if ([group.templateClass isEqualToString:templateClass]) {
            return group;
        }
    }
    
    return nil;
}


@implementation OLProductGroup

- (id)initWithTemplateClassName:(NSString *)templateClass {
    if (self = [super init]) {
        _products = [[NSMutableArray alloc] init];
        _templateClass = templateClass;
    }
    
    return self;
}

+ (NSArray *)groups {
    return [self groupsWithFilters:nil];
}

+ (NSArray *)groupsWithFilters:(NSArray *)templateIds {
    NSMutableArray *groups = [[NSMutableArray alloc] init];
    NSArray *allProducts = [OLProduct productsWithFilters:templateIds];
    
    for (OLProduct *product in allProducts){
        if (![product isValidProductForUI]){
            continue;
        }
        
        OLProductGroup *group = findGroupWithTemplateClass(groups, product.productTemplate.templateClass);
        if (group == nil) {
            group = [[OLProductGroup alloc] initWithTemplateClassName:product.productTemplate.templateClass];
            [groups addObject:group];
        }
        
        [group.products addObject:product];
    }
    
    return groups;
}

@end
