//
//  Utils.swift
//  ApiRTCApp
//
//  Created by Aleksandr Khorobrykh on 31/10/2017.
//  Copyright © 2017 Apizee. All rights reserved.
//

import Foundation
import UIKit

extension String {
    
    func loc() -> String {
        return NSLocalizedString(self, comment: "")
    }
}

extension UIColor {
    
    class func hex(_ hex: String) -> UIColor {
        
        var cString = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if cString.hasPrefix("#") {
            cString.remove(at: cString.startIndex)
        }
        
        if cString.count != 6 {
            return UIColor.gray
        }
        
        var rgbValue: UInt32 = 0
        Scanner(string: cString).scanHexInt32(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}

extension NSObject {
    
    func observe(notif: String, selector: Selector) {
        
        NotificationCenter.default.addObserver(self, selector: selector, name: NSNotification.Name(rawValue: notif), object: nil)
    }
    
    func post(notif: String, object: Any? = nil) {
        
        NotificationCenter.default.post(NSNotification(name: NSNotification.Name(rawValue: notif), object: object) as Notification)
    }
    
    func removeObserver(name: String) {
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: name), object: nil)
    }
    
    func removeObserver() {
        
        NotificationCenter.default.removeObserver(self)
    }
}
