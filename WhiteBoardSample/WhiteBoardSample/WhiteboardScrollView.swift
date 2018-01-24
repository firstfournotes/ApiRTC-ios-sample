//
//  WhiteboardScrollView.swift
//  WhiteBoardSample
//
//  Created by Aleksandr Khorobrykh on 23/01/2018.
//  Copyright © 2018 Apizee. All rights reserved.
//

import UIKit

enum WhiteboardTouchMode {
    case scrolling
    case drawing
}

class WhiteboardScrollView: UIScrollView {

    var whiteboardView: WhiteboardView!
    
    var mode: WhiteboardTouchMode = .drawing {
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
        
        self.backgroundColor = .lightGray
        
        whiteboardView = WhiteboardView(frame: CGRect(x: insets.left, y: insets.top, width: size.width, height: size.height))
        whiteboardView.backgroundColor = .white
        self.addSubview(whiteboardView)
        
        self.contentSize = CGSize(width: size.width + insets.left + insets.right, height: size.height + insets.top + insets.bottom)
    }
    
    private func handleTouchMode(_ mode: WhiteboardTouchMode) {
        switch mode {
        case .scrolling:
            self.isScrollEnabled = true
            whiteboardView.isUserInteractionEnabled = false
        case .drawing:
            self.isScrollEnabled = false
            whiteboardView.isUserInteractionEnabled = true
        }
    }
}
