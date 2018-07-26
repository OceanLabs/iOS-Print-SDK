Creating Print Jobs
==============

If you don't want to use the print shop experience included with the Print SDK (i.e. the [Kite Print Shop Experience](print_shop.md)) then you need to explicitly create a print job.

This tutorial covers creating a print job to be submitted for printing and posting.

_If you haven't already, see the [README](../../README.md) for an initial overview and instructions for adding the SDK to your project._


Overview
--------
1. Initialise the SDK
2. Create `OLAsset` representations of all the images you want to print
3. Create `OLPrintJob`'s for the desired products you want to print and attach the assets created in Step 2

Sample Code
-----------

1. Initialize the SDK and provide your API Keys (these can be found in the [Credentials](https://www.kite.ly/settings/credentials/) section of the development dashboard). A typical place for initialization is in your app delegate's `didFinishLaunchingWithOptions:` method.

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

3. Create `OLPrintJob`s for every type of product you want to print in this order. You can submit multiple print jobs for printing at once.

    ```obj-c
   id<OLPrintJob> squarePrints = [OLPrintJob printJobWithTemplateId:@"TemplateForSquarePrints" OLAssets:assetsForPrinting];
    id<OLPrintJob> magnets = [OLPrintJob printJobWithTemplateId:@"TemplateForMagnets" OLAssets:assetsForPrinting];
    id<OLPrintJob> polaroidStylePrints = [OLPrintJob printJobWithTemplateId:@"TemplateForPolaroidStylePrints" OLAssets:assetsForPrinting];
    ```

     *Note: The above shows only a small sample of the products available for printing with the SDK*
