platform :ios, '8.0'
inhibit_all_warnings!

def shared_pods
    pod 'PayPal-iOS-SDK/Core', '~> 2.18.0'
    pod 'Stripe', '~> 10.1.0'
    pod 'FBSDKCoreKit', '~> 4.27.1'
    pod 'FBSDKLoginKit', '~> 4.27.1'
end

target 'KiteSDK-Demo' do
    shared_pods
end

target 'Kite-CI-Deploy' do
    shared_pods
    pod 'KITAssetsPickerController', :git => 'git@github.com:kkarayannis/KITAssetsPickerController.git'
end
