# iOS SDK

![Kite](Kite-SDK/docs/kite.png)

![Platform](https://img.shields.io/badge/platform-iOS-lightgrey.svg)
![Cocoapods](https://img.shields.io/cocoapods/v/Kite-Print-SDK.svg)
[![Twitter](https://img.shields.io/badge/twitter-@kite_ly-yellow.svg?style=flat)](http://twitter.com/kite_ly)

The Kite SDK makes it easy to add print on demand functionality to your app.

Harness our worldwide print and distribution network. We'll take care of all the tricky printing and postage stuff for you!

To get started, you will need to have a free Kite developer account. Go to [kite.ly](https://www.kite.ly) to sign up for free.

## Products

Use our SDK to unlock hidden revenue streams and add value for your users. *In under ten minutes* you could be selling:

- Magnets
- Polaroid Style Prints
- Square Prints
- Postcards
- Frames
- A4 (invoices, letters, etc)
- Large Format Posters (A3, A2, A1)
- Square and Round Stickers
- T-Shirts & other Apparel
- Phone Cases
- Photo books
- New products being added monthly

## Features
- Print a wide variety of [products](#products) on demand
- Dynamic & realtime control over the pricing of products in your app pricing using our web [Developer Dashboard](https://www.kite.ly)
- Revenue & order volume analytics available in the web dashboard
- Review, refund or reprint any order within the web dashboard
- Localized currency support
- No server infrastructure required. We can handle everything for you from processing payments to printing & postage
- Your branding not ours. You can create your own custom checkout & payment UI or customize ours

## Requirements

* Xcode 10.2
* iOS 10.0+ target deployment

## Installation

### CocoaPods

If you're using [CocoaPods](http://cocoapods.org) just add the following to your Podfile:

```ruby
pod "Kite-Print-SDK"
```

You can also provide your own photo source (for example from within your app or a custom back end). Please read the documentation [here](Kite-SDK/docs/custom_photo_sources.md).


You can find example projects for [Swift](https://github.com/OceanLabs/Example-Kite-iOS-Cocoapods) and [Objective-C](https://github.com/OceanLabs/Example-Kite-iOS-Cocoapods-Objc).

### Quick Integration
We really mean it when we say integration can be done in minutes.
* **Step 1:** Import the SDK

Objective-C:
```obj-c
#import <OLKitePrintSDK.h>
```
Swift:
```swift
import KiteSDK
```
* **Step 2:** Set the API key and the environment:

Objective-C:
```obj-c
[OLKitePrintSDK setAPIKey:@"YOUR_API_KEY" withEnvironment:OLKitePrintSDKEnvironmentLive]; //Or OLKitePrintSDKEnvironmentSandbox for testing
```
Swift:
```swift
OLKitePrintSDK.setAPIKey("YOUR_API_KEY", with: .live) //Or .sandbox for testing
```
* **Step 3:** Set up 3D Secure 2 payments:

Read about SCA (Strong Customer Authentication) requirements [here](https://stripe.com/gb/guides/strong-customer-authentication).

Add a URL Scheme to your info.plist:
```
<key>CFBundleURLTypes</key>
<array>
	<dict>
		<key>CFBundleURLSchemes</key>
		<array>
			<string>myappname123456</string>
		</array>
	</dict>
</array>
```

Pass the URL Scheme you defined to the Kite SDK:

Objective-C:
```obj-c
[OLKitePrintSDK setUrlScheme:@"myappname123456"];
```
Swift:
```swift
OLKitePrintSDK.urlScheme = "myappname123456"
```

Implement the following method in your app delegate:

Objective-C
```obj-c
- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
	return [OLKitePrintSDK handleUrlCallBack:url];   
}
```
Swift:
```swift
func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
   	return OLKitePrintSDK.handleUrlCallBack(with: url)
}
```
* **Step 4:** Create and present Kite:

Objective-C:
```obj-c
OLKiteViewController *vc = [[OLKiteViewController alloc] initWithAssets:@[[OLAsset assetWithURL:[NSURL URLWithString:@"https://psps.s3.amazonaws.com/sdk_static/4.jpg"]]]];
[self presentViewController:vc animated:YES completion:NULL];
```
Swift:
```swift
let kiteViewController = OLKiteViewController.init(assets: [OLAsset(url: URL(string: "http://psps.s3.amazonaws.com/sdk_static/4.jpg"))])
present(kiteViewController!, animated: true, completion: nil)
```
* **Step 5:**: 🎉Profit🎉

💰💵💶💷💴

### iOS Security (ATS)

iOS includes a security feature called App Transport Security. In order to connect to the Kite servers you will need to add some exceptions to your project's info plist file. We need to add forward secrecy exceptions for Amazon S3 (which Kite uses) and PayPal (optional). The following is what you need to copy your app's info plist:

```
	<key>NSAppTransportSecurity</key>
	<dict>
		<key>NSExceptionDomains</key>
		<dict>
			<key>paypal.com</key>
			<dict>
				<key>NSExceptionRequiresForwardSecrecy</key>
				<false/>
				<key>NSIncludesSubdomains</key>
				<true/>
			</dict>
			<key>amazonaws.com</key>
			<dict>
				<key>NSExceptionRequiresForwardSecrecy</key>
				<false/>
				<key>NSIncludesSubdomains</key>
				<true/>
			</dict>
		</dict>
	</dict>
```

There are a few more entries to add if you opt for Facebook and Instagram integration as mentioned above. More info [here](Kite-SDK/docs/social_photo_sources.md).

## Use Cases

The Print SDK supports two primary use cases: **Kite Print Shop Experience**, and **Custom User Experience**.

### Kite Print Shop User Experience

![Kite](Kite-SDK/docs/print-shop1.jpg)

The Kite SDK includes a robust product selection, photo editing and payment experience that's proven to convert well with users. It can take care of everything for you, no need to spend time building any user interfaces.

This is the quickest approach to integration and perfect if you don't want to spend a great deal of time building a custom experience. You can be up & running within minutes!

To use our Print Shop experience:

1. [Create and present (or push) an `OLKiteViewController`](Kite-SDK/docs/print_shop.md) passing it an array of photos, we'll do the rest.
2. [Register your payment details](https://www.kite.ly/accounts/billing/) with us so that we can pay you when your users place orders


### Custom User Experience
You can build your own UI if you don't want to use or customize the provided Print Shop experience. You can still use the Print SDK to handle the print order creation and submission:

1. [Create print jobs](Kite-SDK/docs/create_print_jobs.md) representing the product(s) you wish to have printed and posted
2. [Checkout](Kite-SDK/docs/entry_points.md#launching-directly-to-checkout) for the order and submit it to our servers for printing and posting

## Credentials & Environments
Your mobile app integration requires different API Keys values for each environment: Live and Test (Sandbox).

You can find these Kite API credentials under the [Credentials](https://www.kite.ly/accounts/credentials/) section of the development dashboard.

### Sandbox

Your Sandbox API Key can be used to submit test print orders to our servers. These orders will not be printed and posted but will allow you to integrate the Print SDK into your app without incurring cost. During development and testing you'll primarily want to be using the sandbox environment to avoid moving real money around. To test the sandbox payment you can use your own PayPal sandbox account or contact us at hello@kite.ly

When you're ready to test the end to end printing and postage process; and before you submit your app to the App Store, you'll need to swap in your live API key.

### Live

Your Live API Key is used to submit print orders to our servers that will be printed and posted to the recipient specified. Live orders cost real money. This cost typically passed on to your end user (although this doesn't have to be the case if you want to cover it yourself).

Logging in to our [Developer Dashboard](https://www.kite.ly) allow's you to dynamically change the end user price i.e. the revenue you want to make on every order. Payment in several currencies is supported so that you can easily localize prices for your users. The dashboard also provides an overview of print order volume and the money you're making.

## ApplePay
See our [ApplePay setup documentation](Kite-SDK/docs/applepay.md) if you want to enable checkout via ApplePay.

## SDK Entry Points
Depending on your use case you might want to launch to a specific product, or even bypass the product selection/creation process entirely and jump straight to the checkout/payment journey. See our [SDK entry point documentation](Kite-SDK/docs/entry_points.md) for more details.

## Documentation

* These docs in the SDK, which include an overview of usage, step-by-step integration instructions, and sample code
* The sample app included in this SDK
* Header files are thoroughly documented; refer to them as needed for extra details about any given property or parameter
* The [Kite Print API & SDK Developer Docs](https://www.kite.ly/docs/1.1/), which cover error codes and optional server-side integration instructions

## Print API
We also have a [REST print API](https://www.kite.ly/docs/1.1/) for those who prefer to invent wheels :)

## Migration from older Kite SDK versions
Please see the [Migration Documentation](Kite-SDK/docs/migration.md) to migrate to newer versions

## Open Source Acknowledgements
The iOS Print SDK uses software created by the Open Source community, you can find a full list of acknowledgements [here](https://kite.uservoice.com/knowledgebase/articles/1141681-open-source).

## License
Kite iOS Print SDK is available under a modified MIT license. See the [LICENSE](Kite-SDK/LICENSE) file for more info.
