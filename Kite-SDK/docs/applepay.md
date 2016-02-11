Setting up ApplePay
==============

This document describes the integration process for getting ApplePay configured with the Kite SDK.

To submit an app with Apple Pay to the App Store, you need to register a merchant ID with Apple and add the necessary entitlements to your app. This article will help you with every step of the setup process.

Prerequisites
--------

To begin, you'll need a newer iOS device (iPhone 6 or 6+, iPad Air 2, or iPad mini 3) running iOS 8.1 or later, as well as a Mac with Xcode 6.1 or newer installed. You can install or upgrade Xcode in the Mac App Store.

You'll also need an Apple Developer Account, as well as a membership in the iOS Developer Program. If you need to become a member, you can do so [here](httpx://developer.apple.com).

Registering for an Apple Merchant ID
--------

First, you'll need to obtain an Apple Merchant ID. Start by heading to the Registering a Merchant ID page on the Apple Developer website.

Fill out the form with a description and identifier. Your description is for your own records and can be modified in the future (we recommend just using the name of your app). The idenfitier must be unique (across all apps, not just yours) and can't be changed later (although you can always make another one). We recommend using `merchant.com.{your_app_name}`. Save this value for later use when developing your app.

Creating a new Apple Pay certificate
--------

You need to include a certificate in your app to encrypt outgoing payment data. This involves 3 steps:

1. Obtain a CSR (certificate signing request) file from Kite
2. Use this CSR to generate a certificate through Apple
3. Send the certificate back to Kite, in return we'll send you a .certSigningRequest file

Next, back on the Apple Developer site, visit the Add iOS Certificate page. Choose "Apple Pay Certificate" from the options and click "Continue". On the next page, choose the Merchant ID you created earlier from the dropdown and continue.

The next page explains that you can obtain a CSR from your Payment Provider (which at this point you've done already) or create one manually. Important note: you must use the CSR provided by Kite - creating your own won't work. So ignore the directions at the bottom of this page and continue on.

You'll be prompted to upload a .certSigningRequest file you received from us. Choose the file you received from Kite and continue. You'll see a success page, with an option to download your certificate. Download it. Finally, send this .cer file to Kite.


SDK Integration
--------

Finally 

```obj-c
#ifdef OL_KITE_OFFER_APPLE_PAY
    [OLKitePrintSDK setApplePayMerchantID:@"REPLACE WITH THE MERCHANT ID YOU USED ABOVE"];
    [OLKitePrintSDK setApplePayPayToString:@"REPLACE WITH YOUR APP NAME"];
#endif
```

Finally ensure ApplePay is enabled in the Capabilities tab of your app build target. 

Note that if you integrated the SDK by any means other than CocoaPods you'll need to define the `OL_KITE_OFFER_APPLE_PAY=1` preprocessor macro in the build settings of your application.

