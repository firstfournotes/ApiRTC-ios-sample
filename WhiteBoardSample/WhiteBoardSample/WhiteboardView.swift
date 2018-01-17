//
//  WhiteboardView.swift
//  WhiteBoardSample
//
//  Created by Aleksandr Khorobrykh on 16/01/2018.
//  Copyright © 2018 Apizee. All rights reserved.
//

import UIKit
import CoreGraphics

// FIXME: fix access levels

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
    
    init(size: CGSize, insets: UIEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0)) {
        super.init(frame: .zero)
        initialize(size: size, insets: insets)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func initialize(size: CGSize, insets: UIEdgeInsets) {
        self.backgroundColor = .yellow
        
        contentView = WhiteboardContentView(frame: CGRect(x: insets.left, y: insets.top, width: size.width, height: size.height))
        contentView.backgroundColor = .red
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
}

class WhiteboardContentView: UIImageView {
    
    var drawTimer: Timer?
    var points: [CGPoint] = []
    var drawElementView: DrawElementView?
    
    var tempImageView = UIImageView()
    
    var lastPoint = CGPoint.zero
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        // FIXME:
        
//        self.image = UIImage()
//        self.tempImageView = UIImageView()
//        self.tempImageView.image = UIImage()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        // FIXME:
        
        guard let point = touches.first?.location(in: self) else {
            return
        }
        
        undoManager?.registerUndo(withTarget: self, selector: #selector(handleUndo(_:)), object: self.image)

        lastPoint = point
        
//        drawElementView = DrawElementView(frame: self.bounds)
//        self.addSubview(drawElementView!)
        
//        drawTimer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(handlePoints), userInfo: nil, repeats: true)
//        drawTimer?.fire()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {

        // FIXME:
        
        guard let point = touches.first?.location(in: self) else {
            return
        }
        
        drawLine(fromPoint: lastPoint, toPoint: point)
        
        lastPoint = point
//        lock(points) {
//            points.append(point)
//        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        // FIXME:
        
//        drawTimer?.invalidate()
//        drawTimer = nil
//        drawElementView?.optimize()
        
        
//        UIGraphicsBeginImageContext(self.frame.size)
//        self.image?.draw(in: CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height), blendMode: .normal, alpha: 1.0)
//        tempImageView.image?.draw(in: CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height), blendMode: .normal, alpha: 1.0)
//        self.image = UIGraphicsGetImageFromCurrentImageContext()
//        UIGraphicsEndImageContext()
        
        tempImageView.image = nil
        
    }
    
    @objc private func handlePoints() {
        
        var lastPoints: [CGPoint] = []
        
        lock(points) {
            lastPoints.append(contentsOf: points)
            points = []
        }
        
        DispatchQueue.main.async {
            self.drawElementView?.drawPoints(lastPoints)
        }
    }
    
    func drawLine(fromPoint: CGPoint, toPoint: CGPoint) {
        
        // FIXME:
        
        UIGraphicsBeginImageContext(self.frame.size)
        let context = UIGraphicsGetCurrentContext()
        tempImageView.image?.draw(in: CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height))
        
        context?.move(to: fromPoint)
        context?.addLine(to: toPoint)
        
        //context?.setLineCap(.square)
        context?.setLineWidth(1)
        context?.setStrokeColor(UIColor.blue.cgColor)
        //context?.setBlendMode(.normal)
        
        context?.strokePath()
        
        tempImageView.image = UIGraphicsGetImageFromCurrentImageContext()
//        UIGraphicsEndImageContext()
//        
//        
//        UIGraphicsBeginImageContext(self.frame.size)
        self.image?.draw(in: CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height), blendMode: .colorBurn, alpha: 1.0)
        tempImageView.image?.draw(in: CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height), blendMode: .colorBurn, alpha: 1.0)
        self.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
    
    func undo() {
        undoManager?.undo()
    }
    
    @objc func handleUndo(_ image: UIImage) {
        self.image = image
        print("test")
    }
}

class DrawElementView: UIView {
    
    var points: [CGPoint] = []
    var path: UIBezierPath!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        path = UIBezierPath()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard points.count > 0 else {
            return // FIXME:
        }

        path.addClip()

        for (index, point) in points.enumerated() {

            if index == 0 {
                path.move(to: point)
                continue
            }

            path.addLine(to: point)
        }

        // FIXME: define as lastpoint and continue with next step from here
        // FIXME: check what happens with 1 point or something else

        //path.close()

        UIColor.blue.set()
        path.stroke()
    }
    
    func drawPoints(_ points: [CGPoint]) {
        self.points.append(contentsOf: points)
        self.setNeedsDisplay()
    }
    
    func optimize() {
        let pathRect = path.cgPath.boundingBox
        self.frame = pathRect
        let translation = CGAffineTransform(translationX: 0, y: 0);

        self.setNeedsDisplay()
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
