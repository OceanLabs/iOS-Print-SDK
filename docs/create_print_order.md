Creating a Print Order
==============

If you don't want to use the checkout experience included with the Print SDK (i.e. the [Kite Print Shop Experience](print_shop.md)) then you need to explicitly create a print order. 

This tutorial covers creating a print order to be submitted for printing and posting.

_If you haven't already, see the [README](../README.md) for an initial overview and instructions for adding the SDK to your project._


Overview
--------
1. Initialise the SDK
2. Create `OLAsset` representations of all the images you want to print
3. Create `OLPrintJob`'s for the desired products you want to print and attach the assets created in Step 2
4. Create an `OLPrintOrder` and attach your job(s) created in Step 3


Sample Code
-----------

1. Initialize the SDK and provide your API Keys (these can be found in the [Credentials](https://www.kite.ly/accounts/credentials/) section of the development dashboard). A typical place for initialization is in your app delegate's `didFinishLaunchingWithOptions:` method.

    ```obj-c
    #import <OLKitePrintSDK.h>
    
    [OLKitePrintSDK setAPIKey:@"REPLACE_WITH_YOUR_API_KEY" withEnvironment:kOLKitePrintSDKEnvironmentSandbox];
    ```

    *Note: Sandbox orders will not be printed and posted. The Sandbox environment is purely for testing during development. If you want to submit a real order that will be printed and posted just use your live API key and the `kOLKitePrintSDKEnvironmentLive` environment*

2. Create `OLAsset` representations for every image you want to print. `OLAsset` has many constructors (including ones not listed below) to support any use case you may have.

    ```obj-c
    NSArray *assetsForPrinting = @[
        [OLAsset assetWithURL:[NSURL URLWithString:@"http://psps.s3.amazonaws.com/sdk_static/1.jpg"]],
        [OLAsset assetWithImageAsJPEG:[UIImage imageNamed:@"photo.jpg"]],
        [OLAsset assetWithFilePath:@"..."],
        [OLAsset assetWithALAsset: ...]
    ];
    ```

3. Create `OLPrintJob`'s for every type of product you want to print in this order. A print order can have multiple print jobs attached.

    ```obj-c
   id<OLPrintJob> squarePrints = [OLPrintJob printJobWithTemplateId:kOLDefaultTemplateForSquarePrints OLAssets:assetsForPrinting];
    id<OLPrintJob> magnets = [OLPrintJob printJobWithTemplateId:kOLDefaultTemplateForMagnets OLAssets:assetsForPrinting];
    id<OLPrintJob> polaroidStylePrints = [OLPrintJob printJobWithTemplateId:kOLDefaultTemplateForPolaroidStylePrints OLAssets:assetsForPrinting];
    ```
    
     *Note: The above shows only a small sample of the products available for printing with the SDK*
4. Create an `OLPrintOrder` and attach the print job(s) you created in the previous step

    ```obj-c
    OLPrintOrder *printOrder = [[OLPrintOrder alloc] init];
    [printOrder addPrintJob:squarePrints];
    [printOrder addPrintJob:magnets];
    [printOrder addPrintJob:polaroidStylePrints];    
    ```
    
Next Steps
----------
- If you're building your own [Custom Checkout](../README.md#custom-checkout) UI then it's time to [set the shipping address](shipping.md) to which the order will be delivered
- Alternatively you can use the [Kite Print Shop user experience](../README.md#kite-print-shop-user-experience) where you use our product selection, photo editing and payment UI