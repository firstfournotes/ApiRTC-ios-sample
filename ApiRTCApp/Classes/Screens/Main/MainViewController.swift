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
import FontAwesome_swift

enum State {
    case initializing
    case connecting
    case ready
    case videoCallDialing
    case audioCallDialing
    case videoCall
    case audioCall
    case hangingUp
    case disconnected
    case error(Error?)
}

class MainViewController: UIViewController, UITextFieldDelegate {
    
    var numberField: UITextField!
    var userIdLabel: UILabel!
    var stateLabel: UILabel!

    var videoCallButton: UIButton!
    var audioCallButton: UIButton!
    var answerButton: UIButton!
    var hangupButton: UIButton!
    
    static let buttonSize: Double = 50
    var keyboardRect: CGRect = .zero
    
    var state: State! {
        didSet {
            handle(state)
        }
    }
    
    var localVideoView, remoteVideoView: UIView!
    
    deinit {
        removeKeyboardNotificationsObservers()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = Config.Color.darkGray
        
        // Video views
        remoteVideoView = UIView(frame: self.view.bounds)
        remoteVideoView.backgroundColor = Config.Color.darkGray
        remoteVideoView.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        self.view.addSubview(remoteVideoView)

        localVideoView = UIView(frame: CGRect(x: Config.UI.screenSize.width * 0.7 - 20, y: 20, width: 0.3 * Config.UI.screenSize.width, height: 0.3 * Config.UI.screenSize.height))
        localVideoView.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        self.view.addSubview(localVideoView)
        
        // Buttons
        videoCallButton = Button(image: UIImage.fontAwesomeIcon(name: .videoCamera, textColor: .white, size: CGSize(width: 30, height: 30)), bgColor: Config.Color.green)
        self.view.addSubview(videoCallButton)
        videoCallButton.snp.makeConstraints { (make) in
            make.width.equalTo(type(of: self).buttonSize)
            make.height.equalTo(type(of: self).buttonSize)
            make.bottom.equalTo(0)
            make.left.equalTo(0)
        }
        videoCallButton.addTarget(self, action: #selector(tapVideoCallButton(_:)), for: .touchUpInside)
        
        audioCallButton = Button(image: UIImage.fontAwesomeIcon(name: .phoneSquare, textColor: .white, size: CGSize(width: 30, height: 30)), bgColor: Config.Color.green)
        self.view.addSubview(audioCallButton)
        audioCallButton.snp.makeConstraints { (make) in
            make.width.equalTo(type(of: self).buttonSize)
            make.height.equalTo(type(of: self).buttonSize)
            make.bottom.equalTo(0)
            make.left.equalTo(videoCallButton.snp.right).offset(1)
        }
        audioCallButton.addTarget(self, action: #selector(tapAudioCallButton(_:)), for: .touchUpInside)

        answerButton = Button(image: UIImage.fontAwesomeIcon(name: .phone, textColor: .white, size: CGSize(width: 30, height: 30)), bgColor: Config.Color.green)
        self.view.addSubview(answerButton)
        answerButton.snp.makeConstraints { (make) in
            make.width.equalTo(type(of: self).buttonSize)
            make.height.equalTo(type(of: self).buttonSize)
            make.bottom.equalTo(0)
            make.left.equalTo(audioCallButton.snp.right).offset(1)
        }
        answerButton.addTarget(self, action: #selector(tapAnswerButton(_:)), for: .touchUpInside)

        hangupButton = Button(image: UIImage(named: "hangup")!.withRenderingMode(UIImageRenderingMode.alwaysTemplate), bgColor: Config.Color.red)
        hangupButton.tintColor = .white
        self.view.addSubview(hangupButton)
        hangupButton.snp.makeConstraints { (make) in
            make.height.equalTo(type(of: self).buttonSize)
            make.bottom.equalTo(0)
            make.left.equalTo(answerButton.snp.right).offset(1)
            make.right.equalTo(0)
        }
        hangupButton.addTarget(self, action: #selector(tapHangUpButton(_:)), for: .touchUpInside)
        
        // Number
        numberField = UITextField()
        numberField.text = "106273"
        numberField.textColor = .white
        numberField.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        numberField.placeholder = "Type number".loc()
        numberField.textAlignment = .center
        self.view.addSubview(numberField)
        numberField.snp.makeConstraints { (make) in
            make.left.right.equalTo(0)
            make.bottom.equalTo(-(type(of: self).buttonSize + 1))
            make.height.equalTo(30)
        }
        numberField.delegate = self

        // Misc
        userIdLabel = UILabel()
        userIdLabel.font = UIFont.systemFont(ofSize: 12, weight: .light)
        userIdLabel.textColor = .lightGray
        self.view.addSubview(userIdLabel)
        userIdLabel.snp.makeConstraints { (make) in
            make.height.equalTo(20)
            make.width.equalTo(Config.UI.screenSize.width / 2.0)
            make.top.equalTo(0)
            make.left.equalTo(5)
        }
        
        stateLabel = UILabel()
        stateLabel.font = UIFont.systemFont(ofSize: 12, weight: .light)
        stateLabel.textColor = .lightGray
        stateLabel.textAlignment = .right
        self.view.addSubview(stateLabel)
        stateLabel.snp.makeConstraints { (make) in
            make.height.equalTo(20)
            make.width.equalTo(Config.UI.screenSize.width / 2.0)
            make.top.equalTo(0)
            make.right.equalTo(-5)
        }
        
        registerForKeyboardNotifications()
        
        state = .initializing
        
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
            self?.state = .ready
        }
        ApiRTC.onConnectionError { [weak self] (error) in
            self?.state = .error(error)
        }
        ApiRTC.onDisconnected { [weak self] in
            self?.state = .disconnected
        }
        ApiRTC.connect()
        
        ApiRTC.rtc.initialize()
        ApiRTC.rtc.onCall { (connection) in
            DispatchQueue.main.async {
                switch connection.type {
                case .videoCall:
                    self.state = .videoCall
                case .audioCall:
                    self.state = .audioCall
                default:
                    break
                }
            }
        }
        ApiRTC.rtc.onHangup {
            DispatchQueue.main.async {
                self.state = .hangingUp
                DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                    self.state = .ready
                })
            }
        }
        ApiRTC.rtc.onError { (error) in
            DispatchQueue.main.async {
                self.state = .error(error)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                    self.state = .ready
                })
            }
        }
        
