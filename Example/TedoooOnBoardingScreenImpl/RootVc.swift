//
//  RootVc.swift
//  TedoooOnBoardingScreenImpl_Example
//
//  Created by Mor on 09/07/2022.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import Foundation
import UIKit
import TedoooOnBoardingScreen
import TedoooCombine
import TedoooOnBoardingScreenImpl

class RootVc: UIViewController {
    
    private var bag = CombineBag()
    
    @IBAction func start() {
        InitialFlow(container: TestContainer.shared.container).launchFlow(inNavController: navigationController!).sink { [weak self] result in
            guard let self = self else { return }
            result.vc.dismiss(animated: true) {
                print("got result", result)
            }
        } => bag
        navigationController?.viewControllers = [navigationController!.viewControllers.last!]
    }
    
    
}
