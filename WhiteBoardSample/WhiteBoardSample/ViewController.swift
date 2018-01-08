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
    
    var whiteboard: Whiteboard?
    var presenceGroup: PresenceGroup?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        form = Form()
        
        form +++ Section("")
            <<< ButtonRow() { row in
                    row.title = "Create whiteboard"
                }
                .onCellSelection { cell, row in
                    self.createWhiteboard()
                }
            <<< ButtonRow() { row in
                    row.title = "Refresh contacts"
                }
                .onCellSelection { cell, row in
                    self.updateInviteRow()
                }
            +++ Section("Contacts (tap to invite)") {
                    $0.tag = "contacts"
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
            case .contactListUpdated(let presenceGroup, _):
                self.presenceGroup = presenceGroup
                DispatchQueue.main.async {
                    self.updateInviteRow()
                }
            case .newWhiteboard(let whiteboard):
                self.handleNewWhiteboard(whiteboard)
            default:
                break
            }
        }
        
        ApiRTC.session.connect()
    }
    
    func createWhiteboard() {
        ApiRTC.session.startNewWhiteboard()
    }
    
    func handleNewWhiteboard(_ whiteboard: Whiteboard) {
        self.whiteboard = whiteboard
    }
    
    func updateInviteRow() {

        guard let presenceGroup = presenceGroup else {
            return
        }
        
        let section = form.sectionBy(tag: "contacts")
        section?.removeAll()
        
        var str = "Connected contacts: "
        
        for contact in presenceGroup.contacts {
            str += contact.id + " "
            
            let row = ButtonRow()
            row.title = contact.id
            row.onCellSelection({ (cell, row) in
                self.invite(contactId: contact.id)
            })
            section?.append(row)
        }
        
        print(str)
        section?.reload()
    }
    
    func invite(contactId: String) {
        
        guard let presenceGroup = presenceGroup else {
            return
        }
        
        guard let contact = presenceGroup.contact(withId: contactId) else {
            return
        }
        
        whiteboard?.invite(contact)
    }
}