        ApiRTC.rtc.add(localVideoView: localVideoView, remoteVideoView: remoteVideoView)
    }
    
    @objc func tapVideoCallButton(_ button: UIButton) {
        
        guard let number = getNumber() else {
            return
        }
        
        state = .videoCallDialing
        
        let connection = RTCConnection(type: .videoCall, dst: [number])
        ApiRTC.rtc.start(connection)
    }
    
    @objc func tapAudioCallButton(_ button: UIButton) {
        
        // FIXME:
//        guard let number = getNumber() else {
//            return
//        }
//
//        state = .audioCallDialing
//
//        let connection = RTCConnection(type: .audioCall, dst: [number])
//        ApiRTC.rtc.start(connection)
    }
    
    func getNumber() -> String? {
        guard let number = numberField.text, number.count > 0 else {
            showWarningAlert(message: "Type the number")
            return nil
        }
        return number
    }
    
    
    @objc func tapAnswerButton(_ button: UIButton) {
        
        ApiRTC.rtc.answer()
    }
    
    @objc func tapHangUpButton(_ button: UIButton) {
        
        ApiRTC.rtc.hangUp()
    }
    
    // MARK:
    
    func handle(_ state: State) {
        
        // FIXME: simplify it
        
        func handle() {
            stateLabel.textColor = .lightGray
            
            switch state {
            case .initializing:
                videoCallButton.isEnabled = false
                audioCallButton.isEnabled = false
                answerButton.isEnabled = false
                hangupButton.isEnabled = false
                numberField.isHidden = true
                remoteVideoView.isHidden = true
                localVideoView.isHidden = true
            case .connecting:
                videoCallButton.isEnabled = false
                audioCallButton.isEnabled = false
                answerButton.isEnabled = false
                hangupButton.isEnabled = false
                numberField.isHidden = true
                remoteVideoView.isHidden = true
                localVideoView.isHidden = true
            case .ready:
                videoCallButton.isEnabled = true
                audioCallButton.isEnabled = true
                answerButton.isEnabled = false
                hangupButton.isEnabled = false
                numberField.isHidden = false
                numberField.isEnabled = true
                remoteVideoView.isHidden = true
                localVideoView.isHidden = true
            case .videoCallDialing:
                videoCallButton.isEnabled = false
                audioCallButton.isEnabled = false
                answerButton.isEnabled = false
                hangupButton.isEnabled = true
                numberField.isHidden = false
                numberField.isEnabled = false
                remoteVideoView.isHidden = true
                localVideoView.isHidden = false
            case .audioCallDialing:
                videoCallButton.isEnabled = false
                audioCallButton.isEnabled = false
                answerButton.isEnabled = false
                hangupButton.isEnabled = true
                numberField.isHidden = false
                numberField.isEnabled = false
                remoteVideoView.isHidden = true
                localVideoView.isHidden = true
            case .videoCall:
                videoCallButton.isEnabled = false
                audioCallButton.isEnabled = false
                answerButton.isEnabled = false
                hangupButton.isEnabled = true
                numberField.isHidden = false
                numberField.isEnabled = false
                remoteVideoView.isHidden = false
                localVideoView.isHidden = false
            case .audioCall:
                videoCallButton.isEnabled = false
                audioCallButton.isEnabled = false
                answerButton.isEnabled = false
                hangupButton.isEnabled = true
                numberField.isHidden = false
                numberField.isEnabled = false
                remoteVideoView.isHidden = true
                localVideoView.isHidden = true
            case .hangingUp:
                videoCallButton.isEnabled = false
                audioCallButton.isEnabled = false
                answerButton.isEnabled = false
                hangupButton.isEnabled = false
                numberField.isHidden = false
                numberField.isEnabled = false
                remoteVideoView.isHidden = true
                localVideoView.isHidden = true
            case .disconnected:
                videoCallButton.isEnabled = false
                audioCallButton.isEnabled = false
                answerButton.isEnabled = false
                hangupButton.isEnabled = false
                numberField.isHidden = true
                remoteVideoView.isHidden = true
                localVideoView.isHidden = true
            case .error(_):
                stateLabel.textColor = .red
                videoCallButton.isEnabled = false
                audioCallButton.isEnabled = false
                answerButton.isEnabled = false
                hangupButton.isEnabled = false
                numberField.isHidden = true
                remoteVideoView.isHidden = true
                localVideoView.isHidden = true
            }
            
            stateLabel.text = "\(state)"
        }
        
        DispatchQueue.main.async {
            handle()
        }
    }
    
    // MARK: UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // MARK: Keyboard things
    
    func registerForKeyboardNotifications() {
        
        observe(notif: NSNotification.Name.UIKeyboardWillShow.rawValue, selector: #selector(keyboardWillBeShown(notification:)))
        observe(notif: NSNotification.Name.UIKeyboardWillHide.rawValue, selector: #selector(keyboardWillBeHidden(notification:)))
    }
    
    func removeKeyboardNotificationsObservers() {
        
        removeObserver(name: NSNotification.Name.UIKeyboardWillShow.rawValue)
        removeObserver(name: NSNotification.Name.UIKeyboardWillHide.rawValue)
    }
    
    @objc func keyboardWillBeShown(notification: NSNotification) {
        
        guard let keyboardFrame = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue else {
            return
        }
        guard let animationDuration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }
        
        keyboardRect = keyboardFrame.cgRectValue
        
        UIView.animate(withDuration: animationDuration) {
            self.numberField.snp.updateConstraints { (make) in
                make.bottom.equalTo(-self.keyboardRect.height)
            }
            self.numberField.superview?.layoutIfNeeded()
        }
    }
    
    @objc func keyboardWillBeHidden(notification: NSNotification) {
        
        guard let animationDuration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }
        
        UIView.animate(withDuration: animationDuration) {
            self.numberField.snp.updateConstraints { (make) in
                make.bottom.equalTo(-(type(of: self).buttonSize + 1))
            }
            self.numberField.superview?.layoutIfNeeded()
        }
    }
    
    // MARK: Helpers
    
    func checkPerms(completion: ((_ granted: Bool) -> Void)? = nil) {
        
        if AVCaptureDevice.authorizationStatus(for: .video) ==  .authorized {
            completion?(true)
        }
        else {
            
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { (granted :Bool) -> Void in
                
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
