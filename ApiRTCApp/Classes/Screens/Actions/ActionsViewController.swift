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
        
        // FIXME:
        form +++ Section("Test actions")
            <<< ButtonRow() { row in
                    row.title = "setUserData"
                }
                .onCellSelection { cell, row in
                    ApiRTC.session.setUserData([
                        "testUserData1": "testUserData1",
                        "testUserData2": "testUserData2"
                        ]
                    )
                }
            // FIXME:
            <<< ButtonRow() { row in
                row.title = "Test"
                }
                .onCellSelection { cell, row in
                    //ApiRTC.session.getConnectedUserList()
                }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
}
