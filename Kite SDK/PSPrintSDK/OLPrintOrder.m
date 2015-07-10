//
//  OLPrintOrder.m
//  Kite SDK
//
//  Created by Deon Botha on 30/12/2013.
//  Copyright (c) 2013 Deon Botha. All rights reserved.
//

#import "OLPrintOrder.h"
#import "OLPrintJob.h"
#import "OLAssetUploadRequest.h"
#import "OLPrintOrderRequest.h"
#import "OLAsset.h"
#import "OLAddress.h"
#import "OLCountry.h"
#import "OLAsset+Private.h"
#import "OLPaymentLineItem.h"
#import "OLKitePrintSDK.h"
#import "OLPrintOrderCostRequest.h"
#import "OLPrintOrderCost.h"

static NSString *const kKeyProofOfPayment = @"co.oceanlabs.pssdk.kKeyProofOfPayment";
static NSString *const kKeyVoucherCode = @"co.oceanlabs.pssdk.kKeyVoucherCode";
static NSString *const kKeyJobs = @"co.oceanlabs.pssdk.kKeyJobs";
static NSString *const kKeyFinalCost = @"co.oceanlabs.pssdk.kKeyFinalCost";
static NSString *const kKeyReceipt = @"co.oceanlabs.pssdk.kKeyReceipt";
static NSString *const kKeyStorageIdentifier = @"co.oceanlabs.pssdk.kKeyStorageIdentifier";
static NSString *const kKeyUserData = @"co.oceanlabs.pssdk.kKeyUserData";
static NSString *const kKeyShippingAddress = @"co.oceanlabs.pssdk.kKeyShippingAddress";
static NSString *const kKeyLastPrintError = @"co.oceanlabs.pssdk.kKeyLastPrintError";
static NSString *const kKeyLastPrintSubmissionDate = @"co.oceanlabs.pssdk.kKeyLastPrintSubmissionDate";
static NSString *const kKeyCurrencyCode = @"co.oceanlabs.pssdk.kKeyCurrencyCode";

static NSMutableArray *inProgressPrintOrders; // Tracks all currently in progress print orders. This is useful as it means they won't be dealloc'd if a user doesn't come a strong reference to them but still expects the completion handler callback

static id stringOrEmptyString(NSString *str) {
    return str ? str : @"";
}

@interface OLPrintOrderCostRequest (Private)
+ (NSDictionary *)cachedResponseForOrder:(OLPrintOrder *)order;
@end

@interface OLPrintOrder () <OLAssetUploadRequestDelegate, OLPrintOrderRequestDelegate>
@property (nonatomic, copy) OLPrintOrderProgressHandler progressHandler;
@property (nonatomic, copy) OLPrintOrderCompletionHandler completionHandler;
@property (nonatomic, strong) OLAssetUploadRequest *assetUploadReq;
@property (nonatomic, strong) OLPrintOrderRequest *printOrderReq;
@property (nonatomic, readonly) NSDictionary *jsonRepresentation;

@property (nonatomic, strong) NSMutableArray/*<OLAsset>*/ *assetsToUpload;
@property (nonatomic, assign, getter = isAssetUploadComplete) BOOL assetUploadComplete;

@property (nonatomic, assign) NSInteger storageIdentifier;
@property (nonatomic, assign) BOOL userSubmittedForPrinting;
@property (nonatomic, assign) NSUInteger totalBytesWritten, totalBytesExpectedToWrite;

@property (strong, nonatomic) OLPrintOrderCost *cachedCost;
@property (strong, nonatomic) OLPrintOrderCost *finalCost;
@property (nonatomic, strong) OLPrintOrderCostRequest *costReq;
@property (strong, nonatomic) NSMutableArray *costCompletionHandlers;

@end

@implementation OLPrintOrder

+ (void)initialize {
    if (!inProgressPrintOrders) {
        inProgressPrintOrders = [[NSMutableArray alloc] init];
    }
}

+ (OLPrintOrder *)submitJob:(id<OLPrintJob>)job withProofOfPayment:(NSString *)proofOfPayment forPrintingWithProgressHandler:(OLPrintOrderProgressHandler)progressHandler completionHandler:(OLPrintOrderCompletionHandler)completionHandler {
    OLPrintOrder *printOrder = [[OLPrintOrder alloc] init];
    [printOrder addPrintJob:job];
    printOrder.proofOfPayment = proofOfPayment;
    [printOrder submitForPrintingWithProgressHandler:progressHandler completionHandler:completionHandler];
    return printOrder;
}

