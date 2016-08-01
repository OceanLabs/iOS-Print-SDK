Pod::Spec.new do |spec|
  spec.name		= 'Kite-Print-SDK'
  spec.version         	= '5.2.7'
  spec.license 		= { :type => 'MIT', :file => 'Kite-SDK/LICENSE' }
  spec.homepage         = 'https://github.com/OceanLabs/iOS-Print-SDK'
  spec.authors          = {'Deon Botha' => 'deon@oceanlabs.co'}
  spec.summary          = "Add physical print functionality in minutes! Print magnets, photo prints, postcards, polaroids, posters, stickers, canvas', phone cases, etc"
  spec.source           = {:git => 'https://github.com/OceanLabs/iOS-Print-SDK.git', :tag => spec.version.to_s }
  spec.source_files     = ['Kite-SDK/PSPrintSDK/OL*.{h,m}', 'Kite-SDK/PSPrintSDK/CardIO*.h', 'Kite-SDK/PSPrintSDK/RMImageCropper/*.{h,m}', 'Kite-SDK/PSPrintSDK/Categories/*.{h,m}', 'Kite-SDK/PSPrintSDK/LXReorderableCollectionViewFlowLayout.{h,m}', 'Kite-SDK/PSPrintSDK/QREncoder/*.{h,m,c}']
  spec.resources        = ['Kite-SDK/PSPrintSDK/KitePrintSDK.xcassets', 'Kite-SDK/PSPrintSDK/*.lproj', 'Kite-SDK/PSPrintSDK/Base.lproj/OLEditingToolsView.xib', 'Kite-SDK/PSPrintSDK/kite_corrupt.jpg', 'Kite-SDK/PSPrintSDK/Base.lproj/OLKiteStoryboard.storyboard']
  spec.dependency	'SVProgressHUD', '~> 1.1.3'
  spec.dependency	'CSStickyHeaderFlowLayout', '~> 0.2.4'
  spec.dependency	'MPFlipViewController', '~> 0.0.2'
  spec.dependency	'TSMarkdownParser', '~> 1.0.17'
  spec.dependency 'DACircularProgress'
  spec.requires_arc	= true
  spec.platform		= :ios, '7.0'
  spec.social_media_url	= 'https://twitter.com/dbotha'
  spec.default_subspec = 'Lite'

  spec.subspec 'Lite' do |lite|
  #subspec for developers who don't want the third party PayPal, Stripe, Instagram, Facebook bloat
  end

  spec.subspec 'PayPal' do |paypal|
    paypal.xcconfig	=  { 'OTHER_CFLAGS' => '$(inherited) -DOL_KITE_OFFER_PAYPAL' }
    paypal.dependency	'PayPal-iOS-SDK/Core', '~> 2.12.6'
  end

  spec.subspec 'ApplePay' do |apple|
    apple.xcconfig	  =  { 'OTHER_CFLAGS' => '$(inherited) -DOL_KITE_OFFER_APPLE_PAY' }
    apple.dependency	  'Stripe', '5.1.4'
    apple.dependency	  'Stripe/ApplePay', '5.1.4'
  end

  spec.subspec 'Facebook' do |facebook|
    facebook.xcconfig =  { 'OTHER_CFLAGS' => '$(inherited) -DOL_KITE_OFFER_FACEBOOK' }
    facebook.dependency 'FacebookImagePicker'
  end

  spec.subspec 'Instagram' do |instagram|
    instagram.xcconfig =  { 'OTHER_CFLAGS' => '$(inherited) -DOL_KITE_OFFER_INSTAGRAM' }
    instagram.dependency 'InstagramImagePicker'
  end

  spec.subspec 'ImageProviders' do |imageproviders|
    imageproviders.xcconfig =  { 'OTHER_CFLAGS' => '$(inherited) -DOL_KITE_OFFER_CUSTOM_IMAGE_PROVIDERS' }
    imageproviders.dependency 'KITAssetsPickerController'
  end

end
