### 6.5.3
- Handle HP SDK delegate calls internally if OLKiteDelegate doesn’t handle them.

### 6.5.2
- Fixed xib file not being including in the resource bundle when installing via Cocoapods.

### 6.5.1
- Fixed: Submitting orders without UI.
- Fixed: Not showing error when template sync fails.

## 6.5.0
- Enabled T-Shirts and Hoodies again
- Improved: Visuals when flipping apparel
- Improved: Loading time
- Improved French, German, Spanish localization
- Added: Italian localization
- Fixed: Pricing issue when adding multiples of a product

## 6.4.0
- New Product: Full Sublimation T-Shirts
- Added: An order history screen that you can present outside of the Kite SDK
- Added: Swipe to delete credit card
- Added: German, Danish translations
- Improved: French and Spanish translations
- Improved: Analytics
- Improved: Text on photo controls are always visible now
- Improved: Product/Photo editing control sizes
- Improved: Performance on the image picker screen
- Fixed: Visual glitches on the image picker screen
- Fixed: Memory leak when adding filters
- Fixed: Edits not being saved on images in some circumstances
- Fixed: Product cover photos used the top level images instead
- Fixed: Editing a basket item could cause a crash
- Fixed: Showed text entry field on product that didn't support it

## 6.3.0
- Added fr and es localizations

## 6.2.0
- New products: Apparel
- New image editing tool: Filters
- Ad-like promo banner with product previews using the users’ images to entice them to launch Kite
- Bug fixes and performance improvements

### 6.1.16
- Fixed crashes

### 6.1.15
- Fixed issue where a selected photo would remain after deselecting it

### 6.1.14
- Workaround for Xcode 8.0 bug.
- Remove deselected photos

### 6.1.13
- Fixed issues with collage poster products

### 6.1.12
- Fixes for custom image pickers

### 6.1.11
- Disable 3D touch on frames/calendars

### 6.1.10
- Minor fixes for custom image pickers

### 6.1.9
- Fixed crashing issue with custom image picker

### 6.1.8
- Set properties on custom view controller.
- Fixed issues with maximum photos and duplicated photos from custom view controllers
- Don’t clear added text when replacing assets

### 6.1.7
- Design tweak to the image picker when using an exclusive custom view controller image picker.

### 6.1.6
- Fixed crashes and issues with fast product switching from the editing screen

### 6.1.5
- Fixed crashes with calendars

### 6.1.4
- Added a couple options for custom image pickers

### 6.1.3
- Fixed address, email and phone validation

### 6.1.2
- Fixed Apple Pay address validation

### 6.1.1
- Exposed API for the print order history and added documentation for it.

## 6.1.0
- Added support for calendar products
- Added support for invitation products
- Added support for switching products from the edit screen
- Added support for the HP Print SDK

# 6.0.0
- New image picker
- New UI for single-image products, e.g. Phone Cases
- New image editing tool: text on photo
- Preliminary support for new products
- Removed all dependencies
- Support for installing via Carthage
- Improved interoperability with Swift
- Many bug fixes, performance and memory optimizations
- Dropped support for iOS 7.

### 5.4.10
- Fixed downloads on iOS 8.

### 5.4.9
- Fixed Apple Pay country issue

### 5.4.8
- Fixed PayPal

### 5.4.7
- Added shipping information to PayPal

### 5.4.6
- Internal

### 5.4.5
- Fixed a crash when building with Xcode 8
- More reliable asset uploading

### 5.4.4
- Removed all localization files

### 5.4.3
- Added a way to access the basket order

### 5.4.2
- Fix for custom theme

### 5.4.1
- Fix for custom theme

## 5.4.0
- Update Stripe dependency and use Contacts framework when building with Xcode 8.

### 5.3.10
- Small update to a custom theme
