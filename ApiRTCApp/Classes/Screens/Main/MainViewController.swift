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
        
        let button = UIButton()
        button.backgroundColor = .red
        button.setTitle("Test", for: .normal)
        self.view.addSubview(button)
        button.snp.makeConstraints { (make) in
            make.width.equalTo(100)
            make.height.equalTo(30)
            make.center.equalTo(self.view.snp.center)
        }
        
        button.addTarget(self, action: #selector(tapButton(_:)), for: .touchUpInside)
    }
    
    @objc func tapButton(_ button: UIButton) {
        
        ApiRTC.test()
    }
}
