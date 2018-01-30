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
    
    let toolItems: [DrawTool] = [.pen, .eraser, .rectangle, .arrow, .ellipse, .text]
    
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
        //whiteboardView.backgroundColor = .white
        whiteboardScrollView.addSubview(whiteboardView)

        whiteboard.setView(whiteboardView)
        
        whiteboard.cursorColor = .green
        
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
            make.top.equalTo(0)
            make.right.equalTo(0)
            make.width.equalTo(80)
            make.height.equalTo(30)
        }
        undoButton.addTarget(self, action: #selector(tapUndo(_:)), for: .touchUpInside)

        let redoButton = Button(title: "Redo")
        self.view.addSubview(redoButton)
        redoButton.snp.makeConstraints { (make) in
            make.top.equalTo(undoButton.snp.bottom).offset(3)
            make.right.equalTo(0)
            make.width.equalTo(80)
            make.height.equalTo(30)
        }
        redoButton.addTarget(self, action: #selector(tapRedo(_:)), for: .touchUpInside)
        
        let newSheetButton = Button(title: "New Sheet")
        self.view.addSubview(newSheetButton)
        newSheetButton.snp.makeConstraints { (make) in
            make.top.equalTo(redoButton.snp.bottom).offset(3)
            make.right.equalTo(0)
            make.width.equalTo(80)
            make.height.equalTo(30)
        }
        newSheetButton.addTarget(self, action: #selector(tapNewSheet(_:)), for: .touchUpInside)
        
        let toolSegmentedControl = UISegmentedControl(items: toolItems.map({ "\($0)" }))
        self.view.addSubview(toolSegmentedControl)
        toolSegmentedControl.snp.makeConstraints { (make) in
            make.left.equalTo(8)
            make.right.equalTo(-8)
            make.bottom.equalTo(-10)
            make.height.equalTo(26)
        }
        toolSegmentedControl.selectedSegmentIndex = 0
        toolSegmentedControl.addTarget(self, action: #selector(tapToolSegmentedControl(_:)), for: .valueChanged)
        
        let toolLabel = Label(text: "Tool")
        self.view.addSubview(toolLabel)
        toolLabel.snp.makeConstraints { (make) in
            make.left.equalTo(8)
            make.width.equalTo(100)
            make.bottom.equalTo(toolSegmentedControl.snp.top).offset(-1)
            make.height.equalTo(15)
        }
        
        let colorSegmentedControl = UISegmentedControl(items: ["Black", "Red", "Blue"])
        self.view.addSubview(colorSegmentedControl)
        colorSegmentedControl.snp.makeConstraints { (make) in
            make.left.equalTo(8)
            make.width.equalTo(150)
            make.bottom.equalTo(toolLabel.snp.top).offset(-8)
            make.height.equalTo(26)
        }
        colorSegmentedControl.addTarget(self, action: #selector(tapColorSegmentedControl(_:)), for: .valueChanged)
        colorSegmentedControl.selectedSegmentIndex = 0
        
        let colorLabel = Label(text: "Color")
        self.view.addSubview(colorLabel)
        colorLabel.snp.makeConstraints { (make) in
            make.left.equalTo(8)
            make.width.equalTo(100)
            make.bottom.equalTo(colorSegmentedControl.snp.top).offset(-1)
            make.height.equalTo(15)
        }
        
        let brushSegmentedControl = UISegmentedControl(items: ["1", "2", "3"])
        self.view.addSubview(brushSegmentedControl)
        brushSegmentedControl.snp.makeConstraints { (make) in
            make.left.equalTo(8)
            make.width.equalTo(100)
            make.bottom.equalTo(colorLabel.snp.top).offset(-8)
            make.height.equalTo(26)
        }
        brushSegmentedControl.addTarget(self, action: #selector(tapBrushSegmentedControl(_:)), for: .valueChanged)
        brushSegmentedControl.selectedSegmentIndex = 0
        
        let brushSizeLabel = Label(text: "Brush size")
        self.view.addSubview(brushSizeLabel)
        brushSizeLabel.snp.makeConstraints { (make) in
            make.left.equalTo(8)
            make.width.equalTo(100)
            make.bottom.equalTo(brushSegmentedControl.snp.top).offset(-1)
            make.height.equalTo(15)
        }
        
        let touchModeSegmentedControl = UISegmentedControl(items: ["Draw", "Scroll"])
        self.view.addSubview(touchModeSegmentedControl)
        touchModeSegmentedControl.snp.makeConstraints { (make) in
            make.left.equalTo(8)
            make.width.equalTo(150)
            make.bottom.equalTo(brushSizeLabel.snp.top).offset(-8)
            make.height.equalTo(26)
        }
        touchModeSegmentedControl.addTarget(self, action: #selector(tapModeSegmentedControl(_:)), for: .valueChanged)
        touchModeSegmentedControl.selectedSegmentIndex = 0
        
        let tapGR = UITapGestureRecognizer(target: self, action: #selector(tapGR(_:)))
        self.view.addGestureRecognizer(tapGR)
        
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
    
    @objc func tapColorSegmentedControl(_ control: UISegmentedControl) {
        switch control.selectedSegmentIndex {
        case 0:
            whiteboard.color = .black
        case 1:
            whiteboard.color = .red
        case 2:
            whiteboard.color = .blue
        default:
            break
        }
    }
    
    @objc func tapBrushSegmentedControl(_ control: UISegmentedControl) {
        switch control.selectedSegmentIndex {
        case 0:
            whiteboard.brushSize = 1
        case 1:
            whiteboard.brushSize = 3
        case 2:
            whiteboard.brushSize = 5
        default:
            break
        }
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
    
    @objc func tapGR(_ gr: UITapGestureRecognizer) {

        guard whiteboard.tool == .text else {
            return
        }

        let point = gr.location(in: whiteboardView)

        let alert = UIAlertController(title: "Print text", message: nil, preferredStyle: .alert)
        alert.addTextField { _ in

        }
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            let textField = alert.textFields![0]
            if let text = textField.text {
                self.whiteboard.addText(text, atPoint: point)
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in

        }))

        self.present(alert, animated: true, completion: nil)
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

class Label: UILabel {
    
    init(text: String) {
        super.init(frame: .zero)
        self.font = UIFont.systemFont(ofSize: 12)
        self.textColor = .gray
        self.text = text
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
