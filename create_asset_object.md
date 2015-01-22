Creating an OLAsset object
==============

This tutorial covers creating an `OLAsset` object to be submitted for printing and posting.

_If you haven't already, see the [README](../README.md) for an initial overview and instructions for adding the SDK to your project._


Overview
--------
OLAsset provides many constructors to support any use case you may have.
```obj-c
+ (OLAsset *)assetWithImageAsJPEG:(UIImage *)image;
+ (OLAsset *)assetWithImageAsPNG:(UIImage *)image;
+ (OLAsset *)assetWithDataAsJPEG:(NSData *)data;
+ (OLAsset *)assetWithDataAsPNG:(NSData *)data;
+ (OLAsset *)assetWithFilePath:(NSString *)path;
+ (OLAsset *)assetWithALAsset:(ALAsset *)asset;
+ (OLAsset *)assetWithDataSource:(id<OLAssetDataSource>)dataSource;
+ (OLAsset *)assetWithURL:(NSURL *)url;
```


Sample Code
-----------

1. Create `OLAsset` representations for every image you want to print.

```obj-c
NSArray *assetsForPrinting = @[
[OLAsset assetWithURL:[NSURL URLWithString:@"http://psps.s3.amazonaws.com/sdk_static/1.jpg"]],
[OLAsset assetWithImageAsJPEG:[UIImage imageNamed:@"photo.jpg"]],
[OLAsset assetWithFilePath:@"..."],
[OLAsset assetWithALAsset: ...]
];
```

Next Steps
----------
- If you are using the [Full mode of the SDK](../README.md#managed-checkout#full) then create and present or push an [`OLKiteViewController`](OLKiteViewController.md) passing it an array of OLAssets
- If you are using the [Managed Checkout](../README.md#managed-checkout) flow where you use our checkout and payment UI then
[create and present a `OLCheckoutViewController`](managed_checkout.md) passing it a [`OLPrintOrder`](create_print_order.md)
- Alternatively if you're building your own [Custom Checkout](../README.md#custom-checkout) UI then it's time to [set the shipping address](shipping.md) to which the order will be delivered
