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
#import "OLProductPrintJob.h"
#import "OLPrintOrderSubmitStatusRequest.h"
#import "OLPaymentViewController.h"
#import "OLKiteUtils.h"

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
static NSString *const kKeyOrderEmail = @"co.oceanlabs.pssdk.kKeyOrderEmail";
static NSString *const kKeyOrderPhone = @"co.oceanlabs.pssdk.kKeyOrderPhone";
static NSString *const kKeyOrderSubmitStatus = @"co.oceanlabs.pssdk.kKeyOrderSubmitStatus";
static NSString *const kKeyOrderSubmitStatusError = @"co.oceanlabs.pssdk.kKeyOrderSubmitStatusError";
static NSString *const kKeyOrderOptOutOfEmail = @"co.oceanlabs.pssdk.kKeyOrderOptOutOfEmail";
static NSString *const kKeyOrderShipToStore = @"co.oceanlabs.pssdk.kKeyOrderShipToStore";
static NSString *const kKeyOrderPayInStore = @"co.oceanlabs.pssdk.kKeyOrderPayInStore";
static NSString *const kKeyOrderPaymentMethod = @"co.oceanlabs.pssdk.kKeyOrderPaymentMethod";

static NSString *const kKeySavedOrderSDKVersion = @"co.oceanlabs.pssdk.kKeySavedOrderSDKVersion";

static NSMutableArray *inProgressPrintOrders; // Tracks all currently in progress print orders. This is useful as it means they won't be dealloc'd if a user doesn't come a strong reference to them but still expects the completion handler callback

static id stringOrEmptyString(NSString *str) {
    return str ? str : @"";
}

@interface OLPrintOrderCostRequest (Private)
+ (NSDictionary *)cachedResponseForOrder:(OLPrintOrder *)order;
@end

@interface OLPrintOrderCost ()
@property (strong, nonatomic) NSString *paymentMethod;
@end

@interface OLKitePrintSDK (Private)
+(BOOL)isUnitTesting;
+ (NSString *)paypalAccountId;
+ (NSString *)stripeAccountId;
@end

@interface OLPrintOrder () <OLAssetUploadRequestDelegate, OLPrintOrderRequestDelegate>
@property (nonatomic, copy) OLPrintOrderProgressHandler progressHandler;
@property (nonatomic, copy) OLPrintOrderCompletionHandler completionHandler;
@property (nonatomic, strong) OLAssetUploadRequest *assetUploadReq;
@property (nonatomic, strong) OLPrintOrderRequest *printOrderReq;
@property (nonatomic, strong) OLPrintOrderSubmitStatusRequest *printOrderSubmitStatusReq;
@property (nonatomic, readonly) NSDictionary *jsonRepresentation;

@property (nonatomic, strong) NSMutableArray<OLAsset *> *assetsToUpload;
@property (nonatomic, assign, getter = isAssetUploadComplete) BOOL assetUploadComplete;

@property (strong, nonatomic, readwrite) NSArray *jobs;

@property (nonatomic, assign) NSInteger storageIdentifier;
@property (nonatomic, assign) BOOL userSubmittedForPrinting;
@property (nonatomic, assign) NSUInteger totalBytesWritten, totalBytesExpectedToWrite;

@property (strong, nonatomic) OLPrintOrderCost *cachedCost;
@property (strong, nonatomic) OLPrintOrderCost *finalCost;
@property (nonatomic, strong) OLPrintOrderCostRequest *costReq;
@property (strong, nonatomic) NSMutableArray *costCompletionHandlers;

@property (assign, nonatomic, readwrite) OLPrintOrderSubmitStatus submitStatus;
@property (strong, nonatomic, readwrite) NSString *submitStatusErrorMessage;
@property (assign, nonatomic) NSInteger numberOfTimesPolledForSubmissionStatus;

@property (strong, nonatomic) NSString *paymentMethod;
@property (nonatomic, readwrite) NSString *receipt;

@property (assign, nonatomic) BOOL optOutOfEmail;
@property (assign, nonatomic) BOOL shipToStore;
@property (assign, nonatomic) BOOL payInStore;

@end

@interface OLProductPrintJob ()
@property (strong, nonatomic) NSMutableSet <OLUpsellOffer *>*declinedOffers;
@property (strong, nonatomic) NSMutableSet <OLUpsellOffer *>*acceptedOffers;
@property (strong, nonatomic) OLUpsellOffer *redeemedOffer;
@end

