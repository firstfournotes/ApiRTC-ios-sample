//
//  InputAligningViewController.swift
//  ApiRTCApp
//
//  Created by Aleksandr Khorobrykh on 06/11/2017.
//  Copyright © 2017 Apizee. All rights reserved.
//

import UIKit

class InputAligningViewController: UIViewController, UIScrollViewDelegate {
    
    var scrollView: UIScrollView!
    var keyboardRect: CGRect = .zero
    
    var activeView: UIView?
    
    deinit {
        removeKeyboardNotificationsObservers()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        registerForKeyboardNotifications()
        
        scrollView = UIScrollView()
        scrollView.delegate = self
        self.view.addSubview(scrollView)
        scrollView.snp.makeConstraints { (make) in
            make.top.equalTo(0)
            make.left.equalTo(0)
            make.right.equalTo(0)
            make.bottom.equalTo(0)
        }
        scrollView.isScrollEnabled = true
        
        let tapGR = UITapGestureRecognizer(target: self, action: #selector(tap(_:)))
        self.view.addGestureRecognizer(tapGR)
    }
    
    func registerForKeyboardNotifications() {
        
        observe(notif: NSNotification.Name.UIKeyboardWillShow.rawValue, selector: #selector(keyboardWillBeShown(notification:)))
        observe(notif: NSNotification.Name.UIKeyboardWillHide.rawValue, selector: #selector(keyboardWillBeHidden(notification:)))
    }
    
    func removeKeyboardNotificationsObservers() {
        
        removeObserver(name: NSNotification.Name.UIKeyboardWillShow.rawValue)
        removeObserver(name: NSNotification.Name.UIKeyboardWillHide.rawValue)
    }
    
    @objc func keyboardWillBeShown(notification: NSNotification) {
        
        guard let keyboardFrame = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue else {
            return
        }
        
        keyboardRect = keyboardFrame.cgRectValue
        
        scrollView.contentSize = CGSize(width: 0, height: Config.UI.screenSize.height + keyboardRect.height)
    }
    
    @objc func keyboardWillBeHidden(notification: NSNotification){
        scrollView.contentSize = CGSize(width: 0, height: Config.UI.screenSize.height)
    }
    
    @objc func tap(_ gr: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }
}
