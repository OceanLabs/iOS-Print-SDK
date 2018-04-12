Pod::Spec.new do |spec|
  spec.name                = 'Kite-Print-SDK'
  spec.version             = '6.8.7'
  spec.license             = { :type => 'MIT', :file => 'Kite-SDK/LICENSE' }
  spec.homepage            = 'https://github.com/OceanLabs/iOS-Print-SDK'
  spec.authors             = {'Deon Botha' => 'deon@oceanlabs.co'}
  spec.summary             = "Add physical print functionality in minutes! Print magnets, photo prints, postcards, polaroids, posters, stickers, canvas', phone cases, etc"
  spec.source              = {:git => 'https://github.com/OceanLabs/iOS-Print-SDK.git', :tag => "v" + spec.version.to_s }
  spec.requires_arc        = true
  spec.platform            = :ios, '8.0'
  spec.social_media_url    = 'https://twitter.com/dbotha'
  spec.module_name         = 'KiteSDK'
  spec.default_subspec     = 'Core'

  spec.subspec 'Core' do |core|
    core.source_files      = ['Kite-SDK/PSPrintSDK/OL*.{h,m}', 'Kite-SDK/PSPrintSDK/CardIO*.h', 'Kite-SDK/PSPrintSDK/RMImageCropper/*.{h,m}', 'Kite-SDK/PSPrintSDK/Categories/*.{h,m}', 'Kite-SDK/PSPrintSDK/LXReorderableCollectionViewFlowLayout.{h,m}', 'Kite-SDK/PSPrintSDK/QREncoder/*.{h,m,c}']
    core.resources         = ['Kite-SDK/PSPrintSDK/OLProgressHUD.bundle', 'Kite-SDK/PSPrintSDK/OLKiteLocalizationResources.bundle']
    core.resource_bundles  = { 'OLKiteResources' => ['Kite-SDK/PSPrintSDK/KitePrintSDK.xcassets', 'Kite-SDK/PSPrintSDK/Base.lproj/OLEditingToolsView.xib', 'Kite-SDK/PSPrintSDK/Base.lproj/OLHintView.xib', 'Kite-SDK/PSPrintSDK/kite_corrupt.jpg', 'Kite-SDK/PSPrintSDK/Base.lproj/OLKiteStoryboard.storyboard', 'Kite-SDK/PSPrintSDK/mug.scn'] }
  end

  spec.subspec 'Lite' do |lite|
    lite.source_files      = ['Kite-SDK/PSPrintSDK/OL*.{h,m}', 'Kite-SDK/PSPrintSDK/CardIO*.h', 'Kite-SDK/PSPrintSDK/RMImageCropper/*.{h,m}', 'Kite-SDK/PSPrintSDK/Categories/*.{h,m}', 'Kite-SDK/PSPrintSDK/LXReorderableCollectionViewFlowLayout.{h,m}', 'Kite-SDK/PSPrintSDK/QREncoder/*.{h,m,c}']
    lite.resources         = ['Kite-SDK/PSPrintSDK/OLProgressHUD.bundle', 'Kite-SDK/PSPrintSDK/OLKiteLocalizationResources.bundle']
    lite.resource_bundles  = { 'OLKiteResources' => ['Kite-SDK/PSPrintSDK/KitePrintSDK.xcassets', 'Kite-SDK/PSPrintSDK/Base.lproj/OLEditingToolsView.xib', 'Kite-SDK/PSPrintSDK/Base.lproj/OLHintView.xib', 'Kite-SDK/PSPrintSDK/kite_corrupt.jpg', 'Kite-SDK/PSPrintSDK/Base.lproj/OLKiteStoryboard.storyboard'] }
    lite.xcconfig =  { 'OTHER_CFLAGS' => '$(inherited) -DOL_KITE_LITE' }
  end

  spec.subspec 'PayPal' do |paypal|
    paypal.source_files      = ['Kite-SDK/PSPrintSDK/OL*.{h,m}', 'Kite-SDK/PSPrintSDK/CardIO*.h', 'Kite-SDK/PSPrintSDK/RMImageCropper/*.{h,m}', 'Kite-SDK/PSPrintSDK/Categories/*.{h,m}', 'Kite-SDK/PSPrintSDK/LXReorderableCollectionViewFlowLayout.{h,m}', 'Kite-SDK/PSPrintSDK/QREncoder/*.{h,m,c}']
    paypal.resources         = ['Kite-SDK/PSPrintSDK/OLProgressHUD.bundle', 'Kite-SDK/PSPrintSDK/OLKiteLocalizationResources.bundle']
    paypal.resource_bundles  = { 'OLKiteResources' => ['Kite-SDK/PSPrintSDK/KitePrintSDK.xcassets', 'Kite-SDK/PSPrintSDK/Base.lproj/OLEditingToolsView.xib', 'Kite-SDK/PSPrintSDK/Base.lproj/OLHintView.xib', 'Kite-SDK/PSPrintSDK/kite_corrupt.jpg', 'Kite-SDK/PSPrintSDK/Base.lproj/OLKiteStoryboard.storyboard', 'Kite-SDK/PSPrintSDK/mug.scn'] }
    #deprecated Please install separately: pod 'PayPal-iOS-SDK/Core', '~> 2.12.6'
  end

  spec.subspec 'ApplePay' do |apple|
    apple.source_files      = ['Kite-SDK/PSPrintSDK/OL*.{h,m}', 'Kite-SDK/PSPrintSDK/CardIO*.h', 'Kite-SDK/PSPrintSDK/RMImageCropper/*.{h,m}', 'Kite-SDK/PSPrintSDK/Categories/*.{h,m}', 'Kite-SDK/PSPrintSDK/LXReorderableCollectionViewFlowLayout.{h,m}', 'Kite-SDK/PSPrintSDK/QREncoder/*.{h,m,c}']
    apple.resources         = ['Kite-SDK/PSPrintSDK/OLProgressHUD.bundle', 'Kite-SDK/PSPrintSDK/OLKiteLocalizationResources.bundle']
    apple.resource_bundles  = { 'OLKiteResources' => ['Kite-SDK/PSPrintSDK/KitePrintSDK.xcassets', 'Kite-SDK/PSPrintSDK/Base.lproj/OLEditingToolsView.xib', 'Kite-SDK/PSPrintSDK/Base.lproj/OLHintView.xib', 'Kite-SDK/PSPrintSDK/kite_corrupt.jpg', 'Kite-SDK/PSPrintSDK/Base.lproj/OLKiteStoryboard.storyboard', 'Kite-SDK/PSPrintSDK/mug.scn'] }
    #deprecated Please install separately: pod 'Stripe', '8.0.6'
  end

  spec.subspec 'Facebook' do |facebook|
    facebook.source_files      = ['Kite-SDK/PSPrintSDK/OL*.{h,m}', 'Kite-SDK/PSPrintSDK/CardIO*.h', 'Kite-SDK/PSPrintSDK/RMImageCropper/*.{h,m}', 'Kite-SDK/PSPrintSDK/Categories/*.{h,m}', 'Kite-SDK/PSPrintSDK/LXReorderableCollectionViewFlowLayout.{h,m}', 'Kite-SDK/PSPrintSDK/QREncoder/*.{h,m,c}']
    facebook.resources         = ['Kite-SDK/PSPrintSDK/OLProgressHUD.bundle', 'Kite-SDK/PSPrintSDK/OLKiteLocalizationResources.bundle']
    facebook.resource_bundles  = { 'OLKiteResources' => ['Kite-SDK/PSPrintSDK/KitePrintSDK.xcassets', 'Kite-SDK/PSPrintSDK/Base.lproj/OLEditingToolsView.xib', 'Kite-SDK/PSPrintSDK/Base.lproj/OLHintView.xib', 'Kite-SDK/PSPrintSDK/kite_corrupt.jpg', 'Kite-SDK/PSPrintSDK/Base.lproj/OLKiteStoryboard.storyboard', 'Kite-SDK/PSPrintSDK/mug.scn'] }
    #deprecated Please install separately: pod 'FBSDKCoreKit', '~> 4.16.0' 
    #and:                                  pod 'FBSDKLoginKit', '~> 4.16.0'
  end

  spec.subspec 'Instagram' do |instagram|
    instagram.source_files      = ['Kite-SDK/PSPrintSDK/OL*.{h,m}', 'Kite-SDK/PSPrintSDK/CardIO*.h', 'Kite-SDK/PSPrintSDK/RMImageCropper/*.{h,m}', 'Kite-SDK/PSPrintSDK/Categories/*.{h,m}', 'Kite-SDK/PSPrintSDK/LXReorderableCollectionViewFlowLayout.{h,m}', 'Kite-SDK/PSPrintSDK/QREncoder/*.{h,m,c}']
    instagram.resources         = ['Kite-SDK/PSPrintSDK/OLProgressHUD.bundle', 'Kite-SDK/PSPrintSDK/OLKiteLocalizationResources.bundle']
    instagram.resource_bundles  = { 'OLKiteResources' => ['Kite-SDK/PSPrintSDK/KitePrintSDK.xcassets', 'Kite-SDK/PSPrintSDK/Base.lproj/OLEditingToolsView.xib', 'Kite-SDK/PSPrintSDK/Base.lproj/OLHintView.xib', 'Kite-SDK/PSPrintSDK/kite_corrupt.jpg', 'Kite-SDK/PSPrintSDK/Base.lproj/OLKiteStoryboard.storyboard', 'Kite-SDK/PSPrintSDK/mug.scn'] }
    #deprecated
  end

  spec.subspec 'ImageProviders' do |imageproviders|
    imageproviders.source_files      = ['Kite-SDK/PSPrintSDK/OL*.{h,m}', 'Kite-SDK/PSPrintSDK/CardIO*.h', 'Kite-SDK/PSPrintSDK/RMImageCropper/*.{h,m}', 'Kite-SDK/PSPrintSDK/Categories/*.{h,m}', 'Kite-SDK/PSPrintSDK/LXReorderableCollectionViewFlowLayout.{h,m}', 'Kite-SDK/PSPrintSDK/QREncoder/*.{h,m,c}']
    imageproviders.resources         = ['Kite-SDK/PSPrintSDK/OLProgressHUD.bundle', 'Kite-SDK/PSPrintSDK/OLKiteLocalizationResources.bundle']
    imageproviders.resource_bundles  = { 'OLKiteResources' => ['Kite-SDK/PSPrintSDK/KitePrintSDK.xcassets', 'Kite-SDK/PSPrintSDK/Base.lproj/OLEditingToolsView.xib', 'Kite-SDK/PSPrintSDK/Base.lproj/OLHintView.xib', 'Kite-SDK/PSPrintSDK/kite_corrupt.jpg', 'Kite-SDK/PSPrintSDK/Base.lproj/OLKiteStoryboard.storyboard', 'Kite-SDK/PSPrintSDK/mug.scn'] }
    #deprecated
  end
end