static NSBlockOperation *templateSyncOperation;

@interface OLAddress ()
@property (strong, nonatomic) NSString *companyName;

@end

@implementation OLPrintOrder

@synthesize userData=_userData;

+ (void)initialize {
    if (!inProgressPrintOrders) {
        inProgressPrintOrders = [[NSMutableArray alloc] init];
    }
}

+ (OLPrintOrderSubmitStatus)submitStatusFromIdentifier:(NSString *)identifier{
    if ([identifier isEqualToString:@"Received"]){
        return OLPrintOrderSubmitStatusReceived;
    }
    else if ([identifier isEqualToString:@"Accepted"]){
        return OLPrintOrderSubmitStatusAccepted;
    }
    else if ([identifier isEqualToString:@"Validated"]){
        return OLPrintOrderSubmitStatusValidated;
    }
    else if ([identifier isEqualToString:@"Processed"]){
        return OLPrintOrderSubmitStatusProcessed;
    }
    else if ([identifier isEqualToString:@"Error"]){
        return OLPrintOrderSubmitStatusError;
    }
    else if ([identifier isEqualToString:@"Cancelled"]){
        return OLPrintOrderSubmitStatusCancelled;
    }
    else{
        return OLPrintOrderSubmitStatusUnknown;
    }
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
    switch (self.submitStatus) {
        case OLPrintOrderSubmitStatusUnknown:
            return self.receipt != nil;
            break;
        case OLPrintOrderSubmitStatusReceived:
            return NO;
            break;
        case OLPrintOrderSubmitStatusAccepted:
            return NO;
            break;
        case OLPrintOrderSubmitStatusValidated:
            return YES;
            break;
        case OLPrintOrderSubmitStatusProcessed:
            return YES;
            break;
            
        default:
            return NO;
            break;
    }
}

- (BOOL)isAssetUploadInProgress {
    // There may be a brief window where assetUploadReq == nil whilst we asynchronously collect info about the assets
    // to upload. assetsToUpload will be non nil whilst this is happening.
    return self.assetsToUpload != nil || self.assetUploadReq != nil;
}

- (void)setUserData:(NSDictionary *)userData {
    if (userData){
        NSAssert([NSJSONSerialization isValidJSONObject:userData], @"Only valid JSON structures are accepted as user data");
    }
    _userData = userData;
}

- (NSDictionary *)userData{
    if ([OLKitePrintSDK isUnitTesting]){
        if (_userData){
            NSMutableDictionary *mutableCopy = [_userData mutableCopy];
            mutableCopy[@"automated_test_order"] = @YES;
            return mutableCopy;
        }
        else{
            return @{@"automated_test_order" : @YES};
        }
    }
    return _userData;
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
    
    if ([self.currenciesSupported firstObject]){
        code = [self.currenciesSupported firstObject]; // return the first currency supported if the user hasn't specified one explicitly
    }
    return code;
}

- (void)addPrintJob:(id<OLPrintJob>)job {
    if (![job dateAddedToBasket]){
        [job setDateAddedToBasket:[NSDate date]];
    }
    
    [(NSMutableArray *) self.jobs addObject:job];
    
    self.jobs = [[self.jobs sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        NSDate *first = [(id<OLPrintJob>)a dateAddedToBasket];
        NSDate *second = [(id<OLPrintJob>)b dateAddedToBasket];
        return [second compare:first];
    }] mutableCopy];
}

