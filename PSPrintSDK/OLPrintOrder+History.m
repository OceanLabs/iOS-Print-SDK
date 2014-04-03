//
//  OLPrintOrder+Receipt.m
//  PS SDK
//
//  Created by Deon Botha on 11/01/2014.
//  Copyright (c) 2014 Deon Botha. All rights reserved.
//

#import "OLPrintOrder+History.h"
#import "OLProductPrintJob.h"

static NSMutableArray *printOrders;

@interface OLPrintOrder ()
@property (nonatomic, assign) NSInteger storageIdentifier;
@end

@implementation OLPrintOrder (History)

+ (NSString *)historyFilePath {
    NSArray * urls = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSString *documentDirPath = [(NSURL *)[urls objectAtIndex:0] path];
    return [documentDirPath stringByAppendingPathComponent:@"co.oceanlabs.pssdk.OLPrintOrderHistory"];
}

- (BOOL)isSavedInHistory {
    return self.storageIdentifier != NSNotFound;
}

- (void)saveToHistory {
    // TODO: this seems totally wrong on reflection. StorageIdentifier is not even persisted. Need to make it part of PrintOrder.
    if (self.storageIdentifier == NSNotFound) {
        // Get a new unique storage identifier
        NSInteger maxStorageIdentifier = -1;
        for (OLPrintOrder *order in [OLPrintOrder printOrderHistory]) {
            maxStorageIdentifier = MAX(maxStorageIdentifier, order.storageIdentifier);
        }
        
        self.storageIdentifier = maxStorageIdentifier + 1;
        [printOrders addObject:self];
    } else {
        // as a storage identifier is assigned this print order must already be stored in the array
    }
    
     [NSKeyedArchiver archiveRootObject:printOrders toFile:[OLPrintOrder historyFilePath]];
}

- (void)deleteFromHistory {
    for (OLPrintOrder *order in [OLPrintOrder printOrderHistory]) {
        if (order.storageIdentifier == self.storageIdentifier) {
            [printOrders removeObject:order];
            break;
        }
    }
    
    self.storageIdentifier = NSNotFound;
    [NSKeyedArchiver archiveRootObject:printOrders toFile:[OLPrintOrder historyFilePath]];
}

+ (NSArray *)printOrderHistory {
    if (!printOrders) {
        printOrders = [NSKeyedUnarchiver unarchiveObjectWithFile:[OLPrintOrder historyFilePath]];
        if (!printOrders) {
            printOrders = [[NSMutableArray alloc] init];
        }
    }
    
    return printOrders;
}


@end
