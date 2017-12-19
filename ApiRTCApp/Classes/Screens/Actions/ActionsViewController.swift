//
//  ActionsViewController.swift
//  ApiRTCApp
//
//  Created by Aleksandr Khorobrykh on 14/12/2017.
//  Copyright © 2017 Apizee. All rights reserved.
//

import UIKit
import Eureka
import ApiRTC

class ActionsViewController: FormViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = Config.Color.darkGray
        
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
}
