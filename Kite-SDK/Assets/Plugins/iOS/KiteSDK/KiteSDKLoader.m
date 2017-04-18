#import "KiteSDKLoader.h"
#import <KiteSDK/KiteSDK.h>

@interface KiteSDKLoader ()

@end

@implementation KiteSDKLoader

+ (void)presentKiteViewControllerWithKey:(NSString *)apiKey withEnvironment:(int)environment{
    [OLKitePrintSDK setAPIKey:apiKey withEnvironment:OLKitePrintSDKEnvironmentSandbox];
    
    OLKiteViewController *vc = [[OLKiteViewController alloc] initWithAssets:@[]];
    
    [[[[UIApplication sharedApplication].delegate window] rootViewController] presentViewController:vc animated:YES completion:NULL];
}

void _PresentKiteShop (const char* apiKey, int environment){
    if (apiKey){
        [KiteSDKLoader presentKiteViewControllerWithKey:[NSString stringWithUTF8String:apiKey] withEnvironment:environment == 1 ? OLKitePrintSDKEnvironmentLive : OLKitePrintSDKEnvironmentSandbox];
    }
}

@end
