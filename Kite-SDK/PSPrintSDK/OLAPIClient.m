//
//  OLAPIClient.m
//  KiteSDK
//
//  Created by Jaime Landazuri on 18/03/2019.
//  Copyright © 2019 Kite.ly. All rights reserved.
//

#import "OLAPIClient.h"
#import "OLConstants.h"
#import "OLKitePrintSDK.h"

typedef NS_ENUM(NSInteger, OLAPIClientHTTPMethod) {
    OLAPIClientHTTPMethodGet,
    OLAPIClientHTTPMethodPost
};

typedef NS_ENUM(NSInteger, OLAPIClientParameterEncoding) {
    OLAPIClientParameterEncodingRaw,
    OLAPIClientParameterEncodingJSON
};

@interface OLAPIClient() <NSURLSessionDelegate>
@property (nonatomic, strong) NSURLSession *urlSession;
@end

@implementation OLAPIClient

+ (id)shared {
    static OLAPIClient *sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedClient = [[self alloc] init];
    });
    return sharedClient;
}

- (id)init {
    self = [super init];
    if (self) {
        _urlSession = [NSURLSession sessionWithConfiguration: NSURLSessionConfiguration.defaultSessionConfiguration
                                                    delegate: self
                                               delegateQueue: NSOperationQueue.mainQueue];
    }
    return self;
}

- (void)dataTaskWith:(NSURL *)url parameters:(NSDictionary *)parameters headers:(NSDictionary *)headers requestIdentifier:(NSNumber **)requestIdentifier method:(OLAPIClientHTTPMethod)method encoding:(OLAPIClientParameterEncoding)encoding completionHandler:(OLAPIClientRequestHandler)completionHandler {
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: url];
    request.HTTPMethod = [self methodString: method];
    
    // Add headers
    [request setValue:[NSString stringWithFormat: @"Kite SDK iOS v%@", kOLKiteSDKVersion] forHTTPHeaderField:@"User-Agent"];
    [request setValue:[[NSBundle mainBundle] bundleIdentifier] forHTTPHeaderField:@"X-App-Bundle-Id"];
    [request setValue:[self appName] forHTTPHeaderField:@"X-App-Name"];
    [request setValue:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] forHTTPHeaderField:@"X-App-Version"];
    [request setValue:[OLAnalytics userDistinctId] forHTTPHeaderField:@"X-Person-UUID"];
    if ([OLKitePrintSDK isKiosk]){
        [request setValue:@"true" forHTTPHeaderField:@"X-Kiosk-Mode"];
    }
    
    // Custom headers
    for (NSString *key in headers.allKeys) {
        NSString *value = headers[key];
        [request setValue: value forHTTPHeaderField: key];
    }
    
    switch (method) {
        case OLAPIClientHTTPMethodGet:
            if (parameters != nil) {
                NSURLComponents *components = [NSURLComponents componentsWithString:request.URL.absoluteString];
                NSMutableArray *items = [[NSMutableArray alloc] init];
                [parameters enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSObject *value, BOOL *stop) {
                    NSString *itemValue = @"";
                    if ([value isKindOfClass: [NSString class]]) {
                        itemValue = (NSString *)value;
                    } else if ([value isKindOfClass: [NSNumber class]]) {
                        itemValue = [(NSNumber *)value stringValue];
                    } else {
                        [NSException raise: @"OLAPIClientMethodException" format: @"HTTP method not implemented"];
                    }
                    
                    NSURLQueryItem *item = [[NSURLQueryItem alloc] initWithName:key value:itemValue];
                    [items addObject: item];
                }];
                components.queryItems = items;
                request.URL = components.URL;
            }
            break;
        case OLAPIClientHTTPMethodPost:
            if (parameters != nil) {
                if (encoding == OLAPIClientParameterEncodingJSON) {
                    [request setValue: @"application/json" forHTTPHeaderField: @"Content-Type"];
                    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:parameters options:0 error:nil];
                    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[request.HTTPBody length]] forHTTPHeaderField:@"Content-Length"];
                } else {
                    NSMutableArray *parameterStrings = [[NSMutableArray alloc] init];
                    [parameters enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSObject *value, BOOL *stop) {
                        [parameterStrings addObject:[NSString stringWithFormat:@"=%@", value]];
                    }];
                    NSString *postString = [parameterStrings componentsJoinedByString:@"&"];
                    request.HTTPBody = [postString dataUsingEncoding:NSUTF8StringEncoding];
                }
            }
            break;
    }
    
    NSURLSessionDataTask *dataTask = [self.urlSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode == 503) {
            NSError *parsingError = [NSError errorWithDomain:kOLKiteSDKErrorDomain code:kOLKiteSDKErrorCodeMaintenanceMode userInfo:@{NSLocalizedDescriptionKey: kOLKiteSDKErrorMessageMaintenanceMode}];
            completionHandler(httpResponse.statusCode, nil, parsingError);
            return;
        }
        
        if (error != nil) {
            completionHandler(httpResponse.statusCode, nil, error);
            return;
        }
        
        if (data == nil) {
            completionHandler(0, nil, [NSError errorWithDomain:@"ly.kite.sdk" code:0 userInfo:@{ NSLocalizedDescriptionKey:@"DataTask failed", NSLocalizedFailureReasonErrorKey:@"No data was received" }]);
            return;
        }
        
        NSError *jsonError = nil;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error: &jsonError];
        if (jsonError == nil) {
            completionHandler(httpResponse.statusCode, json, nil);
        } else {
            completionHandler(httpResponse.statusCode, nil, jsonError);
        }
    }];
    *requestIdentifier = [NSNumber numberWithUnsignedInteger:dataTask.taskIdentifier];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [dataTask resume];
}

- (NSString *)methodString:(OLAPIClientHTTPMethod)method {
    switch (method) {
        case OLAPIClientHTTPMethodGet:
            return @"GET";
        case OLAPIClientHTTPMethodPost:
            return @"POST";
    }
}

- (NSString *)appName {
    NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
    NSString *bundleName = nil;
    if ([info objectForKey:@"CFBundleDisplayName"] == nil) {
        bundleName = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *) kCFBundleNameKey];
    } else {
        bundleName = [NSString stringWithFormat:@"%@", [info objectForKey:@"CFBundleDisplayName"]];
    }
    
    return bundleName;
}

#pragma mark - Public

- (void)getWithURL:(NSURL *)url parameters:(NSDictionary *)parameters headers:(NSDictionary *)headers requestIdentifier:(NSNumber **)requestIdentifier completionHandler:(OLAPIClientRequestHandler)completionHandler {
    [self dataTaskWith:url parameters:parameters headers:headers requestIdentifier:(NSNumber **)requestIdentifier method:OLAPIClientHTTPMethodGet encoding:OLAPIClientParameterEncodingJSON completionHandler:completionHandler];
}

- (void)cancelRequestWithIdentifier:(NSNumber *)requestIdentifier {
    [self.urlSession getAllTasksWithCompletionHandler:^(NSArray<__kindof NSURLSessionTask *> * _Nonnull tasks) {
        for (NSURLSessionTask *task in tasks) {
            if (task.taskIdentifier == requestIdentifier.unsignedIntegerValue) {
                [task cancel];
            }
        }
    }];
}

@end
