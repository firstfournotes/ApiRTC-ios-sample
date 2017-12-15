//
//  ToolBar.swift
//  ApiRTCApp
//
//  Created by Aleksandr Khorobrykh on 14/12/2017.
//  Copyright © 2017 Apizee. All rights reserved.
//

import UIKit

class ToolBar: UIView {

    static let height: Float = 40
    
    var actionsButton: UIButton!
    
    init() {
        super.init(frame: .zero)
        initUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initUI() {
                
        actionsButton = Button(image: UIImage.fontAwesomeIcon(name: .bars, textColor: .white, size: CGSize(width: 30, height: 30)), bgColor: .clear)
        self.addSubview(actionsButton)
        actionsButton.snp.makeConstraints { (make) in
            make.top.equalTo(0)
            make.right.equalTo(0)
            make.width.height.equalTo(type(of: self).height)
        }
    }
}
