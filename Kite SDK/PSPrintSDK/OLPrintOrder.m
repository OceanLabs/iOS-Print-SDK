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
#import "OLCheckPromoCodeRequest.h"
#import "OLPaymentLineItem.h"
#import "OLKitePrintSDK.h"
#import "OLBaseRequest.h"
#import "OLProductPrintJob.h"

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

@property (nonatomic, strong) OLBaseRequest *req;
@property (strong, nonatomic) NSDictionary *cachedCostResponse;
@property (strong, nonatomic) NSDictionary *finalCost;

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

- (NSDictionary *)cachedCostResponse{
    if (self.finalCost){
        return self.finalCost;
    }
    if (!_cachedCostResponse){
        return nil;
    }
    
    NSDate *cacheDate = _cachedCostResponse[@"cacheDate"];
    NSTimeInterval elapsedSecondsSinceLastCache = -[cacheDate timeIntervalSinceNow];
    if (elapsedSecondsSinceLastCache > (60 * 60)) { // if > 1hr has passed since last successful sync then cache is invalid
        _cachedCostResponse = nil;
    }
    if (![_cachedCostResponse[@"orderHash"] isEqualToString:[NSString stringWithFormat:@"%lu", [self hash]]]){
        _cachedCostResponse = nil;
    }
    
    return _cachedCostResponse[@"response"];
}

- (void) cacheCostResponse:(NSDictionary *)json forHash:(NSUInteger) hash{
    self.cachedCostResponse = @{@"cacheDate" : [NSDate date], @"orderHash" : [NSString stringWithFormat:@"%lu", hash], @"response" : json};
}

- (void)invalidateCachedCost{
    self.cachedCostResponse = nil;
}

- (NSArray *)cachedLineItems{
    return [self cachedLineItemsForCurrency:self.currencyCode];
}

- (NSArray *)cachedLineItemsForCurrency:(NSString *)currencyCode{
    if (self.cachedCostResponse){
        return [self lineItemsFromArray:self.cachedCostResponse forCurrency:currencyCode];
    }
    else{
        return nil;
    }
}

- (NSString *)paymentDescription {
    NSString *description = [(id<OLPrintJob>)[self.jobs firstObject] productName];
    if (self.jobs.count > 1){
        description = [description stringByAppendingString:@"& More"];
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

- (NSString *)orderStringParameter{
    NSString *basketString = @"";
    for (id<OLPrintJob> job in self.jobs){
        basketString = [basketString stringByAppendingString:[NSString stringWithFormat:@"%@:%d,", [job templateId], (int)[job quantity]]];
    }
    basketString = [basketString stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@","]];
    
    NSDictionary *dict = @{@"basket" : basketString,
                           @"shipping_country_code" : self.shippingAddress.country ? [self.shippingAddress.country codeAlpha3] : [[OLCountry countryForCurrentLocale] codeAlpha3],
                           @"promo_code" : self.promoCode ? self.promoCode : @""
                           };
    
    NSString *orderString = @"";
    for (NSString *key in [dict allKeys]){
        orderString = [orderString stringByAppendingString:[NSString stringWithFormat:@"%@=%@&", key, [dict objectForKey:key]]];
    }
    orderString = [orderString stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"&"]];
    return orderString;
}

- (NSArray *)lineItemsFromArray:(NSDictionary *)json forCurrency:(NSString *)currencyCode{
    NSMutableArray *lineItems = [[NSMutableArray alloc] init];
    NSInteger idx = 0;
    for (NSDictionary *lineItemDict in json[@"line_items"]){
        OLPaymentLineItem * item = [[OLPaymentLineItem alloc] init];
        item.cost = [NSDecimalNumber decimalNumberWithDecimal: [lineItemDict[@"product_cost"][currencyCode] decimalValue]];
        item.name = [OLProductTemplate templateWithId:lineItemDict[@"template_id"]].name;
        [lineItems addObject:item];
        
        idx++;
    }
    
    NSDecimalNumber *discount = [NSDecimalNumber decimalNumberWithDecimal: [json[@"discount"][currencyCode] decimalValue]];
    if ([discount doubleValue] != 0){
        OLPaymentLineItem *discountItem = [[OLPaymentLineItem alloc] init];
        discountItem.cost = [discount decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:@"-1"]];
        discountItem.name = NSLocalizedString(@"Discount", @"");
        [lineItems addObject:discountItem];
    }
    
    NSDecimalNumber *shippingNumber = [NSDecimalNumber decimalNumberWithDecimal: [json[@"total_shipping_cost"][currencyCode] decimalValue]];
    OLPaymentLineItem *shippingItem = [[OLPaymentLineItem alloc] init];
    shippingItem.name = NSLocalizedString(@"Shipping", @"");
    shippingItem.cost = shippingNumber;
    [lineItems addObject:shippingItem];
    
    return lineItems;
}

