//
//  MainViewController.swift
//  ApiRTCApp
//
//  Created by Aleksandr Khorobrykh on 30/10/2017.
//  Copyright © 2017 Apizee. All rights reserved.
//

import UIKit
import SnapKit
import AVFoundation
import ApiRTC
import FontAwesome_swift

enum State {
    case unknown
    case initializing
    case connecting
    case ready
    case incomingCall
    case videoCallConnecting
    case audioCallConnecting
    case videoCall
    case audioCall
    case hangedUp
    case disconnected
    case error
}

class MainViewController: UIViewController, UITextFieldDelegate {
    
    var controlView: ControlView!
    var usernameField: UsernameField!
    var userIdLabel: UILabel!
    var stateLabel: UILabel!
    
    var keyboardRect: CGRect = .zero
    
    var state: State! {
        didSet {
            handle(state)
        }
    }
    
    var cameraView: CameraView!
    var remoteVideoView: RemoteVideoView!
    var remoteVideoTrack: VideoTrack?
    
    var currentSession: RTCSession? {
        didSet {
            currentSession?.onEvent { [weak self] (event) in
                self?.handle(event: event)
            }
        }
    }
    
    deinit {
        removeKeyboardNotificationsObservers()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        state = .unknown
        
        self.view.backgroundColor = Config.Color.darkGray
        
        // Video views
        remoteVideoView = RemoteVideoView(frame: self.view.bounds)
        remoteVideoView.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        self.view.addSubview(remoteVideoView)

        cameraView = CameraView(frame: CGRect(x: Config.UI.screenSize.width * 0.7 - 20, y: 20, width: 0.3 * Config.UI.screenSize.width, height: 0.3 * Config.UI.screenSize.height))
        cameraView.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        self.view.addSubview(cameraView)
        
        controlView = ControlView()
        self.view.addSubview(controlView)
        controlView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalTo(0)
            make.height.equalTo(ControlView.height)
        }
        controlView.videoCallButton.addTarget(self, action: #selector(tapVideoCallButton(_:)), for: .touchUpInside)
        controlView.audioCallButton.addTarget(self, action: #selector(tapAudioCallButton(_:)), for: .touchUpInside)
        controlView.answerButton.addTarget(self, action: #selector(tapAnswerButton(_:)), for: .touchUpInside)
        controlView.hangupButton.addTarget(self, action: #selector(tapHangUpButton(_:)), for: .touchUpInside)
        
        // Number
        usernameField = UsernameField()
        //usernameField.text = ""
        usernameField.delegate = self
        self.view.addSubview(usernameField)
        usernameField.snp.makeConstraints { (make) in
            make.left.right.equalTo(0)
            make.bottom.equalTo(-(ControlView.height + 1))
            make.height.equalTo(30)
        }

        // Misc
        userIdLabel = UILabel()
        userIdLabel.font = UIFont.systemFont(ofSize: 12, weight: .light)
        userIdLabel.textColor = .lightGray
        self.view.addSubview(userIdLabel)
        userIdLabel.snp.makeConstraints { (make) in
            make.height.equalTo(20)
            make.width.equalTo(Config.UI.screenSize.width / 2)
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
            make.width.equalTo(Config.UI.screenSize.width / 2)
            make.top.equalTo(0)
            make.right.equalTo(-5)
        }
        
        let swipeGR = UISwipeGestureRecognizer(target: self, action: #selector(swipeDown(_:)))
        swipeGR.direction = .down
        self.view.addGestureRecognizer(swipeGR)
        
        registerForKeyboardNotifications()
        
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
        ApiRTC.setLogTypes([.error, .info, .warning])
        ApiRTC.onEvent { [weak self] (event) in
            guard let wSelf = self else {
                return
            }
            switch event {
            case .initialized:
                wSelf.state = .initializing
            case .connected:
                wSelf.userIdLabel.text = "Your id".loc() + ": " + ApiRTC.user.id
                wSelf.state = .ready
            case .newSession(let session):
                if wSelf.currentSession == nil {
                    wSelf.currentSession = session
                    DispatchQueue.main.async {
                        wSelf.usernameField.text = session.ownerId
                        wSelf.state = .incomingCall
                    }
                }
            case .error(let error):
                wSelf.state = .error
                debugPrint("Error:\(error)")
            case .disconnected:
                wSelf.state = .disconnected
            default:
                break
            }
        }

        ApiRTC.connect()
    }
    
    // MARK: Actions
    
    @objc func tapVideoCallButton(_ button: UIButton) {
        
        guard let number = getNumber() else {
            return
        }
        
        state = .videoCallConnecting
        currentSession = ApiRTC.createSession(type: .videoCall, destinationId: number)
        currentSession!.start()
    }
    
    @objc func tapAudioCallButton(_ button: UIButton) {
        
        guard let number = getNumber() else {
            return
        }
        
        state = .audioCallConnecting
        currentSession = ApiRTC.createSession(type: .audioCall, destinationId: number)
        currentSession!.start()
    }
    
    func getNumber() -> String? {
        guard let number = usernameField.text, number.count > 0 else {
            showWarningAlert(message: "Type the number")
            return nil
        }
        return number
    }
    
    @objc func tapAnswerButton(_ button: UIButton) {
        answer()
    }
    
    func answer() {

        guard let session = currentSession else {
            return
        }
        
        switch session.type {
        case .videoCall:
            state = .videoCall
        case .audioCall:
            state = .audioCall
        default:
            break
        }
        
        session.answer()
    }
    
    @objc func tapHangUpButton(_ button: UIButton) {
        hangUp()
    }
    
    func hangUp() {
        currentSession?.close()
    }
    
    @objc func swipeDown(_ gr: UISwipeGestureRecognizer) {
        usernameField.resignFirstResponder()
    }
    
    // MARK:
    
    func handle(event: RTCSessionEvent) {
        guard let session = currentSession else {
            return
        }
        
        switch event {
        case .call:
            DispatchQueue.main.async {
                switch session.type {
                case .videoCall:
                    self.state = .videoCall
                case .audioCall:
                    self.state = .audioCall
                default:
                    break
                }
            }
        case .localCaptureSession(let captureSession):
            DispatchQueue.main.async {
                self.cameraView.previewLayer.videoGravity = .resizeAspectFill
                self.cameraView.captureSession = captureSession
            }
        case .remoteMediaStream(let mediaStream):
            if let videoTrack = mediaStream.videoTracks.first {
                DispatchQueue.main.async {
                    self.remoteVideoTrack = videoTrack
                    self.remoteVideoTrack?.add(renderer: self.remoteVideoView)
                }
            }
        case .closed:
            currentSession = nil
            DispatchQueue.main.async {
                self.remoteVideoTrack?.remove(renderer: self.remoteVideoView)
                self.remoteVideoTrack = nil
                self.cameraView.captureSession = nil
                self.state = .hangedUp
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                    self.state = .ready
                })
            }
        case .error(let error):
            DispatchQueue.main.async {
                self.state = .error
                debugPrint("Error:\(error)")
            }
        }
    }
    
    // MARK:
    
    func handle(_ state: State) {
        
        func resetUI() {
            remoteVideoView.isHidden = true
            cameraView.isHidden = true
        }
        
        func handle() {
            stateLabel.textColor = .lightGray
            
            resetUI()
            
            switch state {
            case .videoCallConnecting:
                cameraView.isHidden = false
            case .videoCall:
                remoteVideoView.isHidden = false
                cameraView.isHidden = false
            case .error:
                stateLabel.textColor = .red
            default:
                break
            }
            
            stateLabel.text = "\(state)"
            
            if state != .error {
                controlView.update(state)
                usernameField.update(state)
            }
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
            self.usernameField.snp.updateConstraints { (make) in
                make.bottom.equalTo(-self.keyboardRect.height)
            }
            self.usernameField.superview?.layoutIfNeeded()
        }
    }
    
    @objc func keyboardWillBeHidden(notification: NSNotification) {
        
        guard let animationDuration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }
        
        UIView.animate(withDuration: animationDuration) {
            self.usernameField.snp.updateConstraints { (make) in
                make.bottom.equalTo(-(ControlView.height + 1))
            }
            self.usernameField.superview?.layoutIfNeeded()
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