- (id)init {
    if (self = [super init]) {
        _jobs = [[NSMutableArray alloc] init];
        _storageIdentifier = NSNotFound;
    }
    
    return self;
}

- (void)setPromoCode:(NSString *)promoCode{
    _promoCode = promoCode;
}

- (NSString *)paymentDescription {
    NSString *description = [(id<OLPrintJob>)[self.jobs firstObject] productName];
    if (self.jobs.count > 1){
        description = [description stringByAppendingString:@" & More"];
    }
    
    if (description == nil) {
        description = @"";
    }
    
    return description;
}

- (BOOL)printed {
    return self.receipt != nil;
}

- (BOOL)isAssetUploadInProgress {
    // There may be a brief window where assetUploadReq == nil whilst we asynchronously collect info about the assets
    // to upload. assetsToUpload will be non nil whilst this is happening.
    return self.assetsToUpload != nil || self.assetUploadReq != nil;
}

- (void)setUserData:(NSDictionary *)userData {
    NSAssert([NSJSONSerialization isValidJSONObject:userData], @"Only valid JSON structures are accepted as user data");
    _userData = userData;
}

- (NSArray *)currenciesSupported {
    NSMutableSet *supported = [[NSMutableSet alloc] init];
    NSUInteger i = 0;
    for (id<OLPrintJob> job in self.jobs) {
        if (i++ == 0) {
            [supported addObjectsFromArray:job.currenciesSupported];
        } else {
            [supported intersectSet:[NSSet setWithArray:job.currenciesSupported]];
        }
    }
    return [supported allObjects];
}

- (NSString *)currencyCode {
    NSString *code = _currencyCode ? _currencyCode : [OLCountry countryForCurrentLocale].currencyCode;
    if ([self.currenciesSupported containsObject:code]) {
        return code;
    }
    
    if ([self.currenciesSupported containsObject:@"USD"]) {
        return @"USD";
    }
    
    if ([self.currenciesSupported containsObject:@"GBP"]) {
        return @"GBP";
    }
    
    if ([self.currenciesSupported containsObject:@"EUR"]) {
        return @"EUR";
    }
    
    NSAssert(self.currenciesSupported.count > 0, @"currenciesSupported.count == 0. There are %lu jobs that are part of this order", (unsigned long) self.jobs.count);
    code = self.currenciesSupported[0]; // return the first currency supported if the user hasn't specified one explicitly
    NSAssert(code != nil, @"Please ensure all OLPrintJobs making up a print order have at least one supported currency in common");
    return code;
}

- (void)addPrintJob:(id<OLPrintJob>)job {
    [(NSMutableArray *) self.jobs addObject:job];
}

- (void)removePrintJob:(id<OLPrintJob>)job {
    [(NSMutableArray *) self.jobs removeObject:job];
}

- (BOOL)hasCachedCost {
    if (self.finalCost) {
        return YES;
    }
    
    return [OLPrintOrderCostRequest cachedResponseForOrder:self] != nil;
}

- (void)costWithCompletionHandler:(OLPrintOrderCostCompletionHandler)handler {
    if (self.finalCost) {
        if (handler) {
            handler(self.finalCost, nil);
        }
        return;
    }
    
    if (handler && !self.costCompletionHandlers) {
        self.costCompletionHandlers = [[NSMutableArray alloc] init];
    }
    
    if (handler) {
        [self.costCompletionHandlers addObject:handler];
    }
    
    if (self.costReq != nil) {
        return; // request already in progress. 
    }
    
    self.costReq = [[OLPrintOrderCostRequest alloc] init];
    [self.costReq orderCost:self completionHandler:^(OLPrintOrderCost *cost, NSError *error) {
        self.costReq = nil;
        self.cachedCost = cost;
        
        NSArray *handlers = [self.costCompletionHandlers copy];
        [self.costCompletionHandlers removeAllObjects];
        for (OLPrintOrderCostCompletionHandler handler in handlers) {
            handler(cost, error);
        }
    }];
}

- (void)cancelSubmissionOrPreemptedAssetUpload {
    [self.assetUploadReq cancelUpload];
    [self.printOrderReq cancelSubmissionForPrinting];
    self.assetUploadReq = nil;
    self.printOrderReq = nil;
    self.userSubmittedForPrinting = NO;
    [inProgressPrintOrders removeObject:self];
}

