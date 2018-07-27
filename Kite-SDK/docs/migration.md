# From version 6.x.x

## Installation

### CocoaPods
- Deprecated subspecs have been removed
- Stripe is now a mandatory dependency and the latest version is supported.

### Carthage Support has been removed
- Please use CocoaPods instead

### Git Submodule
- No longer supported. Please install using Cocoapods or Carthage

 ## API Changes
 - Deprecated methods have been removed.
 - `[OLKiteViewController initWithPrintOrder:]` has been removed. Instead please use `[OLKitePrintSDK checkoutViewControllerWithPrintJobs:]` which returns a UIViewController which you can present.
 - Setting a promo code, the user's email or phone for faster checkout can be done via the appropriate methods in `OLKitePrintSDK`
 - Removed some checkout-related properties on `OLKiteViewController`
 - Removed Order history and related APIs
 - Removed OLPromoView
 - Removed all level-2 analytics events and a few others. Some of the remaining analytics events have changed.
 - Local analytics events are now notified on the delegate of OLAnalytics.sharedInstance instead of the delegate of the OLKiteViewController.

 ## Customization
 - Fully custom checkout is no longer supported with this SDK. You *must* use the provided Checkout experience or implement your own using the Kite REST APIs.
 - Visual customization of the Photobook and Checkout screens are not supported.
 

# From versions 5.x.x or earlier

## Installation

### CocoaPods
 All payment and social subspecs are deprecated. If you need any of the following please install them separately.
#### PayPal:
 ```ruby
 pod 'PayPal-iOS-SDK/Core', '~> 2.18.0'
 ```
#### Apple Pay:
 ```ruby
 pod 'Stripe', '~> 10.1.0'
 ```
#### Facebook:
 ```ruby
 pod 'FBSDKCoreKit', '~> 4.27.1'
 pod 'FBSDKLoginKit', '~> 4.27.1'
 ```

#### Instagram:
 Nothing to install, just setting up the Instagram keys will do the trick. See the [documentation](Kite-SDK/docs/social_photo_sources.md) for details.

#### Custom Image Source
 Nothing to install, but please see the API changes section below or the [documentation](Kite-SDK/docs/custom_photo_sources.md) for details.

#### Swift module name
 Change your import statement to:
```swift
import KiteSDK
```

### Git Submodule
 * We have replaced the static KiteSDK.a library with a dynamic KiteSDK.framework. This includes all assets so no need to have them in the Copy Resources build phase anymore. Please remove the static library and add KiteSDK.framework to the embedded libraries section of the General tab of your target.
 * All submodule dependencies have been removed. Please install the PayPal dependency separately (linking with the Kite SDK is not needed).

 ## API Changes

 * OLKiteDelegate
 Many of the delegate calls that were essentially options were moved to `OLKiteViewController` properties. Please note that some of these properties are the reverse of what their delegate predecessors were. For example, a shouldShowX delegate method might have changed to a hideX property.

 * OLPrintPhoto
 Removed, use `OLAsset`

 * Custom image sources (assets)
 `addCustomPhotoProviderWithCollections:name:icon:` now expects an array OLImagePickerProviderCollection

 * Custom image sources (ViewController)
 Your ViewController needs to adopt the `OLCustomPickerController` protocol. The delegate you need to notify is an `id<OLCustomImagePickerViewControllerDelegate>` object. See the [documentation](Kite-SDK/docs/custom_photo_sources.md) for details.
