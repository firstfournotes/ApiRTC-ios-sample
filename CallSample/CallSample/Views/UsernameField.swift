//
//  UsernameField.swift
//  ApiRTCApp
//
//  Created by Aleksandr Khorobrykh on 09/11/2017.
//  Copyright © 2017 Apizee. All rights reserved.
//

import UIKit

class UsernameField: UITextField {

    static let height: Float = 40
    
    init() {
        super.init(frame: .zero)
        initUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initUI() {
        self.font = UIFont.systemFont(ofSize: 24)
        self.textColor = .white
        self.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        self.placeholder = "Type username".loc()
        self.textAlignment = .center
    }

    func update(_ state: State) {
        self.isEnabled = false
        self.isHidden = true
        
        switch state {
        case .initializing:
            self.isHidden = true
        case .ready:
            self.isEnabled = true
            self.isHidden = false
        default:
            self.isHidden = false
            break
        }
    }
}
