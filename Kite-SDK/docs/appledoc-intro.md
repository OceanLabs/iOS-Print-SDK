The Kite Print SDK makes it easy to add print on demand functionality to your app.

Harness our worldwide print and distribution network. We'll take care of all the tricky printing and postage stuff for you!

To get started, you will need to have a free Kite developer account. Go to [kite.ly](https://www.kite.ly) to sign up for free.

### Quick Integration
We really mean it when we say integration can be done in minutes.


[OLKitePrintSDK setAPIKey:@"YOUR_API_KEY" withEnvironment:kOLKitePrintSDKEnvironmentLive]; //Or kOLKitePrintSDKEnvironmentSandbox for testing

OLKiteViewController *vc = [[OLKiteViewController alloc] initWithAssets:@[[OLAsset assetWithImageAsJPEG:YOUR_UIIMAGE_OBJECT]]]];

[self presentViewController:vc animated:YES completion:NULL];

