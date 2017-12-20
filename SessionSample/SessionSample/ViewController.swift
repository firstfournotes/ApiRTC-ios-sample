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

class ViewController: FormViewController {

    var stateLabel, userIdLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        form = Form()
        
        form +++ Section("User test actions")
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
        form +++ Section("Group test actions")
            <<< ButtonRow() { row in
                row.title = "Join default group"
                }
                .onCellSelection { cell, row in
                    ApiRTC.session.joinGroup(groupNames: ["default"])
            }
            <<< ButtonRow() { row in
                row.title = "Leave default group"
                }
                .onCellSelection { cell, row in
                    ApiRTC.session.leaveGroup(groupNames: ["default"])
            }
            <<< ButtonRow() { row in
                row.title = "Subscribe default group"
                }
                .onCellSelection { cell, row in
                    ApiRTC.session.subscribeGroup(groupNames: ["default"])
            }
            <<< ButtonRow() { row in
                row.title = "Unsubscribe default group"
                }
                .onCellSelection { cell, row in
                    ApiRTC.session.unsubscribeGroup(groupNames: ["default"])
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
        ApiRTC.setLog([.error, .info, .warning])
        
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
            case .contactListUpdate(let joinedGroup, let leftGroup, let changedContacts):
                if let joinedGroup = joinedGroup {
                    print("Join group \(joinedGroup.name)")
                    for contact in joinedGroup.contacts {
                        print("Contact: \(contact.id)")
                        print(contact.data ?? "")
                    }
                }
                if let leftGroup = leftGroup {
                    print("Left group \(leftGroup.name)")
                    for contact in leftGroup.contacts {
                        print("Contact: \(contact.id)")
                        print(contact.data ?? "")
                    }
                }
                if let changedContacts = changedContacts {
                    print("Changed contacts")
                    for contact in changedContacts {
                        print("Contact: \(contact.id)")
                        print(contact.data ?? "")
                    }
                }
            default:
                break
            }
        }
        
        ApiRTC.session.connect()
    }
}

