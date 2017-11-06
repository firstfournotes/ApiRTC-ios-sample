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

import AVFoundation // todo

class MainViewController: UIViewController {
    
    var localView, remoteView: UIView!
    var textField: UITextField!
    var userIdLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        localView = UIView(frame: CGRect(x: 0, y: 0, width: Config.UI.screenSize.width / 2.0, height: 250))
        localView.backgroundColor = .yellow
        self.view.addSubview(localView)
        
        remoteView = UIView(frame: CGRect(x: Config.UI.screenSize.width / 2.0, y: 0, width: Config.UI.screenSize.width / 2.0, height: 250))
        remoteView.backgroundColor = .gray
        self.view.addSubview(remoteView)
        
        textField = UITextField()
        textField.text = "27543"
        textField.backgroundColor = UIColor.gray.withAlphaComponent(0.3)
        self.view.addSubview(textField)
        textField.snp.makeConstraints { (make) in
            make.top.equalTo(remoteView.snp.bottom).offset(20)
            make.centerX.equalTo(self.view.snp.centerX)
            make.width.equalTo(250)
            make.height.equalTo(30)
        }
        
        let callButton = UIButton()
        callButton.backgroundColor = .green
        callButton.setTitle("call".loc(), for: .normal)
        self.view.addSubview(callButton)
        callButton.snp.makeConstraints { (make) in
            make.width.equalTo(100)
            make.height.equalTo(30)
            make.top.equalTo(textField.snp.bottom).offset(20)
            make.centerX.equalTo(self.view.snp.centerX).offset(-110)
        }
        callButton.addTarget(self, action: #selector(tapCallButton(_:)), for: .touchUpInside)
        
        let answerButton = UIButton()
        answerButton.backgroundColor = .green
        answerButton.setTitle("answer".loc(), for: .normal)
        self.view.addSubview(answerButton)
        answerButton.snp.makeConstraints { (make) in
            make.width.equalTo(100)
            make.height.equalTo(30)
            make.top.equalTo(textField.snp.bottom).offset(20)
            make.centerX.equalTo(self.view.snp.centerX)
        }
        answerButton.addTarget(self, action: #selector(tapAnswerButton(_:)), for: .touchUpInside)
        
        let hangupButton = UIButton()
        hangupButton.backgroundColor = .red
        hangupButton.setTitle("hangUp".loc(), for: .normal)
        self.view.addSubview(hangupButton)
        hangupButton.snp.makeConstraints { (make) in
            make.width.equalTo(100)
            make.height.equalTo(30)
            make.top.equalTo(textField.snp.bottom).offset(20)
            make.centerX.equalTo(self.view.snp.centerX).offset(110)
        }
        hangupButton.addTarget(self, action: #selector(tapHangUpButton(_:)), for: .touchUpInside)
        
        userIdLabel = UILabel()
        userIdLabel.textAlignment = .center
        self.view.addSubview(userIdLabel)
        userIdLabel.snp.makeConstraints { (make) in
            make.width.equalTo(100)
            make.height.equalTo(30)
            make.top.equalTo(answerButton.snp.bottom).offset(20)
            make.centerX.equalTo(self.view.snp.centerX)
        }
        
        // FIXME:
        checkPerms { (ok) in
            //print(ok)
        }
        
        initializeSDK()
    }
    
    func initializeSDK() {
        
        ApiRTC.initialize(apiKey: Config.apiKey)
        ApiRTC.settings.logTypes = [.error, .info, .warning]
        
        ApiRTC.onConnected { [weak self] in
            self?.userIdLabel.text = ApiRTC.user.id
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

    // FIXME: tmp make sdk checkers
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
