# Use Kite SDK in your Unity apps and games

## Installation & Usage

 - Download Kite SDK from the Unity Asset Store
 - When you want to show the Kite Shop, call this method from your C# code:
 ```cs
 KiteSDK.PresentKiteShop("YOUR KITE API KEY", KiteSDK.KiteEnvironment.Live);
 ```
 Substituting 'YOUR KITE API KEY' with your API key and 'Live' with 'Test' to run Kite in the Test payment environment. You can find these Kite API credentials under the [Credentials](https://www.kite.ly/accounts/credentials/) section of the development dashboard.
 - Make sure your Target minimum iOS Version is set to 8.0 or above in the Player Settings in Unity.
 - When Unity builds the Xcode project, please add the KiteSDK.framework to the Embedded Binaries section which is located on the General tab of the project settings.
![Add Kite.framework to Embedded Binaries ](add_framework.gif)
- Click on the Info tab of the project settings, and add a new entry with "NSPhotoLibraryUsageDescription" on the left and "Allow access to your device’s photo library to customize products with your own photos!" on the right.

This has been tested to work on Unity 5.5