- (void)removePrintJob:(id<OLPrintJob>)job {
    NSUInteger index = [self.jobs indexOfObjectIdenticalTo:job];
    if (index == NSNotFound){
        index = [self.jobs indexOfObject:job];
    }
    [(NSMutableArray *)self.jobs removeObjectAtIndex:index];
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
    
    if (![OLProductTemplate lastSyncDate] && !templateSyncOperation){
        templateSyncOperation = [NSBlockOperation blockOperationWithBlock:^{
            templateSyncOperation = nil;
        }];
        [OLProductTemplate syncWithCompletionHandler:^(NSArray *templates, NSError *error){
            if (error){
                if (handler){
                    [self.costCompletionHandlers removeObject:handler];
                    handler(nil, error);
                    [[NSOperationQueue mainQueue] addOperation:templateSyncOperation];
                }
            }
            else{
                [[NSOperationQueue mainQueue] addOperation:templateSyncOperation];
            }
        }];
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
        NSBlockOperation *costResultBlock = [NSBlockOperation blockOperationWithBlock:^{
            self.costReq = nil;
            self.cachedCost = cost;
            
            NSArray *handlers = [self.costCompletionHandlers copy];
            [self.costCompletionHandlers removeAllObjects];
            for (OLPrintOrderCostCompletionHandler handler in handlers) {
                cost.paymentMethod = self.paymentMethod;
                handler(cost, error);
            }
        }];
        if (templateSyncOperation){
            [costResultBlock addDependency:templateSyncOperation];
        }
        [[NSOperationQueue mainQueue] addOperation:costResultBlock];
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
    if (proofOfPayment && ![proofOfPayment isEqualToString:@""]) {
        NSAssert([proofOfPayment hasPrefix:@"AP-"] || [proofOfPayment hasPrefix:@"PAY-"] || [proofOfPayment hasPrefix:@"tok_"] || [proofOfPayment hasPrefix:@"PAUTH-"], @"Proof of payment must be a PayPal REST payment confirmation id or a PayPal Adaptive Payment pay key i.e. PAY-..., AP-... or J-");
    }
}

- (NSDictionary *)jsonRepresentation {
    NSMutableDictionary *json = [[NSMutableDictionary alloc] init];
    
    if (self.proofOfPayment) {
        [json setObject:self.proofOfPayment forKey:@"proof_of_payment"];
        
        if ([self.proofOfPayment hasPrefix:@"AP-"] || [self.proofOfPayment hasPrefix:@"PAY-"] || [self.proofOfPayment hasPrefix:@"PAUTH-"]){
            json[@"payment_account_id"] = stringOrEmptyString([OLKitePrintSDK paypalAccountId]);
        }
        else if ([self.proofOfPayment hasPrefix:@"tok_"]){
            json[@"payment_account_id"] = stringOrEmptyString([OLKitePrintSDK stripeAccountId]);
        }
    }
    
    if (self.currencyCode && (self.cachedCost || self.finalCost)) {
        OLPrintOrderCost *cost = self.cachedCost ? self.cachedCost : self.finalCost;
        [json setObject:@{@"currency": self.currencyCode, @"amount" : [cost totalCostInCurrency:self.currencyCode]} forKey:@"customer_payment"];
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
        [jobs addObject:[[printJob jsonRepresentation] mutableCopy]];
    }
    
    if (self.phone){
        [json setObject:self.phone forKey:@"customer_phone"];
    }
    if (self.email){
        [json setObject:self.email forKey:@"customer_email"];
    }
    
    if (self.paymentMethod){
        [json setObject:self.paymentMethod forKey:@"payment_gateway"];
    }
    
    [json setObject:[NSNumber numberWithBool:self.shipToStore] forKey:@"ship_to_store"];
    [json setObject:[NSNumber numberWithBool:self.payInStore] forKey:@"pay_in_store"];
    [json setObject:[NSNumber numberWithBool:self.optOutOfEmail] forKey:@"opt_out_of_emails"];
    
    if (self.shippingAddress) {
        NSDictionary *shippingAddress = @{@"recipient_name": stringOrEmptyString(self.shippingAddress.fullNameFromFirstAndLast),
                                          @"recipient_first_name": stringOrEmptyString(self.shippingAddress.recipientFirstName),
                                          @"recipient_last_name": stringOrEmptyString(self.shippingAddress.recipientLastName),
                                          @"address_line_1": stringOrEmptyString(self.shippingAddress.line1),
                                          @"address_line_2": stringOrEmptyString(self.shippingAddress.line2),
                                          @"city": stringOrEmptyString(self.shippingAddress.city),
                                          @"county_state": stringOrEmptyString(self.shippingAddress.stateOrCounty),
                                          @"postcode": stringOrEmptyString(self.shippingAddress.zipOrPostcode),
                                          @"country_code": stringOrEmptyString(self.shippingAddress.country.codeAlpha3),
                                          @"company_name": stringOrEmptyString(self.shippingAddress.companyName)
                                          };
        [json setObject:shippingAddress forKey:@"shipping_address"];
    }
    
    return json;
}

- (NSUInteger) hash {
    NSUInteger hash = 17;
    for (id<OLPrintJob> job in self.jobs){
        hash = 31 * hash + [job hash];
    }
    
    // shipping address country can change delivery costs
    OLCountry *country = self.shippingAddress.country ? self.shippingAddress.country : [OLCountry countryForCurrentLocale];
    hash = 31 * hash + [country.codeAlpha3 hash];
    hash = 31 * hash + [self.promoCode hash];
    hash = 31 * hash + (self.shipToStore ? 39 : 0);
    hash = 31 * hash + (self.payInStore ? 73 : 0);
    hash = 31 * hash + ([OLKiteUtils isApplePayAvailable] ? 47 : 0);
    for (id<OLPrintJob> job in self.jobs){
        if (job.address.country){
            hash = 32 * hash + [job.address.country.codeAlpha3 hash];
        }
    }
    return hash;
}

- (NSArray <OLAddress *>*)shippingAddressesOfJobs{
    NSMutableArray *addresses = [[NSMutableArray alloc] init];
    for (id<OLPrintJob> job in self.jobs){
        if ([job address]){
            [addresses addObject:[job address]];
        }
    }
    return addresses;
}

+ (NSString *)orderFilePath {
    NSArray * urls = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSString *documentDirPath = [(NSURL *)[urls objectAtIndex:0] path];
    return [documentDirPath stringByAppendingPathComponent:@"ly.kite.sdk.basket"];
}

- (void)saveOrder {
    [NSKeyedArchiver archiveRootObject:self toFile:[OLPrintOrder orderFilePath]];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:kOLKiteSDKVersion forKey:kKeySavedOrderSDKVersion];
}

