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

enum WhiteboardMemeberState {
    case offline
    case invited
    case member
}

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
    var openWhiteboardButton: ButtonRow!
    
    var whiteboardMemberState: WhiteboardMemeberState! {
        didSet {
            DispatchQueue.main.async {
                self.update(self.whiteboardMemberState)
            }
        }
    }
    
    var whiteboardViewController: WhiteboardViewController?
    
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
            }
            .onCellSelection { cell, row in
                self.joinWhiteboard()
            }
        leaveButton = ButtonRow() { row in
                row.title = "Leave whiteboard"
            }
            .onCellSelection { cell, row in
                self.leaveWhiteboard()
            }
        whiteboardUsersButton = ButtonRow() { row in
                row.title = "Whiteboard users"
            }
            .onCellSelection { cell, row in
                self.showWhiteboardUsers()
            }
        
        openWhiteboardButton = ButtonRow() { row in
            row.title = "Open whiteboard"
            }
            .onCellSelection { cell, row in
                self.openWhiteboard()
            }
        
        form
            +++ toolsSection
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
            +++ Section()
                <<< openWhiteboardButton
        
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
        
        whiteboardMemberState = .offline
        
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
            
            if whiteboard.room.hasContact(withId: ApiRTC.session.user.id) {
                self.whiteboardMemberState = .member
            }

            print(str)
            Drop.down(str)
        }
        
        whiteboard.onUpdate { update in
            DispatchQueue.main.async {
                self.whiteboardViewController?.update(update)
            }
        }
        
        whiteboardMemberState = whiteboard.room.isOwned ? .member : .invited
        DispatchQueue.main.async {
            Drop.down("New whiteboard, roomId: \(whiteboard.room.id)")
        }
    }
    
    func joinWhiteboard() {
        whiteboard?.join()
    }
    
    func leaveWhiteboard() {
        whiteboard?.leave()
        whiteboard = nil
        
        whiteboardMemberState = .offline
    }
    
    func invite(contactId: String) {
        
        guard whiteboard != nil else {
            showAlert(message: "Create whiteboard before sending invitation")
            return
        }
        
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
    
    func update(_ state: WhiteboardMemeberState) {
        
        switch state {
        case .offline:

            createButton.enable()
            joinButton.disable()
            leaveButton.disable()
            whiteboardUsersButton.disable()
            //openWhiteboardButton.disable() // FIXME:
            
        case .invited:
          
            createButton.enable()
            joinButton.enable()
            leaveButton.disable()
            whiteboardUsersButton.disable()
            //openWhiteboardButton.disable()
        
        case .member:
            
            createButton.disable()
            joinButton.disable()
            leaveButton.enable()
            whiteboardUsersButton.enable()
            //openWhiteboardButton.enable()
        }
    }
    
    func openWhiteboard() {
        whiteboardViewController = WhiteboardViewController()
        whiteboardViewController?.delegate = self
        self.present(whiteboardViewController!, animated: true, completion: nil)
    }
}

extension ViewController: WhiteboardViewControllerDelegate {
    
    func whiteboardViewController(_ controller: WhiteboardViewController, didAddData data: WhiteboardData) {
        whiteboard?.add(data)
    }
}

extension Row {
    func enable() {
        disabled = false
        evaluateDisabled()
        reload()
    }

    func disable() {
        disabled = true
        evaluateDisabled()
        reload()
    }
}
