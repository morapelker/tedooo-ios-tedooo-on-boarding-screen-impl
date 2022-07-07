//
//  ViewController.swift
//  TedoooOnBoardingScreenImpl
//
//  Created by morapelker on 07/06/2022.
//  Copyright (c) 2022 morapelker. All rights reserved.
//

import UIKit
import TedoooOnBoardingScreen
import TedoooOnBoardingScreenImpl
import Swinject
import TedoooCategoriesApi
import TedoooOnBoardingApi
import CreateShopFlowApi
import TedoooCombine

class ViewController: UIViewController {

    private var bag = CombineBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let container = Container()
        
        container.register(TedoooCategoriesApi.CategoriesProvider.self) { _ in
            return Mockers.shared
        }.inObjectScope(.container)
        container.register(TedoooOnBoardingApi.self) { _ in
            return Mockers.shared
        }.inObjectScope(.container)
        container.register(CreateShopFlowApi.self) { _ in
            return Mockers.shared
        }.inObjectScope(.container)
        
        DispatchQueue.main.async {
            let flow = InitialFlow(container: container)
            flow.launchFlow(in: self).sink { result in
                print("result from main app", result)
            } => self.bag
        }

    }

}