+ (id)loadOrder {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![[defaults objectForKey:kKeySavedOrderSDKVersion] isEqualToString:kOLKiteSDKVersion]){
        return nil;
    }
    OLPrintOrder *order = [NSKeyedUnarchiver unarchiveObjectWithFile:[OLPrintOrder orderFilePath]];
    return order;
}

- (BOOL)hasOfferIdBeenUsed:(NSUInteger)identifier{
    for (id<OLPrintJob> job in self.jobs){
        if (![job respondsToSelector:@selector(acceptedOffers)]){
            continue;
        }
        OLProductPrintJob *printJob = job;
        for (OLUpsellOffer *acceptedOffer in printJob.acceptedOffers){
            if (acceptedOffer.identifier == identifier){
                return YES;
            }
        }
        for (OLUpsellOffer *declinedOffer in printJob.declinedOffers){
            if (declinedOffer.identifier == identifier){
                return YES;
            }
        }
        if (printJob.redeemedOffer.identifier == identifier){
            return YES;
        }
        
    }
    return NO;
}

- (NSArray<OLShippingClass *> *)shippingMethodsForJobs:(NSArray<id<OLPrintJob>>*)jobs;{
    NSString *countryCode = self.shippingAddress.country ? [self.shippingAddress.country codeAlpha3] : [[OLCountry countryForCurrentLocale] codeAlpha3];
    NSMutableArray *common = [[NSMutableArray alloc] init];
    
    OLProductTemplate *firstJobTemplate = [OLProductTemplate templateWithId:jobs.firstObject.templateId];
    
    NSString *firstJobRegion = firstJobTemplate.countryMapping[countryCode];
    if (!firstJobRegion){
        return common;
    }
    for (OLShippingClass *firstJobShippingClass in firstJobTemplate.shippingClasses[firstJobRegion]){
        BOOL commonInAllJobs = YES;
        for (id<OLPrintJob> job in jobs){
            BOOL foundInJob = NO;
            OLProductTemplate *template = [OLProductTemplate templateWithId:job.templateId];
            NSString *region = template.countryMapping[countryCode];
            if (!region){
                break;
            }
            for(OLShippingClass *shippingClass in template.shippingClasses[region]){
                if ([shippingClass.className isEqualToString:firstJobShippingClass.className]){
                    foundInJob = YES;
                    break;
                }
            }
            commonInAllJobs &= foundInJob;
        }
        if (commonInAllJobs){
            [common addObject:firstJobShippingClass];
        }
    }
    
    return common;
}

- (NSDecimalNumber *)costForShippingMethodName:(NSString *)name forJobs:(NSArray<id<OLPrintJob>>*)jobs;{
    NSString *countryCode = self.shippingAddress.country ? [self.shippingAddress.country codeAlpha3] : [[OLCountry countryForCurrentLocale] codeAlpha3];
    
    NSDecimalNumber *cost = [NSDecimalNumber decimalNumberWithString:@"0"];
    for (id<OLPrintJob> job in self.jobs){
        OLProductTemplate *template = [OLProductTemplate templateWithId:job.templateId];
        NSString *region = template.countryMapping[countryCode];
        if (!region){
            return nil;
        }
        for(OLShippingClass *shippingClass in template.shippingClasses[region]){
            if ([shippingClass.className isEqualToString:name]){
                cost = [cost decimalNumberByAdding:[NSDecimalNumber decimalNumberWithDecimal:[shippingClass.costs[self.currencyCode] decimalValue]]];
                break;
            }
        }
    }
    
    return cost;
}

