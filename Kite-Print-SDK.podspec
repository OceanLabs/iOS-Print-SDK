Pod::Spec.new do |spec|
  spec.name             = 'Kite-Print-SDK'
  spec.version          = '1.0.2'
  spec.license          =  :type => 'MIT' 
  spec.homepage         = 'https://github.com/OceanLabs/iOS-Print-SDK'
  spec.authors          = 'Deon Botha' => 'deon@oceanlabs.co'
  spec.summary          = 'Easily add print on demand functionality to your app. Print magnets, photo prints, postcards, polaroids, A4, etc.'
  spec.source           =  :git => 'https://github.com/OceanLabs/iOS-Print-SDK.git', :tag => '1.0.2' 
  spec.source_files     = ['PSPrintSDK/OL*.{h,m}', 'PSPrintSDK/CardIO*.h']
  spec.resources        = ['PSPrintSDK/KitePrintSDK.xcassets', '*.lproj']
  spec.dependency	'SDWebImage'
  spec.dependency	'SVProgressHUD'
  spec.dependency	'AFNetworking', '2.5.0'
  spec.dependency	'UICKeyChainStore', '~> 1.0.4' 
  spec.requires_arc     = true
  spec.social_media_url = 'https://twitter.com/dbotha'

  spec.subspec 'PayPal' do |paypal|
    paypal.xcconfig	=  { 'OTHER_CFLAGS' => '$(inherited) -DOL_KITE_OFFER_PAYPAL' }
    paypal.dependency 'PayPal-iOS-SDK', '~> 2.3.2'
  end

  spec.subspec 'ApplePay' do |apple|
    apple.xcconfig     =  { 'OTHER_CFLAGS' => '$(inherited) -DOL_KITE_OFFER_APPLE_PAY' }
    apple.dependency 'Stripe', '2.2.0'
    apple.dependency 'Stripe/ApplePay'
  end

end