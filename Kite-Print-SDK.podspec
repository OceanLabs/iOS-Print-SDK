Pod::Spec.new do |spec|
  spec.name                = 'Kite-Print-SDK'
  spec.version             = '6.6.0'
  spec.license             = { :type => 'MIT', :file => 'Kite-SDK/LICENSE' }
  spec.homepage            = 'https://github.com/OceanLabs/iOS-Print-SDK'
  spec.authors             = {'Deon Botha' => 'deon@oceanlabs.co'}
  spec.summary             = "Add physical print functionality in minutes! Print magnets, photo prints, postcards, polaroids, posters, stickers, canvas', phone cases, etc"
  spec.public_header_files = ['Kite-SDK/PSPrintSDK/OLOLAddress.h', 'Kite-SDK/PSPrintSDK/OLAddress+AddressBook.h ', 'Kite-SDK/PSPrintSDK/OLAddressPickerController.h ', 'Kite-SDK/PSPrintSDK/OLAddressSearchRequest.h ', 'Kite-SDK/PSPrintSDK/OLAnalytics.h ', 'Kite-SDK/PSPrintSDK/OLAsset.h ', 'Kite-SDK/PSPrintSDK/OLAssetUploadRequest.h ', 'Kite-SDK/PSPrintSDK/OLCheckoutDelegate.h ', 'Kite-SDK/PSPrintSDK/OLCheckoutViewController.h ', 'Kite-SDK/PSPrintSDK/OLConstants.h ', 'Kite-SDK/PSPrintSDK/OLCountry.h ', 'Kite-SDK/PSPrintSDK/OLCountryPickerController.h ', 'Kite-SDK/PSPrintSDK/OLFulfilmentItem.h ', 'Kite-SDK/PSPrintSDK/OLImagePickerProviderCollection.h ', 'Kite-SDK/PSPrintSDK/OLKitePrintSDK.h ', 'Kite-SDK/PSPrintSDK/OLKiteViewController.h ', 'Kite-SDK/PSPrintSDK/OLNavigationController.h ', 'Kite-SDK/PSPrintSDK/OLPageLayout.h ', 'Kite-SDK/PSPrintSDK/OLPayPalCard.h ', 'Kite-SDK/PSPrintSDK/OLPrintEnvironment.h ', 'Kite-SDK/PSPrintSDK/OLPrintJob.h ', 'Kite-SDK/PSPrintSDK/OLPrintOrder.h ', 'Kite-SDK/PSPrintSDK/OLPrintOrder+History.h ', 'Kite-SDK/PSPrintSDK/OLPrintOrderCost.h ', 'Kite-SDK/PSPrintSDK/OLProduct.h ', 'Kite-SDK/PSPrintSDK/OLProductPrintJob.h ', 'Kite-SDK/PSPrintSDK/OLProductRepresentation.h ', 'Kite-SDK/PSPrintSDK/OLProductTemplate.h ', 'Kite-SDK/PSPrintSDK/OLProductTemplateOption.h ', 'Kite-SDK/PSPrintSDK/OLProductTemplateOptionChoice.h ', 'Kite-SDK/PSPrintSDK/OLPromoView.h ', 'Kite-SDK/PSPrintSDK/OLReceiptViewController.h ', 'Kite-SDK/PSPrintSDK/OLStripeCard.h ', 'Kite-SDK/PSPrintSDK/OLUpsellOffer.h ', 'Kite-SDK/PSPrintSDK/OLViewController.h']
  spec.source              = {:git => 'https://github.com/OceanLabs/iOS-Print-SDK.git', :tag => "v" + spec.version.to_s }
  spec.source_files        = ['Kite-SDK/PSPrintSDK/OL*.{h,m}', 'Kite-SDK/PSPrintSDK/CardIO*.h', 'Kite-SDK/PSPrintSDK/RMImageCropper/*.{h,m}', 'Kite-SDK/PSPrintSDK/Categories/*.{h,m}', 'Kite-SDK/PSPrintSDK/LXReorderableCollectionViewFlowLayout.{h,m}', 'Kite-SDK/PSPrintSDK/QREncoder/*.{h,m,c}']
  spec.resources           = ['Kite-SDK/PSPrintSDK/OLProgressHUD.bundle', 'Kite-SDK/PSPrintSDK/OLKiteLocalizationResources.bundle']
  spec.resource_bundles    = { 'OLKiteResources' => ['Kite-SDK/PSPrintSDK/KitePrintSDK.xcassets', 'Kite-SDK/PSPrintSDK/Base.lproj/OLEditingToolsView.xib', 'Kite-SDK/PSPrintSDK/Base.lproj/OLHintView.xib', 'Kite-SDK/PSPrintSDK/kite_corrupt.jpg', 'Kite-SDK/PSPrintSDK/Base.lproj/OLKiteStoryboard.storyboard', 'Kite-SDK/PSPrintSDK/mug.dae'] }
  spec.requires_arc        = true
  spec.platform            = :ios, '8.0'
  spec.social_media_url    = 'https://twitter.com/dbotha'
  spec.module_name         = 'KiteSDK'

  spec.subspec 'Lite' do |lite|
    lite.source_files     = ['Kite-SDK/PSPrintSDK/OL*.{h,m}', 'Kite-SDK/PSPrintSDK/CardIO*.h', 'Kite-SDK/PSPrintSDK/RMImageCropper/*.{h,m}', 'Kite-SDK/PSPrintSDK/Categories/*.{h,m}', 'Kite-SDK/PSPrintSDK/LXReorderableCollectionViewFlowLayout.{h,m}', 'Kite-SDK/PSPrintSDK/QREncoder/*.{h,m,c}']
    #deprecated
  end

  spec.subspec 'PayPal' do |paypal|
    paypal.source_files     = ['Kite-SDK/PSPrintSDK/OL*.{h,m}', 'Kite-SDK/PSPrintSDK/CardIO*.h', 'Kite-SDK/PSPrintSDK/RMImageCropper/*.{h,m}', 'Kite-SDK/PSPrintSDK/Categories/*.{h,m}', 'Kite-SDK/PSPrintSDK/LXReorderableCollectionViewFlowLayout.{h,m}', 'Kite-SDK/PSPrintSDK/QREncoder/*.{h,m,c}']
    #deprecated Please install separately: pod 'PayPal-iOS-SDK/Core', '~> 2.12.6'
  end

  spec.subspec 'ApplePay' do |apple|
    apple.source_files     = ['Kite-SDK/PSPrintSDK/OL*.{h,m}', 'Kite-SDK/PSPrintSDK/CardIO*.h', 'Kite-SDK/PSPrintSDK/RMImageCropper/*.{h,m}', 'Kite-SDK/PSPrintSDK/Categories/*.{h,m}', 'Kite-SDK/PSPrintSDK/LXReorderableCollectionViewFlowLayout.{h,m}', 'Kite-SDK/PSPrintSDK/QREncoder/*.{h,m,c}']
    #deprecated Please install separately: pod 'Stripe', '8.0.6'
  end

  spec.subspec 'Facebook' do |facebook|
    facebook.source_files     = ['Kite-SDK/PSPrintSDK/OL*.{h,m}', 'Kite-SDK/PSPrintSDK/CardIO*.h', 'Kite-SDK/PSPrintSDK/RMImageCropper/*.{h,m}', 'Kite-SDK/PSPrintSDK/Categories/*.{h,m}', 'Kite-SDK/PSPrintSDK/LXReorderableCollectionViewFlowLayout.{h,m}', 'Kite-SDK/PSPrintSDK/QREncoder/*.{h,m,c}']
    #deprecated Please install separately: pod 'FBSDKCoreKit', '~> 4.16.0' 
    #and:                                  pod 'FBSDKLoginKit', '~> 4.16.0'
  end

  spec.subspec 'Instagram' do |instagram|
    instagram.source_files     = ['Kite-SDK/PSPrintSDK/OL*.{h,m}', 'Kite-SDK/PSPrintSDK/CardIO*.h', 'Kite-SDK/PSPrintSDK/RMImageCropper/*.{h,m}', 'Kite-SDK/PSPrintSDK/Categories/*.{h,m}', 'Kite-SDK/PSPrintSDK/LXReorderableCollectionViewFlowLayout.{h,m}', 'Kite-SDK/PSPrintSDK/QREncoder/*.{h,m,c}']
    #deprecated
  end

  spec.subspec 'ImageProviders' do |imageproviders|
    imageproviders.source_files     = ['Kite-SDK/PSPrintSDK/OL*.{h,m}', 'Kite-SDK/PSPrintSDK/CardIO*.h', 'Kite-SDK/PSPrintSDK/RMImageCropper/*.{h,m}', 'Kite-SDK/PSPrintSDK/Categories/*.{h,m}', 'Kite-SDK/PSPrintSDK/LXReorderableCollectionViewFlowLayout.{h,m}', 'Kite-SDK/PSPrintSDK/QREncoder/*.{h,m,c}']
    #deprecated
  end

end