- (NSInteger)maximumDaysForShippingMethodName:(NSString *)name forJobs:(NSArray<id<OLPrintJob>>*)jobs;{
    NSString *countryCode = self.shippingAddress.country ? [self.shippingAddress.country codeAlpha3] : [[OLCountry countryForCurrentLocale] codeAlpha3];
    
    NSInteger days = NSIntegerMin;
    for (id<OLPrintJob> job in jobs){
        OLProductTemplate *template = [OLProductTemplate templateWithId:job.templateId];
        NSString *region = template.countryMapping[countryCode];
        if (!region){
            return days;
        }
        for(OLShippingClass *shippingClass in template.shippingClasses[region]){
            if ([shippingClass.className isEqualToString:name] && shippingClass.maxDeliveryTime){
                days = MAX(days, [shippingClass.maxDeliveryTime integerValue]);
                break;
            }
        }
    }
    
    return days;
}

- (NSInteger)minimumDaysForShippingMethodName:(NSString *)name forJobs:(NSArray<id<OLPrintJob>>*)jobs;{
    NSString *countryCode = self.shippingAddress.country ? [self.shippingAddress.country codeAlpha3] : [[OLCountry countryForCurrentLocale] codeAlpha3];
    
    NSInteger days = NSIntegerMax;
    for (id<OLPrintJob> job in self.jobs){
        OLProductTemplate *template = [OLProductTemplate templateWithId:job.templateId];
        NSString *region = template.countryMapping[countryCode];
        if (!region){
            return days;
        }
        for(OLShippingClass *shippingClass in template.shippingClasses[region]){
            if ([shippingClass.className isEqualToString:name] && shippingClass.minDeliveryTime){
                days = MIN(days, [shippingClass.minDeliveryTime integerValue]);
                break;
            }
        }
    }
    
    return days;
}

- (NSString *)deliveryEstimatedDaysStringForShippingMethodName:(NSString *)name forJobs:(NSArray<id<OLPrintJob>>*)jobs;{
    NSInteger min = [self minimumDaysForShippingMethodName:name forJobs:jobs];
    NSInteger max = [self maximumDaysForShippingMethodName:name forJobs:jobs];
    
    if (min != NSIntegerMax && max != NSIntegerMin && min != max){
        return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%@ days", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Examples: 2-5 days, 7 days"), [NSString stringWithFormat:@"%d - %d", (int)min, (int)max]];
    }
    else if (min == max){
        if (min == 1){
            return NSLocalizedStringFromTableInBundle(@"1 day", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"");
        }
        else{
            return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%@ days", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Examples: 2-5 days, 7 days"), [NSString stringWithFormat:@"%d", (int)min]];
        }
    }
    else if (min != NSIntegerMax){
        if (min == 1){
            return NSLocalizedStringFromTableInBundle(@"1 day", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"");
        }
        else{
            return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%@ days", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Examples: 2-5 days, 7 days"), [NSString stringWithFormat:@"%d", (int)min]];
        }
    }
    else if (max != NSIntegerMin){
        if (max == 1){
            return NSLocalizedStringFromTableInBundle(@"1 day", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"");
        }
        else{
            return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%@ days", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Examples: 2-5 days, 7 days"), [NSString stringWithFormat:@"%d", (int)max]];
        }
    }
    
    return nil;
}

#pragma mark - OLAssetUploadRequestDelegate methods

- (void)assetUploadRequest:(OLAssetUploadRequest *)req didProgressWithTotalAssetsUploaded:(NSUInteger)totalAssetsUploaded totalAssetsToUpload:(NSUInteger)totalAssetsToUpload bytesWritten:(long long)bytesWritten totalAssetBytesWritten:(long long)totalAssetBytesWritten totalAssetBytesExpectedToWrite:(long long)totalAssetBytesExpectedToWrite {
    self.totalBytesWritten += (NSUInteger) bytesWritten;
    if (self.userSubmittedForPrinting && self.progressHandler) {
        self.progressHandler(totalAssetsUploaded, totalAssetsToUpload, totalAssetBytesWritten, totalAssetBytesExpectedToWrite, self.totalBytesWritten, self.totalBytesExpectedToWrite);
    }
}

