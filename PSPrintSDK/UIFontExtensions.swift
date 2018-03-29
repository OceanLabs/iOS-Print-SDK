//
//  UIFontExtensions.swift
//  Canon
//
//  Created by Konstadinos Karayannis on 22/03/2018.
//  Copyright © 2018 Ocean Labs. All rights reserved.
//

// Taken from: https://stackoverflow.com/a/32870919/3265861

import UIKit

public extension UIFont {
    
    @objc class public func loadAllFonts() {
        registerFontWithFilenameString(filenameString: "LeagueGothic-Regular.otf")
        registerFontWithFilenameString(filenameString: "OpenSans-Regular.ttf")
        registerFontWithFilenameString(filenameString: "Montserrat-Bold.ttf")
        registerFontWithFilenameString(filenameString: "Lora-Regular.ttf")
            // Add more font files here as required
    }
    
    static func registerFontWithFilenameString(filenameString: String) {
        guard let frameworkBundle = Bundle(identifier: "ly.kite.Photobook"),
        let pathForResourceString = frameworkBundle.path(forResource: filenameString, ofType: nil),
        let fontData = NSData(contentsOfFile: pathForResourceString),
            let dataProvider = CGDataProvider(data: fontData)
            else { return }
        
        guard let fontRef = CGFont(dataProvider) else { return }
        var errorRef: Unmanaged<CFError>? = nil
        
        if (CTFontManagerRegisterGraphicsFont(fontRef, &errorRef) == false) {
            NSLog("Failed to register font - register graphics font failed - this font may have already been registered in the main bundle.")
        }
        
    }
}
