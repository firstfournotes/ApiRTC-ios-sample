//
//  WhiteboardViewController.swift
//  WhiteBoardSample
//
//  Created by Aleksandr Khorobrykh on 16/01/2018.
//  Copyright © 2018 Apizee. All rights reserved.
//

import UIKit
import ApiRTC
import SnapKit

protocol WhiteboardViewControllerDelegate: class {
    func whiteboardViewController(_ controller: WhiteboardViewController, didAddData data: WhiteboardData)
}

class WhiteboardViewController: UIViewController {

    weak var delegate: WhiteboardViewControllerDelegate?
    
    var whiteboardView: WhiteboardView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .white
    
        whiteboardView = WhiteboardView(size: CGSize(width: 1000, height: 1000))
        
        self.view.addSubview(whiteboardView)
        whiteboardView.snp.makeConstraints { (make) in
            make.top.right.left.bottom.equalTo(0)
        }
        whiteboardView.onUpdate { drawElements in
            let data = WhiteboardData(drawElements: drawElements)
            self.delegate?.whiteboardViewController(self, didAddData: data)
        }
        
        let dismissButton = UIButton()
        dismissButton.backgroundColor = .lightGray
        dismissButton.setTitle("Close", for: .normal)
        self.view.addSubview(dismissButton)
        dismissButton.snp.makeConstraints { (make) in
            make.left.top.equalTo(10)
            make.width.equalTo(80)
            make.height.equalTo(30)
        }
        dismissButton.addTarget(self, action: #selector(tapDismiss(_:)), for: .touchUpInside)
        
        let touchModeSegmentedControl = UISegmentedControl(items: ["Scroll", "Draw"])
        self.view.addSubview(touchModeSegmentedControl)
        touchModeSegmentedControl.snp.makeConstraints { (make) in
            make.left.equalTo(10)
            make.bottom.equalTo(-10)
            make.width.equalTo(100)
            make.height.equalTo(26)
        }
        touchModeSegmentedControl.selectedSegmentIndex = 0
        touchModeSegmentedControl.addTarget(self, action: #selector(tapSegmentedControl(_:)), for: .valueChanged)
        
        let undoButton = UIButton()
        undoButton.backgroundColor = .lightGray
        undoButton.setTitle("Undo", for: .normal)
        self.view.addSubview(undoButton)
        undoButton.snp.makeConstraints { (make) in
            make.right.bottom.equalTo(-10)
            make.width.equalTo(80)
            make.height.equalTo(30)
        }
        undoButton.addTarget(self, action: #selector(tapUndo(_:)), for: .touchUpInside)

    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // MARK:
    
    func update(_ whiteboardData: WhiteboardData) {
        whiteboardView.update(whiteboardData.drawElements)
    }
    
    // MARK:
    
    @objc func tapDismiss(_ button: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func tapSegmentedControl(_ control: UISegmentedControl) {
        whiteboardView.mode = control.selectedSegmentIndex == 0 ? .scrolling : .drawing
    }
    
    @objc func tapUndo(_ button: UIButton) {
        whiteboardView.undo()
    }
}
