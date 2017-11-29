//
//  CallToolbar.swift
//  ApiRTCApp
//
//  Created by Aleksandr Khorobrykh on 28/11/2017.
//  Copyright © 2017 Apizee. All rights reserved.
//

import UIKit

class CallToolbar: UIView {
    
    static let height: Float = 50
    static let width: Float = 50

    var switchCameraButton: Button!
    
    init() {
        super.init(frame: .zero)
        initUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initUI() {
        
        switchCameraButton = Button(image: UIImage.fontAwesomeIcon(name: .refresh, textColor: .white, size: CGSize(width: 30, height: 30)), bgColor: UIColor.white.withAlphaComponent(0.1))
        self.addSubview(switchCameraButton)
        switchCameraButton.snp.makeConstraints { (make) in
            make.bottom.left.right.equalTo(0)
            make.height.equalTo(type(of: self).width)
        }
    }
}
