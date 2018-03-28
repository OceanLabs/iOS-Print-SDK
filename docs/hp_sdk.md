Enable Print at Home Functionality with HP Print SDK
==============

Kite SDK provides offers integrated print-at-home functionality with the HP Print SDK.

![Kite](hp_sdk.png)

## Installation with CocoaPods
```ruby
pod 'MobilePrintSDK', '~> 3.0.9'
```

## Usage
Enable by setting the showPrintAtHome property of OLKiteViewController to true.

Objective-C:
```obj-c
OLKiteViewController *kiteViewController = [[OLKiteViewController alloc] initWithAssets:assets];
kiteViewController.showPrintAtHome = YES;
[self presentViewController:kiteViewController animated:YES completion:NULL];
```
Swift:
```swift
let kiteViewController = OLKiteViewController.init(assets: [OLAsset(url: URL(string: "http://psps.s3.amazonaws.com/sdk_static/4.jpg"))])
kiteViewController.showPrintAtHome = true
present(kiteViewController!, animated: true, completion: nil)
```

Please note that only the first asset passed to KiteViewController will be available for print with the Print at Home functionality.
