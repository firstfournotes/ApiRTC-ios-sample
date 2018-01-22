//
//  WhiteboardView.swift
//  WhiteBoardSample
//
//  Created by Aleksandr Khorobrykh on 16/01/2018.
//  Copyright © 2018 Apizee. All rights reserved.
//

import UIKit
import ApiRTC

// FIXME: fix all access levels !

enum WhiteboardTouchMode {
    case scrolling
    case drawing
}

class WhiteboardView: UIScrollView {

    var contentView: WhiteboardContentView!
    var mode: WhiteboardTouchMode = .scrolling {
        didSet {
            handleTouchMode(mode)
        }
    }
    
    private var onUpdate: ((_ drawElements: [DrawElement]) -> Void)? { // FIXME: add
        didSet {
            contentView.onUpdate = onUpdate
        }
    }
    
    init(size: CGSize, insets: UIEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0)) {
        super.init(frame: .zero)
        initialize(size: size, insets: insets)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func initialize(size: CGSize, insets: UIEdgeInsets) {
        self.backgroundColor = .lightGray
        
        contentView = WhiteboardContentView(frame: CGRect(x: insets.left, y: insets.top, width: size.width, height: size.height))
        contentView.backgroundColor = .white
        self.addSubview(contentView)
        
        self.contentSize = CGSize(width: size.width + insets.left + insets.right, height: size.height + insets.top + insets.bottom)
    }
    
    private func handleTouchMode(_ mode: WhiteboardTouchMode) {
        switch mode {
        case .scrolling:
            self.isScrollEnabled = true
            contentView.isUserInteractionEnabled = false
        case .drawing:
            self.isScrollEnabled = false
            contentView.isUserInteractionEnabled = true
        }
    }
    
    func undo() {
        contentView.undo()
    }
    
    func clear() {
        contentView.clear()
    }
    
    open func onUpdate(_ onUpdate: @escaping (_ drawElements: [DrawElement]) -> Void) {
        self.onUpdate = onUpdate
    }
    
    func update(_ drawElements: [DrawElement]) {
        
        for drawElement in drawElements {
            contentView.addElement(drawElement)
        }
    }
}

class WhiteboardContentView: UIImageView {
    
    var drawTimer: Timer?
    var drawElements: [DrawElement] = []
    
    var currentUserImage: UIImage?
    var commonImage: UIImage?
    
    var lastPoint = CGPoint.zero
    var actualOwnElementIndex = 0
    
    var onUpdate: ((_ drawElements: [DrawElement]) -> Void)?
    
    // MARK: Touches
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        guard let point = touches.first?.location(in: self) else {
            return
        }
        
        undoManager?.registerUndo(withTarget: self, selector: #selector(handleUndo(_:)), object: currentUserImage)

        lastPoint = point
        
        // FIXME: make property for frequency
        drawTimer = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(drawTimerAction), userInfo: nil, repeats: true)
        drawTimer?.fire()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {

        guard let point = touches.first?.location(in: self) else {
            return
        }
    
        let element = DrawElement(id: actualOwnElementIndex, undoIndex: 1, fromPoint: lastPoint, toPoint: point)
        addElement(element)
        
        lastPoint = point
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {

        drawTimer?.invalidate()
        drawTimer = nil
        drawTimerAction()
    }
    
    @objc private func drawTimerAction() {
        
        guard drawElements.count > 0 else {
            return
        }
        
        lock(drawElements) {
            onUpdate?(drawElements)
            drawElements = []
        }
    }
    
    // MARK: Drawing
    
    private func drawLine(fromPoint: CGPoint, toPoint: CGPoint, byCurrentUser: Bool = true) {
        
        draw(byCurrentUser: byCurrentUser) { context in
            context.move(to: fromPoint)
            context.addLine(to: toPoint)
            
            context.setLineWidth(1)
            context.setStrokeColor(UIColor.blue.cgColor)
            context.strokePath()
        }
    }
    
    func draw(byCurrentUser: Bool = true, draw: ((_ context: CGContext) -> Void)) {
        
        UIGraphicsBeginImageContextWithOptions(self.frame.size, false, 0)
        
        guard let context = UIGraphicsGetCurrentContext() else {
            print("No context")
            return
        }
        
        draw(context)
        
        if byCurrentUser {
            currentUserImage?.draw(in: CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height), blendMode: .colorBurn, alpha: 1.0)
            currentUserImage = UIGraphicsGetImageFromCurrentImageContext()
        }
        else {
            commonImage?.draw(in: CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height), blendMode: .colorBurn, alpha: 1.0)
            commonImage = UIGraphicsGetImageFromCurrentImageContext()
        }
        
        var newImage = commonImage
        
        if let currentUserImage = currentUserImage {
            newImage = newImage?.combineImage(image: currentUserImage) ?? currentUserImage
        }
        
        self.image = newImage
        
        UIGraphicsEndImageContext()
    }
    
    func addElement(_ drawElement: DrawElement) {
        
        switch drawElement.tool {
        case .pen:
            drawLine(fromPoint: drawElement.fromPoint, toPoint: drawElement.toPoint, byCurrentUser: drawElement.userId == ApiRTC.session.user.id)
        }
        
        lock(drawElements) {
            drawElements.append(drawElement)
        }
        
        if drawElement.userId == ApiRTC.session.user.id {
            actualOwnElementIndex += 1
        }
    }
    
    // FIXME:
    
    func undo() {
        undoManager?.undo()
    }
    
    func redo() {
        undoManager?.redo()
    }
    
    func clear() {
        
        guard let undoManager = undoManager else {
            return
        }
        
        while undoManager.canUndo {
            undo()
        }
    }
    
    @objc func handleUndo(_ image: UIImage) {
        
        draw { _ in
            currentUserImage = image
        }
    }
}

// MARK: Threads

func lock<T>(_ lock: Any, _ body: () throws -> T) rethrows -> T {
    objc_sync_enter(lock)
    defer {
        objc_sync_exit(lock)
    }
    return try body()
}


extension UIImage {
    
    func combineImage(image: UIImage) -> UIImage? {
        
        let newImageWidth  = max(self.size.width,  image.size.width )
        let newImageHeight = max(self.size.height, image.size.height)
        let newImageSize = CGSize(width : newImageWidth, height: newImageHeight)
        
        UIGraphicsBeginImageContextWithOptions(newImageSize, false, UIScreen.main.scale)
        
        let firstImageDrawX  = round((newImageSize.width  - self.size.width  ) / 2)
        let firstImageDrawY  = round((newImageSize.height - self.size.height ) / 2)
        
        let secondImageDrawX = round((newImageSize.width  - image.size.width ) / 2)
        let secondImageDrawY = round((newImageSize.height - image.size.height) / 2)
        
        self.draw(at: CGPoint(x: firstImageDrawX,  y: firstImageDrawY))
        image.draw(at: CGPoint(x: secondImageDrawX, y: secondImageDrawY))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return newImage
    }
}
