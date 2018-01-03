//
//  ViewController.swift
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
    case videoCallStarting
    case audioCallStarting
    case videoCall
    case audioCall
    case disconnected
    case error
}

class ViewController: UIViewController, UITextFieldDelegate {
    
    var callBar: CallBar!
    var callSettingsBar: CallSettingsBar!
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
    
    var currentCall: Call? {
        didSet {
            currentCall?.onEvent { [weak self] (event) in
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
        
        callBar = CallBar()
        self.view.addSubview(callBar)
        callBar.snp.makeConstraints { (make) in
            make.left.right.bottom.equalTo(0)
            make.height.equalTo(CallBar.height)
        }
        callBar.videoCallButton.addTarget(self, action: #selector(tapVideoCallButton(_:)), for: .touchUpInside)
        callBar.audioCallButton.addTarget(self, action: #selector(tapAudioCallButton(_:)), for: .touchUpInside)
        callBar.answerButton.addTarget(self, action: #selector(tapAnswerButton(_:)), for: .touchUpInside)
        callBar.hangupButton.addTarget(self, action: #selector(tapHangUpButton(_:)), for: .touchUpInside)
        
        // Number
        usernameField = UsernameField()
        //usernameField.text = ""
        usernameField.delegate = self
        self.view.addSubview(usernameField)
        usernameField.snp.makeConstraints { (make) in
            make.left.right.equalTo(0)
            make.bottom.equalTo(-(CallBar.height + 1))
            make.height.equalTo(UsernameField.height)
        }
        
        // Toolbar
        callSettingsBar = CallSettingsBar()
        self.view.addSubview(callSettingsBar)
        callSettingsBar.snp.makeConstraints { (make) in
            make.bottom.equalTo(usernameField.snp.top).offset(-1)
            make.right.equalTo(0)
            make.width.equalTo(CallSettingsBar.width)
            make.height.equalTo(CallSettingsBar.height)
        }
        callSettingsBar.takeSnapshotButton.addTarget(self, action: #selector(tapTakeSnapshotButton(_:)), for: .touchUpInside)
        callSettingsBar.switchCameraButton.addTarget(self, action: #selector(tapSwitchCameraButton(_:)), for: .touchUpInside)
        callSettingsBar.switchAudioButton.addTarget(self, action: #selector(tapSwitchAudioButton(_:)), for: .touchUpInside)
        callSettingsBar.switchVideoButton.addTarget(self, action: #selector(tapSwitchVideoButton(_:)), for: .touchUpInside)
        
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
        ApiRTC.setLog([.error, .info, .warning])
        
        ApiRTC.session.onEvent { [weak self] (event) in
            guard let wSelf = self else {
                return
            }
            switch event {
            case .initialized:
                wSelf.state = .initializing
            case .connected:
                wSelf.userIdLabel.text = "Your id" + ": " + ApiRTC.session.user.id
                wSelf.state = .ready
            case .incomingCall(let call):
                guard wSelf.currentCall == nil else {
                    call.close()
                    return
                }
                wSelf.currentCall = call
                DispatchQueue.main.async {
                    wSelf.usernameField.text = call.ownerId
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

        ApiRTC.session.connect()
    }
    
    // MARK: CallBar actions
    
    @objc func tapVideoCallButton(_ button: UIButton) {

        guard let number = getNumber() else {
            return
        }

        state = .videoCallStarting
        
        currentCall = ApiRTC.session.createCall(type: .video, destinationId: number)
        currentCall!.start()
    }
    
    @objc func tapAudioCallButton(_ button: UIButton) {
        
        guard let number = getNumber() else {
            return
        }
        
        state = .audioCallStarting
        currentCall = ApiRTC.session.createCall(type: .audio, destinationId: number)
        currentCall!.start()
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

        guard let call = currentCall else {
            return
        }
        
        switch call.type {
        case .video:
            state = .videoCall
        case .audio:
            state = .audioCall
        default:
            break
        }
        
        call.answer()
    }
    
    @objc func tapHangUpButton(_ button: UIButton) {
        hangUp()
    }
    
    func hangUp() {
        currentCall?.close()
    }
    
    @objc func swipeDown(_ gr: UISwipeGestureRecognizer) {
        usernameField.resignFirstResponder()
    }
    
    // MARK: CallSettingsBar actions
    
    @objc func tapTakeSnapshotButton(_ button: UIButton) {
        
        guard let image = remoteVideoView.takeSnapshot() else {
            return
        }
        
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }
    
    @objc func tapSwitchCameraButton(_ button: UIButton) {
        
        guard let call = currentCall as? VideoCall else {
            return
        }

        call.switchCamera()
    }
    
    @objc func tapSwitchAudioButton(_ button: UIButton) {
        
        guard let call = currentCall else {
            return
        }
        
        call.isLocalAudioEnabled = !call.isLocalAudioEnabled
        callSettingsBar.update(isAudioEnabled: call.isLocalAudioEnabled)
    }
    
    @objc func tapSwitchVideoButton(_ button: UIButton) {
        
        guard let call = currentCall as? VideoCall else {
            return
        }
        
        let isCapturing = call.isCapturing
        isCapturing ? call.stopCapture() : call.startCapture()
        callSettingsBar.update(isVideoEnabled: !isCapturing)
        cameraView.isHidden = isCapturing
    }
    
    // MARK: Event handling
    
    func handle(event: CallEvent) {
        guard let call = currentCall else {
            return
        }
        
        switch event {
        case .call:
            DispatchQueue.main.async {
                switch call.type {
                case .video:
                    self.state = .videoCall
                case .audio:
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
            currentCall = nil
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
            callSettingsBar.isHidden = true
        }
        
        func handle() {
            stateLabel.textColor = .lightGray
            
            resetUI()
            
            switch state {
            case .videoCallStarting:
                cameraView.isHidden = false
            case .videoCall:
                remoteVideoView.isHidden = false
                cameraView.isHidden = false
                callSettingsBar.isHidden = false
            case .audioCall:
                callSettingsBar.isHidden = false
            case .error:
                stateLabel.textColor = .red
            default:
                break
            }
            
            stateLabel.text = "\(state)"
            
            if state != .error {
                callBar.update(state)
                usernameField.update(state)
                callSettingsBar.update(state)
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
                make.bottom.equalTo(-(CallBar.height + 1))
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
