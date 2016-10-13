# From versions 5.x.x or earlier

## Installation

### CocoaPods
 All payment and social subspecs are deprecated. If you need any of the following please install them separately.
#### PayPal:
 ```ruby
 pod 'PayPal-iOS-SDK/Core', '~> 2.12.5'
 ```
#### Apple Pay:
 ```ruby
 pod 'Stripe', '~> 8.0.6'
 ```
#### Facebook:
 ```ruby
 pod 'FBSDKCoreKit', '~> 4.16.0'
 pod 'FBSDKLoginKit', '~> 4.16.0'
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
 * We have removed the static KiteSDK.a library with a dynamic KiteSDK.framework. This includes all assets so no need to have them in the Copy Resources build phase anymore. Please remove the static library and add KiteSDK.framework to the embedded libraries section of the General tab of your target.
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
