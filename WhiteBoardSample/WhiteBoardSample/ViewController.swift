//
//  ViewController.swift
//  WhiteBoardSample
//
//  Created by Aleksandr Khorobrykh on 04/01/2018.
//  Copyright © 2018 Apizee. All rights reserved.
//

import UIKit
import ApiRTC
import Eureka
import SnapKit
//import SwiftyDrop

class ViewController: FormViewController {

    var stateLabel, userIdLabel: UILabel!
    
    var whiteBoard: Whiteboard?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        form = Form()
        
        form +++ Section("Test")
            <<< ButtonRow() { row in
                    row.title = "Create whiteboard"
                }
                .onCellSelection { cell, row in
                    self.createWhiteBoard()
                }
        // Misc
        userIdLabel = UILabel()
        userIdLabel.font = UIFont.systemFont(ofSize: 12, weight: .light)
        userIdLabel.textColor = .darkGray
        self.view.addSubview(userIdLabel)
        userIdLabel.snp.makeConstraints { (make) in
            make.height.equalTo(20)
            make.width.equalTo(Config.UI.screenSize.width / 2)
            make.top.equalTo(0)
            make.left.equalTo(5)
        }
        
        stateLabel = UILabel()
        stateLabel.font = UIFont.systemFont(ofSize: 12, weight: .light)
        stateLabel.textColor = .darkGray
        stateLabel.textAlignment = .right
        self.view.addSubview(stateLabel)
        stateLabel.snp.makeConstraints { (make) in
            make.height.equalTo(20)
            make.width.equalTo(Config.UI.screenSize.width / 2)
            make.top.equalTo(0)
            make.right.equalTo(-5)
        }
        
        initializeSDK()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    func initializeSDK() {
        
        ApiRTC.initialize(apiKey: Config.apiKey)
        ApiRTC.setLog([.error, .warning, .info])
        ApiRTC.session.onEvent { (event) in
            switch event {
            case .initialized:
                self.stateLabel.text = "initialized"
            case .connected:
                self.userIdLabel.text = "Your id" + ": " + ApiRTC.session.user.id
                self.stateLabel.text = "connected"
            case .error(let error):
                self.stateLabel.text = "error"
                print("Error: \(error)")
            case .disconnected(let error):
                self.stateLabel.text = "disconnected"
                if let error = error {
                    self.stateLabel.text = "error"
                    print("Error: \(error)")
                }
            default:
                break
            }
        }
        
        ApiRTC.session.connect()
    }
    
    func createWhiteBoard() {
        whiteBoard = ApiRTC.session.createWhiteBoard()
        whiteBoard!.onEvent { event in
            switch event {
            case .roomCreated(let room):
                print("lol")
                print(room)
            }
        }
        whiteBoard?.createRoom()
    }
}
