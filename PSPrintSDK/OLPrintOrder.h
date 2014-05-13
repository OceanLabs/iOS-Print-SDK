//
//  OLPrintOrder.h
//  Kite SDK
//
//  Created by Deon Botha on 30/12/2013.
//  Copyright (c) 2013 Deon Botha. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OLAddress;

@protocol OLPrintJob;

typedef void (^OLPrintOrderProgressHandler)(NSUInteger totalAssetsUploaded, NSUInteger totalAssetsToUpload, long long totalAssetBytesWritten, long long totalAssetBytesExpectedToWrite, long long totalBytesWritten, long long totalBytesExpectedToWrite);
typedef void (^OLPrintOrderCompletionHandler)(NSString *orderIdReceipt, NSError *error);

typedef void (^OLApplyPromoCodeCompletionHandler)(NSDecimalNumber *discount, NSError *error);

@interface OLPrintOrder : NSObject <NSCoding>

+ (OLPrintOrder *)submitJob:(id<OLPrintJob>)job withProofOfPayment:(NSString *)proofOfPayment forPrintingWithProgressHandler:(OLPrintOrderProgressHandler)progressHandler completionHandler:(OLPrintOrderCompletionHandler)completionHandler;

- (void)addPrintJob:(id<OLPrintJob>)job;
- (void)removePrintJob:(id<OLPrintJob>)job;
- (void)submitForPrintingWithCompletionHandler:(OLPrintOrderCompletionHandler)completionHandler;
- (void)submitForPrintingWithProgressHandler:(OLPrintOrderProgressHandler)progressHandler completionHandler:(OLPrintOrderCompletionHandler)completionHandler;
- (void)cancelSubmissionOrPreemptedAssetUpload; // cancels both preempted asset upload and submission for printing

/*
 * Preempting asset upload kicks off the asset upload process early before the print order has even been submited to the system for processing. This incurs no cost
 * to you and allows for a speedier checkout process as it gives the option to begin the asset uploading whilst the user is still filling out details.
 */
- (void)preemptAssetUpload;

- (void)applyPromoCode:(NSString *)promoCode withCompletionHandler:(OLApplyPromoCodeCompletionHandler)handler;
- (void)clearPromoCode;

@property (nonatomic, strong) OLAddress *shippingAddress;
@property (nonatomic, strong) NSString *proofOfPayment;
@property (nonatomic, readonly) NSString *promoCode;
@property (nonatomic, readonly) NSDecimalNumber *promoDiscount;

@property (nonatomic, readonly) NSArray *jobs;
@property (nonatomic, readonly) NSUInteger totalAssetsToUpload;

@property (nonatomic, readonly) BOOL printed; // YES if submission for printing was successful and receipt will be non nil.
@property (nonatomic, readonly) NSDate *lastPrintSubmissionDate;
@property (nonatomic, readonly) NSError *lastPrintSubmissionError;
@property (nonatomic, readonly) NSString *receipt;

@property (nonatomic, strong) NSDictionary *userData;

@property (nonatomic, readonly) NSArray *currenciesSupported;
@property (nonatomic, copy) NSString *currencyCode;
@property (nonatomic, readonly) NSDecimalNumber *cost;

- (NSDecimalNumber *)costInCurrency:(NSString *)currencyCode;

@end
