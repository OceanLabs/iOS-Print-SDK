//
//  OLPrintPostcardRequest.h
//  PS SDK
//
//  Created by Deon Botha on 28/12/2013.
//  Copyright (c) 2013 Deon Botha. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OLPrintOrder;
@class OLPrintOrderRequest;

@protocol OLPrintOrderRequestDelegate <NSObject>
- (void)printOrderRequest:(OLPrintOrderRequest *)req didSucceedWithOrderReceiptId:(NSString *)receipt;
- (void)printOrderRequest:(OLPrintOrderRequest *)req didFailWithError:(NSError *)error;
@end

@interface OLPrintOrderRequest : NSObject
- (id)initWithPrintOrder:(OLPrintOrder *)printOrder;
- (void)submitForPrinting;
- (void)cancelSubmissionForPrinting;

@property (nonatomic, weak) id<OLPrintOrderRequestDelegate> delegate;
@end