- (void)assetUploadRequest:(OLAssetUploadRequest *)req didSucceedWithAssets:(NSArray<OLAsset *> *)assets {
    NSAssert(self.assetsToUpload.count == assets.count, @"Oops there should be a 1:1 relationship between uploaded assets and submitted, currently its: %lu:%lu", (unsigned long) self.assetsToUpload.count, (unsigned long) assets.count);
#ifdef DEBUG
    for (OLAsset *asset in assets) {
        NSAssert([self.assetsToUpload containsObject:asset], @"oops");
    }
#endif
    
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
    
#ifdef DEBUG
    // sanity check all assets are uploaded
    for (id<OLPrintJob> job in self.jobs) {
        for (OLAsset *jobAsset in job.assetsForUploading) {
            NSAssert(jobAsset.isUploaded, @"oops all assets should have been uploaded");
        }
    }
#endif
    
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
    
    [self validateOrderSubmissionWithCompletionHandler:self.completionHandler];
}

- (void)validateOrderSubmissionWithCompletionHandler:(void(^)(NSString *orderIdReceipt, NSError *error))handler{
    if (self.numberOfTimesPolledForSubmissionStatus > 60){
        self.numberOfTimesPolledForSubmissionStatus = 0;
        handler(self.receipt, [NSError errorWithDomain:kOLKiteSDKErrorDomain code:kOLKiteSDKErrorCodeServerFault userInfo:@{NSLocalizedDescriptionKey: NSLocalizedStringFromTableInBundle(@"Error validating the order. Please try again later.", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"")}]);
        return;
    }
    
    self.numberOfTimesPolledForSubmissionStatus++;
#ifdef OL_KITE_VERBOSE
    NSLog(@"Polling Kite server for order status: %lu", (unsigned long)self.numberOfTimesPolledForSubmissionStatus);
#endif
    self.printOrderSubmitStatusReq = [[OLPrintOrderSubmitStatusRequest alloc] initWithPrintOrder:self];
    [self.printOrderSubmitStatusReq checkStatusWithCompletionHandler:^(OLPrintOrderSubmitStatus status, NSError *error){
        if (status == OLPrintOrderSubmitStatusAccepted || status == OLPrintOrderSubmitStatusReceived){
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [self validateOrderSubmissionWithCompletionHandler:handler];
            });
        }
        else{
#ifdef OL_KITE_VERBOSE
            NSLog(@"Print order submit status request finished with status:%lu", (unsigned long)status);
#endif
            self.numberOfTimesPolledForSubmissionStatus = 0;
            handler(self.receipt, error);
        }
    }];
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
    [aCoder encodeObject:self.email forKey:kKeyOrderEmail];
    [aCoder encodeObject:self.phone forKey:kKeyOrderPhone];
    [aCoder encodeInteger:self.submitStatus forKey:kKeyOrderSubmitStatus];
    [aCoder encodeObject:self.submitStatusErrorMessage forKey:kKeyOrderSubmitStatusError];
    [aCoder encodeBool:self.optOutOfEmail forKey:kKeyOrderOptOutOfEmail];
    [aCoder encodeBool:self.shipToStore forKey:kKeyOrderShipToStore];
    [aCoder encodeBool:self.payInStore forKey:kKeyOrderPayInStore];
    [aCoder encodeObject:self.paymentMethod forKey:kKeyOrderPaymentMethod];
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
            _email = [aDecoder decodeObjectForKey:kKeyOrderEmail];
            _phone = [aDecoder decodeObjectForKey:kKeyOrderPhone];
            _submitStatus = [aDecoder decodeIntegerForKey:kKeyOrderSubmitStatus];
            _submitStatusErrorMessage = [aDecoder decodeObjectForKey:kKeyOrderSubmitStatusError];
            _optOutOfEmail = [aDecoder decodeBoolForKey:kKeyOrderOptOutOfEmail];
            _shipToStore = [aDecoder decodeBoolForKey:kKeyOrderShipToStore];
            _payInStore = [aDecoder decodeBoolForKey:kKeyOrderPayInStore];
            _paymentMethod = [aDecoder decodeObjectForKey:kKeyOrderPaymentMethod];
        }
        return self;
        
    }
    @catch (NSException *exception) {
        return nil;
    }
}

@end
