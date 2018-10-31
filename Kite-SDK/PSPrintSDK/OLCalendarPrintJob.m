//
//  OLCalendarPrintJob.m
//  KiteSDK
//
//  Created by Konstadinos Karayannis on 06/08/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

#import "OLCalendarPrintJob.h"

@implementation OLCalendarPrintJob

- (NSDictionary *)jsonRepresentation {
    NSMutableDictionary *dict = [[super jsonRepresentation] mutableCopy];
    NSMutableDictionary *options = dict[@"options"] ? dict[@"options"] : [[NSMutableDictionary alloc] init];
    options[@"start_month"] = @"1";
    
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitYear fromDate:[NSDate date]];
    options[@"start_year"] = [NSString stringWithFormat:@"%ld", components.year];
    dict[@"options"] = options;
    
    return dict;
}

@end
