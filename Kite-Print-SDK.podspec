Pod::Spec.new do |spec|
  spec.name                = 'Kite-Print-SDK'
  spec.version             = '8.2.1'
  spec.license             = { :type => 'MIT', :file => 'Kite-SDK/LICENSE' }
  spec.homepage            = 'https://github.com/OceanLabs/iOS-Print-SDK'
  spec.authors             = {'Deon Botha' => 'deon@oceanlabs.co'}
  spec.summary             = "Add physical print functionality in minutes! Print magnets, photo prints, postcards, polaroids, posters, stickers, canvas', phone cases, photo books, etc"
  spec.source              = {:git => 'https://github.com/OceanLabs/iOS-Print-SDK.git', :tag => "v" + spec.version.to_s }
  spec.requires_arc        = true
  spec.platform            = :ios, '10.0'
  spec.swift_version       = '5.0'
  spec.social_media_url    = 'https://twitter.com/dbotha'
  spec.module_name         = 'KiteSDK'
  spec.default_subspec     = 'Core'
  spec.dependency "Photobook", "~> 2.1.2"

  spec.subspec 'Core' do |core|
    core.source_files      = ['Kite-SDK/PSPrintSDK/OL*.{h,m}', 'Kite-SDK/PSPrintSDK/RMImageCropper/*.{h,m}', 'Kite-SDK/PSPrintSDK/Categories/*.{h,m}']
    core.resources         = ['Kite-SDK/PSPrintSDK/OLKiteLocalizationResources.bundle']
    core.resource_bundles  = { 'OLKiteResources' => ['Kite-SDK/PSPrintSDK/KitePrintSDK.xcassets', 'Kite-SDK/PSPrintSDK/Base.lproj/OLEditingToolsView.xib', 'Kite-SDK/PSPrintSDK/Base.lproj/OLHintView.xib', 'Kite-SDK/PSPrintSDK/kite_corrupt.jpg', 'Kite-SDK/PSPrintSDK/Base.lproj/OLKiteStoryboard.storyboard', 'Kite-SDK/PSPrintSDK/mug.scn'] }
  end

  spec.subspec 'Lite' do |lite|
    lite.source_files      = ['Kite-SDK/PSPrintSDK/OL*.{h,m}', 'Kite-SDK/PSPrintSDK/RMImageCropper/*.{h,m}', 'Kite-SDK/PSPrintSDK/Categories/*.{h,m}']
    lite.resources         = ['Kite-SDK/PSPrintSDK/OLKiteLocalizationResources.bundle']
    lite.resource_bundles  = { 'OLKiteResources' => ['Kite-SDK/PSPrintSDK/KitePrintSDK.xcassets', 'Kite-SDK/PSPrintSDK/Base.lproj/OLEditingToolsView.xib', 'Kite-SDK/PSPrintSDK/Base.lproj/OLHintView.xib', 'Kite-SDK/PSPrintSDK/kite_corrupt.jpg', 'Kite-SDK/PSPrintSDK/Base.lproj/OLKiteStoryboard.storyboard'] }
    lite.xcconfig =  { 'OTHER_CFLAGS' => '$(inherited) -DOL_KITE_LITE' }
  end

end
