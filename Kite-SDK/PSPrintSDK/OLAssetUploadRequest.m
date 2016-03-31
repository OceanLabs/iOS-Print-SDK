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

#import "OLAssetUploadRequest.h"
#import "OLBaseRequest.h"
#import "OLConstants.h"
#import "OLKitePrintSDK.h"
#import "OLAsset.h"
#import "OLAsset+Private.h"

@interface OLKitePrintSDK (Private)

+ (NSString *)apiEndpoint;
+ (NSString *)apiVersion;

@end

@interface SignedS3RequestUploadDetails : NSObject
@property (nonatomic, strong) OLAsset *asset;
@property (nonatomic, strong) NSURL *signedS3UploadReqURL;
@property (nonatomic, strong) NSURL *s3AssetPreviewURL;
@property (nonatomic, assign) NSUInteger assetId;
@end

@implementation SignedS3RequestUploadDetails
@end

typedef void (^SignedS3UploadRequestCompletionHandler)(NSArray/*<SignedS3RequestUploadDetails>*/ *signedS3RequestUploadDetails, NSError *error);
typedef void (^UploadToS3ProgressHandler)(long long bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite);
typedef void (^UploadToS3CompletionHandler)(NSError *error);

typedef void (^RegisterImageURLAssetsCompletionHandler)(NSError *error);
typedef void (^UploadAssetsCompletionHandler)(NSError *error);

@interface OLAssetUploadRequest () <NSURLSessionTaskDelegate>
@property (nonatomic, strong) OLBaseRequest *signReq, *registerImageURLAssetsReq;
@property (nonatomic, strong) NSURLSessionDataTask *s3UploadTask;
@property (nonatomic, assign) BOOL cancelled;
@property (copy, nonatomic) UploadToS3ProgressHandler progressHandler;
@end

@implementation OLAssetUploadRequest

- (void)cancelUpload {
    [self.signReq cancel];
    [self.s3UploadTask cancel];
    self.signReq = nil;
    self.s3UploadTask = nil;
    self.cancelled = YES;
}

+ (NSError *)errorFromResponse:(id)json httpStatusCode:(NSInteger)httpStatusCode {
    NSString *errorMessage = @"Your asset upload request failed. Please try again.";
    NSInteger errorCode = kOLKiteSDKErrorCodeServerFault;
    switch (httpStatusCode) {
        case 401:
            errorMessage = NSLocalizedStringFromTableInBundle(@"401 Unauthorized Request Error whilst trying to upload an asset. Please check you included an Authorization header and that the supplied auth credentials are correct.", @"KitePrintSDK", [OLConstants bundle], @"");
            errorCode = kOLKiteSDKErrorCodeUnauthorized;
            break;
        case 500:
            errorMessage = NSLocalizedStringFromTableInBundle(@"500 Internal Server Error whilst trying to upload an asset. Please try again.", @"KitePrintSDK", [OLConstants bundle], @"");
            break;
        default:
            break;
    }
    
    if (json[@"error"]) {
        if (json[@"error"][@"message"]) {
            errorMessage = json[@"error"][@"message"];
        }
    }
    
    return [NSError errorWithDomain:kOLKiteSDKErrorDomain code:errorCode userInfo:@{NSLocalizedDescriptionKey:errorMessage}];
}

