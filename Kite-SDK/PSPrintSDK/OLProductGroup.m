//
//  OLProductGroup.m
//  KitePrintSDK
//
//  Created by Deon Botha on 09/04/2015.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
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