- (NSMutableArray *)getAssetsForUploading {
    NSMutableArray *assets = [[NSMutableArray alloc] init];
    for (id<OLPrintJob> job in self.jobs) {
        for (id asset in job.assetsForUploading) {
            NSAssert([asset isKindOfClass:[OLAsset class]], @"OLPrintJob assetsForUploading should only contain OLAsset objects i.e. no %@ allowed", [asset class]);
            // only upload unique images, it would be redundant to upload
            // duplicates that are spread across different print jobs.
            if (![assets containsObject:asset]) {
                [assets addObject:asset];
            }
        }
    }
    
    return assets;
}

- (NSUInteger)totalAssetsToUpload {
    return [self getAssetsForUploading].count;
}

- (void)submitForPrintingWithCompletionHandler:(OLPrintOrderCompletionHandler)completionHandler {
    [self submitForPrintingWithProgressHandler:^(NSUInteger totalAssetsUploaded, NSUInteger totalAssetsToUpload, long long totalAssetBytesWritten, long long totalAssetBytesExpectedToWrite, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        // null progress handler
    } completionHandler:completionHandler];
}

- (void)submitForPrintingWithProgressHandler:(OLPrintOrderProgressHandler)progressHandler completionHandler:(OLPrintOrderCompletionHandler)completionHandler {
    // NSComparisonResult result = [self.cost compare:[NSDecimalNumber zero]];
    NSAssert(!self.userSubmittedForPrinting, @"A PrintOrder can only be submitted once unless you cancel the previous submission");
    // NSAssert(self.proofOfPayment || result == NSOrderedAscending || result == NSOrderedSame, @"You must provide a proofOfPayment before you can submit a print order that costs money");
    NSAssert(self.printOrderReq == nil, @"A PrintOrder request should not already be in progress");
    [inProgressPrintOrders addObject:self];
    
    _lastPrintSubmissionDate = [NSDate date];
    self.progressHandler = progressHandler;
    self.completionHandler = completionHandler;
    
    self.userSubmittedForPrinting = YES;
    if ([self isAssetUploadComplete]) {
        [self submitForPrinting];
    } else if (![self isAssetUploadInProgress]) {
        [self startAssetUpload];
    }
}

- (void)submitForPrinting {
    NSAssert(self.userSubmittedForPrinting, @"oops");
    NSAssert([self isAssetUploadComplete] && ![self isAssetUploadInProgress], @"Oops asset upload should be complete by now");
    // Step 2: Submit print order to the server. Print Job JSON can now reference real asset ids.
    
    self.printOrderReq = [[OLPrintOrderRequest alloc] initWithPrintOrder:self];
    self.printOrderReq.delegate = self;
    [self.printOrderReq submitForPrinting];
}

- (void)preemptAssetUpload {
    if ([self isAssetUploadInProgress] || [self isAssetUploadComplete]) {
        return;
    }
    
    [self startAssetUpload];
}

- (void)startAssetUpload {
    NSAssert(![self isAssetUploadInProgress] && ![self isAssetUploadComplete], @"Oops asset upload should not have previously been started");
    self.assetsToUpload = [self getAssetsForUploading];
    
    // calc total upload size, after we know this kick off the asset upload
    self.totalBytesWritten = 0;
    self.totalBytesExpectedToWrite = 0;
    __block NSUInteger outstandingLengthCallbacks = self.assetsToUpload.count;
    __block NSError *previousError = nil;
    for (OLAsset *asset in self.assetsToUpload) {        
        [asset dataLengthWithCompletionHandler:^(long long dataLength, NSError *error) {
            if (previousError) {
                return;
            }
            
            if (error) {
                previousError = error;
                [self assetUploadRequest:nil didFailWithError:error];
                return;
            }
            
            self.totalBytesExpectedToWrite += (NSUInteger) dataLength;
            if (--outstandingLengthCallbacks == 0) {
                // kick off the asset upload as we now know the total upload size
                self.assetUploadReq = [[OLAssetUploadRequest alloc] init];
                self.assetUploadReq.delegate = self;
                [self.assetUploadReq uploadOLAssets:self.assetsToUpload];
            }
        }];
    }
}

