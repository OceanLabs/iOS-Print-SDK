//
//  OLPaymentLineItemPercentage.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 5/12/15.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import "OLPaymentLineItemPercentage.h"

static NSString *const kKeyLineItemJob = @"co.oceanlabs.kKeyLineItemJob";

@interface OLDecimalNumberBehavior : NSObject <NSDecimalNumberBehaviors>

@end

@implementation OLDecimalNumberBehavior

- (NSRoundingMode)roundingMode{
    return NSRoundPlain;
}

- (short)scale{
    return 2;
}

- (NSDecimalNumber *)exceptionDuringOperation:(SEL)operation error:(NSCalculationError)error leftOperand:(NSDecimalNumber *)leftOperand rightOperand:(NSDecimalNumber *)rightOperand{
    if (error != NSCalculationDivideByZero){
        return nil;
    }
    else{
        NSException* exception = [NSException
                                    exceptionWithName:@"DivideByZeroException"
                                    reason:@"Attempted to divide a number by zero."
                                    userInfo:nil];
        @throw exception;
    }
}

@end

@implementation OLPaymentLineItemPercentage

- (NSDecimalNumber *)price{
    if (self.printJob && self.currencyCode){
        NSDecimalNumber *decimal = [self.value decimalNumberByMultiplyingBy:[self.printJob costInCurrency:self.currencyCode]];
        return [decimal decimalNumberByRoundingAccordingToBehavior:[[OLDecimalNumberBehavior alloc] init]];
    }
    else{
        return [super price];
    }
}

#pragma mark - NSCoding protocol methods

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.printJob forKey:kKeyLineItemJob];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        self.printJob = [aDecoder decodeObjectForKey:kKeyLineItemJob];
    }
    
    return self;
}

@end