- (void)registerImageURLAssets:(NSArray/*<OLAsset>*/ *)imageURLAssets completionHandler:(RegisterImageURLAssetsCompletionHandler)handler {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/asset/", [OLKitePrintSDK apiEndpoint], [OLKitePrintSDK apiVersion]]];
    NSDictionary *headers = @{@"Authorization": [NSString stringWithFormat:@"ApiKey %@:", [OLKitePrintSDK apiKey]]};
    
    NSUInteger expectedRegisteredAssetCount = 0;
    NSMutableDictionary *jsonBody = [[NSMutableDictionary alloc] init];
    NSMutableArray *objects = [[NSMutableArray alloc] init];
    jsonBody[@"objects"] = objects;
    for (OLAsset *asset in imageURLAssets) {
        if (asset.assetType == kOLAssetTypeRemoteImageURL) {
            [objects addObject:@{@"url":asset.imageURL.absoluteString, @"client_asset":@"true", @"mime_type":asset.mimeType}];
            ++expectedRegisteredAssetCount;
        }
    }
    
    NSAssert(expectedRegisteredAssetCount > 0, @"oops called registerImageURLAssets with no applicable assets");
    
    NSData *jsonBodyData = [NSJSONSerialization dataWithJSONObject:jsonBody options:0 error:nil];
    NSString *jsonBodyString = [[NSString alloc] initWithData:jsonBodyData encoding:NSUTF8StringEncoding];
    
    self.registerImageURLAssetsReq = [[OLBaseRequest alloc] initWithURL:url httpMethod:kOLHTTPMethodPATCH headers:headers body:jsonBodyString];
    [self.registerImageURLAssetsReq startWithCompletionHandler:^(NSInteger httpStatusCode, id json, NSError *error) {
        NSUInteger registeredAssetCount = 0;
        if (!error && httpStatusCode >= 200 && httpStatusCode <= 299) {
            if ([json isKindOfClass:[NSDictionary class]]) {
                id objects = json[@"objects"];
                if ([objects isKindOfClass:[NSArray class]]) {
                    for (id obj in objects) {
                        if ([obj isKindOfClass:[NSDictionary class]]) {
                            id assetId = obj[@"asset_id"];
                            id url = obj[@"url"];
                            if (![assetId isKindOfClass:[NSNumber class]] || ![url isKindOfClass:[NSString class]]) {
                                continue;
                            }
                            
                            for (OLAsset *asset in imageURLAssets) {
                                if (asset.assetType == kOLAssetTypeRemoteImageURL && [asset.imageURL.absoluteString isEqualToString:url]) {
                                    [asset setUploadedWithAssetId:[assetId unsignedIntegerValue] previewURL:url];
                                    ++registeredAssetCount;
                                }
                            }
                        }
                    }
                }
            }
        }
        
        if (!error && registeredAssetCount != expectedRegisteredAssetCount) {
            error = [NSError errorWithDomain:kOLKiteSDKErrorDomain code:kOLKiteSDKErrorCodeRegisteredAssetCountDiscrepency userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Only registered %d/%d image URLs with the asset endpoint", @"KitePrintSDK", [OLConstants bundle], @""), registeredAssetCount, expectedRegisteredAssetCount]}];
        }
        
        handler(error);
    }];
}

- (void)getSignedS3UploadRequestURLsWithAssets:(NSArray/*<OLAsset>*/ *)assets completionHandler:(SignedS3UploadRequestCompletionHandler)handler {
    NSMutableString *mimeTypes = [[NSMutableString alloc] init];
    for (OLAsset *asset in assets) {
        if (mimeTypes.length > 0) {
            [mimeTypes appendString:@","];
        }
        [mimeTypes appendString:asset.mimeType];
    }
    
    __weak OLAssetUploadRequest *zelf = self;
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/asset/sign/?mime_types=%@&client_asset=true", [OLKitePrintSDK apiEndpoint], [OLKitePrintSDK apiVersion], mimeTypes]];
    NSDictionary *headers = @{@"Authorization": [NSString stringWithFormat:@"ApiKey %@:", [OLKitePrintSDK apiKey]]};
    self.signReq = [[OLBaseRequest alloc] initWithURL:url httpMethod:kOLHTTPMethodGET headers:headers body:nil];
    [self.signReq startWithCompletionHandler:^(NSInteger httpStatusCode, id json, NSError *error) {
        if (zelf.cancelled) return;
        
        if (httpStatusCode != 200) {
            if (error == nil) {
                error = [OLAssetUploadRequest errorFromResponse:json httpStatusCode:httpStatusCode];
            }
        }
        
        if (error) {
            handler(nil, error);
            return;
        }
        
        NSArray *signedUploadReqURLs = [json objectForKey:@"signed_requests"];
        NSArray *assetS3PreviewURLs = [json objectForKey:@"urls"];
        NSArray *assetIds = [json objectForKey:@"asset_ids"];
        NSMutableArray *signedS3RequestUploadDetails = [[NSMutableArray alloc] init];
        for (NSUInteger i = 0; i < signedUploadReqURLs.count; ++i) {
            SignedS3RequestUploadDetails *details = [[SignedS3RequestUploadDetails alloc] init];
            details.signedS3UploadReqURL = [NSURL URLWithString:signedUploadReqURLs[i]];
            details.s3AssetPreviewURL = [NSURL URLWithString:assetS3PreviewURLs[i]];
            details.assetId = [assetIds[i] unsignedIntegerValue];
            details.asset = assets[i];
            [signedS3RequestUploadDetails addObject:details];
        }
        
        handler(signedS3RequestUploadDetails, nil);
    }];
}

- (void)uploadData:(NSData *)data mimeType:(NSString *)mimeType toS3WithSignedRequestURL:(NSURL *)signedS3UploadReqURL progress:(UploadToS3ProgressHandler)progressHandler completion:(UploadToS3CompletionHandler)completionHandler {
    self.progressHandler = progressHandler;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:signedS3UploadReqURL];
    [request setHTTPMethod:@"PUT"];
    [request setHTTPBody:data];
    [request setValue:@"private" forHTTPHeaderField:@"x-amz-acl"];
    [request setValue:mimeType forHTTPHeaderField:@"Content-Type"];
    [request setTimeoutInterval:120];
    
    __weak OLAssetUploadRequest *zelf = self;
    
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig
                                                          delegate:self
                                                     delegateQueue:nil];
    
    self.s3UploadTask  = [session uploadTaskWithRequest:request fromData:data completionHandler:^(NSData *data, NSURLResponse *response, NSError *error){
        if (zelf.cancelled) return;
        if (error){
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(error);
            });
        }
        else{
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(nil);
            });
        }
    }];
    
    [self.s3UploadTask resume];
}

