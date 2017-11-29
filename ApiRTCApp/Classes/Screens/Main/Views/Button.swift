//
//  Button.swift
//  ApiRTCApp
//
//  Created by Aleksandr Khorobrykh on 28/11/2017.
//  Copyright © 2017 Apizee. All rights reserved.
//

import UIKit

class Button: UIButton {

    var bgColor: UIColor!
    
    init(image: UIImage, bgColor: UIColor) {
        super.init(frame: .zero)
        self.bgColor = bgColor
        initUI(image: image)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initUI(image: UIImage) {
        
        self.alpha = 0.7
        self.backgroundColor = bgColor
        self.setImage(image, for: .normal)
    }
    
    override var isHighlighted: Bool {
        didSet {
            switch isHighlighted {
            case true:
                self.backgroundColor = bgColor.withAlphaComponent(0.5)
            case false:
                self.backgroundColor = bgColor
            }
        }
    }
    
    override var isEnabled: Bool {
        didSet {
            switch isEnabled {
            case true:
                self.backgroundColor = bgColor
            case false:
                self.backgroundColor = Config.Color.lightGray
            }
        }
    }
}
