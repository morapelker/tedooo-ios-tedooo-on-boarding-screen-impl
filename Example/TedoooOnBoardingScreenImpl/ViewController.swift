//
//  ViewController.swift
//  TedoooOnBoardingScreenImpl
//
//  Created by morapelker on 07/06/2022.
//  Copyright (c) 2022 morapelker. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    
    override func viewDidLoad() {
        super.viewDidLoad()

        DispatchQueue.main.async {
            if let navVc = self.storyboard?.instantiateViewController(withIdentifier: "TestNavController") {
                navVc.modalPresentationStyle = .overCurrentContext
                self.present(navVc, animated: true)
            }
            
        }

    }

}

