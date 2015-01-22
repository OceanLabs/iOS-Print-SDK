Show the user the available products with OLKiteViewController
==============

The Print SDK includes a robust print shop experience including checkout and payment that's proven to convert well with users. It features well thought UX and beautiful UI. It can take care of the entire checkout process for you, no need to spend time building any user interfaces.

This is the quickest and most complete approach to integration and perfect if you don't want to spend any time building a custom checkout experience.

If you don't want to use or customize the provided experience you can [build your own custom checkout UI](../README.md#).

`OLKiteViewController` supports both being presented modally and being pushed on your existing `UINavigationController`.

_If you haven't already, see the [README](../README.md#Custom-Checkout) for an initial overview and instructions for adding the SDK to your project._


Overview
--------
1. [Create `OLAsset` objects](docs/create_asset_object.md) for the photo(s) you want to print
2. Create an `NSArray` of the `OLAsset` object(s) created in step 1.
3. [Create and present or push an `OLKiteViewController`](docs/OLKiteViewController.md) passing it the `NSArray` of `OLAsset` objects.
4. _(Optional)_ [Customize `OLKitePrintSDK`](docs/OLKitePrintSDK.md) to limit which products are available to the user and provide custom photography for the available products.

Sample Code
-----------
1. See [Creating a OLAssets](create_asset_object.md) for details on creating `OLAsset` objects.
2. Create an `OLKiteViewController` passing it an `NSArray` object with `OLAsset` objects.

```obj-c
// SomeViewController.m
#import "OLKitePrintSDK.h"

@implementation SomeViewController

- (void)showPrintShopWithAssets:(NSArray *)assets {
  OLKiteViewController *vc = [[OLKiteViewController alloc] initWithAssets:assets];
  [self.navigationController pushViewController:vc animated:YES];
}

@end
```
*Note: If you prefer you can also present the `OLKiteViewController` as a modal view controller rather than pushing it onto the navigation stack.*