- (void)URLSession:(NSURLSession *)session task:(nonnull NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend{
    if (self.cancelled) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.progressHandler(bytesSent, totalBytesSent, totalBytesExpectedToSend);
    });
}

- (void)uploadImageAsJPEG:(UIImage *)image {
    [self uploadOLAssets:@[[OLAsset assetWithImageAsJPEG:image]]];
}

- (void)uploadImageAsPNG:(UIImage *)image {
    [self uploadOLAssets:@[[OLAsset assetWithImageAsPNG:image]]];
}

- (void)uploadOLAsset:(OLAsset *)asset {
    [self uploadOLAssets:@[asset]];
}

- (void)uploadOLAssets:(NSArray<OLAsset *> *)assets {
    NSMutableArray *imageURLAssets = [[NSMutableArray alloc] init];
    NSMutableArray *assetsToUpload = [[NSMutableArray alloc] init];
    
    for (OLAsset *asset in assets) {
        if (asset.assetType == kOLAssetTypeRemoteImageURL) {
            [imageURLAssets addObject:asset];
        } else {
            [assetsToUpload addObject:asset];
        }
    }
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    __weak OLAssetUploadRequest *zelf = self;
    __block NSUInteger outstandingAsyncOperationsCount = 0;
    __block BOOL notifiedDelegateOfSomeOutcome = NO;
    
    void (^completeBlock)(NSError *error) = ^void(NSError *error) {
        if (zelf.cancelled || notifiedDelegateOfSomeOutcome) {
            return;
        }
        
        if (error) {
            notifiedDelegateOfSomeOutcome = YES;
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            if ([zelf.delegate respondsToSelector:@selector(assetUploadRequest:didFailWithError:)]){
                [zelf.delegate assetUploadRequest:zelf didFailWithError:error];
            }
            return;
        }
        
        if (--outstandingAsyncOperationsCount == 0) {
            NSAssert(!error, @"errors should be covered above");
            notifiedDelegateOfSomeOutcome = YES;
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            if ([zelf.delegate respondsToSelector:@selector(assetUploadRequest:didSucceedWithAssets:)]){
                [zelf.delegate assetUploadRequest:zelf didSucceedWithAssets:assets];
            }
        }
    };
    
    if (assetsToUpload.count > 0) {
        ++outstandingAsyncOperationsCount;
        __weak OLAssetUploadRequest *zelf = self;
        [self getSignedS3UploadRequestURLsWithAssets:assetsToUpload completionHandler:^(NSArray/*<SignedS3RequestUploadDetails>*/ *signedS3RequestUploadDetails, NSError *error) {
            if (zelf.cancelled) return;
            NSAssert([NSThread isMainThread], @"Oops we should be calling back on the main thread");
            if (error && !notifiedDelegateOfSomeOutcome) {
                notifiedDelegateOfSomeOutcome = YES;
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                if ([zelf.delegate respondsToSelector:@selector(assetUploadRequest:didFailWithError:)]){
                    [zelf.delegate assetUploadRequest:zelf didFailWithError:error];
                }
                return;
            }
            
            [self uploadOLAssets:signedS3RequestUploadDetails.mutableCopy uploadedAssetAccumulator:[[NSMutableArray alloc] init] completionHandler:^(NSError *error) {
                completeBlock(error);
            }];
        }];
    }
    
    // Register any Assets with remote image URLs differently, this means we don't need to download the asset before hand
    if (imageURLAssets.count > 0) {
        ++outstandingAsyncOperationsCount;
        [self registerImageURLAssets:imageURLAssets completionHandler:^(NSError *error) {
            completeBlock(error);
        }];
    }
}

