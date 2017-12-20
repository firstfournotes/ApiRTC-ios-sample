//
//  CallSettingsBar.swift
//  ApiRTCApp
//
//  Created by Aleksandr Khorobrykh on 28/11/2017.
//  Copyright © 2017 Apizee. All rights reserved.
//

import UIKit

class CallSettingsBar: UIView {
    
    static let height: Float = 50 * 3
    static let width: Float = 50

    var switchCameraButton: Button!
    var switchAudioButton: Button!
    var switchVideoButton: Button!
    
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
        
        switchVideoButton = Button(
            image: UIImage.fontAwesomeIcon(name: .videoCamera, textColor: .white, size: CGSize(width: 30, height: 30)),
            nonActiveImage: UIImage(named: "camera_off")!.withRenderingMode(UIImageRenderingMode.alwaysTemplate),
            bgColor: UIColor.white.withAlphaComponent(0.1)
        )
        switchVideoButton.tintColor = .white
        self.addSubview(switchVideoButton)
        switchVideoButton.snp.makeConstraints { (make) in
            make.left.right.equalTo(0)
            make.height.equalTo(type(of: self).width)
            make.bottom.equalTo(switchAudioButton.snp.top).offset(-1)
        }
    }
    
    func update(_ state: State) {
        switch state {
        case .videoCall, .incomingCall:
            switchAudioButton.isActive = true
            switchVideoButton.isActive = true
        default:
            break
        }
    }
    
    func update(isAudioEnabled: Bool) {
        switchAudioButton.isActive = isAudioEnabled
    }
    
    func update(isVideoEnabled: Bool) {
        switchVideoButton.isActive = isVideoEnabled
    }
}
