//
//  HomeButton.swift
//  Rhyme a Zoo
//
//  Created by Cal Stephens on 9/6/18.
//  Copyright © 2018 Cal Stephens. All rights reserved.
//

import UIKit

class HomeButton: UIButton {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.addTarget(self, action: #selector(HomeButton.returnHome(_:)), for: .touchUpInside)
    }
    
    @objc func returnHome(_ sender: AnyObject) {
        UAHaltPlayback()
        
        if let application = UIApplication.shared.delegate,
            let topController = getTopController(application)
        {
            // find the Home view controller
            var viewController: UIViewController = topController
            
            while !(viewController is MainViewController),
                let previousController = viewController.presentingViewController
            {
                viewController = previousController
            }
            
            // ⚠️ hack ahead ⚠️
            viewController.dismiss(animated: true, completion: nil)
            
            // the dismissal animation is a bit buggy --
            // it dismisses the top-most VC instantly, and then plays the animation
            // on the MainViewController's first-presented VC.
            // Get around this issue by  transplanting the visible view heirarchy
            // onto the VC that will actually get dismissed
            
            // we also have to temporarily disable audio playback, because some VCs
            // play audio on viewDidAppear
            UAHaltPlayback()
            UADisablePlayback(forSeconds: 0.5)
            
            if let dismissingViewController = viewController.presentedViewController {
                dismissingViewController.view.addSubview(topController.view)
            }
        }
    }
    
}
