Custom Photo Sources
==============

In addition to the device's Photo Library/Camera Roll and the optional Facebook and Instagram photo pickers you can provide your own photo sources to be available in the app. One example use of this would be to offer a list of stock photography options to your users.

Installation
--------
If you are using CocoaPods, install the `ImageProviders` subspec:
```ruby
pod 'Kite-Print-SDK/ImageProviders'
```

Usage
--------

There are 2 ways to offer custom photo sources:

1. You can just provide the collection/albums and the photos within those collections, and the Kite SDK will present them in a View Controller similar to the one that handles the Camera Roll pictures. The stock photography is a good fit for this method. The sample app provides an example of this method.

  Your photo object class should conform to the `KITAssetDataSource` protocol and your album class should conform to the `KITAssetCollectionDataSource` protocol. Your `KITAssetDataSource` should handle fetching the photos (if they are remote) and providing low-resolution thumbnail versions when asked.

  Tell Kite SDK to use your collections using the following method of `OLKiteViewController`
  ```obj-c
  - (void)addCustomPhotoProviderWithCollections:(NSArray <id<KITAssetCollectionDataSource>>*_Nonnull)collections name:(NSString *_Nonnull)name icon:(UIImage *_Nullable)image;
  ```

  Note that you can call this as many times you like, and your sources will show up along side the standard sources. If for example you have stock photography for Cats and Dogs, you may call the above method twice so that your user will see the following options: Camera Roll, Facebook, Instagram, Cats, Dogs. Or you may want Cats and Dogs to be 2 collections/albums of a single "Animals" source.

2. You can provide your own view controller to be used as a photo source. This involves quite a bit more work on your side but allows for a lot more control. If for example you have invested a lot of effort in efficient caching and navigation of large quantities of photos this method is probably a better fit for you. The photo objects that are returned to the Kite SDK should still conform to the `KITAssetDataSource` protocol.

  Tell Kite SDK to use your View Controller using the following method of `OLKiteViewController`
  ```obj-c
  - (void)addCustomPhotoProviderWithViewController:(UIViewController<KITCustomAssetPickerController> *_Nonnull)vc name:(NSString *_Nonnull)name icon:(UIImage *_Nullable)icon;
  ```

  Like the first method, you can call this method as many times as you like, and multiple photo sources will show up next to the standard ones.
