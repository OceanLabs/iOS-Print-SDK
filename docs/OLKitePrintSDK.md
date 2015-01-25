Customizing The Kite.ly Print SDK
==============

This tutorial covers customizing the Kite.ly Print SDK

_If you haven't already, see the [README](../README.md) for an initial overview and instructions for adding the SDK to your project._


Overview
--------
`OLKitePrintSDK` is a static class that needs to be initialized with apiKey by using the method:
```obj-c
+ (void)setAPIKey:(NSString *)apiKey withEnvironment:(OLKitePrintSDKEnvironment)environment;
```

You can set the environment to be either live or sandbox for testing:
```obj-c
+ (OLKitePrintSDKEnvironment)environment;
```

You can also customize the available products. Pass an array of `OLProduct` objects:
```obj-c
+ (void)setEnabledProducts:(NSArray *)products;
```
If you don't provide an array of products, then by default all active products are available.

`OLProduct` objects can be created by using the template name which you can find in the [Developer Dashboard](https://www.kite.ly) using:
```obj-c
+(OLProduct *) productWithTemplateId:(NSString *)templateId
```

`OLProduct` objects can be further be customized with your own image that appears in the product list and in the product description by setting the following public properties.
```obj-c
@property (strong, nonatomic) id coverPhoto;
@property (strong, nonatomic) NSArray *productPhotos;
```
These images can be in the form of:
* `NSURL`: The images will loaded remotely. Great for keeping the app size low, but will need to be downloaded the first time they are displayed.
* `NSString`: The images will be loaded from the local app bundle image assets.
* `UIImage`: Provide an image object to be displayed. Straight-forward but be wary of high memory usage.

If you don't provide images, then the default remote images will be used.

Sample Code
-----------
```obj-c
// AppDelegate.m
#import "OLKitePrintSDK.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [OLKitePrintSDK setAPIKey:@"API KEY HERE" withEnvironment:kOLKitePrintSDKEnvironmentSandbox];

  OLProduct *squares = [OLProduct productWithTemplateId:@"squares"];
  OLProduct *magnets = [OLProduct productWithTemplateId:@"magnets"];
  squares.coverImage = [NSURL URLWithString:@"URL HERE"];
  squares.productPhotos = @[[NSURL URLWithString:@"URL HERE"]];
  [OLKitePrintSDK setEnabledProducts:@[squares, magnets]];

}

@end
```


Next Steps
----------
- If you are using the [Full mode of the SDK](../README.md#full) then create and present or push an [`OLKiteViewController`](OLKiteViewController.md) passing it an array of OLAssets
- If you are using the [Managed Checkout](../README.md#managed-checkout) flow where you use our checkout and payment UI then
[create and present a `OLCheckoutViewController`](managed_checkout.md) passing it a [`OLPrintOrder`](create_print_order.md)
- Alternatively if you're building your own [Custom Checkout](../README.md#custom-checkout) UI then it's time to [set the shipping address](shipping.md) to which the order will be delivered
