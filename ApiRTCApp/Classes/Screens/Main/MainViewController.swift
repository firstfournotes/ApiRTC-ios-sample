//
//  MainViewController.swift
//  ApiRTCApp
//
//  Created by Aleksandr Khorobrykh on 30/10/2017.
//  Copyright © 2017 Apizee. All rights reserved.
//

import UIKit
import SnapKit
import ApiRTC

class MainViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        ApiRTC.initialize(apiKey: Config.apiKey)
        ApiRTC.settings.logTypes = [.error, .info, .warning]
        ApiRTC.set(delegate: self)
        
        let button = UIButton()
        button.backgroundColor = .red
        button.setTitle("test".loc(), for: .normal)
        self.view.addSubview(button)
        button.snp.makeConstraints { (make) in
            make.width.equalTo(100)
            make.height.equalTo(30)
            make.center.equalTo(self.view.snp.center)
        }

        button.addTarget(self, action: #selector(tapButton(_:)), for: .touchUpInside)
    }
    
    @objc func tapButton(_ button: UIButton) {

        ApiRTC.connect()
    }
}

extension MainViewController: ApiRTCDelegate {
    
    func apiRTCConnected(_ apiRTC: ApiRTC) {
        
    }
    
    func apiRTCDisconnected(_ apiRTC: ApiRTC) {
        
    }
    
    func apiRTCConnection(_ apiRTC: ApiRTC, failWithError error: Error) {
        //print(error)
    }
}
