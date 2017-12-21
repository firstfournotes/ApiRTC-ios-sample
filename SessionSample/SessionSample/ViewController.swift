//
//  ViewController.swift
//  SessionSample
//
//  Created by Aleksandr Khorobrykh on 20/12/2017.
//  Copyright © 2017 Apizee. All rights reserved.
//

import UIKit
import SnapKit
import Eureka
import ApiRTC
import SwiftyDrop

class ViewController: FormViewController {

    var stateLabel, userIdLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        form = Form()
        
        form +++ Section("Info actions")
            <<< ButtonRow() { row in
                    row.title = "Get actual groups"
                }
                .onCellSelection { cell, row in
                    var str = "Actual groups:"
                    for (key, value) in ApiRTC.session.presenceGroups {
                        str += "\n" + key + " (\(value.state))"
                    }
                    print(str)
                    Drop.down(str)
                }
            <<< ButtonRow() { row in
                    row.title = "Get default group contacts"
                }
                .onCellSelection { cell, row in
                    if let contacts = ApiRTC.session.presenceGroups["default"]?.contacts {
                        var str = "Connected contacts: "
                        for contact in contacts {
                            str += contact.id + " "
                        }
                        print(str)
                        Drop.down(str)
                    }
                }
            <<< ButtonRow() { row in
                    row.title = "Get custom group contacts"
                }
                .onCellSelection { cell, row in
                    if let contacts = ApiRTC.session.presenceGroups["custom"]?.contacts {
                        var str = "Connected contacts: "
                        for contact in contacts {
                            str += contact.id + " "
                        }
                        print(str)
                        Drop.down(str)
                    }
                }
        
        form +++ Section("User actions")
            <<< ButtonRow() { row in
                row.title = "Set test user data"
                }
                .onCellSelection { cell, row in
                    ApiRTC.session.setUserData([
                        "testUserData1": "testUserData1",
                        "testUserData2": "testUserData2"
                        ]
                    )
                }
        form +++ Section("Default group actions")
            <<< ButtonRow() { row in
                row.title = "Join default group"
                }
                .onCellSelection { cell, row in
                    ApiRTC.session.joinGroup("default")
                }
            <<< ButtonRow() { row in
                row.title = "Leave default group"
                }
                .onCellSelection { cell, row in
                    ApiRTC.session.leaveGroup("default")
                }
            <<< ButtonRow() { row in
                row.title = "Subscribe default group"
                }
                .onCellSelection { cell, row in
                    ApiRTC.session.subscribeGroup("default")
                }
            <<< ButtonRow() { row in
                row.title = "Unsubscribe default group"
                }
                .onCellSelection { cell, row in
                    ApiRTC.session.unsubscribeGroup("default")
                }
        form +++ Section("Custom group actions")
            <<< ButtonRow() { row in
                row.title = "Join custom group"
                }
                .onCellSelection { cell, row in
                    ApiRTC.session.joinGroup("custom")
                }
        
            <<< ButtonRow() { row in
                row.title = "Leave custom group"
                }
                .onCellSelection { cell, row in
                    ApiRTC.session.leaveGroup("custom")
                }
            <<< ButtonRow() { row in
                row.title = "Subscribe custom group"
                }
                .onCellSelection { cell, row in
                    ApiRTC.session.subscribeGroup("custom")
            }
            <<< ButtonRow() { row in
                row.title = "Unsubscribe custom group"
                }
                .onCellSelection { cell, row in
                    ApiRTC.session.unsubscribeGroup("custom")
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
                
            case .contactListUpdated(let presenceGroup, let groupUpdate):

                var str = "---Contact list updated---\n"

                switch groupUpdate.type {
                case .join:
                    str += "Join"
                case .left:
                    str += "Left"
                case .userDataChange:
                    str += "Change"
                }
                
                str += "\nGroup: " + presenceGroup.name
                
                for contact in groupUpdate.contacts {
                    str += "\nContact: " + contact.id
                }
                
                print(str)
                Drop.down(str)
                
            default:
                break
            }
        }
        
        ApiRTC.session.connect()
    }
}
