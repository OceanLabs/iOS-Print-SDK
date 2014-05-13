//
//  OLPrintOrder+Receipt.h
//  Kite SDK
//
//  Created by Deon Botha on 11/01/2014.
//  Copyright (c) 2014 Deon Botha. All rights reserved.
//

#import "OLPrintOrder.h"

@interface OLPrintOrder (History)
+ (NSArray *)printOrderHistory;
- (void)saveToHistory;
- (void)deleteFromHistory;
- (BOOL)isSavedInHistory;
@end
