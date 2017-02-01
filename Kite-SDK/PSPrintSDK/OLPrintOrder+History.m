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

#import "OLPrintOrder+History.h"
#import "OLProductPrintJob.h"

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
    NSMutableArray *printOrders = (NSMutableArray *)[OLPrintOrder printOrderHistory];
    if (self.storageIdentifier == NSNotFound) {
        // Get a new unique storage identifier
        NSInteger maxStorageIdentifier = -1;
        for (OLPrintOrder *order in printOrders) {
            maxStorageIdentifier = MAX(maxStorageIdentifier, order.storageIdentifier);
        }
        
        self.storageIdentifier = maxStorageIdentifier + 1;
        [printOrders addObject:self];
    } else {
        // as a storage identifier is assigned this print order must already be stored in the array,
        // replace it there as there might have been changes
        [printOrders replaceObjectAtIndex:(NSUInteger)self.storageIdentifier withObject:self];
    }
    
     [NSKeyedArchiver archiveRootObject:printOrders toFile:[OLPrintOrder historyFilePath]];
    printOrders = nil;
}

- (void)deleteFromHistory {
    NSMutableArray *printOrders = (NSMutableArray *)[OLPrintOrder printOrderHistory];
    for (OLPrintOrder *order in printOrders) {
        if (order.storageIdentifier == self.storageIdentifier) {
            self.storageIdentifier = NSNotFound;
            [printOrders removeObject:order];
            break;
        }
    }
    
    [NSKeyedArchiver archiveRootObject:printOrders toFile:[OLPrintOrder historyFilePath]];
}

+ (NSArray *)printOrderHistory {
    NSMutableArray *printOrders = [NSKeyedUnarchiver unarchiveObjectWithFile:[OLPrintOrder historyFilePath]];
    if (!printOrders) {
        printOrders = [[NSMutableArray alloc] init];
    }
    
    return printOrders;
}


@end
