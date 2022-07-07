//
//  InitialFlow.swift
//  TedoooOnBoardingScreenImpl
//
//  Created by Mor on 06/07/2022.
//

import Foundation
import TedoooOnBoardingScreen
import Swinject
import Combine
import CreateShopFlowApi

public class InitialFlow {
    
    public init(container: Container) {
        DIContainer.shared.registerContainer(container: container)
    }
    
    public func launchFlow(in viewController: UIViewController) -> AnyPublisher<AddShopResult, Never> {
        let vc = InitialViewController.instantiate()
        vc.modalPresentationStyle = .overCurrentContext
        let navVc = UINavigationController(rootViewController: vc)
        navVc.isNavigationBarHidden = true
        navVc.modalPresentationStyle = .overCurrentContext
        let vm = ActivityViewModel.get(navController: navVc)
        viewController.present(navVc, animated: true)
        return vm.endSubject.eraseToAnyPublisher()
        
    }
    
}
