//
//  UIViewController+presentFullScreen.swift
//  Rhyme a Zoo
//
//  Created by Cal on 11/6/23.
//  Copyright © 2023 Cal Stephens. All rights reserved.
//

import UIKit

extension UIViewController {
  // Rhyme a Zoo was designed back when `UIViewController.present` defaulted to a
  // full-screen modal slide over animation, so we preserve that default here.
  func presentFullScreen(
    _ viewController: UIViewController,
    animated: Bool,
    completion: (() -> Void)?)
  {
    viewController.modalPresentationStyle = .fullScreen
    present(viewController, animated: animated, completion: completion)
  }
}