- (void)parseCostResponseJson:(NSDictionary *)json withCompletionHandler:(OLPrintOrderCostCompletionHandler)handler{
    [self parseCostResponseJson:json forCurrency:self.currencyCode withCompletionHandler:handler];
}

- (void)parseCostResponseJson:(NSDictionary *)json forCurrency:(NSString *)currencyCode withCompletionHandler:(OLPrintOrderCostCompletionHandler)handler{
    NSMutableArray *lineItems = [[NSMutableArray alloc] init];
    NSMutableDictionary *jobCosts = [[NSMutableDictionary alloc] init];
    NSInteger idx = 0;
    for (NSDictionary *lineItemDict in json[@"line_items"]){
        OLPaymentLineItem * item = [[OLPaymentLineItem alloc] init];
        item.cost = [NSDecimalNumber decimalNumberWithDecimal: [lineItemDict[@"product_cost"][currencyCode] decimalValue]];
        item.currencyCode = currencyCode;
        
        OLProductPrintJob *job = self.jobs[idx];
        item.name = [NSString stringWithFormat:@"%lu x %@", (unsigned long)job.quantity, job.productName];
        OLProductTemplate *template = [OLProductTemplate templateWithId:job.templateId];
        if ([job.templateId isEqualToString:@"ps_postcard"] || [job.templateId isEqualToString:@"60_postcards"]) {
            item.name = [NSString stringWithFormat:@"%@", job.productName];
        } else if (template.templateUI == kOLTemplateUIFrame || template.templateUI == kOLTemplateUIPoster || template.templateUI == kOLTemplateUICase || template.templateUI == kOLTemplateUIPhotobook) {
            item.name = [NSString stringWithFormat:@"%lu x %@", (unsigned long) (job.quantity + template.quantityPerSheet - 1 ) / template.quantityPerSheet, job.productName];
        }
        else {
            item.name = [NSString stringWithFormat:@"Pack of %lu %@", (unsigned long)job.quantity, job.productName];
        }
        
        [lineItems addObject:item];
        
        [jobCosts setObject:@{@"product_cost" : lineItemDict[@"product_cost"][currencyCode], @"shipping_cost" : lineItemDict[@"shipping_cost"][currencyCode]} forKey:job];
        idx++;
    }
    NSDecimalNumber *totalNumber = [NSDecimalNumber decimalNumberWithDecimal: [json[@"total"][currencyCode]  decimalValue]];
    
    NSDecimalNumber *discount = json[@"discount"][currencyCode];
    if ([discount doubleValue] != 0){
        OLPaymentLineItem *discountItem = [[OLPaymentLineItem alloc] init];
        discountItem.cost = [[NSDecimalNumber decimalNumberWithDecimal:[discount decimalValue]] decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:@"-1"]];
        discountItem.name = NSLocalizedString(@"Discount", @"");
        discountItem.currencyCode = currencyCode;
        [lineItems addObject:discountItem];
    }
    
    NSDecimalNumber *shippingNumber = [NSDecimalNumber decimalNumberWithDecimal: [json[@"total_shipping_cost"][currencyCode] decimalValue]];
    OLPaymentLineItem *shippingItem = [[OLPaymentLineItem alloc] init];
    shippingItem.name = NSLocalizedString(@"Shipping", @"");
    shippingItem.cost = shippingNumber;
    shippingItem.currencyCode = currencyCode;
    [lineItems addObject:shippingItem];
    
    handler(totalNumber, shippingNumber, lineItems, jobCosts, nil);
}

- (OLBaseRequest *)costWithCompletionHandler:(OLPrintOrderCostCompletionHandler)handler{
    return [self costInCurrency:self.currencyCode completionHandler:handler];
}