- (void)uploadOLAssets:(NSMutableArray *)remainingAssetsToUpload uploadedAssetAccumulator:(NSMutableArray *)uploadedAssetAccumulator completionHandler:(UploadAssetsCompletionHandler)handler {
    if (self.cancelled) return;
    __weak OLAssetUploadRequest *zelf = self;
    
    SignedS3RequestUploadDetails *detailsForAssetToUpload = remainingAssetsToUpload[0];
    [remainingAssetsToUpload removeObjectAtIndex:0];
    
    NSUInteger totalAssetsToUpload = uploadedAssetAccumulator.count + remainingAssetsToUpload.count + 1;
    
    [detailsForAssetToUpload.asset dataWithCompletionHandler:^(NSData *assetData, NSError *error) {
        if (zelf.cancelled) return;
        
        if (error) {
            handler(error);
            return;
        }
        if ([zelf.delegate respondsToSelector:@selector(assetUploadRequest:didProgressWithTotalAssetsUploaded:totalAssetsToUpload:bytesWritten:totalAssetBytesWritten:totalAssetBytesExpectedToWrite:)]){
            [zelf.delegate assetUploadRequest:zelf didProgressWithTotalAssetsUploaded:uploadedAssetAccumulator.count totalAssetsToUpload:totalAssetsToUpload bytesWritten:0 totalAssetBytesWritten:0 totalAssetBytesExpectedToWrite:assetData.length];
        }
        [self uploadData:assetData mimeType:detailsForAssetToUpload.asset.mimeType toS3WithSignedRequestURL:detailsForAssetToUpload.signedS3UploadReqURL progress:^(long long bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
            if (zelf.cancelled) return;
            NSAssert([NSThread isMainThread], @"Oops we should be calling back on the main thread");
            if ([zelf.delegate respondsToSelector:@selector(assetUploadRequest:didProgressWithTotalAssetsUploaded:totalAssetsToUpload:bytesWritten:totalAssetBytesWritten:totalAssetBytesExpectedToWrite:)]){
                [zelf.delegate assetUploadRequest:zelf didProgressWithTotalAssetsUploaded:uploadedAssetAccumulator.count totalAssetsToUpload:totalAssetsToUpload bytesWritten:bytesWritten totalAssetBytesWritten:totalBytesWritten totalAssetBytesExpectedToWrite:totalBytesExpectedToWrite];
            }
        } completion:^(NSError *error) {
            if (zelf.cancelled) return;
            
            NSAssert([NSThread isMainThread], @"Oops we should be calling back on the main thread");
            if (error) {
                handler(error);
            } else {
                OLAsset *asset = detailsForAssetToUpload.asset;
                [asset setUploadedWithAssetId:detailsForAssetToUpload.assetId previewURL:detailsForAssetToUpload.s3AssetPreviewURL];
                [uploadedAssetAccumulator addObject:asset];
                if (remainingAssetsToUpload.count == 0) {
                    handler(nil);
                } else {
                    [zelf uploadOLAssets:remainingAssetsToUpload uploadedAssetAccumulator:uploadedAssetAccumulator completionHandler:handler];
                }
            }
        }];
    }];
    
}

@end
