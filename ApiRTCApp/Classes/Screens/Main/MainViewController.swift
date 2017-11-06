//
//  MainViewController.swift
//  ApiRTCApp
//
//  Created by Aleksandr Khorobrykh on 30/10/2017.
//  Copyright © 2017 Apizee. All rights reserved.
//

import UIKit
import SnapKit
import ApiRTC
import AVFoundation

class MainViewController: InputAligningViewController {
    
    var localView, remoteView: UIView!
    var textField: UITextField!
    var userIdLabel: UILabel!
    
    var callButton: UIButton!
    var answerButton: UIButton!
    var hangupButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = Config.Color.darkGray
        
        localView = UIView(frame: CGRect(x: 0, y: 0, width: Config.UI.screenSize.width / 2.0, height: 250))
        localView.backgroundColor = UIColor.gray.withAlphaComponent(0.1)
        scrollView.addSubview(localView)
        
        remoteView = UIView(frame: CGRect(x: Config.UI.screenSize.width / 2.0, y: 0, width: Config.UI.screenSize.width / 2.0, height: 250))
        remoteView.backgroundColor = UIColor.gray.withAlphaComponent(0.1)
        scrollView.addSubview(remoteView)
        
        textField = UITextField()
        textField.textColor = .lightGray
        textField.backgroundColor = UIColor.gray.withAlphaComponent(0.2)
        scrollView.addSubview(textField)
        textField.snp.makeConstraints { (make) in
            make.width.equalTo(250)
            make.height.equalTo(30)
            make.top.equalTo(remoteView.snp.bottom).offset(20)
            make.left.equalTo((Config.UI.screenSize.width - 250) / 2.0)
        }
        
        callButton = Button(title: "Call".loc(), bgColor: Config.Color.green)
        scrollView.addSubview(callButton)
        callButton.snp.makeConstraints { (make) in
            make.width.equalTo(80)
            make.height.equalTo(30)
            make.top.equalTo(textField.snp.bottom).offset(20)
            make.centerX.equalTo(self.view.snp.centerX).offset(-100)
        }
        callButton.addTarget(self, action: #selector(tapCallButton(_:)), for: .touchUpInside)
        callButton.isEnabled = false

        answerButton = Button(title: "Answer".loc(), bgColor: Config.Color.green)
        scrollView.addSubview(answerButton)
        answerButton.snp.makeConstraints { (make) in
            make.width.equalTo(80)
            make.height.equalTo(30)
            make.top.equalTo(textField.snp.bottom).offset(20)
            make.centerX.equalTo(self.view.snp.centerX)
        }
        answerButton.addTarget(self, action: #selector(tapAnswerButton(_:)), for: .touchUpInside)
        answerButton.isEnabled = false

        hangupButton = Button(title: "HangUp".loc(), bgColor: Config.Color.red)
        scrollView.addSubview(hangupButton)
        hangupButton.snp.makeConstraints { (make) in
            make.width.equalTo(80)
            make.height.equalTo(30)
            make.top.equalTo(textField.snp.bottom).offset(20)
            make.centerX.equalTo(self.view.snp.centerX).offset(100)
        }
        hangupButton.addTarget(self, action: #selector(tapHangUpButton(_:)), for: .touchUpInside)
        hangupButton.isEnabled = false

        userIdLabel = UILabel()
        userIdLabel.textAlignment = .center
        userIdLabel.textColor = .lightGray
        scrollView.addSubview(userIdLabel)
        userIdLabel.snp.makeConstraints { (make) in
            make.width.equalTo(Config.UI.screenSize.width)
            make.height.equalTo(30)
            make.top.equalTo(answerButton.snp.bottom).offset(20)
            make.left.equalTo(0)
        }

        scrollView.layoutIfNeeded()
        
        checkPerms { (ok) in
            if ok {
                self.initializeSDK()
            }
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    func initializeSDK() {
        
        ApiRTC.initialize(apiKey: Config.apiKey)
        ApiRTC.settings.logTypes = [.error, .info, .warning]
        
        ApiRTC.onConnected { [weak self] in
            self?.userIdLabel.text = "Your id".loc() + ": " + ApiRTC.user.id
            self?.callButton.isEnabled = true
        }
        ApiRTC.onConnectionError { (error) in
            
        }
        ApiRTC.onDisconnected {
            
        }
        ApiRTC.connect()
        
        ApiRTC.rtc.initialize()
        ApiRTC.rtc.add(localView: localView, remoteView: remoteView)
    }
    
    @objc func tapCallButton(_ button: UIButton) {
        
        if let caleeId = textField.text, caleeId.count > 0 {
            let call = RTCCall(mediaType: .video, callee: [caleeId])
            ApiRTC.rtc.start(call: call)
        }
    }
    
    @objc func tapAnswerButton(_ button: UIButton) {
        
        ApiRTC.rtc.answer()
    }
    
    @objc func tapHangUpButton(_ button: UIButton) {
        
        ApiRTC.rtc.hangUp()
    }

    func checkPerms(completion: ((_ granted: Bool) -> Void)? = nil) {
        
        if AVCaptureDevice.authorizationStatus(for: AVMediaType.video) ==  AVAuthorizationStatus.authorized {
            completion?(true)
        }
        else {
            
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { (granted :Bool) -> Void in
                
                if !granted {
                    completion?(false)
                    return
                }
                
                AVAudioSession.sharedInstance().requestRecordPermission({ (granted) in
                    completion?(granted)
                })
            });
        }
    }
}

class Button: UIButton {
    
    var bgColor: UIColor!
    
    init(title: String, bgColor: UIColor) {
        super.init(frame: .zero)
        self.bgColor = bgColor
        initUI(title: title)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initUI(title: String) {
        
        self.backgroundColor = bgColor
        self.setTitle(title, for: .normal)
        self.setTitleColor(.white, for: .normal)
        self.layer.cornerRadius = 6
        self.clipsToBounds = true
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
