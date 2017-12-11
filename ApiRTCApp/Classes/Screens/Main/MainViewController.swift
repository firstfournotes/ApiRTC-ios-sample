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
    case disconnected
    case error
}

class MainViewController: UIViewController, UITextFieldDelegate {
    
    var controlView: ControlView!
    var callToolbar: CallToolbar!
    var usernameField: UsernameField!
    var userIdLabel: UILabel!
    var stateLabel: UILabel!
    
    var switchCameraButton: Button!
    
    var keyboardRect: CGRect = .zero
    
    var state: State! {
        didSet {
            handle(state)
        }
    }
    
    var cameraView: CameraView!
    var remoteVideoView: EAGLVideoView!
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
        remoteVideoView = EAGLVideoView(frame: self.view.bounds)
        remoteVideoView.contentMode = .scaleAspectFit
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
            make.height.equalTo(UsernameField.height)
        }
        
        // Toolbar
        callToolbar = CallToolbar()
        self.view.addSubview(callToolbar)
        callToolbar.snp.makeConstraints { (make) in
            make.bottom.equalTo(usernameField.snp.top).offset(-1)
            make.right.equalTo(0)
            make.width.equalTo(CallToolbar.width)
            make.height.equalTo(CallToolbar.height)
        }
        callToolbar.switchCameraButton.addTarget(self, action: #selector(tapSwitchCameraButton(_:)), for: .touchUpInside)
        callToolbar.switchAudioButton.addTarget(self, action: #selector(tapSwitchAudioButton(_:)), for: .touchUpInside)
        callToolbar.switchVideoButton.addTarget(self, action: #selector(tapSwitchVideoButton(_:)), for: .touchUpInside)
        
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
        ApiRTC.setLog([.error, .info, .warning, .debug])
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
            case .incomingSession(let session):
                guard wSelf.currentSession == nil else {
                    session.close()
                    return
                }
                wSelf.currentSession = session
                DispatchQueue.main.async {
                    wSelf.usernameField.text = session.ownerId
                    wSelf.state = .incomingCall
                }
            case .error(let error):
                wSelf.state = .error
                debugPrint("Error: \(error)")
            case .disconnected(let error):
                wSelf.hangUp()
                wSelf.state = .disconnected
                if let error = error {
                    debugPrint("Disconnected with error: \(error)")
                }
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
    
    // MARK: Toolbar actions
    
    @objc func tapSwitchCameraButton(_ button: UIButton) {
        
        guard let session = currentSession as? RTCVideoSession else {
            return
        }

        session.switchCamera()
    }
    
    @objc func tapSwitchAudioButton(_ button: UIButton) {
        
        guard let session = currentSession else {
            return
        }
        
        session.isLocalAudioEnabled = !session.isLocalAudioEnabled
        callToolbar.update(isAudioEnabled: session.isLocalAudioEnabled)
    }
    
    @objc func tapSwitchVideoButton(_ button: UIButton) {
        
        guard let session = currentSession as? RTCVideoSession else {
            return
        }
        
        let isCapturing = session.isCapturing
        isCapturing ? session.stopCapture() : session.startCapture()
        callToolbar.update(isVideoEnabled: !isCapturing)
        cameraView.isHidden = isCapturing
    }
    
    // MARK: Event handling
    
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
                    self.remoteVideoTrack?.add(renderer: self.remoteVideoView.renderer)
                }
            }
        case .closed:
            currentSession = nil
            self.remoteVideoTrack?.remove(renderer: self.remoteVideoView.renderer)
            self.remoteVideoTrack = nil
            self.cameraView.captureSession = nil
            DispatchQueue.main.async {
                if self.state == .disconnected {
                    return
                }
                self.state = .ready
            }
        case .error(let error):
            DispatchQueue.main.async {
                self.state = .error
                debugPrint("Error:\(error)")
            }
        }
    }
    
    // MARK: State handling
    
    func handle(_ state: State) {
        
        func resetUI() {
            remoteVideoView.isHidden = true
            cameraView.isHidden = true
            callToolbar.isHidden = true
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
                callToolbar.isHidden = false
            case .audioCall:
                callToolbar.isHidden = false
            case .error:
                stateLabel.textColor = .red
            default:
                break
            }
            
            stateLabel.text = "\(state)"
            
            if state != .error {
                controlView.update(state)
                usernameField.update(state)
                callToolbar.update(state)
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
