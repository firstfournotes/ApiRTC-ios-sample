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
    
    var whiteboardScrollView: WhiteboardScrollView!
    var whiteboardView: WhiteboardView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .white
    
        whiteboardScrollView = WhiteboardScrollView(size: CGSize(width: 1000, height: 1000), insets: UIEdgeInsetsMake(10, 10, 10, 10))
        whiteboardView = whiteboardScrollView.whiteboardView // FIXME:
        
        self.view.addSubview(whiteboardScrollView)
        whiteboardScrollView.snp.makeConstraints { (make) in
            make.top.right.left.bottom.equalTo(0)
        }
        whiteboardScrollView.mode = .drawing
        
        whiteboardView.onUpdate { data in
            self.delegate?.whiteboardViewController(self, didAddData: data)
        }
        
        let dismissButton = Button(title: "Close")
        self.view.addSubview(dismissButton)
        dismissButton.snp.makeConstraints { (make) in
            make.left.top.equalTo(5)
            make.width.equalTo(80)
            make.height.equalTo(30)
        }
        dismissButton.addTarget(self, action: #selector(tapDismiss(_:)), for: .touchUpInside)
        
        let touchModeSegmentedControl = UISegmentedControl(items: ["Draw", "Scroll"])
        self.view.addSubview(touchModeSegmentedControl)
        touchModeSegmentedControl.snp.makeConstraints { (make) in
            make.left.equalTo(10)
            make.bottom.equalTo(-10)
            make.width.equalTo(100)
            make.height.equalTo(26)
        }
        touchModeSegmentedControl.selectedSegmentIndex = 0
        touchModeSegmentedControl.addTarget(self, action: #selector(tapSegmentedControl(_:)), for: .valueChanged)
        
        let undoButton = Button(title: "Undo")
        self.view.addSubview(undoButton)
        undoButton.snp.makeConstraints { (make) in
            make.right.bottom.equalTo(-5)
            make.width.equalTo(80)
            make.height.equalTo(30)
        }
        undoButton.addTarget(self, action: #selector(tapUndo(_:)), for: .touchUpInside)

        let redoButton = Button(title: "Redo")
        self.view.addSubview(redoButton)
        redoButton.snp.makeConstraints { (make) in
            make.right.equalTo(-5)
            make.bottom.equalTo(undoButton.snp.top).offset(-5)
            make.width.equalTo(80)
            make.height.equalTo(30)
        }
        redoButton.addTarget(self, action: #selector(tapRedo(_:)), for: .touchUpInside)
        
        let newSheetButton = Button(title: "New Sheet")
        self.view.addSubview(newSheetButton)
        newSheetButton.snp.makeConstraints { (make) in
            make.right.equalTo(-5)
            make.bottom.equalTo(redoButton.snp.top).offset(-5)
            make.width.equalTo(80)
            make.height.equalTo(30)
        }
        newSheetButton.addTarget(self, action: #selector(tapNewSheet(_:)), for: .touchUpInside)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // MARK:
    
    func update(_ data: WhiteboardData) {
        DispatchQueue.main.async {
            self.whiteboardView.update(data)
        }
    }
    
    // MARK:
    
    @objc func tapDismiss(_ button: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func tapSegmentedControl(_ control: UISegmentedControl) {
        whiteboardScrollView.mode = control.selectedSegmentIndex == 0 ? .drawing : .scrolling
    }
    
    @objc func tapUndo(_ button: UIButton) {
        whiteboardView.undo()
    }
    
    @objc func tapRedo(_ button: UIButton) {
        whiteboardView.redo() 
    }
    
    @objc func tapNewSheet(_ button: UIButton) {
        whiteboardView.createNewSheet()
    }
}

class Button: UIButton {
    
    init(title: String) {
        super.init(frame: .zero)
        setTitle(title, for: .normal)
        titleLabel?.font = UIFont.systemFont(ofSize: 14)
        setTitleColor(UIColor(red: 0/255, green: 122/255, blue: 255/255, alpha: 1), for: .normal)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
