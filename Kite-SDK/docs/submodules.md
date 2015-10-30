Installing the Kite Print SDK as a Git Submodule
==============

This document describes the installation process for getting the Kite SDK installed into an iOS project built using Xcode 7.x using git submodules.

Installation via CocoaPods
--------
The recommended installation mechanism for the SDK is via CocoaPods. CocoaPods is an Objective-C library dependency manager that streamlines the process of installing, configuring, and updating third-party libraries.

Please consult the [CocoaPods install guide](https://github.com/OceanLabs/iOS-Print-SDK#cocoapods) if you wish to utilize CocoaPods to install the SDK.

You can learn more about CocoaPods at the website: [http://cocoapods.org/](http://cocoapods.org/)


Adding the Submodule
-----------
If you do not wish to use CocoaPods then the secondary recommendation is to use a submodule. This allows you to easily track updates using standard Git commands. The first step to installation is to add the submodule to your project:

```
$ cd /path/to/YourApplication
# If this is a new project, initialize git...
$ git init
$ git submodule add https://github.com/OceanLabs/iOS-Print-SDK.git
$ git submodule update --init --recursive
```

Adding the SDK to Your Project
-----------
Now that you have cloned the Kite SDK into your project, you need to let your project know about the Kite SDK by adding it to your project Workspace. Find the `KitePrintSDK.xcodeproj` file inside of the cloned iOS-Print-SDK project directory and drag it into the Project Navigator (`⌘+1`).

![Add Project Dependency](add_dependency.gif)