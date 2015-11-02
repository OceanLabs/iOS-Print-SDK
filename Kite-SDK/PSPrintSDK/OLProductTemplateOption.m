//
//  OLProductTemplateOptions.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 30/10/15.
//  Copyright © 2015 Kite.ly. All rights reserved.
//

#import "OLProductTemplateOption.h"

@interface OLProductTemplateOption ()

@property (strong, nonatomic) NSArray<NSDictionary *> *options;
@property (strong, nonatomic, readwrite) NSArray <NSString *> *selections;
@property (strong, nonatomic) NSDictionary <NSString *, NSString *> *nameForSelectionCode;

@end

@implementation OLProductTemplateOption

- (instancetype)initWithDictionary:(NSDictionary *)options{
    if (self = [super init]){
        _options = options[@"options"];
        _code = options[@"code"];
        _name = options[@"name"];
        
        NSMutableArray *sel = [[NSMutableArray alloc] init];
        NSMutableDictionary *nameForCode = [[NSMutableDictionary alloc] init];
        for (NSDictionary *dict in _options){
            [sel addObject:dict[@"code"]];
            nameForCode[dict[@"code"]] = dict[@"name"];
        }
        _nameForSelectionCode = nameForCode;
        _selections = sel;
    }
    return self;
}

- (NSString *)nameForSelection:(NSString *)selection{
    return self.nameForSelectionCode[selection];
}

@end