- (void)setProofOfPayment:(NSString *)proofOfPayment {
    _proofOfPayment = proofOfPayment;
    if (proofOfPayment) {
        NSAssert([proofOfPayment hasPrefix:@"AP-"] || [proofOfPayment hasPrefix:@"PAY-"] || [proofOfPayment hasPrefix:@"tok_"]
                 || [proofOfPayment hasPrefix:@"J-"], @"Proof of payment must be a PayPal REST payment confirmation id or a PayPal Adaptive Payment pay key or JudoPay receiptId i.e. PAY-..., AP-... or J-");
    }
}

- (NSDictionary *)jsonRepresentation {
    NSMutableDictionary *json = [[NSMutableDictionary alloc] init];

    if (self.proofOfPayment) {
        [json setObject:self.proofOfPayment forKey:@"proof_of_payment"];
    }
    
    if (self.currencyCode && self.cachedCost) {
        [json setObject:@{@"currency": self.currencyCode, @"amount" : [self.cachedCost totalCostInCurrency:self.currencyCode]} forKey:@"customer_payment"];
    }
    
    if (self.promoCode) {
        [json setObject:[self promoCode] forKey:@"promo_code"];
    }
    
    NSMutableArray *jobs = [[NSMutableArray alloc] init];
    [json setObject:jobs forKey:@"jobs"];
    if (self.userData) {
        [json setObject:self.userData forKey:@"user_data"];
    }

    for (id<OLPrintJob> printJob in self.jobs) {
        [jobs addObject:[printJob jsonRepresentation]];
    }
    
    
    if (self.shippingAddresses.count > 0) {
        NSMutableArray *addresses = [[NSMutableArray alloc] init];
        for (OLAddress *address in self.shippingAddresses){
            NSDictionary *shippingAddress = @{@"recipient_name": stringOrEmptyString(address.recipientName),
                                              @"address_line_1": stringOrEmptyString(address.line1),
                                              @"address_line_2": stringOrEmptyString(address.line2),
                                              @"city": stringOrEmptyString(address.city),
                                              @"county_state": stringOrEmptyString(address.stateOrCounty),
                                              @"postcode": stringOrEmptyString(address.zipOrPostcode),
                                              @"country_code": stringOrEmptyString(address.country.codeAlpha3)
                                              };
            [addresses addObject:shippingAddress];
        }
        [json setObject:addresses forKey:@"shipping_addresses"];
    }
    
    return json;
}

- (NSUInteger) hash {
    NSUInteger hash = 17;
    for (id<OLPrintJob> job in self.jobs){
        hash = 31 * hash + [job hash];
    }
    
    NSMutableArray *countries = [[NSMutableArray alloc] init];
    for (OLAddress *address in self.shippingAddresses){
        [countries addObject:address.country];
    }
    if (countries.count == 0){
        [countries addObject:[OLCountry countryForCurrentLocale]];
    }
    
    // shipping address country can change delivery costs
    for (OLCountry *country in countries){
        hash = 31 * hash + [country.codeAlpha3 hash];
    }
    hash = 31 * hash + [self.promoCode hash];
    return hash;
}

#pragma mark - OLAssetUploadRequestDelegate methods

- (void)assetUploadRequest:(OLAssetUploadRequest *)req didProgressWithTotalAssetsUploaded:(NSUInteger)totalAssetsUploaded totalAssetsToUpload:(NSUInteger)totalAssetsToUpload bytesWritten:(long long)bytesWritten totalAssetBytesWritten:(long long)totalAssetBytesWritten totalAssetBytesExpectedToWrite:(long long)totalAssetBytesExpectedToWrite {
    self.totalBytesWritten += (NSUInteger) bytesWritten;
    if (self.userSubmittedForPrinting) {
        self.progressHandler(totalAssetsUploaded, totalAssetsToUpload, totalAssetBytesWritten, totalAssetBytesExpectedToWrite, self.totalBytesWritten, self.totalBytesExpectedToWrite);
    }
}

