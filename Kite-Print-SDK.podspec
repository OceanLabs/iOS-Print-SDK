Pod::Spec.new do |spec|
  spec.name   = 'Kite-Print-SDK'
  spec.version          = '6.0.0'
  spec.license    = { :type => 'MIT', :file => 'Kite-SDK/LICENSE' }
  spec.homepage         = 'https://github.com/OceanLabs/iOS-Print-SDK'
  spec.authors          = {'Deon Botha' => 'deon@oceanlabs.co'}
  spec.summary          = "Add physical print functionality in minutes! Print magnets, photo prints, postcards, polaroids, posters, stickers, canvas', phone cases, etc"
  spec.source           = {:git => 'https://github.com/OceanLabs/iOS-Print-SDK.git', :tag => spec.version.to_s }
  spec.source_files     = ['Kite-SDK/PSPrintSDK/OL*.{h,m}', 'Kite-SDK/PSPrintSDK/CardIO*.h', 'Kite-SDK/PSPrintSDK/RMImageCropper/*.{h,m}', 'Kite-SDK/PSPrintSDK/Categories/*.{h,m}', 'Kite-SDK/PSPrintSDK/LXReorderableCollectionViewFlowLayout.{h,m}', 'Kite-SDK/PSPrintSDK/QREncoder/*.{h,m,c}']
  spec.resources        = ['Kite-SDK/PSPrintSDK/KitePrintSDK.xcassets', 'Kite-SDK/PSPrintSDK/*.lproj', 'Kite-SDK/PSPrintSDK/Base.lproj/OLEditingToolsView.xib', 'Kite-SDK/PSPrintSDK/kite_corrupt.jpg', 'Kite-SDK/PSPrintSDK/Base.lproj/OLKiteStoryboard.storyboard', 'Kite-SDK/PSPrintSDK/OLProgressHUD.bundle']
  spec.requires_arc = true
  spec.platform   = :ios, '8.0'
  spec.social_media_url = 'https://twitter.com/dbotha'

  spec.subspec 'Lite' do |lite|
    lite.source_files     = ['Kite-SDK/PSPrintSDK/OL*.{h,m}']
    #deprecated
  end

  spec.subspec 'PayPal' do |paypal|
    paypal.dependency 'PayPal-iOS-SDK/Core', '~> 2.12.6'
    #deprecated Please install separately: pod 'PayPal-iOS-SDK/Core', '~> 2.12.6'
  end

  spec.subspec 'ApplePay' do |apple|
    apple.dependency    'Stripe', '8.0.6'
    #deprecated Please install separately: pod 'Stripe', '8.0.6'
  end

  spec.subspec 'Facebook' do |facebook|
    facebook.dependency 'FBSDKCoreKit', '~> 4.11.0'
    facebook.dependency 'FBSDKLoginKit', '~> 4.11.0'
    #deprecated Please install separately: pod 'FBSDKCoreKit', '~> 4.11.0' 
    #and:                                  pod 'FBSDKLoginKit', '~> 4.11.0'
  end

  spec.subspec 'Instagram' do |instagram|
    instagram.source_files     = ['Kite-SDK/PSPrintSDK/OL*.{h,m}']
    #deprecated
  end

  spec.subspec 'ImageProviders' do |imageproviders|
    imageproviders.source_files     = ['Kite-SDK/PSPrintSDK/OL*.{h,m}']
    #deprecated
  end

end
