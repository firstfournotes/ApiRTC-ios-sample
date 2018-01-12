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
import SwiftyDrop

class ViewController: FormViewController {

    var stateLabel, userIdLabel: UILabel!
    
    var whiteboard: Whiteboard?
    
    var presenceGroup: PresenceGroup?
    
    var contactsSection = Section("Contacts (tap to invite)")
    var toolsSection = Section()
    
    var createButton: ButtonRow!
    var joinButton: ButtonRow!
    var leaveButton: ButtonRow!
    var whiteboardUsersButton: ButtonRow!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        form = Form()
        
        createButton = ButtonRow() { row in
                row.title = "Create whiteboard"
            }
            .onCellSelection { cell, row in
                self.createWhiteboard()
            }
        joinButton = ButtonRow() { row in
                row.title = "Join whiteboard"
                row.disabled = true
            }
            .onCellSelection { cell, row in
                self.joinWhiteboard()
            }
        leaveButton = ButtonRow() { row in
                row.title = "Leave whiteboard"
                row.disabled = true
            }
            .onCellSelection { cell, row in
                self.leaveWhiteboard()
            }
        whiteboardUsersButton = ButtonRow() { row in
                row.title = "Whiteboard users"
                row.disabled = true
            }
            .onCellSelection { cell, row in
                self.showWhiteboardUsers()
            }
        
        form +++ toolsSection
            <<< createButton
            <<< joinButton
            <<< leaveButton
            <<< whiteboardUsersButton
            <<< ButtonRow() { row in
                    row.title = "Refresh contacts"
                }
                .onCellSelection { cell, row in
                    self.refreshContacts()
                }
            +++ contactsSection
            +++ Section("tmp")
                <<< ButtonRow() { row in
                        row.title = "Send message"
                    }
                    .onCellSelection { cell, row in
                        self.sendMessage()
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
                    self.refreshContacts()
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
        
        whiteboard.room.onEvent { event in
            
            var str = "---Room updated---"
            switch event {
            case .updated(let roomUpdate):
                switch roomUpdate.type {
                case .join:
                    str += "\nJoin"
                case .left:
                    str += "\nLeft"
                }
                for contact in roomUpdate.contacts {
                    str += "\nContact: " + contact.id
                }
            }
            
            print(str)
            Drop.down(str)
        }
        
        DispatchQueue.main.async {
            if !whiteboard.room.isOwned {
                self.joinButton.disabled = false
                self.joinButton.evaluateDisabled()
                self.joinButton.reload()
            }
            
            self.leaveButton.disabled = false
            self.leaveButton.evaluateDisabled()
            self.leaveButton.reload()

            self.whiteboardUsersButton.disabled = false
            self.whiteboardUsersButton.evaluateDisabled()
            self.whiteboardUsersButton.reload()
            
            Drop.down("New whiteboard, roomId: \(whiteboard.room.id)")
        }
    }
    
    func joinWhiteboard() {
        whiteboard?.join()
    }
    
    func leaveWhiteboard() {
        whiteboard?.leave()
        whiteboard = nil
        
        joinButton.disabled = true
        joinButton.evaluateDisabled()
        joinButton.reload()
        
        leaveButton.disabled = true
        leaveButton.evaluateDisabled()
        leaveButton.reload()
        
        whiteboardUsersButton.disabled = true
        whiteboardUsersButton.evaluateDisabled()
        whiteboardUsersButton.reload()
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
    
    func showWhiteboardUsers() {
        guard let whiteboard = whiteboard else {
            return
        }
        var str = "---Whiteboard users---"
        for contact in whiteboard.room.contacts {
            str += "\nContact: " + contact.id
        }
        Drop.down(str)
    }
    
    func refreshContacts() {

        guard let presenceGroup = presenceGroup else {
            return
        }
        
        contactsSection.removeAll()
        
        var str = "Connected contacts: "
        
        for contact in presenceGroup.contacts {
            if contact.id == ApiRTC.session.user.id {
                continue
            }
            
            str += contact.id + " "
            
            let row = ButtonRow()
            row.title = contact.id
            row.onCellSelection({ (cell, row) in
                self.invite(contactId: contact.id)
            })
            contactsSection.append(row)
        }
        
        print(str)
        contactsSection.reload()
    }
    
    func sendMessage() {
        let update = WhiteboardUpdate()
        whiteboard?.update(update)
    }
}