- (void)assetUploadRequest:(OLAssetUploadRequest *)req didSucceedWithAssets:(NSArray/*<OLAsset>*/ *)assets {
    NSAssert(self.assetsToUpload.count == assets.count, @"Oops there should be a 1:1 relationship between uploaded assets and submitted, currently its: %lu:%lu", (unsigned long) self.assetsToUpload.count, (unsigned long) assets.count);
    for (OLAsset *asset in assets) {
        NSAssert([self.assetsToUpload containsObject:asset], @"oops");
    }
    
    // make sure all job assets have asset ids & preview urls. We need to do this because we optimize the asset upload to avoid uploading
    // assets that are considered to have duplicate contents
    for (id<OLPrintJob> job in self.jobs) {
        for (OLAsset *uploadedAsset in assets) {
            for (OLAsset *jobAsset in job.assetsForUploading) {
                if (uploadedAsset != jobAsset && [uploadedAsset isEqual:jobAsset]) {
                    [jobAsset setUploadedWithAssetId:uploadedAsset.assetId previewURL:uploadedAsset.previewURL];
                }
            }
        }
    }
    
    // sanity check all assets are uploaded
    for (id<OLPrintJob> job in self.jobs) {
        for (OLAsset *jobAsset in job.assetsForUploading) {
            BOOL isUploaded = jobAsset.isUploaded;
            NSAssert(isUploaded, @"oops all assets should have been uploaded");
        }
    }
    
    self.assetUploadComplete = YES;
    self.assetsToUpload = nil;
    self.assetUploadReq = nil;
    
    if (self.userSubmittedForPrinting) {
        [self submitForPrinting];
    }
}

- (void)assetUploadRequest:(OLAssetUploadRequest *)req didFailWithError:(NSError *)error {
    self.assetUploadReq = nil;
    self.assetsToUpload = nil;
    if (self.userSubmittedForPrinting) {
        self.userSubmittedForPrinting = NO; // allow the user to resubmit for printing
        [inProgressPrintOrders removeObject:self];
        self.completionHandler(nil, error);
    }
}

#pragma mark - OLPrintOrderRequestDelegate methods

- (void)printOrderRequest:(OLPrintOrderRequest *)req didSucceedWithOrderReceiptId:(NSString *)receipt {
    self.printOrderReq = nil;
    [inProgressPrintOrders removeObject:self];
    _receipt = receipt;
    self.finalCost = self.cachedCost;
    self.completionHandler(receipt, nil);
}

- (void)printOrderRequest:(OLPrintOrderRequest *)req didFailWithError:(NSError *)error {
    self.printOrderReq = nil;
    self.userSubmittedForPrinting = NO; // allow the user to resubmit for printing
    [inProgressPrintOrders removeObject:self];
    _lastPrintSubmissionError = error;
    self.completionHandler(nil, error);
}

#pragma mark - NSCoding protocol

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.proofOfPayment forKey:kKeyProofOfPayment];
    [aCoder encodeObject:self.promoCode forKey:kKeyVoucherCode];
    [aCoder encodeObject:self.jobs forKey:kKeyJobs];
    [aCoder encodeObject:self.receipt forKey:kKeyReceipt];
    [aCoder encodeInteger:self.storageIdentifier forKey:kKeyStorageIdentifier];
    [aCoder encodeObject:self.userData forKey:kKeyUserData];
    [aCoder encodeObject:self.shippingAddresses forKey:kKeyShippingAddress];
    [aCoder encodeObject:self.lastPrintSubmissionError forKey:kKeyLastPrintError];
    [aCoder encodeObject:self.lastPrintSubmissionDate forKey:kKeyLastPrintSubmissionDate];
    [aCoder encodeObject:_currencyCode forKey:kKeyCurrencyCode];
    [aCoder encodeObject:self.finalCost forKey:kKeyFinalCost];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    @try {
        if (self = [self init]) {
            _proofOfPayment = [aDecoder decodeObjectForKey:kKeyProofOfPayment];
            _promoCode = [aDecoder decodeObjectForKey:kKeyVoucherCode];
            _jobs = [aDecoder decodeObjectForKey:kKeyJobs];
            _receipt = [aDecoder decodeObjectForKey:kKeyReceipt];
            _storageIdentifier = [aDecoder decodeIntegerForKey:kKeyStorageIdentifier];
            _userData = [aDecoder decodeObjectForKey:kKeyUserData];
            _shippingAddresses = [aDecoder decodeObjectForKey:kKeyShippingAddress];
            _lastPrintSubmissionError = [aDecoder decodeObjectForKey:kKeyLastPrintError];
            _lastPrintSubmissionDate = [aDecoder decodeObjectForKey:kKeyLastPrintSubmissionDate];
            _currencyCode = [aDecoder decodeObjectForKey:kKeyCurrencyCode];
            _finalCost = [aDecoder decodeObjectForKey:kKeyFinalCost];
        }
        return self;
        
    }
    @catch (NSException *exception) {
        return nil;
    }
}

@end
