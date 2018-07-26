Kite SDK Entry Points
==============

Depending on your use case you might want to launch to a specific product, or even bypass the product selection/creation process entirely and jump straight to the checkout/payment journey. 

This document describes the various points at which the SDK can be launched into.

Launching to product groups
--------
This is the most common way of launching the SDK. The user is able to select a product to customise and purchase from a range of product groups ranging from phone cases to magnets.

[![Preview](https://raw.githubusercontent.com/OceanLabs/iOS-Print-SDK/master/Kite-SDK/docs/entry_home.png)](https://vimeo.com/155506756)


```obj-c
[OLKitePrintSDK setAPIKey:@"19622ec7352a63a21700ea0323590f617bf380fe" withEnvironment:kOLKitePrintSDKEnvironmentSandbox];

OLKiteViewController *vc = [[OLKiteViewController alloc] initWithAssets:@[[OLAsset assetWithURL:[NSURL URLWithString:@"http://psps.s3.amazonaws.com/sdk_static/4.jpg"]]]];

[self presentViewController:vc animated:YES completion:NULL];
```

Launching to specific/filtered products
-----------
If you only want to present a subset of products (or an individual product) to the user for purchase then use this method. If you filter by just a single product then the user journey will begin at the "detail" screen for that product.

[![Preview](https://raw.githubusercontent.com/OceanLabs/iOS-Print-SDK/master/Kite-SDK/docs/entry_filtered.png)](https://vimeo.com/155507539)

```obj-c
 [OLKitePrintSDK setAPIKey:@"19622ec7352a63a21700ea0323590f617bf380fe" withEnvironment:kOLKitePrintSDKEnvironmentSandbox];
    OLKiteViewController *vc = [[OLKiteViewController alloc] initWithAssets:@[[OLAsset assetWithURL:[NSURL URLWithString:@"http://psps.s3.amazonaws.com/sdk_static/4.jpg"]]]];
    vc.filterProducts = @[@"stickers_square"];
    [self presentViewController:vc animated:YES completion:NULL];
```

Launching directly to checkout
-----------
If you're handling the product selection/creation journey within your own app it's possible to use the SDK just to accept payment on your behalf and place the order with Kite

[![Preview](https://raw.githubusercontent.com/OceanLabs/iOS-Print-SDK/master/Kite-SDK/docs/entry_payment.png)](https://vimeo.com/155507747)

```obj-c
[OLKitePrintSDK setAPIKey:@"REPLACE_WITH_YOUR_API_KEY" withEnvironment:kOLKitePrintSDKEnvironmentSandbox];
    
OLAsset *asset = [OLAsset assetWithURL:[NSURL URLWithString:@"http://psps.s3.amazonaws.com/sdk_static/4.jpg"]];

id<OLPrintJob> job = [OLPrintJob printJobWithTemplateId:@"squares" OLAssets:@[asset]];

UIViewController *vc = [OLKitePrintSDK checkoutViewControllerWithPrintJobs:@[job]];

[self presentViewController:vc animated:YES completion:NULL];
```