//
//  OLAddress+AddressBook.m
//  Kite SDK
//
//  Created by Deon Botha on 04/01/2014.
//  Copyright (c) 2014 Deon Botha. All rights reserved.
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
