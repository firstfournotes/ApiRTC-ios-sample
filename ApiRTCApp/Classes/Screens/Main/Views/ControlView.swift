//
//  ControlView.swift
//  ApiRTCApp
//
//  Created by Aleksandr Khorobrykh on 09/11/2017.
//  Copyright © 2017 Apizee. All rights reserved.
//

import UIKit

class ControlView: UIView {
    
    var videoCallButton: UIButton!
    var audioCallButton: UIButton!
    var answerButton: UIButton!
    var hangupButton: UIButton!
    
    private static let buttonSize: Double = 50
    static let height: Double = 50
    
    init() {
        super.init(frame: .zero)
        initUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initUI() {
        
        videoCallButton = Button(image: UIImage.fontAwesomeIcon(name: .videoCamera, textColor: .white, size: CGSize(width: 30, height: 30)), bgColor: Config.Color.green)
        self.addSubview(videoCallButton)
        videoCallButton.snp.makeConstraints { (make) in
            make.width.equalTo(type(of: self).buttonSize)
            make.height.equalTo(type(of: self).buttonSize)
            make.bottom.equalTo(0)
            make.left.equalTo(0)
        }
        
        audioCallButton = Button(image: UIImage.fontAwesomeIcon(name: .phoneSquare, textColor: .white, size: CGSize(width: 30, height: 30)), bgColor: Config.Color.green)
        self.addSubview(audioCallButton)
        audioCallButton.snp.makeConstraints { (make) in
            make.width.equalTo(type(of: self).buttonSize)
            make.height.equalTo(type(of: self).buttonSize)
            make.bottom.equalTo(0)
            make.left.equalTo(videoCallButton.snp.right).offset(1)
        }
        
        answerButton = Button(image: UIImage.fontAwesomeIcon(name: .phone, textColor: .white, size: CGSize(width: 30, height: 30)), bgColor: Config.Color.green)
        self.addSubview(answerButton)
        answerButton.snp.makeConstraints { (make) in
            make.width.equalTo(type(of: self).buttonSize * 2)
            make.height.equalTo(type(of: self).buttonSize)
            make.bottom.equalTo(0)
            make.left.equalTo(audioCallButton.snp.right).offset(1)
        }
        
        hangupButton = Button(image: UIImage(named: "hangup")!.withRenderingMode(UIImageRenderingMode.alwaysTemplate), bgColor: Config.Color.red)
        hangupButton.tintColor = .white
        self.addSubview(hangupButton)
        hangupButton.snp.makeConstraints { (make) in
            make.height.equalTo(type(of: self).buttonSize)
            make.bottom.equalTo(0)
            make.left.equalTo(answerButton.snp.right).offset(1)
            make.right.equalTo(0)
        }
    }
    
    func update(_ state: State) {
        
        videoCallButton.isEnabled = false
        audioCallButton.isEnabled = false
        answerButton.isEnabled = false
        hangupButton.isEnabled = false
        
        switch state {
        case .ready:
            videoCallButton.isEnabled = true
            audioCallButton.isEnabled = true
        case .incomingCall:
            answerButton.isEnabled = true
            hangupButton.isEnabled = true
        case .videoCallConnecting, .audioCallConnecting, .videoCall, .audioCall:
            hangupButton.isEnabled = true
        default:
            break
        }
    }
}
