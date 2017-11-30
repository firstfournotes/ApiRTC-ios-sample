//
//  CallToolbar.swift
//  ApiRTCApp
//
//  Created by Aleksandr Khorobrykh on 28/11/2017.
//  Copyright © 2017 Apizee. All rights reserved.
//

import UIKit

class CallToolbar: UIView {
    
    static let height: Float = 50 * 2
    static let width: Float = 50

    var switchCameraButton: Button!
    var switchAudioButton: Button!
    
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
        
        switchAudioButton = Button(
            image: UIImage.fontAwesomeIcon(name: .microphone, textColor: .white, size: CGSize(width: 30, height: 30)),
            nonActiveImage: UIImage.fontAwesomeIcon(name: .microphoneSlash, textColor: .white, size: CGSize(width: 30, height: 30)),
            bgColor: UIColor.white.withAlphaComponent(0.1)
        )
        self.addSubview(switchAudioButton)
        switchAudioButton.snp.makeConstraints { (make) in
            make.left.right.equalTo(0)
            make.height.equalTo(type(of: self).width)
            make.bottom.equalTo(switchCameraButton.snp.top).offset(-1)
        }
    }
    
    func update(_ state: State) {
        
    }
    
    func update(isAudioEnabled: Bool) {
        switchAudioButton.isActive = !isAudioEnabled
    }
}
