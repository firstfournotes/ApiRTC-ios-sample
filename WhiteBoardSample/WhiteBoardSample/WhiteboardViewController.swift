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

enum WhiteboardTouchMode {
    case scrolling
    case drawing
}

class WhiteboardViewController: UIViewController {
    
    var whiteboard: Whiteboard!
    var whiteboardScrollView: WhiteboardScrollView!
    var whiteboardView: WhiteboardView!
    
    var mode: WhiteboardTouchMode! {
        didSet {
            handleTouchMode(mode)
        }
    }
    
    let toolItems: [DrawTool] = [.pen, .eraser, .rectangle, .arrow, .ellipse]
    
    init(whiteboard: Whiteboard) {
        super.init(nibName: nil, bundle: nil)
        self.whiteboard = whiteboard
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
 
        self.view.backgroundColor = .white
    
        // FIXME: fix sizes
        whiteboardScrollView = WhiteboardScrollView(size: CGSize(width: 1000, height: 1000))
        self.view.addSubview(whiteboardScrollView)
        whiteboardScrollView.snp.makeConstraints { (make) in
            make.top.right.left.bottom.equalTo(0)
        }
        
        whiteboardView = WhiteboardView(frame: CGRect(x: 5, y: 5, width: 990, height: 990))
        whiteboardScrollView.addSubview(whiteboardView)

        whiteboard.setView(whiteboardView)
        
        // Buttons
        
        let dismissButton = Button(title: "Close")
        self.view.addSubview(dismissButton)
        dismissButton.snp.makeConstraints { (make) in
            make.left.top.equalTo(0)
            make.width.equalTo(80)
            make.height.equalTo(30)
        }
        dismissButton.addTarget(self, action: #selector(tapDismiss(_:)), for: .touchUpInside)
        
        let undoButton = Button(title: "Undo")
        self.view.addSubview(undoButton)
        undoButton.snp.makeConstraints { (make) in
            make.top.equalTo(dismissButton.snp.bottom).offset(3)
            make.left.equalTo(0)
            make.width.equalTo(80)
            make.height.equalTo(30)
        }
        undoButton.addTarget(self, action: #selector(tapUndo(_:)), for: .touchUpInside)

        let redoButton = Button(title: "Redo")
        self.view.addSubview(redoButton)
        redoButton.snp.makeConstraints { (make) in
            make.top.equalTo(undoButton.snp.bottom).offset(3)
            make.left.equalTo(0)
            make.width.equalTo(80)
            make.height.equalTo(30)
        }
        redoButton.addTarget(self, action: #selector(tapRedo(_:)), for: .touchUpInside)
        
        let newSheetButton = Button(title: "New Sheet")
        self.view.addSubview(newSheetButton)
        newSheetButton.snp.makeConstraints { (make) in
            make.top.equalTo(redoButton.snp.bottom).offset(3)
            make.left.equalTo(0)
            make.width.equalTo(80)
            make.height.equalTo(30)
        }
        newSheetButton.addTarget(self, action: #selector(tapNewSheet(_:)), for: .touchUpInside)
        
        let toolSegmentedControl = UISegmentedControl(items: toolItems.map({ "\($0)" }))
        self.view.addSubview(toolSegmentedControl)
        toolSegmentedControl.snp.makeConstraints { (make) in
            make.left.equalTo(5)
            make.right.equalTo(-5)
            make.bottom.equalTo(-5)
            make.height.equalTo(26)
        }
        toolSegmentedControl.selectedSegmentIndex = 0
        toolSegmentedControl.addTarget(self, action: #selector(tapToolSegmentedControl(_:)), for: .valueChanged)
        
        let touchModeSegmentedControl = UISegmentedControl(items: ["Draw", "Scroll"])
        self.view.addSubview(touchModeSegmentedControl)
        touchModeSegmentedControl.snp.makeConstraints { (make) in
            make.left.equalTo(5)
            make.width.equalTo(150)
            make.bottom.equalTo(toolSegmentedControl.snp.top).offset(-10)
            make.height.equalTo(26)
        }
        touchModeSegmentedControl.selectedSegmentIndex = 0
        touchModeSegmentedControl.addTarget(self, action: #selector(tapModeSegmentedControl(_:)), for: .valueChanged)
        
        mode = .drawing
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // MARK:
    
    @objc func tapDismiss(_ button: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func tapModeSegmentedControl(_ control: UISegmentedControl) {
        mode = control.selectedSegmentIndex == 0 ? .drawing : .scrolling
    }
    
    @objc func tapToolSegmentedControl(_ control: UISegmentedControl) {
        whiteboard.tool = toolItems[control.selectedSegmentIndex]
    }
    
    @objc func tapUndo(_ button: UIButton) {
        whiteboard.undo()
    }
    
    @objc func tapRedo(_ button: UIButton) {
        whiteboard.redo()
    }
    
    @objc func tapNewSheet(_ button: UIButton) {
        whiteboard.createNewSheet()
    }
    
    // MARK:
    
    func handleTouchMode(_ mode: WhiteboardTouchMode) {
        switch mode {
        case .scrolling:
            whiteboardScrollView.isScrollEnabled = true
            whiteboardView.isUserInteractionEnabled = false
        case .drawing:
            whiteboardScrollView.isScrollEnabled = false
            whiteboardView.isUserInteractionEnabled = true
        }
    }
}

class Button: UIButton {
    
    static var bgColor = UIColor(red: 0/255, green: 122/255, blue: 255/255, alpha: 0.7)
    
    init(title: String) {
        super.init(frame: .zero)
        setTitle(title, for: .normal)
        titleLabel?.font = UIFont.systemFont(ofSize: 14)
        self.backgroundColor = Button.bgColor
        setTitleColor(.white, for: .normal)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var isHighlighted: Bool {
        didSet {
            switch isHighlighted {
            case true:
                self.backgroundColor = Button.bgColor.withAlphaComponent(1)
            case false:
                self.backgroundColor = Button.bgColor
            }
        }
    }
}
