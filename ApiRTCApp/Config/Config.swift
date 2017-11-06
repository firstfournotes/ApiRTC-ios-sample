//
//  Config.swift
//  ApiRTCApp
//
//  Created by Aleksandr Khorobrykh on 31/10/2017.
//  Copyright © 2017 Apizee. All rights reserved.
//

import UIKit

struct Config {

    static let apiKey = "myDemoApiKey_IOS_SDK"
    
    struct UI {
        static let screenSize = UIScreen.main.bounds.size
    }
    
    struct Color {
        static let darkGray = UIColor.hex("354B5D")
        static let lightGray = UIColor.hex("47637a")
        static let green = UIColor.hex("80dd58")
        static let red = UIColor.hex("CC3637")
    }
}
