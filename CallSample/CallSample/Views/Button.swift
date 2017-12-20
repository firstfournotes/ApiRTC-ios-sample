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
    
    var image: UIImage!
    var nonActiveImage: UIImage?
    
    var isActive = false {
        didSet {
            switch isActive {
            case true:
                self.setImage(image, for: .normal)
            case false:
                if let nonActiveImage = nonActiveImage {
                    self.setImage(nonActiveImage, for: .normal)
                }
            }
        }
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
    
    init(image: UIImage, nonActiveImage: UIImage? = nil, bgColor: UIColor) {
        super.init(frame: .zero)
        self.bgColor = bgColor
        self.image = image
        self.nonActiveImage = nonActiveImage
        initUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initUI() {
        
        self.alpha = 0.7
        self.backgroundColor = bgColor
        self.setImage(image, for: .normal)
    }
}
