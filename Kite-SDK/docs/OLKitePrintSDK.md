Customizing The Kite.ly Print SDK
==============

This tutorial covers customizing the Kite.ly Print SDK

_If you haven't already, see the [README](../../README.md) for an initial overview and instructions for adding the SDK to your project._


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

Next Steps
----------
- If you are using the [Full mode of the SDK](../../README.md#full) then create and present or push an `OLKiteViewController` passing it an array of OLAssets
