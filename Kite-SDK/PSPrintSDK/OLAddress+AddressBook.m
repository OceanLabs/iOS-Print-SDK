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
#import "OLAddress+AddressBook.h"

static NSMutableArray *addressBook;

@implementation OLAddress (AddressBook)

+ (NSString *)addressBookFilePath {
    NSArray * urls = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSString *documentDirPath = [(NSURL *)[urls objectAtIndex:0] path];
    return [documentDirPath stringByAppendingPathComponent:@"co.oceanlabs.pssdk.AddressBook"];
}

- (BOOL)isSavedInAddressBook {
    for (OLAddress *address in [OLAddress addressBook]) {
        if (address == self || [address isEqual:self]) {
            // memory address equal counts to which covers cases where the user edits an existing address!
            return YES;
        }
    }
    
    return NO;
}

- (void)saveToAddressBook {
    for (OLAddress *address in [OLAddress addressBook]) {
        if (address == self || [address isEqual:self]) {
            // memory address equal counts to which covers cases where the user edits an existing address!
            [NSKeyedArchiver archiveRootObject:addressBook toFile:[OLAddress addressBookFilePath]];
            return;
        }
    }
    
    [addressBook addObject:self];
    [NSKeyedArchiver archiveRootObject:addressBook toFile:[OLAddress addressBookFilePath]];
}

- (void)deleteFromAddressBook {
    for (OLAddress *address in [OLAddress addressBook]) {
        if (address == self || [address isEqual:self]) {
            // memory address equal counts to which covers cases where the user edits an existing address!
            [addressBook removeObject:self];
            [NSKeyedArchiver archiveRootObject:addressBook toFile:[OLAddress addressBookFilePath]];
            return;
        }
    }
}

+ (void)clearAddressBook{
    for (OLAddress *address in [OLAddress addressBook]) {
            [addressBook removeObject:address];
            [NSKeyedArchiver archiveRootObject:addressBook toFile:[OLAddress addressBookFilePath]];
            return;
    }
}

+ (NSArray *)addressBook {
    if (!addressBook) {
        addressBook = [NSKeyedUnarchiver unarchiveObjectWithFile:[OLAddress addressBookFilePath]];
        if (!addressBook) {
            addressBook = [[NSMutableArray alloc] init];
        }
    }
    
   
    
    return addressBook;
}

@end