- (OLBaseRequest *)costInCurrency:(NSString *)currencyCode completionHandler:(OLPrintOrderCostCompletionHandler)handler{
    NSDictionary *cache = self.cachedCostResponse;
    if (cache){
        NSLog(@"Cost is cached");
        [self parseCostResponseJson:cache forCurrency:currencyCode withCompletionHandler:handler];
        return nil;
    }
    
    NSUInteger hash = [self hash];
    
    NSDictionary *headers = @{@"Authorization": [NSString stringWithFormat:@"ApiKey %@:", [OLKitePrintSDK apiKey]]};
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/price/?%@", [OLKitePrintSDK apiEndpoint], [OLKitePrintSDK apiVersion], [self orderStringParameter]]];
    
    if (self.req){
        handler(nil, nil, nil, nil, [NSError errorWithDomain:kOLKiteSDKErrorDomain code:kOLKiteSDKErrorCodeFullDetailsFetchFailed userInfo:@{NSLocalizedDescriptionKey: kOLKiteSDKErrorMessageUnauthorized}]);
        return nil;
    }
    
    self.req = [[OLBaseRequest alloc] initWithURL:url httpMethod:kOLHTTPMethodGET headers:headers body:nil];
    [self.req startWithCompletionHandler:^(NSInteger httpStatusCode, id json, NSError *error) {
        if (error) {
            
            if (httpStatusCode == 401) {
                // unauthorized
                error = [NSError errorWithDomain:kOLKiteSDKErrorDomain code:kOLKiteSDKErrorCodeUnauthorized userInfo:@{NSLocalizedDescriptionKey: kOLKiteSDKErrorMessageUnauthorized}];
            }
            
            self.req = nil;
            handler(nil, nil, nil, nil, error);
            return;
        }
        
        if (httpStatusCode >= 200 & httpStatusCode <= 299) {
            NSLog(@"Response: %@", json);
            
            if ([self hash] != hash){
                self.req = nil;
                [self costInCurrency:currencyCode completionHandler:handler];
                return;
            }
            [self cacheCostResponse:json forHash: hash];
            self.req = nil;
            [self parseCostResponseJson:json forCurrency:currencyCode withCompletionHandler:handler];
        }
        else {
            id errorObj = json[@"error"];
            if ([errorObj isKindOfClass:[NSDictionary class]]) {
                id errorMessage = errorObj[@"message"];
                if ([errorMessage isKindOfClass:[NSString class]]) {
                    NSError *error = [NSError errorWithDomain:kOLKiteSDKErrorDomain code:kOLKiteSDKErrorCodeServerFault userInfo:@{NSLocalizedDescriptionKey:errorMessage}];
                    self.req = nil;
                    handler(nil, nil, nil, nil, error);
                    return;
                }
            }
            
            self.req = nil;
            handler(nil, nil, nil, nil, [NSError errorWithDomain:kOLKiteSDKErrorDomain code:kOLKiteSDKErrorCodeServerFault userInfo:@{NSLocalizedDescriptionKey: NSLocalizedStringFromTableInBundle(@"Failed to get order price. Please try again.", @"KitePrintSDK", [OLConstants bundle], @"")}]);
        }
    }];
    return self.req;
}

- (void) costIsFinal{
    self.finalCost = self.cachedCostResponse;
}

- (void)addPrintJob:(id<OLPrintJob>)job {
    [(NSMutableArray *) self.jobs addObject:job];
    [self invalidateCachedCost];
}

- (void)removePrintJob:(id<OLPrintJob>)job {
    [(NSMutableArray *) self.jobs removeObject:job];
    [self invalidateCachedCost];
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
    
    if (self.currencyCode && self.cachedCostResponse) {
        [json setObject:@{@"currency" : self.currencyCode, @"amount" : self.cachedCostResponse[@"total"][self.currencyCode]} forKey:@"customer_payment"];
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
    
    if (self.shippingAddress) {
        NSDictionary *shippingAddress = @{@"recipient_name": stringOrEmptyString(self.shippingAddress.recipientName),
                                          @"address_line_1": stringOrEmptyString(self.shippingAddress.line1),
                                          @"address_line_2": stringOrEmptyString(self.shippingAddress.line2),
                                          @"city": stringOrEmptyString(self.shippingAddress.city),
                                          @"county_state": stringOrEmptyString(self.shippingAddress.stateOrCounty),
                                          @"postcode": stringOrEmptyString(self.shippingAddress.zipOrPostcode),
                                          @"country_code": stringOrEmptyString(self.shippingAddress.country.codeAlpha3)
                                          };
        [json setObject:shippingAddress forKey:@"shipping_address"];
    }
    
    return json;
}

- (NSUInteger) hash{
    NSUInteger hash = 1;
    for (id<OLPrintJob> job in self.jobs){
        hash *= [job hash];
    }
    OLCountry *country = self.shippingAddress.country ? self.shippingAddress.country : [OLCountry countryForCurrentLocale];
    hash *= [country.codeAlpha3 hash];
    
    hash *= [self.promoCode hash];
    
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
    [aCoder encodeObject:self.shippingAddress forKey:kKeyShippingAddress];
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
            _shippingAddress = [aDecoder decodeObjectForKey:kKeyShippingAddress];
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
