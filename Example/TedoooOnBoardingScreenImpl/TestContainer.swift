//
//  TestContainer.swift
//  TedoooOnBoardingScreenImpl_Example
//
//  Created by Mor on 09/07/2022.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import Foundation
import Swinject
import TedoooOnBoardingScreen
import TedoooOnBoardingScreenImpl
import TedoooCategoriesApi
import TedoooOnBoardingApi
import CreateShopFlowApi
import TedoooCombine
import TedoooAnalytics

class TestContainer {
    
    let container = Container()
    
    static let shared = TestContainer()
    
    init() {
        container.register(TedoooCategoriesApi.CategoriesProvider.self) { _ in
            return Mockers.shared
        }.inObjectScope(.container)
        container.register(TedoooOnBoardingApi.self) { _ in
            return Mockers.shared
        }.inObjectScope(.container)
        container.register(CreateShopFlowApi.self) { _ in
            return Mockers.shared
        }.inObjectScope(.container)
        container.register(TedoooAnalytics.self) { _ in
            return Mockers.shared
        }
    }
    
}
