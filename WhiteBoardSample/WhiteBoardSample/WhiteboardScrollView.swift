//
//  WhiteboardScrollView.swift
//  WhiteBoardSample
//
//  Created by Aleksandr Khorobrykh on 23/01/2018.
//  Copyright © 2018 Apizee. All rights reserved.
//

import UIKit

class WhiteboardScrollView: UIScrollView {
    
    init(size: CGSize) {
        super.init(frame: .zero)
        initUI(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func initUI(size: CGSize) {
        
        self.backgroundColor = .lightGray
    
        self.contentSize = size
    }
}
