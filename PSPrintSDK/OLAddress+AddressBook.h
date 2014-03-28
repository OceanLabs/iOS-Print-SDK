//
//  OLAddress+AddressBook.h
//  PS SDK
//
//  Created by Deon Botha on 04/01/2014.
//  Copyright (c) 2014 Deon Botha. All rights reserved.
//

#import "OLAddress.h"

@interface OLAddress (AddressBook)

+ (NSArray *)addressBook;
- (void)saveToAddressBook;
- (void)deleteFromAddressBook;
- (BOOL)isSavedInAddressBook;

@end
