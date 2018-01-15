//
//  Utils.swift
//  WhiteBoardSample
//
//  Created by Aleksandr Khorobrykh on 15/01/2018.
//  Copyright © 2018 Apizee. All rights reserved.
//

import UIKit

class Utils {

}

extension UIViewController {
    
    func showErrorAlert(message: String, okActionHandler: (() -> Void)? = nil) {
        
        showAlert(title: "Error", message: message, okActionHandler: okActionHandler)
    }
    
    func showWarningAlert(message: String, okActionHandler: (() -> Void)? = nil) {
        
        showAlert(title: "Warning", message: message, okActionHandler: okActionHandler)
    }
    
    func showAlert(title: String = "", message: String, okButtonTitle: String = "OK", cancelButtonTitle: String? = "Cancel", okActionHandler: (() -> Void)? = nil, cancelActionHandler: (() -> Void)? = nil) {
        
        guard self.isViewLoaded, self.view.window != nil else { // controller is visible
            return
        }
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        let okAction = UIAlertAction(title: okButtonTitle, style: .default) { (action) in
            okActionHandler?()
        }
        alert.addAction(okAction)
        
        if cancelActionHandler != nil {
            
            let cancelAction = UIAlertAction(title: cancelButtonTitle, style: .cancel) { (action) in
                cancelActionHandler?()
            }
            alert.addAction(cancelAction)
        }
        
        self.present(alert, animated: true)
    }
}
